#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "Fix: Tab-Labels klarer + Badges aus Vorschau herausziehen"

python3 <<'PYEOF'
path = 'src/app/admin/design/page.tsx'
with open(path, 'r', encoding='utf-8') as f:
    src = f.read()

# --- Fix 1: Tab-Labels verdeutlichen ---
src = src.replace(
    "Aktiv ({activeCount})",
    "Aktive Vorlagen ({activeCount})"
)
src = src.replace(
    "Archiv ({archivedCount})",
    "Archiv ({archivedCount})"  # bleibt
)

# --- Fix 2: Badges aus der Vorschau in eine eigene Leiste oberhalb verschieben ---
# Alte Struktur: <div relative cursor-pointer onClick> ... TemplatePreview ... <absolute top-3 left-3 badges> ... <absolute top-3 right-3 count> ... </div>
# Neue Struktur:
#   <div relative>
#     <div className="flex items-center justify-between px-3 py-2" style={bg gray}> badges links ... count rechts </div>
#     <div cursor-pointer onClick><TemplatePreview/></div>
#   </div>

old_block = """      <div className="relative cursor-pointer" onClick={onToggle}>
        <TemplatePreview baseType={tpl.baseType} />
        <div className="absolute top-3 left-3 flex items-center gap-1.5">
          {isSystem && (
            <span className="flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider"
                  style={{ backgroundColor: 'rgba(0,0,0,0.55)', color: '#FFF' }}>
              <span className="material-symbols-outlined" style={{ fontSize: 12 }}>lock</span>
              System
            </span>
          )}
          {!isSystem && (
            <span className="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider"
                  style={{ backgroundColor: 'rgba(0,0,0,0.55)', color: '#FFF' }}>
              Eigene Vorlage
            </span>
          )}
          {isArchived && (
            <span className="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider"
                  style={{ backgroundColor: '#6B7280', color: '#FFF' }}>
              Archiviert
            </span>
          )}
        </div>
        {hasMenus && (
          <div className="absolute top-3 right-3 flex items-center gap-1 px-2.5 py-1 rounded-full"
               style={{ backgroundColor: '#DD3C71', color: '#FFF' }}>
            <span className="material-symbols-outlined" style={{ fontSize: 14 }}>check_circle</span>
            <span className="text-[10px] font-bold uppercase tracking-wider">
              {menuCount} {menuCount === 1 ? 'Karte' : 'Karten'}
            </span>
          </div>
        )}
      </div>"""

new_block = """      <div>
        {/* Metadaten-Leiste OBERHALB der Vorschau */}
        <div className="flex items-center justify-between px-3 py-2"
             style={{ backgroundColor: '#F9FAFB', borderBottom: '1px solid #F3F3F6' }}>
          <div className="flex items-center gap-1.5">
            {isSystem && (
              <span className="flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider"
                    style={{ backgroundColor: '#E5E7EB', color: '#4B5563' }}>
                <span className="material-symbols-outlined" style={{ fontSize: 12 }}>lock</span>
                System
              </span>
            )}
            {!isSystem && (
              <span className="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider"
                    style={{ backgroundColor: '#FDF2F5', color: '#DD3C71' }}>
                Eigene Vorlage
              </span>
            )}
            {isArchived && (
              <span className="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider"
                    style={{ backgroundColor: '#6B7280', color: '#FFF' }}>
                Archiviert
              </span>
            )}
          </div>
          {hasMenus && (
            <div className="flex items-center gap-1 px-2 py-0.5 rounded-full"
                 style={{ backgroundColor: '#DD3C71', color: '#FFF' }}>
              <span className="material-symbols-outlined" style={{ fontSize: 12 }}>check_circle</span>
              <span className="text-[10px] font-bold uppercase tracking-wider">
                {menuCount} {menuCount === 1 ? 'Karte' : 'Karten'}
              </span>
            </div>
          )}
        </div>
        {/* Vorschau clickable */}
        <div className="cursor-pointer" onClick={onToggle}>
          <TemplatePreview baseType={tpl.baseType} />
        </div>
      </div>"""

if old_block not in src:
    raise SystemExit('Patch fehlgeschlagen: Badge-Block nicht exakt gefunden')
src = src.replace(old_block, new_block, 1)

with open(path, 'w', encoding='utf-8') as f:
    f.write(src)
print('  OK: Tab-Label + Badge-Position angepasst')
PYEOF

echo ""
echo "Build..."
npm run build 2>&1 | tail -15

echo ""
pm2 restart menucard-pro
sleep 2
echo ""
echo "FERTIG. Bitte /admin/design mit Strg+Shift+R neu laden."
