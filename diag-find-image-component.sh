#!/bin/bash
cd /var/www/menucard-pro

echo "============================================"
echo "  Suche Bilder-Komponente"
echo "============================================"

echo ""
echo "[1] Dateien die 'Bildarchiv' enthalten:"
grep -rln "Bildarchiv" src/ 2>/dev/null

echo ""
echo "[2] Dateien die 'Hauptbild' enthalten:"
grep -rln "Hauptbild" src/ 2>/dev/null

echo ""
echo "[3] Dateien die 'Hochladen' enthalten:"
grep -rln "Hochladen" src/ 2>/dev/null

echo ""
echo "[4] Alle Dateien unter src/components/admin:"
ls -la src/components/admin/

echo ""
echo "[5] Legacy-Gold #8B6914 in allen src-Dateien:"
grep -rn "8B6914" src/ 2>/dev/null

echo ""
echo "[6] Weitere verdaechtige Gold/Orange-Toene (#A... - #F...) in src:"
grep -rnE "#(A[0-9]|B[0-9]|C[0-9]|D[0-9]|E[0-9])[0-9A-Fa-f]{4}" src/components/admin/ 2>/dev/null | head -30

echo ""
echo "============================================"
