#!/bin/bash
cd /var/www/menucard-pro

echo "=== 1. design/page.tsx Zeile 150-350 ==="
sed -n '150,350p' src/app/admin/design/page.tsx

echo ""
echo "=== 2. Menu.designConfig in der DB ==="
psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -c "
  SELECT m.id, m.slug, t.name as menuName,
    m.\"designConfig\"::text as config_preview
  FROM \"Menu\" m
  LEFT JOIN \"MenuTranslation\" t ON t.\"menuId\"=m.id AND t.\"languageCode\"='de'
  LIMIT 3;"

echo ""
echo "=== 3. API-Endpoint fuer Menu-Liste ==="
ls src/app/api/v1/menus/ 2>/dev/null

echo ""
echo "=== 4. API route GET Menus ==="
cat src/app/api/v1/menus/route.ts 2>/dev/null | head -50
