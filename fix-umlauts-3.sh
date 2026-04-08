#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Fixing Umlaute (Code + DB) ==="

# 1. Fix UI labels in item detail page
echo "1/3 Fixing code labels..."
sed -i "s/Zurueck zur Karte/Zurück zur Karte/g" "src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx"
sed -i "s/Koerper/Körper/g" "src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx"
sed -i "s/Suesse/Süße/g" "src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx"
sed -i "s/Flaschengroesse/Flaschengröße/g" "src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx"
sed -i "s/Weisswein/Weißwein/g" "src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx"
sed -i "s/Likoerwein/Likörwein/g" "src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx"
sed -i "s/Oesterreichischer/Österreichischer/g" "src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx"
sed -i "s/Rose'/Rosé'/g" "src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx"
sed -i "s/Suess/Süß/g" "src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx"

# 2. Fix remaining DB umlauts
echo "2/3 Fixing DB..."
psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" << 'EOSQL'
UPDATE "WineProfile" SET winery = REPLACE(winery, 'Domaene', 'Domäne') WHERE winery LIKE '%Domaene%';
UPDATE "WineProfile" SET region = REPLACE(region, 'Duernstein', 'Dürnstein') WHERE region LIKE '%Duernstein%';
UPDATE "MenuItemTranslation" SET "shortDescription" = REPLACE("shortDescription", 'Domaene', 'Domäne') WHERE "shortDescription" LIKE '%Domaene%';
UPDATE "MenuItemTranslation" SET "shortDescription" = REPLACE("shortDescription", 'Duernstein', 'Dürnstein') WHERE "shortDescription" LIKE '%Duernstein%';
UPDATE "MenuItemTranslation" SET "longDescription" = REPLACE("longDescription", 'Wiesenkraeuter', 'Wiesenkräuter') WHERE "longDescription" LIKE '%Wiesenkraeuter%';
UPDATE "MenuItemTranslation" SET "longDescription" = REPLACE("longDescription", 'Domaene', 'Domäne') WHERE "longDescription" LIKE '%Domaene%';
UPDATE "MenuItemTranslation" SET "longDescription" = REPLACE("longDescription", 'Duernstein', 'Dürnstein') WHERE "longDescription" LIKE '%Duernstein%';
SELECT 'DB fix done!' AS status;
EOSQL

# 3. Rebuild
echo "3/3 Building..."
npm run build && pm2 restart menucard-pro

echo "=== Done! ==="
