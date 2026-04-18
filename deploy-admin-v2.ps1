# Deploy: Admin Items Layout + Dashboard v2 Fix
$server = "root@178.104.138.177"
$remote = "/var/www/menucard-pro"

Write-Host "=== Upload admin files ===" -ForegroundColor Cyan
scp "src/app/admin/page.tsx" "${server}:${remote}/src/app/admin/page.tsx"
scp "src/app/admin/items/layout.tsx" "${server}:${remote}/src/app/admin/items/layout.tsx"

Write-Host "=== Build + Restart ===" -ForegroundColor Cyan
ssh $server "cd ${remote} && npm run build 2>&1 | tail -8 && pm2 restart menucard-pro"

Write-Host "=== Test ===" -ForegroundColor Cyan
Start-Sleep -Seconds 5
ssh $server "pm2 logs menucard-pro --lines 5 --nostream 2>&1 | grep -i error || echo 'Keine Fehler'"
