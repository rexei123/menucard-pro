# ============================================================================
# Fix-Filemode: scripts/deploy.sh executable-Bit im Git-Index setzen
# ============================================================================

$ServerIP   = "178.104.138.177"
$ServerUser = "root"
$AppDir     = "/var/www/menucard-pro"

Write-Host ""
Write-Host "=== Fix-Filemode: scripts/deploy.sh +x im Index ===" -ForegroundColor Cyan
Write-Host ""

& git update-index --chmod=+x scripts/deploy.sh
if ($LASTEXITCODE -ne 0) {
    Write-Host "update-index fehlgeschlagen." -ForegroundColor Red
    exit 1
}

& git commit -m "Mark scripts/deploy.sh as executable (filemode 0755)"
if ($LASTEXITCODE -ne 0) {
    Write-Host "commit fehlgeschlagen (evtl. nichts zu committen)." -ForegroundColor Yellow
}

& git push
if ($LASTEXITCODE -ne 0) {
    Write-Host "push fehlgeschlagen." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Server: filemode zuruecksetzen, pull, dry-run ..." -ForegroundColor Yellow
Write-Host ""

# Auf dem Server:
# 1. 'git checkout -- scripts/deploy.sh' verwirft die lokale Mode-Aenderung
# 2. git pull --ff-only bringt unseren Push mit +x
# 3. dry-run
$cmd = "cd $AppDir && git checkout -- scripts/deploy.sh && git pull --ff-only origin main && ls -l scripts/deploy.sh && bash scripts/deploy.sh --dry-run"

ssh -t "$ServerUser@$ServerIP" $cmd
$exit = $LASTEXITCODE

Write-Host ""
if ($exit -eq 0) {
    Write-Host "Dry-Run OK - Deploy-Pipeline ist einsatzbereit." -ForegroundColor Green
} else {
    Write-Host "Exit $exit - weitere Pruefung noetig." -ForegroundColor Yellow
}
