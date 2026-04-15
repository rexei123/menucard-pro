#!/bin/bash
set -e
echo "============================================"
echo "  Fix: Admin-Backend auf Roboto umstellen"
echo "============================================"

cd /var/www/menucard-pro

# Backup
cp src/app/admin/layout.tsx src/app/admin/layout.tsx.bak

# ============================================
# 1. CSS-Datei für Admin-Font (nur Admin-Scope)
# ============================================
echo "[1/3] CSS für Admin-Roboto erstellen..."

cat > src/styles/admin-font.css << 'CSSEOF'
/* Roboto nur fürs Admin-Backend - Gästeansicht bleibt unverändert */
@import url('https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700;900&display=swap');

.admin-roboto,
.admin-roboto button,
.admin-roboto input,
.admin-roboto textarea,
.admin-roboto select,
.admin-roboto h1,
.admin-roboto h2,
.admin-roboto h3,
.admin-roboto h4,
.admin-roboto h5,
.admin-roboto h6,
.admin-roboto p,
.admin-roboto span,
.admin-roboto a,
.admin-roboto div,
.admin-roboto li,
.admin-roboto label {
  font-family: 'Roboto', system-ui, -apple-system, sans-serif !important;
}

/* Ausnahme: Material Symbols Icons müssen ihre eigene Schrift behalten */
.admin-roboto .material-symbols-outlined,
.admin-roboto [class*="material-symbols"] {
  font-family: 'Material Symbols Outlined' !important;
}
CSSEOF

# ============================================
# 2. CSS in globals.css importieren
# ============================================
echo "[2/3] Import in globals.css einfügen..."

if ! grep -q "admin-font.css" src/app/globals.css; then
  # Import-Zeile ganz oben einfügen
  sed -i '1i @import "../styles/admin-font.css";' src/app/globals.css
  echo "  Import hinzugefügt"
else
  echo "  Import bereits vorhanden"
fi

# ============================================
# 3. admin-roboto Klasse in Admin-Layout setzen
# ============================================
echo "[3/3] Admin-Layout Wrapper aktualisieren..."

# Nur anpassen wenn noch nicht drin
if ! grep -q "admin-roboto" src/app/admin/layout.tsx; then
  sed -i 's|className="flex h-screen overflow-hidden"|className="admin-roboto flex h-screen overflow-hidden"|' src/app/admin/layout.tsx
  echo "  Klasse eingefügt"
else
  echo "  Klasse bereits vorhanden"
fi

# Verifizieren
grep "admin-roboto" src/app/admin/layout.tsx | head -2

# ============================================
# BUILD
# ============================================
echo "[BUILD] Cache löschen + Build..."
rm -rf .next
npm run build 2>&1 | tail -5
pm2 restart menucard-pro

echo ""
echo "============================================"
echo "  Roboto im Admin-Backend: FERTIG!"
echo "============================================"
echo "  - Schrift: Roboto (300, 400, 500, 700, 900)"
echo "  - Scope: nur .admin-roboto (Admin-Bereich)"
echo "  - Material Icons: unverändert"
echo "  - Gästeansicht: unverändert (keine Änderung)"
echo "============================================"
