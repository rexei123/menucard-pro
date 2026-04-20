#!/bin/bash
# ============================================================================
# MenuCard Pro — Git-basiertes Deploy-Script
# Ort auf dem Server: /var/www/menucard-pro/scripts/deploy.sh
# Aufruf (lokal):     ssh root@178.104.138.177 "bash /var/www/menucard-pro/scripts/deploy.sh [--yes]"
# Aufruf (Server):    bash /var/www/menucard-pro/scripts/deploy.sh [--yes|--dry-run|--no-build]
# ============================================================================
# Ablauf:
#   1.  Flags parsen + Lock-File setzen
#   2.  Pre-Check: .env vorhanden, Repo, origin erreichbar
#   3.  Aktuellen HEAD merken (fuer Rollback)
#   4.  git fetch origin main
#   5.  Diff-Preview (Commits + geaenderte Dateien)
#   6.  Bestaetigung (interaktiv) / ueberspringbar mit --yes / --dry-run
#   7.  Pre-Deploy DB-Backup (pg_dump)
#   8.  git reset --hard origin/main
#   9.  Conditional: npm ci (bei package(-lock).json-Aenderung)
#  10.  Conditional: prisma db push (bei schema.prisma-Aenderung)
#  11.  npm run build
#  12.  pm2 restart menucard-pro
#  13.  Smoke-Test (HTTP 200 auf Startseite)
#  14.  Bei Fehler ab 9: Rollback auf PRE_DEPLOY_HEAD + pm2 restart
#  15.  Deploy-Log schreiben
# ============================================================================
set -euo pipefail

# ----------------------------------------------------------------------
# Konfiguration
# ----------------------------------------------------------------------
APP_DIR="/var/www/menucard-pro"
APP_NAME="menucard-pro"
SMOKE_URL="https://menu.hotel-sonnblick.at/"
SMOKE_URL_FALLBACK="http://127.0.0.1:3000/"
LOCK_FILE="/var/run/menucard-deploy.lock"
DEPLOY_LOG="/var/log/menucard-deploy.log"
BACKUP_SCRIPT="${APP_DIR}/scripts/backup-db.sh"

C_C=$'\e[36m'; C_G=$'\e[32m'; C_Y=$'\e[33m'; C_R=$'\e[31m'; C_N=$'\e[0m'

# ----------------------------------------------------------------------
# Flags
# ----------------------------------------------------------------------
AUTO_YES=0
DRY_RUN=0
NO_BUILD=0
for arg in "$@"; do
    case "$arg" in
        --yes|-y)     AUTO_YES=1 ;;
        --dry-run)    DRY_RUN=1; AUTO_YES=1 ;;
        --no-build)   NO_BUILD=1 ;;
        -h|--help)
            sed -n '1,30p' "$0"
            exit 0
            ;;
        *)
            echo "${C_R}Unbekanntes Flag: $arg${C_N}" >&2
            exit 2
            ;;
    esac
done

# ----------------------------------------------------------------------
# Logging-Helfer
# ----------------------------------------------------------------------
mkdir -p "$(dirname "$DEPLOY_LOG")"
log() {
    local msg="${1:-}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $msg" >> "$DEPLOY_LOG"
}
say() {
    local msg="${1:-}"
    echo -e "$msg"
    log "$(echo -e "$msg" | sed 's/\x1b\[[0-9;]*m//g')"
}

# ----------------------------------------------------------------------
# 1. LOCK
# ----------------------------------------------------------------------
if [ -e "$LOCK_FILE" ]; then
    OTHER_PID=$(cat "$LOCK_FILE" 2>/dev/null || echo "?")
    if [ -n "$OTHER_PID" ] && kill -0 "$OTHER_PID" 2>/dev/null; then
        say "${C_R}Deploy laeuft bereits (PID $OTHER_PID). Abbruch.${C_N}"
        exit 1
    fi
    say "${C_Y}Stale Lock gefunden (PID $OTHER_PID nicht aktiv) - raeume auf.${C_N}"
    rm -f "$LOCK_FILE"
fi
echo "$$" > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

say
say "${C_C}=== MenuCard Pro Deploy ===${C_N}"
say "Start:   $(date '+%Y-%m-%d %H:%M:%S')"
say "Modus:   $([ $DRY_RUN -eq 1 ] && echo 'DRY-RUN' || echo 'LIVE')"
say

# ----------------------------------------------------------------------
# 2. PRE-CHECKS
# ----------------------------------------------------------------------
cd "$APP_DIR"

if [ ! -d .git ]; then
    say "${C_R}Kein Git-Repo in $APP_DIR. Abbruch.${C_N}"
    exit 1
fi
if [ ! -f .env ]; then
    say "${C_R}.env fehlt in $APP_DIR. Abbruch.${C_N}"
    exit 1
fi
if ! git remote | grep -q '^origin$'; then
    say "${C_R}Remote 'origin' nicht konfiguriert. Abbruch.${C_N}"
    exit 1
fi

# ----------------------------------------------------------------------
# 3. PRE-DEPLOY HEAD MERKEN (fuer Rollback)
# ----------------------------------------------------------------------
PRE_DEPLOY_HEAD=$(git rev-parse HEAD)
PRE_DEPLOY_SHORT=$(git rev-parse --short HEAD)
say "${C_Y}[1/9] Pre-Deploy HEAD: ${PRE_DEPLOY_SHORT}${C_N}"

# ----------------------------------------------------------------------
# 4. FETCH
# ----------------------------------------------------------------------
say "${C_Y}[2/9] git fetch origin main ...${C_N}"
if ! git fetch origin main 2>&1 | tee -a "$DEPLOY_LOG"; then
    say "${C_R}Fetch fehlgeschlagen. Abbruch.${C_N}"
    exit 1
fi

TARGET_HEAD=$(git rev-parse origin/main)
TARGET_SHORT=$(git rev-parse --short origin/main)

if [ "$PRE_DEPLOY_HEAD" = "$TARGET_HEAD" ]; then
    say "${C_G}HEAD bereits auf origin/main (${TARGET_SHORT}). Kein Deploy noetig.${C_N}"
    exit 0
fi

# ----------------------------------------------------------------------
# 5. DIFF-PREVIEW
# ----------------------------------------------------------------------
say
say "${C_C}--- Neue Commits ---${C_N}"
# Native Limit mit -n; kein |head (SIGPIPE mit pipefail)
git log --oneline -n 20 "${PRE_DEPLOY_HEAD}..${TARGET_HEAD}" | sed 's/^/  /'

say
say "${C_C}--- Geaenderte Dateien ---${C_N}"
CHANGED_FILES=$(git diff --name-only "${PRE_DEPLOY_HEAD}..${TARGET_HEAD}")
if [ -z "$CHANGED_FILES" ]; then
    say "  (keine)"
else
    # sed -n '1,30p' liest bis EOF -> kein SIGPIPE
    echo "$CHANGED_FILES" | sed -n '1,30p' | sed 's/^/  /'
    TOTAL=$(printf '%s\n' "$CHANGED_FILES" | wc -l)
    if [ "$TOTAL" -gt 30 ]; then
        say "  ... und $((TOTAL - 30)) weitere (gesamt $TOTAL)"
    fi
fi

# Conditional-Flags fuer spaetere Schritte bestimmen
NEEDS_NPM_CI=0
NEEDS_PRISMA=0
NEEDS_TEMPLATE_SEED=0
if echo "$CHANGED_FILES" | grep -qE '^(package\.json|package-lock\.json)$'; then
    NEEDS_NPM_CI=1
fi
if echo "$CHANGED_FILES" | grep -qE '^prisma/schema\.prisma$'; then
    NEEDS_PRISMA=1
fi
if echo "$CHANGED_FILES" | grep -qE '^(src/lib/design-templates/.*\.ts|prisma/seed-design-templates\.ts)$'; then
    NEEDS_TEMPLATE_SEED=1
fi

say
say "${C_C}--- Deploy-Plan ---${C_N}"
say "  Von:       ${PRE_DEPLOY_SHORT}"
say "  Nach:      ${TARGET_SHORT}"
say "  npm ci:    $([ $NEEDS_NPM_CI -eq 1 ] && echo 'JA' || echo 'nein')"
say "  prisma:    $([ $NEEDS_PRISMA -eq 1 ] && echo 'JA (db push)' || echo 'nein')"
say "  build:     $([ $NO_BUILD -eq 1 ] && echo 'uebersprungen (--no-build)' || echo 'JA')"
say "  templates: $([ $NEEDS_TEMPLATE_SEED -eq 1 ] && echo 'JA (seed SYSTEM)' || echo 'nein')"
say "  restart:   pm2 restart $APP_NAME"
say "  smoke:     curl $SMOKE_URL"
say

# ----------------------------------------------------------------------
# 6. DRY-RUN / BESTAETIGUNG
# ----------------------------------------------------------------------
if [ $DRY_RUN -eq 1 ]; then
    say "${C_C}DRY-RUN beendet - keine Aenderungen.${C_N}"
    exit 0
fi

if [ $AUTO_YES -ne 1 ]; then
    read -p "Deploy starten? (y/n) " ANS
    if [ "$ANS" != "y" ]; then
        say "${C_Y}Abgebrochen.${C_N}"
        exit 0
    fi
fi

# ----------------------------------------------------------------------
# Rollback-Funktion
# ----------------------------------------------------------------------
rollback() {
    local reason="$1"
    say
    say "${C_R}=== ROLLBACK ===${C_N}"
    say "Grund: $reason"
    say "Ziel:  ${PRE_DEPLOY_SHORT}"
    if git reset --hard "$PRE_DEPLOY_HEAD" 2>&1 | tee -a "$DEPLOY_LOG"; then
        say "${C_Y}Rollback im Git erfolgt. pm2 restart ...${C_N}"
        pm2 restart "$APP_NAME" >> "$DEPLOY_LOG" 2>&1 || \
            say "${C_R}pm2 restart nach Rollback fehlgeschlagen - manuelles Eingreifen noetig.${C_N}"
    else
        say "${C_R}Rollback fehlgeschlagen - manuelles Eingreifen noetig.${C_N}"
    fi
    exit 1
}

# ----------------------------------------------------------------------
# 7. DB-BACKUP
# ----------------------------------------------------------------------
say
say "${C_Y}[3/9] Pre-Deploy DB-Backup ...${C_N}"
if [ -x "$BACKUP_SCRIPT" ]; then
    if bash "$BACKUP_SCRIPT" 2>&1 | tee -a "$DEPLOY_LOG"; then
        say "${C_G}[3/9] Backup OK${C_N}"
    else
        rollback "DB-Backup fehlgeschlagen"
    fi
else
    say "${C_Y}[3/9] WARN: $BACKUP_SCRIPT nicht ausfuehrbar - uebersprungen${C_N}"
fi

# ----------------------------------------------------------------------
# 8. HARD RESET
# ----------------------------------------------------------------------
say
say "${C_Y}[4/9] git reset --hard origin/main ...${C_N}"
if ! git reset --hard "$TARGET_HEAD" 2>&1 | tee -a "$DEPLOY_LOG"; then
    rollback "git reset --hard fehlgeschlagen"
fi
say "${C_G}[4/9] OK - HEAD jetzt ${TARGET_SHORT}${C_N}"

# ----------------------------------------------------------------------
# 9. NPM CI (conditional)
# ----------------------------------------------------------------------
say
if [ $NEEDS_NPM_CI -eq 1 ]; then
    say "${C_Y}[5/9] npm ci (package.json geaendert) ...${C_N}"
    if ! npm ci 2>&1 | tee -a "$DEPLOY_LOG"; then
        rollback "npm ci fehlgeschlagen"
    fi
    say "${C_G}[5/9] OK${C_N}"
else
    say "${C_Y}[5/9] npm ci uebersprungen (keine Abhaengigkeits-Aenderungen)${C_N}"
fi

# ----------------------------------------------------------------------
# 10. PRISMA DB PUSH (conditional)
# ----------------------------------------------------------------------
say
if [ $NEEDS_PRISMA -eq 1 ]; then
    say "${C_Y}[6/9] prisma db push (schema.prisma geaendert) ...${C_N}"
    if ! npx prisma db push --skip-generate 2>&1 | tee -a "$DEPLOY_LOG"; then
        rollback "prisma db push fehlgeschlagen"
    fi
    say "${C_Y}       prisma generate ...${C_N}"
    if ! npx prisma generate 2>&1 | tee -a "$DEPLOY_LOG"; then
        rollback "prisma generate fehlgeschlagen"
    fi
    say "${C_G}[6/9] OK${C_N}"
else
    say "${C_Y}[6/9] prisma db push uebersprungen (Schema unveraendert)${C_N}"
fi

# ----------------------------------------------------------------------
# 11. BUILD
# ----------------------------------------------------------------------
say
if [ $NO_BUILD -eq 1 ]; then
    say "${C_Y}[7/9] npm run build uebersprungen (--no-build)${C_N}"
else
    say "${C_Y}[7/9] npm run build ...${C_N}"
    if ! npm run build 2>&1 | tee -a "$DEPLOY_LOG"; then
        rollback "npm run build fehlgeschlagen"
    fi
    say "${C_G}[7/9] OK${C_N}"
fi

# ----------------------------------------------------------------------
# 11b. DESIGN-TEMPLATES SEED + ARCHIV-CHECK (conditional)
# ----------------------------------------------------------------------
if [ $NEEDS_TEMPLATE_SEED -eq 1 ]; then
    say
    say "${C_Y}[7b/9] SYSTEM-Template 'minimal' neu seeden (idempotent) ...${C_N}"
    if ! npx tsx prisma/seed-design-templates.ts 2>&1 | tee -a "$DEPLOY_LOG"; then
        rollback "Template-Seed fehlgeschlagen"
    fi
    # Legacy-Templates (elegant/modern/classic) archivieren. Script bricht ab,
    # wenn ein Template noch von einer Karte genutzt wird — das waere ein Fehler
    # beim Deploy und muss manuell geklaert werden.
    if [ -f scripts/archive-legacy-system-templates.ts ]; then
        say "${C_Y}       Legacy-SYSTEM-Templates pruefen/archivieren ...${C_N}"
        if ! npx tsx scripts/archive-legacy-system-templates.ts --apply 2>&1 | tee -a "$DEPLOY_LOG"; then
            rollback "Legacy-Template-Archivierung fehlgeschlagen (siehe Log)"
        fi
    fi
    say "${C_G}[7b/9] OK${C_N}"
fi

# ----------------------------------------------------------------------
# 12. PM2 RESTART (GIT_COMMIT in .env einpflegen, dann restart --update-env)
# ----------------------------------------------------------------------
say
GIT_COMMIT_SHA=$(git rev-parse HEAD)
if grep -q '^GIT_COMMIT=' .env; then
    sed -i "s|^GIT_COMMIT=.*|GIT_COMMIT=${GIT_COMMIT_SHA}|" .env
else
    echo "GIT_COMMIT=${GIT_COMMIT_SHA}" >> .env
fi
say "${C_Y}[8/9] pm2 restart $APP_NAME (GIT_COMMIT=${PRE_DEPLOY_SHORT}..${TARGET_SHORT}) ...${C_N}"
if ! pm2 restart "$APP_NAME" --update-env 2>&1 | tee -a "$DEPLOY_LOG"; then
    rollback "pm2 restart fehlgeschlagen"
fi
say "${C_G}[8/9] OK${C_N}"

# ----------------------------------------------------------------------
# 13. SMOKE-TEST
# ----------------------------------------------------------------------
say
say "${C_Y}[9/9] Smoke-Test ...${C_N}"

# Kurz warten, bis App erreichbar ist
SMOKE_OK=0
for i in 1 2 3 4 5 6 7 8 9 10; do
    HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$SMOKE_URL" || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        SMOKE_OK=1
        break
    fi
    sleep 2
done

if [ $SMOKE_OK -eq 1 ]; then
    say "${C_G}[9/9] OK - HTTP 200 von ${SMOKE_URL}${C_N}"
else
    # Fallback: lokal testen (falls DNS/SSL temp. Problem)
    HTTP_LOCAL=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$SMOKE_URL_FALLBACK" || echo "000")
    if [ "$HTTP_LOCAL" = "200" ]; then
        say "${C_Y}[9/9] WARN: Public-URL nicht 200, aber localhost OK - Nginx/SSL pruefen${C_N}"
    else
        rollback "Smoke-Test fehlgeschlagen (public: $HTTP_CODE, local: $HTTP_LOCAL)"
    fi
fi

# ----------------------------------------------------------------------
# ABSCHLUSS
# ----------------------------------------------------------------------
DURATION=$SECONDS
say
say "${C_C}=== DEPLOY ERFOLGREICH ===${C_N}"
say "Dauer:  ${DURATION}s"
say "Von:    ${PRE_DEPLOY_SHORT}"
say "Nach:   ${TARGET_SHORT}"
say "Log:    ${DEPLOY_LOG}"
say
