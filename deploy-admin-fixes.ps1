# ============================================
# DEPLOY: Admin-UI-Bugs
# 5: menu.isActive existiert nicht (3 Dateien)
# 6: 404 auf /admin/menus/[id] (MenuSection.isActive nicht existent)
# 7: Analytics/PDF-Creator Server-Exception
# 8: Settings-Platzhalter-Titel in 4 Seiten
# ============================================

$SERVER = "root@178.104.138.177"
$APP = "/var/www/menucard-pro"

Write-Host "=== FIX ADMIN-UI-BUGS ===" -ForegroundColor Cyan

# 1. Upload Code-Aenderungen (12 Dateien)
Write-Host "[1/4] Upload Code..." -ForegroundColor Yellow

# Menu-Editor Fixes
scp "src/app/admin/menus/[id]/page.tsx" "${SERVER}:${APP}/src/app/admin/menus/[id]/page.tsx"
scp "src/app/admin/menus/layout.tsx" "${SERVER}:${APP}/src/app/admin/menus/layout.tsx"
scp "src/app/api/v1/menus/route.ts" "${SERVER}:${APP}/src/app/api/v1/menus/route.ts"

# Analytics + PDF Fixes
scp "src/app/admin/analytics/page.tsx" "${SERVER}:${APP}/src/app/admin/analytics/page.tsx"
scp "src/app/admin/pdf-creator/page.tsx" "${SERVER}:${APP}/src/app/admin/pdf-creator/page.tsx"
scp "src/app/api/v1/pdf/route.tsx" "${SERVER}:${APP}/src/app/api/v1/pdf/route.tsx"
scp "src/app/api/v1/menus/[id]/pdf/route.ts" "${SERVER}:${APP}/src/app/api/v1/menus/[id]/pdf/route.ts"

# Design-Edit Fix
scp "src/app/admin/design/[id]/edit/page.tsx" "${SERVER}:${APP}/src/app/admin/design/[id]/edit/page.tsx"

# Settings-Titel Fixes
scp "src/app/admin/settings/users/page.tsx" "${SERVER}:${APP}/src/app/admin/settings/users/page.tsx"
scp "src/app/admin/settings/allergens/page.tsx" "${SERVER}:${APP}/src/app/admin/settings/allergens/page.tsx"
scp "src/app/admin/settings/languages/page.tsx" "${SERVER}:${APP}/src/app/admin/settings/languages/page.tsx"
scp "src/app/admin/settings/theme/page.tsx" "${SERVER}:${APP}/src/app/admin/settings/theme/page.tsx"

Write-Host "[1/4] Upload fertig." -ForegroundColor Green

# 2. Build
Write-Host "[2/4] Build..." -ForegroundColor Yellow
ssh $SERVER "cd $APP && npm run build"
Write-Host "[2/4] Build fertig." -ForegroundColor Green

# 3. PM2 Restart
Write-Host "[3/4] Restart..." -ForegroundColor Yellow
ssh $SERVER "pm2 restart menucard-pro"
Start-Sleep -Seconds 3
Write-Host "[3/4] Restart fertig." -ForegroundColor Green

# 4. Verifikation
Write-Host "[4/4] Verifikation..." -ForegroundColor Yellow
$t1 = curl.exe -s -o NUL -w "%{http_code}" -b "next-auth.session-token=placeholder" "https://menu.hotel-sonnblick.at/admin/menus"
$t2 = curl.exe -s -o NUL -w "%{http_code}" "https://menu.hotel-sonnblick.at/api/v1/menus"
$t3 = curl.exe -s -o NUL -w "%{http_code}" "https://menu.hotel-sonnblick.at/hotel-sonnblick/restaurant/abendkarte"
Write-Host "  /admin/menus (redirect erwartet)         -> $t1"
Write-Host "  /api/v1/menus (200 erwartet)             -> $t2"
Write-Host "  /hotel-sonnblick/restaurant/abendkarte   -> $t3"

if ($t2 -eq "200" -and $t3 -eq "200") {
  Write-Host ""
  Write-Host "=== DEPLOY ERFOLGREICH ===" -ForegroundColor Green
  Write-Host "Bitte im Browser pruefen:" -ForegroundColor Cyan
  Write-Host "  1. /admin/menus -> Klick auf Abendkarte (kein 404)" -ForegroundColor White
  Write-Host "  2. /admin/analytics (keine Server-Exception)" -ForegroundColor White
  Write-Host "  3. /admin/pdf-creator (keine Server-Exception)" -ForegroundColor White
  Write-Host "  4. /admin/settings/users (Titel: Benutzer)" -ForegroundColor White
} else {
  Write-Host ""
  Write-Host "=== FEHLER - pm2 logs ===" -ForegroundColor Red
  ssh $SERVER "pm2 logs menucard-pro --lines 40 --nostream --err"
}
