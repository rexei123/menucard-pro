#!/bin/bash
cd /var/www/menucard-pro
DB="postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

echo "=== Komplette DB-Migration v1→v2 ==="

psql "$DB" << 'SQLEOF'
BEGIN;

-- ─── DesignTemplate.key (required, unique) ───
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='DesignTemplate' AND column_name='key') THEN
    ALTER TABLE "DesignTemplate" ADD COLUMN key TEXT;
    -- key aus baseType oder name ableiten
    UPDATE "DesignTemplate" SET key = COALESCE("baseType", LOWER(REPLACE(name, ' ', '-')));
    ALTER TABLE "DesignTemplate" ALTER COLUMN key SET NOT NULL;
    -- Unique-Index erstellen
    CREATE UNIQUE INDEX IF NOT EXISTS "DesignTemplate_key_key" ON "DesignTemplate"(key);
    RAISE NOTICE 'DesignTemplate.key erstellt';
  END IF;
END $$;

-- ─── FillQuantity.slug (required) ───
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='FillQuantity' AND column_name='slug') THEN
    ALTER TABLE "FillQuantity" ADD COLUMN slug TEXT;
    UPDATE "FillQuantity" SET slug = LOWER(REGEXP_REPLACE(REPLACE(REPLACE(REPLACE(label, 'ä', 'ae'), 'ö', 'oe'), 'ü', 'ue'), '[^a-z0-9]+', '-', 'g'));
    ALTER TABLE "FillQuantity" ALTER COLUMN slug SET NOT NULL;
    RAISE NOTICE 'FillQuantity.slug erstellt';
  END IF;
END $$;

-- ─── FillQuantity: volume -> volumeMl ───
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='FillQuantity' AND column_name='volume')
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='FillQuantity' AND column_name='volumeMl') THEN
    ALTER TABLE "FillQuantity" RENAME COLUMN volume TO "volumeMl";
    RAISE NOTICE 'FillQuantity: volume -> volumeMl';
  ELSIF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='FillQuantity' AND column_name='volumeMl') THEN
    ALTER TABLE "FillQuantity" ADD COLUMN "volumeMl" INT;
  END IF;
END $$;

-- ─── Menu.type: Enum -> Text ───
DO $$ BEGIN
  -- Pruefen ob type eine Enum-Spalte ist
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Menu' AND column_name='type' AND udt_name != 'text') THEN
    ALTER TABLE "Menu" ALTER COLUMN type TYPE TEXT USING type::TEXT;
    RAISE NOTICE 'Menu.type zu TEXT konvertiert';
  END IF;
END $$;

-- ─── MenuPlacement: menuSectionId -> sectionId, productId -> variantId ───
DO $$ BEGIN
  -- sectionId hinzufuegen/migrieren
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='MenuPlacement' AND column_name='sectionId') THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='MenuPlacement' AND column_name='menuSectionId') THEN
      ALTER TABLE "MenuPlacement" RENAME COLUMN "menuSectionId" TO "sectionId";
      RAISE NOTICE 'MenuPlacement: menuSectionId -> sectionId';
    ELSE
      ALTER TABLE "MenuPlacement" ADD COLUMN "sectionId" TEXT;
    END IF;
  END IF;

  -- variantId hinzufuegen/migrieren
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='MenuPlacement' AND column_name='variantId') THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='MenuPlacement' AND column_name='productId') THEN
      -- productId -> default variantId migrieren
      ALTER TABLE "MenuPlacement" ADD COLUMN "variantId" TEXT;
      UPDATE "MenuPlacement" mp SET "variantId" = (
        SELECT pv.id FROM "ProductVariant" pv
        WHERE pv."productId" = mp."productId" AND pv."isDefault" = true
        LIMIT 1
      );
      -- Fallback: erste Variante
      UPDATE "MenuPlacement" mp SET "variantId" = (
        SELECT pv.id FROM "ProductVariant" pv
        WHERE pv."productId" = mp."productId"
        ORDER BY pv."sortOrder" ASC LIMIT 1
      ) WHERE mp."variantId" IS NULL AND mp."productId" IS NOT NULL;
      RAISE NOTICE 'MenuPlacement: productId -> variantId migriert';
    ELSE
      ALTER TABLE "MenuPlacement" ADD COLUMN "variantId" TEXT;
    END IF;
  END IF;
END $$;

-- sectionId + variantId NOT NULL setzen (nur wenn Daten da)
UPDATE "MenuPlacement" SET "sectionId" = 'UNKNOWN' WHERE "sectionId" IS NULL;
UPDATE "MenuPlacement" SET "variantId" = 'UNKNOWN' WHERE "variantId" IS NULL;
ALTER TABLE "MenuPlacement" ALTER COLUMN "sectionId" SET NOT NULL;
ALTER TABLE "MenuPlacement" ALTER COLUMN "variantId" SET NOT NULL;

-- ─── MenuPlacement.highlightType: NULL -> NONE ───
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='MenuPlacement' AND column_name='highlightType') THEN
    UPDATE "MenuPlacement" SET "highlightType" = 'NONE' WHERE "highlightType" IS NULL;
    ALTER TABLE "MenuPlacement" ALTER COLUMN "highlightType" SET NOT NULL;
    ALTER TABLE "MenuPlacement" ALTER COLUMN "highlightType" SET DEFAULT 'NONE';
    RAISE NOTICE 'MenuPlacement.highlightType NULL->NONE';
  ELSE
    ALTER TABLE "MenuPlacement" ADD COLUMN "highlightType" TEXT NOT NULL DEFAULT 'NONE';
  END IF;
END $$;

-- ─── MenuPlacement.channels ───
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='MenuPlacement' AND column_name='channels') THEN
    ALTER TABLE "MenuPlacement" ADD COLUMN channels TEXT[] DEFAULT '{DIGITAL,PRINT}';
    RAISE NOTICE 'MenuPlacement.channels hinzugefuegt';
  END IF;
END $$;

-- ─── Product.highlightType: NULL -> NONE ───
UPDATE "Product" SET "highlightType" = 'NONE' WHERE "highlightType" IS NULL;
ALTER TABLE "Product" ALTER COLUMN "highlightType" SET NOT NULL;
ALTER TABLE "Product" ALTER COLUMN "highlightType" SET DEFAULT 'NONE';

-- ─── ProductTag: v1 -> v2 (tagId -> tag string) ───
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='ProductTag' AND column_name='tag') THEN
    ALTER TABLE "ProductTag" ADD COLUMN tag TEXT NOT NULL DEFAULT 'tag';
    RAISE NOTICE 'ProductTag.tag hinzugefuegt (default)';
  END IF;
  -- id sicherstellen (v1 hatte composite PK)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='ProductTag' AND column_name='id') THEN
    ALTER TABLE "ProductTag" ADD COLUMN id TEXT DEFAULT gen_random_uuid()::TEXT;
    UPDATE "ProductTag" SET id = gen_random_uuid()::TEXT WHERE id IS NULL;
    ALTER TABLE "ProductTag" ALTER COLUMN id SET NOT NULL;
    RAISE NOTICE 'ProductTag.id hinzugefuegt';
  END IF;
END $$;

-- ─── Unique-Constraints aktualisieren ───
-- MenuPlacement: sectionId_variantId statt menuSectionId_productId
DROP INDEX IF EXISTS "MenuPlacement_menuSectionId_productId_key";
CREATE UNIQUE INDEX IF NOT EXISTS "MenuPlacement_sectionId_variantId_key" ON "MenuPlacement"("sectionId", "variantId");

-- FillQuantity: tenantId_slug
CREATE UNIQUE INDEX IF NOT EXISTS "FillQuantity_tenantId_slug_key" ON "FillQuantity"("tenantId", slug);

COMMIT;
SELECT 'Migration erfolgreich' AS result;
SQLEOF

echo ""
echo "=== Prisma db push ==="
npx prisma db push --accept-data-loss 2>&1
echo "PUSH=$?"

echo ""
echo "=== Generate + Build ==="
npx prisma generate 2>&1 | tail -2
npm run build 2>&1 | tail -5
echo "BUILD=$?"

echo ""
echo "=== Restart + Test ==="
pm2 restart menucard-pro
sleep 5
echo -n "  menus="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/api/v1/menus; echo
echo -n "  abendkarte="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/restaurant/abendkarte; echo
echo -n "  weinkarte="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/restaurant/weinkarte; echo
echo -n "  barkarte="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/bar/barkarte; echo
echo -n "  admin="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/admin; echo
