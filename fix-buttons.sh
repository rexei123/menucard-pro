#!/bin/bash
cd /var/www/menucard-pro

echo "=== Websuche Buttons Fix ==="

python3 << 'PYEOF'
with open('src/components/admin/media-archive.tsx', 'r') as f:
    content = f.read()

# Finde den Quellen-Block (radio buttons) und ersetze mit großen Buttons
old_block = """      <div className="flex flex-wrap gap-4 mb-6">
        <label className="flex items-center gap-2 text-sm cursor-pointer">
          <input type="radio" name="wsource" checked={source === 'wikimedia'}
            onChange={() => setSource('wikimedia')} className="accent-amber-600" />
          <span>Wikimedia Commons <span className="text-xs text-green-600">(frei)</span></span>
        </label>
        {availableSources.filter((s: any) => s.id !== 'wikimedia').map((s: any) => (
          <label key={s.id} className={'flex items-center gap-2 text-sm cursor-pointer ' + (!s.available ? 'opacity-40' : '')}>
            <input type="radio" name="wsource" checked={source === s.id}
              onChange={() => setSource(s.id)} className="accent-amber-600" disabled={!s.available} />
            <span>{s.name} {!s.available && <span className="text-xs text-gray-400">(Key fehlt)</span>}</span>
          </label>
        ))}
      </div>"""

new_block = """      <div className="flex flex-wrap gap-2 mb-6">
        {[
          { id: 'wikimedia', label: 'Wikimedia Commons', free: true },
          ...availableSources.filter((s: any) => s.id !== 'wikimedia'),
        ].map((s: any) => (
          <button key={s.id || s.label} type="button"
            onClick={() => setSource(s.id)}
            className={'px-4 py-2.5 rounded-lg text-sm font-medium border-2 transition-all ' +
              (source === s.id
                ? 'border-amber-500 bg-amber-50 text-amber-700'
                : s.available || s.free
                  ? 'border-gray-200 bg-white text-gray-600 hover:border-amber-300 hover:bg-amber-50/50'
                  : 'border-gray-100 bg-gray-50 text-gray-400 hover:border-amber-200 hover:bg-amber-50/30 cursor-pointer')
            }>
            {s.label || s.name}
            {(s.free) && <span className="ml-1.5 text-xs text-green-600">(frei)</span>}
            {(!s.available && !s.free) && <span className="ml-1.5 text-xs text-gray-400">(Key fehlt)</span>}
          </button>
        ))}
      </div>"""

if old_block in content:
    content = content.replace(old_block, new_block)
    print("OK - Buttons ersetzt")
else:
    # Fallback: Suche flexibler
    import re
    pattern = r'<div className="flex flex-wrap gap-4 mb-6">.*?</div>\s*</div>'
    match = re.search(pattern, content, re.DOTALL)
    if match:
        content = content[:match.start()] + new_block + content[match.end():]
        print("OK - Buttons ersetzt (regex)")
    else:
        print("FEHLER - Block nicht gefunden")

with open('src/components/admin/media-archive.tsx', 'w') as f:
    f.write(content)
PYEOF

npm run build 2>&1 | tail -3

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo "✅ Buttons gefixt!"
else
  echo "❌ Build fehlgeschlagen"
fi
