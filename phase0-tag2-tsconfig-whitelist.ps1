# tsconfig include-Whitelist: nur src/, prisma/, tailwind.config.ts kompilieren
$ServerIP   = "178.104.138.177"
$ServerUser = "root"
$AppDir     = "/var/www/menucard-pro"
$StagingDir = "/var/www/menucard-pro-staging"

Write-Host ""
Write-Host "=== tsconfig: include-Whitelist statt **/*.ts ===" -ForegroundColor Cyan
Write-Host ""

& git add tsconfig.json
& git commit -m "tsconfig: include-whitelist (src, prisma, tailwind.config) statt globaler **/*.ts"
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
Write-Host "Jetzt .\phase0-tag2-staging-run.ps1 erneut." -ForegroundColor Green
