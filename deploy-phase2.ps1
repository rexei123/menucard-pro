# deploy-phase2.ps1 - MenuCard Pro v2: Seed-Daten (Phase 2)
# ============================================================
# Fuehrt auf dem Server aus:
#   1. seed-v2.ts hochladen
#   2. npx tsx seed-v2.ts ausfuehren
#   3. Datenstand verifizieren
# ============================================================
$ErrorActionPreference = 'Stop'

$SERVER = "root@178.104.138.177"
$APP    = "/var/www/menucard-pro"
$DB     = "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  MenuCard Pro v2 - Phase 2: Seed v2" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# ─── SCHRITT 1: Seed-Script hochladen ───
Write-Host "== 1. seed-v2.ts auf Server hochladen ==" -ForegroundColor Yellow
scp "seed-v2.ts" "${SERVER}:${APP}/seed-v2.ts"
Write-Host "  Hochgeladen." -ForegroundColor Green
Write-Host ""

# ─── SCHRITT 2: Seed ausfuehren ───
Write-Host "== 2. Seed-Script ausfuehren ==" -ForegroundColor Yellow
ssh $SERVER "cd $APP; npx tsx seed-v2.ts 2>&1"
Write-Host ""

# ─── SCHRITT 3: Verifizierung ───
Write-Host "== 3. Datenstand verifizieren ==" -ForegroundColor Yellow

$countSql = @"
SELECT 'Product' as entity, count(*) as anzahl FROM \"Product\"
UNION ALL SELECT 'ProductVariant', count(*) FROM \"ProductVariant\"
UNION ALL SELECT 'VariantPrice', count(*) FROM \"VariantPrice\"
UNION ALL SELECT 'ProductTranslation', count(*) FROM \"ProductTranslation\"
UNION ALL SELECT 'ProductWineProfile', count(*) FROM \"ProductWineProfile\"
UNION ALL SELECT 'ProductBeverageDetail', count(*) FROM \"ProductBeverageDetail\"
UNION ALL SELECT 'ProductTaxonomy', count(*) FROM \"ProductTaxonomy\"
UNION ALL SELECT 'ProductAllergen', count(*) FROM \"ProductAllergen\"
UNION ALL SELECT 'TaxonomyNode', count(*) FROM \"TaxonomyNode\"
UNION ALL SELECT 'Allergen', count(*) FROM \"Allergen\"
UNION ALL SELECT 'PriceLevel', count(*) FROM \"PriceLevel\"
UNION ALL SELECT 'FillQuantity', count(*) FROM \"FillQuantity\"
UNION ALL SELECT 'TaxRate', count(*) FROM \"TaxRate\"
UNION ALL SELECT 'Menu', count(*) FROM \"Menu\"
UNION ALL SELECT 'MenuSection', count(*) FROM \"MenuSection\"
UNION ALL SELECT 'MenuPlacement', count(*) FROM \"MenuPlacement\"
UNION ALL SELECT 'QRCode', count(*) FROM \"QRCode\"
UNION ALL SELECT 'User', count(*) FROM \"User\"
UNION ALL SELECT 'Tenant', count(*) FROM \"Tenant\"
UNION ALL SELECT 'Location', count(*) FROM \"Location\"
UNION ALL SELECT 'DesignTemplate', count(*) FROM \"DesignTemplate\"
ORDER BY entity;
"@

ssh $SERVER "psql '$DB' -c `"$countSql`""

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "  Phase 2 ABGESCHLOSSEN" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Naechster Schritt: Phase 3 (API-Umbau)" -ForegroundColor Yellow
Write-Host ""
