#!/usr/bin/env bash
set -e
cd /var/www/menucard-pro

echo "==> [1/3] pdf-viewer.html einspielen"
cp /tmp/pdf-viewer.html public/pdf-viewer.html
ls -la public/pdf-viewer.html

echo ""
echo "==> [2/3] design-editor.tsx patchen"
python3 /tmp/schritt2a-pdfjs.py

echo ""
echo "==> [3/3] Build + Restart"
npm run build
pm2 restart menucard-pro
echo "DEPLOY OK"
