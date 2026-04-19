#!/bin/bash
# ============================================================================
# MenuCard Pro — Staging-Deploy-Script
# Ort auf dem Server: /var/www/menucard-pro-staging/scripts/deploy-staging.sh
# Aufruf (Server):    bash /var/www/menucard-pro-staging/scripts/deploy-staging.sh [branch] [--yes|--dry-run|--no-build]
# Aufruf (lokal):     ssh root@178.104.138.177 "bash /var/www/menucard-pro-staging/scripts/deploy-staging.sh feature/xxx --yes"
# ============================================================================
# Zweck:
#   Deployed einen beliebigen Branch nach Staging. Bewusst OHNE Rollback bei
#   Smoke-Fail — ein kaputtes Staging ist das Signal fuer den Test-Gate und
#   soll nicht verschleiert werden.
#
# Unterschiede zu production deploy.sh:
#   - APP_DIR=/var/www/menucard-pro-staging
#   - APP_NAME=menucard-pro-staging
#   - Ziel-Port 3001 statt 3000
#   - SMOKE_URL=http://127.0.0.1:3001/ (kein public, kein SSL)
#   - Kein DB-Backup (Staging wird via seed-staging-from-prod.sh regeneriert)
#   - Optionaler Branch-Parameter (Default: main)
#   - Rollback NUR bei Build-Fail/Restart-Fail, NICHT bei Smoke-Fail
# ============================================================================
set -euo pipefail

# ----------------------------------------------------------------------
# Konfiguration
# ----------------------------------------------------------------------
APP_DIR="/var/www/menucard-pro-staging"
APP_NAME="menucard-pro-staging"
SMOKE_URL="http://127.0.0.1:3001/"
LOCK_FILE="/var/run/menucard-deploy-staging.lock"
DEPLOY_LOG="/var/log/menucard-deploy-staging.log"

C_C=$'\e[36m'; C_G=$'\e[32m'; C_Y=$'\e[33m'; C_R=$'\e[31m'; C_N=$'\e[0m'

# ----------------------------------------------------------------------
# Flags + Branch
# ----------------------------------------------------------------------
BRANCH="main"
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
        --*)
            echo "${C_R}Unbekanntes Flag: $arg${C_N}" >&2
            exit 2
            ;;
        *)
            BRANCH="$arg"
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
        say "${C_R}Staging-Deploy laeuft bereits (PID $OTHER_PID). Abbruch.${C_N}"
        exit 1
    fi
    say "${C_Y}Stale Lock gefunden (PID $OTHER_PID nicht aktiv) - raeume auf.${C_N}"
    rm -f "$LOCK_FILE"
fi
echo "$$" > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

say
say "${C_C}=== MenuCard Pro Staging-Deploy ===${C_N}"
say "Start:   $(date '+%Y-%m-%d %H:%M:%S')"
say "Modus:   $([ $DRY_RUN -eq 1 ] && echo 'DRY-RUN' || echo 'LIVE')"
say "Branch:  ${BRANCH}"
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
# 3. PRE-DEPLOY HEAD MERKEN
# ----------------------------------------------------------------------
PRE_DEPLOY_HEAD=$(git rev-parse HEAD)
PRE_DEPLOY_SHORT=$(git rev-parse --short HEAD)
say "${C_Y}[1/8] Pre-Deploy HEAD: ${PRE_DEPLOY_SHORT}${C_N}"

# ----------------------------------------------------------------------
# 4. FETCH
# ----------------------------------------------------------------------
say "${C_Y}[2/8] git fetch origin ${BRANCH} ...${C_N}"
if ! git fetch origin "$BRANCH" 2>&1 | tee -a "$DEPLOY_LOG"; then
    say "${C_R}Fetch fehlgeschlagen. Abbruch.${C_N}"
    exit 1
fi

TARGET_HEAD=$(git rev-parse "origin/${BRANCH}")
TARGET_SHORT=$(git rev-parse --short "origin/${BRANCH}")

# ----------------------------------------------------------------------
# 5. DIFF-PREVIEW
# ----------------------------------------------------------------------
say
if [ "$PRE_DEPLOY_HEAD" = "$TARGET_HEAD" ]; then
    say "${C_Y}HEAD bereits auf origin/${BRANCH} (${TARGET_SHORT}). Re-Deploy.${C_N}"
else
    say "${C_C}--- Neue Commits ---${C_N}"
    git log --oneline -n 20 "${PRE_DEPLOY_HEAD}..${TARGET_HEAD}" | sed 's/^/  /'
fi

CHANGED_FILES=$(git diff --name-only "${PRE_DEPLOY_HEAD}..${TARGET_HEAD}" 2>/dev/null || echo "")
NEEDS_NPM_CI=0
NEEDS_PRISMA=0
if echo "$CHANGED_FILES" | grep -qE '^(package\.json|package-lock\.json)$'; then
    NEEDS_NPM_CI=1
fi
if echo "$CHANGED_FILES" | grep -qE '^prisma/schema\.prisma$'; then
    NEEDS_PRISMA=1
fi

say
say "${C_C}--- Deploy-Plan ---${C_N}"
say "  Von:       ${PRE_DEPLOY_SHORT}"
say "  Nach:      ${TARGET_SHORT} (origin/${BRANCH})"
say "  npm ci:    $([ $NEEDS_NPM_CI -eq 1 ] && echo 'JA' || echo 'nein')"
say "  prisma:    $([ $NEEDS_PRISMA -eq 1 ] && echo 'JA (db push)' || echo 'nein')"
say "  build:     $([ $NO_BUILD -eq 1 ] && echo 'uebersprungen' || echo 'JA')"
say "  restart:   pm2 restart $APP_NAME"
say "  smoke:     curl $SMOKE_URL (nicht-blockierend)"
say

# ----------------------------------------------------------------------
# 6. DRY-RUN / BESTAETIGUNG
# ----------------------------------------------------------------------
if [ $DRY_RUN -eq 1 ]; then
    say "${C_C}DRY-RUN beendet - keine Aenderungen.${C_N}"
    exit 0
fi

if [ $AUTO_YES -ne 1 ]; then
    read -p "Staging-Deploy starten? (y/n) " ANS
    if [ "$ANS" != "y" ]; then
        say "${C_Y}Abgebrochen.${C_N}"
        exit 0
    fi
fi

# ----------------------------------------------------------------------
# Rollback-Funktion (nur bei Build-/Restart-Fail, NICHT bei Smoke-Fail)
# ----------------------------------------------------------------------
rollback() {
    local reason="$1"
    say
    say "${C_R}=== STAGING-ROLLBACK ===${C_N}"
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
# 7. HARD RESET
# ----------------------------------------------------------------------
say
say "${C_Y}[3/8] git reset --hard origin/${BRANCH} ...${C_N}"
if ! git reset --hard "$TARGET_HEAD" 2>&1 | tee -a "$DEPLOY_LOG"; then
    rollback "git reset --hard fehlgeschlagen"
fi
say "${C_G}[3/8] OK - HEAD jetzt ${TARGET_SHORT}${C_N}"

# ----------------------------------------------------------------------
# 8. NPM CI (conditional)
# ----------------------------------------------------------------------
say
if [ $NEEDS_NPM_CI -eq 1 ]; then
    say "${C_Y}[4/8] npm ci ...${C_N}"
    if ! npm ci 2>&1 | tee -a "$DEPLOY_LOG"; then
        rollback "npm ci fehlgeschlagen"
    fi
    say "${C_G}[4/8] OK${C_N}"
else
    say "${C_Y}[4/8] npm ci uebersprungen${C_N}"
fi

# ----------------------------------------------------------------------
# 9. PRISMA DB PUSH (conditional)
# ----------------------------------------------------------------------
say
if [ $NEEDS_PRISMA -eq 1 ]; then
    say "${C_Y}[5/8] prisma db push ...${C_N}"
    if ! npx prisma db push --skip-generate 2>&1 | tee -a "$DEPLOY_LOG"; then
        rollback "prisma db push fehlgeschlagen"
    fi
    if ! npx prisma generate 2>&1 | tee -a "$DEPLOY_LOG"; then
        rollback "prisma generate fehlgeschlagen"
    fi
    say "${C_G}[5/8] OK${C_N}"
else
    say "${C_Y}[5/8] prisma db push uebersprungen${C_N}"
fi

# ----------------------------------------------------------------------
# 10. BUILD
# ----------------------------------------------------------------------
say
if [ $NO_BUILD -eq 1 ]; then
    say "${C_Y}[6/8] npm run build uebersprungen (--no-build)${C_N}"
else
    say "${C_Y}[6/8] npm run build ...${C_N}"
    if ! npm run build 2>&1 | tee -a "$DEPLOY_LOG"; then
        rollback "npm run build fehlgeschlagen"
    fi
    say "${C_G}[6/8] OK${C_N}"
fi

# ----------------------------------------------------------------------
# 11. PM2 RESTART
# ----------------------------------------------------------------------
say
say "${C_Y}[7/8] pm2 restart $APP_NAME ...${C_N}"
if ! pm2 restart "$APP_NAME" 2>&1 | tee -a "$DEPLOY_LOG"; then
    rollback "pm2 restart fehlgeschlagen"
fi
say "${C_G}[7/8] OK${C_N}"

# ----------------------------------------------------------------------
# 12. SMOKE-WAIT (nicht-blockierend: kein Rollback bei Fail)
# ----------------------------------------------------------------------
say
say "${C_Y}[8/8] Smoke-Wait (localhost:3001) ...${C_N}"

SMOKE_OK=0
HTTP_CODE="000"
for i in 1 2 3 4 5 6 7 8 9 10; do
    HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$SMOKE_URL" || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        SMOKE_OK=1
        break
    fi
    sleep 2
done

if [ $SMOKE_OK -eq 1 ]; then
    say "${C_G}[8/8] OK - HTTP 200 von ${SMOKE_URL}${C_N}"
    EXIT_CODE=0
else
    say "${C_R}[8/8] WARN: Smoke-Wait erreichte kein HTTP 200 (letzter Code: $HTTP_CODE)${C_N}"
    say "${C_Y}       KEIN Rollback - der Test-Gate (ship.ps1) wird das aufdecken.${C_N}"
    EXIT_CODE=3
fi

# ----------------------------------------------------------------------
# ABSCHLUSS
# ----------------------------------------------------------------------
DURATION=$SECONDS
say
say "${C_C}=== STAGING-DEPLOY BEENDET ===${C_N}"
say "Dauer:  ${DURATION}s"
say "Von:    ${PRE_DEPLOY_SHORT}"
say "Nach:   ${TARGET_SHORT}"
say "Smoke:  $([ $SMOKE_OK -eq 1 ] && echo 'OK' || echo "WARN ($HTTP_CODE)")"
say "Exit:   ${EXIT_CODE}"
say "Log:    ${DEPLOY_LOG}"
say

exit $EXIT_CODE
