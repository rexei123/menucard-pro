#!/bin/bash
echo "🧪 MenuCard Pro - Automatischer Test"
echo "======================================"
BASE="http://localhost:3000"
PASS=0
FAIL=0

test_url() {
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE$1")
  if [ "$STATUS" = "$2" ]; then
    echo "✅ $1 → $STATUS"
    PASS=$((PASS+1))
  else
    echo "❌ $1 → $STATUS (erwartet: $2)"
    FAIL=$((FAIL+1))
  fi
}

echo ""
echo "--- Landing & Public ---"
test_url "/" 200
test_url "/hotel-sonnblick" 200
test_url "/hotel-sonnblick/restaurant" 200
test_url "/hotel-sonnblick/restaurant/speisekarte" 200
test_url "/hotel-sonnblick/restaurant/weinkarte" 200
test_url "/nicht-existiert" 404

echo ""
echo "--- Auth ---"
test_url "/auth/login" 200
test_url "/admin" 307

echo ""
echo "--- QR Redirect ---"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -L "$BASE/q/SB-REST1")
if [ "$STATUS" = "200" ]; then
  echo "✅ /q/SB-REST1 → Redirect OK"
  PASS=$((PASS+1))
else
  echo "❌ /q/SB-REST1 → $STATUS"
  FAIL=$((FAIL+1))
fi

echo ""
echo "--- API ---"
test_url "/api/v1/public/hotel-sonnblick/restaurant/menus" 200

echo ""
echo "======================================"
echo "Ergebnis: $PASS bestanden, $FAIL fehlgeschlagen"
[ $FAIL -eq 0 ] && echo "🎉 Alle Tests bestanden!" || echo "⚠️  $FAIL Tests fehlgeschlagen"
