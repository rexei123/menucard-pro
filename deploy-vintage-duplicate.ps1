# ============================================
# DEPLOY: Jahrgangs-Duplikation + taxRate/taxLabel
# EIN Befehl für alles
# ============================================

$SERVER = "root@178.104.138.177"
$APP = "/var/www/menucard-pro"

Write-Host "=== JAHRGANGS-DUPLIKATION DEPLOYMENT ===" -ForegroundColor Cyan
Write-Host ""

# 1. Dateien zum Server kopieren
Write-Host "[1/4] Dateien zum Server kopieren..." -ForegroundColor Yellow

scp "prisma/schema.prisma" "${SERVER}:${APP}/prisma/schema.prisma"
scp "src/components/admin/product-editor.tsx" "${SERVER}:${APP}/src/components/admin/product-editor.tsx"

# Neues Verzeichnis fuer Duplicate-Route
ssh $SERVER "mkdir -p ${APP}/src/app/api/v1/products/[id]/duplicate"
scp "src/app/api/v1/products/[id]/duplicate/route.ts" "${SERVER}:${APP}/src/app/api/v1/products/[id]/duplicate/route.ts"

Write-Host "[1/4] Dateien kopiert." -ForegroundColor Green

# 2. Prisma Schema pushen (lineageId + taxRate + taxLabel)
Write-Host "[2/4] Prisma Schema pushen..." -ForegroundColor Yellow
ssh $SERVER "cd ${APP} && npx prisma db push --accept-data-loss 2>&1 | tail -5"
Write-Host "[2/4] Schema aktualisiert." -ForegroundColor Green

# 3. Build + Restart
Write-Host "[3/4] Build + Restart..." -ForegroundColor Yellow
ssh $SERVER "cd ${APP} && npm run build 2>&1 | tail -5 && pm2 restart menucard-pro"
Write-Host "[3/4] Build + Restart fertig." -ForegroundColor Green

# 4. Verifikation
Write-Host "[4/4] Verifikation..." -ForegroundColor Yellow
ssh $SERVER "cd ${APP} && npx prisma db execute --stdin <<'SQL'
SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'Product' AND column_name IN ('lineageId', 'taxRate', 'taxLabel') ORDER BY column_name;
SQL"
Write-Host ""
Write-Host "=== DEPLOYMENT ABGESCHLOSSEN ===" -ForegroundColor Green
Write-Host "Testen: https://menu.hotel-sonnblick.at/admin/items" -ForegroundColor Cyan
