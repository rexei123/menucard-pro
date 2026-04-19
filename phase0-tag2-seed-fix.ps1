# Fix: seed-design-templates.ts upsert auf `key` statt `name`
$ServerIP   = "178.104.138.177"
$ServerUser = "root"
$AppDir     = "/var/www/menucard-pro"
$StagingDir = "/var/www/menucard-pro-staging"

Write-Host ""
Write-Host "=== seed-design-templates: upsert auf key (unique) ===" -ForegroundColor Cyan
Write-Host ""

& git add prisma/seed-design-templates.ts
& git commit -m "seed-design-templates: upsert auf unique key (statt nicht-uniquem name)"
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
