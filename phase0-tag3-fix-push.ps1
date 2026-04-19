# ============================================================================
# Fix-Push: say()-Bug in deploy.sh (unbound variable bei Aufruf ohne Arg)
# ============================================================================

$ServerIP   = "178.104.138.177"
$ServerUser = "root"
$AppDir     = "/var/www/menucard-pro"

Write-Host ""
Write-Host "=== Fix-Push: deploy.sh say()-Bug ===" -ForegroundColor Cyan
Write-Host ""

& git add scripts/deploy.sh
& git commit -m "Fix: deploy.sh say()/log() nounset-safe (local msg=\${1:-})"
if ($LASTEXITCODE -ne 0) {
    Write-Host "commit fehlgeschlagen." -ForegroundColor Red
    exit 1
}
& git push
if ($LASTEXITCODE -ne 0) {
    Write-Host "push fehlgeschlagen." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Server pull + dry-run ..." -ForegroundColor Yellow
Write-Host ""

ssh -t "$ServerUser@$ServerIP" "cd $AppDir && git pull --ff-only origin main && bash scripts/deploy.sh --dry-run"
$exit = $LASTEXITCODE

Write-Host ""
if ($exit -eq 0) {
    Write-Host "Dry-Run OK - Deploy-Pipeline ist einsatzbereit." -ForegroundColor Green
} else {
    Write-Host "Dry-Run Exit $exit - weitere Pruefung noetig." -ForegroundColor Yellow
}
