# Deployment

Produktions-Setup für `menu.hotel-sonnblick.at` auf einem Hetzner CX22 (Ubuntu 24.04 LTS).

## Infrastruktur

| Komponente | Version / Spezifikation |
|---|---|
| Server | Hetzner CX22, Ubuntu 24.04 LTS, IP `178.104.138.177` |
| Runtime | Node.js 22 LTS |
| Prozess-Manager | PM2 (Autostart via systemd) |
| Webserver | Nginx als Reverse-Proxy |
| Datenbank | PostgreSQL 15 (lokal, `127.0.0.1:5432`) |
| SSL | Let's Encrypt (certbot, Auto-Renewal via systemd-Timer) |
| Repository | GitHub `rexei123/menucard-pro` (Branch `main`) |

App-Verzeichnis: `/var/www/menucard-pro`.

## Deployment-Flow

```
Entwickler-PC                GitHub                     Server
──────────────               ──────                     ──────
1. Code-Änderung              git push → main            git pull (manuell)
2. Commit + Push                                         npm install (falls deps)
                                                         npx prisma db push (falls schema)
                                                         npm run build
                                                         pm2 restart menucard-pro
                                                         curl-Smoke-Test
```

## Erstes Setup (einmalig)

### 1. System-Pakete

```bash
apt update && apt upgrade -y
apt install -y curl git build-essential nginx postgresql postgresql-contrib certbot python3-certbot-nginx ufw
```

### 2. Node.js 22

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs
npm install -g pm2
```

### 3. PostgreSQL

```bash
sudo -u postgres psql <<SQL
CREATE USER menucard WITH PASSWORD 'STARKES_PASSWORT';
CREATE DATABASE menucard_pro OWNER menucard;
\q
SQL
```

### 4. App klonen

```bash
mkdir -p /var/www && cd /var/www
git clone https://github.com/rexei123/menucard-pro.git
cd menucard-pro
npm install
```

### 5. Umgebungsvariablen

`/var/www/menucard-pro/.env` (Permissions `600`, Owner `root:root`):

```dotenv
DATABASE_URL="postgresql://menucard:STARKES_PASSWORT@127.0.0.1:5432/menucard_pro"
NEXTAUTH_URL="https://menu.hotel-sonnblick.at"
NEXTAUTH_SECRET="<openssl rand -base64 32>"
S3_ENDPOINT=""
S3_BUCKET=""
S3_ACCESS_KEY=""
S3_SECRET_KEY=""
SEARXNG_URL="http://127.0.0.1:8888"
```

### 6. Datenbank initialisieren

```bash
npx prisma generate
npx prisma db push
npx prisma db seed   # optional: Demo-Daten
```

### 7. Build & PM2

```bash
npm run build
pm2 start npm --name menucard-pro -- start
pm2 save
pm2 startup systemd -u root --hp /root   # einmaliges Autostart-Setup
```

### 8. Nginx

Konfiguration unter `/etc/nginx/sites-available/menucard-pro`:

```nginx
limit_req_zone $binary_remote_addr zone=api_zone:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login_zone:10m rate=3r/s;

server {
    listen 443 ssl http2;
    server_name menu.hotel-sonnblick.at;

    ssl_certificate     /etc/letsencrypt/live/menu.hotel-sonnblick.at/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/menu.hotel-sonnblick.at/privkey.pem;

    # Security-Header
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Block-Regeln
    location ~ /\.(git|env) { deny all; return 404; }
    location ~ /prisma     { deny all; return 404; }
    location ~ \.(bak|sh|sql|log)$ { deny all; return 404; }
    location /node_modules { deny all; return 404; }

    # Rate-Limits
    location /api/auth/ {
        limit_req zone=login_zone burst=5 nodelay;
        proxy_pass http://127.0.0.1:3000;
        include /etc/nginx/conf.d/proxy-params.conf;
    }

    location /api/ {
        limit_req zone=api_zone burst=20 nodelay;
        proxy_pass http://127.0.0.1:3000;
        include /etc/nginx/conf.d/proxy-params.conf;
    }

    location / {
        proxy_pass http://127.0.0.1:3000;
        include /etc/nginx/conf.d/proxy-params.conf;
    }
}

server {
    listen 80;
    server_name menu.hotel-sonnblick.at;
    return 301 https://$host$request_uri;
}
```

Upload-Limit (`/etc/nginx/conf.d/upload.conf`): `client_max_body_size 10M;`

```bash
ln -s /etc/nginx/sites-available/menucard-pro /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

### 9. SSL-Zertifikat

```bash
certbot --nginx -d menu.hotel-sonnblick.at --redirect --agree-tos -m hotelsonnblick@gmail.com
```

Auto-Renewal (standardmäßig via `certbot.timer`):

```bash
systemctl status certbot.timer
certbot renew --dry-run
```

### 10. Firewall

```bash
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw enable
```

## Regel-Deployment (laufend)

```bash
ssh root@178.104.138.177
cd /var/www/menucard-pro
git pull
npm install              # falls package.json verändert
npx prisma db push       # falls schema.prisma verändert
npm run build
pm2 restart menucard-pro
pm2 logs menucard-pro --lines 50 --nostream
```

Smoke-Test danach:

```bash
curl -sI https://menu.hotel-sonnblick.at/ | head -1            # 200 OK
curl -sI https://menu.hotel-sonnblick.at/auth/login | head -1  # 200 OK
curl -sI https://menu.hotel-sonnblick.at/admin | head -1       # 307 (Redirect zu Login)
```

## Backup

### Täglich (empfohlen via Cron)

```bash
#!/bin/bash
BACKUP_DIR="/root/backups-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"
pg_dump -U menucard -h 127.0.0.1 menucard_pro > "$BACKUP_DIR/menucard-db-$(date +%H%M).sql"
tar czf "$BACKUP_DIR/configs.tar.gz" \
  /etc/nginx/sites-available/menucard-pro \
  /etc/nginx/conf.d/ \
  /var/www/menucard-pro/.env \
  /var/www/menucard-pro/ecosystem.config.js \
  2>/dev/null
find /root -maxdepth 1 -type d -name 'backups-*' -mtime +30 -exec rm -rf {} \;
```

Cron (`crontab -e`):

```
0 3 * * * /root/backup.sh >> /var/log/menucard-backup.log 2>&1
```

### Manueller DB-Dump

```bash
pg_dump -U menucard -h 127.0.0.1 menucard_pro > /root/menucard-$(date +%Y%m%d-%H%M).sql
```

### GitHub-Tags

Vor jedem Release:

```bash
git tag -a v1.0-stabil -m "Stabiler Meilenstein 2026-04-14"
git push origin v1.0-stabil
```

## Restore

### Datenbank

```bash
pm2 stop menucard-pro
sudo -u postgres psql -c "DROP DATABASE menucard_pro;"
sudo -u postgres psql -c "CREATE DATABASE menucard_pro OWNER menucard;"
psql -U menucard -h 127.0.0.1 menucard_pro < /root/backups-YYYYMMDD/menucard-db-HHMM.sql
pm2 start menucard-pro
```

### App-Rollback

```bash
cd /var/www/menucard-pro
git fetch --tags
git checkout v1.0-stabil   # letzter stabiler Tag
npm install
npx prisma db push
npm run build
pm2 restart menucard-pro
```

## Monitoring

```bash
pm2 list                        # Prozess-Status
pm2 logs menucard-pro           # Live-Logs
pm2 monit                       # CPU/RAM pro Prozess
systemctl status nginx          # Nginx-Status
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/access.log
df -h                           # Festplatten-Belegung
free -h                         # RAM-Status
```

## Troubleshooting

### App reagiert nicht

```bash
pm2 logs menucard-pro --lines 100 --nostream
pm2 restart menucard-pro
```

Wenn Memory-Leak: `pm2 restart menucard-pro --max-memory-restart 800M` in `ecosystem.config.js`.

### Build schlägt fehl

```bash
cd /var/www/menucard-pro
rm -rf .next node_modules
npm install
npm run build
```

### Prisma-Fehler nach Schema-Änderung

```bash
npx prisma generate
npx prisma db push
pm2 restart menucard-pro
```

Niemals `prisma migrate reset` in Produktion — das löscht die Datenbank.

### Nginx 502/504

```bash
curl -I http://127.0.0.1:3000/       # Prüft ob App antwortet
pm2 logs menucard-pro                # Fehler in Node
systemctl reload nginx
```

### Zertifikat abgelaufen

```bash
certbot renew
systemctl reload nginx
```

### Datenbank voll / langsam

```bash
psql -U menucard -h 127.0.0.1 menucard_pro -c "VACUUM ANALYZE;"
du -sh /var/lib/postgresql/15/main/
```

### PM2 überlebt Reboot nicht

```bash
pm2 save
pm2 startup systemd -u root --hp /root
# Den ausgegebenen Befehl nochmal ausführen.
```

## Security-Hygiene

- `.env` niemals commiten (`.gitignore` enthält `.env*`)
- GitHub-Tokens niemals in Remote-URL einbetten; Credential-Helper verwenden
- Admin-Passwort regelmäßig rotieren
- SSH-Key-only Login aktivieren (derzeit noch Passwort erlaubt — offener Punkt)
- System-Updates: `apt update && apt upgrade -y` monatlich
- PostgreSQL lauscht nur auf `127.0.0.1`
- UFW: nur SSH (22) und Nginx (80/443) offen

## Wichtige Pfade

| Zweck | Pfad |
|---|---|
| App-Code | `/var/www/menucard-pro` |
| Env-Datei | `/var/www/menucard-pro/.env` |
| Nginx-Config | `/etc/nginx/sites-available/menucard-pro` |
| Let's Encrypt | `/etc/letsencrypt/live/menu.hotel-sonnblick.at/` |
| Nginx-Logs | `/var/log/nginx/{access,error}.log` |
| PM2-Logs | `~/.pm2/logs/menucard-pro-{out,error}.log` |
| Backups | `/root/backups-YYYYMMDD/` |
| Uploads | `/var/www/menucard-pro/public/uploads/` |
