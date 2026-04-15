#!/bin/bash
# MenuCard Pro – Fix: Reset-to-Default Button im Design-Editor
# Fügt einen "Auf Standard zurücksetzen"-Button mit Bestätigungsdialog hinzu
# Datum: 11.04.2026

set -e
cd /var/www/menucard-pro

echo "=== Fix: Reset-to-Default Button im Design-Editor ==="

# Backup
cp src/components/admin/design-editor.tsx src/components/admin/design-editor.tsx.bak

echo "[1/2] Bestätigungsdialog + Reset-Funktion + Button einfügen..."

python3 << 'PYEOF'
import re

filepath = 'src/components/admin/design-editor.tsx'
with open(filepath, 'r') as f:
    code = f.read()

# ── 1. Bestätigungsdialog-Komponente einfügen (nach der Toggle-Komponente) ──

confirm_dialog = '''
// ─── Confirm Dialog ───
function ConfirmDialog({ open, title, message, confirmLabel, onConfirm, onCancel }: {
  open: boolean; title: string; message: string; confirmLabel: string;
  onConfirm: () => void; onCancel: () => void;
}) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onCancel} />
      <div className="relative bg-white rounded-xl shadow-2xl max-w-md w-full mx-4 overflow-hidden">
        <div className="p-6">
          <div className="flex items-start gap-3">
            <div className="flex-shrink-0 w-10 h-10 rounded-full bg-amber-100 flex items-center justify-center">
              <svg className="h-5 w-5 text-amber-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5Z" />
              </svg>
            </div>
            <div className="flex-1">
              <h3 className="text-base font-semibold text-gray-900">{title}</h3>
              <p className="mt-2 text-sm text-gray-600 leading-relaxed">{message}</p>
            </div>
          </div>
        </div>
        <div className="flex justify-end gap-2 bg-gray-50 px-6 py-3">
          <button onClick={onCancel}
            className="rounded-lg px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 hover:bg-gray-50 transition-colors">
            Abbrechen
          </button>
          <button onClick={onConfirm}
            className="rounded-lg px-4 py-2 text-sm font-medium text-white bg-amber-500 hover:bg-amber-600 transition-colors">
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}'''

# Einfügen nach der Toggle-Komponente
code = code.replace(
    '// ─── Main Editor ───',
    confirm_dialog + '\n\n// ─── Main Editor ───'
)

# ── 2. State für den Dialog hinzufügen ──
# Nach dem previewMode-State
code = code.replace(
    "const iframeRef = useRef<HTMLIFrameElement>(null);",
    "const [showResetDialog, setShowResetDialog] = useState(false);\n  const iframeRef = useRef<HTMLIFrameElement>(null);"
)

# ── 3. resetToDefaults-Funktion einfügen (nach switchTemplate) ──

reset_function = '''
  // Reset all overrides to template defaults
  const resetToDefaults = useCallback(async () => {
    setSaving(true);
    setShowResetDialog(false);
    try {
      // Save only the template name, removing all other overrides
      await fetch(`/api/v1/menus/${menuId}/design`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ digital: { template: templateName } }),
      });
      // Reload full merged config from server
      const reload = await fetch(`/api/v1/menus/${menuId}/design`);
      const reloaded = await reload.json();
      setConfig(reloaded.mergedConfig?.digital || reloaded.digital);
      setOverrides({ template: templateName });
      setSaved(true);
      setTimeout(() => setSaved(false), 1500);
      if (iframeRef.current) iframeRef.current.src = iframeRef.current.src;
    } catch (e) {
      console.error('Reset failed', e);
    } finally {
      setSaving(false);
    }
  }, [menuId, templateName]);'''

code = code.replace(
    "  if (loading) return",
    reset_function + "\n\n  if (loading) return"
)

# ── 4. Reset-Button in die Status-Bar einfügen ──
# Ersetze die Status-Bar mit einer Version die den Reset-Button enthält

old_statusbar = '''        {/* Status Bar */}
        <div className="sticky top-0 z-10 flex items-center justify-between border-b bg-white px-4 py-2">
          <h2 className="text-sm font-semibold">Design-Editor</h2>
          <div className="flex items-center gap-2">
            {saving && <span className="text-xs text-gray-400">Speichert...</span>}
            {saved && <span className="text-xs text-green-500">Gespeichert ✓</span>}
          </div>
        </div>'''

new_statusbar = '''        {/* Status Bar */}
        <div className="sticky top-0 z-10 flex items-center justify-between border-b bg-white px-4 py-2">
          <h2 className="text-sm font-semibold">Design-Editor</h2>
          <div className="flex items-center gap-2">
            {saving && <span className="text-xs text-gray-400">Speichert...</span>}
            {saved && <span className="text-xs text-green-500">Gespeichert ✓</span>}
            <button onClick={() => setShowResetDialog(true)}
              className="rounded px-2.5 py-1 text-xs font-medium text-gray-500 border border-gray-300 hover:bg-gray-50 hover:text-gray-700 transition-colors"
              title="Alle Einstellungen auf Vorlage-Standard zurücksetzen">
              Zurücksetzen
            </button>
          </div>
        </div>

        {/* Reset Confirmation Dialog */}
        <ConfirmDialog
          open={showResetDialog}
          title="Design zurücksetzen?"
          message="Alle individuellen Anpassungen werden verworfen und die Einstellungen der aktuellen Vorlage wiederhergestellt. Dieser Vorgang kann nicht rückgängig gemacht werden."
          confirmLabel="Zurücksetzen"
          onConfirm={resetToDefaults}
          onCancel={() => setShowResetDialog(false)}
        />'''

code = code.replace(old_statusbar, new_statusbar)

with open(filepath, 'w') as f:
    f.write(code)

print('design-editor.tsx erfolgreich aktualisiert')
PYEOF

echo "  ✓ Reset-Button + Dialog eingefügt"

# === 2. Build ===
echo "[2/2] Build..."
npm run build 2>&1 | tail -20

echo ""
echo "=== Fix fertig: Reset-to-Default Button ==="
echo ""
echo "Änderungen:"
echo "  ✓ ConfirmDialog-Komponente (Modal mit Warnsymbol)"
echo "  ✓ 'Zurücksetzen'-Button in der Editor-Statusleiste"
echo "  ✓ Bestätigungsdialog mit Warnhinweis vor dem Reset"
echo "  ✓ Reset-Logik: löscht alle Overrides, behält nur Template"
echo "  ✓ Automatisches Neuladen der Vorschau nach Reset"
