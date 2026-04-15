#!/bin/bash
# MenuCard Pro – Custom-Vorlagen v2
# 1. PATCH-API: Deep-Merge statt Überschreiben
# 2. Custom-Vorlagen im gleichen Kartenformat wie Standardvorlagen
# 3. Bis zu 4 benutzerdefinierte Vorlagen speicherbar
# Datum: 12.04.2026

cd /var/www/menucard-pro

echo "=== Custom-Vorlagen v2 ==="

cp src/components/admin/design-editor.tsx src/components/admin/design-editor.tsx.bak5
cp src/app/api/v1/menus/\[id\]/design/route.ts src/app/api/v1/menus/\[id\]/design/route.ts.bak

# ═══════════════════════════════════════════
echo "[1/3] PATCH-API: Deep-Merge einbauen..."
# ═══════════════════════════════════════════

cat > src/app/api/v1/menus/\[id\]/design/route.ts << 'ENDOFFILE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import { getTemplate, mergeConfig } from '@/lib/design-templates';

// Deep merge helper
function deepMerge(target: any, source: any): any {
  if (!source) return target;
  if (!target) return source;
  const result = { ...target };
  for (const key of Object.keys(source)) {
    if (source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])) {
      result[key] = deepMerge(target[key] || {}, source[key]);
    } else {
      result[key] = source[key];
    }
  }
  return result;
}

// GET /api/v1/menus/[id]/design
export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const menu = await prisma.menu.findUnique({
    where: { id: params.id },
    select: { id: true, designConfig: true },
  });
  if (!menu) return NextResponse.json({ error: 'Menu not found' }, { status: 404 });

  const saved = menu.designConfig as any;
  const templateName = saved?.digital?.template || 'elegant';
  const template = getTemplate(templateName);
  const merged = {
    digital: mergeConfig(template.digital, saved?.digital),
    analog: mergeConfig(template.analog, saved?.analog),
  };

  return NextResponse.json({
    designConfig: merged,
    savedOverrides: saved,
    templateName,
    customTemplates: saved?.customTemplates || [],
  });
}

// PATCH /api/v1/menus/[id]/design
export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await req.json();
  const { designConfig } = body;
  if (!designConfig) return NextResponse.json({ error: 'designConfig required' }, { status: 400 });

  // Lade bestehende Config und merge
  const existing = await prisma.menu.findUnique({
    where: { id: params.id },
    select: { designConfig: true },
  });

  const existingConfig = (existing?.designConfig as any) || {};
  const mergedConfig = deepMerge(existingConfig, designConfig);

  const updated = await prisma.menu.update({
    where: { id: params.id },
    data: { designConfig: mergedConfig },
    select: { id: true, designConfig: true },
  });

  return NextResponse.json({ success: true, designConfig: updated.designConfig });
}
ENDOFFILE

echo "  ✓ API mit Deep-Merge aktualisiert"

# ═══════════════════════════════════════════
echo "[2/3] Design-Editor: Custom-Vorlagen im Kartenformat + max 4 Slots..."
# ═══════════════════════════════════════════

python3 << 'PYEOF'
filepath = 'src/components/admin/design-editor.tsx'
with open(filepath, 'r') as f:
    code = f.read()

# ── 1. States für Custom-Templates erweitern ──
# Ersetze einzelnen customName durch customTemplates Array
code = code.replace(
    "const [showResetDialog, setShowResetDialog] = useState(false);\n  const [customName, setCustomName] = useState('');",
    """const [showResetDialog, setShowResetDialog] = useState(false);
  const [customName, setCustomName] = useState('');
  const [customTemplates, setCustomTemplates] = useState<Array<{name: string; overrides: any; baseTemplate: string}>>([]);"""
)

# ── 2. Custom-Templates aus API laden ──
code = code.replace(
    "setCustomName(data.savedOverrides?.digital?.customName || data.designConfig?.digital?.customName || '');",
    """setCustomName(data.savedOverrides?.digital?.customName || data.designConfig?.digital?.customName || '');
        setCustomTemplates(data.customTemplates || []);"""
)

# ── 3. Funktion zum Speichern als Custom-Template ──
save_custom_fn = '''
  // Save current overrides as a custom template
  const saveAsCustomTemplate = useCallback(async (name: string) => {
    if (customTemplates.length >= 4) return;
    const newTemplate = {
      name: name || 'Benutzerdefiniert ' + (customTemplates.length + 1),
      overrides: JSON.parse(JSON.stringify(overrides)),
      baseTemplate: templateName,
    };
    const updated = [...customTemplates, newTemplate];
    setCustomTemplates(updated);
    // Save to DB
    try {
      await fetch(`/api/v1/menus/${menuId}/design`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ designConfig: { customTemplates: updated } }),
      });
      setSaved(true);
      setTimeout(() => setSaved(false), 1500);
    } catch (e) {
      console.error('Save custom template failed', e);
    }
  }, [customTemplates, overrides, templateName, menuId]);

  // Load a custom template
  const loadCustomTemplate = useCallback(async (index: number) => {
    const tmpl = customTemplates[index];
    if (!tmpl) return;
    setSaving(true);
    try {
      await fetch(`/api/v1/menus/${menuId}/design`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ designConfig: { digital: { ...tmpl.overrides, template: tmpl.baseTemplate } } }),
      });
      const reload = await fetch(`/api/v1/menus/${menuId}/design`);
      const reloaded = await reload.json();
      setConfig(reloaded.designConfig?.digital || reloaded.digital);
      setOverrides(tmpl.overrides);
      setTemplateName(tmpl.baseTemplate);
      setCustomName(tmpl.name);
      setSaved(true);
      setTimeout(() => setSaved(false), 1500);
      if (iframeRef.current) iframeRef.current.src = iframeRef.current.src;
    } catch (e) {
      console.error(e);
    } finally {
      setSaving(false);
    }
  }, [customTemplates, menuId]);

  // Delete a custom template
  const deleteCustomTemplate = useCallback(async (index: number) => {
    const updated = customTemplates.filter((_, i) => i !== index);
    setCustomTemplates(updated);
    try {
      await fetch(`/api/v1/menus/${menuId}/design`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ designConfig: { customTemplates: updated } }),
      });
    } catch (e) {
      console.error(e);
    }
  }, [customTemplates, menuId]);
'''

code = code.replace(
    "\n  // Save custom template name",
    save_custom_fn + "\n  // Save custom template name"
)

# ── 4. Benutzerdefiniert-Karte durch Kartenformat ersetzen ──
old_card = '''          {/* Benutzerdefiniert-Karte – erscheint nur wenn Anpassungen vorliegen */}
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

base_label = "templateName === 'elegant' ? 'Elegant' : templateName === 'modern' ? 'Modern' : templateName === 'classic' ? 'Klassisch' : 'Minimal'"

new_card = '''          {/* Gespeicherte benutzerdefinierte Vorlagen */}
          {customTemplates.length > 0 && (
            <div className="grid grid-cols-2 gap-2 mt-2">
              {customTemplates.map((ct, idx) => (
                <div key={idx}
                  className="rounded-lg border-2 border-gray-200 hover:border-blue-300 p-3 text-left transition-all cursor-pointer relative group"
                  onClick={() => loadCustomTemplate(idx)}>
                  <div className="text-lg mb-1">✏️</div>
                  <div className="text-sm font-medium truncate">{ct.name}</div>
                  <div className="text-xs text-gray-500 truncate">Basis: {ct.baseTemplate === 'elegant' ? 'Elegant' : ct.baseTemplate === 'modern' ? 'Modern' : ct.baseTemplate === 'classic' ? 'Klassisch' : 'Minimal'}</div>
                  <button onClick={e => { e.stopPropagation(); deleteCustomTemplate(idx); }}
                    className="absolute top-1 right-1 hidden group-hover:flex items-center justify-center w-5 h-5 rounded-full bg-red-100 text-red-500 text-xs hover:bg-red-200"
                    title="Vorlage löschen">✕</button>
                </div>
              ))}
            </div>
          )}

          {/* Aktive benutzerdefinierte Anpassungen */}
          {hasCustomOverrides && (
            <div className="rounded-lg border-2 border-blue-500 bg-blue-50 p-3 mt-2">
              <div className="text-lg mb-1">✏️</div>
              <input
                type="text"
                value={customName}
                onChange={e => saveCustomName(e.target.value)}
                placeholder="Benutzerdefiniert"
                className="w-full text-sm font-medium text-blue-700 bg-transparent border-b border-transparent hover:border-blue-300 focus:border-blue-500 focus:outline-none py-0.5 placeholder-blue-400"
              />
              <div className="text-xs text-blue-500 mt-0.5">Basierend auf {''' + base_label + '''}</div>
              <div className="flex gap-2 mt-2">
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
              </div>
            </div>'''

code = code.replace(old_card, new_card)

with open(filepath, 'w') as f:
    f.write(code)

# Verify
with open(filepath, 'r') as f:
    final = f.read()

checks = [
    ('customTemplates', 'Custom-Templates Array'),
    ('saveAsCustomTemplate', 'Speichern-als-Vorlage'),
    ('loadCustomTemplate', 'Vorlage laden'),
    ('deleteCustomTemplate', 'Vorlage löschen'),
    ('Als Vorlage speichern', 'Speicher-Button'),
    ('customTemplates.length < 4', 'Max 4 Limit'),
    ('grid grid-cols-2', 'Kartenformat-Grid'),
]
for keyword, label in checks:
    if keyword in final:
        print(f'  ✓ {label}')
    else:
        print(f'  ✗ {label} FEHLT!')
PYEOF

echo ""
echo "[3/3] Build + Restart..."
npm run build 2>&1 | tail -5
pm2 restart menucard-pro

echo ""
echo "=== Custom-Vorlagen v2 fertig ==="
echo ""
echo "Features:"
echo "  ✓ PATCH-API: Deep-Merge (bestehende Config bleibt erhalten)"
echo "  ✓ Benutzerdefinierte Vorlage im gleichen Kartenformat"
echo "  ✓ Name editierbar (wird dauerhaft gespeichert)"
echo "  ✓ 'Als Vorlage speichern' – speichert aktuelle Einstellungen"
echo "  ✓ Bis zu 4 Custom-Vorlagen pro Karte"
echo "  ✓ Gespeicherte Vorlagen als Karten anklickbar"
echo "  ✓ Vorlagen löschbar (Hover → ✕)"
