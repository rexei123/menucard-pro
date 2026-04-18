# ============================================
# DEPLOY: Admin-UI-Bugs Runde 2
# Fehler #9: QRCode.location-Relation existiert nicht
#   - src/app/admin/analytics/page.tsx       (IIFE-Pattern fuer qrCodes-Query)
#   - src/app/api/v1/qr-codes/route.ts       (location separat laden)
#   - src/app/api/v1/qr-codes/[id]/route.ts  (getTenantQr-Helper)
# ============================================

$SERVER = "root@178.104.138.177"
$APP = "/var/www/menucard-pro"

Write-Host "=== FIX ADMIN-UI-BUGS RUNDE 2 ===" -ForegroundColor Cyan

# 1. Upload Code-Aenderungen (3 Dateien)
Write-Host "[1/4] Upload Code..." -ForegroundColor Yellow
scp "src/app/admin/analytics/page.tsx" "${SERVER}:${APP}/src/app/admin/analytics/page.tsx"
scp "src/app/api/v1/qr-codes/route.ts" "${SERVER}:${APP}/src/app/api/v1/qr-codes/route.ts"
scp "src/app/api/v1/qr-codes/[id]/route.ts" "${SERVER}:${APP}/src/app/api/v1/qr-codes/[id]/route.ts"
Write-Host "[1/4] Upload fertig." -ForegroundColor Green

# 2. Build + Restart in einer SSH-Session
Write-Host "[2/4] Build + Restart..." -ForegroundColor Yellow
ssh $SERVER "cd $APP && npm run build && pm2 restart menucard-pro"
Start-Sleep -Seconds 3
Write-Host "[2/4] Build + Restart fertig." -ForegroundColor Green

# 3. Verifikation
Write-Host "[3/4] Verifikation..." -ForegroundColor Yellow
$t1 = curl.exe -s -o NUL -w "%{http_code}" "https://menu.hotel-sonnblick.at/api/v1/qr-codes"
$t2 = curl.exe -s -o NUL -w "%{http_code}" "https://menu.hotel-sonnblick.at/hotel-sonnblick/restaurant/abendkarte"
Write-Host "  /api/v1/qr-codes (401 erwartet, nicht 500) -> $t1"
Write-Host "  /hotel-sonnblick/restaurant/abendkarte     -> $t2"

# 4. Server-Log-Check (letzte Fehler)
Write-Host "[4/4] Server-Log-Check..." -ForegroundColor Yellow
ssh $SERVER "pm2 logs menucard-pro --lines 20 --nostream --err"

if ($t1 -ne "500" -and $t2 -eq "200") {
  Write-Host ""
  Write-Host "=== DEPLOY ERFOLGREICH ===" -ForegroundColor Green
  Write-Host "Bitte im Browser pruefen:" -ForegroundColor Cyan
  Write-Host "  1. /admin/analytics  (keine Server-Exception mehr)" -ForegroundColor White
  Write-Host "  2. /admin/qr-codes   (Liste laedt)" -ForegroundColor White
} else {
  Write-Host ""
  Write-Host "=== FEHLER - siehe pm2 logs oben ===" -ForegroundColor Red
}
