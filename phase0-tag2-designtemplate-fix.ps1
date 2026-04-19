# Fix: DesignTemplate-APIs + Seed auf unique `key` umstellen
$ServerIP   = "178.104.138.177"
$ServerUser = "root"
$AppDir     = "/var/www/menucard-pro"
$StagingDir = "/var/www/menucard-pro-staging"

Write-Host ""
Write-Host "=== DesignTemplate: findUnique(name) -> findFirst/key ===" -ForegroundColor Cyan
Write-Host ""

& git add prisma/seed-design-templates.ts src/app/api/v1/design-templates/route.ts src/app/api/v1/design-templates/[id]/route.ts
& git commit -m "DesignTemplate: v2-konforme unique-Lookups (key statt name), POST generiert key + entfernt createdBy"
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
