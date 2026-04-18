# Deploy Phase 4: Alle Admin-Seiten v2-kompatibel
$server = "root@178.104.138.177"
$remote = "/var/www/menucard-pro"

Write-Host "=== Upload alle geaenderten Admin-Dateien ===" -ForegroundColor Cyan
scp "src/app/admin/page.tsx" "${server}:${remote}/src/app/admin/page.tsx"
scp "src/app/admin/menus/layout.tsx" "${server}:${remote}/src/app/admin/menus/layout.tsx"
scp "src/app/admin/menus/[id]/page.tsx" "${server}:${remote}/src/app/admin/menus/[id]/page.tsx"
scp "src/app/admin/items/layout.tsx" "${server}:${remote}/src/app/admin/items/layout.tsx"
scp "src/app/admin/items/[id]/page.tsx" "${server}:${remote}/src/app/admin/items/[id]/page.tsx"
scp "src/app/admin/pdf-creator/page.tsx" "${server}:${remote}/src/app/admin/pdf-creator/page.tsx"

Write-Host ""
Write-Host "=== Build + Restart ===" -ForegroundColor Cyan
ssh $server "cd ${remote} && npm run build 2>&1 | tail -5 && pm2 restart menucard-pro"

Write-Host ""
Write-Host "=== PM2 Flush + Test ===" -ForegroundColor Cyan
Start-Sleep -Seconds 5
ssh $server "pm2 flush menucard-pro 2>&1 | tail -1"
