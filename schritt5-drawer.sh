#!/bin/bash
set -e
cd /var/www/menucard-pro

echo ">>> Drawer-Komponente installieren"
mv template-picker-drawer.tsx src/components/admin/template-picker-drawer.tsx

echo ">>> Patches anwenden"
python3 schritt5-patch.py

echo ">>> Build"
npm run build

echo ">>> Restart"
pm2 restart menucard-pro

echo ">>> Smoke-Test"
sleep 2
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:3000/admin/menus

echo ">>> FERTIG. Karteneditor im Browser öffnen und Button 'Vorlage' klicken."
