#!/bin/bash
set -e
echo "============================================"
echo "  Fix: Hinzufuegen-Buttons auf helles Gruen"
echo "  + Dokumentation der Design-Regel"
echo "============================================"

cd /var/www/menucard-pro

# Backups
cp src/styles/tokens.css src/styles/tokens.css.bak
cp src/components/admin/product-list-panel.tsx src/components/admin/product-list-panel.tsx.bak
cp src/components/admin/product-editor.tsx src/components/admin/product-editor.tsx.bak
[ -f CLAUDE.md ] && cp CLAUDE.md CLAUDE.md.bak || true
[ -f README.md ] && cp README.md README.md.bak || true
[ -f MenuCard-Pro-Karten-Design-Anweisung.md ] && cp MenuCard-Pro-Karten-Design-Anweisung.md MenuCard-Pro-Karten-Design-Anweisung.md.bak || true

# ============================================
# 1. CSS-Variablen fuer "Add"-Farbe ergaenzen
# ============================================
echo "[1/5] CSS-Variablen in tokens.css ergaenzen..."

if ! grep -q "color-add" src/styles/tokens.css; then
  sed -i '/--color-success-light/a\  --color-add: #22C55E;          /* Hinzufuegen-Buttons (green-500) */\n  --color-add-hover: #16A34A;    /* Hinzufuegen-Buttons hover (green-600) */' src/styles/tokens.css
  echo "  Variablen hinzugefuegt"
else
  echo "  Variablen bereits vorhanden"
fi

# ============================================
# 2. "+ Artikel" Button (product-list-panel.tsx)
# ============================================
echo "[2/5] + Artikel Button umstellen..."
sed -i 's|bg-green-600|bg-[\#22C55E] hover:bg-[\#16A34A]|g' src/components/admin/product-list-panel.tsx
grep -n "+ Artikel" src/components/admin/product-list-panel.tsx | head -2

# ============================================
# 3. "+ Preis hinzufuegen" Button (product-editor.tsx)
# ============================================
echo "[3/5] + Preis hinzufuegen Button umstellen..."
sed -i "s|backgroundColor:'#8B6914'|backgroundColor:'#22C55E'|g" src/components/admin/product-editor.tsx
grep -n "Preis hinzu" src/components/admin/product-editor.tsx | head -2

# ============================================
# 4. Dokumentation der Design-Regel
# ============================================
echo "[4/5] Dokumentation aktualisieren..."

DESIGN_RULE='
## Design-Regel: Action-Button-Farben

**Hinzufuegen-Buttons: Gruen (hell)**
- Farbe: `#22C55E` (green-500, CSS-Variable `--color-add`)
- Hover: `#16A34A` (green-600, CSS-Variable `--color-add-hover`)
- Beispiele: `+ Artikel`, `+ Preis hinzufuegen`, `+ Neu anlegen`
- Referenz: gleicher Farbton wie die kleinen Status-Punkte bei Produkten

**Entfernen-/Loeschen-Buttons: Rosa (UI-Primaerfarbe)**
- Farbe: `var(--color-primary)` (#DD3C71)
- Oder: `var(--color-error)` fuer destruktive Aktionen
- Beispiele: `Loeschen`, `Entfernen`, `X` bei Listenpunkten

**Wichtig:** Diese Farblogik gilt im Admin-Backend durchgaengig. Gruen signalisiert "hinzufuegen/bestaetigen", Rosa/Rot signalisiert "entfernen/abbrechen".
'

# CLAUDE.md
if [ -f CLAUDE.md ]; then
  if ! grep -q "Design-Regel: Action-Button-Farben" CLAUDE.md; then
    echo "$DESIGN_RULE" >> CLAUDE.md
    echo "  CLAUDE.md aktualisiert"
  else
    echo "  CLAUDE.md bereits dokumentiert"
  fi
fi

# README.md
if [ -f README.md ]; then
  if ! grep -q "Design-Regel: Action-Button-Farben" README.md; then
    echo "$DESIGN_RULE" >> README.md
    echo "  README.md aktualisiert"
  else
    echo "  README.md bereits dokumentiert"
  fi
fi

# MenuCard-Pro-Karten-Design-Anweisung.md
if [ -f MenuCard-Pro-Karten-Design-Anweisung.md ]; then
  if ! grep -q "Design-Regel: Action-Button-Farben" MenuCard-Pro-Karten-Design-Anweisung.md; then
    echo "$DESIGN_RULE" >> MenuCard-Pro-Karten-Design-Anweisung.md
    echo "  MenuCard-Pro-Karten-Design-Anweisung.md aktualisiert"
  else
    echo "  Design-Anweisung bereits dokumentiert"
  fi
fi

# ============================================
# 5. Build
# ============================================
echo "[5/5] Cache loeschen + Build..."
rm -rf .next
npm run build 2>&1 | tail -5
pm2 restart menucard-pro

echo ""
echo "============================================"
echo "  Hinzufuegen-Buttons + Doku: FERTIG!"
echo "============================================"
echo "  - + Artikel: bg-green-600 -> #22C55E (heller)"
echo "  - + Preis: #8B6914 (gold) -> #22C55E"
echo "  - Hover: #16A34A"
echo "  - CSS-Variablen: --color-add, --color-add-hover"
echo "  - Dokumentation: CLAUDE.md, README.md, Design-Anweisung"
echo "============================================"
