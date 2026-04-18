#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== PHASE 1: Backup ==="
cp prisma/schema.prisma prisma/schema.prisma.v1.bak
pg_dump "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" > /root/menucard-pre-v2-schema-$(date +%Y%m%d-%H%M).sql
echo "DB-Backup erstellt"

echo ""
echo "=== PHASE 2: Bestandsaufnahme DB-Tabellen ==="
psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -t -c "
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;
"

echo ""
echo "=== PHASE 3: Prüfe v2-Tabellen in DB ==="
for table in ProductVariant VariantPrice TaxonomyNode TaxonomyNodeTranslation ProductTaxonomy ModifierGroup Modifier RecipeComponent StockLevel "Order" OrderLine OrderLineModifier; do
  count=$(psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -t -c "SELECT COUNT(*) FROM \"$table\" 2>/dev/null" 2>/dev/null || echo "NICHT VORHANDEN")
  echo "  $table: $count"
done

echo ""
echo "=== PHASE 4: Prüfe v1-Tabellen mit Daten ==="
for table in ProductGroup ProductGroupTranslation ProductPrice ProductPairing Additive AdditiveTranslation Tag TagTranslation; do
  count=$(psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -t -c "SELECT COUNT(*) FROM \"$table\" 2>/dev/null" 2>/dev/null || echo "NICHT VORHANDEN")
  echo "  $table: $count"
done

echo ""
echo "=== PHASE 5: Prüfe kritische Spaltenunterschiede ==="
echo "-- User-Tabelle (password vs passwordHash):"
psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -t -c "SELECT column_name FROM information_schema.columns WHERE table_name='User' ORDER BY ordinal_position;"

echo "-- ProductTranslation (language vs languageCode):"
psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -t -c "SELECT column_name FROM information_schema.columns WHERE table_name='ProductTranslation' ORDER BY ordinal_position;"

echo "-- MenuPlacement (variantId vs productId):"
psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -t -c "SELECT column_name FROM information_schema.columns WHERE table_name='MenuPlacement' ORDER BY ordinal_position;"

echo "-- DesignTemplate (key-Spalte):"
psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -t -c "SELECT column_name FROM information_schema.columns WHERE table_name='DesignTemplate' ORDER BY ordinal_position;"

echo "-- QRCode (locationId):"
psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -t -c "SELECT column_name FROM information_schema.columns WHERE table_name='QRCode' ORDER BY ordinal_position;"

echo "-- FillQuantity (slug, volumeMl):"
psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -t -c "SELECT column_name FROM information_schema.columns WHERE table_name='FillQuantity' ORDER BY ordinal_position;"

echo "-- PriceLevel:"
psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -t -c "SELECT column_name FROM information_schema.columns WHERE table_name='PriceLevel' ORDER BY ordinal_position;"

echo ""
echo "=== FERTIG ==="
echo "Ergebnis analysieren, dann schema.prisma anpassen und 'npx prisma db push' ausfuehren."
