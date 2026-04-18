-- Legt fehlende Location-Uebersetzungen automatisch an (DE + EN)
-- Nimmt Location.name als Basis. EN-Uebersetzung = DE, bis manuell angepasst.

BEGIN;

-- DE
INSERT INTO "LocationTranslation" (id, "locationId", language, "languageCode", name, description)
SELECT
  'lt_' || substr(md5(random()::text || l.id), 1, 20),
  l.id,
  'de',
  'de',
  l.name,
  NULL
FROM "Location" l
WHERE NOT EXISTS (
  SELECT 1 FROM "LocationTranslation" lt
  WHERE lt."locationId" = l.id AND lt.language = 'de'
);

-- EN (uebernimmt DE-Name)
INSERT INTO "LocationTranslation" (id, "locationId", language, "languageCode", name, description)
SELECT
  'lt_' || substr(md5(random()::text || l.id), 1, 20),
  l.id,
  'en',
  'en',
  l.name,
  NULL
FROM "Location" l
WHERE NOT EXISTS (
  SELECT 1 FROM "LocationTranslation" lt
  WHERE lt."locationId" = l.id AND lt.language = 'en'
);

-- Verifikation
SELECT l.slug, l.name, lt.language, lt.name AS translated
FROM "Location" l
LEFT JOIN "LocationTranslation" lt ON lt."locationId" = l.id
ORDER BY l.slug, lt.language;

COMMIT;
