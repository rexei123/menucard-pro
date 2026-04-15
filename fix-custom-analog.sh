#!/bin/bash
# Fix: Custom-Vorlagen im Analog-Editor wie im Digital-Editor
cd /var/www/menucard-pro

echo "=== Custom-Vorlagen Analog-Editor ==="

python3 << 'PYEOF'
with open("src/components/admin/analog-design-editor.tsx", "r") as f:
    content = f.read()

# 1. Custom-Template Datenstruktur ändern: baseTemplate speichern
content = content.replace(
    "const nc = [...customTemplates, { name, config: JSON.parse(JSON.stringify(config)) }];",
    "const nc = [...customTemplates, { name, overrides: JSON.parse(JSON.stringify(config)), baseTemplate: templateName }];"
)

# 2. loadCustomTemplate: baseTemplate nutzen
content = content.replace(
    "setTemplateName(tpl.config.template || 'elegant');",
    "setTemplateName(tpl.baseTemplate || tpl.config?.template || 'elegant');"
)
content = content.replace(
    "body: JSON.stringify({ designConfig: { analog: tpl.config } }),",
    "body: JSON.stringify({ designConfig: { analog: tpl.overrides || tpl.config } }),"
)
content = content.replace(
    "setConfig(data.designConfig?.analog || tpl.config);",
    "setConfig(data.designConfig?.analog || tpl.overrides || tpl.config);"
)

# 3. saveCustomName Funktion hinzufügen
old_toggle = "  const toggleSection = (key: string) =>"
new_toggle = """  const saveCustomName = (name: string) => {
    setCustomName(name);
    saveConfig({ ...config, customName: name });
  };

  const toggleSection = (key: string) =>"""
content = content.replace(old_toggle, new_toggle)

# 4. Ersetze die gesamte Template + Custom-Vorlagen UI
old_templates = """        {/* Templates */}
        <div className="grid grid-cols-2 gap-2">
          {TEMPLATES.map(t => (
            <button key={t.id} onClick={() => handleTemplateClick(t.id)}
              className={`p-3 rounded-lg border-2 text-left transition-all ${templateName === t.id && !hasCustomOverrides ? 'border-blue-600 bg-blue-50' : 'border-gray-200 hover:border-gray-300'}`}>
              <span className="text-lg">{t.icon}</span>
              <p className="font-medium text-sm mt-1">{t.name}</p>
              <p className="text-xs text-gray-500">{t.desc}</p>
            </button>
          ))}
        </div>

        {customTemplates.length > 0 && (
          <div className="grid grid-cols-2 gap-2">
            {customTemplates.map((ct, idx) => (
              <div key={idx} className="p-3 rounded-lg border-2 border-gray-200 hover:border-gray-300 relative group">
                <button onClick={() => loadCustomTemplate(idx)} className="text-left w-full">
                  <span className="text-lg">🎨</span>
                  <p className="font-medium text-sm mt-1 truncate">{ct.name}</p>
                  <p className="text-xs text-gray-500">Benutzerdefiniert</p>
                </button>
                <button onClick={() => deleteCustomTemplate(idx)}
                  className="absolute top-1 right-1 w-5 h-5 rounded-full bg-red-100 text-red-600 text-xs opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">×</button>
              </div>
            ))}
          </div>
        )}

        {hasCustomOverrides && customTemplates.length < 4 && (
          <div className="space-y-2">
            <input type="text" value={customName} onChange={e => setCustomName(e.target.value)}
              placeholder="Name der Vorlage..." maxLength={30} className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm" />
            <button onClick={saveAsCustomTemplate}
              className="w-full py-2.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium text-sm transition-colors">
              Als Vorlage speichern ({customTemplates.length}/4)
            </button>
          </div>
        )}

        {hasCustomOverrides && (
          <button onClick={() => setShowResetDialog(true)}
            className="w-full py-2 text-sm text-red-600 border border-red-200 rounded-lg hover:bg-red-50 transition-colors">
            Auf Standardwerte zurücksetzen
          </button>
        )}"""

new_templates = """        {/* Templates */}
        <div className="grid grid-cols-2 gap-2">
          {TEMPLATES.map(t => (
            <button key={t.id} onClick={() => handleTemplateClick(t.id)}
              className={`rounded-lg border-2 p-3 text-left transition-all ${!hasCustomOverrides && templateName === t.id ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-gray-300'}`}>
              <div className="text-lg mb-1">{t.icon}</div>
              <div className="text-sm font-medium">{t.name}</div>
              <div className="text-xs text-gray-500">{t.desc}</div>
            </button>
          ))}
        </div>

        {/* Gespeicherte benutzerdefinierte Vorlagen */}
        {customTemplates.length > 0 && (
          <div className="grid grid-cols-2 gap-2">
            {customTemplates.map((ct, idx) => (
              <div key={idx}
                className="rounded-lg border-2 border-gray-200 hover:border-blue-300 p-3 text-left transition-all cursor-pointer relative group"
                onClick={() => loadCustomTemplate(idx)}>
                <div className="text-lg mb-1">✏️</div>
                <div className="text-sm font-medium truncate">{ct.name}</div>
                <div className="text-xs text-gray-500 truncate">Basis: {ct.baseTemplate === 'elegant' ? 'Elegant' : ct.baseTemplate === 'modern' ? 'Modern' : ct.baseTemplate === 'classic' ? 'Klassisch' : 'Minimal'}</div>
                <button onClick={(e: React.MouseEvent) => { e.stopPropagation(); deleteCustomTemplate(idx); }}
                  className="absolute top-1 right-1 hidden group-hover:flex items-center justify-center w-5 h-5 rounded-full bg-red-100 text-red-500 text-xs hover:bg-red-200"
                  title="Vorlage löschen">✕</button>
              </div>
            ))}
          </div>
        )}

        {/* Aktive benutzerdefinierte Anpassungen */}
        {hasCustomOverrides && (
          <div className="rounded-lg border-2 border-blue-500 bg-blue-50 p-3">
            <div className="text-lg mb-1">✏️</div>
            <input
              type="text"
              value={customName}
              onChange={e => saveCustomName(e.target.value)}
              placeholder="Benutzerdefiniert"
              className="w-full text-sm font-medium text-blue-700 bg-transparent border-b border-transparent hover:border-blue-300 focus:border-blue-500 focus:outline-none py-0.5 placeholder-blue-400"
            />
            <div className="text-xs text-blue-500 mt-0.5">Basierend auf {templateName === 'elegant' ? 'Elegant' : templateName === 'modern' ? 'Modern' : templateName === 'classic' ? 'Klassisch' : 'Minimal'}</div>
            {customTemplates.length < 4 && (
              <button onClick={() => saveAsCustomTemplate(customName || 'Benutzerdefiniert ' + (customTemplates.length + 1))}
                className="mt-2 w-full rounded-lg py-1.5 text-xs font-medium text-white bg-blue-500 hover:bg-blue-600 transition-colors">
                Als Vorlage speichern
              </button>
            )}
          </div>
        )}

        {hasCustomOverrides && (
          <button onClick={() => setShowResetDialog(true)}
            className="w-full py-2 text-sm text-red-600 border border-red-200 rounded-lg hover:bg-red-50 transition-colors">
            Auf Standardwerte zurücksetzen
          </button>
        )}"""

if old_templates in content:
    content = content.replace(old_templates, new_templates)
    print("  ✓ Template-UI komplett ersetzt")
else:
    print("  ⚠ Template-UI nicht gefunden - prüfe manuell")

with open("src/components/admin/analog-design-editor.tsx", "w") as f:
    f.write(content)
PYEOF

echo "[2/2] Build..."
npm run build 2>&1 | tail -10

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo ""
  echo "  ✅ Custom-Vorlagen Fix LIVE!"
else
  echo ""
  echo "  ❌ Build fehlgeschlagen"
fi
