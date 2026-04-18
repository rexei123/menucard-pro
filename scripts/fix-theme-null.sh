#!/usr/bin/env bash
set -e
cd /var/www/menucard-pro

DB_URL=$(grep -E '^DATABASE_URL=' .env | cut -d '=' -f2- | tr -d '"' | tr -d "'")
DB_URL_PSQL="${DB_URL%%\?*}"

if [ -z "$DB_URL" ]; then
  echo "FEHLER: DATABASE_URL nicht in .env gefunden"
  exit 1
fi

echo "[SQL] Wende Migration an..."
psql "$DB_URL_PSQL" -v ON_ERROR_STOP=1 -f scripts/fix-theme-null-config.sql

echo "[PM2] Restart..."
pm2 restart menucard-pro

echo "[OK] Theme-NULL-Fix angewendet."
