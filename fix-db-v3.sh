#!/bin/bash
cd /var/www/menucard-pro
DB="postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

echo "=== DB-Migration v1→v2 (ohne Transaktion) ==="

# Jeder Block einzeln, damit ein Fehler nicht alles blockiert

echo "-- 1. DesignTemplate.key"
psql "$DB" -c "
DO \$\$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='DesignTemplate' AND column_name='key') THEN
    ALTER TABLE \"DesignTemplate\" ADD COLUMN key TEXT;
  END IF;
  -- Unique keys generieren: baseType oder name-basiert, mit ID-Suffix bei Duplikaten
  UPDATE \"DesignTemplate\" SET key = COALESCE(\"baseType\", LOWER(REPLACE(name, ' ', '-'))) WHERE key IS NULL;
  -- Duplikate auflösen: ID-Suffix anhaengen
  UPDATE \"DesignTemplate\" dt SET key = key || '-' || SUBSTRING(id, 1, 6)
  WHERE id IN (
    SELECT id FROM (
      SELECT id, key, ROW_NUMBER() OVER (PARTITION BY key ORDER BY \"createdAt\") AS rn
      FROM \"DesignTemplate\"
    ) sub WHERE rn > 1
  );
  ALTER TABLE \"DesignTemplate\" ALTER COLUMN key SET NOT NULL;
  DROP INDEX IF EXISTS \"DesignTemplate_key_key\";
  CREATE UNIQUE INDEX \"DesignTemplate_key_key\" ON \"DesignTemplate\"(key);
  RAISE NOTICE 'DesignTemplate.key OK';
END \$\$;
"

echo "-- 2. FillQuantity.slug"
psql "$DB" -c "
DO \$\$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='FillQuantity' AND column_name='slug') THEN
    ALTER TABLE \"FillQuantity\" ADD COLUMN slug TEXT;
  END IF;
  UPDATE \"FillQuantity\" SET slug = LOWER(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(label, 'ä', 'ae'), 'ö', 'oe'), 'ü', 'ue'), '[^a-z0-9]+', '-', 'g')) WHERE slug IS NULL;
  -- Duplikate: Suffix
  UPDATE \"FillQuantity\" f SET slug = slug || '-' || SUBSTRING(id, 1, 6)
  WHERE id IN (SELECT id FROM (SELECT id, slug, ROW_NUMBER() OVER (PARTITION BY slug ORDER BY \"sortOrder\") AS rn FROM \"FillQuantity\") s WHERE rn > 1);
  ALTER TABLE \"FillQuantity\" ALTER COLUMN slug SET NOT NULL;
  RAISE NOTICE 'FillQuantity.slug OK';
END \$\$;
"

echo "-- 3. FillQuantity.volumeMl"
psql "$DB" -c "
DO \$\$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='FillQuantity' AND column_name='volume')
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='FillQuantity' AND column_name='volumeMl') THEN
    ALTER TABLE \"FillQuantity\" RENAME COLUMN volume TO \"volumeMl\";
  ELSIF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='FillQuantity' AND column_name='volumeMl') THEN
    ALTER TABLE \"FillQuantity\" ADD COLUMN \"volumeMl\" INT;
  END IF;
END \$\$;
"

echo "-- 4. Menu.type -> TEXT"
psql "$DB" -c "
DO \$\$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Menu' AND column_name='type' AND udt_name != 'text') THEN
    ALTER TABLE \"Menu\" ALTER COLUMN type TYPE TEXT USING type::TEXT;
    RAISE NOTICE 'Menu.type -> TEXT';
  END IF;
END \$\$;
"

echo "-- 5. MenuPlacement: sectionId + variantId"
psql "$DB" -c "
DO \$\$ BEGIN
  -- sectionId
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='MenuPlacement' AND column_name='sectionId') THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='MenuPlacement' AND column_name='menuSectionId') THEN
      ALTER TABLE \"MenuPlacement\" RENAME COLUMN \"menuSectionId\" TO \"sectionId\";
    ELSE
      ALTER TABLE \"MenuPlacement\" ADD COLUMN \"sectionId\" TEXT NOT NULL DEFAULT 'UNKNOWN';
    END IF;
  END IF;
  -- variantId
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='MenuPlacement' AND column_name='variantId') THEN
    ALTER TABLE \"MenuPlacement\" ADD COLUMN \"variantId\" TEXT;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='MenuPlacement' AND column_name='productId') THEN
      UPDATE \"MenuPlacement\" mp SET \"variantId\" = (SELECT pv.id FROM \"ProductVariant\" pv WHERE pv.\"productId\" = mp.\"productId\" AND pv.\"isDefault\" = true LIMIT 1);
      UPDATE \"MenuPlacement\" mp SET \"variantId\" = (SELECT pv.id FROM \"ProductVariant\" pv WHERE pv.\"productId\" = mp.\"productId\" ORDER BY pv.\"sortOrder\" LIMIT 1) WHERE mp.\"variantId\" IS NULL;
    END IF;
    UPDATE \"MenuPlacement\" SET \"variantId\" = 'UNKNOWN' WHERE \"variantId\" IS NULL;
    ALTER TABLE \"MenuPlacement\" ALTER COLUMN \"variantId\" SET NOT NULL;
  END IF;
  RAISE NOTICE 'MenuPlacement sectionId+variantId OK';
END \$\$;
"

echo "-- 6. MenuPlacement.highlightType NULL->NONE"
psql "$DB" -c "
UPDATE \"MenuPlacement\" SET \"highlightType\" = 'NONE' WHERE \"highlightType\" IS NULL;
ALTER TABLE \"MenuPlacement\" ALTER COLUMN \"highlightType\" SET NOT NULL;
ALTER TABLE \"MenuPlacement\" ALTER COLUMN \"highlightType\" SET DEFAULT 'NONE';
"

echo "-- 7. MenuPlacement.channels"
psql "$DB" -c "
DO \$\$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='MenuPlacement' AND column_name='channels') THEN
    ALTER TABLE \"MenuPlacement\" ADD COLUMN channels TEXT[] DEFAULT '{DIGITAL,PRINT}';
  END IF;
END \$\$;
"

echo "-- 8. Product.highlightType NULL->NONE"
psql "$DB" -c "
UPDATE \"Product\" SET \"highlightType\" = 'NONE' WHERE \"highlightType\" IS NULL;
ALTER TABLE \"Product\" ALTER COLUMN \"highlightType\" SET NOT NULL;
ALTER TABLE \"Product\" ALTER COLUMN \"highlightType\" SET DEFAULT 'NONE';
"

echo "-- 9. ProductTag v1->v2"
psql "$DB" -c "
DO \$\$ BEGIN
  -- tag-Spalte
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='ProductTag' AND column_name='tag') THEN
    ALTER TABLE \"ProductTag\" ADD COLUMN tag TEXT NOT NULL DEFAULT 'tag';
  END IF;
  -- id-Spalte (v1 hatte composite PK)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='ProductTag' AND column_name='id') THEN
    ALTER TABLE \"ProductTag\" ADD COLUMN id TEXT;
    UPDATE \"ProductTag\" SET id = gen_random_uuid()::TEXT WHERE id IS NULL;
    ALTER TABLE \"ProductTag\" ALTER COLUMN id SET NOT NULL;
    ALTER TABLE \"ProductTag\" ALTER COLUMN id SET DEFAULT gen_random_uuid()::TEXT;
  END IF;
END \$\$;
"

echo "-- 10. Unique Indexes"
psql "$DB" -c "
DROP INDEX IF EXISTS \"MenuPlacement_menuSectionId_productId_key\";
CREATE UNIQUE INDEX IF NOT EXISTS \"MenuPlacement_sectionId_variantId_key\" ON \"MenuPlacement\"(\"sectionId\", \"variantId\");
CREATE UNIQUE INDEX IF NOT EXISTS \"FillQuantity_tenantId_slug_key\" ON \"FillQuantity\"(\"tenantId\", slug);
"

echo ""
echo "=== Prisma db push ==="
npx prisma db push --accept-data-loss 2>&1
echo "PUSH=$?"

echo ""
echo "=== Generate + Build + Restart ==="
npx prisma generate 2>&1 | tail -2
npm run build 2>&1 | tail -5
echo "BUILD=$?"
pm2 restart menucard-pro
sleep 5

echo ""
echo "=== TEST ==="
for url in "api/v1/menus" "hotel-sonnblick/restaurant/abendkarte" "hotel-sonnblick/restaurant/weinkarte" "hotel-sonnblick/bar/barkarte" "admin"; do
  echo -n "  $url = "; curl -s -o /dev/null -w '%{http_code}' "http://localhost:3000/$url"; echo
done
