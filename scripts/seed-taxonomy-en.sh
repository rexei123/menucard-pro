#!/usr/bin/env bash
set -e
cd /var/www/menucard-pro

DB_URL=$(grep -E '^DATABASE_URL=' .env | cut -d '=' -f2- | tr -d '"' | tr -d "'")
DB_URL_PSQL="${DB_URL%%\?*}"

echo "[SQL] Seed EN-Uebersetzungen fuer TaxonomyNode..."
psql "$DB_URL_PSQL" -v ON_ERROR_STOP=1 -f scripts/seed-taxonomy-en-translations.sql

echo "[OK] Taxonomy-Translations gesetzt."
