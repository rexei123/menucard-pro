#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "================================================"
echo "Fix: Werkstatt-Zaehlung auf templateId umstellen"
echo "================================================"

# ----------------------------------------------
# 1) /api/v1/menus anpassen: template mitladen
# ----------------------------------------------
echo "[1/3] API /api/v1/menus pruefen und ggf. patchen..."
API_FILE="src/app/api/v1/menus/route.ts"
if [ ! -f "$API_FILE" ]; then
  echo "  FEHLER: $API_FILE existiert nicht"
  exit 1
fi

cp "$API_FILE" "$API_FILE.bak"

python3 <<'PYEOF'
path = 'src/app/api/v1/menus/route.ts'
with open(path, 'r', encoding='utf-8') as f:
    src = f.read()

changed = False

# Versuche: include mit translations -> include mit translations + template
# Wir suchen nach allen plausiblen Varianten ohne Regex
candidates = [
    ("include: { translations: true", "include: { translations: true, template: true"),
    ("include: {\n      translations: true,", "include: {\n      translations: true,\n      template: true,"),
    ("include: {\n    translations: true,", "include: {\n    translations: true,\n    template: true,"),
]

for old, new in candidates:
    if old in src and 'template: true' not in src:
        src = src.replace(old, new, 1)
        changed = True
        print(f"  Patch angewendet: {old[:40]}...")
        break

if not changed and 'template: true' in src:
    print('  Bereits vorhanden: template: true')
    changed = True

if not changed:
    print('  WARNUNG: Konnte include-Block nicht automatisch patchen. Inhalt:')
    print(src[:600])
    raise SystemExit('Manueller Eingriff noetig')

with open(path, 'w', encoding='utf-8') as f:
    f.write(src)
print('  OK')
PYEOF

echo ""
echo "[2/3] Werkstatt-Seite anpassen..."
cp src/app/admin/design/page.tsx src/app/admin/design/page.tsx.bak

python3 <<'PYEOF'
path = 'src/app/admin/design/page.tsx'
with open(path, 'r', encoding='utf-8') as f:
    src = f.read()

# Patch A: Menu-Typ erweitern
old_type = """type Menu = {
  id: string;
  name: string;
  slug: string;
  menuType: string;
  designConfig: any;
};"""
new_type = """type Menu = {
  id: string;
  name: string;
  slug: string;
  menuType: string;
  designConfig: any;
  templateId?: string | null;
  template?: { id: string; name: string; baseType: string } | null;
};"""
if old_type not in src:
    raise SystemExit('Patch A fehlgeschlagen: Menu-Typ nicht exakt gefunden')
src = src.replace(old_type, new_type, 1)

# Patch B: getActiveTemplate auf templateId umstellen
old_fn = """function getActiveTemplate(menu: Menu): string {
  try {
    const dc = menu.designConfig;
    return dc?.digital?.template || dc?.template || 'elegant';
  } catch {
    return 'elegant';
  }
}"""
new_fn = """function getActiveTemplate(menu: Menu): string {
  // Neue Logik: primaer ueber Template-Relation, Fallback auf Legacy-designConfig
  if (menu.template?.baseType) return menu.template.baseType;
  try {
    const dc = menu.designConfig;
    return dc?.digital?.template || dc?.template || 'elegant';
  } catch {
    return 'elegant';
  }
}"""
if old_fn not in src:
    raise SystemExit('Patch B fehlgeschlagen: getActiveTemplate nicht exakt gefunden')
src = src.replace(old_fn, new_fn, 1)

with open(path, 'w', encoding='utf-8') as f:
    f.write(src)
print('  OK: Werkstatt gepatcht')
PYEOF

echo ""
echo "[3/3] Build + Restart..."
npm run build 2>&1 | tail -25
pm2 restart menucard-pro
sleep 3

echo ""
echo "--- Test: /api/v1/menus liefert template ---"
curl -s http://localhost:3000/api/v1/menus -H "Cookie: $(cat /tmp/admin-cookie.txt 2>/dev/null)" | head -c 400
echo ""
echo ""
echo "================================================"
echo "FERTIG"
echo "================================================"
echo "Bitte /admin/design im Browser neu laden (Hard Reload, Strg+Shift+R)."
echo "Elegant sollte jetzt 9 Karten zeigen, Modern/Klassisch/Minimal je 0."
