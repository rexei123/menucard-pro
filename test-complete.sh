#!/bin/bash
# ============================================================
# MenuCard Pro – Kompletter System-Test
# Ausführen auf dem Server: bash test-complete.sh
# ============================================================

cd /var/www/menucard-pro

PASS=0
FAIL=0
WARN=0
BASE="http://localhost:3000"

green() { echo -e "\033[32m  ✓ PASS: $1\033[0m"; PASS=$((PASS+1)); }
red()   { echo -e "\033[31m  ✗ FAIL: $1\033[0m"; FAIL=$((FAIL+1)); }
yellow(){ echo -e "\033[33m  ⚠ WARN: $1\033[0m"; WARN=$((WARN+1)); }

section() { echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "  $1"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

check_http() {
  local url="$1"
  local expected="$2"
  local desc="$3"
  local code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
  if [ "$code" = "$expected" ]; then
    green "$desc → $code"
  else
    red "$desc → $code (erwartet: $expected)"
  fi
}

check_json() {
  local url="$1"
  local desc="$2"
  local resp=$(curl -s "$url" 2>/dev/null)
  local code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
  if [ "$code" = "200" ]; then
    echo "$resp" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null
    if [ $? -eq 0 ]; then
      green "$desc → 200, gültiges JSON"
    else
      red "$desc → 200, aber KEIN gültiges JSON"
    fi
  else
    red "$desc → HTTP $code"
  fi
}

check_json_count() {
  local url="$1"
  local desc="$2"
  local field="$3"
  local resp=$(curl -s "$url" 2>/dev/null)
  local code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
  if [ "$code" = "200" ]; then
    local count=$(echo "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d) if isinstance(d,list) else len(d.get('$field',d.get('items',[]))))" 2>/dev/null)
    if [ -n "$count" ] && [ "$count" -gt 0 ] 2>/dev/null; then
      green "$desc → $count Einträge"
    elif [ "$count" = "0" ]; then
      yellow "$desc → 0 Einträge (leer)"
    else
      red "$desc → Konnte Einträge nicht zählen"
    fi
  else
    red "$desc → HTTP $code"
  fi
}

echo "============================================================"
echo "  MenuCard Pro – Kompletter System-Test"
echo "  $(date '+%d.%m.%Y %H:%M:%S')"
echo "============================================================"

# ============================================================
section "1. PROZESS & SERVICE STATUS"
# ============================================================

# PM2 Status
if pm2 describe menucard-pro > /dev/null 2>&1; then
  STATUS=$(pm2 describe menucard-pro 2>/dev/null | grep "status" | head -1 | awk '{print $4}')
  if [ "$STATUS" = "online" ]; then
    green "PM2 menucard-pro: online"
  else
    red "PM2 menucard-pro: $STATUS"
  fi
else
  red "PM2 menucard-pro: nicht gefunden"
fi

# Nginx
if systemctl is-active --quiet nginx; then
  green "Nginx: aktiv"
else
  red "Nginx: nicht aktiv"
fi

# PostgreSQL
if systemctl is-active --quiet postgresql; then
  green "PostgreSQL: aktiv"
else
  red "PostgreSQL: nicht aktiv"
fi

# Port 3000
if ss -tlnp | grep -q ":3000"; then
  green "Port 3000: lauscht"
else
  red "Port 3000: nicht erreichbar"
fi

# .next Verzeichnis
if [ -d ".next" ]; then
  BUILD_DATE=$(stat -c %y .next/BUILD_ID 2>/dev/null | cut -d'.' -f1)
  green ".next Build vorhanden ($BUILD_DATE)"
else
  red ".next Build FEHLT"
fi

# ============================================================
section "2. DATENBANK-VERBINDUNG & DATEN"
# ============================================================

DB_URL="postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

# Verbindung
if psql "$DB_URL" -c "SELECT 1" > /dev/null 2>&1; then
  green "DB-Verbindung: OK"
else
  red "DB-Verbindung: FEHLGESCHLAGEN"
fi

# Tabellen zählen
TABLE_COUNT=$(psql "$DB_URL" -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public'" 2>/dev/null | tr -d ' ')
if [ -n "$TABLE_COUNT" ] && [ "$TABLE_COUNT" -gt 10 ]; then
  green "Tabellen: $TABLE_COUNT"
else
  red "Tabellen: $TABLE_COUNT (erwartet >10)"
fi

# Daten zählen
for tbl in "Product" "Menu" "ProductTranslation" "ProductPrice" "ProductGroup" "QrCode" "Media" "MenuPlacement"; do
  COUNT=$(psql "$DB_URL" -t -c "SELECT count(*) FROM \"$tbl\"" 2>/dev/null | tr -d ' ')
  if [ -n "$COUNT" ] && [ "$COUNT" -gt 0 ] 2>/dev/null; then
    green "$tbl: $COUNT Einträge"
  elif [ "$COUNT" = "0" ]; then
    yellow "$tbl: 0 Einträge"
  else
    yellow "$tbl: Tabelle nicht gefunden oder Fehler"
  fi
done

# ============================================================
section "3. API-ENDPOINTS"
# ============================================================

# GET Endpoints
check_json_count "$BASE/api/v1/menus" "GET /api/v1/menus" "menus"
check_json_count "$BASE/api/v1/products" "GET /api/v1/products" "products"
check_json_count "$BASE/api/v1/qr-codes" "GET /api/v1/qr-codes" "qrCodes"
check_json_count "$BASE/api/v1/media" "GET /api/v1/media" "items"
check_json "$BASE/api/v1/design-templates" "GET /api/v1/design-templates"

# Menu-spezifische Endpoints
MENU_ID=$(psql "$DB_URL" -t -c "SELECT id FROM \"Menu\" LIMIT 1" 2>/dev/null | tr -d ' ')
if [ -n "$MENU_ID" ]; then
  check_json "$BASE/api/v1/menus/$MENU_ID" "GET /api/v1/menus/:id"
  check_json "$BASE/api/v1/menus/$MENU_ID/design" "GET /api/v1/menus/:id/design"
  check_http "$BASE/api/v1/menus/$MENU_ID/pdf" "200" "GET /api/v1/menus/:id/pdf"
fi

# Produkt-spezifische Endpoints
PROD_ID=$(psql "$DB_URL" -t -c "SELECT id FROM \"Product\" LIMIT 1" 2>/dev/null | tr -d ' ')
if [ -n "$PROD_ID" ]; then
  check_json "$BASE/api/v1/products/$PROD_ID" "GET /api/v1/products/:id"
fi

# Auth Endpoint
check_http "$BASE/api/auth/providers" "200" "GET /api/auth/providers"
check_http "$BASE/api/auth/csrf" "200" "GET /api/auth/csrf"

# Translate Endpoint (POST ohne Body → erwartet 400 oder 405)
TRANSLATE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/v1/translate" 2>/dev/null)
if [ "$TRANSLATE_CODE" = "400" ] || [ "$TRANSLATE_CODE" = "405" ] || [ "$TRANSLATE_CODE" = "422" ]; then
  green "POST /api/v1/translate → $TRANSLATE_CODE (korrekte Fehlerbehandlung)"
else
  yellow "POST /api/v1/translate → $TRANSLATE_CODE (unerwartet)"
fi

# Import Endpoint
IMPORT_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/v1/import" 2>/dev/null)
if [ "$IMPORT_CODE" = "400" ] || [ "$IMPORT_CODE" = "405" ] || [ "$IMPORT_CODE" = "422" ]; then
  green "POST /api/v1/import → $IMPORT_CODE (korrekte Fehlerbehandlung)"
else
  yellow "POST /api/v1/import → $IMPORT_CODE (unerwartet)"
fi

# ============================================================
section "4. ÖFFENTLICHE SEITEN (GÄSTEANSICHT)"
# ============================================================

# Tenant/Location Seiten
TENANT_SLUG=$(psql "$DB_URL" -t -c "SELECT slug FROM \"Tenant\" LIMIT 1" 2>/dev/null | tr -d ' ')
LOC_SLUG=$(psql "$DB_URL" -t -c "SELECT l.slug FROM \"Location\" l LIMIT 1" 2>/dev/null | tr -d ' ')
MENU_SLUG=$(psql "$DB_URL" -t -c "SELECT slug FROM \"Menu\" LIMIT 1" 2>/dev/null | tr -d ' ')

if [ -n "$TENANT_SLUG" ] && [ -n "$LOC_SLUG" ]; then
  check_http "$BASE/$TENANT_SLUG/$LOC_SLUG" "200" "Standort-Seite: /$TENANT_SLUG/$LOC_SLUG"

  if [ -n "$MENU_SLUG" ]; then
    check_http "$BASE/$TENANT_SLUG/$LOC_SLUG/$MENU_SLUG" "200" "Menü-Seite: /$TENANT_SLUG/$LOC_SLUG/$MENU_SLUG"
    check_http "$BASE/$TENANT_SLUG/$LOC_SLUG/$MENU_SLUG?lang=en" "200" "Menü-Seite EN: ?lang=en"
    check_http "$BASE/$TENANT_SLUG/$LOC_SLUG/$MENU_SLUG?lang=de" "200" "Menü-Seite DE: ?lang=de"
  fi
else
  red "Kein Tenant/Location in DB gefunden"
fi

# ============================================================
section "5. ADMIN-SEITEN"
# ============================================================

check_http "$BASE/admin" "200" "Admin Dashboard"
check_http "$BASE/admin/menus" "200" "Admin Menüverwaltung"
check_http "$BASE/admin/items" "200" "Admin Produkte"
check_http "$BASE/admin/design" "200" "Admin Templates"
check_http "$BASE/admin/media" "200" "Admin Bildarchiv"
check_http "$BASE/admin/qr-codes" "200" "Admin QR-Codes"
check_http "$BASE/admin/settings" "200" "Admin Einstellungen"

# Login Seite
check_http "$BASE/api/auth/signin" "200" "Login-Seite"

# ============================================================
section "6. SECURITY CHECKS"
# ============================================================

# Geschützte Dateien/Pfade (sollten 403/404 sein)
for path in "/.git/config" "/.env" "/prisma/schema.prisma" "/.bak" "/test-bugs.sh" "/test-security.sh" "/package.json"; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE$path" 2>/dev/null)
  if [ "$CODE" = "403" ] || [ "$CODE" = "404" ]; then
    green "Blockiert: $path → $CODE"
  else
    red "NICHT BLOCKIERT: $path → $CODE"
  fi
done

# Security Headers via Nginx (Port 80)
echo ""
echo "  Security Headers (Nginx):"
HEADERS=$(curl -s -I http://localhost/ 2>/dev/null)

check_header() {
  local header="$1"
  local desc="$2"
  if echo "$HEADERS" | grep -qi "$header"; then
    VALUE=$(echo "$HEADERS" | grep -i "$header" | head -1 | cut -d: -f2- | tr -d '\r')
    green "$desc:$VALUE"
  else
    red "$desc: FEHLT"
  fi
}

check_header "X-Frame-Options" "X-Frame-Options"
check_header "X-Content-Type-Options" "X-Content-Type-Options"
check_header "X-XSS-Protection" "X-XSS-Protection"
check_header "Referrer-Policy" "Referrer-Policy"
check_header "X-Powered-By" "X-Powered-By (sollte fehlen)"

# Powered-By sollte FEHLEN
if echo "$HEADERS" | grep -qi "X-Powered-By"; then
  red "X-Powered-By ist sichtbar (sollte deaktiviert sein)"
else
  green "X-Powered-By: nicht sichtbar (korrekt)"
fi

# Rate Limiting prüfen (10 schnelle Anfragen)
echo ""
echo "  Rate-Limiting Test (10 schnelle Anfragen):"
RATE_LIMITED=false
for i in $(seq 1 15); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/v1/menus" 2>/dev/null)
  if [ "$CODE" = "429" ]; then
    RATE_LIMITED=true
    green "Rate-Limiting greift bei Anfrage $i → 429"
    break
  fi
done
if [ "$RATE_LIMITED" = false ]; then
  yellow "Rate-Limiting hat bei 15 Anfragen NICHT gegriffen (evtl. nur auf Nginx-Ebene)"
fi

# ============================================================
section "7. DATEISYSTEM & KONFIGURATION"
# ============================================================

# Wichtige Dateien vorhanden
for f in ".env" "package.json" "next.config.mjs" "tsconfig.json" "tailwind.config.ts" "prisma/schema.prisma" "src/styles/tokens.css" "src/app/globals.css" "src/app/layout.tsx"; do
  if [ -f "$f" ]; then
    green "Datei vorhanden: $f"
  else
    red "Datei FEHLT: $f"
  fi
done

# Template-Dateien
echo ""
echo "  Template-Renderer:"
for f in "src/components/templates/minimal-renderer.tsx" "src/components/templates/modern-renderer.tsx" "src/components/templates/classic-renderer.tsx"; do
  if [ -f "$f" ]; then
    green "Template: $f"
  else
    red "Template FEHLT: $f"
  fi
done

# UI-Komponenten
echo ""
echo "  UI-Komponenten:"
for f in "src/components/ui/icon.tsx" "src/components/ui/button.tsx" "src/components/ui/input-field.tsx" "src/components/ui/card-ui.tsx" "src/components/ui/badge-ui.tsx"; do
  if [ -f "$f" ]; then
    green "Komponente: $f"
  else
    red "Komponente FEHLT: $f"
  fi
done

# Upload-Verzeichnis
if [ -d "public/uploads" ]; then
  UPLOAD_COUNT=$(find public/uploads -type f | wc -l)
  green "Upload-Verzeichnis: $UPLOAD_COUNT Dateien"
  UPLOAD_SIZE=$(du -sh public/uploads 2>/dev/null | cut -f1)
  green "Upload-Größe: $UPLOAD_SIZE"
else
  yellow "Upload-Verzeichnis fehlt (public/uploads)"
fi

# .env Variablen prüfen (ohne Werte zu zeigen)
echo ""
echo "  .env Variablen (vorhanden/fehlend):"
for var in "DATABASE_URL" "NEXTAUTH_SECRET" "NEXTAUTH_URL"; do
  if grep -q "^$var=" .env 2>/dev/null; then
    green "ENV: $var gesetzt"
  else
    red "ENV: $var FEHLT"
  fi
done

# ============================================================
section "8. BUILD & TYPESCRIPT"
# ============================================================

# TypeScript Errors prüfen (ohne Build)
echo "  TypeScript-Prüfung (npx tsc --noEmit)..."
TSC_OUTPUT=$(npx tsc --noEmit 2>&1)
TSC_EXIT=$?
if [ $TSC_EXIT -eq 0 ]; then
  green "TypeScript: keine Fehler"
else
  TSC_ERRORS=$(echo "$TSC_OUTPUT" | grep "error TS" | wc -l)
  red "TypeScript: $TSC_ERRORS Fehler gefunden"
  echo "$TSC_OUTPUT" | grep "error TS" | head -10
  if [ $TSC_ERRORS -gt 10 ]; then
    echo "  ... und $(($TSC_ERRORS - 10)) weitere Fehler"
  fi
fi

# node_modules vorhanden
if [ -d "node_modules" ]; then
  green "node_modules vorhanden"
else
  red "node_modules FEHLT"
fi

# Prisma Client generiert
if [ -d "node_modules/.prisma/client" ]; then
  green "Prisma Client generiert"
else
  red "Prisma Client FEHLT"
fi

# ============================================================
section "9. NGINX KONFIGURATION"
# ============================================================

# Nginx Config Test
if nginx -t 2>&1 | grep -q "successful"; then
  green "Nginx Config: gültig"
else
  red "Nginx Config: Fehler"
  nginx -t 2>&1
fi

# Upload Limit
UPLOAD_LIMIT=$(grep -r "client_max_body_size" /etc/nginx/ 2>/dev/null | head -1)
if [ -n "$UPLOAD_LIMIT" ]; then
  green "Upload-Limit: $UPLOAD_LIMIT"
else
  yellow "Upload-Limit: nicht explizit gesetzt"
fi

# ============================================================
section "10. BACKUPS & GIT"
# ============================================================

# Git Status
GIT_BRANCH=$(git branch --show-current 2>/dev/null)
green "Git Branch: $GIT_BRANCH"

GIT_STATUS=$(git status --porcelain 2>/dev/null | wc -l)
if [ "$GIT_STATUS" -eq 0 ]; then
  green "Git: sauber (keine uncommitted Änderungen)"
else
  yellow "Git: $GIT_STATUS uncommitted Änderungen"
fi

LAST_COMMIT=$(git log -1 --format="%h %s (%cr)" 2>/dev/null)
green "Letzter Commit: $LAST_COMMIT"

# Remote
GIT_REMOTE=$(git remote get-url origin 2>/dev/null)
if [ -n "$GIT_REMOTE" ]; then
  green "Git Remote: $GIT_REMOTE"
else
  yellow "Git Remote: nicht konfiguriert"
fi

# Backup-Dateien
echo ""
echo "  Backup-Dateien:"
BACKUP_COUNT=$(find . -name "*.bak" -not -path "./node_modules/*" -not -path "./.next/*" | wc -l)
green "Backup-Dateien (.bak): $BACKUP_COUNT"

# SQL-Backups
for f in /root/menucard-pre-cleanup-20260410.sql /root/menucard-backup-20260410.sql; do
  if [ -f "$f" ]; then
    SIZE=$(du -h "$f" | cut -f1)
    green "SQL-Backup: $f ($SIZE)"
  else
    yellow "SQL-Backup FEHLT: $f"
  fi
done

# ============================================================
section "11. DISK & SYSTEM"
# ============================================================

DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}')
DISK_AVAIL=$(df -h / | tail -1 | awk '{print $4}')
green "Disk: $DISK_USAGE genutzt, $DISK_AVAIL frei"

MEM_USAGE=$(free -h | grep Mem | awk '{print $3 "/" $2}')
green "RAM: $MEM_USAGE"

PM2_MEM=$(pm2 describe menucard-pro 2>/dev/null | grep "memory" | head -1 | awk '{print $4}')
if [ -n "$PM2_MEM" ]; then
  green "PM2 Speicher: $PM2_MEM"
fi

UPTIME=$(uptime -p 2>/dev/null || uptime)
green "Uptime: $UPTIME"

# ============================================================
# ZUSAMMENFASSUNG
# ============================================================
echo ""
echo "============================================================"
echo "  ZUSAMMENFASSUNG"
echo "============================================================"
echo -e "  \033[32m✓ BESTANDEN: $PASS\033[0m"
echo -e "  \033[31m✗ FEHLER:    $FAIL\033[0m"
echo -e "  \033[33m⚠ WARNUNGEN: $WARN\033[0m"
echo "============================================================"
echo "  Gesamt: $((PASS + FAIL + WARN)) Tests"
echo "  Datum:  $(date '+%d.%m.%Y %H:%M:%S')"
echo "============================================================"

if [ $FAIL -gt 0 ]; then
  echo ""
  echo "  ⚠ Es gibt $FAIL fehlgeschlagene Tests. Bitte prüfen!"
  exit 1
fi
