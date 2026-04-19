#!/bin/bash
# ============================================================================
# MenuCard Pro — Staging Nginx Basic-Auth Rotation
# ============================================================================
# Rotiert das Passwort des Basic-Auth-Users 'sonnblick' in:
#   - /etc/nginx/.htpasswd-staging
#   - /root/.secrets/staging-basic-auth.txt (Klartext fuer Browser/Password-Mgr)
#
# Flow:
#   1. Backup des htpasswd + alten Creds-Files
#   2. Neues Passwort generieren (alphanumerisch, 20 Zeichen)
#   3. htpasswd -b ersetzt NUR den Eintrag 'sonnblick' (andere bleiben)
#   4. nginx -t Konfigurations-Test
#   5. systemctl reload nginx
#   6. /root/.secrets/staging-basic-auth.txt neu schreiben
#   7. Verify via curl gegen Staging-URL
#
# Bei Fehler: Rollback aus Backup (htpasswd + optional Creds-File), nginx reload
#
# Aufruf:
#   bash scripts/rotate-staging-basic-auth.sh --dry-run
#   bash scripts/rotate-staging-basic-auth.sh --yes
# ============================================================================
set -Eeuo pipefail

# ---- Konstanten ------------------------------------------------------------
HTPASSWD_FILE="/etc/nginx/.htpasswd-staging"
BASIC_USER="sonnblick"
CREDS_FILE="/root/.secrets/staging-basic-auth.txt"
BACKUP_BASE="/var/backups/menucard-pro"
LOG_FILE="/var/log/menucard-basic-auth-rotation.log"
STAGING_URL="https://staging.menu.hotel-sonnblick.at/"
PW_LENGTH=20

TS=$(date '+%Y%m%d-%H%M%S')
BACKUP_DIR="${BACKUP_BASE}/basic-auth-pre-rotation-${TS}"

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
say "${C_C}=== MenuCard Pro Staging Basic-Auth Rotation ===${C_N}"
say "Start: $(date '+%F %T')"
say "Modus: $([ $DRY_RUN -eq 1 ] && echo 'DRY-RUN' || echo 'LIVE')"
say

# ---- Preflight -------------------------------------------------------------
command -v htpasswd >/dev/null 2>&1 || {
    say "${C_R}FAIL: 'htpasswd' nicht installiert. apt-get install apache2-utils${C_N}"
    exit 1
}
command -v nginx >/dev/null 2>&1 || {
    say "${C_R}FAIL: 'nginx' nicht installiert.${C_N}"
    exit 1
}
[ -f "$HTPASSWD_FILE" ] || {
    say "${C_R}FAIL: $HTPASSWD_FILE fehlt.${C_N}"
    exit 1
}

# ---- 1. Discovery ----------------------------------------------------------
say "${C_Y}[1/6] Discovery${C_N}"
say "  htpasswd:   $HTPASSWD_FILE"
say "  User:       $BASIC_USER"
say "  Creds:      $CREDS_FILE"
say "  Staging:    $STAGING_URL"

if grep -q "^${BASIC_USER}:" "$HTPASSWD_FILE"; then
    say "  User im htpasswd: ${C_G}vorhanden${C_N}"
else
    say "  User im htpasswd: ${C_Y}NICHT vorhanden - wird angelegt${C_N}"
fi

OTHER_USERS=$(grep -v "^${BASIC_USER}:" "$HTPASSWD_FILE" 2>/dev/null | grep -c '^[^#[:space:]]' || true)
say "  Andere User:  $OTHER_USERS (bleiben unveraendert)"

# ---- 2. Dry-Run vorher aussteigen -----------------------------------------
if [ $DRY_RUN -eq 1 ]; then
    say
    say "${C_C}[DRY-RUN] Rotation wuerde:${C_N}"
    say "  - Backup: $BACKUP_DIR/htpasswd-staging + ggf. alte Creds"
    say "  - neues Passwort generieren ($PW_LENGTH Zeichen, alphanumerisch)"
    say "  - htpasswd -b $HTPASSWD_FILE $BASIC_USER <new-pw>"
    say "  - nginx -t (Config-Test)"
    say "  - systemctl reload nginx"
    say "  - $CREDS_FILE neu schreiben (chmod 600)"
    say "  - curl -u $BASIC_USER:<pw> $STAGING_URL (Verify: HTTP 2xx oder 3xx)"
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
say "${C_Y}[2/6] Backup htpasswd + Creds-File${C_N}"
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
cp -a "$HTPASSWD_FILE" "$BACKUP_DIR/htpasswd-staging"
if [ -f "$CREDS_FILE" ]; then
    cp -a "$CREDS_FILE" "$BACKUP_DIR/staging-basic-auth.old.txt"
fi
chmod 600 "$BACKUP_DIR"/*
say "${C_G}  Backup: $BACKUP_DIR${C_N}"

# ---- 4. Neues Passwort -----------------------------------------------------
say
say "${C_Y}[3/6] Neues Passwort generieren${C_N}"
NEW_PW=$(openssl rand -base64 30 | tr -d '/+=' | tr -d '\n' | head -c "$PW_LENGTH")
if [ "${#NEW_PW}" -lt "$PW_LENGTH" ]; then
    say "${C_R}FAIL: konnte kein Passwort mit $PW_LENGTH Zeichen erzeugen${C_N}"
    exit 1
fi
say "${C_G}  Passwort erzeugt (${#NEW_PW} Zeichen)${C_N}"

# ---- 5. Rollback-Trap ------------------------------------------------------
rollback() {
    say
    say "${C_R}=== ROLLBACK ===${C_N}"
    cp -a "$BACKUP_DIR/htpasswd-staging" "$HTPASSWD_FILE" 2>>"$LOG_FILE" || true
    chmod 640 "$HTPASSWD_FILE" 2>>"$LOG_FILE" || true
    chown root:www-data "$HTPASSWD_FILE" 2>>"$LOG_FILE" || true
    if [ -f "$BACKUP_DIR/staging-basic-auth.old.txt" ]; then
        cp -a "$BACKUP_DIR/staging-basic-auth.old.txt" "$CREDS_FILE" 2>>"$LOG_FILE" || true
    fi
    nginx -t >> "$LOG_FILE" 2>&1 && systemctl reload nginx >> "$LOG_FILE" 2>&1 || true
    say "${C_Y}Rollback durchgefuehrt. Backup: $BACKUP_DIR${C_N}"
    exit 1
}
trap rollback ERR

# ---- 6. htpasswd aktualisieren ---------------------------------------------
say
say "${C_Y}[4/6] htpasswd -b (ersetzt NUR User '$BASIC_USER')${C_N}"
# -b: Passwort per Arg (nicht interaktiv), KEIN -c (File bleibt, andere User bleiben)
htpasswd -b "$HTPASSWD_FILE" "$BASIC_USER" "$NEW_PW" >> "$LOG_FILE" 2>&1
chmod 640 "$HTPASSWD_FILE"
chown root:www-data "$HTPASSWD_FILE"
say "${C_G}  htpasswd aktualisiert${C_N}"

# ---- 7. nginx config test + reload -----------------------------------------
say
say "${C_Y}[5/6] nginx -t + reload${C_N}"
nginx -t >> "$LOG_FILE" 2>&1
systemctl reload nginx
say "${C_G}  nginx reloaded${C_N}"

# ---- 8. Creds-File neu schreiben -------------------------------------------
say
say "${C_Y}[6/6] Creds-File + Verify${C_N}"
mkdir -p "$(dirname "$CREDS_FILE")"
chmod 700 "$(dirname "$CREDS_FILE")"
umask 177
cat > "$CREDS_FILE" <<EOF
URL=$STAGING_URL
USER=$BASIC_USER
PASSWORD=$NEW_PW
ROTATED=$(date -Iseconds)
EOF
chmod 600 "$CREDS_FILE"
say "${C_G}  $CREDS_FILE (chmod 600)${C_N}"

# ---- 9. Verify via curl ----------------------------------------------------
# -o /dev/null unterdrueckt Body; -w '%{http_code}' gibt Statuscode zurueck
# Staging kann 200 (Homepage) oder 3xx (Redirect auf /admin oder /auth/login) liefern
HTTP=$(curl -sS -o /dev/null -w '%{http_code}' \
    --max-time 10 \
    -u "$BASIC_USER:$NEW_PW" \
    "$STAGING_URL" || echo "000")

say "  HTTP $HTTP gegen $STAGING_URL"
case "$HTTP" in
    2*|3*) say "${C_G}  Verify OK (HTTP $HTTP)${C_N}" ;;
    401)   say "${C_R}FAIL: HTTP 401 - Passwort scheint nicht zu greifen${C_N}"; false ;;
    000)   say "${C_Y}WARN: curl-Timeout/DNS-Fehler - Rotation trotzdem aktiv (manuell pruefen)${C_N}" ;;
    *)     say "${C_Y}WARN: unerwarteter HTTP $HTTP - manuell pruefen${C_N}" ;;
esac

trap - ERR

# ---- Abschluss -------------------------------------------------------------
say
say "${C_C}=== ROTATION ERFOLGREICH ===${C_N}"
say "User:     $BASIC_USER"
say "Passwort: ${C_G}$NEW_PW${C_N}"
say "URL:      $STAGING_URL"
say
say "${C_Y}Bitte SOFORT in den Password-Manager uebernehmen.${C_N}"
say "Backup: $BACKUP_DIR"
say "Log:    $LOG_FILE"
say
log "Staging-Basic-Auth rotiert fuer $BASIC_USER (Backup: $BACKUP_DIR)"
