# ============================================================================
# MenuCard Pro - SHIP (Deploy-Orchestrator mit Test-Gate)
# ============================================================================
# Ein-Kommando-Deploy nach Deploy-Protokoll (ARBEITSSCHEMA.md, Abschnitt 8):
#
#   1. Push aktueller Branch
#   2. Staging-Deploy (scripts/deploy-staging.sh auf Server)
#   3. SSH-Tunnel aufbauen (localhost:3001 -> Staging)
#   4. Playwright-Smoke-Suite gegen Staging (Test-Gate)
#   5. Bei GRUEN: Bestaetigung -> Merge in main + Push
#   6. Production-Deploy (scripts/deploy.sh auf Server)
#   7. SSH-Tunnel abbauen
#
# Bei rotem Test-Gate wird der Flow hart abgebrochen und NIEMALS auf Prod
# deployed. Staging bleibt im kaputten Zustand, damit die Ursache sichtbar ist.
#
# Aufruf:
#   .\ship.ps1                       # interaktiv, aktueller Branch
#   .\ship.ps1 -Yes                  # ohne Rueckfragen (CI-Modus)
#   .\ship.ps1 -StagingOnly          # Staging + Tests, kein Prod-Deploy
#   .\ship.ps1 -Branch feature/foo   # expliziter Branch
#   .\ship.ps1 -SkipTests            # NICHT EMPFOHLEN, nur Notfall
# ============================================================================

param(
    [string]$Branch,
    [switch]$Yes,
    [switch]$StagingOnly,
    [switch]$SkipTests,
    [switch]$NoBuild,
    [string]$ServerIP   = "178.104.138.177",
    [string]$ServerUser = "root"
)

$ErrorActionPreference = "Stop"

# ----------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------
function Section($t)  { Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Cyan }
function Ok($t)       { Write-Host "OK   $t" -ForegroundColor Green }
function Warn($t)     { Write-Host "WARN $t" -ForegroundColor Yellow }
function ErrLine($t)  { Write-Host "FAIL $t" -ForegroundColor Red }
function Step($n,$t)  { Write-Host ""; Write-Host "[$n] $t" -ForegroundColor Yellow }

function Confirm-Y($prompt) {
    if ($Yes) { return $true }
    $a = Read-Host "$prompt (y/n)"
    return $a -eq 'y' -or $a -eq 'Y'
}

function Stop-Tunnel([System.Diagnostics.Process]$p) {
    if ($null -ne $p -and -not $p.HasExited) {
        try { $p.Kill() } catch { }
    }
}

# ----------------------------------------------------------------------
# 0. Projekt-Root pruefen
# ----------------------------------------------------------------------
if (-not (Test-Path "package.json") -or -not (Test-Path "playwright.config.ts")) {
    ErrLine "Bitte im MenuCard-Pro-Projektverzeichnis ausfuehren."
    exit 1
}

# ----------------------------------------------------------------------
# 1. Branch + Git-State ermitteln
# ----------------------------------------------------------------------
Section "1) Git-State pruefen"

if (-not $Branch) {
    $Branch = (& git rev-parse --abbrev-ref HEAD).Trim()
}
if (-not $Branch -or $Branch -eq "HEAD") {
    ErrLine "Kein gueltiger Branch (detached HEAD?)."
    exit 1
}
Ok "Branch: $Branch"

# Uncommitted Changes?
$dirty = & git status --porcelain
if ($dirty) {
    Warn "Uncommitted Changes im Working Tree:"
    $dirty | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    if (-not (Confirm-Y "Trotzdem fortfahren? (uncommitted wird NICHT deployed)")) {
        exit 0
    }
}

# Prod-Branch-Warnung
if ($Branch -eq "main" -and -not $StagingOnly) {
    Warn "Du bist direkt auf 'main'. Empfohlen: feature-branch + Test-Gate."
    if (-not (Confirm-Y "Direkt-Deploy von main trotzdem ausfuehren?")) {
        exit 0
    }
}

# ----------------------------------------------------------------------
# 2. PUSH
# ----------------------------------------------------------------------
Section "2) Push $Branch"
& git push origin $Branch
if ($LASTEXITCODE -ne 0) {
    # vielleicht fehlt das Upstream-Tracking
    & git push -u origin $Branch
    if ($LASTEXITCODE -ne 0) {
        ErrLine "git push fehlgeschlagen."
        exit 1
    }
}
Ok "Branch $Branch auf origin"

# ----------------------------------------------------------------------
# 3. STAGING-DEPLOY
# ----------------------------------------------------------------------
Section "3) Staging-Deploy"
$stagingScript = "/var/www/menucard-pro-staging/scripts/deploy-staging.sh"
$stagingFlags = @("--yes")
if ($NoBuild) { $stagingFlags += "--no-build" }
$stagingArgs = ($stagingFlags -join " ")
$remoteCmd = "bash $stagingScript $Branch $stagingArgs"

Write-Host "  Kommando: ssh $ServerUser@$ServerIP `"$remoteCmd`"" -ForegroundColor DarkGray
ssh "$ServerUser@$ServerIP" $remoteCmd
$stagingExit = $LASTEXITCODE

if ($stagingExit -ne 0 -and $stagingExit -ne 3) {
    ErrLine "Staging-Deploy fehlgeschlagen (Exit $stagingExit). Abbruch."
    exit $stagingExit
}
if ($stagingExit -eq 3) {
    Warn "Staging-Deploy mit Smoke-Warnung beendet (Exit 3). Test-Gate uebernimmt."
}
Ok "Staging-Deploy abgeschlossen"

# ----------------------------------------------------------------------
# 4. TEST-GATE (SSH-Tunnel + Playwright)
# ----------------------------------------------------------------------
if ($SkipTests) {
    Warn "Test-Gate UEBERSPRUNGEN (--SkipTests). Kein Sicherheitsnetz."
} else {
    Section "4) Test-Gate: SSH-Tunnel + Playwright-Smoke"

    # Tunnel starten
    Step "4a" "SSH-Tunnel starten (127.0.0.1:3001 -> Staging)"
    $tunnelProc = Start-Process -FilePath "ssh" `
        -ArgumentList "-N", "-L", "3001:127.0.0.1:3001", "$ServerUser@$ServerIP" `
        -NoNewWindow -PassThru
    Start-Sleep -Seconds 2

    # Tunnel-Reachability
    $probeOk = $false
    for ($i=1; $i -le 10; $i++) {
        try {
            $probe = Invoke-WebRequest -Uri "http://127.0.0.1:3001" -UseBasicParsing `
                -TimeoutSec 3 -MaximumRedirection 0 -ErrorAction Stop
            if ($probe.StatusCode -ge 200 -and $probe.StatusCode -lt 500) { $probeOk = $true; break }
        } catch [System.Net.WebException] {
            if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -lt 500) {
                $probeOk = $true; break
            }
        } catch { }
        Start-Sleep -Seconds 1
    }
    if (-not $probeOk) {
        Stop-Tunnel $tunnelProc
        ErrLine "Tunnel nicht erreichbar. Test-Gate ROT. Abbruch."
        exit 1
    }
    Ok "Tunnel steht"

    # Credentials laden
    Step "4b" "Staging-Credentials laden"
    $credsRaw = & ssh "$ServerUser@$ServerIP" "cat /root/.secrets/staging-admin-creds.txt"
    if ($LASTEXITCODE -ne 0 -or -not $credsRaw) {
        Stop-Tunnel $tunnelProc
        ErrLine "Kann staging-admin-creds nicht lesen. Abbruch."
        exit 1
    }
    $adminEmail = $null; $adminPass = $null
    foreach ($line in ($credsRaw -split "`n")) {
        $line = $line.Trim()
        if     ($line -match '^EMAIL=(.+)$')    { $adminEmail = $Matches[1] }
        elseif ($line -match '^PASSWORD=(.+)$') { $adminPass  = $Matches[1] }
    }
    if (-not $adminEmail -or -not $adminPass) {
        Stop-Tunnel $tunnelProc
        ErrLine "EMAIL/PASSWORD nicht in Credentials-Datei. Abbruch."
        exit 1
    }
    Ok "Credentials fuer $adminEmail geladen"

    # Playwright laufen lassen
    Step "4c" "Playwright-Suite"
    $env:BASE_URL           = "http://127.0.0.1:3001"
    $env:ADMIN_EMAIL        = $adminEmail
    $env:ADMIN_PASS         = $adminPass
    $env:PUBLIC_TENANT_SLUG = "hotel-sonnblick"

    & npm run test:e2e
    $testExit = $LASTEXITCODE

    # Tunnel wieder schliessen
    Stop-Tunnel $tunnelProc
    Ok "Tunnel beendet"

    if ($testExit -ne 0) {
        Section "TEST-GATE: ROT"
        ErrLine "Playwright-Suite fehlgeschlagen (Exit $testExit)."
        $report = Join-Path $PWD "playwright-report\index.html"
        if (Test-Path $report) {
            Write-Host "  Report: $report" -ForegroundColor Yellow
            if (-not $Yes) { Start-Process $report }
        }
        Write-Host ""
        Write-Host "Kein Production-Deploy. Staging bleibt im IST-Zustand." -ForegroundColor Red
        exit $testExit
    }
    Section "TEST-GATE: GRUEN"
    Ok "Alle Smoke-Tests bestanden"
}

# ----------------------------------------------------------------------
# 5. Ab hier: nur noch wenn -StagingOnly NICHT gesetzt
# ----------------------------------------------------------------------
if ($StagingOnly) {
    Section "FERTIG (Staging-Only)"
    Ok "Staging aktualisiert, Tests gruen."
    Write-Host "  Kein Prod-Deploy - Flag -StagingOnly aktiv." -ForegroundColor Gray
    exit 0
}

# ----------------------------------------------------------------------
# 6. MERGE IN MAIN (nur wenn aktueller Branch != main)
# ----------------------------------------------------------------------
if ($Branch -ne "main") {
    Section "5) Merge $Branch -> main"
    if (-not (Confirm-Y "Jetzt $Branch in main mergen und pushen?")) {
        Warn "Merge uebersprungen. Kein Prod-Deploy."
        exit 0
    }

    & git checkout main
    if ($LASTEXITCODE -ne 0) { ErrLine "git checkout main fehlgeschlagen."; exit 1 }

    & git pull --ff-only origin main
    if ($LASTEXITCODE -ne 0) { Warn "git pull main nicht fast-forward - bitte manuell loesen."; exit 1 }

    & git merge --no-ff $Branch -m "Merge $Branch into main (via ship.ps1, Test-Gate gruen)"
    if ($LASTEXITCODE -ne 0) { ErrLine "git merge fehlgeschlagen."; exit 1 }

    & git push origin main
    if ($LASTEXITCODE -ne 0) { ErrLine "git push main fehlgeschlagen."; exit 1 }
    Ok "Merge + Push main erledigt"
}

# ----------------------------------------------------------------------
# 7. PRODUCTION-DEPLOY
# ----------------------------------------------------------------------
Section "6) Production-Deploy"
if (-not (Confirm-Y "Jetzt Production-Deploy starten?")) {
    Warn "Production-Deploy uebersprungen."
    exit 0
}

$prodScript = "/var/www/menucard-pro/scripts/deploy.sh"
$prodFlags = @("--yes")
if ($NoBuild) { $prodFlags += "--no-build" }
$prodArgs = ($prodFlags -join " ")

ssh -t "$ServerUser@$ServerIP" "bash $prodScript $prodArgs"
$prodExit = $LASTEXITCODE

Section "ZUSAMMENFASSUNG"
if ($prodExit -eq 0) {
    Ok "Production-Deploy erfolgreich."
    Write-Host "  https://menu.hotel-sonnblick.at/" -ForegroundColor Gray
} else {
    ErrLine "Production-Deploy fehlgeschlagen (Exit $prodExit)."
    Write-Host "  ssh $ServerUser@$ServerIP 'tail -100 /var/log/menucard-deploy.log'" -ForegroundColor DarkGray
}
exit $prodExit
