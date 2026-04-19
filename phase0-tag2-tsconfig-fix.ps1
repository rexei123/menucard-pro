# Commit des tsconfig-Fixes + Pull auf Staging + Prod
$ServerIP   = "178.104.138.177"
$ServerUser = "root"
$AppDir     = "/var/www/menucard-pro"
$StagingDir = "/var/www/menucard-pro-staging"

Write-Host ""
Write-Host "=== tsconfig-Fix: exclude design-referenz, .local-archive ===" -ForegroundColor Cyan
Write-Host ""

& git add tsconfig.json
& git commit -m "tsconfig: exclude design-referenz and .local-archive from type-check"
if ($LASTEXITCODE -ne 0) { exit 1 }
& git push
if ($LASTEXITCODE -ne 0) { exit 1 }

$cmd = @"
set -e
cd $StagingDir && git fetch origin main && git reset --hard origin/main && echo 'Staging HEAD:' \$(git rev-parse --short HEAD)
cd $AppDir && git pull --ff-only origin main && echo 'Prod HEAD:' \$(git rev-parse --short HEAD)
"@

ssh -t "$ServerUser@$ServerIP" $cmd

Write-Host ""
Write-Host "Fix gepushed + gepullt. Jetzt .\phase0-tag2-staging-run.ps1 erneut." -ForegroundColor Green
