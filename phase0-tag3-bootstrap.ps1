# ============================================================================
# PHASE 0 TAG 1 SCHRITT 3 - BOOTSTRAP (einmalig)
# ============================================================================
# Aufgaben:
#   1. Lokal: scripts/deploy.sh + deploy.ps1 committen + pushen
#   2. Server: git pull, chmod +x scripts/deploy.sh
#   3. Test: Deploy-Script --dry-run gegen den frischen Stand
#
# Danach ist der Deploy-Flow selbsttragend: jede Aenderung via
#   git add ... && git commit -m "..." && git push
#   .\deploy.ps1 -Yes
# ============================================================================

$ServerIP   = "178.104.138.177"
$ServerUser = "root"
$AppDir     = "/var/www/menucard-pro"

Write-Host ""
Write-Host "=== Bootstrap Deploy-Pipeline ===" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------------------
# 1. LOKAL: COMMIT + PUSH
# ----------------------------------------------------------------------
Write-Host "[1/3] Lokaler Commit + Push ..." -ForegroundColor Yellow

# Nur die Deploy-Pipeline-Dateien stagen
& git add scripts/deploy.sh deploy.ps1 phase0-tag3-bootstrap.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "FEHLER: git add fehlgeschlagen." -ForegroundColor Red
    exit 1
}

# Status zeigen
$staged = & git diff --cached --name-only
if (-not $staged) {
    Write-Host "  Nichts zu committen (Dateien bereits im Repo)." -ForegroundColor Gray
} else {
    Write-Host "  Zu committen:" -ForegroundColor Gray
    $staged | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }

    $msg = "Phase 0 Tag 1 Schritt 3: Git-basiertes Deploy-Script + Launcher (Lock, DB-Backup, conditional npm ci/prisma, Rollback bei Build/Smoke-Fail, Deploy-Log)"

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
# 2. SERVER: PULL + CHMOD
# ----------------------------------------------------------------------
Write-Host ""
Write-Host "[2/3] Server: git pull + chmod ..." -ForegroundColor Yellow

$serverCmd = @"
set -e
cd $AppDir
echo 'Vorher HEAD:' \$(git rev-parse --short HEAD)
git pull --ff-only origin main
echo 'Nachher HEAD:' \$(git rev-parse --short HEAD)
chmod +x scripts/deploy.sh
ls -l scripts/deploy.sh
echo 'Server-Bootstrap OK'
"@

ssh -t "$ServerUser@$ServerIP" $serverCmd
if ($LASTEXITCODE -ne 0) {
    Write-Host "FEHLER: Server-Bootstrap fehlgeschlagen." -ForegroundColor Red
    exit 1
}
Write-Host "[2/3] OK" -ForegroundColor Green

# ----------------------------------------------------------------------
# 3. TEST: DRY-RUN
# ----------------------------------------------------------------------
Write-Host ""
Write-Host "[3/3] Test: deploy.sh --dry-run ..." -ForegroundColor Yellow
Write-Host ""

ssh -t "$ServerUser@$ServerIP" "bash $AppDir/scripts/deploy.sh --dry-run"
$testExit = $LASTEXITCODE

Write-Host ""
if ($testExit -eq 0) {
    Write-Host "[3/3] OK - Deploy-Pipeline einsatzbereit." -ForegroundColor Green
    Write-Host ""
    Write-Host "Naechste Deploys: einfach  .\deploy.ps1 -Yes" -ForegroundColor Cyan
} else {
    Write-Host "[3/3] Dry-Run Exit $testExit - bitte Ausgabe pruefen." -ForegroundColor Yellow
}

Write-Host ""
