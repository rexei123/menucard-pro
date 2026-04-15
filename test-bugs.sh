#!/bin/bash
# MenuCard Pro – Funktionale Bugtests
# Prüft alle kritischen API-Endpunkte und Flows
# Datum: 12.04.2026
# Ausführen auf dem Server: bash test-bugs.sh

cd /var/www/menucard-pro

BASE="http://localhost:3000"
PASS=0
FAIL=0
WARN=0

ok()   { PASS=$((PASS+1)); echo "  ✅ $1"; }
fail() { FAIL=$((FAIL+1)); echo "  ❌ $1"; }
warn() { WARN=$((WARN+1)); echo "  ⚠️  $1"; }
section() { echo ""; echo "━━━ $1 ━━━"; }

# ─── Session-Cookie holen (Login) ───
section "1. AUTHENTIFIZIERUNG"

# Schritt 1: CSRF-Token + Session-Cookie holen
CSRF_RESP=$(curl -s -c /tmp/mc-cookies.txt "${BASE}/api/auth/csrf")
CSRF_TOKEN=$(echo "$CSRF_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('csrfToken',''))" 2>/dev/null)

if [ -n "$CSRF_TOKEN" ]; then
  ok "CSRF-Token erhalten"
else
  fail "CSRF-Token nicht gefunden"
fi

# Schritt 2: Login – NextAuth braucht die signin-Seite zuerst für das Cookie
curl -s -c /tmp/mc-cookies.txt -b /tmp/mc-cookies.txt "${BASE}/api/auth/signin" > /dev/null 2>&1

LOGIN_RESP=$(curl -s -o /dev/null -w "%{http_code}" \
  -b /tmp/mc-cookies.txt -c /tmp/mc-cookies.txt \
  -X POST "${BASE}/api/auth/callback/credentials" \
  -d "csrfToken=${CSRF_TOKEN}&email=admin%40hotel-sonnblick.at&password=Sonnblick2026%21&json=true" \
  --max-redirs 5 -L)

# Session prüfen
SESSION_RESP=$(curl -s -b /tmp/mc-cookies.txt "${BASE}/api/auth/session")
SESSION_EMAIL=$(echo "$SESSION_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('user',{}).get('email',''))" 2>/dev/null)

if [ "$SESSION_EMAIL" = "admin@hotel-sonnblick.at" ]; then
  ok "Admin-Login erfolgreich ($SESSION_EMAIL)"
  LOGGED_IN=true
else
  # Alternativer Login-Versuch mit JSON
  CSRF_RESP2=$(curl -s -c /tmp/mc-cookies.txt "${BASE}/api/auth/csrf")
  CSRF2=$(echo "$CSRF_RESP2" | python3 -c "import sys,json; print(json.load(sys.stdin).get('csrfToken',''))" 2>/dev/null)

  curl -s -o /dev/null \
    -b /tmp/mc-cookies.txt -c /tmp/mc-cookies.txt \
    -X POST "${BASE}/api/auth/callback/credentials" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "csrfToken=${CSRF2}&email=admin%40hotel-sonnblick.at&password=Sonnblick2026!" \
    --max-redirs 5 -L

  SESSION_RESP2=$(curl -s -b /tmp/mc-cookies.txt "${BASE}/api/auth/session")
  SESSION_EMAIL2=$(echo "$SESSION_RESP2" | python3 -c "import sys,json; print(json.load(sys.stdin).get('user',{}).get('email',''))" 2>/dev/null)

  if [ "$SESSION_EMAIL2" = "admin@hotel-sonnblick.at" ]; then
    ok "Admin-Login erfolgreich (2. Versuch)"
    LOGGED_IN=true
  else
    fail "Admin-Login fehlgeschlagen (Session: $SESSION_RESP2)"
    LOGGED_IN=false
    # Direkt aus DB eine Session erzeugen geht nicht, aber wir testen weiter was geht
  fi
fi

# ─── Admin-Seiten ───
section "2. ADMIN-SEITEN"

for PAGE in "/admin" "/admin/design"; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -b /tmp/mc-cookies.txt -L "${BASE}${PAGE}")
  if [ "$CODE" = "200" ]; then
    ok "Admin-Seite ${PAGE}: OK (HTTP $CODE)"
  elif [ "$CODE" = "302" ] || [ "$CODE" = "303" ]; then
    if [ "$LOGGED_IN" = "true" ]; then
      fail "Admin-Seite ${PAGE}: Redirect trotz Login (HTTP $CODE)"
    else
      ok "Admin-Seite ${PAGE}: Redirect zu Login (erwartet ohne Session)"
    fi
  else
    fail "Admin-Seite ${PAGE}: HTTP $CODE"
  fi
done

# ─── Menü-ID aus DB holen (zuverlässiger als API) ───
section "3. DATENBANK-ABFRAGEN"

MENU_ID=$(node -e "
const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();
p.menu.findFirst().then(m => { console.log(m?.id || ''); p.\$disconnect(); });
" 2>/dev/null)

if [ -n "$MENU_ID" ]; then
  ok "Test-Menü-ID: $MENU_ID"
else
  fail "Keine Menü-ID in der Datenbank gefunden"
fi

TENANT_SLUG=$(node -e "
const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();
p.tenant.findFirst({ include: { locations: { include: { menus: true } } } }).then(t => {
  const loc = t?.locations?.[0];
  const menu = loc?.menus?.[0];
  console.log(JSON.stringify({ tenant: t?.slug, location: loc?.slug, menu: menu?.slug }));
  p.\$disconnect();
});
" 2>/dev/null)

T_SLUG=$(echo "$TENANT_SLUG" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tenant',''))" 2>/dev/null)
L_SLUG=$(echo "$TENANT_SLUG" | python3 -c "import sys,json; print(json.load(sys.stdin).get('location',''))" 2>/dev/null)
M_SLUG=$(echo "$TENANT_SLUG" | python3 -c "import sys,json; print(json.load(sys.stdin).get('menu',''))" 2>/dev/null)

if [ -n "$T_SLUG" ]; then
  ok "Tenant: $T_SLUG / Location: $L_SLUG / Menü: $M_SLUG"
else
  warn "Tenant-Slugs konnten nicht ermittelt werden"
fi

# ─── Design-API ───
section "4. DESIGN-API"

if [ -n "$MENU_ID" ]; then
  # GET Design-Config
  DESIGN_RESP=$(curl -s -b /tmp/mc-cookies.txt "${BASE}/api/v1/menus/${MENU_ID}/design")
  DESIGN_CODE=$(curl -s -o /dev/null -w "%{http_code}" -b /tmp/mc-cookies.txt "${BASE}/api/v1/menus/${MENU_ID}/design")

  HAS_CONFIG=$(echo "$DESIGN_RESP" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    has = 'designConfig' in data or 'digital' in data
    print('yes' if has else 'no')
except:
    print('error')
" 2>/dev/null)

  if [ "$HAS_CONFIG" = "yes" ]; then
    ok "Design-Config laden: OK (HTTP $DESIGN_CODE)"
  elif [ "$DESIGN_CODE" = "401" ]; then
    warn "Design-Config laden: 401 (Login fehlgeschlagen, nicht API-Problem)"
  else
    fail "Design-Config laden: Kein designConfig in Antwort (HTTP $DESIGN_CODE)"
  fi

  # PATCH Design-Config
  PATCH_CODE=$(curl -s -o /dev/null -w "%{http_code}" -b /tmp/mc-cookies.txt \
    -X PATCH "${BASE}/api/v1/menus/${MENU_ID}/design" \
    -H "Content-Type: application/json" \
    -d '{"designConfig":{"digital":{"template":"elegant","mood":"warm"}}}')

  if [ "$PATCH_CODE" = "200" ]; then
    ok "Design-Config speichern: OK (HTTP $PATCH_CODE)"
  elif [ "$PATCH_CODE" = "401" ]; then
    warn "Design-Config speichern: 401 (Login-Problem)"
  else
    fail "Design-Config speichern: HTTP $PATCH_CODE"
  fi

  # Persistenz prüfen
  VERIFY_RESP=$(curl -s -b /tmp/mc-cookies.txt "${BASE}/api/v1/menus/${MENU_ID}/design")
  SAVED_MOOD=$(echo "$VERIFY_RESP" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    saved = data.get('savedOverrides', data.get('designConfig', {}))
    digital = saved.get('digital', {})
    print(digital.get('mood', 'NICHT_GEFUNDEN'))
except:
    print('ERROR')
" 2>/dev/null)

  if [ "$SAVED_MOOD" = "warm" ]; then
    ok "Design-Config Persistenz: mood=warm korrekt gespeichert"
  elif [ "$PATCH_CODE" = "401" ]; then
    warn "Persistenz-Check übersprungen (kein Login)"
  else
    fail "Design-Config Persistenz: Erwartet mood=warm, bekommen: $SAVED_MOOD"
  fi

  # Ungültiger Body
  BAD_PATCH=$(curl -s -o /dev/null -w "%{http_code}" -b /tmp/mc-cookies.txt \
    -X PATCH "${BASE}/api/v1/menus/${MENU_ID}/design" \
    -H "Content-Type: application/json" \
    -d '{"invalid":"data"}')

  if [ "$BAD_PATCH" = "400" ]; then
    ok "Validierung: Ungültiger Body abgelehnt (HTTP 400)"
  elif [ "$BAD_PATCH" = "401" ]; then
    warn "Validierung: Nicht testbar (kein Login)"
  else
    warn "Validierung: Ungültiger Body gibt HTTP $BAD_PATCH (erwartet: 400)"
  fi

  # Design-Editor Seite
  DESIGN_PAGE=$(curl -s -o /dev/null -w "%{http_code}" -b /tmp/mc-cookies.txt -L "${BASE}/admin/menus/${MENU_ID}/design")
  if [ "$DESIGN_PAGE" = "200" ]; then
    ok "Design-Editor Seite: OK"
  else
    warn "Design-Editor Seite: HTTP $DESIGN_PAGE"
  fi
fi

# ─── Template-API ───
section "5. DESIGN-TEMPLATES"

TMPL_CODE=$(curl -s -o /dev/null -w "%{http_code}" -b /tmp/mc-cookies.txt "${BASE}/api/v1/design-templates")
if [ "$TMPL_CODE" = "200" ]; then
  ok "Design-Templates Endpunkt: OK (HTTP 200)"
else
  warn "Design-Templates Endpunkt: HTTP $TMPL_CODE"
fi

# ─── Gästeansicht (öffentlich) ───
section "6. GÄSTEANSICHT (öffentlich, ohne Login)"

if [ -n "$T_SLUG" ] && [ -n "$L_SLUG" ]; then
  # Tenant-Seite
  TENANT_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${BASE}/${T_SLUG}")
  if [ "$TENANT_CODE" = "200" ]; then
    ok "Tenant-Seite /${T_SLUG}: OK"
  else
    warn "Tenant-Seite /${T_SLUG}: HTTP $TENANT_CODE"
  fi

  # Location-Seite
  LOC_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${BASE}/${T_SLUG}/${L_SLUG}")
  if [ "$LOC_CODE" = "200" ]; then
    ok "Location-Seite /${T_SLUG}/${L_SLUG}: OK"
  else
    warn "Location-Seite /${T_SLUG}/${L_SLUG}: HTTP $LOC_CODE"
  fi

  # Menü-Seite
  if [ -n "$M_SLUG" ]; then
    MENU_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${BASE}/${T_SLUG}/${L_SLUG}/${M_SLUG}")
    if [ "$MENU_CODE" = "200" ]; then
      ok "Menü-Seite /${T_SLUG}/${L_SLUG}/${M_SLUG}: OK"
    else
      warn "Menü-Seite /${T_SLUG}/${L_SLUG}/${M_SLUG}: HTTP $MENU_CODE"
    fi
  fi
else
  warn "Gästeansicht: Keine Slugs zum Testen gefunden"
fi

# ─── Datenbank-Konsistenz ───
section "7. DATENBANK-KONSISTENZ"

DB_CHECKS=$(node -e "
const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();
(async () => {
  const products = await p.product.count();
  const translations = await p.productTranslation.count();
  const prices = await p.productPrice.count();
  const menus = await p.menu.count();
  const noTrans = await p.product.count({ where: { translations: { none: {} } } });
  const noPrice = await p.product.count({ where: { prices: { none: {} } } });
  const emptyMenus = await p.menu.count({ where: { placements: { none: {} } } });
  console.log(JSON.stringify({ products, translations, prices, menus, noTrans, noPrice, emptyMenus }));
  await p.\$disconnect();
})();
" 2>/dev/null)

if [ -n "$DB_CHECKS" ]; then
  PRODUCTS=$(echo "$DB_CHECKS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['products'])")
  TRANSLATIONS=$(echo "$DB_CHECKS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['translations'])")
  PRICES=$(echo "$DB_CHECKS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['prices'])")
  NO_TRANS=$(echo "$DB_CHECKS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['noTrans'])")
  NO_PRICE=$(echo "$DB_CHECKS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['noPrice'])")
  EMPTY_MENUS=$(echo "$DB_CHECKS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['emptyMenus'])")

  ok "Datenbank: $PRODUCTS Produkte, $TRANSLATIONS Übersetzungen, $PRICES Preise"

  if [ "$NO_TRANS" = "0" ]; then
    ok "Alle Produkte haben Übersetzungen"
  else
    warn "$NO_TRANS Produkte ohne Übersetzung"
  fi

  if [ "$NO_PRICE" = "0" ]; then
    ok "Alle Produkte haben Preise"
  else
    warn "$NO_PRICE Produkte ohne Preis"
  fi

  if [ "$EMPTY_MENUS" = "0" ]; then
    ok "Alle Menüs haben Produkte zugeordnet"
  else
    warn "$EMPTY_MENUS Menüs ohne zugeordnete Produkte"
  fi
else
  fail "Datenbank-Konsistenzprüfung fehlgeschlagen"
fi

# ─── Build & Prozess ───
section "8. BUILD & PROZESS"

# PM2
PM2_STATUS=$(pm2 jlist 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for p in data:
        if 'menucard' in p.get('name','').lower():
            status = p['pm2_env']['status']
            restarts = p['pm2_env'].get('restart_time', 0)
            print(f'{p[\"name\"]}: {status} (restarts: {restarts})')
except:
    print('ERROR')
" 2>/dev/null)

if echo "$PM2_STATUS" | grep -q "online"; then
  ok "PM2: $PM2_STATUS"
else
  fail "PM2: $PM2_STATUS"
fi

# Disk
DISK=$(df -h /var/www/menucard-pro | tail -1 | awk '{print $5}')
DISK_NUM=$(echo "$DISK" | tr -d '%')
if [ "$DISK_NUM" -lt "80" ] 2>/dev/null; then
  ok "Festplatte: $DISK belegt"
elif [ "$DISK_NUM" -lt "90" ] 2>/dev/null; then
  warn "Festplatte: $DISK belegt – wird voll"
else
  fail "Festplatte: $DISK belegt – KRITISCH"
fi

# ─── Ergebnis ───
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║     MenuCard Pro – Bugtest-Ergebnisse        ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  ✅ Bestanden: $PASS"
echo "║  ❌ Fehlgeschlagen: $FAIL"
echo "║  ⚠️  Warnungen: $WARN"
echo "╚══════════════════════════════════════════════╝"

rm -f /tmp/mc-cookies.txt
