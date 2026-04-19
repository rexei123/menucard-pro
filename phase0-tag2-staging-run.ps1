# ============================================================================
# PHASE 0 TAG 2 SCHRITT 1 (LAUNCHER)
# Laedt das Staging-Setup-Script auf den Server und fuehrt es dort aus.
# ============================================================================

$ServerIP     = "178.104.138.177"
$ServerUser   = "root"
$LocalScript  = "phase0-tag2-staging-setup.sh"
$RemoteScript = "/tmp/phase0-tag2-staging-setup.sh"

Write-Host ""
Write-Host "=== Phase 0 Tag 2 Schritt 1 - Staging-Setup ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Das Script legt PostgreSQL-User + DB an, klont das Repo nach"
Write-Host "/var/www/menucard-pro-staging, erzeugt .env aus prod-.env,"
Write-Host "macht npm ci + prisma db push + build."
Write-Host ""
Write-Host "Am Ende werden DB-Passwort + NEXTAUTH_SECRET einmalig angezeigt."
Write-Host ""

if (-not (Test-Path $LocalScript)) {
    Write-Host "FEHLER: $LocalScript nicht gefunden." -ForegroundColor Red
    exit 1
}

Write-Host "Upload..." -ForegroundColor Yellow
scp $LocalScript "${ServerUser}@${ServerIP}:${RemoteScript}"
if ($LASTEXITCODE -ne 0) {
    Write-Host "FEHLER: scp fehlgeschlagen." -ForegroundColor Red
    exit 1
}

Write-Host "Ausfuehrung startet..." -ForegroundColor Yellow
Write-Host ""

ssh -t "${ServerUser}@${ServerIP}" "bash $RemoteScript"
$sshExit = $LASTEXITCODE

Write-Host ""
if ($sshExit -eq 0) {
    Write-Host "Staging-App ist gebaut. Bereit fuer Schritt 2 (PM2 + Nginx)." -ForegroundColor Green
} else {
    Write-Host "Exit-Code $sshExit - bitte Ausgabe pruefen." -ForegroundColor Yellow
}
