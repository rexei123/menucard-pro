#!/bin/bash
# Zeigt die aktuelle Template-Übersichtsseite
cd /var/www/menucard-pro
echo "=== page.tsx ==="
cat src/app/admin/design/page.tsx
echo ""
echo "=== Zeilenzahl ==="
wc -l src/app/admin/design/page.tsx
