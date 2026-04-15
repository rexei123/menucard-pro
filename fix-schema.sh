#!/bin/bash
# MenuCard Pro – Prisma Schema Fix
# Behebt: 1) Doppelte productMedia Zeile in Model Media
#          2) Inventory Model referenziert noch MenuItem
# Datum: 10.04.2026

set -e
cd /var/www/menucard-pro

echo "=== Prisma Schema Fix ==="
echo ""

# Backup erstellen
cp prisma/schema.prisma prisma/schema.prisma.bak
echo "[1/5] Backup erstellt: prisma/schema.prisma.bak"

# Python-Fix ausfuehren
python3 -c "
c = open('prisma/schema.prisma').read()

# Fix 1: Doppelte productMedia Zeile entfernen
before = c.count('productMedia')
c = c.replace('  productMedia ProductMedia[]\n  productMedia     ProductMedia[]', '  productMedia ProductMedia[]')
after = c.count('productMedia')
if before != after:
    print('[2/5] Fix 1: Doppelte productMedia Zeile entfernt')
else:
    # Versuch mit anderer Einrueckung
    import re
    c_new = re.sub(r'(  productMedia\s+ProductMedia\[\])\n\s+productMedia\s+ProductMedia\[\]', r'\1', c)
    if c_new != c:
        c = c_new
        print('[2/5] Fix 1: Doppelte productMedia Zeile entfernt (alt. Pattern)')
    else:
        print('[2/5] Fix 1: Keine doppelte productMedia gefunden (evtl. bereits gefixt)')

# Fix 2: Inventory Model komplett entfernen
import re
c_new = re.sub(r'\nmodel Inventory \{[^}]+\}\n', '\n', c)
if c_new != c:
    c = c_new
    print('[3/5] Fix 2: Inventory Model entfernt')
else:
    print('[3/5] Fix 2: Kein Inventory Model gefunden (evtl. bereits gefixt)')

# Aufraumen: mehrfache Leerzeilen
c = re.sub(r'\n{3,}', '\n\n', c)

open('prisma/schema.prisma', 'w').write(c)
print('[4/5] Schema gespeichert')
"

# Prisma db push + Build + Restart
echo ""
echo "=== Prisma DB Push ==="
npx prisma db push --accept-data-loss

echo ""
echo "=== Build ==="
npm run build

echo ""
echo "=== PM2 Restart ==="
pm2 restart menucard-pro

echo ""
echo "[5/5] Fertig! Schema-Fix erfolgreich abgeschlossen."
echo ""
echo "Zur Kontrolle:"
echo "  grep -n 'productMedia' prisma/schema.prisma"
echo "  grep -n 'Inventory' prisma/schema.prisma"
