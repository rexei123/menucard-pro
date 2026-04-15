#!/bin/bash
cd /var/www/menucard-pro

echo "=== 1. DB Section-Icons (aus MenuSection + Translation) ==="
psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -c "
  SELECT t.name, s.icon, s.slug
  FROM \"MenuSection\" s
  LEFT JOIN \"MenuSectionTranslation\" t ON t.\"sectionId\"=s.id AND t.\"languageCode\"='de'
  LIMIT 30;"

echo ""
echo "=== 2. menu-editor.tsx Zeilen die 'icon' erwaehnen ==="
grep -n "icon" src/components/admin/menu-editor.tsx

echo ""
echo "=== 3. menu-editor.tsx Zeilen 50-200 (Sektions-Rendering) ==="
sed -n '50,200p' src/components/admin/menu-editor.tsx | cat -n

echo ""
echo "=== 4. Seiten-Route fuer /admin/menus/[id] ==="
find src/app/admin/menus -type f -name "*.tsx" | head

echo ""
echo "=== 5. Hochgeladene Menu-Editor-Page-Datei ==="
ls -la src/app/admin/menus/\[id\]/ 2>/dev/null
