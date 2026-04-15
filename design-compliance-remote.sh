#!/bin/bash
# design-compliance-remote.sh
# Läuft auf dem Server. Bundle wird IMMER gebaut, auch bei Teilfehlern.
#
# Ablauf:
#   1. Preflight (Schema-Probing → routes.json)
#   2. Playwright + Chromium sicherstellen
#   3. Quelldateien-Dump (für Runde-2-Rewrites)
#   4. 3 Menüs temporär auf modern/classic/minimal umhängen (Coverage)
#   5. Compliance-Test (58+ Seiten)
#   6. Template-Zuordnung wiederherstellen
#   7. Excel generieren
#   8. Bundle

cd /var/www/menucard-pro || exit 1

DATE_TAG="${1:-$(date +%Y%m%d)}"
XLSX="DESIGN-COMPLIANCE-REPORT-${DATE_TAG}.xlsx"

set +e  # bewusst: wir wollen bis zum Ende laufen

# DB-Zugang
DB_URL=$(grep -E '^DATABASE_URL=' .env | sed 's/^DATABASE_URL=//; s/^"//; s/"$//')
export PGPASSWORD=$(echo "$DB_URL" | sed -E 's|.*://menucard:([^@]+)@.*|\1|')
PSQL="psql -U menucard -h 127.0.0.1 -d menucard_pro -tAF|"

# 1. Preflight
echo "=== [1/8] Preflight ==="
bash design-compliance-preflight.sh

# 2. Playwright + Chromium
echo "=== [2/8] Playwright sicherstellen ==="
if [ ! -d node_modules/playwright ]; then
  npm install --no-save playwright
  npx playwright install chromium
fi

# 3. Quelldateien-Dump für Runde-2-Rewrites
echo "=== [3/8] Quelldateien-Dump ==="
mkdir -p tests/design-compliance/source-dump
DUMP_LIST=(
  "src/styles/tokens.css"
  "src/styles/globals.css"
  "src/app/globals.css"
  "src/app/layout.tsx"
  "src/app/auth/login/page.tsx"
  "src/app/admin/layout.tsx"
  "src/app/admin/page.tsx"
  "src/app/admin/media/page.tsx"
  "src/components/admin/sidebar.tsx"
  "src/components/admin/admin-sidebar.tsx"
  "src/components/admin/admin-layout.tsx"
  "src/components/admin/header.tsx"
  "src/components/admin/media-library.tsx"
  "src/components/ui/icon.tsx"
  "tailwind.config.ts"
  "tailwind.config.js"
  "postcss.config.js"
)
for f in "${DUMP_LIST[@]}"; do
  if [ -f "$f" ]; then
    dest="tests/design-compliance/source-dump/$(echo "$f" | sed 's|/|__|g')"
    cp "$f" "$dest"
    echo "  dump: $f"
  fi
done
# Zusätzlich: alle page.tsx unter src/app/admin + src/app/auth auflisten (damit wir wissen, was es noch gibt)
find src/app/admin src/app/auth -name 'page.tsx' 2>/dev/null > tests/design-compliance/source-dump/_admin-pages.txt
find src/components/admin -name '*.tsx' 2>/dev/null > tests/design-compliance/source-dump/_admin-components.txt
ls -la src/styles 2>/dev/null > tests/design-compliance/source-dump/_styles-dir.txt
ls -la src/app 2>/dev/null > tests/design-compliance/source-dump/_app-dir.txt

# 4. Template-Coverage erweitern: pro Template (modern/classic/minimal) ein aktives Menu temporär umhängen
echo "=== [4/8] Temporäre Template-Coverage setzen ==="
$PSQL -c "CREATE TABLE IF NOT EXISTS _compliance_backup(menu_id TEXT PRIMARY KEY, original_tpl TEXT, set_at TIMESTAMPTZ DEFAULT NOW());"
$PSQL -c "DELETE FROM _compliance_backup;"

# IDs der 3 Nicht-Elegant-SYSTEM-Templates holen
MODERN_ID=$($PSQL  -c "SELECT id FROM \"DesignTemplate\" WHERE \"baseType\"='modern'  AND \"type\"::text='SYSTEM' LIMIT 1;")
CLASSIC_ID=$($PSQL -c "SELECT id FROM \"DesignTemplate\" WHERE \"baseType\"='classic' AND \"type\"::text='SYSTEM' LIMIT 1;")
MINIMAL_ID=$($PSQL -c "SELECT id FROM \"DesignTemplate\" WHERE \"baseType\"='minimal' AND \"type\"::text='SYSTEM' LIMIT 1;")
echo "  modern=$MODERN_ID"
echo "  classic=$CLASSIC_ID"
echo "  minimal=$MINIMAL_ID"

# Drei aktive Menüs auswählen (stabil: nach id sortiert)
MENU_IDS=$($PSQL -c "SELECT id FROM \"Menu\" WHERE \"isActive\"=true ORDER BY id LIMIT 3;")
M1=$(echo "$MENU_IDS" | sed -n '1p')
M2=$(echo "$MENU_IDS" | sed -n '2p')
M3=$(echo "$MENU_IDS" | sed -n '3p')
echo "  M1=$M1 M2=$M2 M3=$M3"

backup_and_set() {
  local mid="$1" tid="$2"
  [ -z "$mid" ] || [ -z "$tid" ] && return
  local orig
  orig=$($PSQL -c "SELECT \"templateId\" FROM \"Menu\" WHERE id='$mid';")
  $PSQL -c "INSERT INTO _compliance_backup(menu_id, original_tpl) VALUES('$mid', '$orig') ON CONFLICT(menu_id) DO UPDATE SET original_tpl=EXCLUDED.original_tpl;"
  $PSQL -c "UPDATE \"Menu\" SET \"templateId\"='$tid' WHERE id='$mid';"
  echo "  $mid  $orig  ->  $tid"
}
backup_and_set "$M1" "$MODERN_ID"
backup_and_set "$M2" "$CLASSIC_ID"
backup_and_set "$M3" "$MINIMAL_ID"

# Preflight nochmal, damit routes.json die neuen templateKeys kennt
echo "  (routes.json neu bauen für geänderte Templates)"
bash design-compliance-preflight.sh >/dev/null

# 5. Compliance-Test
echo "=== [5/8] Compliance-Test ==="
node design-compliance.mjs

# 6. Template-Zuordnung wiederherstellen
echo "=== [6/8] Template-Zuordnung wiederherstellen ==="
$PSQL -c "UPDATE \"Menu\" m SET \"templateId\" = b.original_tpl FROM _compliance_backup b WHERE m.id = b.menu_id;"
$PSQL -c "SELECT menu_id, original_tpl FROM _compliance_backup;"
$PSQL -c "DROP TABLE _compliance_backup;"

# 7. Excel generieren
echo "=== [7/8] Excel generieren ==="
if ! command -v pip3 >/dev/null 2>&1 && ! command -v pip >/dev/null 2>&1; then
  apt-get update -qq && apt-get install -y --no-install-recommends python3-pip
fi
PIPBIN="$(command -v pip3 || command -v pip)"
if [ -n "$PIPBIN" ]; then
  "$PIPBIN" install --break-system-packages --quiet openpyxl
  python3 design-compliance-to-xlsx.py \
    tests/design-compliance/report.json \
    "tests/design-compliance/${XLSX}" || echo "Excel-Build fehlgeschlagen."
else
  echo "WARNUNG: pip nicht verfügbar, Excel nicht gebaut."
fi

# 8. Bundle IMMER bauen
echo "=== [8/8] Bundle bauen ==="
cd tests/design-compliance
FILES=""
for f in routes.json report.json "$XLSX" snapshots source-dump _login_debug.html _login_debug.png; do
  [ -e "$f" ] && FILES="$FILES $f"
done
tar -czf bundle.tgz $FILES
echo "BUNDLE-FERTIG: $(ls -lh bundle.tgz)"
ls -lh .
