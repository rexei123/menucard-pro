#!/bin/bash
# ============================================================================
# MenuCard Pro — Admin-Passwort Rotation (Prod + Staging + Staging-Creds-File)
# ============================================================================
# Rotiert das Passwort des Admin-Users (admin@hotel-sonnblick.at) in:
#   - Prod-DB     menucard_pro.User.passwordHash
#   - Staging-DB  menucard_pro_staging.User.passwordHash
#   - /root/.secrets/staging-admin-creds.txt  (Klartext fuer Playwright/ship.ps1)
#
# Verbindet sich mit psql ueber die vollstaendige DATABASE_URL aus der .env
# (kein eigenes Passwort-Parsing noetig). Das umgeht URL-Encoding-Edgecases.
#
# Aufruf:
#   bash scripts/rotate-admin-password.sh --dry-run
#   bash scripts/rotate-admin-password.sh --yes
# ============================================================================
set -Eeuo pipefail

# ---- Konstanten ------------------------------------------------------------
PROD_DIR="/var/www/menucard-pro"
STAG_DIR="/var/www/menucard-pro-staging"
PROD_ENV="$PROD_DIR/.env"
STAG_ENV="$STAG_DIR/.env"
PROD_DB_NAME="menucard_pro"
STAG_DB_NAME="menucard_pro_staging"
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
        --dry-run)  DRY_RUN=1 ;;
        --yes|-y)   AUTO_YES=1 ;;
        -h|--help)  sed -n '1,30p' "$0"; exit 0 ;;
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

# ---- DATABASE_URL aus .env lesen ------------------------------------------
# sed schneidet den Key "DATABASE_URL=" weg; Anfuehrungszeichen + CR danach
# per Bash-Substring entfernt. awk-Rebuild-Falle (OFS) wird so vermieden.
read_db_url() {
    local file="$1"
    local v
    v=$(sed -n 's/^DATABASE_URL=//p' "$file" | head -n1)
    # Windows CR am Zeilenende
    v="${v%$'\r'}"
    # Outer double or single quotes strippen
    v="${v%\"}"; v="${v#\"}"
    v="${v%\'}"; v="${v#\'}"
    printf '%s' "$v"
}

validate_db_url() {
    local label="$1"
    local u="$2"
    case "$u" in
        postgresql://*|postgres://*) : ;;
        *) say "${C_R}FAIL: $label DATABASE_URL hat falsches Format: '${u:0:40}...'${C_N}"; exit 1 ;;
    esac
}

[ -f "$PROD_ENV" ] || { say "${C_R}FAIL: $PROD_ENV fehlt${C_N}"; exit 1; }
[ -f "$STAG_ENV" ] || { say "${C_R}FAIL: $STAG_ENV fehlt${C_N}"; exit 1; }

PROD_DB_URL=$(read_db_url "$PROD_ENV")
STAG_DB_URL=$(read_db_url "$STAG_ENV")

[ -n "$PROD_DB_URL" ] || { say "${C_R}FAIL: DATABASE_URL leer in $PROD_ENV${C_N}"; exit 1; }
[ -n "$STAG_DB_URL" ] || { say "${C_R}FAIL: DATABASE_URL leer in $STAG_ENV${C_N}"; exit 1; }
validate_db_url "PROD"    "$PROD_DB_URL"
validate_db_url "STAGING" "$STAG_DB_URL"

# ---- 1. Discovery ----------------------------------------------------------
say "${C_Y}[1/5] Discovery${C_N}"
say "  Prod-DB:      $PROD_DB_NAME"
say "  Staging-DB:   $STAG_DB_NAME"
say "  Admin:        $ADMIN_EMAIL"
say "  Creds-File:   $CREDS_FILE"

# psql direkt gegen DATABASE_URL (kein eigenes Passwort-Parsing)
count_admin_prod() {
    psql "$PROD_DB_URL" -t -A -v ON_ERROR_STOP=1 \
        -c "SELECT COUNT(*) FROM \"User\" WHERE email='$ADMIN_EMAIL';"
}
count_admin_stag() {
    psql "$STAG_DB_URL" -t -A -v ON_ERROR_STOP=1 \
        -c "SELECT COUNT(*) FROM \"User\" WHERE email='$ADMIN_EMAIL';"
}

PROD_CNT=$(count_admin_prod)
STAG_CNT=$(count_admin_stag)
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
    say "    * in DB $PROD_DB_NAME"
    say "    * in DB $STAG_DB_NAME"
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

psql "$PROD_DB_URL" -t -A -v ON_ERROR_STOP=1 \
    -c "SELECT \"passwordHash\" FROM \"User\" WHERE email='$ADMIN_EMAIL';" \
    > "$BACKUP_DIR/prod-admin.hash"
psql "$STAG_DB_URL" -t -A -v ON_ERROR_STOP=1 \
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
say "${C_G}  Hash erzeugt (\$2..\$-Prefix, ${#NEW_HASH} Zeichen)${C_N}"

# ---- 5. Rollback-Definition + Updates --------------------------------------
rollback() {
    say
    say "${C_R}=== ROLLBACK ===${C_N}"
    psql "$PROD_DB_URL" -v ON_ERROR_STOP=1 \
        -c "UPDATE \"User\" SET \"passwordHash\"='$OLD_PROD_HASH' WHERE email='$ADMIN_EMAIL';" \
        >> "$LOG_FILE" 2>&1 || true
    psql "$STAG_DB_URL" -v ON_ERROR_STOP=1 \
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
psql "$PROD_DB_URL" -v ON_ERROR_STOP=1 \
    -c "UPDATE \"User\" SET \"passwordHash\"='$NEW_HASH', \"updatedAt\"=NOW() WHERE email='$ADMIN_EMAIL';" \
    >> "$LOG_FILE" 2>&1
say "${C_G}  Prod    aktualisiert${C_N}"

psql "$STAG_DB_URL" -v ON_ERROR_STOP=1 \
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
say "Backup (alte Hashes + altes Creds-File): $BACKUP_DIR"
say "Log: $LOG_FILE"
say
log "Admin-PW rotiert fuer $ADMIN_EMAIL (Backup: $BACKUP_DIR)"
