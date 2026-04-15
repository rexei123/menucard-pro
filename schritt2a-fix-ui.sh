#!/usr/bin/env bash
# Schritt 2a Fix-UI: Tabs flex-wrap + PDF-Preview
set -e
cd /var/www/menucard-pro

echo "==> [1/4] Patches anwenden"
python3 /tmp/schritt2a-fix-ui.py

echo ""
echo "==> [2/4] Build"
if ! npm run build; then
  echo ""
  echo "!! BUILD FEHLGESCHLAGEN – ROLLBACK !!"
  if [ -f src/components/admin/design-editor.tsx.bak2 ]; then
    mv src/components/admin/design-editor.tsx.bak2 src/components/admin/design-editor.tsx
    echo "   design-editor.tsx zurückgesetzt"
  fi
  if [ -f "src/app/admin/design/[id]/edit/page.tsx.bak2" ]; then
    mv "src/app/admin/design/[id]/edit/page.tsx.bak2" "src/app/admin/design/[id]/edit/page.tsx"
    echo "   edit/page.tsx zurückgesetzt"
  fi
  exit 1
fi

echo ""
echo "==> [3/4] PM2 Restart"
pm2 restart menucard-pro
sleep 2
pm2 status | grep menucard-pro

echo ""
echo "==> [4/4] Smoke Tests"
curl -s -o /dev/null -w "Admin Design:  HTTP %{http_code}\n" -I http://127.0.0.1:3000/admin/design
curl -s -o /dev/null -w "API Templates: HTTP %{http_code}\n" http://127.0.0.1:3000/api/v1/design-templates

echo ""
echo "==> Fertig. Backups:"
echo "   src/components/admin/design-editor.tsx.bak2"
echo "   src/app/admin/design/[id]/edit/page.tsx.bak2"
