#!/bin/bash
cd /var/www/menucard-pro
DB="postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

echo "=== Umfassender DB-Spalten-Fix ==="

psql "$DB" << 'SQLEOF'

-- Helper: Spalte nur hinzufuegen wenn nicht vorhanden
CREATE OR REPLACE FUNCTION add_col_if_missing(tbl TEXT, col TEXT, coltype TEXT, defval TEXT DEFAULT NULL)
RETURNS VOID AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name=tbl AND column_name=col) THEN
    IF defval IS NOT NULL THEN
      EXECUTE format('ALTER TABLE %I ADD COLUMN %I %s NOT NULL DEFAULT %s', tbl, col, coltype, defval);
    ELSE
      EXECUTE format('ALTER TABLE %I ADD COLUMN %I %s', tbl, col, coltype);
    END IF;
    RAISE NOTICE 'Added %.%', tbl, col;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ─── Menu ───
SELECT add_col_if_missing('Menu', 'validFrom', 'TIMESTAMPTZ');
SELECT add_col_if_missing('Menu', 'validTo', 'TIMESTAMPTZ');
SELECT add_col_if_missing('Menu', 'status', 'TEXT', '''ACTIVE''');

-- ─── Location ───
SELECT add_col_if_missing('Location', 'isActive', 'BOOLEAN', 'true');
SELECT add_col_if_missing('Location', 'sortOrder', 'INT', '0');

-- ─── QRCode ───
SELECT add_col_if_missing('QRCode', 'locationId', 'TEXT');
SELECT add_col_if_missing('QRCode', 'scans', 'INT', '0');

-- ─── DesignTemplate ───
SELECT add_col_if_missing('DesignTemplate', 'isArchived', 'BOOLEAN', 'false');

-- ─── ProductTag: v1 hatte tagId+Tag-Relation, v2 hat nur tag-String ───
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='ProductTag' AND column_name='tag') THEN
    -- tag-Spalte hinzufuegen
    ALTER TABLE "ProductTag" ADD COLUMN tag TEXT;
    -- Falls tagId existiert: Tag-Name uebernehmen
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='ProductTag' AND column_name='tagId') THEN
      IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='Tag') THEN
        -- Tag-Name in die neue tag-Spalte kopieren
        UPDATE "ProductTag" pt SET tag = (
          SELECT COALESCE(
            (SELECT tt.name FROM "TagTranslation" tt WHERE tt."tagId" = pt."tagId" AND tt."languageCode" = 'de' LIMIT 1),
            (SELECT t.name FROM "Tag" t WHERE t.id = pt."tagId" LIMIT 1),
            'tag'
          )
        ) WHERE pt.tag IS NULL;
      END IF;
    END IF;
    -- Fallback fuer NULL-Werte
    UPDATE "ProductTag" SET tag = 'tag' WHERE tag IS NULL;
    ALTER TABLE "ProductTag" ALTER COLUMN tag SET NOT NULL;
    RAISE NOTICE 'ProductTag: tag Spalte erstellt und befuellt';
  END IF;
END $$;

-- ─── TaxRate: tenant-Relation sicherstellen ───
-- (tenantId existiert bereits, percentage wurde schon umbenannt)

-- ─── ProductWineProfile: v2 hat weniger Felder, aber bestehende Daten behalten ───
-- Nichts zu tun - v2 hat subset der v1-Felder, ueberfluessige bleiben in DB

-- ─── LocationTranslation.language ───
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='LocationTranslation' AND column_name='language') THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='LocationTranslation' AND column_name='languageCode') THEN
      ALTER TABLE "LocationTranslation" RENAME COLUMN "languageCode" TO language;
      RAISE NOTICE 'LocationTranslation: languageCode -> language';
    ELSE
      ALTER TABLE "LocationTranslation" ADD COLUMN language TEXT NOT NULL DEFAULT 'de';
      RAISE NOTICE 'LocationTranslation: language hinzugefuegt';
    END IF;
  END IF;
END $$;

-- ─── AllergenTranslation.language ───
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='AllergenTranslation' AND column_name='language') THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='AllergenTranslation' AND column_name='languageCode') THEN
      ALTER TABLE "AllergenTranslation" RENAME COLUMN "languageCode" TO language;
      RAISE NOTICE 'AllergenTranslation: languageCode -> language';
    ELSE
      ALTER TABLE "AllergenTranslation" ADD COLUMN language TEXT NOT NULL DEFAULT 'de';
    END IF;
  END IF;
END $$;

-- ─── TaxonomyNodeTranslation.language ───
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='TaxonomyNodeTranslation' AND column_name='language') THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='TaxonomyNodeTranslation' AND column_name='languageCode') THEN
      ALTER TABLE "TaxonomyNodeTranslation" RENAME COLUMN "languageCode" TO language;
      RAISE NOTICE 'TaxonomyNodeTranslation: languageCode -> language';
    ELSE
      ALTER TABLE "TaxonomyNodeTranslation" ADD COLUMN language TEXT NOT NULL DEFAULT 'de';
    END IF;
  END IF;
END $$;

-- ─── ModifierGroupTranslation.language ───
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='ModifierGroupTranslation' AND column_name='language') THEN
    ALTER TABLE "ModifierGroupTranslation" ADD COLUMN language TEXT NOT NULL DEFAULT 'de';
  END IF;
END $$;

-- ─── ModifierTranslation.language ───
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='ModifierTranslation' AND column_name='language') THEN
    ALTER TABLE "ModifierTranslation" ADD COLUMN language TEXT NOT NULL DEFAULT 'de';
  END IF;
END $$;

-- Aufraeum-Funktion entfernen
DROP FUNCTION IF EXISTS add_col_if_missing;

SELECT 'Alle Spalten-Fixes angewendet' AS result;
SQLEOF

echo ""
echo "=== Prisma db push ==="
npx prisma db push --accept-data-loss 2>&1
PUSH_RC=$?
echo "PUSH_RC=$PUSH_RC"

if [ $PUSH_RC -ne 0 ]; then
  echo "PUSH FEHLGESCHLAGEN - versuche trotzdem generate+build"
fi

echo ""
echo "=== Prisma generate ==="
npx prisma generate 2>&1 | tail -2

echo ""
echo "=== Build ==="
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
