#!/bin/bash
# MenuCard Pro – Alte Seed-Dateien bereinigen
# Die Daten sind bereits in der DB (322 Produkte).
# Alte Seeds referenzieren ItemType/MenuItem die nicht mehr existieren.
# Datum: 10.04.2026

set -e
cd /var/www/menucard-pro

echo "=== Alte Seed-Dateien bereinigen ==="
echo ""

# Archiv-Ordner erstellen
mkdir -p prisma/archive
echo "[1/4] Archiv-Ordner erstellt: prisma/archive/"

# Alte Seeds verschieben
for f in prisma/seed-bar.ts prisma/seed-real.ts prisma/seed.ts prisma/seed-wine.ts; do
  if [ -f "$f" ]; then
    mv "$f" prisma/archive/
    echo "[2/4] Verschoben: $f -> prisma/archive/"
  else
    echo "[2/4] Nicht gefunden (bereits verschoben?): $f"
  fi
done

# Pruefen ob noch ItemType/MenuItem Referenzen existieren
echo ""
echo "[3/4] Pruefe auf verbleibende ItemType/MenuItem Referenzen..."
if grep -rl 'ItemType\|MenuItem' prisma/*.ts 2>/dev/null; then
  echo "WARNUNG: Noch Referenzen gefunden!"
else
  echo "OK – keine Referenzen mehr."
fi

# Build + Restart
echo ""
echo "=== Build ==="
npm run build

echo ""
echo "=== PM2 Restart ==="
pm2 restart menucard-pro

echo ""
echo "[4/4] Fertig! Build erfolgreich."
