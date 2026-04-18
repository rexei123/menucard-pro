-- Repariert den bekannten Theme.config-NULL-Bug
-- Schema definiert Theme.config als Json (NOT NULL), DB hat aber NULL-Werte.
-- Alle Null-Configs werden auf leeres JSON-Objekt gesetzt.

BEGIN;

UPDATE "Theme" SET "config" = '{}'::jsonb WHERE "config" IS NULL;

-- Gleiches Problem vorbeugend auch fuer Menu und Location checken,
-- falls die designConfig-Felder irgendwo auf NOT NULL gesetzt wurden.
-- (laut Schema sind sie optional, daher sollte das kein NOOP sein)
SELECT
  (SELECT COUNT(*) FROM "Theme"    WHERE "config"       IS NULL) AS theme_null,
  (SELECT COUNT(*) FROM "Theme")                                 AS theme_total;

COMMIT;
