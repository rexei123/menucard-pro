# ============================================
# DEPLOY: Taxonomie-Überarbeitung
# EIN Befehl für alles
# ============================================

$SERVER = "root@178.104.138.177"
$APP = "/var/www/menucard-pro"

Write-Host "=== TAXONOMIE-DEPLOYMENT ===" -ForegroundColor Cyan
Write-Host ""

# 1. Alle geänderten Dateien zum Server kopieren
Write-Host "[1/5] Dateien zum Server kopieren..." -ForegroundColor Yellow

# Neue Dateien + geänderte Dateien
scp "prisma/schema.prisma" "${SERVER}:${APP}/prisma/schema.prisma"
scp "src/app/api/v1/taxonomy/route.ts" "${SERVER}:${APP}/src/app/api/v1/taxonomy/route.ts"
scp "src/app/api/v1/taxonomy/[id]/route.ts" "${SERVER}:${APP}/src/app/api/v1/taxonomy/[id]/route.ts"
scp "src/components/admin/icon-bar.tsx" "${SERVER}:${APP}/src/components/admin/icon-bar.tsx"
scp "src/components/admin/product-editor.tsx" "${SERVER}:${APP}/src/components/admin/product-editor.tsx"
scp "src/components/admin/taxonomy-manager.tsx" "${SERVER}:${APP}/src/components/admin/taxonomy-manager.tsx"
scp "src/app/admin/items/[id]/page.tsx" "${SERVER}:${APP}/src/app/admin/items/[id]/page.tsx"
scp "scripts/migrate-taxonomy.sql" "${SERVER}:${APP}/scripts/migrate-taxonomy.sql"

# Neues Verzeichnis + Seite auf dem Server erstellen
ssh $SERVER "mkdir -p ${APP}/src/app/admin/settings/taxonomy"
scp "src/app/admin/settings/taxonomy/page.tsx" "${SERVER}:${APP}/src/app/admin/settings/taxonomy/page.tsx"

Write-Host "[1/5] Dateien kopiert." -ForegroundColor Green

# 2. Schema pushen (neue Felder: taxRate, taxLabel)
Write-Host "[2/5] Prisma Schema pushen..." -ForegroundColor Yellow
ssh $SERVER "cd ${APP} && npx prisma db push --accept-data-loss 2>&1 | tail -5"
Write-Host "[2/5] Schema aktualisiert." -ForegroundColor Green

# 3. SQL-Migration ausführen (Umlaute + Hierarchie)
Write-Host "[3/5] SQL-Migration ausfuehren..." -ForegroundColor Yellow
ssh $SERVER "cd ${APP} && PGPASSWORD=ccTFFSJtuN7l1dC17PzT8Q psql -h 127.0.0.1 -U menucard menucard_pro -f scripts/migrate-taxonomy.sql 2>&1 | tail -20"
Write-Host "[3/5] Migration abgeschlossen." -ForegroundColor Green

# 4. Build + Restart
Write-Host "[4/5] Build + Restart..." -ForegroundColor Yellow
ssh $SERVER "cd ${APP} && npm run build 2>&1 | tail -5 && pm2 restart menucard-pro"
Write-Host "[4/5] Build + Restart fertig." -ForegroundColor Green

# 5. Verifikation
Write-Host "[5/5] Verifikation..." -ForegroundColor Yellow
ssh $SERVER "cd ${APP} && PGPASSWORD=ccTFFSJtuN7l1dC17PzT8Q psql -h 127.0.0.1 -U menucard menucard_pro -c `"SELECT type, depth, name FROM \`"TaxonomyNode\`" WHERE depth = 0 ORDER BY type, \`"sortOrder\`"`""
Write-Host ""
Write-Host "=== DEPLOYMENT ABGESCHLOSSEN ===" -ForegroundColor Green
Write-Host "Testen: https://menu.hotel-sonnblick.at/admin/settings/taxonomy" -ForegroundColor Cyan
