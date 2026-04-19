#!/bin/bash
# ============================================================================
# PHASE 0 TAG 2 SCHRITT 1 — Staging-DB + App-Setup
# ============================================================================
# Ort:   /tmp/phase0-tag2-staging-setup.sh (wird via scp hochgeladen)
# Ziel:  Staging-Umgebung unter /var/www/menucard-pro-staging vorbereiten.
#
# Was passiert:
#   1.  Pre-Checks (PostgreSQL laeuft, prod-.env vorhanden)
#   2.  PostgreSQL: User menucard_staging + DB menucard_pro_staging anlegen
#       (idempotent: bestehendes wird nicht ueberschrieben, nur Passwort updated)
#   3.  Staging-Verzeichnis klonen (git clone von origin/main)
#   4.  .env.staging aus prod-.env ableiten + kritische Keys ueberschreiben
#   5.  npm ci
#   6.  npx prisma db push + prisma generate (Schema in staging-DB)
#   7.  npm run build
#   8.  Zusammenfassung mit DB-Passwort + NEXTAUTH_SECRET (einmalig anzeigen)
#
# Was NICHT passiert:
#   - Kein pm2 start (kommt in Schritt 2)
#   - Keine Nginx-Konfig (kommt in Schritt 2)
#   - Kein SSL / kein Basic-Auth (kommt in Schritt 2)
#   - Keine Prod-Daten (kommt in Schritt 3 via staging-seed.sh)
# ============================================================================
set -euo pipefail

# ----------------------------------------------------------------------
# Konfiguration
# ----------------------------------------------------------------------
PROD_DIR="/var/www/menucard-pro"
STAGING_DIR="/var/www/menucard-pro-staging"
STAGING_DB_NAME="menucard_pro_staging"
STAGING_DB_USER="menucard_staging"
STAGING_PORT="3001"
STAGING_URL="https://staging.menu.hotel-sonnblick.at"
REPO_SSH="git@github-menucard:rexei123/menucard-pro.git"

C_C=$'\e[36m'; C_G=$'\e[32m'; C_Y=$'\e[33m'; C_R=$'\e[31m'; C_N=$'\e[0m'

say() {
    local msg="${1:-}"
    echo -e "$msg"
}

# ----------------------------------------------------------------------
# 1. PRE-CHECKS
# ----------------------------------------------------------------------
say
say "${C_C}=== PHASE 0 TAG 2 SCHRITT 1 — Staging-Setup ===${C_N}"
say

say "${C_Y}[1/8] Pre-Checks ...${C_N}"

if ! pg_isready -h 127.0.0.1 -p 5432 >/dev/null 2>&1; then
    say "${C_R}  PostgreSQL auf 127.0.0.1:5432 nicht erreichbar. Abbruch.${C_N}"
    exit 1
fi
say "  PostgreSQL: OK ($(pg_isready -h 127.0.0.1 -p 5432))"

if [ ! -f "$PROD_DIR/.env" ]; then
    say "${C_R}  $PROD_DIR/.env nicht gefunden. Abbruch.${C_N}"
    exit 1
fi
say "  Prod-.env: OK"

if ! command -v node >/dev/null 2>&1; then
    say "${C_R}  node fehlt. Abbruch.${C_N}"
    exit 1
fi
say "  node: $(node -v)"

if ! command -v npm >/dev/null 2>&1; then
    say "${C_R}  npm fehlt. Abbruch.${C_N}"
    exit 1
fi
say "  npm: $(npm -v)"

say "${C_G}[1/8] OK${C_N}"

# ----------------------------------------------------------------------
# 2. POSTGRES: USER + DB
# ----------------------------------------------------------------------
# PostgreSQL laeuft in Docker (Container menucard-db, postgres:16-alpine).
# Kein OS-User 'postgres' - stattdessen 'menucard'-Superuser via TCP nutzen.
say
say "${C_Y}[2/8] PostgreSQL: Staging-User + DB ...${C_N}"

# Prod-DB-Passwort aus .env extrahieren
PROD_DB_PASS=$(grep -oP 'DATABASE_URL=.*:\/\/[^:]+:\K[^@]+' "$PROD_DIR/.env" || echo "")
if [ -z "$PROD_DB_PASS" ]; then
    say "${C_R}  Konnte DATABASE_URL-Passwort nicht aus prod-.env extrahieren. Abbruch.${C_N}"
    exit 1
fi

# Staging-Passwort: wiederverwenden, falls bereits eine .env existiert
STAGING_ENV_EXIST="$STAGING_DIR/.env"
EXISTING_PASS=""
if [ -f "$STAGING_ENV_EXIST" ]; then
    EXISTING_PASS=$(grep -oP 'DATABASE_URL=.*:\/\/[^:]+:\K[^@]+' "$STAGING_ENV_EXIST" 2>/dev/null || echo "")
fi
if [ -n "$EXISTING_PASS" ]; then
    STAGING_DB_PASS="$EXISTING_PASS"
    say "  Bestehendes Staging-DB-Passwort aus .env uebernommen"
else
    STAGING_DB_PASS=$(openssl rand -base64 36 | tr -d '/+=' | head -c 48)
    say "  Neues Staging-DB-Passwort generiert"
fi

# Admin-Verbindung via menucard-Superuser, Default-DB 'postgres'
export PGPASSWORD="$PROD_DB_PASS"
PSQL_ADMIN="psql -h 127.0.0.1 -U menucard -d postgres -v ON_ERROR_STOP=1"

# User anlegen / Passwort updaten
USER_EXISTS=$($PSQL_ADMIN -tAc "SELECT 1 FROM pg_roles WHERE rolname='${STAGING_DB_USER}'" || echo "")
if [ "$USER_EXISTS" = "1" ]; then
    say "  User ${STAGING_DB_USER} existiert - aktualisiere Passwort"
    $PSQL_ADMIN -c "ALTER USER ${STAGING_DB_USER} WITH ENCRYPTED PASSWORD '${STAGING_DB_PASS}';" >/dev/null
else
    say "  User ${STAGING_DB_USER} wird angelegt"
    $PSQL_ADMIN -c "CREATE USER ${STAGING_DB_USER} WITH ENCRYPTED PASSWORD '${STAGING_DB_PASS}';" >/dev/null
fi

# DB anlegen (idempotent)
DB_EXISTS=$($PSQL_ADMIN -tAc "SELECT 1 FROM pg_database WHERE datname='${STAGING_DB_NAME}'" || echo "")
if [ "$DB_EXISTS" = "1" ]; then
    say "  DB ${STAGING_DB_NAME} existiert bereits"
else
    say "  DB ${STAGING_DB_NAME} wird angelegt"
    $PSQL_ADMIN -c "CREATE DATABASE ${STAGING_DB_NAME} OWNER ${STAGING_DB_USER} ENCODING 'UTF8';" >/dev/null
fi

# Rechte sicherstellen (auch wenn DB schon existierte)
$PSQL_ADMIN -c "GRANT ALL PRIVILEGES ON DATABASE ${STAGING_DB_NAME} TO ${STAGING_DB_USER};" >/dev/null
psql -h 127.0.0.1 -U menucard -d "${STAGING_DB_NAME}" -v ON_ERROR_STOP=1 \
    -c "GRANT ALL ON SCHEMA public TO ${STAGING_DB_USER};" >/dev/null

unset PGPASSWORD
say "${C_G}[2/8] OK${C_N}"

# ----------------------------------------------------------------------
# 3. STAGING-VERZEICHNIS (git clone)
# ----------------------------------------------------------------------
say
say "${C_Y}[3/8] Staging-Verzeichnis klonen ...${C_N}"

if [ -d "$STAGING_DIR/.git" ]; then
    say "  ${STAGING_DIR} existiert - ueberspringe Clone, mache nur fetch"
    cd "$STAGING_DIR"
    git fetch origin main
    git reset --hard origin/main
else
    if [ -e "$STAGING_DIR" ]; then
        say "${C_R}  ${STAGING_DIR} existiert bereits, aber ist kein Git-Repo. Abbruch.${C_N}"
        exit 1
    fi
    mkdir -p "$(dirname "$STAGING_DIR")"
    git clone "$REPO_SSH" "$STAGING_DIR"
    cd "$STAGING_DIR"
    git config user.email "staging-deploy@hotel-sonnblick.at"
    git config user.name "Staging Deploy"
fi

HEAD_SHORT=$(git rev-parse --short HEAD)
say "  HEAD: $HEAD_SHORT (origin/main)"
say "${C_G}[3/8] OK${C_N}"

# ----------------------------------------------------------------------
# 4. .env.staging AUS PROD-.env ABLEITEN
# ----------------------------------------------------------------------
say
say "${C_Y}[4/8] .env fuer Staging erzeugen ...${C_N}"

STAGING_ENV="$STAGING_DIR/.env"

# NEXTAUTH_SECRET: wiederverwenden, falls schon in .env
EXISTING_NA_SECRET=""
if [ -f "$STAGING_ENV" ]; then
    EXISTING_NA_SECRET=$(grep -oP '^NEXTAUTH_SECRET="?\K[^"]*' "$STAGING_ENV" 2>/dev/null | head -1 || echo "")
fi
if [ -n "$EXISTING_NA_SECRET" ]; then
    STAGING_NEXTAUTH_SECRET="$EXISTING_NA_SECRET"
    say "  Bestehendes NEXTAUTH_SECRET aus .env uebernommen"
else
    STAGING_NEXTAUTH_SECRET=$(openssl rand -base64 48 | tr -d '\n')
    say "  Neues NEXTAUTH_SECRET generiert"
fi

if [ -f "$STAGING_ENV" ]; then
    BACKUP_ENV="${STAGING_ENV}.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$STAGING_ENV" "$BACKUP_ENV"
    say "  Bestehende .env nach ${BACKUP_ENV} gesichert"
fi

# Prod-.env als Basis kopieren, dann selektiv ueberschreiben.
# Kommentierter Marker am Anfang fuer Nachvollziehbarkeit.
{
    echo "# ============================================================"
    echo "# .env.staging - erzeugt von phase0-tag2-staging-setup.sh"
    echo "# Stand: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "# Basis: ${PROD_DIR}/.env, mit Staging-Overrides"
    echo "# ============================================================"
    echo
    # Alle Zeilen aus prod-.env, aber die spaeter ueberschriebenen Keys filtern
    grep -vE '^(DATABASE_URL|NEXTAUTH_SECRET|NEXTAUTH_URL|NEXT_PUBLIC_APP_URL|PORT|NODE_ENV)=' "$PROD_DIR/.env" || true
    echo
    echo "# --- Staging-Overrides ---"
    echo "DATABASE_URL=\"postgresql://${STAGING_DB_USER}:${STAGING_DB_PASS}@127.0.0.1:5432/${STAGING_DB_NAME}?schema=public\""
    echo "NEXTAUTH_SECRET=\"${STAGING_NEXTAUTH_SECRET}\""
    echo "NEXTAUTH_URL=\"${STAGING_URL}\""
    echo "NEXT_PUBLIC_APP_URL=\"${STAGING_URL}\""
    echo "PORT=${STAGING_PORT}"
    echo "NODE_ENV=production"
} > "$STAGING_ENV"

chmod 600 "$STAGING_ENV"
say "  .env geschrieben (Port ${STAGING_PORT}, URL ${STAGING_URL})"
say "${C_G}[4/8] OK${C_N}"

# ----------------------------------------------------------------------
# 5. NPM CI
# ----------------------------------------------------------------------
say
say "${C_Y}[5/8] npm ci ...${C_N}"
cd "$STAGING_DIR"
npm ci
say "${C_G}[5/8] OK${C_N}"

# ----------------------------------------------------------------------
# 6. PRISMA DB PUSH + GENERATE
# ----------------------------------------------------------------------
say
say "${C_Y}[6/8] prisma db push + generate ...${C_N}"
npx prisma db push --skip-generate --accept-data-loss
npx prisma generate
say "${C_G}[6/8] OK${C_N}"

# ----------------------------------------------------------------------
# 7. BUILD
# ----------------------------------------------------------------------
say
say "${C_Y}[7/8] npm run build ...${C_N}"
npm run build
say "${C_G}[7/8] OK${C_N}"

# ----------------------------------------------------------------------
# 8. ZUSAMMENFASSUNG
# ----------------------------------------------------------------------
say
say "${C_C}=== STAGING-APP FERTIG ===${C_N}"
say
say "Verzeichnis:      ${STAGING_DIR}"
say "HEAD:             ${HEAD_SHORT}"
say "DB-Name:          ${STAGING_DB_NAME}"
say "DB-User:          ${STAGING_DB_USER}"
say "Port (geplant):   ${STAGING_PORT}"
say "URL (geplant):    ${STAGING_URL}"
say
say "${C_Y}=== EINMALIGE SECRETS (jetzt speichern!) ===${C_N}"
say
say "DB-Passwort staging:"
say "  ${STAGING_DB_PASS}"
say
say "NextAuth-Secret staging:"
say "  ${STAGING_NEXTAUTH_SECRET}"
say
say "Beides ist bereits in ${STAGING_ENV} persistiert (mode 600)."
say "Sichern Sie die Secrets zusaetzlich in Ihrem Passwort-Manager."
say
say "Naechster Schritt: Phase 0 Tag 2 Schritt 2 — PM2 + Nginx + Basic-Auth + SSL"
say
