#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Translate Button Color States ==="

python3 << 'PYEOF'
content = open('src/components/admin/product-editor.tsx').read()

# 1. Add translated state tracking
content = content.replace(
    "const [deChanged, setDeChanged] = useState<Set<string>>(new Set());",
    "const [deChanged, setDeChanged] = useState<Set<string>>(new Set());\n  const [enSynced, setEnSynced] = useState<Set<string>>(new Set());"
)

# 2. When DE changes, remove from synced
content = content.replace(
    "if (lang === 'de') setDeChanged(prev => new Set(prev).add(field));",
    "if (lang === 'de') { setDeChanged(prev => new Set(prev).add(field)); setEnSynced(prev => { const n = new Set(prev); n.delete(field); return n; }); }"
)

# 3. When EN is manually edited, mark as synced if deChanged
content = content.replace(
    "if (lang === 'de') { setDeChanged(prev => new Set(prev).add(field)); setEnSynced(prev => { const n = new Set(prev); n.delete(field); return n; }); }",
    "if (lang === 'de') { setDeChanged(prev => new Set(prev).add(field)); setEnSynced(prev => { const n = new Set(prev); n.delete(field); return n; }); }\n    if (lang === 'en') { setDeChanged(prev => { const n = new Set(prev); n.delete(field); return n; }); setEnSynced(prev => new Set(prev).add(field)); }"
)

# 4. After successful translation, mark as synced and clear deChanged
content = content.replace(
    """setTrans('en', field, translated);
        setDeChanged(prev => { const n = new Set(prev); n.delete(field); return n; });""",
    """setTrans('en', field, translated);
        setDeChanged(prev => { const n = new Set(prev); n.delete(field); return n; });
        setEnSynced(prev => new Set(prev).add(field));"""
)

# 5. Clear states on save
content = content.replace(
    "if (res.ok) { setSaved(true); setDirty(false); setDeChanged(new Set()); setTimeout(() => setSaved(false), 2000); }",
    "if (res.ok) { setSaved(true); setDirty(false); setDeChanged(new Set()); setEnSynced(new Set()); setTimeout(() => setSaved(false), 2000); }"
)

# 6. Replace button styles with dynamic colors
for field in ['name', 'shortDescription', 'longDescription', 'servingSuggestion']:
    old = f"""<button type="button" onClick={{() => translateDeToEn('{field}')}} disabled={{translating.has('{field}')}} className="rounded-md px-2 py-0.5 text-[11px] font-medium border border-amber-300 text-amber-700 bg-amber-50 hover:bg-amber-100 disabled:opacity-50 transition-colors">{{translating.has('{field}') ? '⏳ Übersetze...' : '🔄 DE → EN'}}</button>"""
    new = f"""<button type="button" onClick={{() => translateDeToEn('{field}')}} disabled={{translating.has('{field}')}} className={{`rounded-md px-2 py-0.5 text-[11px] font-medium border transition-colors disabled:opacity-50 ${{enSynced.has('{field}') && !deChanged.has('{field}') ? 'border-green-300 text-green-700 bg-green-50 hover:bg-green-100' : deChanged.has('{field}') ? 'border-amber-300 text-amber-700 bg-amber-50 hover:bg-amber-100' : 'border-gray-300 text-gray-500 bg-gray-50 hover:bg-gray-100'}}`}}>{{translating.has('{field}') ? '⏳ Übersetze...' : enSynced.has('{field}') && !deChanged.has('{field}') ? '✅ Übersetzt' : '🔄 DE → EN'}}</button>"""
    content = content.replace(old, new)

open('src/components/admin/product-editor.tsx', 'w').write(content)
print('Done!')
PYEOF

npm run build && pm2 restart menucard-pro
echo "=== Done ==="
