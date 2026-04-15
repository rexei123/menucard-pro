#!/bin/bash
# Fix: PDF Content-Disposition Dateiname - Umlaute korrekt kodieren
cd /var/www/menucard-pro

echo "=== Fix PDF Dateiname ==="

# Zeige die aktuelle Content-Disposition Zeile
grep -n "Content-Disposition\|filename" src/app/api/v1/menus/\[id\]/pdf/route.ts

# Finde und ersetze die Response-Zeile mit korrekter UTF-8 Kodierung
python3 << 'PYEOF'
with open("src/app/api/v1/menus/[id]/pdf/route.ts", "r") as f:
    content = f.read()

# Suche die Stelle wo filename gesetzt wird und die Response erstellt wird
# Ersetze Content-Disposition mit ASCII-safe + UTF-8 Variante
import re

# Finde das Pattern wo der filename erstellt wird
# Typisch: const filename = `${menuName}.pdf`
# und dann: 'Content-Disposition': `inline; filename="${filename}"`

# Fix 1: Füge eine Funktion hinzu die den Dateinamen bereinigt
sanitize_fn = '''
// Dateiname ASCII-sicher machen für Content-Disposition
function sanitizeFilename(name: string): string {
  return name
    .replace(/ä/g, 'ae').replace(/ö/g, 'oe').replace(/ü/g, 'ue')
    .replace(/Ä/g, 'Ae').replace(/Ö/g, 'Oe').replace(/Ü/g, 'Ue')
    .replace(/ß/g, 'ss')
    .replace(/[^a-zA-Z0-9._\\- ]/g, '')
    .trim();
}
'''

# Füge die Funktion nach den imports ein
if 'sanitizeFilename' not in content:
    # Finde die letzte import-Zeile
    lines = content.split('\n')
    insert_idx = 0
    for i, line in enumerate(lines):
        if line.startswith('import '):
            insert_idx = i + 1
    lines.insert(insert_idx, sanitize_fn)
    content = '\n'.join(lines)
    print("  ✓ sanitizeFilename Funktion eingefügt")

# Fix 2: Ersetze die Content-Disposition Zeile
# Suche nach dem Pattern mit filename
old_disp = re.search(r"'Content-Disposition':\s*`inline; filename=\"\$\{(\w+)\}\"`", content)
if old_disp:
    var_name = old_disp.group(1)
    old_str = old_disp.group(0)
    new_str = f"'Content-Disposition': `inline; filename=\"${{sanitizeFilename({var_name})}}\"; filename*=UTF-8''${{encodeURIComponent({var_name})}}`"
    content = content.replace(old_str, new_str)
    print(f"  ✓ Content-Disposition mit sanitizeFilename({var_name}) ersetzt")
else:
    print("  ⚠ Content-Disposition Pattern nicht gefunden, suche alternativ...")
    # Alternatives Pattern
    if 'inline; filename=' in content:
        content = re.sub(
            r"'Content-Disposition':\s*`inline;\s*filename=\"([^\"]*)\"`",
            lambda m: "'Content-Disposition': `inline; filename=\"${sanitizeFilename(" + m.group(1).replace('${','').replace('}','') + ")}\"; filename*=UTF-8''${encodeURIComponent(" + m.group(1).replace('${','').replace('}','') + ")}`",
            content
        )
        print("  ✓ Alternatives Pattern ersetzt")

with open("src/app/api/v1/menus/[id]/pdf/route.ts", "w") as f:
    f.write(content)
PYEOF

echo ""
echo "[2/2] Build..."
npm run build 2>&1 | tail -10

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo ""
  echo "  ✅ PDF Dateiname Fix LIVE!"
  # Teste den Header
  MENU_ID=$(node -e "const{PrismaClient}=require('@prisma/client');new PrismaClient().menu.findFirst().then(m=>console.log(m.id))" 2>/dev/null)
  sleep 2
  echo "  Header-Test:"
  curl -sI http://127.0.0.1:80/api/v1/menus/$MENU_ID/pdf | grep -i content-disposition
else
  echo "  ❌ Build fehlgeschlagen"
fi
