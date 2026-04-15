#!/bin/bash
# MenuCard Pro – Fix: Benutzerdefinierte Vorlage mit editierbarem Namen
# Datum: 12.04.2026

cd /var/www/menucard-pro

echo "=== Fix: Custom-Vorlage Name editierbar ==="

cp src/components/admin/design-editor.tsx src/components/admin/design-editor.tsx.bak4

echo "[1/2] Editierbaren Namen einbauen..."

python3 << 'PYEOF'
filepath = 'src/components/admin/design-editor.tsx'
with open(filepath, 'r') as f:
    code = f.read()

# ── 1. State für den Custom-Namen hinzufügen ──
code = code.replace(
    "const [showResetDialog, setShowResetDialog] = useState(false);",
    "const [showResetDialog, setShowResetDialog] = useState(false);\n  const [customName, setCustomName] = useState('');"
)

# ── 2. Custom-Name aus Config laden (im useEffect) ──
code = code.replace(
    "setTemplateName(data.templateName || data.designConfig?.digital?.template || 'elegant');",
    "setTemplateName(data.templateName || data.designConfig?.digital?.template || 'elegant');\n        setCustomName(data.savedOverrides?.digital?.customName || data.designConfig?.digital?.customName || '');"
)

# ── 3. Custom-Name speichern wenn geändert ──
# Funktion zum Speichern des Namens (mit Debounce über updateConfig)
save_name_fn = '''
  // Save custom template name
  const saveCustomName = useCallback((name: string) => {
    setCustomName(name);
    updateConfig('customName', name);
  }, [updateConfig]);
'''

code = code.replace(
    "  // Reset all overrides to template defaults",
    save_name_fn + "\n  // Reset all overrides to template defaults"
)

# ── 4. Custom-Name bei Reset zurücksetzen ──
code = code.replace(
    "setOverrides({ template: templateName });",
    "setOverrides({ template: templateName });\n      setCustomName('');"
)

# ── 5. Benutzerdefiniert-Karte durch editierbare Version ersetzen ──
old_card = '''          {/* Benutzerdefiniert-Karte – erscheint nur wenn Anpassungen vorliegen */}
          {hasCustomOverrides && (
            <div className="mt-2 rounded-lg border-2 border-blue-500 bg-blue-50 p-3 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="text-lg">✏️</span>
                <div>
                  <div className="text-sm font-medium text-blue-700">Benutzerdefiniert</div>
                  <div className="text-xs text-blue-500">Basierend auf {templateName === 'elegant' ? 'Elegant' : templateName === 'modern' ? 'Modern' : templateName === 'classic' ? 'Klassisch' : 'Minimal'}</div>
                </div>
              </div>
              <button onClick={() => setShowResetDialog(true)}
                className="text-xs text-blue-500 hover:text-blue-700 underline">
                Zurücksetzen
              </button>
            </div>'''

new_card = '''          {/* Benutzerdefiniert-Karte – erscheint nur wenn Anpassungen vorliegen */}
          {hasCustomOverrides && (
            <div className="mt-2 rounded-lg border-2 border-blue-500 bg-blue-50 p-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 flex-1">
                  <span className="text-lg">✏️</span>
                  <div className="flex-1">
                    <input
                      type="text"
                      value={customName}
                      onChange={e => saveCustomName(e.target.value)}
                      placeholder="Benutzerdefiniert"
                      className="w-full text-sm font-medium text-blue-700 bg-transparent border-b border-transparent hover:border-blue-300 focus:border-blue-500 focus:outline-none py-0.5 placeholder-blue-400"
                    />
                    <div className="text-xs text-blue-500">Basierend auf {templateName === 'elegant' ? 'Elegant' : templateName === 'modern' ? 'Modern' : templateName === 'classic' ? 'Klassisch' : 'Minimal'}</div>
                  </div>
                </div>
                <button onClick={() => setShowResetDialog(true)}
                  className="text-xs text-blue-500 hover:text-blue-700 underline ml-2 flex-shrink-0">
                  Zurücksetzen
                </button>
              </div>
            </div>'''

code = code.replace(old_card, new_card)

with open(filepath, 'w') as f:
    f.write(code)

# Verify
with open(filepath, 'r') as f:
    final = f.read()

checks = [
    ('customName', 'Custom-Name State'),
    ('saveCustomName', 'Save-Funktion'),
    ('placeholder="Benutzerdefiniert"', 'Editierbares Eingabefeld'),
]
for keyword, label in checks:
    if keyword in final:
        print(f'  ✓ {label}')
    else:
        print(f'  ✗ {label} FEHLT!')
PYEOF

echo ""
echo "[2/2] Build + Restart..."
npm run build 2>&1 | tail -5
pm2 restart menucard-pro

echo ""
echo "=== Fix fertig ==="
echo "Der Name der benutzerdefinierten Vorlage ist jetzt editierbar."
echo "Einfach in das Textfeld klicken und einen Namen eingeben."
