#!/bin/bash
# MenuCard Pro – Fix: API-Editor Mismatch bei Design-Config
# Problem: Editor liest "mergedConfig" aber API liefert "designConfig"
#          Editor sendet { digital: ... } aber API erwartet { designConfig: ... }
# Datum: 11.04.2026

set -e
cd /var/www/menucard-pro

echo "=== Fix: Design-Editor API Mismatch ==="

cp src/components/admin/design-editor.tsx src/components/admin/design-editor.tsx.bak2

echo "[1/2] Editor-Komponente fixen..."

python3 << 'PYEOF'
filepath = 'src/components/admin/design-editor.tsx'
with open(filepath, 'r') as f:
    code = f.read()

# ── Fix 1: GET-Response richtig parsen ──
# Alt: data.mergedConfig?.digital → Neu: data.designConfig?.digital
code = code.replace(
    "setConfig(data.mergedConfig?.digital || data.digital || data);",
    "setConfig(data.designConfig?.digital || data.digital || data);"
)
code = code.replace(
    "setTemplateName(data.templateName || data.mergedConfig?.digital?.template || 'elegant');",
    "setTemplateName(data.templateName || data.designConfig?.digital?.template || 'elegant');"
)

# ── Fix 2: PATCH – saveConfig muss designConfig wrappen ──
code = code.replace(
    "body: JSON.stringify({ digital: newOverrides }),",
    "body: JSON.stringify({ designConfig: { digital: newOverrides } }),"
)

# ── Fix 3: switchTemplate – gleicher Fix ──
code = code.replace(
    "body: JSON.stringify({ digital: { template: name } }),",
    "body: JSON.stringify({ designConfig: { digital: { template: name } } }),"
)

# ── Fix 4: switchTemplate – Reload-Parsing fixen ──
code = code.replace(
    "setConfig(reloaded.mergedConfig?.digital || reloaded.digital);",
    "setConfig(reloaded.designConfig?.digital || reloaded.digital);"
)
code = code.replace(
    "setOverrides(reloaded.savedOverrides?.digital || { template: name });",
    "setOverrides(reloaded.savedOverrides?.digital || {});"
)

# ── Fix 5: resetToDefaults – gleicher Fix ──
code = code.replace(
    '''body: JSON.stringify({ digital: { template: templateName } }),
      });
      // Reload full merged config from server''',
    '''body: JSON.stringify({ designConfig: { digital: { template: templateName } } }),
      });
      // Reload full merged config from server'''
)
code = code.replace(
    "setConfig(reloaded.mergedConfig?.digital || reloaded.digital);\n      setOverrides({ template: templateName });",
    "setConfig(reloaded.designConfig?.digital || reloaded.digital);\n      setOverrides({ template: templateName });"
)

with open(filepath, 'w') as f:
    f.write(code)

# Verify
with open(filepath, 'r') as f:
    final = f.read()

errors = []
if 'mergedConfig' in final:
    errors.append('WARNUNG: mergedConfig noch vorhanden!')
if 'JSON.stringify({ digital:' in final and 'designConfig' not in final.split('JSON.stringify({ digital:')[0][-50:]:
    errors.append('WARNUNG: Nicht-gewrapptes digital gefunden!')

if errors:
    for e in errors:
        print(e)
else:
    print('Alle Fixes erfolgreich angewendet')

# Zeige relevante Zeilen zur Kontrolle
import re
for keyword in ['designConfig', 'JSON.stringify', 'setConfig']:
    for i, line in enumerate(final.split('\n'), 1):
        if keyword in line and ('fetch' in line or 'setConfig' in line or 'stringify' in line):
            print(f'  L{i}: {line.strip()[:100]}')
PYEOF

echo ""
echo "[2/2] Build + Restart..."
npm run build 2>&1 | tail -10
pm2 restart menucard-pro

echo ""
echo "=== Fix fertig ==="
echo "Bitte im Browser Ctrl+Shift+R (Hard Refresh) drücken."
