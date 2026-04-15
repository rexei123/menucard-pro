#!/bin/bash
# =============================================================
# Automatisierte UI-Tests MenuCard Pro
# Stand: 14.04.2026 (nach Schritt 2a + 2b + 2c)
# =============================================================
set +e
BASE="http://127.0.0.1:3000"
PUB="https://menu.hotel-sonnblick.at"
OUT="/tmp/ui-test-result.md"
PASS=0
FAIL=0
echo "# MenuCard Pro – Automatisierter UI-Testreport" > "$OUT"
echo "**Stand:** $(date '+%Y-%m-%d %H:%M:%S')" >> "$OUT"
echo "" >> "$OUT"

# Helper: status check
check() {
  local label="$1"; local url="$2"; local expected="$3"
  local code=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 8 "$url" 2>/dev/null)
  if [[ "$code" == "$expected" ]]; then
    echo "| $label | $url | $expected | $code | ✅ |" >> "$OUT"
    ((PASS++))
  else
    echo "| $label | $url | $expected | $code | ❌ |" >> "$OUT"
    ((FAIL++))
  fi
}

# Helper: check response contains text
check_contains() {
  local label="$1"; local url="$2"; local pattern="$3"
  local body=$(curl -sS --max-time 10 "$url" 2>/dev/null)
  if echo "$body" | grep -q "$pattern"; then
    echo "| $label | $url | enthält \"$pattern\" | ✅ |" >> "$OUT"
    ((PASS++))
  else
    echo "| $label | $url | enthält \"$pattern\" | ❌ |" >> "$OUT"
    ((FAIL++))
  fi
}

# Helper: check HTTP header present
check_header() {
  local label="$1"; local url="$2"; local header="$3"
  if curl -sSI --max-time 8 "$url" 2>/dev/null | grep -qi "^$header:"; then
    echo "| $label | $header | vorhanden | ✅ |" >> "$OUT"
    ((PASS++))
  else
    echo "| $label | $header | vorhanden | ❌ |" >> "$OUT"
    ((FAIL++))
  fi
}

# ===== 1. Infrastruktur =====
echo "## 1. Infrastruktur" >> "$OUT"
echo "" >> "$OUT"
echo "| Test | Erwartet | Ergebnis | Status |" >> "$OUT"
echo "|------|----------|----------|--------|" >> "$OUT"

# PM2
if pm2 describe menucard-pro 2>/dev/null | grep -q "online"; then
  echo "| PM2 menucard-pro | online | online | ✅ |" >> "$OUT"; ((PASS++))
else
  echo "| PM2 menucard-pro | online | nicht online | ❌ |" >> "$OUT"; ((FAIL++))
fi
# Nginx
systemctl is-active --quiet nginx && { echo "| Nginx | aktiv | aktiv | ✅ |" >> "$OUT"; ((PASS++)); } || { echo "| Nginx | aktiv | inaktiv | ❌ |" >> "$OUT"; ((FAIL++)); }
# Postgres
systemctl is-active --quiet postgresql && { echo "| PostgreSQL | aktiv | aktiv | ✅ |" >> "$OUT"; ((PASS++)); } || { echo "| PostgreSQL | aktiv | inaktiv | ❌ |" >> "$OUT"; ((FAIL++)); }
# Port 3000
ss -lnt 2>/dev/null | grep -q ":3000 " && { echo "| Port 3000 | lauscht | lauscht | ✅ |" >> "$OUT"; ((PASS++)); } || { echo "| Port 3000 | lauscht | nicht offen | ❌ |" >> "$OUT"; ((FAIL++)); }
# HTTPS Cert
if curl -sS -o /dev/null -w "%{http_code}" --max-time 8 "$PUB/" 2>/dev/null | grep -q "200\|301\|302"; then
  echo "| HTTPS $PUB | erreichbar | erreichbar | ✅ |" >> "$OUT"; ((PASS++))
else
  echo "| HTTPS $PUB | erreichbar | nicht erreichbar | ❌ |" >> "$OUT"; ((FAIL++))
fi

# ===== 2. Datenbank-Konsistenz =====
echo "" >> "$OUT"
echo "## 2. Datenbank-Konsistenz" >> "$OUT"
echo "" >> "$OUT"
echo "| Entität | Erwartet | Ergebnis | Status |" >> "$OUT"
echo "|---------|----------|----------|--------|" >> "$OUT"

PSQL="psql -t -A postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro -c"

count() { $PSQL "$1" 2>/dev/null | tr -d ' '; }
check_count() {
  local label="$1"; local q="$2"; local expected="$3"
  local n=$(count "$q")
  if [[ "$n" -ge "$expected" ]]; then
    echo "| $label | ≥ $expected | $n | ✅ |" >> "$OUT"; ((PASS++))
  else
    echo "| $label | ≥ $expected | $n | ❌ |" >> "$OUT"; ((FAIL++))
  fi
}
check_count "Product"       'SELECT COUNT(*) FROM "Product";'             322
check_count "Menu"          'SELECT COUNT(*) FROM "Menu";'                  9
check_count "ProductTranslation" 'SELECT COUNT(*) FROM "ProductTranslation";' 640
check_count "ProductPrice"  'SELECT COUNT(*) FROM "ProductPrice";'          298
check_count "QrCode"        'SELECT COUNT(*) FROM "QrCode";'               10
check_count "DesignTemplate" 'SELECT COUNT(*) FROM "DesignTemplate";'        4
check_count "MenuPlacement" 'SELECT COUNT(*) FROM "MenuPlacement";'          1
check_count "Media"         'SELECT COUNT(*) FROM "Media";'                  1

# ===== 3. API-Endpoints =====
echo "" >> "$OUT"
echo "## 3. API-Endpoints" >> "$OUT"
echo "" >> "$OUT"
echo "| Test | URL | Erwartet | Ergebnis | Status |" >> "$OUT"
echo "|------|-----|----------|----------|--------|" >> "$OUT"

check "GET /api/v1/menus"            "$BASE/api/v1/menus"           200
check "GET /api/v1/products"          "$BASE/api/v1/products"        200
check "GET /api/v1/qr-codes"          "$BASE/api/v1/qr-codes"        200
check "GET /api/v1/media"             "$BASE/api/v1/media"           200
check "GET /api/v1/design-templates"  "$BASE/api/v1/design-templates" 200
check "GET /api/auth/providers"       "$BASE/api/auth/providers"     200
check "POST /api/v1/translate (leer)" "$BASE/api/v1/translate"       "405"
check "POST /api/v1/import (leer)"    "$BASE/api/v1/import"          "405"

# ===== 4. Oeffentliche Seiten =====
echo "" >> "$OUT"
echo "## 4. Oeffentliche Seiten" >> "$OUT"
echo "" >> "$OUT"
echo "| Test | URL | Erwartet | Ergebnis | Status |" >> "$OUT"
echo "|------|-----|----------|----------|--------|" >> "$OUT"

# Hole ersten Tenant/Location/Menu-Slug
TSLUG=$($PSQL 'SELECT slug FROM "Tenant" LIMIT 1;' 2>/dev/null | tr -d ' ')
LSLUG=$($PSQL 'SELECT slug FROM "Location" LIMIT 1;' 2>/dev/null | tr -d ' ')
MSLUG=$($PSQL 'SELECT slug FROM "Menu" LIMIT 1;' 2>/dev/null | tr -d ' ')
if [[ -n "$TSLUG" && -n "$LSLUG" && -n "$MSLUG" ]]; then
  PUBURL="$BASE/$TSLUG/$LSLUG/$MSLUG"
  check "Oeffentliche Menueseite DE" "$PUBURL?lang=de" 200
  check "Oeffentliche Menueseite EN" "$PUBURL?lang=en" 200
else
  echo "| Menueseite | (Slug nicht ermittelbar) | - | ❌ |" >> "$OUT"; ((FAIL++))
fi

# ===== 5. Admin-Seiten (ohne Login) =====
echo "" >> "$OUT"
echo "## 5. Admin-Seiten (ohne Login: 200 = redirect zu Login)" >> "$OUT"
echo "" >> "$OUT"
echo "| Test | URL | Erwartet | Ergebnis | Status |" >> "$OUT"
echo "|------|-----|----------|----------|--------|" >> "$OUT"

check "Admin Dashboard"   "$BASE/admin"            200
check "Admin Karten"      "$BASE/admin/menus"      200
check "Admin Produkte"    "$BASE/admin/products"   200
check "Admin Design"      "$BASE/admin/design"     200
check "Admin QR-Codes"    "$BASE/admin/qr-codes"   200
check "Admin Bildarchiv"  "$BASE/admin/media"      200
check "Admin PDF-Creator" "$BASE/admin/pdf-creator" 200
check "Admin Einstellungen" "$BASE/admin/settings" 200
check "Login-Seite"        "$BASE/login"            200

# ===== 6. Dead-Code (Schritt 2c) =====
echo "" >> "$OUT"
echo "## 6. Dead-Code-Check (Schritt 2c)" >> "$OUT"
echo "" >> "$OUT"
echo "| Test | Erwartet | Ergebnis | Status |" >> "$OUT"
echo "|------|----------|----------|--------|" >> "$OUT"

# Alte Route muss 404 liefern
MID=$($PSQL 'SELECT id FROM "Menu" LIMIT 1;' 2>/dev/null | tr -d ' ')
if [[ -n "$MID" ]]; then
  CODE=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 8 "$BASE/admin/menus/$MID/design" 2>/dev/null)
  if [[ "$CODE" == "404" ]]; then
    echo "| /admin/menus/:id/design entfernt | 404 | $CODE | ✅ |" >> "$OUT"; ((PASS++))
  else
    echo "| /admin/menus/:id/design entfernt | 404 | $CODE | ❌ |" >> "$OUT"; ((FAIL++))
  fi
fi
# Alte Dateien nicht mehr vorhanden
for f in "src/app/admin/menus/[id]/design/page.tsx" "src/components/admin/design-tabs.tsx" "src/components/admin/analog-design-editor.tsx"; do
  if [[ -e "/var/www/menucard-pro/$f" ]]; then
    echo "| $f entfernt | nicht vorhanden | vorhanden | ❌ |" >> "$OUT"; ((FAIL++))
  else
    echo "| $f entfernt | nicht vorhanden | ok | ✅ |" >> "$OUT"; ((PASS++))
  fi
done
# PDF-Layout-Tab vorhanden
if grep -q "pdf-layout-tab" /var/www/menucard-pro/src/components/admin/design-editor.tsx; then
  echo "| pdf-layout-tab importiert (Schritt 2a) | vorhanden | ✅ | ✅ |" >> "$OUT"; ((PASS++))
else
  echo "| pdf-layout-tab importiert (Schritt 2a) | vorhanden | fehlt | ❌ |" >> "$OUT"; ((FAIL++))
fi
# pdf-viewer.html vorhanden
if [[ -f /var/www/menucard-pro/public/pdf-viewer.html ]]; then
  echo "| pdf-viewer.html (pdf.js Wrapper) | vorhanden | ✅ | ✅ |" >> "$OUT"; ((PASS++))
else
  echo "| pdf-viewer.html (pdf.js Wrapper) | vorhanden | fehlt | ❌ |" >> "$OUT"; ((FAIL++))
fi

# ===== 7. PDF-Generierung alle 9 Karten (Schritt 2b) =====
echo "" >> "$OUT"
echo "## 7. PDF-Generierung alle 9 Karten" >> "$OUT"
echo "" >> "$OUT"
echo "| # | Karte | HTTP | Groesse | Status |" >> "$OUT"
echo "|---|-------|------|---------|--------|" >> "$OUT"

i=0
$PSQL 'SELECT id, name FROM "Menu" ORDER BY "sortOrder", name;' 2>/dev/null | while IFS='|' read -r id name; do
  id=$(echo "$id" | tr -d ' ')
  name=$(echo "$name" | sed 's/^ *//;s/ *$//')
  [[ -z "$id" ]] && continue
  i=$((i+1))
  TMP=$(mktemp --suffix=.pdf)
  CODE=$(curl -sS -o "$TMP" -w "%{http_code}" --max-time 60 "$BASE/api/v1/menus/$id/pdf" 2>/dev/null)
  SIZE=$(stat -c%s "$TMP" 2>/dev/null || echo 0)
  if [[ "$CODE" == "200" && "$SIZE" -gt 1000 ]]; then
    # Pruefe PDF-Magic
    if head -c 4 "$TMP" | grep -q "%PDF"; then
      echo "| $i | $name | $CODE | ${SIZE} B | ✅ |" >> "$OUT"
    else
      echo "| $i | $name | $CODE | ${SIZE} B (kein %PDF) | ❌ |" >> "$OUT"
    fi
  else
    echo "| $i | $name | $CODE | ${SIZE} B | ❌ |" >> "$OUT"
  fi
  rm -f "$TMP"
done

# ===== 8. Security-Header =====
echo "" >> "$OUT"
echo "## 8. Security-Header (Public)" >> "$OUT"
echo "" >> "$OUT"
echo "| Test | Header | Ergebnis | Status |" >> "$OUT"
echo "|------|--------|----------|--------|" >> "$OUT"

check_header "X-Frame-Options"        "$PUB/"  "X-Frame-Options"
check_header "X-Content-Type-Options" "$PUB/"  "X-Content-Type-Options"
check_header "X-XSS-Protection"       "$PUB/"  "X-XSS-Protection"
check_header "Strict-Transport-Security" "$PUB/" "Strict-Transport-Security"

# X-Powered-By darf NICHT da sein
if curl -sSI --max-time 8 "$PUB/" 2>/dev/null | grep -qi "^X-Powered-By:"; then
  echo "| X-Powered-By versteckt | nicht vorhanden | vorhanden | ❌ |" >> "$OUT"; ((FAIL++))
else
  echo "| X-Powered-By versteckt | nicht vorhanden | ok | ✅ |" >> "$OUT"; ((PASS++))
fi

# ===== 9. Blockierte Pfade =====
echo "" >> "$OUT"
echo "## 9. Nginx-blockierte Pfade" >> "$OUT"
echo "" >> "$OUT"
echo "| Test | URL | Erwartet | Ergebnis | Status |" >> "$OUT"
echo "|------|-----|----------|----------|--------|" >> "$OUT"

for path in "/.env" "/.git/config" "/prisma/schema.prisma" "/package.json" "/test-bugs.sh"; do
  CODE=$(curl -sSk -o /dev/null -w "%{http_code}" --max-time 8 "$PUB$path" 2>/dev/null)
  if [[ "$CODE" == "403" || "$CODE" == "404" ]]; then
    echo "| $path blockiert | 403/404 | $CODE | ✅ |" >> "$OUT"; ((PASS++))
  else
    echo "| $path blockiert | 403/404 | $CODE | ❌ |" >> "$OUT"; ((FAIL++))
  fi
done

# ===== 10. TypeScript/Build =====
echo "" >> "$OUT"
echo "## 10. Build & TypeScript" >> "$OUT"
echo "" >> "$OUT"
echo "| Test | Erwartet | Ergebnis | Status |" >> "$OUT"
echo "|------|----------|----------|--------|" >> "$OUT"

cd /var/www/menucard-pro
if [[ -d .next ]]; then
  AGE=$(( ($(date +%s) - $(stat -c%Y .next/BUILD_ID 2>/dev/null || echo 0)) / 60 ))
  echo "| .next Build | aktuell | vor $AGE Min | ✅ |" >> "$OUT"; ((PASS++))
else
  echo "| .next Build | aktuell | nicht vorhanden | ❌ |" >> "$OUT"; ((FAIL++))
fi
[[ -d node_modules ]] && { echo "| node_modules | vorhanden | vorhanden | ✅ |" >> "$OUT"; ((PASS++)); } || { echo "| node_modules | vorhanden | fehlt | ❌ |" >> "$OUT"; ((FAIL++)); }
[[ -d node_modules/@prisma/client ]] && { echo "| Prisma Client | generiert | ja | ✅ |" >> "$OUT"; ((PASS++)); } || { echo "| Prisma Client | generiert | nein | ❌ |" >> "$OUT"; ((FAIL++)); }

# ===== Zusammenfassung =====
echo "" >> "$OUT"
echo "---" >> "$OUT"
echo "" >> "$OUT"
echo "## Gesamt" >> "$OUT"
echo "" >> "$OUT"
echo "- **Bestanden:** $PASS" >> "$OUT"
echo "- **Fehlgeschlagen:** $FAIL" >> "$OUT"
echo "- **Gesamt:** $((PASS+FAIL))" >> "$OUT"

echo ""
echo "============================================"
echo "Report geschrieben: $OUT"
echo "Bestanden: $PASS  Fehlgeschlagen: $FAIL"
echo "============================================"
cat "$OUT"
