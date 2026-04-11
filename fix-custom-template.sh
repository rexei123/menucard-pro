#!/bin/bash
# MenuCard Pro – Feature: Benutzerdefinierte Vorlage
# Wenn eine Standardvorlage geändert wird, zeigt der Editor automatisch
# "Benutzerdefiniert" als aktive Vorlage an. Klick auf Standard-Vorlage
# setzt alle Anpassungen zurück (mit Bestätigungsdialog).
# Datum: 11.04.2026

set -e
cd /var/www/menucard-pro

echo "=== Feature: Benutzerdefinierte Vorlage ==="

cp src/components/admin/design-editor.tsx src/components/admin/design-editor.tsx.bak3

echo "[1/2] Custom-Template-Logik einfügen..."

python3 << 'PYEOF'
filepath = 'src/components/admin/design-editor.tsx'
with open(filepath, 'r') as f:
    code = f.read()

# ── 1. hasCustomOverrides-Check nach den States einfügen ──
# Suche nach dem showResetDialog-State und füge danach die Berechnung ein

code = code.replace(
    "const [showResetDialog, setShowResetDialog] = useState(false);",
    """const [showResetDialog, setShowResetDialog] = useState(false);
  const [showTemplateSwitch, setShowTemplateSwitch] = useState<string | null>(null);

  // Prüfe ob benutzerdefinierte Anpassungen vorliegen
  const hasCustomOverrides = (() => {
    if (!overrides || typeof overrides !== 'object') return false;
    const keys = Object.keys(overrides).filter(k => k !== 'template');
    if (keys.length === 0) return false;
    // Prüfe ob die übrigen Keys tatsächlich Werte enthalten
    return keys.some(k => {
      const val = overrides[k];
      if (val === null || val === undefined) return false;
      if (typeof val === 'object' && Object.keys(val).length === 0) return false;
      return true;
    });
  })();"""
)

# ── 2. Template-Wechsel mit Warnung wenn Custom-Overrides existieren ──
# switchTemplate soll nur ausgeführt werden wenn keine Overrides da sind,
# sonst erst Bestätigung zeigen

old_switch = """  // Switch template
  const switchTemplate = useCallback(async (name: string) => {
    setTemplateName(name);
    setSaving(true);"""

new_switch = """  // Switch template – mit Warnung wenn benutzerdefinierte Anpassungen existieren
  const handleTemplateClick = useCallback((name: string) => {
    if (hasCustomOverrides) {
      setShowTemplateSwitch(name);
    } else {
      switchTemplate(name);
    }
  }, [hasCustomOverrides]);

  const switchTemplate = useCallback(async (name: string) => {
    setShowTemplateSwitch(null);
    setTemplateName(name);
    setSaving(true);"""

code = code.replace(old_switch, new_switch)

# ── 3. Template-Buttons: switchTemplate → handleTemplateClick ──
code = code.replace(
    "onClick={() => switchTemplate(tmpl.id)}",
    "onClick={() => handleTemplateClick(tmpl.id)}"
)

# ── 4. Aktive Template-Anzeige: Wenn Custom-Overrides, keinen Standard markieren ──
code = code.replace(
    "className={`rounded-lg border-2 p-3 text-left transition-all ${templateName === tmpl.id ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-gray-300'}`}",
    "className={`rounded-lg border-2 p-3 text-left transition-all ${!hasCustomOverrides && templateName === tmpl.id ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-gray-300'}`}"
)

# ── 5. "Benutzerdefiniert"-Karte nach den 4 Standard-Vorlagen einfügen ──
old_grid_end = """          </div>
          <SelectInput label="Stimmung\""""

new_grid_end = """          </div>
          {/* Benutzerdefiniert-Karte – erscheint nur wenn Anpassungen vorliegen */}
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
            </div>
          )}
          <SelectInput label="Stimmung\""""

code = code.replace(old_grid_end, new_grid_end)

# ── 6. Template-Wechsel-Bestätigungsdialog einfügen (nach dem Reset-Dialog) ──
code = code.replace(
    """onCancel={() => setShowResetDialog(false)}
        />""",
    """onCancel={() => setShowResetDialog(false)}
        />

        {/* Template Switch Confirmation Dialog */}
        <ConfirmDialog
          open={showTemplateSwitch !== null}
          title="Vorlage wechseln?"
          message="Sie haben individuelle Anpassungen vorgenommen. Beim Wechsel zu einer anderen Vorlage gehen alle Änderungen verloren und werden durch die Standard-Einstellungen der neuen Vorlage ersetzt."
          confirmLabel="Vorlage wechseln"
          onConfirm={() => showTemplateSwitch && switchTemplate(showTemplateSwitch)}
          onCancel={() => setShowTemplateSwitch(null)}
        />"""
)

with open(filepath, 'w') as f:
    f.write(code)

print('design-editor.tsx erfolgreich aktualisiert')

# Verification
with open(filepath, 'r') as f:
    final = f.read()

checks = [
    ('hasCustomOverrides', 'Custom-Override-Erkennung'),
    ('handleTemplateClick', 'Template-Klick-Handler'),
    ('showTemplateSwitch', 'Template-Wechsel-Dialog-State'),
    ('Benutzerdefiniert', 'Custom-Template-Karte'),
    ('Vorlage wechseln', 'Wechsel-Bestätigungsdialog'),
]
for keyword, label in checks:
    if keyword in final:
        print(f'  ✓ {label}')
    else:
        print(f'  ✗ {label} FEHLT!')
PYEOF

echo ""
echo "[2/2] Build + Restart..."
npm run build 2>&1 | tail -10
pm2 restart menucard-pro

echo ""
echo "=== Feature fertig: Benutzerdefinierte Vorlage ==="
echo ""
echo "So funktioniert es:"
echo "  1. Standard-Vorlage wählen → wird blau markiert"
echo "  2. Irgendeine Einstellung ändern → 'Benutzerdefiniert' erscheint"
echo "  3. Klick auf andere Vorlage → Warnung: Änderungen gehen verloren"
echo "  4. 'Zurücksetzen' → setzt auf Template-Standard zurück"
