#!/usr/bin/env bash
# MenuCard Pro — Pass 5 (14.04.2026)
# B-4 finaler Patch: ${sectionName} in Template-String einfügen
set -uo pipefail
cd /var/www/menucard-pro

STAMP=$(date +%Y%m%d-%H%M%S)
cp src/components/menu-content.tsx "/root/menu-content-pre-b4-${STAMP}.bak"

echo "### B-4 final: sectionName in Template-String ###"

python3 - <<'PY'
import pathlib
p = pathlib.Path("src/components/menu-content.tsx")
src = p.read_text()
old = "`${name} ${desc} ${longDesc} ${winery} ${region} ${grapes}`.includes(q)"
new = "`${sectionName} ${name} ${desc} ${longDesc} ${winery} ${region} ${grapes}`.includes(q)"
if old in src:
    src = src.replace(old, new, 1)
    p.write_text(src)
    print("  ✓ Patch gesetzt.")
else:
    if "${sectionName}" in src:
        print("  ℹ  Bereits gepatcht.")
    else:
        print("  ✗ Template-String nicht gefunden.")
PY

echo ""
echo "### Zeile 93 (Check) ###"
sed -n '93p' src/components/menu-content.tsx

echo ""
echo "### Build & Restart ###"
npm run build 2>&1 | tail -8
pm2 restart menucard-pro
sleep 2

echo ""
echo "### Verifikation alle Fixes ###"
export PGPASSWORD='ccTFFSJtuN7l1dC17PzT8Q'

echo "B-1 Startseite Umlaute:"
curl -s https://menu.hotel-sonnblick.at/ | grep -oE "Getr[aä]nke|f[uü]r die gehobene" | sort -u

echo ""
echo "B-3 DB (Rosé/Jouët):"
psql -U menucard -h 127.0.0.1 -d menucard_pro -t -c \
  "SELECT count(*) FROM \"ProductTranslation\" WHERE name LIKE '%Jouët%' OR name LIKE '%Secco Rosé%';"

echo "B-4 Suche um Kategorie erweitert:"
grep -c '\${sectionName}' src/components/menu-content.tsx

echo "B-5 Whitespace-nowrap aktiv:"
grep -c 'whitespace-nowrap px-4 py-2.5' src/components/menu-content.tsx

echo ""
echo "B-8 Tenant-Seite Plural:"
curl -s https://menu.hotel-sonnblick.at/hotel-sonnblick | grep -oE "[0-9]+\s+(Karte|Karten|menu|menus)" | sort -u

echo ""
echo "=========================================="
echo " Pass 5 FERTIG"
echo "=========================================="
