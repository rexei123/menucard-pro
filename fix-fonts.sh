#!/bin/bash
# Cormorant Garamond TTF-Dateien herunterladen
cd /var/www/menucard-pro/public/fonts

# Aufräumen
rm -f Cormorant*.ttf cormorant*

# URLs direkt von Google Fonts CSS extrahieren und herunterladen
CSS=$(curl -sL -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,600;0,700;1,400")

echo "$CSS" | grep -oP "src: url\(\K[^)]+" > /tmp/font-urls.txt

IDX=0
NAMES=("CormorantGaramond-Regular.ttf" "CormorantGaramond-SemiBold.ttf" "CormorantGaramond-Bold.ttf" "CormorantGaramond-Italic.ttf")

while read -r URL; do
  if [ $IDX -lt 4 ]; then
    echo "Lade ${NAMES[$IDX]} von $URL ..."
    curl -sL -o "${NAMES[$IDX]}" "$URL"
    SIZE=$(stat -c%s "${NAMES[$IDX]}" 2>/dev/null || echo 0)
    echo "  -> $SIZE bytes"
  fi
  IDX=$((IDX+1))
done < /tmp/font-urls.txt

echo ""
echo "Ergebnis:"
ls -la Cormorant*.ttf 2>/dev/null || echo "Keine Dateien gefunden"

# Falls immer noch leer, Fallback: woff2 nutzen
TOTAL=$(ls -la Cormorant*.ttf 2>/dev/null | awk '{sum+=$5}END{print sum+0}')
if [ "$TOTAL" -lt 1000 ]; then
  echo ""
  echo "TTF-Download fehlgeschlagen. Versuche woff2..."
  rm -f Cormorant*.ttf

  # Fontsource woff2 kopieren und fonts.ts auf woff2 umstellen
  cd /var/www/menucard-pro
  npm pack @fontsource/cormorant-garamond 2>/dev/null
  tar xzf fontsource-cormorant-garamond-*.tgz 2>/dev/null

  cp package/files/cormorant-garamond-latin-400-normal.woff2 public/fonts/CormorantGaramond-Regular.woff2 2>/dev/null
  cp package/files/cormorant-garamond-latin-600-normal.woff2 public/fonts/CormorantGaramond-SemiBold.woff2 2>/dev/null
  cp package/files/cormorant-garamond-latin-700-normal.woff2 public/fonts/CormorantGaramond-Bold.woff2 2>/dev/null
  cp package/files/cormorant-garamond-latin-400-italic.woff2 public/fonts/CormorantGaramond-Italic.woff2 2>/dev/null

  ls -la public/fonts/Cormorant*.woff2 2>/dev/null

  # fonts.ts updaten: .ttf -> .woff2 für Cormorant
  sed -i "s/CormorantGaramond-Regular.ttf/CormorantGaramond-Regular.woff2/g" src/lib/pdf/fonts.ts
  sed -i "s/CormorantGaramond-SemiBold.ttf/CormorantGaramond-SemiBold.woff2/g" src/lib/pdf/fonts.ts
  sed -i "s/CormorantGaramond-Bold.ttf/CormorantGaramond-Bold.woff2/g" src/lib/pdf/fonts.ts
  sed -i "s/CormorantGaramond-Italic.ttf/CormorantGaramond-Italic.woff2/g" src/lib/pdf/fonts.ts

  echo "  ✓ woff2-Dateien kopiert und fonts.ts aktualisiert"

  rm -rf package fontsource-cormorant-garamond-*.tgz
fi

echo ""
echo "=== Restart ==="
cd /var/www/menucard-pro
pm2 restart menucard-pro
echo "  ✓ Fertig! Teste Klassisch-Template erneut."
