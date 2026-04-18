#!/bin/bash
cd /var/www/menucard-pro
DB="postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

echo "=== 1. Trigger: languageCode = language automatisch setzen ==="
psql "$DB" << 'SQLEOF'
-- Funktion fuer alle Translation-Tabellen
CREATE OR REPLACE FUNCTION sync_language_code() RETURNS TRIGGER AS $$
BEGIN
  NEW."languageCode" := NEW.language;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger auf ProductTranslation
DROP TRIGGER IF EXISTS trg_product_translation_langcode ON "ProductTranslation";
CREATE TRIGGER trg_product_translation_langcode
  BEFORE INSERT OR UPDATE ON "ProductTranslation"
  FOR EACH ROW EXECUTE FUNCTION sync_language_code();

-- Trigger auf MenuTranslation
DROP TRIGGER IF EXISTS trg_menu_translation_langcode ON "MenuTranslation";
CREATE TRIGGER trg_menu_translation_langcode
  BEFORE INSERT OR UPDATE ON "MenuTranslation"
  FOR EACH ROW EXECUTE FUNCTION sync_language_code();

-- Trigger auf MenuSectionTranslation
DROP TRIGGER IF EXISTS trg_section_translation_langcode ON "MenuSectionTranslation";
CREATE TRIGGER trg_section_translation_langcode
  BEFORE INSERT OR UPDATE ON "MenuSectionTranslation"
  FOR EACH ROW EXECUTE FUNCTION sync_language_code();

SELECT 'Trigger erstellt' AS result;
SQLEOF

echo ""
echo "=== 2. Bestehende Daten loeschen (Seed laeuft dann sauber) ==="
psql "$DB" << 'SQLEOF'
-- Reihenfolge beachten (FK-Constraints)
DELETE FROM "MenuPlacement";
DELETE FROM "MenuSectionTranslation";
DELETE FROM "MenuSection";
DELETE FROM "MenuTranslation";
DELETE FROM "Menu";
DELETE FROM "VariantPrice";
DELETE FROM "ProductVariant";
DELETE FROM "ProductTaxonomy";
DELETE FROM "ProductAllergen";
DELETE FROM "ProductTag";
DELETE FROM "ProductMedia";
DELETE FROM "ProductCustomFieldValue";
DELETE FROM "ProductWineProfile";
DELETE FROM "ProductBeverageDetail";
DELETE FROM "ProductTranslation";
DELETE FROM "Product";
DELETE FROM "QRCode";
DELETE FROM "DesignTemplate";
SELECT 'Daten geloescht' AS result;
SQLEOF

echo ""
echo "=== 3. Seed v2 ausfuehren ==="
npx tsx scripts/seed-v2.ts 2>&1
echo "SEED=$?"

echo ""
echo "=== 4. languageCode synchronisieren ==="
psql "$DB" -c "UPDATE \"ProductTranslation\" SET \"languageCode\" = language WHERE \"languageCode\" != language;"
psql "$DB" -c "UPDATE \"MenuTranslation\" SET \"languageCode\" = language WHERE \"languageCode\" != language;"
psql "$DB" -c "UPDATE \"MenuSectionTranslation\" SET \"languageCode\" = language WHERE \"languageCode\" != language;"

echo ""
echo "=== 5. Restart + Test ==="
pm2 restart menucard-pro
sleep 5
for url in "api/v1/menus" "hotel-sonnblick/restaurant/abendkarte" "hotel-sonnblick/restaurant/weinkarte" "hotel-sonnblick/bar/barkarte" "admin"; do
  echo -n "  $url = "; curl -s -o /dev/null -w '%{http_code}' "http://localhost:3000/$url"; echo
done

echo ""
echo "=== 6. Datenstand ==="
psql "$DB" -c "
SELECT 'Products' as entity, count(*) FROM \"Product\"
UNION ALL SELECT 'Variants', count(*) FROM \"ProductVariant\"
UNION ALL SELECT 'VariantPrices', count(*) FROM \"VariantPrice\"
UNION ALL SELECT 'Menus', count(*) FROM \"Menu\"
UNION ALL SELECT 'Sections', count(*) FROM \"MenuSection\"
UNION ALL SELECT 'Placements', count(*) FROM \"MenuPlacement\"
UNION ALL SELECT 'Taxonomy', count(*) FROM \"TaxonomyNode\"
UNION ALL SELECT 'Allergens', count(*) FROM \"Allergen\"
UNION ALL SELECT 'QRCodes', count(*) FROM \"QRCode\"
UNION ALL SELECT 'Templates', count(*) FROM \"DesignTemplate\"
ORDER BY 1;
"
