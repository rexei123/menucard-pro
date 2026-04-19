#!/usr/bin/env bash
# ============================================================================
# rotate-secrets.sh
# ----------------------------------------------------------------------------
# Rotiert die Priority-1-Secrets von MenuCard Pro (Prod + Staging):
#   - NEXTAUTH_SECRET (Prod)     - eigener neuer Wert
#   - NEXTAUTH_SECRET (Staging)  - eigener neuer Wert
#   - DB-Passwort fuer den 'menucard'-PG-User (shared zwischen Prod + Staging)
#
# Ablauf:
#   1. Discovery     : aktuelle .env-Keys (maskiert) einlesen, PG-Ping
#   2. Dry-Run       : bei --dry-run hier exit 0
#   3. Backup        : .env Prod + Staging nach /var/backups/menucard-pro/secrets-pre-rotation-<ts>/
#   4. Rotate        : NEXTAUTH_SECRET in beiden .env, DB-Passwort in PG + beiden .env
#   5. Restart       : pm2 restart menucard-pro + menucard-pro-staging
#   6. Verify        : curl /api/health gegen 3000 + 3001, psql mit neuem Passwort
#   7. Log + Summary
#
# Bei Fehler ab Schritt 4: Restore .env aus Backup + psql ALTER USER zurueck
# auf altes Passwort + pm2 restart. Exit 1.
#
# Aufruf:
#   sudo bash /var/www/menucard-pro/scripts/rotate-secrets.sh            # interaktiv
#   sudo bash /var/www/menucard-pro/scripts/rotate-secrets.sh --yes      # ohne Rueckfrage
#   sudo bash /var/www/menucard-pro/scripts/rotate-secrets.sh --dry-run  # nur Discovery
# ============================================================================

set -eu
set -o pipefail

# --- Konstanten -------------------------------------------------------------
PROD_DIR="/var/www/menucard-pro"
STAG_DIR="/var/www/menucard-pro-staging"
PROD_ENV="$PROD_DIR/.env"
STAG_ENV="$STAG_DIR/.env"
PROD_PM2="menucard-pro"
STAG_PM2="menucard-pro-staging"
PROD_HEALTH_URL="http://127.0.0.1:3000/api/health"
STAG_HEALTH_URL="http://127.0.0.1:3001/api/health"

BACKUP_ROOT="/var/backups/menucard-pro"
LOG_FILE="/var/log/menucard-secrets-rotation.log"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${BACKUP_ROOT}/secrets-pre-rotation-${TS}"

DRY_RUN=0
YES=0

# --- Farben ----------------------------------------------------------------
if [ -t 1 ]; then
    C_R=$'\e[31m'; C_G=$'\e[32m'; C_Y=$'\e[33m'; C_C=$'\e[36m'; C_N=$'\e[0m'
else
    C_R=""; C_G=""; C_Y=""; C_C=""; C_N=""
fi

# --- Helper ----------------------------------------------------------------
say()   { printf "%s\n" "$*" | tee -a "$LOG_FILE" >/dev/null; printf "%s\n" "$*"; }
ok()    { say "${C_G}OK   $*${C_N}"; }
warn()  { say "${C_Y}WARN $*${C_N}"; }
fail()  { say "${C_R}FAIL $*${C_N}"; }
step()  { say ""; say "${C_Y}[$1] $2${C_N}"; }
section() { say ""; say "${C_C}=== $1 ===${C_N}"; }

mask_secret() {
    # zeigt nur die letzten 4 Zeichen
    local v="$1"
    local len=${#v}
    if [ "$len" -le 4 ]; then
        printf "****"
    else
        printf "****%s" "${v: -4}"
    fi
}

# --- Arg parsen ------------------------------------------------------------
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --yes|-y)  YES=1 ;;
        --help|-h)
            sed -n '1,30p' "$0"
            exit 0
            ;;
        *) fail "Unbekanntes Argument: $arg"; exit 2 ;;
    esac
done

# --- Root-Check ------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    fail "Muss als root laufen (oder via sudo)."
    exit 1
fi

mkdir -p "$BACKUP_ROOT"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"

section "MenuCard Pro Secrets-Rotation (${TS})"

# ----------------------------------------------------------------------
# 1. DISCOVERY
# ----------------------------------------------------------------------
step "1/7" "Discovery"

if [ ! -f "$PROD_ENV" ]; then fail "Prod-.env fehlt: $PROD_ENV"; exit 1; fi
if [ ! -f "$STAG_ENV" ]; then fail "Staging-.env fehlt: $STAG_ENV"; exit 1; fi

extract_env_var() {
    # $1 = file, $2 = key
    local key="$2"
    awk -v k="^${key}=" 'match($0,k){sub(k,""); print; exit}' "$1"
}

extract_db_password() {
    # extrahiert Passwort aus DATABASE_URL postgresql://<user>:<pw>@host...
    local file="$1"
    local url
    url="$(extract_env_var "$file" DATABASE_URL)"
    # strip umgebende Anfuehrungszeichen
    url="${url%\"}"; url="${url#\"}"; url="${url%\'}"; url="${url#\'}"
    # postgresql://<user>:<password>@host:port/db
    echo "$url" | sed -E 's|^[^:]+://[^:]+:([^@]+)@.*$|\1|'
}

extract_db_user() {
    local file="$1"
    local url
    url="$(extract_env_var "$file" DATABASE_URL)"
    url="${url%\"}"; url="${url#\"}"; url="${url%\'}"; url="${url#\'}"
    echo "$url" | sed -E 's|^[^:]+://([^:]+):.*$|\1|'
}

OLD_PROD_NEXT="$(extract_env_var "$PROD_ENV" NEXTAUTH_SECRET | tr -d '"'"'")"
OLD_STAG_NEXT="$(extract_env_var "$STAG_ENV" NEXTAUTH_SECRET | tr -d '"'"'")"
OLD_PROD_PW="$(extract_db_password "$PROD_ENV")"
OLD_STAG_PW="$(extract_db_password "$STAG_ENV")"
PROD_DB_USER="$(extract_db_user "$PROD_ENV")"
STAG_DB_USER="$(extract_db_user "$STAG_ENV")"

say "  Prod-.env:       $PROD_ENV"
say "    DB-User:       $PROD_DB_USER"
say "    DB-Passwort:   $(mask_secret "$OLD_PROD_PW")"
say "    NEXTAUTH:      $(mask_secret "$OLD_PROD_NEXT")"
say "  Staging-.env:    $STAG_ENV"
say "    DB-User:       $STAG_DB_USER"
say "    DB-Passwort:   $(mask_secret "$OLD_STAG_PW")"
say "    NEXTAUTH:      $(mask_secret "$OLD_STAG_NEXT")"

if [ "$PROD_DB_USER" != "$STAG_DB_USER" ]; then
    warn "Prod und Staging nutzen verschiedene DB-User ($PROD_DB_USER vs $STAG_DB_USER)."
    warn "Dieser Rotation-Lauf rotiert nur '$PROD_DB_USER'. '$STAG_DB_USER' bleibt unveraendert."
fi
if [ "$PROD_DB_USER" = "$STAG_DB_USER" ] && [ "$OLD_PROD_PW" != "$OLD_STAG_PW" ]; then
    fail "Prod und Staging nutzen denselben User '$PROD_DB_USER', aber unterschiedliche Passwoerter in den .env!"
    fail "Bitte erst manuell synchronisieren."
    exit 1
fi

# PG erreichbar?
if ! pg_isready -h 127.0.0.1 -p 5432 -q; then
    fail "PostgreSQL nicht erreichbar auf 127.0.0.1:5432."
    exit 1
fi
ok "PostgreSQL erreichbar"

# PM2-Prozesse da?
if ! pm2 describe "$PROD_PM2" >/dev/null 2>&1; then
    fail "PM2-Prozess '$PROD_PM2' nicht gefunden."
    exit 1
fi
if ! pm2 describe "$STAG_PM2" >/dev/null 2>&1; then
    warn "PM2-Prozess '$STAG_PM2' nicht gefunden - Staging-Rotation wird trotzdem versucht."
fi
ok "PM2-Prozesse ok"

# ----------------------------------------------------------------------
# 2. DRY-RUN
# ----------------------------------------------------------------------
if [ "$DRY_RUN" -eq 1 ]; then
    section "DRY-RUN - ende ohne Aenderungen"
    say "Geplante Aktionen:"
    say "  - Generiere neues NEXTAUTH_SECRET fuer Prod (48 Byte, base64)"
    say "  - Generiere neues NEXTAUTH_SECRET fuer Staging (unabhaengig)"
    say "  - Generiere neues DB-Passwort fuer User '$PROD_DB_USER'"
    say "  - Backup .env-Dateien nach: $BACKUP_DIR"
    say "  - ALTER USER $PROD_DB_USER WITH PASSWORD '<neu>' (ueber psql als menucard superuser)"
    say "  - Schreibe beide .env-Dateien atomar neu"
    say "  - pm2 restart $PROD_PM2 + $STAG_PM2"
    say "  - curl $PROD_HEALTH_URL + $STAG_HEALTH_URL"
    ok "Dry-Run Ende"
    exit 0
fi

# ----------------------------------------------------------------------
# 3. BESTAETIGUNG
# ----------------------------------------------------------------------
if [ "$YES" -ne 1 ]; then
    say ""
    say "Achtung: Rotation invalidiert alle Login-Sessions und aendert DB-Credentials."
    read -r -p "Weiter? (y/n) " ans
    case "$ans" in y|Y) : ;; *) warn "Abbruch durch User"; exit 0 ;; esac
fi

# ----------------------------------------------------------------------
# 4. BACKUP
# ----------------------------------------------------------------------
step "2/7" "Backup der .env-Dateien nach $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
cp -p "$PROD_ENV" "$BACKUP_DIR/prod.env"
cp -p "$STAG_ENV" "$BACKUP_DIR/staging.env"
chmod 600 "$BACKUP_DIR/"*
ok "Backup erstellt"

# ----------------------------------------------------------------------
# 5. NEUE SECRETS GENERIEREN
# ----------------------------------------------------------------------
step "3/7" "Neue Secrets generieren"
NEW_PROD_NEXT="$(openssl rand -base64 48 | tr -d '\n')"
NEW_STAG_NEXT="$(openssl rand -base64 48 | tr -d '\n')"
# Passwort ohne @:/\' damit URL-safe
NEW_DB_PW="$(openssl rand -base64 36 | tr -d '\n' | tr -d '/=+@:')"
if [ -z "$NEW_DB_PW" ] || [ "${#NEW_DB_PW}" -lt 20 ]; then
    fail "Generiertes DB-Passwort zu kurz (Zufallseffekt nach Filter) - Abbruch."
    exit 1
fi
ok "Drei neue Secrets im Speicher"

# ----------------------------------------------------------------------
# 6. ROLLBACK-FUNKTION
# ----------------------------------------------------------------------
rollback() {
    warn "Rollback gestartet ..."
    # .env zurueck
    if [ -f "$BACKUP_DIR/prod.env" ]; then
        cp -p "$BACKUP_DIR/prod.env" "$PROD_ENV" && ok "Prod-.env restored" || fail "Prod-.env restore FAIL"
    fi
    if [ -f "$BACKUP_DIR/staging.env" ]; then
        cp -p "$BACKUP_DIR/staging.env" "$STAG_ENV" && ok "Staging-.env restored" || fail "Staging-.env restore FAIL"
    fi
    # DB-Passwort zurueck (mit altem Passwort, falls neues schon gesetzt war)
    if [ -n "${DB_ROTATED:-}" ] && [ "$DB_ROTATED" = "1" ]; then
        warn "Versuche DB-Passwort zurueckzusetzen ..."
        # Wir muessen ein Passwort haben, das grad gueltig ist. Nach dem ALTER war nur noch NEW_DB_PW gueltig.
        PGPASSWORD="$NEW_DB_PW" psql -h 127.0.0.1 -U "$PROD_DB_USER" -d postgres -v ON_ERROR_STOP=1 \
            -c "ALTER USER \"$PROD_DB_USER\" WITH PASSWORD '$(printf '%s' "$OLD_PROD_PW" | sed "s/'/''/g")';" \
            >/dev/null 2>&1 && ok "DB-Passwort zurueckgesetzt" || fail "DB-Passwort Rollback FAIL - Backup .env-Dateien pruefen!"
    fi
    # Apps neu starten
    pm2 restart "$PROD_PM2" >/dev/null 2>&1 || true
    pm2 restart "$STAG_PM2" >/dev/null 2>&1 || true
    fail "Rollback abgeschlossen. Log: $LOG_FILE"
}
trap rollback ERR

DB_ROTATED=0

# ----------------------------------------------------------------------
# 7. DB-PASSWORT IN PG AENDERN
# ----------------------------------------------------------------------
step "4/7" "DB-Passwort fuer '$PROD_DB_USER' rotieren"

# Escape-Passwort fuer SQL (einfache Quotes doppeln)
SQL_PW="$(printf '%s' "$NEW_DB_PW" | sed "s/'/''/g")"

PGPASSWORD="$OLD_PROD_PW" psql -h 127.0.0.1 -U "$PROD_DB_USER" -d postgres -v ON_ERROR_STOP=1 \
    -c "ALTER USER \"$PROD_DB_USER\" WITH PASSWORD '${SQL_PW}';" >/dev/null
DB_ROTATED=1
ok "PG-Passwort geaendert"

# Sofortige Verifikation mit neuem Passwort
if ! PGPASSWORD="$NEW_DB_PW" psql -h 127.0.0.1 -U "$PROD_DB_USER" -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
    fail "Neues DB-Passwort funktioniert nicht - trigger Rollback."
    false
fi
ok "Neues DB-Passwort verifiziert"

# ----------------------------------------------------------------------
# 8. .ENV-DATEIEN AKTUALISIEREN
# ----------------------------------------------------------------------
step "5/7" ".env-Dateien atomar aktualisieren"

update_env_file() {
    # $1 = file, $2 = new NEXTAUTH_SECRET, $3 = new DB password (optional - falls leer, DB-URL bleibt)
    local file="$1"
    local new_next="$2"
    local new_pw="$3"
    local tmp="${file}.new.${TS}"

    # Line by line umschreiben
    awk -v NEW_NEXT="$new_next" -v NEW_PW="$new_pw" '
    BEGIN { next_done=0; db_done=0 }
    /^NEXTAUTH_SECRET=/ {
        print "NEXTAUTH_SECRET=\"" NEW_NEXT "\""
        next_done=1
        next
    }
    /^DATABASE_URL=/ {
        if (NEW_PW != "") {
            line=$0
            # postgresql://<user>:<pw>@rest
            # Wir ersetzen nur das Passwort-Segment zwischen erstem ":" nach "//" und erstem "@".
            head=substr(line, 1, index(line, "://") + 2)   # bis einschl. "://"
            rest=substr(line, index(line, "://") + 3)
            userPart=substr(rest, 1, index(rest, ":") - 1)
            afterUser=substr(rest, index(rest, ":") + 1)
            afterPw=substr(afterUser, index(afterUser, "@"))
            # Quotes ggf. schuetzen
            quote=""
            if (substr(line, length(line)) == "\"") quote="\""
            if (substr(line, length(line)) == "\x27") quote="\x27"
            # Wenn Wert komplett gequotet war, Anfangs-Quote auch beruecksichtigen
            prefix="DATABASE_URL="
            val=substr(line, length(prefix)+1)
            vlen=length(val)
            leading=""
            trailing=""
            if (vlen>=2 && (substr(val,1,1)=="\"" || substr(val,1,1)=="\x27") && substr(val,vlen,1)==substr(val,1,1)) {
                leading=substr(val,1,1); trailing=substr(val,1,1)
                val=substr(val,2,vlen-2)
            }
            # neu zusammenbauen
            sep=index(val,"://")
            scheme=substr(val,1,sep+2)
            tail=substr(val,sep+3)
            userName=""; i=1
            while(i<=length(tail) && substr(tail,i,1)!=":") { userName=userName substr(tail,i,1); i++ }
            # i zeigt auf ":"
            afterColon=substr(tail,i+1)
            atIdx=index(afterColon,"@")
            afterAt=substr(afterColon,atIdx)
            new_val=scheme userName ":" NEW_PW afterAt
            print "DATABASE_URL=" leading new_val trailing
            db_done=1
            next
        }
    }
    { print }
    END {
        if (!next_done) print "NEXTAUTH_SECRET=\"" NEW_NEXT "\""
    }
    ' "$file" > "$tmp"

    # Permissions uebertragen
    chmod --reference="$file" "$tmp"
    chown --reference="$file" "$tmp"
    mv "$tmp" "$file"
}

update_env_file "$PROD_ENV" "$NEW_PROD_NEXT" "$NEW_DB_PW"
ok "Prod-.env aktualisiert"

# Staging-.env: NEXTAUTH neu, DB-PW nur wenn staging denselben User nutzt
if [ "$PROD_DB_USER" = "$STAG_DB_USER" ]; then
    update_env_file "$STAG_ENV" "$NEW_STAG_NEXT" "$NEW_DB_PW"
    ok "Staging-.env aktualisiert (NEXTAUTH + DB-Passwort)"
else
    update_env_file "$STAG_ENV" "$NEW_STAG_NEXT" ""
    ok "Staging-.env aktualisiert (nur NEXTAUTH)"
fi

# Nochmals verifizieren dass Pfad stimmt
NEW_PROD_NEXT_FILE="$(extract_env_var "$PROD_ENV" NEXTAUTH_SECRET | tr -d '"'"'")"
NEW_STAG_NEXT_FILE="$(extract_env_var "$STAG_ENV" NEXTAUTH_SECRET | tr -d '"'"'")"
NEW_PROD_PW_FILE="$(extract_db_password "$PROD_ENV")"
if [ "$NEW_PROD_NEXT_FILE" != "$NEW_PROD_NEXT" ]; then fail ".env Prod NEXTAUTH falsch geschrieben"; false; fi
if [ "$NEW_STAG_NEXT_FILE" != "$NEW_STAG_NEXT" ]; then fail ".env Staging NEXTAUTH falsch geschrieben"; false; fi
if [ "$NEW_PROD_PW_FILE" != "$NEW_DB_PW" ]; then fail ".env Prod DB-Passwort falsch geschrieben"; false; fi
ok ".env-Verifikation bestanden"

# ----------------------------------------------------------------------
# 9. PM2 RESTART
# ----------------------------------------------------------------------
step "6/7" "PM2 restart"
pm2 restart "$PROD_PM2" --update-env >/dev/null
ok "$PROD_PM2 neu gestartet"
if pm2 describe "$STAG_PM2" >/dev/null 2>&1; then
    pm2 restart "$STAG_PM2" --update-env >/dev/null
    ok "$STAG_PM2 neu gestartet"
fi
pm2 save >/dev/null 2>&1 || true

# ----------------------------------------------------------------------
# 10. VERIFIKATION
# ----------------------------------------------------------------------
step "7/7" "Health-Check"
sleep 3

check_url() {
    # $1 = url, $2 = label
    local attempts=15
    local i=1
    while [ $i -le $attempts ]; do
        if code="$(curl -s -o /dev/null -w '%{http_code}' "$1")" && [ "$code" = "200" ]; then
            ok "$2 -> HTTP 200"
            return 0
        fi
        sleep 1
        i=$((i+1))
    done
    fail "$2 -> kein HTTP 200 nach ${attempts}s (letzter Code: ${code:-?})"
    return 1
}

check_url "$PROD_HEALTH_URL" "Prod /api/health"
if pm2 describe "$STAG_PM2" >/dev/null 2>&1; then
    check_url "$STAG_HEALTH_URL" "Staging /api/health"
fi

# Trap aufheben, wir sind durch
trap - ERR

# ----------------------------------------------------------------------
# 11. FERTIG
# ----------------------------------------------------------------------
section "ROTATION ERFOLGREICH"
say "Backup:   $BACKUP_DIR"
say "Log:      $LOG_FILE"
say ""
say "Neue Secrets (bitte nicht aus dem Log kopieren - stehen nur in .env):"
say "  Prod NEXTAUTH_SECRET:    $(mask_secret "$NEW_PROD_NEXT")"
say "  Staging NEXTAUTH_SECRET: $(mask_secret "$NEW_STAG_NEXT")"
say "  DB-Passwort '$PROD_DB_USER': $(mask_secret "$NEW_DB_PW")"
say ""
say "Wichtig: alle Admin-Sessions sind ungueltig, bitte einmal neu einloggen."
exit 0
