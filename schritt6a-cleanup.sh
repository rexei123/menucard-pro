#!/bin/bash
set -e
cd /var/www/menucard-pro

echo ">>> [1/6] Code-Patches anwenden"
python3 schritt6a-patch.py

echo ""
echo ">>> [2/6] Alte API-Route /api/v1/menus/[id]/design entfernen"
if [ -d "src/app/api/v1/menus/[id]/design" ]; then
  # Sicherheitsbackup in /root
  mkdir -p /root/menucard-s6a-backup
  cp -r "src/app/api/v1/menus/[id]/design" /root/menucard-s6a-backup/
  rm -rf "src/app/api/v1/menus/[id]/design"
  echo "  entfernt (Backup in /root/menucard-s6a-backup/)"
else
  echo "  bereits entfernt"
fi

echo ""
echo ">>> [3/6] Build"
if ! npm run build; then
  echo ""
  echo "!!! BUILD FEHLGESCHLAGEN - Rollback !!!"
  # Code-Patches zurueck
  for bak in src/app/admin/page.tsx.bak-s6a src/app/api/v1/menus/route.ts.bak-s6a src/app/admin/pdf-creator/page.tsx.bak-s6a; do
    orig="${bak%.bak-s6a}"
    if [ -f "$bak" ]; then mv "$bak" "$orig"; fi
  done
  # Route zurueck
  if [ -d /root/menucard-s6a-backup/design ]; then
    mkdir -p "src/app/api/v1/menus/[id]"
    cp -r /root/menucard-s6a-backup/design "src/app/api/v1/menus/[id]/"
  fi
  exit 1
fi

echo ""
echo ">>> [4/6] Restart"
pm2 restart menucard-pro
sleep 2

echo ""
echo ">>> [5/6] Smoke-Tests"
curl -s -o /dev/null -w "HTTP /admin:                  %{http_code}\n" http://localhost:3000/admin
curl -s -o /dev/null -w "HTTP /admin/menus:            %{http_code}\n" http://localhost:3000/admin/menus
curl -s -o /dev/null -w "HTTP /admin/design:           %{http_code}\n" http://localhost:3000/admin/design
curl -s -o /dev/null -w "HTTP /admin/pdf-creator:      %{http_code}\n" http://localhost:3000/admin/pdf-creator
# Alte API-Route muss 404 liefern
CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/v1/menus/any-id/design)
echo "HTTP /api/v1/menus/.../design: $CODE (erwartet 404)"

echo ""
echo ">>> [6/6] .bak-Dateien aufraeumen"
BAK_COUNT=$(find src -name "*.bak*" -type f | wc -l)
echo "  Gefunden: $BAK_COUNT .bak-Dateien in src/"
# Liste in Log, dann loeschen
find src -name "*.bak*" -type f > /root/menucard-s6a-backup/bak-files-removed.txt 2>/dev/null || true
find src -name "*.bak*" -type f -delete
REMAIN=$(find src -name "*.bak*" -type f | wc -l)
echo "  Geloescht. Verbleibend: $REMAIN (sollte 0 sein)"
echo "  Liste der entfernten Dateien: /root/menucard-s6a-backup/bak-files-removed.txt"

echo ""
echo ">>> FERTIG Phase A."
echo "Erledigt:"
echo "  - Dashboard liest Template via Menu.template.baseType"
echo "  - Menu-Liste-API ohne designConfig in Response"
echo "  - PDF-Creator-Link entfernt"
echo "  - Alte /api/v1/menus/[id]/design Route geloescht"
echo "  - $BAK_COUNT .bak-Dateien entfernt"
echo ""
echo "NICHT angetastet (kommen in Phase B nach PDF-Export v2):"
echo "  - Menu.designConfig Spalte in DB"
echo "  - Analog-Editor Lesepfad"
echo "  - lib/template-resolver.ts Fallback"
