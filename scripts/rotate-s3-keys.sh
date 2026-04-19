#!/bin/bash
# ============================================================================
# MenuCard Pro — S3-Keys Rotation
# ============================================================================
# Rotiert S3_ACCESS_KEY und S3_SECRET_KEY in:
#   - /var/www/menucard-pro/.env          (Prod)
#   - /var/www/menucard-pro-staging/.env  (Staging, falls vorhanden)
#
# Neue Keys liest das Script von stdin, Format (exakt zwei Zeilen):
#   <NEW_ACCESS_KEY>
#   <NEW_SECRET_KEY>
#
# Flow:
#   1. Backup beider .env-Files
#   2. stdin lesen, sanity check
#   3. .env atomar umschreiben (awk-Rewrite analog rotate-secrets.sh)
#   4. pm2 restart --update-env fuer beide Apps
#   5. Verify via aws CLI (falls installiert), sonst Warn + Skip
#
# Bei Fehler: Rollback aus Backup + pm2 restart
#
# Aufruf:
#   printf '%s\n%s\n' "$NEW_ACC" "$NEW_SEC" | bash scripts/rotate-s3-keys.sh --yes
#   bash scripts/rotate-s3-keys.sh --dry-run   (keine Keys noetig)
# ============================================================================
set -Eeuo pipefail

PROD_DIR="/var/www/menucard-pro"
STAG_DIR="/var/www/menucard-pro-staging"
PROD_ENV="$PROD_DIR/.env"
STAG_ENV="$STAG_DIR/.env"
PROD_APP="menucard-pro"
STAG_APP="menucard-pro-staging"
BACKUP_BASE="/var/backups/menucard-pro"
LOG_FILE="/var/log/menucard-s3-rotation.log"

TS=$(date '+%Y%m%d-%H%M%S')
BACKUP_DIR="${BACKUP_BASE}/s3-pre-rotation-${TS}"

C_C=$'\e[36m'; C_G=$'\e[32m'; C_Y=$'\e[33m'; C_R=$'\e[31m'; C_N=$'\e[0m'

DRY_RUN=0; AUTO_YES=0
for arg in "$@"; do
    case "$arg" in
        --dry-run)  DRY_RUN=1 ;;
        --yes|-y)   AUTO_YES=1 ;;
        -h|--help)  sed -n '1,30p' "$0"; exit 0 ;;
        *) echo "${C_R}Unbekanntes Flag: $arg${C_N}" >&2; exit 2 ;;
    esac
done

mkdir -p "$(dirname "$LOG_FILE")"
log()  { echo "[$(date '+%F %T')] $*" >> "$LOG_FILE"; }
say()  { echo -e "$*"; log "$(echo -e "$*" | sed 's/\x1b\[[0-9;]*m//g')"; }

say
say "${C_C}=== S3-Keys Rotation ===${C_N}"
say "Start: $(date '+%F %T')  Modus: $([ $DRY_RUN -eq 1 ] && echo DRY-RUN || echo LIVE)"
say

# ---- Preflight -------------------------------------------------------------
[ -f "$PROD_ENV" ] || { say "${C_R}FAIL: $PROD_ENV fehlt${C_N}"; exit 1; }
HAVE_STAGING=0
[ -f "$STAG_ENV" ] && HAVE_STAGING=1

# ---- 1. Discovery ----------------------------------------------------------
say "${C_Y}[1/5] Discovery${C_N}"
# Keys-Namen pruefen (ohne Werte zu zeigen)
for k in S3_ENDPOINT S3_ACCESS_KEY S3_SECRET_KEY S3_BUCKET; do
    if grep -q "^${k}=" "$PROD_ENV"; then
        say "  $k in prod .env: vorhanden"
    else
        say "${C_R}  $k in prod .env: FEHLT${C_N}"; exit 1
    fi
done
if [ $HAVE_STAGING -eq 1 ]; then
    for k in S3_ACCESS_KEY S3_SECRET_KEY; do
        grep -q "^${k}=" "$STAG_ENV" \
            && say "  $k in staging .env: vorhanden" \
            || say "${C_Y}  $k in staging .env: fehlt (wird uebersprungen)${C_N}"
    done
fi

# ---- Dry-Run ---------------------------------------------------------------
if [ $DRY_RUN -eq 1 ]; then
    say
    say "${C_C}[DRY-RUN] Rotation wuerde:${C_N}"
    say "  - $PROD_ENV + ${HAVE_STAGING:+$STAG_ENV + }Backup nach $BACKUP_DIR/"
    say "  - S3_ACCESS_KEY + S3_SECRET_KEY in .env atomar ersetzen"
    say "  - pm2 restart $PROD_APP --update-env (+ $STAG_APP falls vorhanden)"
    say "  - aws s3 ls --endpoint-url=\$S3_ENDPOINT s3://\$S3_BUCKET (Verify, falls aws CLI)"
    say
    say "${C_C}DRY-RUN Ende - keine Aenderungen.${C_N}"
    exit 0
fi

# ---- 2. Neue Keys lesen ----------------------------------------------------
say
say "${C_Y}[2/5] Neue Keys von stdin lesen${C_N}"
if [ -t 0 ]; then
    say "${C_R}FAIL: stdin ist ein Terminal - bitte Keys per Pipe uebergeben.${C_N}"
    say "  Beispiel:  printf '%s\\n%s\\n' '\$NEW_ACC' '\$NEW_SEC' | bash $0 --yes"
    exit 1
fi
IFS= read -r NEW_ACC || true
IFS= read -r NEW_SEC || true
[ -n "$NEW_ACC" ] || { say "${C_R}FAIL: NEW_ACCESS_KEY leer${C_N}"; exit 1; }
[ -n "$NEW_SEC" ] || { say "${C_R}FAIL: NEW_SECRET_KEY leer${C_N}"; exit 1; }
# Minimal-Sanity: keine Whitespaces/newlines
case "$NEW_ACC" in *[[:space:]]*) say "${C_R}FAIL: Access-Key enthaelt Whitespace${C_N}"; exit 1;; esac
case "$NEW_SEC" in *[[:space:]]*) say "${C_R}FAIL: Secret-Key enthaelt Whitespace${C_N}"; exit 1;; esac
say "${C_G}  Access-Key laenge: ${#NEW_ACC}${C_N}"
say "${C_G}  Secret-Key laenge: ${#NEW_SEC}${C_N}"

if [ $AUTO_YES -ne 1 ]; then
    echo
    read -p "Rotation jetzt ausfuehren? (y/n) " ANS < /dev/tty
    [ "$ANS" = "y" ] || { say "${C_Y}Abbruch.${C_N}"; exit 0; }
fi

# ---- 3. Backup -------------------------------------------------------------
say
say "${C_Y}[3/5] Backup beider .env${C_N}"
mkdir -p "$BACKUP_DIR"; chmod 700 "$BACKUP_DIR"
cp -a "$PROD_ENV" "$BACKUP_DIR/prod.env"
[ $HAVE_STAGING -eq 1 ] && cp -a "$STAG_ENV" "$BACKUP_DIR/staging.env"
chmod 600 "$BACKUP_DIR"/*
say "${C_G}  Backup: $BACKUP_DIR${C_N}"

# ---- 4. .env atomar umschreiben -------------------------------------------
# Wir nutzen awk, um in-place S3_ACCESS_KEY / S3_SECRET_KEY zu ersetzen ohne
# andere Zeilen anzufassen. Werte werden ohne Anfuehrungszeichen geschrieben
# (Node-dotenv versteht beide Varianten).
rewrite_env() {
    local file="$1" acc="$2" sec="$3"
    local tmp
    tmp=$(mktemp "${file}.new.XXXXXX")
    awk -v ACC="$acc" -v SEC="$sec" '
        BEGIN { FS="="; OFS="=" }
        /^S3_ACCESS_KEY=/ { print "S3_ACCESS_KEY=" ACC; next }
        /^S3_SECRET_KEY=/ { print "S3_SECRET_KEY=" SEC; next }
        { print }
    ' "$file" > "$tmp"
    # Mode uebernehmen, dann atomar ersetzen
    chmod --reference="$file" "$tmp" || chmod 600 "$tmp"
    chown --reference="$file" "$tmp" 2>/dev/null || true
    mv "$tmp" "$file"
}

rollback() {
    say
    say "${C_R}=== ROLLBACK ===${C_N}"
    [ -f "$BACKUP_DIR/prod.env" ]    && cp -a "$BACKUP_DIR/prod.env"    "$PROD_ENV" || true
    [ -f "$BACKUP_DIR/staging.env" ] && cp -a "$BACKUP_DIR/staging.env" "$STAG_ENV" || true
    pm2 restart "$PROD_APP" --update-env >> "$LOG_FILE" 2>&1 || true
    [ $HAVE_STAGING -eq 1 ] && pm2 restart "$STAG_APP" --update-env >> "$LOG_FILE" 2>&1 || true
    say "${C_Y}Rollback durchgefuehrt. Backup: $BACKUP_DIR${C_N}"
    exit 1
}
trap rollback ERR

say
say "${C_Y}[4/5] .env umschreiben + pm2 restart${C_N}"
rewrite_env "$PROD_ENV" "$NEW_ACC" "$NEW_SEC"
say "${C_G}  Prod .env aktualisiert${C_N}"
if [ $HAVE_STAGING -eq 1 ]; then
    rewrite_env "$STAG_ENV" "$NEW_ACC" "$NEW_SEC"
    say "${C_G}  Staging .env aktualisiert${C_N}"
fi

pm2 restart "$PROD_APP" --update-env >> "$LOG_FILE" 2>&1
say "${C_G}  $PROD_APP restarted${C_N}"
if [ $HAVE_STAGING -eq 1 ]; then
    pm2 restart "$STAG_APP" --update-env >> "$LOG_FILE" 2>&1
    say "${C_G}  $STAG_APP restarted${C_N}"
fi

# ---- 5. Verify -------------------------------------------------------------
say
say "${C_Y}[5/5] Verify${C_N}"
# Neue .env einlesen fuer Endpoint + Bucket
S3_ENDPOINT=$(sed -n 's/^S3_ENDPOINT=//p' "$PROD_ENV" | head -n1 | tr -d '\r' | sed 's/^"//;s/"$//')
S3_BUCKET=$(  sed -n 's/^S3_BUCKET=//p'   "$PROD_ENV" | head -n1 | tr -d '\r' | sed 's/^"//;s/"$//')

if command -v aws >/dev/null 2>&1; then
    # aws CLI: simpler read-test auf Bucket
    if AWS_ACCESS_KEY_ID="$NEW_ACC" AWS_SECRET_ACCESS_KEY="$NEW_SEC" \
       aws s3 ls --endpoint-url="$S3_ENDPOINT" "s3://$S3_BUCKET/" \
            --max-items 1 >> "$LOG_FILE" 2>&1; then
        say "${C_G}  aws s3 ls OK gegen $S3_BUCKET @ $S3_ENDPOINT${C_N}"
    else
        say "${C_R}FAIL: aws s3 ls liefert Fehler - neue Keys scheinen nicht zu greifen${C_N}"
        false
    fi
else
    say "${C_Y}  aws CLI nicht installiert - Verify uebersprungen.${C_N}"
    say "${C_Y}  Bitte manuell testen (z.B. Bild-Upload im Admin).${C_N}"
fi

trap - ERR

# ---- Abschluss -------------------------------------------------------------
say
say "${C_C}=== ROTATION ERFOLGREICH ===${C_N}"
say "Prod-.env:     $PROD_ENV"
[ $HAVE_STAGING -eq 1 ] && say "Staging-.env:  $STAG_ENV"
say "Backup:        $BACKUP_DIR"
say
say "${C_Y}Naechster Schritt beim S3-Provider:${C_N}"
say "  ALTEN Access-Key jetzt DEAKTIVIEREN/LOESCHEN."
say "  Erst dann ist die Rotation vollstaendig."
say
log "S3-Keys rotiert (Backup: $BACKUP_DIR)"
