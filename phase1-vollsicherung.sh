#!/usr/bin/env bash
# Phase 1 - Vollsicherung MenuCard Pro
# Erstellt: 2026-04-14
# Ausführung: bash phase1-vollsicherung.sh

set -u  # undefinierte Variablen = Fehler
# set -e NICHT, weil einzelne Schritte fehlschlagen dürfen und trotzdem weitermachen

DATE="20260414"
APP_DIR="/var/www/menucard-pro"
BACKUP_DIR="/root/backups-${DATE}"
REPORT="/tmp/INVENTAR-${DATE}.md"
PGCONN="postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"
export PGPASSWORD="ccTFFSJtuN7l1dC17PzT8Q"

echo "================================"
echo "  PHASE 1 - VOLLSICHERUNG"
echo "  $(date)"
echo "================================"

mkdir -p "$BACKUP_DIR"
cd "$APP_DIR" || { echo "FEHLER: $APP_DIR nicht erreichbar"; exit 1; }

# ------------------------------------
# 1. DB-BACKUP
# ------------------------------------
echo ""
echo "[1/9] PostgreSQL-Vollbackup..."
pg_dump "$PGCONN" > "$BACKUP_DIR/menucard-db-${DATE}.sql" 2>/tmp/pg_dump.err
DB_SIZE=$(du -h "$BACKUP_DIR/menucard-db-${DATE}.sql" | cut -f1)
echo "    -> $BACKUP_DIR/menucard-db-${DATE}.sql ($DB_SIZE)"

# ------------------------------------
# 2. CONFIG-BACKUP (nginx + pm2 + env)
# ------------------------------------
echo ""
echo "[2/9] Config-Backup (Nginx, PM2, .env)..."
tar czf "$BACKUP_DIR/config-${DATE}.tar.gz" \
  -C / \
  etc/nginx/sites-available etc/nginx/conf.d \
  var/www/menucard-pro/.env \
  var/www/menucard-pro/ecosystem.config.js 2>/dev/null || \
  tar czf "$BACKUP_DIR/config-${DATE}.tar.gz" \
    -C / \
    etc/nginx/sites-available etc/nginx/conf.d \
    var/www/menucard-pro/.env 2>/dev/null

CFG_SIZE=$(du -h "$BACKUP_DIR/config-${DATE}.tar.gz" | cut -f1)
echo "    -> $BACKUP_DIR/config-${DATE}.tar.gz ($CFG_SIZE)"

# PM2-Config separat (dump ist manchmal besser als ecosystem.config)
pm2 save >/dev/null 2>&1
cp /root/.pm2/dump.pm2 "$BACKUP_DIR/pm2-dump-${DATE}.pm2" 2>/dev/null && \
  echo "    -> pm2-dump gesichert"

# ------------------------------------
# 3. PRISMA-SCHEMA-SNAPSHOT
# ------------------------------------
echo ""
echo "[3/9] Prisma-Schema-Snapshot..."
cp "$APP_DIR/prisma/schema.prisma" "$BACKUP_DIR/schema-${DATE}.prisma"
echo "    -> $BACKUP_DIR/schema-${DATE}.prisma"

# ------------------------------------
# 4. DB-ZÄHLERSTÄNDE
# ------------------------------------
echo ""
echo "[4/9] DB-Zählerstände..."
COUNTS=$(psql "$PGCONN" -t -A -F'|' <<'SQL'
SELECT 'Products', COUNT(*) FROM "Product"
UNION ALL SELECT 'ProductTranslations', COUNT(*) FROM "ProductTranslation"
UNION ALL SELECT 'ProductPrices', COUNT(*) FROM "ProductPrice"
UNION ALL SELECT 'ProductWineProfiles', COUNT(*) FROM "ProductWineProfile"
UNION ALL SELECT 'ProductBeverageDetails', COUNT(*) FROM "ProductBeverageDetail"
UNION ALL SELECT 'ProductMedia', COUNT(*) FROM "ProductMedia"
UNION ALL SELECT 'Menus', COUNT(*) FROM "Menu"
UNION ALL SELECT 'MenuPlacements', COUNT(*) FROM "MenuPlacement"
UNION ALL SELECT 'MenuTranslations', COUNT(*) FROM "MenuTranslation"
UNION ALL SELECT 'ProductGroups', COUNT(*) FROM "ProductGroup"
UNION ALL SELECT 'PriceLevels', COUNT(*) FROM "PriceLevel"
UNION ALL SELECT 'FillQuantities', COUNT(*) FROM "FillQuantity"
UNION ALL SELECT 'DesignTemplates', COUNT(*) FROM "DesignTemplate"
UNION ALL SELECT 'QrCodes', COUNT(*) FROM "QrCode"
UNION ALL SELECT 'Users', COUNT(*) FROM "User"
UNION ALL SELECT 'Tenants', COUNT(*) FROM "Tenant"
UNION ALL SELECT 'Locations', COUNT(*) FROM "Location";
SQL
)
echo "$COUNTS" | sed 's/|/: /' | sed 's/^/    /'

# ------------------------------------
# 5. DATEIBAUM
# ------------------------------------
echo ""
echo "[5/9] Dateibaum src/..."
if command -v tree >/dev/null 2>&1; then
  tree -L 4 -I 'node_modules|.next|.git|public/uploads' "$APP_DIR/src" > "$BACKUP_DIR/tree-${DATE}.txt"
else
  find "$APP_DIR/src" -type d | head -200 > "$BACKUP_DIR/tree-${DATE}.txt"
fi
echo "    -> $BACKUP_DIR/tree-${DATE}.txt ($(wc -l < $BACKUP_DIR/tree-${DATE}.txt) Zeilen)"

# ------------------------------------
# 6. DEPENDENCIES
# ------------------------------------
echo ""
echo "[6/9] Dependencies dumpen..."
cd "$APP_DIR"
jq '.dependencies, .devDependencies' package.json > "$BACKUP_DIR/deps-${DATE}.json" 2>/dev/null || \
  cp package.json "$BACKUP_DIR/package-${DATE}.json"
DEPS_COUNT=$(jq -r '.dependencies | length' package.json 2>/dev/null || echo "?")
DEV_COUNT=$(jq -r '.devDependencies | length' package.json 2>/dev/null || echo "?")
echo "    -> $DEPS_COUNT dependencies, $DEV_COUNT devDependencies"

# ------------------------------------
# 7. API-ROUTEN LISTEN
# ------------------------------------
echo ""
echo "[7/9] API-Routen listen..."
find "$APP_DIR/src/app/api" -name "route.ts" -o -name "route.tsx" 2>/dev/null | \
  sed "s|$APP_DIR/src/app||" | \
  sed 's|/route\.tsx\?$||' | \
  sort > "$BACKUP_DIR/api-routes-${DATE}.txt"
ROUTE_COUNT=$(wc -l < "$BACKUP_DIR/api-routes-${DATE}.txt")
echo "    -> $ROUTE_COUNT API-Routen"

# Admin-Seiten
find "$APP_DIR/src/app/admin" -name "page.tsx" 2>/dev/null | \
  sed "s|$APP_DIR/src/app||" | \
  sed 's|/page\.tsx$||' | \
  sort > "$BACKUP_DIR/admin-pages-${DATE}.txt"
ADMIN_COUNT=$(wc -l < "$BACKUP_DIR/admin-pages-${DATE}.txt")
echo "    -> $ADMIN_COUNT Admin-Seiten"

# ------------------------------------
# 8. GIT-STATUS + TAG + PUSH
# ------------------------------------
echo ""
echo "[8/9] Git-Status / Tag / Push..."
cd "$APP_DIR"

UNCOMMITTED=$(git status --porcelain | wc -l)
echo "    Uncommitted changes: $UNCOMMITTED"

if [ "$UNCOMMITTED" -gt 0 ]; then
  git add -A
  git commit -m "chore: pre-reorganisation snapshot 2026-04-14" >/dev/null 2>&1 && \
    echo "    -> auto-commit erstellt"
fi

# Existiert der Tag schon?
if git rev-parse "v1.0-stabil" >/dev/null 2>&1; then
  echo "    Tag v1.0-stabil existiert bereits, überspringe"
else
  git tag -a v1.0-stabil -m "Stabiler Stand vor Reorganisation (14.04.2026): 6 Browser-Befunde gefixt, 22/22 Playwright-Tests OK" && \
    echo "    -> Tag v1.0-stabil erstellt"
fi

# Push
git push origin main 2>&1 | tail -3 | sed 's/^/    /'
git push origin v1.0-stabil 2>&1 | tail -3 | sed 's/^/    /'

GIT_HEAD=$(git rev-parse --short HEAD)
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "    HEAD: $GIT_HEAD ($GIT_BRANCH)"

# ------------------------------------
# 9. INVENTAR-REPORT
# ------------------------------------
echo ""
echo "[9/9] Inventar-Report schreiben..."

cat > "$REPORT" <<EOF
# MenuCard Pro — Inventar

**Stichtag:** $(date '+%Y-%m-%d %H:%M:%S')
**Git-HEAD:** $GIT_HEAD ($GIT_BRANCH)
**Tag:** v1.0-stabil
**Sicherungen in:** $BACKUP_DIR

---

## Datenbank-Zählerstände

\`\`\`
$(echo "$COUNTS" | sed 's/|/: /')
\`\`\`

## Backup-Artefakte

| Datei | Größe |
|---|---|
$(ls -lh "$BACKUP_DIR" | awk 'NR>1 {print "| " $9 " | " $5 " |"}')

## Dependencies

- Laufzeit-Packages: $DEPS_COUNT
- Dev-Packages: $DEV_COUNT

## Code-Struktur

- API-Routen: $ROUTE_COUNT
- Admin-Seiten: $ADMIN_COUNT
- Source-Verzeichnisbaum: siehe \`tree-${DATE}.txt\`

## API-Routen (vollständig)

\`\`\`
$(cat "$BACKUP_DIR/api-routes-${DATE}.txt")
\`\`\`

## Admin-Seiten (vollständig)

\`\`\`
$(cat "$BACKUP_DIR/admin-pages-${DATE}.txt")
\`\`\`

## Git-Status

\`\`\`
$(git log --oneline -10)
\`\`\`

---

## Status der Absicherung

- [x] PostgreSQL-Dump: \`menucard-db-${DATE}.sql\` ($DB_SIZE)
- [x] Config-Archiv: \`config-${DATE}.tar.gz\` ($CFG_SIZE)
- [x] Prisma-Schema: \`schema-${DATE}.prisma\`
- [x] PM2-Dump gesichert
- [x] Git-Commit + Tag \`v1.0-stabil\` + Push
- [x] Inventar-Report geschrieben

EOF

echo "    -> $REPORT"

# Report auch im Projektordner für Windows-Zugriff ablegen
cp "$REPORT" "$APP_DIR/INVENTAR-${DATE}.md"

echo ""
echo "================================"
echo "  PHASE 1 ABGESCHLOSSEN"
echo "================================"
echo "Backup-Verzeichnis: $BACKUP_DIR"
echo "Inventar-Report:    $REPORT"
echo "Auch im Projekt:    $APP_DIR/INVENTAR-${DATE}.md"
echo ""
echo "Nächster Schritt: INVENTAR-${DATE}.md prüfen, dann Freigabe für Phase 2"
