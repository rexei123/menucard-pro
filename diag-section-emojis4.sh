#!/bin/bash
cd /var/www/menucard-pro

echo "=== 1. menu-editor.tsx KOMPLETT ==="
cat -n src/components/admin/menu-editor.tsx

echo ""
echo "=== 2. Alle distinct Emoji-Icons in DB ==="
psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -tAc "SELECT DISTINCT icon FROM \"MenuSection\" WHERE icon IS NOT NULL ORDER BY icon;"
