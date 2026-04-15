#!/bin/bash
set -e
echo "============================================"
echo "  SSL & Domain Setup: menu.hotel-sonnblick.at"
echo "============================================"

DOMAIN="menu.hotel-sonnblick.at"
EMAIL="hotelsonnblick@gmail.com"

# ============================================
# 1. DNS-VERIFIKATION
# ============================================
echo "[1/5] DNS prüfen..."

RESOLVED_IP=$(dig +short "$DOMAIN" @8.8.8.8 2>/dev/null | tail -1)
EXPECTED_IP="178.104.138.177"

if [ "$RESOLVED_IP" = "$EXPECTED_IP" ]; then
  echo "  ✓ DNS OK: $DOMAIN → $RESOLVED_IP"
else
  echo "  ✗ DNS: $DOMAIN → $RESOLVED_IP (erwartet: $EXPECTED_IP)"
  echo ""
  echo "  DNS noch nicht propagiert. Das kann bis zu 24h dauern."
  echo "  Prüfen mit: dig $DOMAIN @8.8.8.8"
  echo ""
  read -p "  Trotzdem fortfahren? (j/n) " ANSWER
  if [ "$ANSWER" != "j" ]; then
    exit 1
  fi
fi

# ============================================
# 2. CERTBOT INSTALLIEREN (falls nicht vorhanden)
# ============================================
echo ""
echo "[2/5] Certbot prüfen..."

if ! command -v certbot > /dev/null 2>&1; then
  echo "  Certbot installieren..."
  apt-get update -qq
  apt-get install -y certbot python3-certbot-nginx
else
  echo "  ✓ Certbot bereits installiert: $(certbot --version 2>&1)"
fi

# ============================================
# 3. NGINX-KONFIGURATION VORBEREITEN
# ============================================
echo ""
echo "[3/5] Nginx-Konfiguration..."

NGINX_CONF="/etc/nginx/sites-available/menucard-pro"
NGINX_LINK="/etc/nginx/sites-enabled/menucard-pro"

# Backup aktuelle Config
cp /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.pre-ssl-$(date +%Y%m%d) 2>/dev/null || true

# Neue Konfiguration für HTTP (Certbot nutzt dies für Challenge)
cat > "$NGINX_CONF" << NGXEOF
# MenuCard Pro – HTTP (wird von Certbot ersetzt)
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;

    client_max_body_size 10M;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Sensitive Dateien blockieren
    location ~ /\.git { deny all; return 404; }
    location ~ /prisma { deny all; return 404; }
    location ~ \.env\$ { deny all; return 404; }
    location ~ \.bak\$ { deny all; return 404; }
    location ~ \.sh\$ { deny all; return 404; }
    location ~ \.sql\$ { deny all; return 404; }

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
NGXEOF

# Symlink aktivieren
ln -sf "$NGINX_CONF" "$NGINX_LINK"

# Alte default deaktivieren falls sie stört
if [ -f "/etc/nginx/sites-enabled/default" ]; then
  mv /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default.disabled-$(date +%Y%m%d)
  echo "  default Site deaktiviert"
fi

# Test
if nginx -t 2>&1 | grep -q "successful"; then
  systemctl reload nginx
  echo "  ✓ Nginx: HTTP-Konfig aktiv"
else
  echo "  ✗ Nginx Config Fehler:"
  nginx -t
  exit 1
fi

# ============================================
# 4. SSL-ZERTIFIKAT VIA CERTBOT
# ============================================
echo ""
echo "[4/5] SSL-Zertifikat via Let's Encrypt..."

# Certbot ausführen mit automatischer Nginx-Konfiguration
certbot --nginx \
  -d "$DOMAIN" \
  --non-interactive \
  --agree-tos \
  --email "$EMAIL" \
  --redirect \
  --no-eff-email 2>&1 | tail -20

# Prüfen ob Zertifikat vorhanden
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
  echo "  ✓ SSL-Zertifikat erstellt"
  EXPIRY=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" | cut -d= -f2)
  echo "  Gültig bis: $EXPIRY"
else
  echo "  ✗ SSL-Zertifikat konnte nicht erstellt werden"
  exit 1
fi

# ============================================
# 5. NEXTAUTH_URL AKTUALISIEREN
# ============================================
echo ""
echo "[5/5] NEXTAUTH_URL in .env aktualisieren..."

cd /var/www/menucard-pro

# Backup .env
cp .env .env.pre-ssl-$(date +%Y%m%d)

# NEXTAUTH_URL auf neue Domain setzen
if grep -q "^NEXTAUTH_URL=" .env; then
  sed -i "s|^NEXTAUTH_URL=.*|NEXTAUTH_URL=https://$DOMAIN|" .env
  echo "  ✓ NEXTAUTH_URL aktualisiert: https://$DOMAIN"
else
  echo "NEXTAUTH_URL=https://$DOMAIN" >> .env
  echo "  ✓ NEXTAUTH_URL hinzugefügt"
fi

# PM2 neu starten damit neue .env geladen wird
pm2 restart menucard-pro --update-env
echo "  ✓ PM2 neu gestartet"

# Auto-Renewal testen
echo ""
echo "  Certbot Auto-Renewal testen (Dry-Run)..."
certbot renew --dry-run 2>&1 | tail -5

# ============================================
# 6. FINAL TESTS
# ============================================
echo ""
echo "============================================"
echo "  FINAL TESTS"
echo "============================================"

sleep 3

# HTTP → HTTPS Redirect
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN" 2>/dev/null)
echo "  HTTP → HTTPS Redirect: $HTTP_CODE (erwartet: 301)"

# HTTPS
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" 2>/dev/null)
echo "  HTTPS Response: $HTTPS_CODE (erwartet: 200)"

# SSL Zertifikat
echo "  SSL Zertifikat:"
echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null | openssl x509 -noout -subject -dates 2>/dev/null | sed 's/^/    /'

# Security Headers über HTTPS
echo "  Security Headers (HTTPS):"
curl -sI "https://$DOMAIN" 2>/dev/null | grep -iE "x-frame|x-content|x-xss|referrer|strict-transport" | sed 's/^/    /'

# Geschützte Pfade
echo "  Geschützte Pfade:"
for path in "/.git/config" "/prisma/schema.prisma" "/.env"; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN$path" 2>/dev/null)
  echo "    $path → $CODE"
done

# Gästeansicht
echo "  Gästeansicht:"
GUEST_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/hotel-sonnblick/restaurant/jaegerabend" 2>/dev/null)
echo "    /hotel-sonnblick/restaurant/jaegerabend → $GUEST_CODE (erwartet: 200)"

echo ""
echo "============================================"
echo "  SSL & DOMAIN SETUP ABGESCHLOSSEN"
echo "============================================"
echo ""
echo "  Produktiv-URL: https://$DOMAIN"
echo "  Admin-URL:     https://$DOMAIN/admin"
echo ""
echo "  Auto-Renewal: läuft via systemd (certbot.timer)"
echo "  Manueller Renewal-Test: certbot renew --dry-run"
echo ""
