#!/bin/bash
set -e
cd /var/www/menucard-pro

echo ">>> [1/7] Backups anlegen"
cp src/components/admin/design-editor.tsx src/components/admin/design-editor.tsx.bak-editor-v2
if [ -f "src/app/admin/design/[id]/edit/page.tsx" ]; then
  cp "src/app/admin/design/[id]/edit/page.tsx" "src/app/admin/design/[id]/edit/page.tsx.bak-editor-v2"
fi

echo ">>> [2/7] Template-API auf deep-merge patchen"
python3 schritt-editor-v2-patch.py

echo ">>> [3/7] Neuen Editor einspielen"
mv design-editor-v2.tsx src/components/admin/design-editor.tsx

echo ">>> [4/7] Template-Edit-Route anlegen"
mkdir -p "src/app/admin/design/[id]/edit"
mv template-edit-page-v2.tsx "src/app/admin/design/[id]/edit/page.tsx"

echo ">>> [5/7] Build"
if ! npm run build; then
  echo ""
  echo "!!! BUILD FEHLGESCHLAGEN - Rollback !!!"
  # Editor zurück
  mv src/components/admin/design-editor.tsx.bak-editor-v2 src/components/admin/design-editor.tsx
  # Template-API zurück
  if [ -f "src/app/api/v1/design-templates/[id]/route.ts.bak-editor-v2" ]; then
    mv "src/app/api/v1/design-templates/[id]/route.ts.bak-editor-v2" "src/app/api/v1/design-templates/[id]/route.ts"
  fi
  # Edit-Page zurück (oder neu entfernen, wenn sie vorher nicht existierte)
  if [ -f "src/app/admin/design/[id]/edit/page.tsx.bak-editor-v2" ]; then
    mv "src/app/admin/design/[id]/edit/page.tsx.bak-editor-v2" "src/app/admin/design/[id]/edit/page.tsx"
  else
    rm -f "src/app/admin/design/[id]/edit/page.tsx"
    rmdir "src/app/admin/design/[id]/edit" 2>/dev/null || true
  fi
  exit 1
fi

echo ">>> [6/7] Restart"
pm2 restart menucard-pro

echo ">>> [7/7] Smoke-Test"
sleep 2
curl -s -o /dev/null -w "HTTP /admin/design:       %{http_code}\n" http://localhost:3000/admin/design
curl -s -o /dev/null -w "HTTP /admin/menus:        %{http_code}\n" http://localhost:3000/admin/menus

echo ""
echo ">>> FERTIG."
echo ">>> Karteneditor (Menü-Modus):     /admin/menus/[id]/design  (alte Route, bleibt bis Schritt 6)"
echo ">>> Template-Editor (Template-Modus): /admin/design/[id]/edit"
