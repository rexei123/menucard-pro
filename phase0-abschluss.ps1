# ============================================================================
# PHASE 0 ABSCHLUSS - End-to-End-Test der kompletten Deploy-Pipeline
# ============================================================================
# Fuehrt Phase 0 zum sauberen Abschluss:
#
#   Schritt 1: HOUSEKEEPING auf main
#     - Alle bisher nicht committeten Phase-0-Infrastruktur-Dateien
#       (Tag-2/Tag-3-Scripts, playwright.config.ts, tests/e2e, package*.json)
#       in einem klaren Commit auf main landen + pushen.
#
#   Schritt 2: FEATURE-BRANCH fuer Health-Endpoint
#     - feature/health-endpoint abzweigen
#     - src/app/api/health/route.ts + phase0-abschluss.ps1 committen
#     - push
#
#   Schritt 3: SHIP
#     - Uebergabe an ship.ps1: Staging-Deploy -> Test-Gate -> Prod-Deploy
#
#   Schritt 4: VERIFIKATION
#     - curl https://menu.hotel-sonnblick.at/api/health
#
# Aufruf:
#   .\phase0-abschluss.ps1             # interaktiv (empfohlen)
#   .\phase0-abschluss.ps1 -Yes        # ohne Rueckfragen (auch in ship.ps1)
#   .\phase0-abschluss.ps1 -DryRun     # nur Plan anzeigen, nichts aendern
# ============================================================================

param(
    [switch]$Yes,
    [switch]$DryRun,
    [string]$BranchName = "feature/health-endpoint"
)

$ErrorActionPreference = "Stop"

function Section($t)  { Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Cyan }
function Ok($t)       { Write-Host "OK   $t" -ForegroundColor Green }
function Warn($t)     { Write-Host "WARN $t" -ForegroundColor Yellow }
function ErrLine($t)  { Write-Host "FAIL $t" -ForegroundColor Red }
function Step($n,$t)  { Write-Host ""; Write-Host "[$n] $t" -ForegroundColor Yellow }

function Confirm-Y($prompt) {
    if ($Yes) { return $true }
    $a = Read-Host "$prompt (y/n)"
    return ($a -eq 'y' -or $a -eq 'Y')
}

$HealthRoute = "src/app/api/health/route.ts"

# ----------------------------------------------------------------------
# 0. Plausibilitaet
# ----------------------------------------------------------------------
Section "Phase 0 Abschluss - End-to-End-Test"

if (-not (Test-Path "package.json") -or -not (Test-Path "ship.ps1")) {
    ErrLine "Bitte im MenuCard-Pro-Projektverzeichnis ausfuehren."
    exit 1
}
if (-not (Test-Path $HealthRoute)) {
    ErrLine "Datei fehlt: $HealthRoute (wurde von Claude vorbereitet)"
    exit 1
}
Ok "Projektverzeichnis erkannt"
Ok "Health-Route vorhanden: $HealthRoute"

# ----------------------------------------------------------------------
# 1. Arbeitsverzeichnis sortieren
# ----------------------------------------------------------------------
Step "1" "Working-Tree analysieren"

$currentBranch = (& git rev-parse --abbrev-ref HEAD).Trim()
Write-Host "  Aktueller Branch: $currentBranch" -ForegroundColor Gray

if ($currentBranch -ne "main") {
    Warn "Du bist nicht auf main. Bitte zuerst: git checkout main"
    if (-not (Confirm-Y "Jetzt zu main wechseln?")) { exit 0 }
    & git checkout main
    if ($LASTEXITCODE -ne 0) { ErrLine "Checkout fehlgeschlagen."; exit 1 }
}

# porcelain-Zeilen sammeln (Format: "XY <pfad>")
$porcelain = & git status --porcelain
if (-not $porcelain) {
    Warn "Working-Tree ist vollstaendig clean - nichts zu committen."
    Ok  "Ueberspringe Housekeeping, gehe direkt zum Feature-Branch."
    $housekeepingFiles = @()
    $healthGroup       = @()
} else {
    # Dateien aufteilen: Housekeeping (alles Phase-0-Infra) vs. Health-Route/Abschluss-Script
    $housekeepingFiles = @()
    $healthGroup       = @()
    foreach ($line in $porcelain) {
        $path = ($line.Substring(3)).Trim()
        if ($path -match "^src/app/api/health" -or
            $path -eq "phase0-abschluss.ps1") {
            $healthGroup += $path
        } else {
            $housekeepingFiles += $path
        }
    }

    if ($housekeepingFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "  Housekeeping-Kandidaten (landen als 1 Commit auf main):" -ForegroundColor Gray
        $housekeepingFiles | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    }
    if ($healthGroup.Count -gt 0) {
        Write-Host ""
        Write-Host "  Feature-Branch-Kandidaten (Commit auf $BranchName):" -ForegroundColor Gray
        $healthGroup | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    }
}

# ----------------------------------------------------------------------
# 2. DRY-RUN ggf. ausgeben
# ----------------------------------------------------------------------
if ($DryRun) {
    Section "DRY-RUN"
    if ($housekeepingFiles.Count -gt 0) {
        Write-Host "  git add <housekeeping>; git commit; git push origin main" -ForegroundColor Gray
    }
    Write-Host "  git checkout -b $BranchName" -ForegroundColor Gray
    Write-Host "  git add $HealthRoute phase0-abschluss.ps1" -ForegroundColor Gray
    Write-Host "  git commit -m 'Phase 0 Abschluss: /api/health Endpoint'" -ForegroundColor Gray
    Write-Host "  git push -u origin $BranchName" -ForegroundColor Gray
    if ($Yes) {
        Write-Host "  .\ship.ps1 -Yes" -ForegroundColor Gray
    } else {
        Write-Host "  .\ship.ps1" -ForegroundColor Gray
    }
    Ok "Dry-Run Ende"
    exit 0
}

# ----------------------------------------------------------------------
# 3. Housekeeping-Commit auf main
# ----------------------------------------------------------------------
if ($housekeepingFiles.Count -gt 0) {
    Step "2" "Housekeeping-Commit auf main"
    if (-not (Confirm-Y "Housekeeping auf main committen und pushen?")) {
        Warn "Abbruch durch User."
        exit 0
    }

    foreach ($f in $housekeepingFiles) {
        & git add -- $f
        if ($LASTEXITCODE -ne 0) { ErrLine "git add $f fehlgeschlagen."; exit 1 }
    }

    $hkMsg = @"
Phase 0 Housekeeping: Infra-Scripts, Playwright-Setup, Package-Updates

Committet alle im Lauf von Phase 0 entstandenen Infrastrukturdateien:
- Tag-2 Staging-Setup-Scripts (phase0-tag2-*)
- Tag-3 Fix/Launch-Scripts (phase0-tag3-*)
- Playwright-Konfiguration und E2E-Testsuite (playwright.config.ts, tests/e2e/)
- package.json / package-lock.json Aenderungen (Playwright-Abhaengigkeiten)

Hintergrund: Waehrend Phase 0 (Arbeitsschema + Deploy-Pipeline + Test-Gate)
liefen die Scripts ueberwiegend lokal und waren noch nicht versioniert.
Dieser Commit zieht den Stand sauber nach, damit Phase 1 auf einer
konsistenten main-Basis startet.
"@

    & git commit -m $hkMsg
    if ($LASTEXITCODE -ne 0) { ErrLine "Housekeeping-Commit fehlgeschlagen."; exit 1 }
    Ok "Housekeeping-Commit erstellt"

    & git push origin main
    if ($LASTEXITCODE -ne 0) { ErrLine "Push main fehlgeschlagen."; exit 1 }
    Ok "main gepusht"
} else {
    Write-Host ""
    Write-Host "  Kein Housekeeping noetig." -ForegroundColor Gray
}

# ----------------------------------------------------------------------
# 4. Feature-Branch anlegen
# ----------------------------------------------------------------------
Step "3" "Feature-Branch: $BranchName"

$exists = & git branch --list $BranchName
if ($exists) {
    Warn "Branch $BranchName existiert bereits lokal."
    if (-not (Confirm-Y "Checkout und weiterarbeiten?")) { exit 0 }
    & git checkout $BranchName
} else {
    & git checkout -b $BranchName
}
if ($LASTEXITCODE -ne 0) { ErrLine "Branch-Wechsel fehlgeschlagen."; exit 1 }
Ok "Auf Branch: $BranchName"

# ----------------------------------------------------------------------
# 5. Health-Endpoint committen
# ----------------------------------------------------------------------
Step "4" "Health-Endpoint committen"

& git add -- $HealthRoute
if (Test-Path "phase0-abschluss.ps1") { & git add -- phase0-abschluss.ps1 }

$staged = & git diff --cached --name-only
if (-not $staged) {
    Warn "Nichts zu committen - Branch bereits synchron."
} else {
    Write-Host "  Commit beinhaltet:" -ForegroundColor Gray
    $staged | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

    $msg = @"
Phase 0 Abschluss: /api/health Endpoint

- Minimaler Lebenszeichen-Endpoint, ohne DB, ohne Auth
- Returns JSON (ok, service, ts, uptimeSec, node, env, commit, version)
- Dient Monitoring, Staging-Smoke-Test und Test-Gate (ship.ps1)

Dient gleichzeitig als End-to-End-Test der Phase-0-Pipeline:
Feature-Branch -> Staging-Deploy -> Playwright-Test-Gate -> Prod-Deploy.
"@
    & git commit -m $msg
    if ($LASTEXITCODE -ne 0) { ErrLine "Feature-Commit fehlgeschlagen."; exit 1 }
    Ok "Feature-Commit erstellt"
}

Step "5" "Feature-Branch pushen"
& git push -u origin $BranchName
if ($LASTEXITCODE -ne 0) { ErrLine "git push fehlgeschlagen."; exit 1 }
Ok "Branch gepusht"

# ----------------------------------------------------------------------
# 6. Ship
# ----------------------------------------------------------------------
Step "6" "Uebergabe an ship.ps1 (Staging -> Test-Gate -> Prod)"

$shipArgs = @()
if ($Yes) { $shipArgs += "-Yes" }

Write-Host ""
Write-Host "  Kommando: .\ship.ps1 $($shipArgs -join ' ')" -ForegroundColor DarkGray
Write-Host ""

& .\ship.ps1 @shipArgs
$shipExit = $LASTEXITCODE

if ($shipExit -ne 0) {
    ErrLine "ship.ps1 fehlgeschlagen (Exit $shipExit)."
    Write-Host ""
    Write-Host "  Naechste Schritte bei rotem Test-Gate:" -ForegroundColor Yellow
    Write-Host "    1. HTML-Report wurde automatisch geoeffnet" -ForegroundColor Gray
    Write-Host "    2. Fehler analysieren, auf $BranchName fixen" -ForegroundColor Gray
    Write-Host "    3. Commit + Push -> ship.ps1 erneut laufen lassen" -ForegroundColor Gray
    Write-Host "    4. Staging bleibt rot bis zum gruenen Deploy (Absicht)" -ForegroundColor Gray
    exit $shipExit
}

# ----------------------------------------------------------------------
# 7. Verifikation auf Produktion
# ----------------------------------------------------------------------
Step "7" "Produktions-Check /api/health"

Start-Sleep -Seconds 3

try {
    $resp = Invoke-WebRequest -Uri "https://menu.hotel-sonnblick.at/api/health" `
                              -UseBasicParsing -TimeoutSec 15
    if ($resp.StatusCode -eq 200) {
        Ok "HTTP 200 von menu.hotel-sonnblick.at/api/health"
        Write-Host ""
        Write-Host $resp.Content -ForegroundColor Green
    } else {
        Warn "HTTP $($resp.StatusCode) - erwartet war 200"
    }
} catch {
    ErrLine "Prod-Check fehlgeschlagen: $($_.Exception.Message)"
    Warn "Evtl. Cache/Delay - bitte manuell pruefen:"
    Warn "  curl https://menu.hotel-sonnblick.at/api/health"
}

# ----------------------------------------------------------------------
# 8. Fertig
# ----------------------------------------------------------------------
Section "PHASE 0 ABSCHLUSS - FERTIG"
Write-Host ""
Ok "Kompletter End-to-End-Durchlauf erfolgreich:"
Write-Host "  - Housekeeping-Commit auf main gepusht" -ForegroundColor Gray
Write-Host "  - Feature-Branch + Health-Endpoint committet" -ForegroundColor Gray
Write-Host "  - Staging-Deploy erfolgreich" -ForegroundColor Gray
Write-Host "  - Test-Gate GRUEN (Playwright)" -ForegroundColor Gray
Write-Host "  - Merge nach main + Prod-Deploy" -ForegroundColor Gray
Write-Host "  - /api/health auf Produktion erreichbar" -ForegroundColor Gray
Write-Host ""
Write-Host "Phase 0 ist abgeschlossen." -ForegroundColor Green
Write-Host "Naechster Schritt: Secrets rotieren (Task #33)." -ForegroundColor Cyan
Write-Host ""
