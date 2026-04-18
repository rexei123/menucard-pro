# deploy-phase1.ps1 - MenuCard Pro v2: Datenbank-Umbau (Phase 1)
# ================================================================
# Fuehrt auf dem Server aus:
#   1. Datenbank-Backup (pg_dump)
#   2. Alle Testdaten loeschen (in FK-Reihenfolge)
#   3. Alte Tabellen droppen (ProductPrice, ProductGroup)
#   4. schema.prisma durch v2 ersetzen
#   5. npx prisma db push
#   6. Verifizierung (Tabellen zaehlen)
# ================================================================
$ErrorActionPreference = 'Stop'

$SERVER = "root@178.104.138.177"
$APP    = "/var/www/menucard-pro"
$DB     = "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  MenuCard Pro v2 - Phase 1: Datenbank-Umbau" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# ─── SCHRITT 1: Backup ───
Write-Host "== 1. Datenbank-Backup erstellen ==" -ForegroundColor Yellow
$backupFile = "menucard-pre-v2-$(Get-Date -Format 'yyyyMMdd').sql"
ssh $SERVER "pg_dump -U menucard menucard_pro > /root/$backupFile; ls -lh /root/$backupFile"
Write-Host "  Backup: /root/$backupFile" -ForegroundColor Green
Write-Host ""

# ─── SCHRITT 2: Schema-v2 hochladen ───
Write-Host "== 2. schema-v2.prisma auf Server hochladen ==" -ForegroundColor Yellow
scp "schema-v2.prisma" "${SERVER}:${APP}/prisma/schema-v2.prisma"
Write-Host "  Hochgeladen." -ForegroundColor Green
Write-Host ""

# ─── SCHRITT 3: Alle Daten loeschen (FK-Reihenfolge) ───
Write-Host "== 3. Alle Testdaten loeschen ==" -ForegroundColor Yellow
Write-Host "  (FK-Reihenfolge beachten: Abhaengige zuerst)" -ForegroundColor Gray

$deleteSql = @"
-- DesignTemplates behalten wir (SYSTEM Templates)
-- User behalten wir (Admin-Account)
-- Tenant + Location behalten wir (Infrastruktur)

-- Schritt 3a: Abhaengige Daten zuerst
DELETE FROM "AnalyticsEvent";
DELETE FROM "TimeRule";
DELETE FROM "QRCode";

-- Schritt 3b: Menu-Struktur (von aussen nach innen)
DELETE FROM "MenuPlacement";
DELETE FROM "MenuSectionTranslation";
DELETE FROM "MenuSection";
DELETE FROM "MenuTranslation";
DELETE FROM "Menu";

-- Schritt 3c: Produkt-Abhaengigkeiten
DELETE FROM "ProductMedia";
DELETE FROM "ProductPrice";

-- Schritt 3d: Weinprofile und Getraenkedetails
DELETE FROM "ProductWineProfile";
DELETE FROM "ProductBeverageDetail";

-- Schritt 3e: Uebersetzungen und Produkte
DELETE FROM "ProductTranslation";
DELETE FROM "Product";

-- Schritt 3f: Produktgruppen
DELETE FROM "ProductGroup";

-- Schritt 3g: Stammdaten die neu geseeded werden
DELETE FROM "FillQuantity";
DELETE FROM "PriceLevel";

-- Schritt 3h: Medien (optional - koennen bleiben wenn gewuenscht)
-- DELETE FROM "Media";
"@

ssh $SERVER "psql '$DB' -c `"$($deleteSql -replace '"', '\"')`""
Write-Host "  Testdaten geloescht." -ForegroundColor Green
Write-Host ""

# ─── SCHRITT 4: Altes Schema durch v2 ersetzen ───
Write-Host "== 4. schema.prisma durch v2 ersetzen ==" -ForegroundColor Yellow
ssh $SERVER "cp $APP/prisma/schema.prisma $APP/prisma/schema.prisma.bak.v1; cp $APP/prisma/schema-v2.prisma $APP/prisma/schema.prisma; echo 'Schema ersetzt. Backup: schema.prisma.bak.v1'"
Write-Host "  Schema v2 aktiv." -ForegroundColor Green
Write-Host ""

# ─── SCHRITT 5: Prisma db push ───
Write-Host "== 5. npx prisma db push ==" -ForegroundColor Yellow
ssh $SERVER "cd $APP; npx prisma db push --accept-data-loss 2>&1"
Write-Host ""

# ─── SCHRITT 6: Prisma Client generieren ───
Write-Host "== 6. Prisma Client generieren ==" -ForegroundColor Yellow
ssh $SERVER "cd $APP; npx prisma generate 2>&1"
Write-Host ""

# ─── SCHRITT 7: Verifizierung ───
Write-Host "== 7. Verifizierung: Neue Tabellen pruefen ==" -ForegroundColor Yellow

$verifySql = @"
SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename;
"@

ssh $SERVER "psql '$DB' -c `"$verifySql`""
Write-Host ""

# Kernmodelle pruefen
$countSql = @"
SELECT 'ProductVariant' as tabelle, count(*) FROM \"ProductVariant\"
UNION ALL SELECT 'VariantPrice', count(*) FROM \"VariantPrice\"
UNION ALL SELECT 'TaxonomyNode', count(*) FROM \"TaxonomyNode\"
UNION ALL SELECT 'Allergen', count(*) FROM \"Allergen\"
UNION ALL SELECT 'ModifierGroup', count(*) FROM \"ModifierGroup\"
UNION ALL SELECT 'RecipeComponent', count(*) FROM \"RecipeComponent\"
UNION ALL SELECT 'StockLevel', count(*) FROM \"StockLevel\"
UNION ALL SELECT 'Order', count(*) FROM \"Order\"
UNION ALL SELECT 'User', count(*) FROM \"User\"
UNION ALL SELECT 'Tenant', count(*) FROM \"Tenant\"
UNION ALL SELECT 'Location', count(*) FROM \"Location\"
UNION ALL SELECT 'DesignTemplate', count(*) FROM \"DesignTemplate\";
"@

Write-Host "== 8. Kern-Tabellen Status ==" -ForegroundColor Yellow
ssh $SERVER "psql '$DB' -c `"$countSql`""

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "  Phase 1 ABGESCHLOSSEN" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Backup:     /root/$backupFile" -ForegroundColor White
Write-Host "  Alt-Schema: $APP/prisma/schema.prisma.bak.v1" -ForegroundColor White
Write-Host ""
Write-Host "  Naechster Schritt: Phase 2 (Seed v2 - Stamm- und Testdaten)" -ForegroundColor Yellow
Write-Host ""
