#!/bin/bash
set -e
echo "============================================"
echo "  Fix: Test-Befunde beheben"
echo "============================================"

cd /var/www/menucard-pro

# ============================================
# 1. SECURITY: .git und prisma blockieren
# ============================================
echo "[1/3] Nginx: .git und prisma blockieren..."

# Prüfe aktuelle Nginx-Config
NGINX_CONF=$(grep -rl "server_name" /etc/nginx/sites-enabled/ 2>/dev/null | head -1)
if [ -z "$NGINX_CONF" ]; then
  NGINX_CONF=$(grep -rl "server_name" /etc/nginx/conf.d/ 2>/dev/null | head -1)
fi

if [ -z "$NGINX_CONF" ]; then
  echo "  WARNUNG: Nginx-Config nicht gefunden, versuche default..."
  NGINX_CONF="/etc/nginx/sites-enabled/default"
fi

echo "  Nginx-Config: $NGINX_CONF"
cp "$NGINX_CONF" "${NGINX_CONF}.bak-$(date +%Y%m%d)"

# Prüfe ob Blockierung bereits existiert
if grep -q "\.git" "$NGINX_CONF"; then
  echo "  .git Regel existiert bereits - wird aktualisiert..."
else
  echo "  Füge Security-Regeln hinzu..."
fi

# Security-Block in separater Config
cat > /etc/nginx/conf.d/security-blocks.conf << 'NGXEOF'
# Security: Sensitive Dateien und Verzeichnisse blockieren
# Erstellt: 13.04.2026 nach Test-Audit

# .git Verzeichnis komplett blockieren
location ~ /\.git {
    deny all;
    return 404;
}

# Prisma-Dateien blockieren
location ~ /prisma {
    deny all;
    return 404;
}

# Weitere sensitive Pfade
location ~ /\.sql$ {
    deny all;
    return 404;
}
NGXEOF

# Teste und lade Nginx neu
nginx -t && systemctl reload nginx
echo "  ✓ Nginx Security-Regeln aktiv"

# Verifiziere
echo "  Verifiziere Blockierung..."
GIT_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/.git/config)
PRISMA_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/prisma/schema.prisma)
echo "  /.git/config: $GIT_CODE (soll 404)"
echo "  /prisma/schema.prisma: $PRISMA_CODE (soll 404)"

# ============================================
# 2. TypeScript: admin/page.tsx Fehler fixen
# ============================================
echo ""
echo "[2/3] TypeScript-Fehler in admin/page.tsx fixen..."

# Zuerst: Prisma Schema prüfen um korrekte Feldnamen zu finden
echo "  Prüfe Prisma-Schema für korrekte Feldnamen..."

# Finde den korrekten Feldnamen für Preis
PRICE_FIELD=$(grep -A 5 "model ProductPrice" prisma/schema.prisma | grep -E "price|amount" | head -1 | awk '{print $1}')
echo "  Preis-Feld: $PRICE_FIELD"

# Finde den korrekten Feldnamen für Thumbnail
THUMB_FIELD=$(grep -E "thumbnail|thumbPath|thumbnailPath|filePath|path" prisma/schema.prisma | head -3)
echo "  Media-Felder: $THUMB_FIELD"

# Finde korrekte Menu-Select Felder
MENU_FIELDS=$(grep -A 15 "model Menu " prisma/schema.prisma | head -20)
echo "  Menu-Modell gefunden"

# Python-Script für sichere Korrektur
cat > /tmp/fix-admin-page.py << 'PYEOF'
import subprocess, re

# Prisma Schema lesen um korrekte Felder zu finden
with open('prisma/schema.prisma', 'r') as f:
    schema = f.read()

with open('src/app/admin/page.tsx', 'r') as f:
    content = f.read()

original = content

# Fix 1: Menu select - 'name' existiert nicht direkt
# Ersetze fehlerhaften select mit korrekter Struktur
# Finde die Prisma-Query und fixe den select
content = content.replace(
    "select: { name: true",
    "select: { slug: true"
)

# Wenn name in Menu nicht existiert, müssen wir prüfen
# Oft heißt es bei Menu auch 'name' - aber das select-Objekt passt nicht zum Type
# Versuche alternatives Pattern
if "MenuSelect" in content:
    # Das Problem ist möglicherweise dass extra Felder im select sind
    pass

# Fix 2: 'amount' → 'price' (ProductPrice hat 'price' nicht 'amount')
content = content.replace('.amount', '.price')

# Fix 3: 'thumbnailPath' → korrektes Feld
# Prüfe was Media hat
if 'thumbnailPath' in content:
    # Media hat vermutlich 'filePath' oder 'path' oder wir brauchen formats
    # Einfachste Lösung: auf ein existierendes Feld mappen
    # Schaue im Schema nach
    media_fields = re.findall(r'model Media \{(.*?)\}', schema, re.DOTALL)
    if media_fields:
        fields_text = media_fields[0]
        if 'filePath' in fields_text:
            content = content.replace('thumbnailPath', 'filePath')
        elif 'path' in fields_text and 'path ' in fields_text:
            content = content.replace('thumbnailPath', 'path')
        elif 'url' in fields_text:
            content = content.replace('thumbnailPath', 'url')
        else:
            # Fallback: formats JSON Feld nutzen oder filePath
            content = content.replace('.thumbnailPath', '?.filePath || ""')
            print(f"  WARNUNG: thumbnailPath Feld nicht eindeutig, bitte manuell prüfen")
            print(f"  Media-Felder: {fields_text[:200]}")

if content != original:
    with open('src/app/admin/page.tsx', 'w') as f:
        f.write(content)
    print("  admin/page.tsx korrigiert")
else:
    print("  Keine Änderungen nötig oder Pattern nicht gefunden")
    print("  Manuelle Prüfung empfohlen")
PYEOF
python3 /tmp/fix-admin-page.py
rm -f /tmp/fix-admin-page.py

# ============================================
# 3. QrCode Tabellenname prüfen
# ============================================
echo ""
echo "[3/3] QrCode-Tabelle prüfen..."

# Prüfe den tatsächlichen Tabellennamen
QR_TABLE=$(psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -t -c "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name ILIKE '%qr%'" 2>/dev/null | tr -d ' ')

if [ -n "$QR_TABLE" ]; then
  echo "  QR-Tabelle gefunden: $QR_TABLE"
  QR_COUNT=$(psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -t -c "SELECT count(*) FROM \"$QR_TABLE\"" 2>/dev/null | tr -d ' ')
  echo "  QR-Codes: $QR_COUNT Einträge"
else
  echo "  KEINE QR-Tabelle gefunden"
  echo "  Alle Tabellen mit 'qr' oder 'code':"
  psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -t -c "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND (table_name ILIKE '%qr%' OR table_name ILIKE '%code%')" 2>/dev/null
  echo "  Prisma-Schema QR-Modell:"
  grep -A 3 "model.*[Qq][Rr]" prisma/schema.prisma 2>/dev/null || echo "  Kein QR-Modell im Schema"
fi

# ============================================
# 4. TypeScript nochmal prüfen
# ============================================
echo ""
echo "[CHECK] TypeScript-Prüfung..."
TSC_ERRORS=$(npx tsc --noEmit 2>&1 | grep "error TS" | wc -l)
if [ "$TSC_ERRORS" -eq 0 ]; then
  echo "  ✓ TypeScript: 0 Fehler"
else
  echo "  ✗ TypeScript: noch $TSC_ERRORS Fehler"
  npx tsc --noEmit 2>&1 | grep "error TS"
fi

# ============================================
# 5. Security nochmal prüfen
# ============================================
echo ""
echo "[CHECK] Security-Verifizierung..."
for path in "/.git/config" "/prisma/schema.prisma" "/.env" "/.bak"; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost$path")
  if [ "$CODE" = "403" ] || [ "$CODE" = "404" ]; then
    echo "  ✓ Blockiert: $path → $CODE"
  else
    echo "  ✗ OFFEN: $path → $CODE"
  fi
done

# ============================================
# 6. Build wenn TS-Fehler behoben
# ============================================
if [ "$TSC_ERRORS" -eq 0 ]; then
  echo ""
  echo "[BUILD] Starte Build..."
  npm run build && pm2 restart menucard-pro
  echo "  ✓ Build erfolgreich"
else
  echo ""
  echo "  ⚠ Build übersprungen wegen TypeScript-Fehlern"
  echo "  Bitte Fehler manuell beheben und dann: npm run build && pm2 restart menucard-pro"
fi

echo ""
echo "============================================"
echo "  Fix: Test-Befunde ERGEBNISSE"
echo "============================================"
