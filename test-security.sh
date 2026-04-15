#!/bin/bash
# MenuCard Pro – Sicherheitstests
# Prüft Auth-Schutz, Input-Validierung, Header, Datenlecks
# Datum: 12.04.2026
# Ausführen auf dem Server: bash test-security.sh

cd /var/www/menucard-pro

BASE="http://localhost:3000"
NGINX="http://127.0.0.1:80"
PASS=0
FAIL=0
WARN=0

ok()   { PASS=$((PASS+1)); echo "  ✅ $1"; }
fail() { FAIL=$((FAIL+1)); echo "  ❌ $1"; }
warn() { WARN=$((WARN+1)); echo "  ⚠️  $1"; }
section() { echo ""; echo "━━━ $1 ━━━"; }

# ═══════════════════════════════════════════
section "1. AUTH-SCHUTZ (ohne Login)"
# ═══════════════════════════════════════════

ADMIN_PATHS=(
  "/admin"
  "/admin/design"
  "/api/v1/products"
  "/api/v1/qr-codes"
  "/api/v1/placements"
  "/api/v1/import"
  "/api/v1/translate"
)

for APATH in "${ADMIN_PATHS[@]}"; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "${BASE}${APATH}" 2>/dev/null)
  BODY=$(curl -s "${BASE}${APATH}" 2>/dev/null | head -c 200)

  if [ "$CODE" = "401" ] || [ "$CODE" = "403" ]; then
    ok "Auth-Schutz ${APATH}: Geschützt (HTTP $CODE)"
  elif [ "$CODE" = "302" ] || [ "$CODE" = "303" ] || [ "$CODE" = "307" ]; then
    ok "Auth-Schutz ${APATH}: Redirect zu Login (HTTP $CODE)"
  elif echo "$BODY" | grep -qi "unauthorized\|login\|signin\|anmelden"; then
    ok "Auth-Schutz ${APATH}: Leitet zu Login weiter"
  elif [ "$CODE" = "200" ]; then
    fail "Auth-Schutz ${APATH}: NICHT GESCHÜTZT (HTTP 200 ohne Login!)"
  else
    warn "Auth-Schutz ${APATH}: HTTP $CODE"
  fi
done

# Design-API ohne Auth
MENU_ID=$(node -e "
const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();
p.menu.findFirst().then(m => { console.log(m?.id || ''); p.\$disconnect(); });
" 2>/dev/null)

if [ -n "$MENU_ID" ]; then
  DESIGN_NOAUTH=$(curl -s -o /dev/null -w "%{http_code}" "${BASE}/api/v1/menus/${MENU_ID}/design")
  if [ "$DESIGN_NOAUTH" = "401" ]; then
    ok "Design-API ohne Auth: Abgelehnt (401)"
  else
    fail "Design-API ohne Auth: HTTP $DESIGN_NOAUTH (erwartet: 401)"
  fi
fi

# ═══════════════════════════════════════════
section "2. LOGIN-SICHERHEIT"
# ═══════════════════════════════════════════

# Falsches Passwort
CSRF_RESP=$(curl -s -c /tmp/mc-sec.txt "${BASE}/api/auth/csrf")
CSRF=$(echo "$CSRF_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('csrfToken',''))" 2>/dev/null)

curl -s -o /dev/null -b /tmp/mc-sec.txt -c /tmp/mc-sec.txt \
  -X POST "${BASE}/api/auth/callback/credentials" \
  -d "csrfToken=${CSRF}&email=admin%40hotel-sonnblick.at&password=FalschesPasswort123" \
  -L 2>/dev/null

BAD_SESSION=$(curl -s -b /tmp/mc-sec.txt "${BASE}/api/auth/session")
BAD_EMAIL=$(echo "$BAD_SESSION" | python3 -c "import sys,json; print(json.load(sys.stdin).get('user',{}).get('email',''))" 2>/dev/null)

if [ -z "$BAD_EMAIL" ]; then
  ok "Falsches Passwort: Kein Zugang"
else
  fail "Falsches Passwort: Login trotzdem möglich! ($BAD_EMAIL)"
fi

# SQL-Injection im Login
rm -f /tmp/mc-sec.txt
CSRF_RESP2=$(curl -s -c /tmp/mc-sec.txt "${BASE}/api/auth/csrf")
CSRF2=$(echo "$CSRF_RESP2" | python3 -c "import sys,json; print(json.load(sys.stdin).get('csrfToken',''))" 2>/dev/null)

curl -s -o /dev/null -b /tmp/mc-sec.txt -c /tmp/mc-sec.txt \
  -X POST "${BASE}/api/auth/callback/credentials" \
  -d "csrfToken=${CSRF2}&email=admin%27+OR+1%3D1--&password=x" \
  -L 2>/dev/null

SQL_SESSION=$(curl -s -b /tmp/mc-sec.txt "${BASE}/api/auth/session")
SQL_EMAIL=$(echo "$SQL_SESSION" | python3 -c "import sys,json; print(json.load(sys.stdin).get('user',{}).get('email',''))" 2>/dev/null)

if [ -z "$SQL_EMAIL" ]; then
  ok "SQL-Injection im Login: Geschützt"
else
  fail "SQL-INJECTION IM LOGIN MÖGLICH! ($SQL_EMAIL)"
fi

# ═══════════════════════════════════════════
section "3. SENSIBLE DATEIEN & PFADE"
# ═══════════════════════════════════════════

SENSITIVE_PATHS=(
  "/.env"
  "/.env.local"
  "/.env.production"
  "/prisma/schema.prisma"
  "/.git/config"
  "/.git/HEAD"
)

for SPATH in "${SENSITIVE_PATHS[@]}"; do
  SCODE=$(curl -s -o /dev/null -w "%{http_code}" "${NGINX}${SPATH}" 2>/dev/null)
  SBODY=$(curl -s "${NGINX}${SPATH}" 2>/dev/null | head -c 500)

  if [ "$SCODE" = "404" ] || [ "$SCODE" = "403" ]; then
    ok "Sensible Datei ${SPATH}: Nicht erreichbar ($SCODE)"
  elif echo "$SBODY" | grep -qi "DATABASE_URL\|NEXTAUTH_SECRET\|password.*=\|private_key"; then
    fail "SENSIBLE DATEN EXPONIERT: ${SPATH}"
  elif [ "$SCODE" = "200" ]; then
    warn "Datei ${SPATH} erreichbar (HTTP 200) – Inhalt manuell prüfen"
  else
    ok "Sensible Datei ${SPATH}: HTTP $SCODE"
  fi
done

# .env Dateiberechtigungen auf dem Server
if [ -f ".env" ]; then
  ENV_PERMS=$(stat -c "%a" .env)
  if [ "$ENV_PERMS" = "600" ] || [ "$ENV_PERMS" = "640" ]; then
    ok ".env Berechtigungen: $ENV_PERMS (eingeschränkt)"
  else
    warn ".env Berechtigungen: $ENV_PERMS (empfohlen: 600). Fix: chmod 600 .env"
  fi
fi

# ═══════════════════════════════════════════
section "4. HTTP-SICHERHEITS-HEADER"
# ═══════════════════════════════════════════

HEADERS=$(curl -s -I "${NGINX}" 2>/dev/null)

# X-Frame-Options
if echo "$HEADERS" | grep -qi "x-frame-options"; then
  ok "Clickjacking-Schutz: X-Frame-Options vorhanden"
else
  warn "Clickjacking-Schutz: X-Frame-Options fehlt"
fi

# X-Content-Type-Options
if echo "$HEADERS" | grep -qi "x-content-type-options"; then
  ok "MIME-Sniffing-Schutz: X-Content-Type-Options vorhanden"
else
  warn "MIME-Sniffing-Schutz: X-Content-Type-Options fehlt"
fi

# HSTS
if echo "$HEADERS" | grep -qi "strict-transport-security"; then
  ok "HSTS vorhanden"
else
  warn "HSTS fehlt (relevant sobald SSL aktiv)"
fi

# X-Powered-By
if echo "$HEADERS" | grep -qi "x-powered-by"; then
  XPOW=$(echo "$HEADERS" | grep -i "x-powered-by")
  warn "X-Powered-By exponiert: $XPOW (Fix: next.config poweredByHeader: false)"
else
  ok "X-Powered-By: Nicht exponiert"
fi

# Server-Header
if echo "$HEADERS" | grep -qi "^server:.*nginx"; then
  warn "Server-Header zeigt Nginx-Version"
else
  ok "Server-Header: Nicht zu detailliert"
fi

# ═══════════════════════════════════════════
section "5. INPUT-VALIDIERUNG"
# ═══════════════════════════════════════════

if [ -n "$MENU_ID" ]; then
  # Login für API-Tests
  rm -f /tmp/mc-sec-auth.txt
  CSRF3=$(curl -s -c /tmp/mc-sec-auth.txt "${BASE}/api/auth/csrf" | python3 -c "import sys,json; print(json.load(sys.stdin).get('csrfToken',''))" 2>/dev/null)
  curl -s -o /dev/null -b /tmp/mc-sec-auth.txt -c /tmp/mc-sec-auth.txt \
    -X POST "${BASE}/api/auth/callback/credentials" \
    -d "csrfToken=${CSRF3}&email=admin%40hotel-sonnblick.at&password=Sonnblick2026%21" \
    -L 2>/dev/null

  # XSS in Design-Config
  XSS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -b /tmp/mc-sec-auth.txt \
    -X PATCH "${BASE}/api/v1/menus/${MENU_ID}/design" \
    -H "Content-Type: application/json" \
    -d '{"designConfig":{"digital":{"header":{"title":"<script>alert(1)</script>"}}}}')

  XSS_RESP=$(curl -s -b /tmp/mc-sec-auth.txt "${BASE}/api/v1/menus/${MENU_ID}/design")

  if echo "$XSS_RESP" | grep -q "<script>alert"; then
    warn "XSS: Script-Tag wird gespeichert (React escaped beim Render, aber Sanitierung empfohlen)"
  else
    ok "XSS: Script-Tag nicht in Antwort"
  fi

  # Bereinigung
  curl -s -o /dev/null -b /tmp/mc-sec-auth.txt \
    -X PATCH "${BASE}/api/v1/menus/${MENU_ID}/design" \
    -H "Content-Type: application/json" \
    -d '{"designConfig":{"digital":{"header":{"title":null}}}}'

  # Nicht existierende Menü-ID
  FAKE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -b /tmp/mc-sec-auth.txt \
    "${BASE}/api/v1/menus/fake-nonexistent-id/design")
  if [ "$FAKE_CODE" = "404" ]; then
    ok "Nicht existierende ID: Korrekt 404"
  elif [ "$FAKE_CODE" = "500" ]; then
    warn "Nicht existierende ID: Server Error 500 (sollte 404 sein)"
  else
    warn "Nicht existierende ID: HTTP $FAKE_CODE"
  fi
fi

# ═══════════════════════════════════════════
section "6. CORS"
# ═══════════════════════════════════════════

CORS_RESP=$(curl -s -I -H "Origin: https://evil-site.com" "${NGINX}/api/v1/menus" 2>/dev/null)

if echo "$CORS_RESP" | grep -qi "access-control-allow-origin.*evil-site\|access-control-allow-origin.*\*"; then
  fail "CORS: Erlaubt Zugriff von beliebigen Origins!"
else
  ok "CORS: Kein offener Wildcard-Zugriff"
fi

# ═══════════════════════════════════════════
section "7. DATENBANK"
# ═══════════════════════════════════════════

# PostgreSQL nur lokal?
PG_PORT=$(ss -tlnp 2>/dev/null | grep ":5432")
if echo "$PG_PORT" | grep -q "127.0.0.1"; then
  ok "PostgreSQL: Nur auf localhost (127.0.0.1:5432)"
elif [ -z "$PG_PORT" ]; then
  ok "PostgreSQL Port 5432: Nicht extern sichtbar"
else
  fail "PostgreSQL: Extern erreichbar! ($PG_PORT)"
fi

# ═══════════════════════════════════════════
section "8. NGINX"
# ═══════════════════════════════════════════

if command -v nginx &>/dev/null; then
  NGINX_TEST=$(nginx -t 2>&1)
  if echo "$NGINX_TEST" | grep -q "successful"; then
    ok "Nginx-Config: Syntax OK"
  else
    fail "Nginx-Config: Fehler"
  fi

  if grep -r "limit_req" /etc/nginx/ 2>/dev/null | grep -qv "^#"; then
    ok "Nginx Rate-Limiting: Konfiguriert"
  else
    warn "Nginx Rate-Limiting: Nicht konfiguriert"
  fi
else
  warn "Nginx nicht gefunden"
fi

# ═══════════════════════════════════════════
section "9. SYSTEM"
# ═══════════════════════════════════════════

# SSH
SSH_ROOT=$(grep -i "^PermitRootLogin" /etc/ssh/sshd_config 2>/dev/null | head -1)
if echo "$SSH_ROOT" | grep -qi "no\|prohibit-password"; then
  ok "SSH Root-Login: Eingeschränkt ($SSH_ROOT)"
elif echo "$SSH_ROOT" | grep -qi "yes"; then
  warn "SSH Root-Login erlaubt mit Passwort (empfohlen: prohibit-password)"
else
  warn "SSH Root-Login: $SSH_ROOT"
fi

# Firewall
if command -v ufw &>/dev/null; then
  UFW=$(ufw status 2>/dev/null | head -1)
  if echo "$UFW" | grep -qi "active"; then
    ok "Firewall (UFW): Aktiv"
  else
    warn "Firewall (UFW): Nicht aktiv"
  fi
else
  warn "UFW nicht installiert"
fi

# Node.js
NODE_V=$(node -v 2>/dev/null)
ok "Node.js: $NODE_V"

# npm audit (kurz)
AUDIT=$(npm audit --json 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    v = d.get('metadata',{}).get('vulnerabilities',{})
    c = v.get('critical',0)
    h = v.get('high',0)
    print(f'{c} kritisch, {h} hoch')
except:
    print('nicht auswertbar')
" 2>/dev/null)

if echo "$AUDIT" | grep -q "^0 kritisch, 0 hoch"; then
  ok "npm audit: Keine kritischen Schwachstellen"
else
  warn "npm audit: $AUDIT"
fi

# ─── Ergebnis ───
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   MenuCard Pro – Sicherheitstest-Ergebnisse      ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║  ✅ Bestanden: $PASS"
echo "║  ❌ Fehlgeschlagen: $FAIL"
echo "║  ⚠️  Warnungen: $WARN"
echo "╚══════════════════════════════════════════════════╝"

if [ "$FAIL" -gt "0" ]; then
  echo ""
  echo "⚠️  Es gibt fehlgeschlagene Sicherheitstests!"
  echo "Bitte die markierten Punkte zeitnah beheben."
fi

rm -f /tmp/mc-sec.txt /tmp/mc-sec-auth.txt
