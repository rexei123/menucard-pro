# deploy-phase3-api.ps1 - Phase 3: API-Umbau auf v2 (Varianten-Architektur)
# =========================================================================
# Dieses Script:
#   1. Backup der bestehenden API-Dateien auf dem Server
#   2. Upload aller neuen/geaenderten API-Routes
#   3. Upload der neuen Gaeste-Ansichten (Menu + Item-Detail)
#   4. npm run build
#   5. pm2 restart
#   6. curl-Tests aller Endpoints
# =========================================================================
$ErrorActionPreference = 'Stop'

$SERVER = "root@178.104.138.177"
$APP    = "/var/www/menucard-pro"
$SRC    = "server-src/src"
$DB     = "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  Phase 3: API-Umbau auf v2 (Varianten-Architektur)" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# ─── SCHRITT 1: Backup bestehender Dateien ───
Write-Host "== 1. Backup bestehender API-Dateien ==" -ForegroundColor Yellow
$ts = Get-Date -Format "yyyyMMdd-HHmm"
ssh $SERVER "cd $APP; mkdir -p backups/phase3-$ts; cp -r src/app/api/v1/products backups/phase3-$ts/products-api-v1; cp -r src/app/api/v1/placements backups/phase3-$ts/placements-api-v1; cp -r 'src/app/(public)' backups/phase3-$ts/public-v1 2>/dev/null; echo 'Backup erstellt: backups/phase3-$ts'"
Write-Host "  Backup erstellt." -ForegroundColor Green

# ─── SCHRITT 2: Verzeichnisse auf Server anlegen ───
Write-Host "`n== 2. Verzeichnisse anlegen ==" -ForegroundColor Yellow
ssh $SERVER "cd $APP/src/app/api/v1; mkdir -p products/[id]/variants variants/[id] taxonomy"
Write-Host "  Verzeichnisse angelegt." -ForegroundColor Green

# ─── SCHRITT 3: API-Dateien hochladen ───
Write-Host "`n== 3. API-Dateien hochladen ==" -ForegroundColor Yellow

# Products API (POST + GET)
Write-Host "  -> products/route.ts"
scp "$SRC/app/api/v1/products/route.ts" "${SERVER}:${APP}/src/app/api/v1/products/route.ts"

# Products [id] API (GET + PATCH + DELETE)
Write-Host "  -> products/[id]/route.ts"
scp "$SRC/app/api/v1/products/[id]/route.ts" "${SERVER}:${APP}/src/app/api/v1/products/[id]/route.ts"

# Variants unter Produkt (POST + GET)
Write-Host "  -> products/[id]/variants/route.ts"
scp "$SRC/app/api/v1/products/[id]/variants/route.ts" "${SERVER}:${APP}/src/app/api/v1/products/[id]/variants/route.ts"

# Variants einzeln (PATCH + DELETE)
Write-Host "  -> variants/[id]/route.ts"
scp "$SRC/app/api/v1/variants/[id]/route.ts" "${SERVER}:${APP}/src/app/api/v1/variants/[id]/route.ts"

# Placements
Write-Host "  -> placements/route.ts"
scp "$SRC/app/api/v1/placements/route.ts" "${SERVER}:${APP}/src/app/api/v1/placements/route.ts"
Write-Host "  -> placements/[id]/route.ts"
scp "$SRC/app/api/v1/placements/[id]/route.ts" "${SERVER}:${APP}/src/app/api/v1/placements/[id]/route.ts"

# Taxonomy (NEU)
Write-Host "  -> taxonomy/route.ts"
scp "$SRC/app/api/v1/taxonomy/route.ts" "${SERVER}:${APP}/src/app/api/v1/taxonomy/route.ts"

Write-Host "  Alle API-Dateien hochgeladen." -ForegroundColor Green

# ─── SCHRITT 4: Gaeste-Ansichten hochladen ───
Write-Host "`n== 4. Gaeste-Ansichten hochladen ==" -ForegroundColor Yellow

Write-Host "  -> (public)/[tenant]/[location]/[menu]/page.tsx"
scp "$SRC/app/(public)/[tenant]/[location]/[menu]/page.tsx" "${SERVER}:${APP}/src/app/(public)/[tenant]/[location]/[menu]/page.tsx"

Write-Host "  -> (public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx"
scp "$SRC/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx" "${SERVER}:${APP}/src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx"

Write-Host "  Gaeste-Ansichten hochgeladen." -ForegroundColor Green

# ─── SCHRITT 5: Prisma Client generieren ───
Write-Host "`n== 5. Prisma Client generieren ==" -ForegroundColor Yellow
ssh $SERVER "cd $APP; npx prisma generate 2>&1"

# ─── SCHRITT 6: Build ───
Write-Host "`n== 6. npm run build ==" -ForegroundColor Yellow
ssh $SERVER "cd $APP; npm run build 2>&1"

# ─── SCHRITT 7: PM2 Restart ───
Write-Host "`n== 7. pm2 restart ==" -ForegroundColor Yellow
ssh $SERVER "pm2 restart menucard-pro 2>&1"
Start-Sleep -Seconds 3

# ─── SCHRITT 8: Verifikation ───
Write-Host "`n== 8. Verifikation ==" -ForegroundColor Yellow

Write-Host "  [DB] Datenstand pruefen..."
$verifySql = @"
SELECT 'Products' as entity, count(*) FROM "Product"
UNION ALL SELECT 'ProductVariants', count(*) FROM "ProductVariant"
UNION ALL SELECT 'VariantPrices', count(*) FROM "VariantPrice"
UNION ALL SELECT 'MenuPlacements', count(*) FROM "MenuPlacement"
UNION ALL SELECT 'TaxonomyNodes', count(*) FROM "TaxonomyNode"
UNION ALL SELECT 'Allergens', count(*) FROM "Allergen"
UNION ALL SELECT 'Menus', count(*) FROM "Menu";
"@
ssh $SERVER "psql '$DB' -c `"$verifySql`""

Write-Host ""
Write-Host "  [API] Endpoints testen..."
Write-Host "  -> GET /api/v1/menus"
ssh $SERVER "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/api/v1/menus"
Write-Host ""

Write-Host "  -> GET /api/v1/taxonomy?type=CATEGORY"
ssh $SERVER "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/api/v1/taxonomy?type=CATEGORY"
Write-Host ""

Write-Host ""
Write-Host "  [PAGE] Gaeste-Ansicht testen..."
Write-Host "  -> GET /hotel-sonnblick/restaurant/abendkarte"
ssh $SERVER "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/restaurant/abendkarte"
Write-Host ""

Write-Host "  -> GET /hotel-sonnblick/restaurant/weinkarte"
ssh $SERVER "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/restaurant/weinkarte"
Write-Host ""

Write-Host "  -> GET /hotel-sonnblick/bar/barkarte"
ssh $SERVER "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/bar/barkarte"
Write-Host ""

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "  Phase 3 API-Umbau ABGESCHLOSSEN" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Zusammenfassung der neuen Endpoints:" -ForegroundColor Yellow
Write-Host "    GET    /api/v1/products          (Alle Produkte + Varianten)"
Write-Host "    POST   /api/v1/products          (Neues Produkt + Default-Variante)"
Write-Host "    GET    /api/v1/products/:id       (Einzelprodukt)"
Write-Host "    PATCH  /api/v1/products/:id       (Produkt bearbeiten)"
Write-Host "    DELETE /api/v1/products/:id       (Produkt loeschen)"
Write-Host "    GET    /api/v1/products/:id/variants  (Varianten eines Produkts)"
Write-Host "    POST   /api/v1/products/:id/variants  (Neue Variante)"
Write-Host "    PATCH  /api/v1/variants/:id       (Variante bearbeiten)"
Write-Host "    DELETE /api/v1/variants/:id       (Variante loeschen)"
Write-Host "    POST   /api/v1/placements         (Platzierung, v1+v2 kompatibel)"
Write-Host "    PATCH  /api/v1/placements/:id     (Platzierung bearbeiten)"
Write-Host "    DELETE /api/v1/placements/:id     (Platzierung entfernen)"
Write-Host "    GET    /api/v1/taxonomy           (Taxonomie-Baum)"
Write-Host "    POST   /api/v1/taxonomy           (Neuer Taxonomie-Knoten)"
Write-Host ""
Write-Host "  Naechster Schritt: Phase 4 (Admin-UI-Umbau)" -ForegroundColor Yellow
Write-Host ""
