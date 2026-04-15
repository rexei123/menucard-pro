#!/bin/bash
set -e
echo "============================================"
echo "  Fix v2: Roboto auf ALLE Elemente anwenden"
echo "============================================"

cd /var/www/menucard-pro

# CSS komplett überschreiben mit Wildcard-Selektor
cat > src/styles/admin-font.css << 'CSSEOF'
/* Roboto nur fürs Admin-Backend - Gästeansicht bleibt unverändert */
@import url('https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700;900&display=swap');

/* Alles innerhalb .admin-roboto bekommt Roboto - überschreibt auch inline styles */
.admin-roboto,
.admin-roboto * {
  font-family: 'Roboto', system-ui, -apple-system, BlinkMacSystemFont, sans-serif !important;
}

/* Ausnahmen: Material Symbols Icons müssen ihre eigene Schrift behalten */
.admin-roboto .material-symbols-outlined,
.admin-roboto [class*="material-symbols"],
.admin-roboto .material-icons,
.admin-roboto [class*="material-icons"] {
  font-family: 'Material Symbols Outlined', 'Material Icons' !important;
}
CSSEOF

echo "CSS aktualisiert"

# Cache löschen und neu bauen
rm -rf .next
npm run build 2>&1 | tail -3
pm2 restart menucard-pro

echo ""
echo "============================================"
echo "  Roboto v2: FERTIG"
echo "============================================"
echo "  - Wildcard-Selektor (.admin-roboto *)"
echo "  - Überschreibt inline fontFamily"
echo "  - Material Icons ausgenommen"
echo "============================================"
