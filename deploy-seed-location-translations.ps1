# ============================================
# DEPLOY: Seed fehlende Location-Uebersetzungen
# ============================================

$SERVER = "root@178.104.138.177"
$APP = "/var/www/menucard-pro"

Write-Host "=== SEED LOCATION-TRANSLATIONS ===" -ForegroundColor Cyan

Write-Host "[1/3] Upload..." -ForegroundColor Yellow
scp "scripts/seed-location-translations.sql" "${SERVER}:${APP}/scripts/seed-location-translations.sql"
scp "scripts/seed-location-translations.sh" "${SERVER}:${APP}/scripts/seed-location-translations.sh"
Write-Host "[1/3] Upload fertig." -ForegroundColor Green

Write-Host "[2/3] SQL + Restart..." -ForegroundColor Yellow
ssh $SERVER "cd $APP && bash scripts/seed-location-translations.sh"
Write-Host "[2/3] fertig." -ForegroundColor Green

Write-Host "[3/3] Verifikation..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
$t1 = curl.exe -s -o NUL -w "%{http_code}" "https://menu.hotel-sonnblick.at/hotel-sonnblick"
$t2 = curl.exe -s -o NUL -w "%{http_code}" "https://menu.hotel-sonnblick.at/hotel-sonnblick/restaurant"
Write-Host "  /hotel-sonnblick            -> $t1"
Write-Host "  /hotel-sonnblick/restaurant -> $t2"

if ($t1 -eq "200" -and $t2 -eq "200") {
  Write-Host "=== FIX ERFOLGREICH ===" -ForegroundColor Green
} else {
  Write-Host "=== FEHLER - pm2 logs ===" -ForegroundColor Red
  ssh $SERVER "pm2 logs menucard-pro --lines 30 --nostream --err"
}
