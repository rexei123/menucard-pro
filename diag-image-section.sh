#!/bin/bash
# Diagnose: Legacy-Gold-Farben im Bilder-Bereich aufspueren

cd /var/www/menucard-pro

echo "============================================"
echo "  Diagnose Bilder-Bereich (Legacy-Farben)"
echo "============================================"

echo ""
echo "[1] #8B6914 (Legacy-Gold) im product-editor:"
grep -n "8B6914" src/components/admin/product-editor.tsx || echo "  keine Treffer"

echo ""
echo "[2] Weitere Gold/Orange-Toene im product-editor:"
grep -nE "#(A0|B0|C0|D0|E0|F0)[0-9A-Fa-f]{4}" src/components/admin/product-editor.tsx | head -20

echo ""
echo "[3] Alle inline-backgroundColor im product-editor:"
grep -nE "backgroundColor:'#[0-9A-Fa-f]{6}'" src/components/admin/product-editor.tsx

echo ""
echo "[4] Alle inline-borderColor / color im product-editor:"
grep -nE "(borderColor|color):'#[0-9A-Fa-f]{6}'" src/components/admin/product-editor.tsx

echo ""
echo "[5] Bilder-Bereich (Zeilen mit 'Bildarchiv' / 'Hochladen' / 'Hauptbild'):"
grep -nE "(Bildarchiv|Hochladen|Hauptbild)" src/components/admin/product-editor.tsx

echo ""
echo "[6] Kontext um 'Bildarchiv':"
grep -nB 3 -A 3 "Bildarchiv" src/components/admin/product-editor.tsx | head -30

echo ""
echo "[7] Kontext um 'Hochladen':"
grep -nB 3 -A 3 "Hochladen" src/components/admin/product-editor.tsx | head -30

echo ""
echo "[8] Kontext um 'Hauptbild':"
grep -nB 3 -A 3 "Hauptbild" src/components/admin/product-editor.tsx | head -30

echo ""
echo "============================================"
