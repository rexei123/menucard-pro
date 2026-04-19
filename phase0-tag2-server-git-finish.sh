#!/bin/bash
# ============================================================================
# PHASE 0 TAG 1 SCHRITT 2 — FORTSETZUNG (Schritt 8+9)
# Nach SIGPIPE-Abbruch des Haupt-Scripts: nur noch mixed-reset + hard-reset.
# Vorbedingung: .git/, origin + Fetch sind schon vorhanden.
# ============================================================================
set -euo pipefail

APP_DIR="/var/www/menucard-pro"
C_C=$'\e[36m'; C_G=$'\e[32m'; C_Y=$'\e[33m'; C_R=$'\e[31m'; C_N=$'\e[0m'

cd "$APP_DIR"

echo
echo "${C_C}=== Fortsetzung: Schritt 8 + 9 ===${C_N}"
echo

# Defensive: Fetch erneuern, falls noetig
echo "${C_Y}[pre] Fetch origin/main ...${C_N}"
git fetch origin main

# ----------------------------------------------------------------------
# 8. HEAD auf origin/main (mixed) + Preview
# ----------------------------------------------------------------------
echo
echo "${C_Y}[8/9] HEAD auf origin/main ausrichten (Preview) ...${C_N}"
git reset origin/main

echo
echo "  Abweichungen Working-Tree vs. origin/main:"
STATUS=$(git status --short)
if [ -z "$STATUS" ]; then
    echo "    (keine - Server bereits identisch mit GitHub)"
else
    # sed -n '1,40p' liest bis EOF -> kein SIGPIPE auf echo
    echo "$STATUS" | sed -n '1,40p' | sed 's/^/    /'
    TOTAL=$(printf '%s\n' "$STATUS" | wc -l)
    if [ "$TOTAL" -gt 40 ]; then
        echo "    ... und $((TOTAL - 40)) weitere Zeilen (gesamt $TOTAL)"
    fi
fi
echo
echo "Hard reset: ${C_Y}getrackte${C_N} Dateien auf GitHub-Stand zurueck."
echo "Untracked (.env, node_modules, .next, Backups) bleiben unberuehrt."
read -p "Fortfahren? (y/n) " ANS
if [ "$ANS" != "y" ]; then
    echo "Abgebrochen. Repo bleibt im mixed-Zustand (HEAD=origin/main, Working Tree unveraendert)."
    exit 0
fi

# ----------------------------------------------------------------------
# 9. Hard reset + Verifikation
# ----------------------------------------------------------------------
echo
echo "${C_Y}[9/9] git reset --hard origin/main ...${C_N}"
git reset --hard origin/main
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
    echo "    ${C_Y}WARN${C_N} node_modules fehlt - 'npm ci' vor naechstem Build noetig"
fi
echo "    HEAD:     $(git log -1 --oneline)"
echo "    Branch:   $(git branch --show-current)"
echo "    Upstream: $(git rev-parse --abbrev-ref '@{u}' 2>/dev/null || echo 'NEIN')"

echo
echo "${C_C}=== FERTIG ===${C_N}"
echo "Naechster Schritt (Phase 0 Tag 1 Schritt 3): Git-basiertes Deploy-Script."
echo
