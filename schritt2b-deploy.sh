#!/bin/bash
# Schritt 2b-1: "In neuem Tab oeffnen" -> pdf.js Wrapper bei PDF-Vorschau
set -e
cd /var/www/menucard-pro

echo "--- Aktuelle href-Zeile ---"
grep -n "In neuem Tab\|target=\"_blank\"" src/components/admin/design-editor.tsx | head -10

echo ""
echo "--- Patch anwenden ---"
python3 /tmp/schritt2b-pdf-newtab.py

echo ""
echo "--- Build + Restart ---"
npm run build && pm2 restart menucard-pro && echo "DEPLOY OK"
