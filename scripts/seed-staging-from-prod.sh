#!/usr/bin/env bash
# =============================================================================
# Phase 0 Tag 2 Schritt 3: Staging-Seed aus Prod-Dump
#
# Ersetzt Staging-DB ($STAGING_DB_NAME) durch einen aktuellen Prod-Dump.
# Danach werden User-Passworte anonymisiert, Tenants mit "(STAGING)" markiert.
# Vorhandener Staging-Zustand wird vor dem Austausch gesichert (Rollback).
#
# Idempotent. Kann bei Bedarf erneut laufen (z. B. wenn Prod neue Daten hat).
# =============================================================================
set -euo pipefail

PROD_DIR="/var/www/menucard-pro"
STAGING_DIR="/var/www/menucard-pro-staging"
PM2_NAME="menucard-pro-staging"
STAGING_DOMAIN="staging.menu.hotel-sonnblick.at"
STAGING_PORT=3001

# Dump-Ziel (temporaer, im Script geraeumt)
DUMP_FILE="/tmp/prod-for-staging-$(date +%Y%m%d-%H%M%S).sql"
ROLLBACK_DIR="/var/backups/menucard-pro/staging-rollback"
ROLLBACK_FILE="${ROLLBACK_DIR}/staging-before-seed-$(date +%Y%m%d-%H%M%S).sql.gz"

# Admin-Credentials-File (staging-admin-login)
STAGING_ADMIN_CREDS="/root/.secrets/staging-admin-creds.txt"

# Logging
LOG_PREFIX=">>"
say() { echo -e "\n${LOG_PREFIX} $*"; }
ok()  { echo "   OK: $*"; }
err() { echo "   FEHLER: $*" >&2; }

# -----------------------------------------------------------------------------
# 0. Preflight + URL-Parsing
# -----------------------------------------------------------------------------
say "0) Preflight"

[ -f "$PROD_DIR/.env" ] || { err "$PROD_DIR/.env fehlt"; exit 1; }
[ -f "$STAGING_DIR/.env" ] || { err "$STAGING_DIR/.env fehlt"; exit 1; }
[ -d "$STAGING_DIR/node_modules/bcryptjs" ] || { err "bcryptjs im Staging node_modules nicht gefunden"; exit 1; }

parse_url_field() {
    # $1 = URL, $2 = field (user|pass|host|port|db)
    local url="$1" field="$2"
    case "$field" in
        user) echo "$url" | sed -E 's|postgresql://([^:]+):.*|\1|' ;;
        pass) echo "$url" | sed -E 's|postgresql://[^:]+:([^@]+)@.*|\1|' ;;
        host) echo "$url" | sed -E 's|postgresql://[^@]+@([^:]+):.*|\1|' ;;
        port) echo "$url" | sed -E 's|postgresql://[^@]+@[^:]+:([^/]+)/.*|\1|' ;;
        db)   echo "$url" | sed -E 's|postgresql://[^/]+/([^?]+).*|\1|' ;;
    esac
}

PROD_DB_URL=$(grep -oP '^DATABASE_URL=\K.*' "$PROD_DIR/.env" | tr -d '"')
STAGING_DB_URL=$(grep -oP '^DATABASE_URL=\K.*' "$STAGING_DIR/.env" | tr -d '"')

PROD_USER=$(parse_url_field "$PROD_DB_URL" user)
PROD_PASS=$(parse_url_field "$PROD_DB_URL" pass)
PROD_HOST=$(parse_url_field "$PROD_DB_URL" host)
PROD_PORT=$(parse_url_field "$PROD_DB_URL" port)
PROD_DB=$(parse_url_field "$PROD_DB_URL" db)

STAGING_USER=$(parse_url_field "$STAGING_DB_URL" user)
STAGING_PASS=$(parse_url_field "$STAGING_DB_URL" pass)
STAGING_HOST=$(parse_url_field "$STAGING_DB_URL" host)
STAGING_PORT_DB=$(parse_url_field "$STAGING_DB_URL" port)
STAGING_DB=$(parse_url_field "$STAGING_DB_URL" db)

if [ -z "$PROD_PASS" ] || [ -z "$STAGING_PASS" ]; then
    err "DB-Passwort nicht aus .env-Dateien extrahierbar"
    exit 1
fi

ok "Prod: ${PROD_USER}@${PROD_HOST}:${PROD_PORT}/${PROD_DB}"
ok "Staging: ${STAGING_USER}@${STAGING_HOST}:${STAGING_PORT_DB}/${STAGING_DB}"

# PROD_USER ist Superuser (per project memory) - darf DROP SCHEMA auf Staging
# -----------------------------------------------------------------------------
# 1. Lock
# -----------------------------------------------------------------------------
LOCK_FILE="/var/lock/seed-staging-from-prod.lock"
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    err "Ein anderer Seed-Lauf ist aktiv ($LOCK_FILE). Abbruch."
    exit 1
fi
ok "Lock erworben: $LOCK_FILE"

# -----------------------------------------------------------------------------
# 2. PM2 Staging stoppen (loest DB-Connections aus menucard_pro_staging)
# -----------------------------------------------------------------------------
say "2) PM2: $PM2_NAME stoppen"
if pm2 describe "$PM2_NAME" >/dev/null 2>&1; then
    pm2 stop "$PM2_NAME" >/dev/null
    ok "$PM2_NAME gestoppt"
else
    ok "$PM2_NAME nicht aktiv (uebersprungen)"
fi

# -----------------------------------------------------------------------------
# 3. Staging-DB sichern (Rollback-Punkt)
# -----------------------------------------------------------------------------
say "3) Rollback-Backup der aktuellen Staging-DB"
mkdir -p "$ROLLBACK_DIR"
export PGPASSWORD="$STAGING_PASS"
if PGPASSWORD="$STAGING_PASS" psql -h "$STAGING_HOST" -p "$STAGING_PORT_DB" \
    -U "$STAGING_USER" -d "$STAGING_DB" -c "SELECT 1" >/dev/null 2>&1; then
    PGPASSWORD="$STAGING_PASS" pg_dump -h "$STAGING_HOST" -p "$STAGING_PORT_DB" \
        -U "$STAGING_USER" -d "$STAGING_DB" --no-owner --no-acl \
        | gzip > "$ROLLBACK_FILE"
    ok "Rollback: $ROLLBACK_FILE ($(du -h "$ROLLBACK_FILE" | cut -f1))"
else
    ok "Staging-DB existiert nicht oder ist leer - Rollback uebersprungen"
fi
unset PGPASSWORD

# -----------------------------------------------------------------------------
# 4. Prod-Dump ziehen
# -----------------------------------------------------------------------------
say "4) Prod-Dump ziehen"
PGPASSWORD="$PROD_PASS" pg_dump -h "$PROD_HOST" -p "$PROD_PORT" \
    -U "$PROD_USER" -d "$PROD_DB" \
    --no-owner --no-acl \
    > "$DUMP_FILE"
unset PGPASSWORD
DUMP_SIZE=$(du -h "$DUMP_FILE" | cut -f1)
ok "Dump erzeugt: $DUMP_FILE ($DUMP_SIZE)"

# -----------------------------------------------------------------------------
# 5. Staging-DB leeren (DROP SCHEMA public CASCADE + CREATE SCHEMA public)
# -----------------------------------------------------------------------------
say "5) Staging-DB leeren"
PGPASSWORD="$PROD_PASS" psql -h "$STAGING_HOST" -p "$STAGING_PORT_DB" \
    -U "$PROD_USER" -d "$STAGING_DB" -v ON_ERROR_STOP=1 <<SQL
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO $STAGING_USER;
GRANT ALL ON SCHEMA public TO public;
SQL
unset PGPASSWORD
ok "Staging-Schema 'public' neu erstellt, Rechte fuer $STAGING_USER gesetzt"

# -----------------------------------------------------------------------------
# 6. Dump in Staging restaurieren (als Staging-User -> Tabellen gehoeren ihm)
# -----------------------------------------------------------------------------
say "6) Dump in Staging-DB restaurieren"
PGPASSWORD="$STAGING_PASS" psql -h "$STAGING_HOST" -p "$STAGING_PORT_DB" \
    -U "$STAGING_USER" -d "$STAGING_DB" -v ON_ERROR_STOP=1 \
    -q -f "$DUMP_FILE" > /tmp/restore.log 2>&1 || {
        err "Restore fehlgeschlagen - Log:"
        tail -n 40 /tmp/restore.log >&2
        exit 6
    }
unset PGPASSWORD
ok "Restore abgeschlossen (Log: /tmp/restore.log)"

# -----------------------------------------------------------------------------
# 7. Staging-Admin-Passwort anonymisieren
#    - einmalig generieren, persistieren unter $STAGING_ADMIN_CREDS (600)
#    - Re-Run verwendet gespeichertes Passwort
# -----------------------------------------------------------------------------
say "7) Staging-Admin-Credentials"
mkdir -p "$(dirname "$STAGING_ADMIN_CREDS")"
chmod 700 "$(dirname "$STAGING_ADMIN_CREDS")"

ADMIN_EMAIL="admin@hotel-sonnblick.at"
if [ -f "$STAGING_ADMIN_CREDS" ]; then
    # shellcheck disable=SC1090
    source "$STAGING_ADMIN_CREDS"
    ADMIN_PASS="$PASSWORD"
    ok "Vorhandenes Staging-Admin-Passwort wiederverwendet"
else
    ADMIN_PASS=$(openssl rand -base64 21 | tr -d '/+=' | head -c 18)
    {
        echo "EMAIL=$ADMIN_EMAIL"
        echo "PASSWORD=$ADMIN_PASS"
        echo "DOMAIN=$STAGING_DOMAIN"
        echo "GENERATED=$(date -Iseconds)"
    } > "$STAGING_ADMIN_CREDS"
    chmod 600 "$STAGING_ADMIN_CREDS"
    ok "Staging-Admin-Passwort neu generiert: $STAGING_ADMIN_CREDS (600)"
fi

# Hash via bcryptjs im Staging-Projekt berechnen
cd "$STAGING_DIR"
ADMIN_HASH=$(node -e "console.log(require('bcryptjs').hashSync(process.argv[1], 10))" "$ADMIN_PASS")
[ -n "$ADMIN_HASH" ] || { err "bcryptjs konnte Hash nicht erzeugen"; exit 7; }
ok "bcryptjs-Hash fuer '$ADMIN_EMAIL' erzeugt"

# -----------------------------------------------------------------------------
# 8. Transformations: Admin-Passwort + Tenant mit (STAGING) markieren
# -----------------------------------------------------------------------------
say "8) Anonymisierung + Kennzeichnung"
PGPASSWORD="$STAGING_PASS" psql -h "$STAGING_HOST" -p "$STAGING_PORT_DB" \
    -U "$STAGING_USER" -d "$STAGING_DB" -v ON_ERROR_STOP=1 <<SQL
-- Alle User-Passworte auf Admin-Hash setzen (vereinheitlicht den Staging-Login)
UPDATE "User" SET "passwordHash" = '$ADMIN_HASH';

-- Tenant-Namen mit STAGING markieren (falls nicht bereits)
UPDATE "Tenant"
   SET name = name || ' (STAGING)'
 WHERE name NOT LIKE '% (STAGING)';
SQL
unset PGPASSWORD
ok "Alle User-Passworte = Staging-Admin-Hash; Tenants markiert"

# -----------------------------------------------------------------------------
# 9. PM2 Staging starten
# -----------------------------------------------------------------------------
say "9) PM2: $PM2_NAME starten"
if pm2 describe "$PM2_NAME" >/dev/null 2>&1; then
    PORT="$STAGING_PORT" pm2 restart "$PM2_NAME" --update-env >/dev/null
else
    cd "$STAGING_DIR"
    PORT="$STAGING_PORT" pm2 start npm --name "$PM2_NAME" -- start >/dev/null
fi
pm2 save >/dev/null
sleep 3
ok "$PM2_NAME laeuft"

# -----------------------------------------------------------------------------
# 10. Smoke-Test
# -----------------------------------------------------------------------------
say "10) Smoke-Test"

# 10a) Loopback
HTTP_CODE=$(curl -o /dev/null -s -w '%{http_code}' "http://127.0.0.1:${STAGING_PORT}/" || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "307" ] || [ "$HTTP_CODE" = "308" ]; then
    ok "Loopback: HTTP $HTTP_CODE"
else
    err "Loopback smoke failed: HTTP $HTTP_CODE"
    pm2 logs "$PM2_NAME" --lines 30 --nostream || true
    exit 10
fi

# 10b) Tenant-Count in Staging
TENANT_COUNT=$(PGPASSWORD="$STAGING_PASS" psql -h "$STAGING_HOST" -p "$STAGING_PORT_DB" \
    -U "$STAGING_USER" -d "$STAGING_DB" -tAc 'SELECT COUNT(*) FROM "Tenant";')
PRODUCT_COUNT=$(PGPASSWORD="$STAGING_PASS" psql -h "$STAGING_HOST" -p "$STAGING_PORT_DB" \
    -U "$STAGING_USER" -d "$STAGING_DB" -tAc 'SELECT COUNT(*) FROM "Product";')
MENU_COUNT=$(PGPASSWORD="$STAGING_PASS" psql -h "$STAGING_HOST" -p "$STAGING_PORT_DB" \
    -U "$STAGING_USER" -d "$STAGING_DB" -tAc 'SELECT COUNT(*) FROM "Menu";')
ok "Tenants: $TENANT_COUNT | Products: $PRODUCT_COUNT | Menus: $MENU_COUNT"

# -----------------------------------------------------------------------------
# 11. Dump-File loeschen (Rollback bleibt erhalten)
# -----------------------------------------------------------------------------
rm -f "$DUMP_FILE"

# -----------------------------------------------------------------------------
# 12. Fertig
# -----------------------------------------------------------------------------
say "12) Fertig"
echo ""
echo "=== Staging-Admin-Login ==="
echo "  Email: $ADMIN_EMAIL"
echo "  Pass:  $ADMIN_PASS"
echo "  (persistiert in $STAGING_ADMIN_CREDS, mode 600)"
echo ""
echo "=== Daten ==="
echo "  Tenants: $TENANT_COUNT (alle mit ' (STAGING)'-Suffix)"
echo "  Products: $PRODUCT_COUNT"
echo "  Menus: $MENU_COUNT"
echo ""
echo "=== Rollback ==="
if [ -f "$ROLLBACK_FILE" ]; then
    echo "  Vorheriger Staging-Zustand: $ROLLBACK_FILE"
    echo "  Wiederherstellen: bash scripts/restore-staging.sh $ROLLBACK_FILE"
else
    echo "  (kein Vor-Zustand, Staging war leer)"
fi
echo ""
echo "=== Staging erreichbar ==="
echo "  SSH-Tunnel: ssh -L ${STAGING_PORT}:127.0.0.1:${STAGING_PORT} root@178.104.138.177"
echo "  Browser:    http://127.0.0.1:${STAGING_PORT}"
echo "  Login mit den Staging-Admin-Credentials oben"
