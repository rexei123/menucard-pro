# Deploy: Admin Dashboard v2 Fix + Tenant.settings + Passwort-Reset
$server = "root@178.104.138.177"
$remote = "/var/www/menucard-pro"

Write-Host "=== 1. DB-Fix + Passwort ===" -ForegroundColor Cyan
scp "fix-admin-dashboard.sh" "${server}:${remote}/"
ssh $server "bash ${remote}/fix-admin-dashboard.sh"

Write-Host ""
Write-Host "=== 2. Admin page.tsx Upload + Build ===" -ForegroundColor Cyan
scp "src/app/admin/page.tsx" "${server}:${remote}/src/app/admin/page.tsx"
ssh $server "cd ${remote} && npm run build 2>&1 | tail -8 && pm2 restart menucard-pro"

Write-Host ""
Write-Host "=== 3. Test ===" -ForegroundColor Cyan
Start-Sleep -Seconds 5
ssh $server "curl -s -o /dev/null -w 'admin=%{http_code}' http://localhost:3000/admin; echo"
