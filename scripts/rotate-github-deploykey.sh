#!/bin/bash
# ============================================================================
# MenuCard Pro — GitHub Deploy-Key Rotation
# ============================================================================
# Rotiert den SSH-Key, mit dem der Server vom GitHub-Repo pullt:
#   /root/.ssh/id_ed25519_github_menucard (+.pub)
#
# Flow (interaktiv):
#   1. Neues ed25519-Keypair in /root/.ssh/id_ed25519_github_menucard.new
#   2. Public-Key wird angezeigt - User haengt ihn in GitHub ein
#      (Repo Settings > Deploy keys > Add deploy key, Write-Access NICHT noetig)
#   3. User bestaetigt mit Enter
#   4. SSH-Test zu github.com mit neuem Key
#   5. Backup alter Key, Swap neu->current
#   6. git fetch als Verify
#   7. User entfernt alten Key in GitHub (Anweisung am Ende)
#
# Bei jedem Fehler: Rollback (altes Keypair zurueckkopieren)
#
# Aufruf:
#   bash scripts/rotate-github-deploykey.sh --dry-run
#   bash scripts/rotate-github-deploykey.sh --yes
# ============================================================================
set -Eeuo pipefail

KEY_DIR="/root/.ssh"
KEY_NAME="id_ed25519_github_menucard"
KEY_CUR="$KEY_DIR/$KEY_NAME"
KEY_NEW="$KEY_DIR/${KEY_NAME}.new"
SSH_HOST_ALIAS="github-menucard"
REPO_DIR="/var/www/menucard-pro"
BACKUP_BASE="/var/backups/menucard-pro"
LOG_FILE="/var/log/menucard-github-key-rotation.log"

TS=$(date '+%Y%m%d-%H%M%S')
BACKUP_DIR="${BACKUP_BASE}/github-deploykey-pre-rotation-${TS}"

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
say "${C_C}=== GitHub Deploy-Key Rotation ===${C_N}"
say "Start: $(date '+%F %T')  Modus: $([ $DRY_RUN -eq 1 ] && echo DRY-RUN || echo LIVE)"
say

# ---- Preflight -------------------------------------------------------------
[ -f "$KEY_CUR" ]     || { say "${C_R}FAIL: aktueller Key $KEY_CUR fehlt${C_N}"; exit 1; }
[ -f "$KEY_CUR.pub" ] || { say "${C_R}FAIL: aktueller Pubkey $KEY_CUR.pub fehlt${C_N}"; exit 1; }
command -v ssh-keygen >/dev/null 2>&1 || { say "${C_R}FAIL: ssh-keygen nicht gefunden${C_N}"; exit 1; }

# ---- 1. Discovery ----------------------------------------------------------
say "${C_Y}[1/6] Discovery${C_N}"
say "  Key-Pfad:   $KEY_CUR"
say "  Host-Alias: $SSH_HOST_ALIAS (siehe ~/.ssh/config)"
say "  Repo:       $REPO_DIR"
OLD_FP=$(ssh-keygen -lf "$KEY_CUR.pub" | awk '{print $2}')
say "  Old Fingerprint: $OLD_FP"

# ---- Dry-Run ---------------------------------------------------------------
if [ $DRY_RUN -eq 1 ]; then
    say
    say "${C_C}[DRY-RUN] Rotation wuerde:${C_N}"
    say "  - Backup alter Key nach $BACKUP_DIR/"
    say "  - ssh-keygen -t ed25519 -N '' -f $KEY_NEW"
    say "  - Pubkey anzeigen, User fuegt in GitHub ein"
    say "  - ssh -i <new> -T git@github.com (Auth-Test)"
    say "  - alter Key -> Backup, neuer Key -> $KEY_CUR"
    say "  - git -C $REPO_DIR fetch (Verify)"
    say
    say "${C_C}DRY-RUN Ende - keine Aenderungen.${C_N}"
    exit 0
fi

if [ $AUTO_YES -ne 1 ]; then
    echo
    read -p "Rotation jetzt ausfuehren? (y/n) " ANS
    [ "$ANS" = "y" ] || { say "${C_Y}Abbruch.${C_N}"; exit 0; }
fi

# ---- 2. Backup + Key erzeugen ---------------------------------------------
say
say "${C_Y}[2/6] Backup alter Key${C_N}"
mkdir -p "$BACKUP_DIR"; chmod 700 "$BACKUP_DIR"
cp -a "$KEY_CUR"     "$BACKUP_DIR/"
cp -a "$KEY_CUR.pub" "$BACKUP_DIR/"
chmod 600 "$BACKUP_DIR"/*
say "${C_G}  Backup: $BACKUP_DIR${C_N}"

say
say "${C_Y}[3/6] Neues ed25519-Keypair erzeugen${C_N}"
# Alte .new-Reste wegraeumen
rm -f "$KEY_NEW" "$KEY_NEW.pub"
ssh-keygen -t ed25519 -N "" -f "$KEY_NEW" -C "menucard-deploy-rotated-$TS" >/dev/null
chmod 600 "$KEY_NEW"
chmod 644 "$KEY_NEW.pub"
NEW_FP=$(ssh-keygen -lf "$KEY_NEW.pub" | awk '{print $2}')
say "${C_G}  Neu: $KEY_NEW${C_N}"
say "  Fingerprint: $NEW_FP"
say

# Rollback-Helfer
rollback() {
    say
    say "${C_R}=== ROLLBACK ===${C_N}"
    rm -f "$KEY_NEW" "$KEY_NEW.pub"
    if [ -f "$BACKUP_DIR/$KEY_NAME" ]; then
        cp -a "$BACKUP_DIR/$KEY_NAME"     "$KEY_CUR"
        cp -a "$BACKUP_DIR/$KEY_NAME.pub" "$KEY_CUR.pub"
        chmod 600 "$KEY_CUR"; chmod 644 "$KEY_CUR.pub"
    fi
    say "${C_Y}Rollback durchgefuehrt. Backup: $BACKUP_DIR${C_N}"
    exit 1
}
trap rollback ERR

# ---- 3. Pubkey anzeigen + Pause -------------------------------------------
say "${C_Y}[4/6] Public-Key fuer GitHub${C_N}"
say "${C_C}---- COPY START ----${C_N}"
cat "$KEY_NEW.pub"
say "${C_C}---- COPY END ------${C_N}"
say
say "Bitte jetzt:"
say "  1. GitHub oeffnen: https://github.com/rexei123/menucard-pro/settings/keys"
say "  2. 'Add deploy key' -> Title: 'menucard-deploy-${TS}'"
say "  3. Key oben hineinkopieren (komplette Zeile)"
say "  4. 'Allow write access' NICHT aktivieren"
say "  5. Speichern"
say
read -p "Public-Key in GitHub eingetragen? Enter zum Testen, Ctrl-C zum Abbruch..."

# ---- 4. SSH-Test mit neuem Key -------------------------------------------
say
say "${C_Y}[5/6] SSH-Test gegen github.com mit neuem Key${C_N}"
# github.com gibt bei erfolgreichem Auth Exit 1 zurueck ("Hi USER/REPO! ...
# but does not provide shell access"), darum Output pruefen statt Exit.
SSH_OUT=$(ssh -i "$KEY_NEW" \
             -o IdentitiesOnly=yes \
             -o StrictHostKeyChecking=accept-new \
             -o BatchMode=yes \
             -T git@github.com 2>&1 || true)
say "  Antwort: $SSH_OUT"
if ! echo "$SSH_OUT" | grep -qi "successfully authenticated"; then
    say "${C_R}FAIL: GitHub hat den neuen Key nicht akzeptiert.${C_N}"
    say "  -> Pubkey in GitHub korrekt gespeichert? Richtiges Repo?"
    false
fi
say "${C_G}  SSH-Auth OK${C_N}"

# ---- 5. Swap + Repo-Pull-Verify -------------------------------------------
say
say "${C_Y}[6/6] Swap + git fetch${C_N}"
mv "$KEY_NEW"     "$KEY_CUR"
mv "$KEY_NEW.pub" "$KEY_CUR.pub"
chmod 600 "$KEY_CUR"; chmod 644 "$KEY_CUR.pub"

# git fetch nutzt ~/.ssh/config Alias github-menucard -> neuer Key greift
git -C "$REPO_DIR" fetch origin main >> "$LOG_FILE" 2>&1
say "${C_G}  git fetch OK${C_N}"

trap - ERR

# ---- Abschluss -------------------------------------------------------------
say
say "${C_C}=== ROTATION ERFOLGREICH ===${C_N}"
say "Neuer Key:        $KEY_CUR"
say "Alter Fingerprint: $OLD_FP"
say "Neuer Fingerprint: $NEW_FP"
say "Backup:            $BACKUP_DIR"
say
say "${C_Y}Wichtig - naechster Schritt in GitHub:${C_N}"
say "  https://github.com/rexei123/menucard-pro/settings/keys"
say "  ALTEN Deploy-Key (Fingerprint $OLD_FP) jetzt LOESCHEN."
say "  Erst dann ist die Rotation vollstaendig."
say
log "GitHub-Deploy-Key rotiert (old=$OLD_FP new=$NEW_FP backup=$BACKUP_DIR)"
