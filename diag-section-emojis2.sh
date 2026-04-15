#!/bin/bash
cd /var/www/menucard-pro

echo "=== 1. menu-editor.tsx (Sektions-Rendering) ==="
cat -n src/components/admin/menu-editor.tsx | sed -n '1,50p'
echo "..."

echo ""
echo "=== 2. Wo wird 'section.' angesprochen? ==="
grep -nE "section\.(name|icon|emoji|type)" src/components/admin/menu-editor.tsx

echo ""
echo "=== 3. Import/Composition in menu-editor ==="
grep -nE "^import|from '" src/components/admin/menu-editor.tsx | head -20

echo ""
echo "=== 4. Prisma Schema: Section ==="
grep -nA 20 "^model.*Section" prisma/schema.prisma 2>/dev/null

echo ""
echo "=== 5. DB: MenuSection Icons ==="
psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -c "\d \"MenuSection\"" 2>/dev/null | head -30

echo ""
echo "=== 6. Beispiel-Werte der Sections ==="
psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -c "SELECT name, icon FROM \"MenuSection\" LIMIT 20;" 2>/dev/null
