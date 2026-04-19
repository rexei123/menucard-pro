# ============================================
# PHASE 0 TAG 1 SCHRITT 2 - FORTSETZUNG (LAUNCHER)
# Fuer den Fall, dass der Haupt-Lauf bei Schritt 7 wegen SIGPIPE abgebrochen ist.
# ============================================

$ServerIP = "178.104.138.177"
$ServerUser = "root"
$LocalScript = "phase0-tag2-server-git-finish.sh"
$RemoteScript = "/tmp/phase0-tag2-server-git-finish.sh"

Write-Host ""
Write-Host "=== Phase 0 Tag 1 Schritt 2 - Fortsetzung ===" -ForegroundColor Cyan
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
    Write-Host "Server-Repo ist synced. Bereit fuer Schritt 3." -ForegroundColor Green
} else {
    Write-Host "Exit-Code $sshExit - bitte Ausgabe pruefen." -ForegroundColor Yellow
}
