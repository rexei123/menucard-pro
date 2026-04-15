#!/usr/bin/env bash
# Diagnose-Skript Pass 2 — sammelt Info für B-3, B-4, B-5, B-8
# Ausführung:
#   scp diag-pass2-20260414.sh root@178.104.138.177:/root/
#   ssh root@178.104.138.177 "bash /root/diag-pass2-20260414.sh > /root/diag-pass2.out 2>&1"
#   cat /root/diag-pass2.out
set -u
cd /var/www/menucard-pro

echo "==========================================================="
echo " 1) DB-Schema: Product / ProductTranslation"
echo "==========================================================="
export PGPASSWORD='ccTFFSJtuN7l1dC17PzT8Q'
psql -U menucard -h 127.0.0.1 -d menucard_pro -c '\d "Product"'
psql -U menucard -h 127.0.0.1 -d menucard_pro -c '\d "ProductTranslation"'

echo ""
echo "==========================================================="
echo " 2) Produkte mit Rose/Jouet/Epernay"
echo "==========================================================="
psql -U menucard -h 127.0.0.1 -d menucard_pro <<'SQL'
SELECT p.id, pt."languageCode", pt.name
FROM "Product" p
JOIN "ProductTranslation" pt ON pt."productId" = p.id
WHERE pt.name ILIKE '%ROSE%' OR pt.name ILIKE '%Jouet%' OR pt.name ILIKE '%Epernay%'
ORDER BY pt.name;
SQL

echo ""
echo "==========================================================="
echo " 3) src/app/page.tsx (für B-8 Plural)"
echo "==========================================================="
cat -n src/app/page.tsx

echo ""
echo "==========================================================="
echo " 4) src/components/menu-content.tsx (für B-4 Suche, B-5 Nav)"
echo "==========================================================="
if [[ -f src/components/menu-content.tsx ]]; then
  wc -l src/components/menu-content.tsx
  echo "--- erste 80 Zeilen ---"
  head -80 src/components/menu-content.tsx
  echo "--- sticky-Bereich ---"
  grep -n "sticky\|overflow-x\|flex" src/components/menu-content.tsx | head -30
  echo "--- Suche-Bereich ---"
  grep -n "search\|filter\|query\|toLower" src/components/menu-content.tsx | head -30
else
  echo "Datei nicht gefunden. Suche nach Alternativen:"
  find src -name "menu-content*" -o -name "MenuContent*" 2>/dev/null
  find src/app/\[tenant\] -type f -name "*.tsx" 2>/dev/null
fi

echo ""
echo "==========================================================="
echo " 5) Gäste-Route struktur"
echo "==========================================================="
find 'src/app/[tenant]' -type f 2>/dev/null

echo ""
echo "==========================================================="
echo " 6) Was nutzt bereits formatPrice oder toFixed?"
echo "==========================================================="
grep -rn "toFixed\(2\)\|formatPrice\|€.*\${" src/app src/components --include="*.tsx" 2>/dev/null | head -40

echo ""
echo "==========================================================="
echo " FERTIG"
echo "==========================================================="
