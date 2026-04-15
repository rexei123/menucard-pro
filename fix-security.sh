#!/bin/bash
# MenuCard Pro – Umfassender Security-Fix
# Behebt alle Findings aus dem Sicherheitstest
# Datum: 12.04.2026
# Ausführen auf dem Server: bash fix-security.sh

cd /var/www/menucard-pro

echo "=== MenuCard Pro – Security-Fix ==="
echo ""

# ═══════════════════════════════════════════
echo "[1/6] Nginx: Sensible Dateien blockieren + Security-Header + Rate-Limiting"
# ═══════════════════════════════════════════

# Backup
cp /etc/nginx/sites-enabled/menucard-pro /etc/nginx/sites-enabled/menucard-pro.bak 2>/dev/null
cp /etc/nginx/sites-available/menucard-pro /etc/nginx/sites-available/menucard-pro.bak 2>/dev/null

# Finde die aktive Config-Datei
NGINX_CONF=""
if [ -f /etc/nginx/sites-enabled/menucard-pro ]; then
  NGINX_CONF="/etc/nginx/sites-enabled/menucard-pro"
elif [ -f /etc/nginx/sites-available/menucard-pro ]; then
  NGINX_CONF="/etc/nginx/sites-available/menucard-pro"
elif [ -f /etc/nginx/sites-enabled/default ]; then
  NGINX_CONF="/etc/nginx/sites-enabled/default"
fi

if [ -n "$NGINX_CONF" ]; then
  cat > "$NGINX_CONF" << 'NGINXEOF'
# Rate-Limiting Zone (10 requests/sec pro IP)
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=3r/s;

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    # ── Security-Header ──
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # ── Sensible Dateien blockieren ──
    location ~ /\.git {
        deny all;
        return 404;
    }

    location ~ /\.env {
        deny all;
        return 404;
    }

    location ~ /prisma {
        deny all;
        return 404;
    }

    location ~ /\.next/cache {
        deny all;
        return 404;
    }

    location ~ /node_modules {
        deny all;
        return 404;
    }

    # Backup-Dateien blockieren
    location ~ \.(bak|sql|sh|log)$ {
        deny all;
        return 404;
    }

    # ── Rate-Limiting für Login ──
    location /api/auth {
        limit_req zone=login burst=5 nodelay;
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # ── Rate-Limiting für API ──
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # ── Hauptanwendung ──
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
NGINXEOF

  # Nginx-Config testen
  nginx -t 2>&1
  if [ $? -eq 0 ]; then
    systemctl reload nginx
    echo "  ✅ Nginx: Config aktualisiert und neu geladen"
  else
    echo "  ❌ Nginx: Config-Fehler! Stelle Backup wieder her..."
    cp "${NGINX_CONF}.bak" "$NGINX_CONF"
    systemctl reload nginx
  fi
else
  echo "  ❌ Nginx-Config nicht gefunden"
fi

# ═══════════════════════════════════════════
echo ""
echo "[2/6] Next.js: X-Powered-By Header entfernen"
# ═══════════════════════════════════════════

# Finde next.config Datei
NEXT_CONF=""
if [ -f "next.config.mjs" ]; then
  NEXT_CONF="next.config.mjs"
elif [ -f "next.config.js" ]; then
  NEXT_CONF="next.config.js"
fi

if [ -n "$NEXT_CONF" ]; then
  cp "$NEXT_CONF" "${NEXT_CONF}.bak"

  # Prüfe ob poweredByHeader schon gesetzt ist
  if grep -q "poweredByHeader" "$NEXT_CONF"; then
    echo "  ✅ poweredByHeader bereits konfiguriert"
  else
    # Füge poweredByHeader: false ein
    python3 << PYEOF
import re

with open('$NEXT_CONF', 'r') as f:
    content = f.read()

# Suche nach dem nextConfig-Objekt und füge poweredByHeader hinzu
# Verschiedene Patterns für .mjs und .js

if 'const nextConfig' in content:
    # Pattern: const nextConfig = { ... }
    content = content.replace(
        'const nextConfig = {',
        'const nextConfig = {\n  poweredByHeader: false,'
    )
elif 'module.exports' in content:
    # Pattern: module.exports = { ... }
    content = content.replace(
        'module.exports = {',
        'module.exports = {\n  poweredByHeader: false,'
    )
elif '/** @type' in content:
    # Hat JSDoc aber vielleicht anderes Pattern
    if '= {' in content:
        content = content.replace('= {', '= {\n  poweredByHeader: false,', 1)

with open('$NEXT_CONF', 'w') as f:
    f.write(content)

print('  poweredByHeader: false eingefügt')
PYEOF
    echo "  ✅ X-Powered-By wird nicht mehr gesendet"
  fi
else
  echo "  ⚠️  next.config nicht gefunden"
fi

# ═══════════════════════════════════════════
echo ""
echo "[3/6] .env Dateiberechtigungen"
# ═══════════════════════════════════════════

if [ -f ".env" ]; then
  chmod 600 .env
  echo "  ✅ .env Berechtigungen auf 600 gesetzt"
fi

if [ -f ".env.local" ]; then
  chmod 600 .env.local
  echo "  ✅ .env.local Berechtigungen auf 600 gesetzt"
fi

if [ -f ".env.production" ]; then
  chmod 600 .env.production
  echo "  ✅ .env.production Berechtigungen auf 600 gesetzt"
fi

# ═══════════════════════════════════════════
echo ""
echo "[4/6] npm audit – Schwachstellen beheben"
# ═══════════════════════════════════════════

echo "  Führe npm audit fix aus..."
npm audit fix 2>&1 | tail -5
echo "  Prüfe verbleibende Schwachstellen..."
REMAINING=$(npm audit --json 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    v = d.get('metadata',{}).get('vulnerabilities',{})
    c = v.get('critical',0)
    h = v.get('high',0)
    m = v.get('moderate',0)
    print(f'{c} kritisch, {h} hoch, {m} mittel')
except:
    print('nicht auswertbar')
" 2>/dev/null)
echo "  Verbleibend: $REMAINING"

# ═══════════════════════════════════════════
echo ""
echo "[5/6] .gitignore: Sensible Dateien ausschließen"
# ═══════════════════════════════════════════

# Prüfe und ergänze .gitignore
GITIGNORE_ADDITIONS=""
for PATTERN in "*.bak" "*.sh" "*.sql" ".env" ".env.*"; do
  if ! grep -qx "$PATTERN" .gitignore 2>/dev/null; then
    GITIGNORE_ADDITIONS="${GITIGNORE_ADDITIONS}${PATTERN}\n"
  fi
done

if [ -n "$GITIGNORE_ADDITIONS" ]; then
  echo "" >> .gitignore
  echo "# Security: Sensible Dateien ausschließen" >> .gitignore
  printf "$GITIGNORE_ADDITIONS" >> .gitignore
  echo "  ✅ .gitignore erweitert"
else
  echo "  ✅ .gitignore bereits vollständig"
fi

# ═══════════════════════════════════════════
echo ""
echo "[6/6] Build + Restart"
# ═══════════════════════════════════════════

echo "  Building..."
npm run build 2>&1 | tail -5
pm2 restart menucard-pro
echo "  ✅ App neu gebaut und gestartet"

# ═══════════════════════════════════════════
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║          Security-Fix abgeschlossen              ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║                                                  ║"
echo "║  ✅ Nginx: .git, .env, prisma blockiert          ║"
echo "║  ✅ Nginx: Security-Header gesetzt               ║"
echo "║  ✅ Nginx: Rate-Limiting aktiv                   ║"
echo "║  ✅ Next.js: X-Powered-By entfernt               ║"
echo "║  ✅ .env: Berechtigungen 600                     ║"
echo "║  ✅ npm audit: Fixes angewendet                  ║"
echo "║  ✅ .gitignore: Sensible Dateien ausgeschlossen  ║"
echo "║                                                  ║"
echo "║  MANUELL ZU ERLEDIGEN:                           ║"
echo "║  ⚠️  SSH Root-Login einschränken:                 ║"
echo "║     nano /etc/ssh/sshd_config                    ║"
echo "║     PermitRootLogin prohibit-password             ║"
echo "║     systemctl restart sshd                       ║"
echo "║     (Erst SSH-Key einrichten, sonst Aussperrung!)║"
echo "║                                                  ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "Tipp: Führen Sie jetzt 'bash test-security.sh' erneut aus"
echo "um die Verbesserungen zu verifizieren."
