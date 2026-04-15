#!/usr/bin/env bash
# Phase 2 - Schritt 1: Alle dokumentationsrelevanten Quellen in EIN Archiv packen
set -u

APP_DIR="/var/www/menucard-pro"
DATE="20260414"
OUT_DIR="/tmp/phase2-sources"
OUT_TAR="/tmp/phase2-sources-${DATE}.tar.gz"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

echo "=== Phase 2 - Quellen-Sammlung ==="
echo ""

# --------------------------------------------
# 1. Prisma-Schema (komplett)
# --------------------------------------------
cp "$APP_DIR/prisma/schema.prisma" "$OUT_DIR/schema.prisma"
echo "[1/8] Prisma-Schema gesammelt"

# --------------------------------------------
# 2. Alle API-Routen (Datei-Inhalt)
# --------------------------------------------
mkdir -p "$OUT_DIR/api"
find "$APP_DIR/src/app/api" -name "route.ts" -o -name "route.tsx" | while read -r f; do
  rel=${f#$APP_DIR/src/app/api/}
  dest_dir="$OUT_DIR/api/$(dirname "$rel")"
  mkdir -p "$dest_dir"
  cp "$f" "$dest_dir/"
done
API_COUNT=$(find "$OUT_DIR/api" -name "route.*" | wc -l)
echo "[2/8] $API_COUNT API-Routen gesammelt"

# --------------------------------------------
# 3. Alle Admin-Seiten (page.tsx + layout.tsx)
# --------------------------------------------
mkdir -p "$OUT_DIR/admin-pages"
find "$APP_DIR/src/app/admin" -name "page.tsx" -o -name "layout.tsx" | while read -r f; do
  rel=${f#$APP_DIR/src/app/admin/}
  dest_dir="$OUT_DIR/admin-pages/$(dirname "$rel")"
  mkdir -p "$dest_dir"
  cp "$f" "$dest_dir/"
done
ADMIN_COUNT=$(find "$OUT_DIR/admin-pages" -name "*.tsx" | wc -l)
echo "[3/8] $ADMIN_COUNT Admin-Seiten gesammelt"

# --------------------------------------------
# 4. Öffentliche Gäste-Views
# --------------------------------------------
mkdir -p "$OUT_DIR/public-pages"
find "$APP_DIR/src/app" -path "*/admin" -prune -o -path "*/api" -prune -o \( -name "page.tsx" -o -name "layout.tsx" \) -print | while read -r f; do
  if [ -f "$f" ]; then
    rel=${f#$APP_DIR/src/app/}
    dest_dir="$OUT_DIR/public-pages/$(dirname "$rel")"
    mkdir -p "$dest_dir"
    cp "$f" "$dest_dir/"
  fi
done
echo "[4/8] Öffentliche Seiten gesammelt"

# --------------------------------------------
# 5. Wichtige Libraries (auth, prisma, pdf, design-templates)
# --------------------------------------------
mkdir -p "$OUT_DIR/lib"
if [ -d "$APP_DIR/src/lib" ]; then
  cp -r "$APP_DIR/src/lib/"* "$OUT_DIR/lib/" 2>/dev/null
fi
echo "[5/8] lib/ gesammelt"

# --------------------------------------------
# 6. Komponenten-Namen (nur Liste, keine Inhalte - zu groß)
# --------------------------------------------
find "$APP_DIR/src/components" -name "*.tsx" 2>/dev/null | \
  sed "s|$APP_DIR/src/components/||" | \
  sort > "$OUT_DIR/components-list.txt"
echo "[6/8] Komponenten-Liste erstellt ($(wc -l < $OUT_DIR/components-list.txt) Komponenten)"

# --------------------------------------------
# 7. Configs (ohne Secrets)
# --------------------------------------------
mkdir -p "$OUT_DIR/configs"
for f in next.config.mjs tailwind.config.ts tsconfig.json postcss.config.js package.json; do
  if [ -f "$APP_DIR/$f" ]; then
    cp "$APP_DIR/$f" "$OUT_DIR/configs/"
  fi
done

# Nginx-Config (nur Struktur, Server-Name-Redact ist nicht nötig da öffentlich)
cp /etc/nginx/sites-available/menu.hotel-sonnblick.at "$OUT_DIR/configs/nginx.conf" 2>/dev/null || \
  cp /etc/nginx/sites-available/default "$OUT_DIR/configs/nginx.conf" 2>/dev/null

# Wichtig: .env NICHT reinkopieren!
echo "[7/8] Configs gesammelt (ohne Secrets)"

# --------------------------------------------
# 8. Meta-Infos: git log, DB counts, tree
# --------------------------------------------
mkdir -p "$OUT_DIR/meta"
cd "$APP_DIR"
git log --oneline -50 > "$OUT_DIR/meta/git-log.txt"
git tag --sort=-creatordate > "$OUT_DIR/meta/git-tags.txt"
cp "/root/backups-${DATE}/db-counts-${DATE}.txt" "$OUT_DIR/meta/db-counts.txt" 2>/dev/null
cp "/root/backups-${DATE}/tree-${DATE}.txt" "$OUT_DIR/meta/tree.txt" 2>/dev/null
cp "$APP_DIR/CLAUDE.md" "$OUT_DIR/meta/CLAUDE.md.current" 2>/dev/null
cp "$APP_DIR/INVENTAR-${DATE}.md" "$OUT_DIR/meta/INVENTAR.md" 2>/dev/null

# README + andere Docs falls vorhanden
for f in README.md CHANGELOG.md CONTRIBUTING.md LICENSE; do
  [ -f "$APP_DIR/$f" ] && cp "$APP_DIR/$f" "$OUT_DIR/meta/${f}.current"
done

echo "[8/8] Meta-Infos gesammelt"

# --------------------------------------------
# Archivieren
# --------------------------------------------
cd /tmp
tar czf "$OUT_TAR" phase2-sources/
SIZE=$(du -h "$OUT_TAR" | cut -f1)

echo ""
echo "================================"
echo "Quellen-Archiv bereit: $OUT_TAR ($SIZE)"
echo "================================"
echo ""
echo "Bitte herunterladen mit (in lokaler PowerShell):"
echo "  scp root@178.104.138.177:$OUT_TAR <projekt-ordner>\\"
echo ""
ls -lh "$OUT_TAR"
