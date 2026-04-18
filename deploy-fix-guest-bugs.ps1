# ============================================
# DEPLOY: Behebt drei Gaeste-UI-Bugs
# 1. Kontrast in Kartenansicht (h1 / Sektion-Header)
# 2. "science Sulfite"-Bug in Allergene-Badges
# 3. Taxonomie-Uebersetzungen EN
# ============================================

$SERVER = "root@178.104.138.177"
$APP = "/var/www/menucard-pro"

Write-Host "=== FIX GUEST-UI-BUGS ===" -ForegroundColor Cyan

# 1. Upload Code-Aenderungen
Write-Host "[1/5] Upload Code..." -ForegroundColor Yellow
scp "src/app/(public)/[tenant]/[location]/[menu]/page.tsx" "${SERVER}:${APP}/src/app/(public)/[tenant]/[location]/[menu]/page.tsx"
scp "src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx" "${SERVER}:${APP}/src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx"
scp "src/components/templates/modern-renderer.tsx" "${SERVER}:${APP}/src/components/templates/modern-renderer.tsx"
scp "scripts/seed-taxonomy-en-translations.sql" "${SERVER}:${APP}/scripts/seed-taxonomy-en-translations.sql"
scp "scripts/seed-taxonomy-en.sh" "${SERVER}:${APP}/scripts/seed-taxonomy-en.sh"
Write-Host "[1/5] Upload fertig." -ForegroundColor Green

# 2. SQL einspielen
Write-Host "[2/5] Seed Taxonomy EN..." -ForegroundColor Yellow
ssh $SERVER "cd $APP && bash scripts/seed-taxonomy-en.sh"
Write-Host "[2/5] fertig." -ForegroundColor Green

# 3. Build
Write-Host "[3/5] Build..." -ForegroundColor Yellow
ssh $SERVER "cd $APP && npm run build"
Write-Host "[3/5] Build fertig." -ForegroundColor Green

# 4. PM2 Restart
Write-Host "[4/5] Restart..." -ForegroundColor Yellow
ssh $SERVER "pm2 restart menucard-pro"
Start-Sleep -Seconds 3
Write-Host "[4/5] Restart fertig." -ForegroundColor Green

# 5. Verifikation
Write-Host "[5/5] Verifikation..." -ForegroundColor Yellow
$t1 = curl.exe -s -o NUL -w "%{http_code}" "https://menu.hotel-sonnblick.at/hotel-sonnblick"
$t2 = curl.exe -s -o NUL -w "%{http_code}" "https://menu.hotel-sonnblick.at/hotel-sonnblick/restaurant"
$t3 = curl.exe -s -o NUL -w "%{http_code}" "https://menu.hotel-sonnblick.at/hotel-sonnblick/restaurant/abendkarte"
Write-Host "  /hotel-sonnblick                         -> $t1"
Write-Host "  /hotel-sonnblick/restaurant              -> $t2"
Write-Host "  /hotel-sonnblick/restaurant/abendkarte   -> $t3"

if ($t1 -eq "200" -and $t2 -eq "200" -and $t3 -eq "200") {
  Write-Host ""
  Write-Host "=== DEPLOY ERFOLGREICH ===" -ForegroundColor Green
} else {
  Write-Host ""
  Write-Host "=== FEHLER - pm2 logs ===" -ForegroundColor Red
  ssh $SERVER "pm2 logs menucard-pro --lines 30 --nostream --err"
}
