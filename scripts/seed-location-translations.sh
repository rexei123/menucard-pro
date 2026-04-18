#!/usr/bin/env bash
set -e
cd /var/www/menucard-pro

DB_URL=$(grep -E '^DATABASE_URL=' .env | cut -d '=' -f2- | tr -d '"' | tr -d "'")
DB_URL_PSQL="${DB_URL%%\?*}"

echo "[SQL] Seed Location-Uebersetzungen..."
psql "$DB_URL_PSQL" -v ON_ERROR_STOP=1 -f scripts/seed-location-translations.sql

echo "[PM2] Restart..."
pm2 restart menucard-pro

echo "[OK] Location-Translations gesetzt."
