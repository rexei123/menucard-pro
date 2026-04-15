#!/usr/bin/env bash
# MenuCard Pro — Pass 6 (14.04.2026)
# B-2 final: Preisformat in MenuTranslation.description vereinheitlichen
set -uo pipefail
export PGPASSWORD='ccTFFSJtuN7l1dC17PzT8Q'

echo "### B-2: MenuTranslation.description — Preisformat ###"
echo ""
echo "--- Vorher (alle Descriptions mit Euro-Preis) ---"
psql -U menucard -h 127.0.0.1 -d menucard_pro <<'SQL'
SELECT "languageCode", description
FROM "MenuTranslation"
WHERE description ~ '€\s*[0-9]+[.,][0-9]{2}'
ORDER BY description;
SQL

echo ""
echo "--- SQL-Update (nur DE, en-Format bleibt mit Punkt) ---"
psql -U menucard -h 127.0.0.1 -d menucard_pro <<'SQL'
BEGIN;

-- DE: Punkt -> Komma bei Euro-Preisen
UPDATE "MenuTranslation"
SET description = regexp_replace(
  description,
  '(€\s*[0-9]+)\.([0-9]{2})',
  '\1,\2',
  'g'
)
WHERE "languageCode" = 'de'
  AND description ~ '€\s*[0-9]+\.[0-9]{2}';

-- EN: Komma -> Punkt (Konsistenz)
UPDATE "MenuTranslation"
SET description = regexp_replace(
  description,
  '(€\s*[0-9]+),([0-9]{2})',
  '\1.\2',
  'g'
)
WHERE "languageCode" = 'en'
  AND description ~ '€\s*[0-9]+,[0-9]{2}';

-- Kontrolle
SELECT "languageCode", description
FROM "MenuTranslation"
WHERE description ~ '€\s*[0-9]+[.,][0-9]{2}'
ORDER BY "languageCode", description;

COMMIT;
SQL

echo ""
echo "### Verifikation via curl ###"
curl -s 'https://menu.hotel-sonnblick.at/hotel-sonnblick/restaurant' \
  | grep -oE "€\s?[0-9]+[.,][0-9]{2}" | sort | uniq -c | sort -rn

echo ""
echo "### Re-Test Playwright ###"
cd /tmp && BASE_URL=https://menu.hotel-sonnblick.at node playwright-guest-tests.mjs 2>&1 | tail -15
