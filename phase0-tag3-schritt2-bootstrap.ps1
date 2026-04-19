# ============================================================================
# PHASE 0 TAG 3 SCHRITT 2 - BOOTSTRAP (einmalig)
# ============================================================================
# Rollt das Test-Gate-Setup aus:
#
#   1. Lokal: scripts/deploy-staging.sh + ship.ps1 + Anpassungen committen + pushen
#   2. Staging-Server: git pull, chmod +x, Dry-Run des Staging-Deploy-Scripts
#   3. Kurzcheck: ship.ps1 --StagingOnly -Yes (End-to-End ohne Prod-Merge)
#
# Danach ist der Test-Gate scharf:
#   .\ship.ps1                       # Feature-Branch nach Staging + Tests + optional Prod
# ============================================================================

$ServerIP         = "178.104.138.177"
$ServerUser       = "root"
$StagingAppDir    = "/var/www/menucard-pro-staging"
$ProdAppDir       = "/var/www/menucard-pro"

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=== Bootstrap Test-Gate ===" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------------------
# 1. LOKAL: COMMIT + PUSH
# ----------------------------------------------------------------------
Write-Host "[1/3] Lokaler Commit + Push ..." -ForegroundColor Yellow

# .sh mit Executable-Bit im Git-Index markieren (Windows -> Linux)
& git add --chmod=+x scripts/deploy-staging.sh
if ($LASTEXITCODE -ne 0) {
    Write-Host "FEHLER: git add --chmod=+x fehlgeschlagen." -ForegroundColor Red
    exit 1
}
& git add ship.ps1 deploy.ps1 phase0-tag3-schritt2-bootstrap.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "FEHLER: git add fehlgeschlagen." -ForegroundColor Red
    exit 1
}

$staged = & git diff --cached --name-only
if (-not $staged) {
    Write-Host "  Nichts zu committen (Dateien bereits im Repo)." -ForegroundColor Gray
} else {
    Write-Host "  Zu committen:" -ForegroundColor Gray
    $staged | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }

    $msg = @"
Phase 0 Tag 3 Schritt 2: Deploy-Hook mit Test-Gate

- scripts/deploy-staging.sh: Staging-Deploy fuer beliebigen Branch, kein
  Smoke-Rollback (Test-Gate deckt Smoke-Fail ab)
- ship.ps1: Orchestriert Push -> Staging-Deploy -> Tunnel -> Playwright ->
  (bei gruen) Merge main + Prod-Deploy. Bei rotem Gate kein Prod.
- deploy.ps1: Header-Hinweis, ship.ps1 ist neuer Standard

Deploy-Protokoll (ARBEITSSCHEMA Abschnitt 8) jetzt in einem Kommando umgesetzt.
"@
    & git commit -m $msg
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FEHLER: git commit fehlgeschlagen." -ForegroundColor Red
        exit 1
    }

    & git push
    if ($LASTEXITCODE -ne 0) {
        Write-Host "FEHLER: git push fehlgeschlagen." -ForegroundColor Red
        exit 1
    }
}
Write-Host "[1/3] OK" -ForegroundColor Green

# ----------------------------------------------------------------------
# 2. STAGING-SERVER: PULL + CHMOD
# ----------------------------------------------------------------------
Write-Host ""
Write-Host "[2/3] Staging-Server: git pull + chmod ..." -ForegroundColor Yellow

$serverCmd = @"
set -e
cd $StagingAppDir
echo 'Vorher HEAD:' \$(git rev-parse --short HEAD)
git pull --ff-only origin main
echo 'Nachher HEAD:' \$(git rev-parse --short HEAD)
chmod +x scripts/deploy-staging.sh
ls -l scripts/deploy-staging.sh
echo ''
echo '--- Dry-Run ---'
bash scripts/deploy-staging.sh main --dry-run
echo ''
echo 'Staging-Bootstrap OK'
"@

ssh -t "$ServerUser@$ServerIP" $serverCmd
if ($LASTEXITCODE -ne 0) {
    Write-Host "FEHLER: Staging-Bootstrap fehlgeschlagen." -ForegroundColor Red
    exit 1
}
Write-Host "[2/3] OK" -ForegroundColor Green

# ----------------------------------------------------------------------
# 3. HINWEIS (kein automatischer End-to-End-Lauf, da User das steuern sollte)
# ----------------------------------------------------------------------
Write-Host ""
Write-Host "[3/3] Setup abgeschlossen." -ForegroundColor Green
Write-Host ""
Write-Host "Der Test-Gate ist einsatzbereit. Empfohlener naechster Schritt:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  .\ship.ps1 -StagingOnly -Yes" -ForegroundColor Yellow
Write-Host ""
Write-Host "Dieser Lauf macht einen echten End-to-End-Test der Pipeline ohne" -ForegroundColor Gray
Write-Host "Prod-Deploy: Staging-Deploy + Tunnel + Playwright-Suite." -ForegroundColor Gray
Write-Host ""
Write-Host "Bei gruen ist Tag 3 Schritt 2 erledigt. Fuer echte Releases dann:" -ForegroundColor Gray
Write-Host ""
Write-Host "  .\ship.ps1                (Feature-Branch -> Staging -> Test-Gate -> Prod)" -ForegroundColor Gray
Write-Host ""
