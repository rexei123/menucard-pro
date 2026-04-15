#!/bin/bash
# MenuCard Pro – Fix: Speicher-Button besser sichtbar, Zurücksetzen entfernen
# Datum: 12.04.2026

cd /var/www/menucard-pro

echo "=== Fix: Custom-Vorlage Button-Style ==="

cp src/components/admin/design-editor.tsx src/components/admin/design-editor.tsx.bak6

python3 << 'PYEOF'
filepath = 'src/components/admin/design-editor.tsx'
with open(filepath, 'r') as f:
    code = f.read()

# Ersetze den Button-Bereich in der Custom-Karte
old_buttons = '''              <div className="flex gap-2 mt-2">
                {customTemplates.length < 4 && (
                  <button onClick={() => saveAsCustomTemplate(customName || 'Benutzerdefiniert ' + (customTemplates.length + 1))}
                    className="text-xs text-blue-600 hover:text-blue-800 font-medium">
                    Als Vorlage speichern
                  </button>
                )}
                <button onClick={() => setShowResetDialog(true)}
                  className="text-xs text-gray-500 hover:text-gray-700">
                  Zurücksetzen
                </button>
              </div>'''

new_buttons = '''              {customTemplates.length < 4 && (
                <button onClick={() => saveAsCustomTemplate(customName || 'Benutzerdefiniert ' + (customTemplates.length + 1))}
                  className="mt-2 w-full rounded-lg py-1.5 text-xs font-medium text-white bg-blue-500 hover:bg-blue-600 transition-colors">
                  Als Vorlage speichern
                </button>
              )}'''

code = code.replace(old_buttons, new_buttons)

with open(filepath, 'w') as f:
    f.write(code)

print('  ✓ Speicher-Button: Volle Breite, blau, gut sichtbar')
print('  ✓ Zurücksetzen-Link aus Custom-Karte entfernt')
PYEOF

echo "[2/2] Build + Restart..."
npm run build 2>&1 | tail -5
pm2 restart menucard-pro

echo "=== Fertig ==="
