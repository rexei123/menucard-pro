#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Phase 3: API-Umbau v2 ==="
echo "Dateien wurden per scp kopiert"

echo ""
echo "=== Build ==="
npm run build 2>&1 | tail -10

echo ""
echo "=== PM2 Restart ==="
pm2 restart menucard-pro 2>&1 | tail -3
sleep 3
pm2 flush menucard-pro 2>&1 | tail -1

echo ""
echo "=== Test: Gästeansicht ==="
echo "Abendkarte:"
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/hotel-sonnblick/restaurant/abendkarte
echo ""
echo "Weinkarte:"
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/hotel-sonnblick/restaurant/weinkarte
echo ""
echo "Barkarte:"
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/hotel-sonnblick/bar/barkarte
echo ""

echo ""
echo "=== Test: APIs ==="
echo "Taxonomy:"
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/v1/taxonomy
echo ""
echo "Products:"
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/v1/products
echo ""

echo ""
echo "=== PM2 Logs (letzte Fehler) ==="
pm2 logs menucard-pro --lines 5 --nostream 2>&1 | grep -i "error\|Error\|ERROR" || echo "Keine Fehler"

echo ""
echo "=== FERTIG ==="
