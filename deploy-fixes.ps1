# Deploy: Barkarte Location-Fix + Weinkarte Flatten-Fix
$server = "root@178.104.138.177"
$remote = "/var/www/menucard-pro"

Write-Host "=== 1. DB-Fix: Barkarte Location ===" -ForegroundColor Cyan
scp "fix-menus.sh" "${server}:${remote}/"
ssh $server "bash ${remote}/fix-menus.sh"

Write-Host ""
Write-Host "=== 2. page.tsx Upload + Build ===" -ForegroundColor Cyan
scp "server-src/src/app/(public)/[tenant]/[location]/[menu]/page.tsx" "${server}:${remote}/src/app/(public)/[tenant]/[location]/[menu]/page.tsx"
ssh $server "cd ${remote} && npm run build 2>&1 | tail -8 && pm2 restart menucard-pro"

Write-Host ""
Write-Host "=== 3. Test ===" -ForegroundColor Cyan
Start-Sleep -Seconds 5
ssh $server "for url in 'hotel-sonnblick/restaurant/abendkarte' 'hotel-sonnblick/restaurant/weinkarte' 'hotel-sonnblick/bar/barkarte' 'admin'; do echo -n ""  `$url = ""; curl -s -o /dev/null -w '%{http_code}' ""http://localhost:3000/`$url""; echo; done"
