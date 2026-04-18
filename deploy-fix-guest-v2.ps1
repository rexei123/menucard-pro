# ============================================
# DEPLOY: Fix Gaeste-Seiten v2-Schema
# Behebt 500er-Error nach Klick auf "Demo ansehen"
# ============================================
# Bugs (alle v1-Altlasten nach v2-Migration):
#  1. tenant/page.tsx: isActive/isArchived/sortOrder auf Tenant/Location/Menu
#  2. tenant/location/page.tsx: gleiche Muster
#  3. item/[itemId]/page.tsx: theme.backgroundColor/textColor/accentColor
#     existieren nicht mehr als Spalten, nur noch in theme.config (JSON)

$SERVER = "root@178.104.138.177"
$APP = "/var/www/menucard-pro"

Write-Host "=== FIX GAESTE-SEITEN v2-SCHEMA ===" -ForegroundColor Cyan

# 1. Upload (Git dient als Backup)
Write-Host "[1/3] Upload..." -ForegroundColor Yellow
scp "src/app/(public)/[tenant]/page.tsx" "${SERVER}:${APP}/src/app/(public)/[tenant]/page.tsx"
scp "src/app/(public)/[tenant]/[location]/page.tsx" "${SERVER}:${APP}/src/app/(public)/[tenant]/[location]/page.tsx"
scp "src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx" "${SERVER}:${APP}/src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx"
Write-Host "[1/3] Upload fertig." -ForegroundColor Green

# 2. Build + Restart
Write-Host "[2/3] Build + PM2 Restart..." -ForegroundColor Yellow
ssh $SERVER "cd $APP && npm run build 2>&1 | tail -15 && pm2 restart menucard-pro"
Write-Host "[2/3] Build + Restart fertig." -ForegroundColor Green

# 3. Verifikation
Write-Host "[3/3] Verifikation..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
$t1 = curl.exe -s -o NUL -w "%{http_code}" "https://menu.hotel-sonnblick.at/hotel-sonnblick"
$t2 = curl.exe -s -o NUL -w "%{http_code}" "https://menu.hotel-sonnblick.at/hotel-sonnblick/restaurant"
Write-Host "  /hotel-sonnblick            -> $t1"
Write-Host "  /hotel-sonnblick/restaurant -> $t2"

if ($t1 -eq "200" -and $t2 -eq "200") {
  Write-Host ""
  Write-Host "=== FIX ERFOLGREICH ===" -ForegroundColor Green
} else {
  Write-Host ""
  Write-Host "=== FEHLER - pm2 logs ===" -ForegroundColor Red
  ssh $SERVER "pm2 logs menucard-pro --lines 30 --nostream --err"
}
