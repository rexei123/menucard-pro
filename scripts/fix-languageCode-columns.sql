-- Stellt sicher, dass in allen Translation-Tabellen die languageCode-Spalte existiert
-- und befüllt sie mit dem language-Wert (Backwards-Compat mit Prisma-Client v2)

BEGIN;

ALTER TABLE "LocationTranslation"    ADD COLUMN IF NOT EXISTS "languageCode" TEXT;
ALTER TABLE "MenuTranslation"        ADD COLUMN IF NOT EXISTS "languageCode" TEXT;
ALTER TABLE "MenuSectionTranslation" ADD COLUMN IF NOT EXISTS "languageCode" TEXT;
ALTER TABLE "ProductTranslation"     ADD COLUMN IF NOT EXISTS "languageCode" TEXT;

UPDATE "LocationTranslation"    SET "languageCode" = "language" WHERE "languageCode" IS NULL;
UPDATE "MenuTranslation"        SET "languageCode" = "language" WHERE "languageCode" IS NULL;
UPDATE "MenuSectionTranslation" SET "languageCode" = "language" WHERE "languageCode" IS NULL;
UPDATE "ProductTranslation"     SET "languageCode" = "language" WHERE "languageCode" IS NULL;

-- Verifikation
SELECT 'LocationTranslation'    AS tbl, COUNT(*) AS rows, COUNT("languageCode") AS filled FROM "LocationTranslation"
UNION ALL SELECT 'MenuTranslation',        COUNT(*), COUNT("languageCode") FROM "MenuTranslation"
UNION ALL SELECT 'MenuSectionTranslation', COUNT(*), COUNT("languageCode") FROM "MenuSectionTranslation"
UNION ALL SELECT 'ProductTranslation',     COUNT(*), COUNT("languageCode") FROM "ProductTranslation";

COMMIT;
