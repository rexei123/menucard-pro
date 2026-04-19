#!/bin/bash
# ============================================================================
# MenuCard Pro — Admin-Passwort Rotation (Prod + Staging + Staging-Creds-File)
# ============================================================================
# Rotiert das Passwort des Admin-Users (admin@hotel-sonnblick.at) in:
#   - Prod-DB     menucard_pro.User.passwordHash
#   - Staging-DB  menucard_pro_staging.User.passwordHash
#   - /root/.secrets/staging-admin-creds.txt  (Klartext fuer Playwright/ship.ps1)
#
# Ablauf:
#   1. Discovery: DB-URLs aus beiden .env, Admin-User in beiden DBs pruefen
#   2. Backup: alte passwordHashes + Creds-File nach
#              /var/backups/menucard-pro/admin-pw-pre-rotation-<ts>/
#   3. Neues Passwort generieren (20 Zeichen alphanumerisch)
#   4. bcrypt-Hash (10 Rounds, kompatibel zu bcryptjs in src/lib/auth.ts)
#   5. UPDATE beide DBs + neues Creds-File schreiben
#   6. Rollback bei Fehler (ERR-Trap)
#
# Aufruf:
#   bash scripts/rotate-admin-password.sh --dry-run   # Plan zeigen
#   bash scripts/rotate-admin-password.sh --yes       # Rotation durchfuehren
# ============================================================================
set -Eeuo pipefail

# ---- Konstanten ------------------------------------------------------------
PROD_DIR="/var/www/menucard-pro"
STAG_DIR="/var/www/menucard-pro-staging"
PROD_DB="menucard_pro"
STAG_DB="menucard_pro_staging"
DB_HOST="127.0.0.1"
DB_USER="menucard"
ADMIN_EMAIL="admin@hotel-sonnblick.at"
CREDS_FILE="/root/.secrets/staging-admin-creds.txt"
BACKUP_BASE="/var/backups/menucard-pro"
LOG_FILE="/var/log/menucard-admin-pw-rotation.log"
BCRYPT_ROUNDS=10
PW_LENGTH=20

TS=$(date '+%Y%m%d-%H%M%S')
BACKUP_DIR="${BACKUP_BASE}/admin-pw-pre-rotation-${TS}"

C_C=$'\e[36m'; C_G=$'\e[32m'; C_Y=$'\e[33m'; C_R=$'\e[31m'; C_N=$'\e[0m'

# ---- Flags -----------------------------------------------------------------
DRY_RUN=0
AUTO_YES=0
for arg in "$@"; do
    case "$arg" in
        --dry-run)   DRY_RUN=1 ;;
        --yes|-y)    AUTO_YES=1 ;;
        -h|--help)   sed -n '1,30p' "$0"; exit 0 ;;
        *) echo "${C_R}Unbekanntes Flag: $arg${C_N}" >&2; exit 2 ;;
    esac
done

# ---- Logging ---------------------------------------------------------------
mkdir -p "$(dirname "$LOG_FILE")"
log()  { echo "[$(date '+%F %T')] $*" >> "$LOG_FILE"; }
say()  { echo -e "$*"; log "$(echo -e "$*" | sed 's/\x1b\[[0-9;]*m//g')"; }

say
say "${C_C}=== MenuCard Pro Admin-Passwort Rotation ===${C_N}"
say "Start: $(date '+%F %T')"
say "Modus: $([ $DRY_RUN -eq 1 ] && echo 'DRY-RUN' || echo 'LIVE')"
say

# ---- 1. Discovery ----------------------------------------------------------
[ -f "$PROD_DIR/.env" ] || { say "${C_R}FAIL: $PROD_DIR/.env fehlt${C_N}"; exit 1; }
[ -f "$STAG_DIR/.env" ] || { say "${C_R}FAIL: $STAG_DIR/.env fehlt${C_N}"; exit 1; }

extract_db_pw() {
    # Format: DATABASE_URL=postgresql://user:PASSWORD@host:port/db
    grep -E '^DATABASE_URL=' "$1" | head -n1 \
        | sed -E 's/^DATABASE_URL=//; s/^"//; s/"$//' \
        | sed -E 's|^[^:]+://[^:]+:([^@]+)@.*|\1|'
}
PROD_DB_PW=$(extract_db_pw "$PROD_DIR/.env")
STAG_DB_PW=$(extract_db_pw "$STAG_DIR/.env")
[ -n "$PROD_DB_PW" ] || { say "${C_R}FAIL: kein DB-Passwort in Prod .env${C_N}"; exit 1; }
[ -n "$STAG_DB_PW" ] || { say "${C_R}FAIL: kein DB-Passwort in Staging .env${C_N}"; exit 1; }

say "${C_Y}[1/5] Discovery${C_N}"
say "  Prod-DB:      $PROD_DB  (user: $DB_USER @ $DB_HOST)"
say "  Staging-DB:   $STAG_DB  (user: $DB_USER @ $DB_HOST)"
say "  Admin:        $ADMIN_EMAIL"
say "  Creds-File:   $CREDS_FILE"

count_admin() {
    PGPASSWORD="$1" psql -h "$DB_HOST" -U "$DB_USER" -d "$2" -t -A -v ON_ERROR_STOP=1 \
        -c "SELECT COUNT(*) FROM \"User\" WHERE email='$ADMIN_EMAIL';"
}
PROD_CNT=$(count_admin "$PROD_DB_PW" "$PROD_DB")
STAG_CNT=$(count_admin "$STAG_DB_PW" "$STAG_DB")
say "  Admin in Prod:    $PROD_CNT"
say "  Admin in Staging: $STAG_CNT"
if [ "$PROD_CNT" != "1" ] || [ "$STAG_CNT" != "1" ]; then
    say "${C_R}FAIL: Admin-User nicht genau 1x in beiden DBs.${C_N}"
    exit 1
fi

# ---- 2. Dry-Run vorher aussteigen -----------------------------------------
if [ $DRY_RUN -eq 1 ]; then
    say
    say "${C_C}[DRY-RUN] Rotation wuerde:${C_N}"
    say "  - neues Passwort generieren (alphanumerisch, $PW_LENGTH Zeichen)"
    say "  - bcryptjs-Hash erzeugen (Rounds=$BCRYPT_ROUNDS)"
    say "  - UPDATE \"User\" SET \"passwordHash\"=... WHERE email='$ADMIN_EMAIL'"
    say "    * in DB $PROD_DB"
    say "    * in DB $STAG_DB"
    say "  - $CREDS_FILE neu schreiben (chmod 600)"
    say "  - Backup nach $BACKUP_DIR/"
    say
    say "${C_C}DRY-RUN Ende - keine Aenderungen.${C_N}"
    exit 0
fi

# ---- Bestaetigung ----------------------------------------------------------
if [ $AUTO_YES -ne 1 ]; then
    echo
    read -p "Rotation jetzt ausfuehren? (y/n) " ANS
    [ "$ANS" = "y" ] || { say "${C_Y}Abbruch.${C_N}"; exit 0; }
fi

# ---- 3. Backup -------------------------------------------------------------
say
say "${C_Y}[2/5] Backup alter Hashes + Creds-File${C_N}"
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

PGPASSWORD="$PROD_DB_PW" psql -h "$DB_HOST" -U "$DB_USER" -d "$PROD_DB" -t -A -v ON_ERROR_STOP=1 \
    -c "SELECT \"passwordHash\" FROM \"User\" WHERE email='$ADMIN_EMAIL';" \
    > "$BACKUP_DIR/prod-admin.hash"
PGPASSWORD="$STAG_DB_PW" psql -h "$DB_HOST" -U "$DB_USER" -d "$STAG_DB" -t -A -v ON_ERROR_STOP=1 \
    -c "SELECT \"passwordHash\" FROM \"User\" WHERE email='$ADMIN_EMAIL';" \
    > "$BACKUP_DIR/staging-admin.hash"

if [ -f "$CREDS_FILE" ]; then
    cp -a "$CREDS_FILE" "$BACKUP_DIR/staging-admin-creds.old.txt"
fi
chmod 600 "$BACKUP_DIR"/*
say "${C_G}  Backup: $BACKUP_DIR${C_N}"

OLD_PROD_HASH=$(tr -d '\n' < "$BACKUP_DIR/prod-admin.hash")
OLD_STAG_HASH=$(tr -d '\n' < "$BACKUP_DIR/staging-admin.hash")
[ -n "$OLD_PROD_HASH" ] || { say "${C_R}FAIL: alter Prod-Hash leer${C_N}"; exit 1; }
[ -n "$OLD_STAG_HASH" ] || { say "${C_R}FAIL: alter Staging-Hash leer${C_N}"; exit 1; }

# ---- 4. Neues Passwort + bcrypt-Hash --------------------------------------
say
say "${C_Y}[3/5] Neues Passwort + bcryptjs-Hash erzeugen${C_N}"
# 30 Byte -> base64 -> nur [A-Za-z0-9], erste 20 Zeichen
NEW_PW=$(openssl rand -base64 30 | tr -d '/+=' | tr -d '\n' | head -c "$PW_LENGTH")
if [ "${#NEW_PW}" -lt "$PW_LENGTH" ]; then
    say "${C_R}FAIL: konnte kein Passwort mit $PW_LENGTH Zeichen erzeugen${C_N}"
    exit 1
fi

NEW_HASH=$(cd "$PROD_DIR" && node -e \
    "console.log(require('bcryptjs').hashSync(process.argv[1], ${BCRYPT_ROUNDS}))" \
    "$NEW_PW")
if [ -z "$NEW_HASH" ] || [[ ! "$NEW_HASH" =~ ^\$2[aby]\$ ]]; then
    say "${C_R}FAIL: bcryptjs-Hash ungueltig: $NEW_HASH${C_N}"
    exit 1
fi
say "${C_G}  Hash erzeugt (\$2..\$ Prefix, ${#NEW_HASH} Zeichen)${C_N}"

# ---- 5. Rollback-Definition + Updates --------------------------------------
rollback() {
    say
    say "${C_R}=== ROLLBACK ===${C_N}"
    PGPASSWORD="$PROD_DB_PW" psql -h "$DB_HOST" -U "$DB_USER" -d "$PROD_DB" \
        -c "UPDATE \"User\" SET \"passwordHash\"='$OLD_PROD_HASH' WHERE email='$ADMIN_EMAIL';" \
        >> "$LOG_FILE" 2>&1 || true
    PGPASSWORD="$STAG_DB_PW" psql -h "$DB_HOST" -U "$DB_USER" -d "$STAG_DB" \
        -c "UPDATE \"User\" SET \"passwordHash\"='$OLD_STAG_HASH' WHERE email='$ADMIN_EMAIL';" \
        >> "$LOG_FILE" 2>&1 || true
    if [ -f "$BACKUP_DIR/staging-admin-creds.old.txt" ]; then
        cp -a "$BACKUP_DIR/staging-admin-creds.old.txt" "$CREDS_FILE"
    fi
    say "${C_Y}Rollback durchgefuehrt. Backup-Pfad: $BACKUP_DIR${C_N}"
    exit 1
}
trap rollback ERR

say
say "${C_Y}[4/5] DB-Updates${C_N}"
PGPASSWORD="$PROD_DB_PW" psql -h "$DB_HOST" -U "$DB_USER" -d "$PROD_DB" -v ON_ERROR_STOP=1 \
    -c "UPDATE \"User\" SET \"passwordHash\"='$NEW_HASH', \"updatedAt\"=NOW() WHERE email='$ADMIN_EMAIL';" \
    >> "$LOG_FILE" 2>&1
say "${C_G}  Prod    aktualisiert${C_N}"

PGPASSWORD="$STAG_DB_PW" psql -h "$DB_HOST" -U "$DB_USER" -d "$STAG_DB" -v ON_ERROR_STOP=1 \
    -c "UPDATE \"User\" SET \"passwordHash\"='$NEW_HASH', \"updatedAt\"=NOW() WHERE email='$ADMIN_EMAIL';" \
    >> "$LOG_FILE" 2>&1
say "${C_G}  Staging aktualisiert${C_N}"

say
say "${C_Y}[5/5] Staging-Creds-File neu schreiben${C_N}"
mkdir -p "$(dirname "$CREDS_FILE")"
chmod 700 "$(dirname "$CREDS_FILE")"
umask 177
cat > "$CREDS_FILE" <<EOF
EMAIL=$ADMIN_EMAIL
PASSWORD=$NEW_PW
ROTATED=$(date -Iseconds)
EOF
chmod 600 "$CREDS_FILE"
say "${C_G}  $CREDS_FILE (chmod 600)${C_N}"

trap - ERR

# ---- Abschluss -------------------------------------------------------------
say
say "${C_C}=== ROTATION ERFOLGREICH ===${C_N}"
say "Admin:    $ADMIN_EMAIL"
say "Passwort: ${C_G}$NEW_PW${C_N}"
say
say "${C_Y}Bitte SOFORT in den Password-Manager uebernehmen.${C_N}"
say "Dieses Passwort wird nirgends sonst gespeichert (ausser verschluesselt in"
say "den bcrypt-Hashes in der DB). Das Staging-Creds-File enthaelt den Klartext,"
say "ist aber chmod 600 + liegt unter /root/.secrets/."
say
say "Backup (alte Hashes + altes Creds-File): $BACKUP_DIR"
say "Log: $LOG_FILE"
say
log "Admin-PW rotiert fuer $ADMIN_EMAIL (Backup: $BACKUP_DIR)"
