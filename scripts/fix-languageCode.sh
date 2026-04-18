#!/usr/bin/env bash
# Wird auf dem Server ausgefuehrt.
# Laedt DATABASE_URL aus .env, bereinigt Prisma-Query-Parameter und
# wendet das SQL-Script an.

set -e
cd /var/www/menucard-pro

# DATABASE_URL aus .env lesen
DB_URL=$(grep -E '^DATABASE_URL=' .env | cut -d '=' -f2- | tr -d '"' | tr -d "'")

if [ -z "$DB_URL" ]; then
  echo "FEHLER: DATABASE_URL nicht in .env gefunden"
  exit 1
fi

# Prisma-spezifische Query-Parameter (z.B. ?schema=public) fuer libpq abschneiden
DB_URL_PSQL="${DB_URL%%\?*}"

echo "[SQL] Wende Migration an..."
psql "$DB_URL_PSQL" -v ON_ERROR_STOP=1 -f scripts/fix-languageCode-columns.sql

echo "[PM2] Restart..."
pm2 restart menucard-pro

echo "[OK] Fix angewendet."
