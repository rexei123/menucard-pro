#!/usr/bin/env bash
# Schritt 2a: Analog-Tab ("PDF-Layout") deployen
# Läuft auf dem Server in /var/www/menucard-pro
set -e
cd /var/www/menucard-pro

echo "==> [1/6] Neue Komponente einspielen"
cp /tmp/pdf-layout-tab.tsx src/components/admin/pdf-layout-tab.tsx
ls -la src/components/admin/pdf-layout-tab.tsx

echo ""
echo "==> [2/6] Patches auf design-editor.tsx anwenden"
python3 /tmp/schritt2a-patch.py

echo ""
echo "==> [3/6] TypeScript-Check (nur Syntax, kein Build)"
npx tsc --noEmit --skipLibCheck src/components/admin/pdf-layout-tab.tsx 2>/dev/null || true

echo ""
echo "==> [4/6] Build"
if ! npm run build; then
  echo ""
  echo "!! BUILD FEHLGESCHLAGEN – ROLLBACK !!"
  if [ -f src/components/admin/design-editor.tsx.bak ]; then
    mv src/components/admin/design-editor.tsx.bak src/components/admin/design-editor.tsx
    echo "   design-editor.tsx zurückgesetzt"
  fi
  rm -f src/components/admin/pdf-layout-tab.tsx
  echo "   pdf-layout-tab.tsx entfernt"
  exit 1
fi

echo ""
echo "==> [5/6] PM2 Restart"
pm2 restart menucard-pro
sleep 2
pm2 status | grep menucard-pro

echo ""
echo "==> [6/6] Smoke Tests"
echo "-- Status-Code Admin-Design-Seite:"
curl -s -o /dev/null -w "HTTP %{http_code}\n" -I http://127.0.0.1:3000/admin/design || true
echo "-- Status-Code API design-templates list:"
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://127.0.0.1:3000/api/v1/design-templates || true

echo ""
echo "==> Fertig."
echo "   Backup: src/components/admin/design-editor.tsx.bak"
echo "   Neue Datei: src/components/admin/pdf-layout-tab.tsx"
echo ""
echo "   Aufräumen nach manuellem Test:"
echo "   rm src/components/admin/design-editor.tsx.bak"
