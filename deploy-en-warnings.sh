#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Adding EN translation warnings ==="

python3 << 'PYEOF'
content = open('src/components/admin/product-editor.tsx').read()

# 1. Add deChanged state
content = content.replace(
    "const [dirty, setDirty] = useState(false);",
    "const [dirty, setDirty] = useState(false);\n  const [deChanged, setDeChanged] = useState<Set<string>>(new Set());"
)

# 2. Upgrade setTrans + add helpers
content = content.replace(
    """const setTrans = (lang: string, field: string, value: string) => {
    setData(p => {
      const exists = p.translations.find(t => t.languageCode === lang);
      if (exists) {
        return { ...p, translations: p.translations.map(t => t.languageCode === lang ? { ...t, [field]: value || null } : t) };
      }
      return { ...p, translations: [...p.translations, { languageCode: lang, name: '', shortDescription: null, longDescription: null, servingSuggestion: null, [field]: value || null }] };
    });
    setDirty(true);
  };""",
    """const setTrans = (lang: string, field: string, value: string) => {
    setData(p => {
      const exists = p.translations.find(t => t.languageCode === lang);
      if (exists) {
        return { ...p, translations: p.translations.map(t => t.languageCode === lang ? { ...t, [field]: value || null } : t) };
      }
      return { ...p, translations: [...p.translations, { languageCode: lang, name: '', shortDescription: null, longDescription: null, servingSuggestion: null, [field]: value || null }] };
    });
    if (lang === 'de') setDeChanged(prev => new Set(prev).add(field));
    setDirty(true);
  };

  const copyDeToEn = (field: string) => {
    const deVal = (data.translations.find(t => t.languageCode === 'de') as any)?.[field] || '';
    setTrans('en', field, deVal);
    setDeChanged(prev => { const n = new Set(prev); n.delete(field); return n; });
  };"""
)

# 3. Clear deChanged on save
content = content.replace(
    "if (res.ok) { setSaved(true); setDirty(false); setTimeout(() => setSaved(false), 2000); }",
    "if (res.ok) { setSaved(true); setDirty(false); setDeChanged(new Set()); setTimeout(() => setSaved(false), 2000); }"
)

# 4. Replace EN labels with warning + copy button
for old_label, field in [
    ('Name', 'name'),
    ('Short Description', 'shortDescription'),
    ('Long Description', 'longDescription'),
    ('Serving Suggestion', 'servingSuggestion'),
]:
    old = f'<label className="block text-[10px] uppercase tracking-wider text-gray-400 mb-1">{old_label}</label>'
    new = f'<div className="flex items-center justify-between mb-1"><label className="text-[10px] uppercase tracking-wider text-gray-400">{old_label}</label><div className="flex items-center gap-1">{{deChanged.has(\'{field}\') && <span className="text-[10px] text-amber-600">⚠️ DE geändert</span>}}<button type="button" onClick={{() => copyDeToEn(\'{field}\')}} className="text-[10px] text-gray-400 hover:text-amber-700">DE→EN</button></div></div>'
    # Only replace in the EN section (second occurrence)
    parts = content.split(old)
    if len(parts) >= 3:
        content = parts[0] + old + parts[1] + new + parts[2]
    elif len(parts) == 2:
        content = parts[0] + new + parts[1]

open('src/components/admin/product-editor.tsx', 'w').write(content)
print('Done!')
PYEOF

npm run build && pm2 restart menucard-pro
echo "=== Deployed ==="
