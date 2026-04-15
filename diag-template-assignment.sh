#!/bin/bash
cd /var/www/menucard-pro

echo "=== 1. Wie sind Templates pro Karte gespeichert? ==="
psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -c "
  SELECT name, slug, \"templateId\", \"designConfig\"
  FROM \"Menu\"
  LIMIT 3;"

echo ""
echo "=== 2. Wo wird die Zuweisungs-Zahl pro Template berechnet? ==="
grep -rn "zugewiesen\|Noch keine Karte" src/app/admin/design/ 2>/dev/null | head

echo ""
echo "=== 3. design/page.tsx (Datenbeschaffung, erste 150 Zeilen) ==="
sed -n '1,150p' src/app/admin/design/page.tsx

echo ""
echo "=== 4. Prisma: Menu-Feld 'templateId' vs 'designConfig' ==="
grep -A 20 "^model Menu " prisma/schema.prisma | head -30
