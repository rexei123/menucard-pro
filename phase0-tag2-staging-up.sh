#!/usr/bin/env bash
# =============================================================================
# Phase 0 Tag 2 Schritt 2: Staging PM2 + Nginx + Basic-Auth (+ optional SSL)
#
# Idempotent. Kann mehrfach ausgefuehrt werden.
# Erwartet: Staging-Build unter $STAGING_DIR existiert (Schritt 1 done).
#
# Steuerung:
#   ENABLE_SSL=1   -> macht DNS-Check + certbot --nginx + HTTPS-Smoke
#   (default)      -> nur PM2 + Basic-Auth + HTTP-Nginx, kein SSL, kein DNS-Check
# =============================================================================
set -euo pipefail

STAGING_DIR="/var/www/menucard-pro-staging"
STAGING_PORT=3001
STAGING_DOMAIN="staging.menu.hotel-sonnblick.at"
PM2_NAME="menucard-pro-staging"
BASIC_AUTH_USER="sonnblick"
HTPASSWD_FILE="/etc/nginx/.htpasswd-staging"
NGINX_VHOST="/etc/nginx/sites-available/${STAGING_DOMAIN}"
NGINX_LINK="/etc/nginx/sites-enabled/${STAGING_DOMAIN}"
SECRET_FILE="/root/.secrets/staging-basic-auth.txt"
SERVER_IP="178.104.138.177"
ENABLE_SSL="${ENABLE_SSL:-0}"
LOG_PREFIX=">>"

say() { echo -e "\n${LOG_PREFIX} $*"; }
ok()  { echo "   OK: $*"; }
err() { echo "   FEHLER: $*" >&2; }

# -----------------------------------------------------------------------------
# 0. Preflight
# -----------------------------------------------------------------------------
say "0) Preflight"

[ -d "$STAGING_DIR" ] || { err "$STAGING_DIR fehlt - erst Schritt 1 ausfuehren"; exit 1; }
[ -d "$STAGING_DIR/.next" ] || { err "$STAGING_DIR/.next fehlt - Staging-Build nicht vorhanden"; exit 1; }
[ -f "$STAGING_DIR/.env" ] || { err "$STAGING_DIR/.env fehlt"; exit 1; }
command -v pm2 >/dev/null || { err "pm2 nicht installiert"; exit 1; }
command -v nginx >/dev/null || { err "nginx nicht installiert"; exit 1; }
ok "Build+Binaries vorhanden"

# apache2-utils fuer htpasswd
if ! command -v htpasswd >/dev/null; then
    say "0a) apache2-utils installieren (fuer htpasswd)"
    apt-get update -qq
    apt-get install -y -qq apache2-utils
fi
ok "htpasswd verfuegbar"

if [ "$ENABLE_SSL" = "1" ]; then
    # -----------------------------------------------------------------------------
    # 1. DNS-Check (nur wenn SSL gewuenscht)
    # -----------------------------------------------------------------------------
    say "1) DNS-Check fuer $STAGING_DOMAIN"
    RESOLVED=$(getent hosts "$STAGING_DOMAIN" | awk '{print $1}' | head -n 1 || true)
    if [ -z "$RESOLVED" ]; then
        err "$STAGING_DOMAIN loest nicht auf"
        err "Bitte DNS A-Record setzen: $STAGING_DOMAIN -> $SERVER_IP"
        exit 2
    fi
    if [ "$RESOLVED" != "$SERVER_IP" ]; then
        err "$STAGING_DOMAIN zeigt auf $RESOLVED, erwartet $SERVER_IP"
        exit 2
    fi
    ok "DNS: $STAGING_DOMAIN -> $RESOLVED"

    command -v certbot >/dev/null || { err "certbot nicht installiert - bitte 'apt install certbot python3-certbot-nginx'"; exit 1; }
    ok "certbot verfuegbar"
else
    say "1) DNS-Check uebersprungen (ENABLE_SSL=0)"
    ok "HTTP-Only Betrieb, certbot-Schritt wird spaeter nachgezogen"
fi

# -----------------------------------------------------------------------------
# 2. NEXTAUTH_URL in .env setzen (idempotent)
#    Auch ohne SSL bereits auf https://... setzen, damit nach certbot nichts mehr
#    geaendert werden muss und Login direkt ueber externe URL funktioniert.
# -----------------------------------------------------------------------------
say "2) NEXTAUTH_URL in Staging-.env setzen"
if [ "$ENABLE_SSL" = "1" ]; then
    TARGET_URL="https://${STAGING_DOMAIN}"
else
    # Ohne SSL: fuer lokalen SSH-Tunnel-Test ist die localhost-URL die richtige;
    # bei NEXTAUTH_URL geht es um Redirect-Targets, die muessen der aufrufenden
    # URL entsprechen. Wir setzen deshalb vorlaeufig auf http://127.0.0.1:3001.
    TARGET_URL="http://127.0.0.1:${STAGING_PORT}"
fi
if grep -q '^NEXTAUTH_URL=' "$STAGING_DIR/.env"; then
    sed -i "s|^NEXTAUTH_URL=.*|NEXTAUTH_URL=${TARGET_URL}|" "$STAGING_DIR/.env"
else
    echo "NEXTAUTH_URL=${TARGET_URL}" >> "$STAGING_DIR/.env"
fi
ok "NEXTAUTH_URL=${TARGET_URL}"

# -----------------------------------------------------------------------------
# 3. PM2 Prozess starten / neustarten
# -----------------------------------------------------------------------------
say "3) PM2: Staging-App starten"
cd "$STAGING_DIR"

if pm2 describe "$PM2_NAME" >/dev/null 2>&1; then
    ok "PM2-Prozess $PM2_NAME existiert - restart"
    PORT="$STAGING_PORT" pm2 restart "$PM2_NAME" --update-env
else
    ok "PM2-Prozess $PM2_NAME neu starten"
    PORT="$STAGING_PORT" pm2 start npm --name "$PM2_NAME" -- start
fi
pm2 save >/dev/null
ok "PM2: $PM2_NAME laeuft"

# Smoke-Test auf localhost:3001
say "3a) Smoke-Test 127.0.0.1:${STAGING_PORT}"
sleep 3
for i in 1 2 3 4 5; do
    HTTP_CODE=$(curl -o /dev/null -s -w '%{http_code}' "http://127.0.0.1:${STAGING_PORT}/" || echo "000")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "307" ] || [ "$HTTP_CODE" = "308" ]; then
        ok "Loopback: HTTP $HTTP_CODE"
        break
    fi
    if [ $i -eq 5 ]; then
        err "Loopback smoke failed, HTTP $HTTP_CODE"
        pm2 logs "$PM2_NAME" --lines 30 --nostream || true
        exit 3
    fi
    sleep 2
done

# -----------------------------------------------------------------------------
# 4. htpasswd (sonnblick / random) - Passwort nur einmal generieren
# -----------------------------------------------------------------------------
say "4) Basic-Auth: htpasswd"
mkdir -p /root/.secrets
chmod 700 /root/.secrets

if [ -f "$SECRET_FILE" ] && [ -f "$HTPASSWD_FILE" ]; then
    ok "htpasswd existiert bereits - Passwort wiederverwendet"
    BASIC_PASS=$(grep '^PASS=' "$SECRET_FILE" | cut -d= -f2-)
else
    BASIC_PASS=$(openssl rand -base64 27 | tr -d '/+=' | head -c 24)
    htpasswd -cbB "$HTPASSWD_FILE" "$BASIC_AUTH_USER" "$BASIC_PASS"
    chown root:www-data "$HTPASSWD_FILE"
    chmod 640 "$HTPASSWD_FILE"
    {
        echo "USER=${BASIC_AUTH_USER}"
        echo "PASS=${BASIC_PASS}"
        echo "DOMAIN=${STAGING_DOMAIN}"
    } > "$SECRET_FILE"
    chmod 600 "$SECRET_FILE"
    ok "htpasswd erstellt (User: $BASIC_AUTH_USER)"
fi

# -----------------------------------------------------------------------------
# 5. Nginx VHost (HTTP-only - certbot --nginx ergaenzt SSL spaeter)
# -----------------------------------------------------------------------------
say "5) Nginx VHost"
if [ ! -f "$NGINX_VHOST" ]; then
    cat > "$NGINX_VHOST" <<EOF
# Staging: staging.menu.hotel-sonnblick.at
# Basic-Auth geschuetzt, proxy -> 127.0.0.1:${STAGING_PORT}
# Ohne SSL - certbot --nginx wird nach DNS-Setup aufgerufen.
server {
    listen 80;
    listen [::]:80;
    server_name ${STAGING_DOMAIN};

    client_max_body_size 32M;

    # ACME challenge (certbot webroot fallback)
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        auth_basic "MenuCard Pro Staging";
        auth_basic_user_file ${HTPASSWD_FILE};

        proxy_pass http://127.0.0.1:${STAGING_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 90s;
    }
}
EOF
    ln -sf "$NGINX_VHOST" "$NGINX_LINK"
    ok "VHost erstellt: $NGINX_VHOST"
else
    ok "VHost existiert - unveraendert gelassen"
fi

if ! grep -q "auth_basic_user_file" "$NGINX_VHOST"; then
    err "VHost $NGINX_VHOST ohne auth_basic - bitte manuell pruefen"
    exit 4
fi

# -----------------------------------------------------------------------------
# 6. Nginx Syntax + Reload
# -----------------------------------------------------------------------------
say "6) Nginx: Config-Test + Reload"
nginx -t
systemctl reload nginx
# Warten bis reload tatsaechlich durch ist (Ubuntu systemd macht das asynchron)
for i in 1 2 3 4 5 6 7 8; do
    sleep 1
    # Test: matcht unsere server_name-Regel?
    CODE=$(curl -o /dev/null -s -w '%{http_code}' -H "Host: ${STAGING_DOMAIN}" "http://127.0.0.1/" || echo "000")
    if [ "$CODE" = "401" ]; then break; fi
done
ok "Nginx reloaded (reload-wait: ${i}s, Probe-Code: $CODE)"

# -----------------------------------------------------------------------------
# 7. (optional) Let's Encrypt
# -----------------------------------------------------------------------------
if [ "$ENABLE_SSL" = "1" ]; then
    say "7) Let's Encrypt"
    if [ -d "/etc/letsencrypt/live/${STAGING_DOMAIN}" ]; then
        ok "Zertifikat fuer $STAGING_DOMAIN existiert bereits"
    else
        ADMIN_EMAIL=$(certbot certificates 2>/dev/null | grep -oE '^[[:space:]]*Email: .*' | head -n 1 | sed 's/.*Email: //' || echo "")
        [ -z "$ADMIN_EMAIL" ] && ADMIN_EMAIL="admin@hotel-sonnblick.at"
        certbot --nginx -d "$STAGING_DOMAIN" \
            --non-interactive --agree-tos \
            --email "$ADMIN_EMAIL" \
            --redirect
        ok "SSL installiert (Email: $ADMIN_EMAIL)"
    fi

    # NEXTAUTH_URL jetzt auf https setzen (falls nicht schon)
    sed -i "s|^NEXTAUTH_URL=.*|NEXTAUTH_URL=https://${STAGING_DOMAIN}|" "$STAGING_DIR/.env"
    PORT="$STAGING_PORT" pm2 restart "$PM2_NAME" --update-env >/dev/null
    ok "NEXTAUTH_URL auf https://${STAGING_DOMAIN} aktualisiert + PM2 restart"
else
    say "7) Let's Encrypt uebersprungen (ENABLE_SSL=0)"
fi

# -----------------------------------------------------------------------------
# 8. Smoke-Tests
# -----------------------------------------------------------------------------
say "8) Smoke-Tests"
BASIC_PASS=$(grep '^PASS=' "$SECRET_FILE" | cut -d= -f2-)

# 8a) Nginx via Host-Header auf Port 80 (lokal, ohne DNS)
HTTP_CODE=$(curl -o /dev/null -s -w '%{http_code}' \
    -H "Host: ${STAGING_DOMAIN}" \
    "http://127.0.0.1/" || echo "000")
if [ "$HTTP_CODE" = "401" ]; then
    ok "Nginx HTTP ohne Auth: 401 (Basic-Auth aktiv)"
else
    err "Nginx HTTP ohne Auth: $HTTP_CODE (erwartet 401)"
    exit 5
fi

HTTP_CODE=$(curl -o /dev/null -s -w '%{http_code}' \
    -H "Host: ${STAGING_DOMAIN}" \
    -u "${BASIC_AUTH_USER}:${BASIC_PASS}" \
    "http://127.0.0.1/" || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "307" ] || [ "$HTTP_CODE" = "308" ]; then
    ok "Nginx HTTP mit Auth: $HTTP_CODE"
else
    err "Nginx HTTP mit Auth: $HTTP_CODE"
    exit 5
fi

# 8b) HTTPS nur wenn SSL aktiv
if [ "$ENABLE_SSL" = "1" ]; then
    HTTP_CODE=$(curl -o /dev/null -s -w '%{http_code}' -k "https://${STAGING_DOMAIN}/" || echo "000")
    if [ "$HTTP_CODE" = "401" ]; then
        ok "HTTPS ohne Auth: 401"
    else
        err "HTTPS ohne Auth: $HTTP_CODE (erwartet 401)"
        exit 5
    fi

    HTTP_CODE=$(curl -o /dev/null -s -w '%{http_code}' -k \
        -u "${BASIC_AUTH_USER}:${BASIC_PASS}" \
        "https://${STAGING_DOMAIN}/" || echo "000")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "307" ] || [ "$HTTP_CODE" = "308" ]; then
        ok "HTTPS mit Auth: $HTTP_CODE"
    else
        err "HTTPS mit Auth: $HTTP_CODE"
        exit 5
    fi
fi

# -----------------------------------------------------------------------------
# 9. Ausgabe
# -----------------------------------------------------------------------------
say "9) Fertig"
echo ""
if [ "$ENABLE_SSL" = "1" ]; then
    echo "=== Staging-URL (extern) ==="
    echo "  https://${STAGING_DOMAIN}"
else
    echo "=== Staging-URL (DNS fehlt noch) ==="
    echo "  Direkt-Zugriff ueber SSH-Tunnel:"
    echo "    ssh -L ${STAGING_PORT}:127.0.0.1:${STAGING_PORT} root@${SERVER_IP}"
    echo "    -> http://127.0.0.1:${STAGING_PORT}  (ohne Basic-Auth, direkt auf PM2)"
    echo ""
    echo "  Nginx-Pfad via Host-Header (auf dem Server getestet, 401/200 = OK):"
    echo "    curl -H 'Host: ${STAGING_DOMAIN}' http://127.0.0.1/"
    echo ""
    echo "  Sobald DNS-A-Record gesetzt ist, SSL nachziehen mit:"
    echo "    ENABLE_SSL=1 bash /root/phase0-tag2-staging-up.sh"
fi
echo ""
echo "=== Basic-Auth Zugangsdaten ==="
echo "  User: ${BASIC_AUTH_USER}"
echo "  Pass: ${BASIC_PASS}"
echo "  (persistiert in ${SECRET_FILE}, mode 600)"
echo ""
echo "=== PM2 Status ==="
pm2 list --no-color 2>/dev/null | sed -n '1,20p' || pm2 status
echo ""
if [ "$ENABLE_SSL" = "1" ]; then
    echo "Naechster Schritt: Phase 0 Tag 2 Schritt 3 - Staging-Seed-Script"
else
    echo "Naechste Schritte:"
    echo "  - Phase 0 Tag 2 Schritt 3: Staging-Seed-Script (DNS-unabhaengig)"
    echo "  - In ~3 Tagen wenn DNS da ist: ENABLE_SSL=1 bash /root/phase0-tag2-staging-up.sh"
fi
