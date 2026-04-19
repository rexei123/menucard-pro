#!/bin/bash
# ============================================================================
# PHASE 0 TAG 1 SCHRITT 2 — Server zum Git-Repo machen (Variante A: in-place)
# ============================================================================
# Was dieses Script tut:
#  1. Backup des aktuellen Server-Code-Stands
#  2. SSH Deploy Key fuer GitHub erzeugen (Read-only)
#  3. Public Key anzeigen + auf Benutzer-Bestaetigung warten
#  4. SSH-Verbindung zu GitHub testen
#  5. /var/www/menucard-pro als Git-Repo initialisieren
#  6. Remote 'origin' konfigurieren (SSH via github-menucard-Alias)
#  7. Fetch origin/main
#  8. HEAD + Index auf origin/main setzen (mixed), Abweichungen zeigen
#  9. Nach Bestaetigung: git reset --hard origin/main + Verifikation
#
# Was NICHT passiert:
#  - Kein npm run build (kommt in Schritt 3)
#  - Kein pm2 restart (kommt in Schritt 3)
#  - .env, node_modules, .next werden nicht angefasst (sind gitignored)
# ============================================================================
set -euo pipefail

APP_DIR="/var/www/menucard-pro"
REPO_SLUG="rexei123/menucard-pro"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519_github_menucard"
SSH_HOST_ALIAS="github-menucard"
REMOTE_URL="git@${SSH_HOST_ALIAS}:${REPO_SLUG}.git"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="/var/backups/menucard-pro-code-${TS}"

C_C=$'\e[36m'; C_G=$'\e[32m'; C_Y=$'\e[33m'; C_R=$'\e[31m'; C_N=$'\e[0m'

echo
echo "${C_C}=== PHASE 0 TAG 1 SCHRITT 2 — SERVER -> GIT-REPO ===${C_N}"
echo

# ----------------------------------------------------------------------
# 1. CODE-BACKUP
# ----------------------------------------------------------------------
echo "${C_Y}[1/9] Backup Server-Code nach ${BACKUP_DIR} ...${C_N}"
mkdir -p "$(dirname "$BACKUP_DIR")"
rsync -a \
    --exclude 'node_modules' \
    --exclude '.next' \
    --exclude '.git' \
    "$APP_DIR/" "$BACKUP_DIR/"
echo "  Groesse: $(du -sh "$BACKUP_DIR" | cut -f1)"
echo "${C_G}[1/9] OK${C_N}"

# ----------------------------------------------------------------------
# 2. SSH DEPLOY KEY
# ----------------------------------------------------------------------
echo
echo "${C_Y}[2/9] SSH Deploy Key vorbereiten ...${C_N}"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
if [ ! -f "$SSH_KEY_PATH" ]; then
    ssh-keygen -t ed25519 -N '' -C 'menucard-server-deploy' -f "$SSH_KEY_PATH"
    echo "  Neuer Key: $SSH_KEY_PATH"
else
    echo "  Key existiert bereits: $SSH_KEY_PATH"
fi
chmod 600 "$SSH_KEY_PATH"

SSH_CFG="$HOME/.ssh/config"
touch "$SSH_CFG" && chmod 600 "$SSH_CFG"
if ! grep -q "^Host ${SSH_HOST_ALIAS}\$" "$SSH_CFG"; then
    cat >> "$SSH_CFG" <<EOF

Host ${SSH_HOST_ALIAS}
    HostName github.com
    User git
    IdentityFile ${SSH_KEY_PATH}
    IdentitiesOnly yes
EOF
    echo "  SSH-Config-Eintrag hinzugefuegt."
else
    echo "  SSH-Config bereits konfiguriert."
fi
echo "${C_G}[2/9] OK${C_N}"

# ----------------------------------------------------------------------
# 3. PUBLIC KEY ZEIGEN + WARTEN
# ----------------------------------------------------------------------
echo
echo "${C_Y}[3/9] Public Key fuer GitHub Deploy Key:${C_N}"
echo "${C_C}---------------------------------------------------------------${C_N}"
cat "${SSH_KEY_PATH}.pub"
echo "${C_C}---------------------------------------------------------------${C_N}"
echo
echo "JETZT in GitHub eintragen:"
echo "  ${C_C}https://github.com/${REPO_SLUG}/settings/keys/new${C_N}"
echo
echo "  Title:              Server Hetzner CX22"
echo "  Key:                (komplette Zeile oben kopieren)"
echo "  Allow write access: ${C_R}NICHT${C_N} aktivieren (Read-only reicht)"
echo
read -p "Nach dem Hinzufuegen ENTER druecken ... " _
echo "${C_G}[3/9] OK${C_N}"

# ----------------------------------------------------------------------
# 4. SSH-VERBINDUNG ZU GITHUB TESTEN
# ----------------------------------------------------------------------
echo
echo "${C_Y}[4/9] SSH-Verbindung zu GitHub pruefen ...${C_N}"
set +e
SSH_OUT=$(ssh -T -o StrictHostKeyChecking=accept-new "$SSH_HOST_ALIAS" 2>&1)
SSH_EXIT=$?
set -e
echo "  $SSH_OUT"
# GitHub verweigert Shell (Exit 1 ist Normalfall), akzeptiert Auth via Schluessel
if ! echo "$SSH_OUT" | grep -q "successfully authenticated"; then
    echo "${C_R}  Authentifizierung fehlgeschlagen. Deploy Key korrekt eingetragen?${C_N}"
    echo "  Exit-Code war: $SSH_EXIT"
    exit 1
fi
echo "${C_G}[4/9] OK${C_N}"

# ----------------------------------------------------------------------
# 5. GIT-REPO INITIALISIEREN
# ----------------------------------------------------------------------
echo
echo "${C_Y}[5/9] Git-Repo in ${APP_DIR} ...${C_N}"
cd "$APP_DIR"
if [ ! -d .git ]; then
    git init -b main
    echo "  git init erfolgt"
else
    echo "  .git/ existiert bereits"
fi
# Git-Identitaet setzen (fuer Commits auf diesem Server, falls mal noetig)
git config user.email "server-deploy@hotel-sonnblick.at"
git config user.name "Server Deploy"
echo "${C_G}[5/9] OK${C_N}"

# ----------------------------------------------------------------------
# 6. REMOTE EINRICHTEN
# ----------------------------------------------------------------------
echo
echo "${C_Y}[6/9] Remote 'origin' ...${C_N}"
if git remote | grep -q '^origin$'; then
    git remote set-url origin "$REMOTE_URL"
    echo "  origin-URL aktualisiert"
else
    git remote add origin "$REMOTE_URL"
    echo "  origin hinzugefuegt"
fi
git remote -v
echo "${C_G}[6/9] OK${C_N}"

# ----------------------------------------------------------------------
# 7. FETCH
# ----------------------------------------------------------------------
echo
echo "${C_Y}[7/9] Fetch origin/main ...${C_N}"
git fetch origin main
echo
echo "  Letzte 5 Commits auf origin/main:"
# -n 5 statt Pipe zu head, um SIGPIPE mit 'set -o pipefail' zu vermeiden
git log --oneline -n 5 origin/main | sed 's/^/    /'
echo "${C_G}[7/9] OK${C_N}"

# ----------------------------------------------------------------------
# 8. HEAD + INDEX AUF ORIGIN/MAIN (MIXED) + PREVIEW + BESTAETIGUNG
# ----------------------------------------------------------------------
echo
echo "${C_Y}[8/9] HEAD auf origin/main ausrichten (Preview) ...${C_N}"
# --mixed (Default): HEAD + Index auf origin/main, Working Tree unberuehrt.
# Gitignore aus origin/main greift ab hier -> .env & Co. erscheinen NICHT als Aenderung.
git reset origin/main

echo
echo "  Abweichungen Working-Tree vs. origin/main:"
STATUS=$(git status --short)
if [ -z "$STATUS" ]; then
    echo "  (keine - Server bereits identisch mit GitHub)"
else
    # sed -n '1,40p' liest bis EOF -> kein SIGPIPE auf echo
    echo "$STATUS" | sed -n '1,40p' | sed 's/^/    /'
    TOTAL=$(printf '%s\n' "$STATUS" | wc -l)
    if [ "$TOTAL" -gt 40 ]; then
        echo "    ... und $((TOTAL - 40)) weitere Zeilen (gesamt $TOTAL)"
    fi
fi
echo
echo "Mit 'git reset --hard origin/main' werden ${C_Y}getrackte${C_N} Dateien auf"
echo "den GitHub-Stand zurueckgesetzt. ${C_G}Untracked${C_N} (.env, node_modules, .next,"
echo "alle Backups in .env.*, .bak, .local-archive) bleiben unberuehrt."
echo
read -p "Fortfahren? (y/n) " ANS
if [ "$ANS" != "y" ]; then
    echo "Abgebrochen. Repo ist initialisiert, aber nicht hard-synced."
    echo "Stand: HEAD zeigt auf origin/main (mixed), Working Tree unveraendert."
    exit 0
fi
echo "${C_G}[8/9] OK${C_N}"

# ----------------------------------------------------------------------
# 9. HARD RESET + VERIFIKATION
# ----------------------------------------------------------------------
echo
echo "${C_Y}[9/9] git reset --hard origin/main + Verifikation ...${C_N}"
git reset --hard origin/main

# Tracking-Branch konfigurieren
git branch --set-upstream-to=origin/main main 2>/dev/null || true

echo
echo "  Verifikation:"
if [ -f .env ]; then
    echo "    ${C_G}OK${C_N}   .env vorhanden ($(stat -c%s .env) Bytes)"
else
    echo "    ${C_R}FEHLER${C_N} .env fehlt!"
    exit 1
fi
if [ -d node_modules ]; then
    echo "    ${C_G}OK${C_N}   node_modules vorhanden"
else
    echo "    ${C_Y}WARN${C_N} node_modules fehlt - 'npm ci' vor Build noetig"
fi
echo "    HEAD:     $(git log -1 --oneline)"
echo "    Branch:   $(git branch --show-current)"
echo "    Upstream: $(git rev-parse --abbrev-ref '@{u}' 2>/dev/null || echo 'NICHT KONFIGURIERT')"
echo "${C_G}[9/9] OK${C_N}"

# ----------------------------------------------------------------------
# ABSCHLUSS
# ----------------------------------------------------------------------
echo
echo "${C_C}=== FERTIG ===${C_N}"
echo
echo "Server-Code in ${APP_DIR} ist jetzt ein Git-Repo, synced mit origin/main."
echo "Backup des vorigen Server-Stands: ${BACKUP_DIR}"
echo
echo "Naechster Schritt (Phase 0 Tag 1 Schritt 3):"
echo "  Git-basiertes Deploy-Script (git pull -> npm ci -> build -> pm2 restart)"
echo
echo "Rollback bei Bedarf:"
echo "  rsync -a ${BACKUP_DIR}/ ${APP_DIR}/"
echo "  cd ${APP_DIR} && pm2 restart menucard-pro"
echo
