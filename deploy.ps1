# ============================================================================
# MenuCard Pro - Deploy-Launcher (lokal, PowerShell)
# ============================================================================
# HINWEIS: Ab 19.04.2026 ist .\ship.ps1 der empfohlene Deploy-Weg.
# ship.ps1 deployed erst nach Staging, laesst die Playwright-Suite laufen
# (Test-Gate) und geht nur bei gruen weiter auf Production.
# deploy.ps1 bleibt als direkter Hotfix-Weg fuer main-Deploys ohne Gate.
#
# Aufruf:
#   .\deploy.ps1                  # interaktiv (fragt am Server nach y/n)
#   .\deploy.ps1 -Yes             # automatisch bestaetigen
#   .\deploy.ps1 -DryRun          # nur anzeigen, nichts aendern
#   .\deploy.ps1 -NoBuild         # ohne npm run build (selten)
#
# Vorbedingung: aktueller Branch lokal ist gepusht.
# Das Script prueft das und warnt bei uncommitted / ungepushten Changes.
# ============================================================================

param(
    [switch]$Yes,
    [switch]$DryRun,
    [switch]$NoBuild,
    [switch]$SkipLocalCheck
)

$ServerIP       = "178.104.138.177"
$ServerUser     = "root"
$RemoteScript   = "/var/www/menucard-pro/scripts/deploy.sh"

Write-Host ""
Write-Host "=== MenuCard Pro Deploy ===" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------------------
# 1. Lokale Git-Checks (optional ueberspringbar)
# ----------------------------------------------------------------------
if (-not $SkipLocalCheck) {
    # uncommitted changes?
    $dirty = & git status --porcelain 2>$null
    if ($LASTEXITCODE -eq 0 -and $dirty) {
        Write-Host "WARNUNG: Uncommitted Changes im lokalen Repo:" -ForegroundColor Yellow
        $dirty | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        Write-Host ""
        $resp = Read-Host "Trotzdem fortfahren? (y/n)"
        if ($resp -ne "y") { exit 0 }
    }

    # local ahead of origin?
    $ahead = & git rev-list --count '@{u}..HEAD' 2>$null
    if ($LASTEXITCODE -eq 0 -and $ahead -and [int]$ahead -gt 0) {
        Write-Host "WARNUNG: Lokaler Branch ist $ahead Commit(s) vor origin." -ForegroundColor Yellow
        Write-Host "Ungepushte Commits gelangen NICHT auf den Server." -ForegroundColor Yellow
        $resp = Read-Host "Jetzt pushen? (y/n)"
        if ($resp -eq "y") {
            & git push
            if ($LASTEXITCODE -ne 0) {
                Write-Host "git push fehlgeschlagen." -ForegroundColor Red
                exit 1
            }
        }
    }
}

# ----------------------------------------------------------------------
# 2. Flags zum Server-Script bauen
# ----------------------------------------------------------------------
$flags = @()
if ($Yes)     { $flags += "--yes" }
if ($DryRun)  { $flags += "--dry-run" }
if ($NoBuild) { $flags += "--no-build" }
$flagStr = $flags -join " "

# ----------------------------------------------------------------------
# 3. SSH-Aufruf
# ----------------------------------------------------------------------
$remoteCmd = "bash $RemoteScript $flagStr"
Write-Host "Verbinde zu $ServerUser@$ServerIP ..." -ForegroundColor Yellow
Write-Host "Kommando: $remoteCmd" -ForegroundColor DarkGray
Write-Host ""

ssh -t "$ServerUser@$ServerIP" $remoteCmd
$sshExit = $LASTEXITCODE

Write-Host ""
if ($sshExit -eq 0) {
    Write-Host "Deploy erfolgreich." -ForegroundColor Green
} elseif ($sshExit -eq 2) {
    Write-Host "Flag-Fehler - bitte Syntax pruefen." -ForegroundColor Red
} else {
    Write-Host "Deploy fehlgeschlagen (Exit $sshExit). Log pruefen:" -ForegroundColor Red
    Write-Host "  ssh $ServerUser@$ServerIP 'tail -100 /var/log/menucard-deploy.log'" -ForegroundColor DarkGray
}

exit $sshExit
