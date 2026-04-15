#!/usr/bin/env bash
# Phase 1 Security-Fix: Token aus Inventar und Git-Remote entfernen
set -u

APP_DIR="/var/www/menucard-pro"
DATE="20260414"
REPORTS=(
  "/tmp/INVENTAR-${DATE}.md"
  "$APP_DIR/INVENTAR-${DATE}.md"
)

echo "=== SECURITY-FIX: GitHub-Token aus allen Artefakten entfernen ==="
echo ""

# --------------------------------------------
# 1. Git-Remote-URL säubern
# --------------------------------------------
cd "$APP_DIR"
OLD_URL=$(git remote get-url origin)
# Maskierung für Output
MASKED=$(echo "$OLD_URL" | sed -E 's|([A-Za-z0-9_-]+):[^@]+@|\1:***@|')
echo "[1/4] Git-Remote prüfen"
echo "    Alte URL (maskiert): $MASKED"

NEW_URL=$(echo "$OLD_URL" | sed -E 's|https://[^@]+@|https://|')
echo "    Neue URL:            $NEW_URL"

git remote set-url origin "$NEW_URL"
echo "    ✓ Remote-URL umgestellt"

# --------------------------------------------
# 2. Token aus allen INVENTAR-Reports entfernen
# --------------------------------------------
echo ""
echo "[2/4] INVENTAR-Dateien bereinigen"
for f in "${REPORTS[@]}"; do
  if [ -f "$f" ]; then
    # Backup
    cp "$f" "${f}.pre-security"
    # Token-Pattern entfernen: https://USER:TOKEN@github.com → https://github.com
    sed -i -E 's|https://[A-Za-z0-9_-]+:[A-Za-z0-9_-]+@github\.com|https://github.com|g' "$f"
    echo "    ✓ $f bereinigt (Backup: ${f}.pre-security)"
  else
    echo "    - $f nicht vorhanden, übersprungen"
  fi
done

# --------------------------------------------
# 3. Auch andere Dateien im Projekt checken (falls Token irgendwo geleakt)
# --------------------------------------------
echo ""
echo "[3/4] Projektweite Token-Suche"
cd "$APP_DIR"
LEAKS=$(grep -r "ghp_" --include="*.md" --include="*.json" --include="*.txt" --include="*.sh" --include="*.log" . 2>/dev/null | grep -v node_modules | grep -v .next | grep -v .git)
if [ -n "$LEAKS" ]; then
  echo "    ⚠ WEITERE TREFFER:"
  echo "$LEAKS" | head -20 | sed 's/^/    /'
else
  echo "    ✓ Keine weiteren 'ghp_'-Treffer im Projekt"
fi

# Auch im /root/backups-Verzeichnis
BACKUP_LEAKS=$(grep -r "ghp_" /root/backups-${DATE}/ 2>/dev/null)
if [ -n "$BACKUP_LEAKS" ]; then
  echo "    ⚠ IM BACKUP-VERZEICHNIS:"
  echo "$BACKUP_LEAKS" | head -5 | sed 's/^/    /'
else
  echo "    ✓ Keine Treffer in /root/backups-${DATE}/"
fi

# Auch in /tmp
TMP_LEAKS=$(grep -r "ghp_" /tmp/ 2>/dev/null | grep -v Binary)
if [ -n "$TMP_LEAKS" ]; then
  echo "    ⚠ IN /tmp (LOG-FILES):"
  echo "$TMP_LEAKS" | head -10 | sed 's/^/    /'
fi

# --------------------------------------------
# 4. Nachkontrolle
# --------------------------------------------
echo ""
echo "[4/4] Nachkontrolle"
cd "$APP_DIR"
echo "    Remote-URLs jetzt:"
git remote -v | sed 's/^/      /'
echo ""
echo "    Inventar-Dateien auf Token prüfen:"
for f in "${REPORTS[@]}"; do
  if [ -f "$f" ]; then
    C=$(grep -c 'ghp_' "$f" 2>/dev/null || echo 0)
    if [ "$C" = "0" ]; then
      echo "      ✓ $f: sauber"
    else
      echo "      ✗ $f: $C Treffer — MANUELLE PRÜFUNG!"
    fi
  fi
done

echo ""
echo "==============================================================="
echo "  AUTONOME FIXES ERLEDIGT"
echo "==============================================================="
echo ""
echo "  ⚠ NOCH ZU TUN (nur Sie können das):"
echo ""
echo "  1. GitHub öffnen → Settings → Developer settings → Personal"
echo "     access tokens → das geleakte Token REVOKEN (widerrufen)."
echo ""
echo "  2. Neues Token erstellen ODER SSH-Key einrichten."
echo ""
echo "  3. Für zukünftige Pushes eine der drei Optionen:"
echo "     a) SSH-Key (empfohlen, einmaliger Aufwand)"
echo "     b) gh auth login (speichert Token sicher)"
echo "     c) git config credential.helper store (weniger sicher)"
echo ""
echo "  4. Alte .pre-security Backups können nach Verifikation gelöscht"
echo "     werden — sie enthalten noch den alten Token."
echo ""
