#!/usr/bin/env bash
# Phase 1 - Fix: Inventar-Report mit dynamischen Tabellen + Node-basierten Deps neu schreiben
set -u

DATE="20260414"
APP_DIR="/var/www/menucard-pro"
BACKUP_DIR="/root/backups-${DATE}"
REPORT="/tmp/INVENTAR-${DATE}.md"
PGCONN="postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"
export PGPASSWORD="ccTFFSJtuN7l1dC17PzT8Q"

echo "=== Phase 1 Fix: Inventar nachschärfen ==="

# ------------------------------------
# DB-ZÄHLERSTÄNDE dynamisch
# ------------------------------------
echo ""
echo "[1/3] DB-Zählerstände dynamisch ermitteln..."

# Alle User-Tabellen (kein _prisma_migrations) holen
TABLES=$(psql "$PGCONN" -t -A -c "
SELECT table_name
FROM information_schema.tables
WHERE table_schema='public'
  AND table_type='BASE TABLE'
  AND table_name NOT LIKE '\\_prisma%'
ORDER BY table_name;
")

COUNTS_FILE="$BACKUP_DIR/db-counts-${DATE}.txt"
: > "$COUNTS_FILE"

echo "" > /tmp/counts_md.txt
while IFS= read -r t; do
  [ -z "$t" ] && continue
  C=$(psql "$PGCONN" -t -A -c "SELECT COUNT(*) FROM \"$t\";" 2>/dev/null)
  printf "%-30s %8s\n" "$t" "$C" | tee -a "$COUNTS_FILE"
  printf "| %s | %s |\n" "$t" "$C" >> /tmp/counts_md.txt
done <<< "$TABLES"

TABLE_COUNT=$(wc -l < "$COUNTS_FILE")
echo ""
echo "    -> $TABLE_COUNT Tabellen gezählt, Details in $COUNTS_FILE"

# ------------------------------------
# DEPENDENCIES via Node
# ------------------------------------
echo ""
echo "[2/3] Dependencies via Node parsen..."
cd "$APP_DIR"

DEPS_COUNT=$(node -e "const p=require('./package.json');console.log(Object.keys(p.dependencies||{}).length)")
DEV_COUNT=$(node -e "const p=require('./package.json');console.log(Object.keys(p.devDependencies||{}).length)")
NODE_VER=$(node --version)
NPM_VER=$(npm --version)
NEXT_VER=$(node -e "const p=require('./package.json');console.log(p.dependencies.next||'n/a')")
PRISMA_VER=$(node -e "const p=require('./package.json');console.log(p.dependencies['@prisma/client']||p.devDependencies['prisma']||'n/a')")

# Deps als JSON sichern
node -e "
const p=require('./package.json');
const out={deps:p.dependencies,dev:p.devDependencies,scripts:p.scripts,name:p.name,version:p.version};
require('fs').writeFileSync('$BACKUP_DIR/deps-${DATE}.json', JSON.stringify(out,null,2));
"
echo "    -> $DEPS_COUNT dependencies, $DEV_COUNT devDependencies"
echo "    -> Node $NODE_VER, npm $NPM_VER, Next.js $NEXT_VER"

# ------------------------------------
# INVENTAR-REPORT neu schreiben
# ------------------------------------
echo ""
echo "[3/3] Inventar-Report neu schreiben..."

cd "$APP_DIR"
GIT_HEAD=$(git rev-parse --short HEAD)
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
GIT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "?")

cat > "$REPORT" <<EOF
# MenuCard Pro — Inventar

**Stichtag:** $(date '+%Y-%m-%d %H:%M:%S')
**Git-HEAD:** $GIT_HEAD ($GIT_BRANCH)
**Git-Remote:** $GIT_REMOTE
**Tag:** v1.0-stabil
**Sicherungen in:** \`$BACKUP_DIR\`

---

## Laufzeit-Umgebung

| Komponente | Version |
|---|---|
| Node.js | $NODE_VER |
| npm | $NPM_VER |
| Next.js | $NEXT_VER |
| Prisma | $PRISMA_VER |

## Datenbank-Zählerstände ($TABLE_COUNT Tabellen)

| Tabelle | Anzahl |
|---|---|
$(cat /tmp/counts_md.txt)

## Backup-Artefakte

| Datei | Größe |
|---|---|
$(ls -lh "$BACKUP_DIR" | awk 'NR>1 {print "| " $9 " | " $5 " |"}')

## Dependencies

- Laufzeit-Packages: **$DEPS_COUNT**
- Dev-Packages: **$DEV_COUNT**
- Volle Liste: \`deps-${DATE}.json\`

## Code-Struktur

- API-Routen: $(wc -l < "$BACKUP_DIR/api-routes-${DATE}.txt")
- Admin-Seiten: $(wc -l < "$BACKUP_DIR/admin-pages-${DATE}.txt")
- Source-Baum: \`tree-${DATE}.txt\`

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

- [x] PostgreSQL-Dump: \`menucard-db-${DATE}.sql\` ($(du -h "$BACKUP_DIR/menucard-db-${DATE}.sql" | cut -f1))
- [x] Config-Archiv: \`config-${DATE}.tar.gz\` ($(du -h "$BACKUP_DIR/config-${DATE}.tar.gz" | cut -f1))
- [x] Prisma-Schema: \`schema-${DATE}.prisma\`
- [x] PM2-Dump: \`pm2-dump-${DATE}.pm2\`
- [x] Dependencies-Snapshot: \`deps-${DATE}.json\`
- [x] DB-Zählerstände: \`db-counts-${DATE}.txt\`
- [x] API-Routen + Admin-Seiten Listing
- [x] Git-Commit + Tag \`v1.0-stabil\` + Push zu GitHub

EOF

# Kopie in Projektordner
cp "$REPORT" "$APP_DIR/INVENTAR-${DATE}.md"

echo "    -> $REPORT"
echo "    -> $APP_DIR/INVENTAR-${DATE}.md"

echo ""
echo "=== Fix abgeschlossen ==="
echo ""
echo "--- INHALTSÜBERSICHT ---"
head -40 "$REPORT"
