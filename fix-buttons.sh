#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Fixing + Button and Translate Buttons ==="

python3 << 'PYEOF'
# Fix 1: Product list panel - simple + button without type dropdown
content = open('src/components/admin/product-list-panel.tsx').read()

content = content.replace(
    """const createProduct = async (type: string) => {
    setCreating(true);
    try {
      const res = await fetch('/api/v1/products', {
        method: 'POST', credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type }),
      });""",
    """const createProduct = async () => {
    setCreating(true);
    try {
      const res = await fetch('/api/v1/products', {
        method: 'POST', credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type: 'OTHER' }),
      });"""
)

# Replace dropdown with simple button
old_btn = """<div className="relative group">
              <button disabled={creating} className="flex h-6 w-6 items-center justify-center rounded-md text-white text-xs font-bold hover:opacity-80 disabled:opacity-50" style={{backgroundColor:'#8B6914'}}>+</button>
              <div className="absolute right-0 top-7 z-20 hidden group-hover:block rounded-lg border bg-white shadow-lg py-1 w-32">
                <button onClick={() => createProduct('WINE')} className="block w-full px-3 py-1.5 text-left text-xs hover:bg-gray-50">🍷 Wein</button>
                <button onClick={() => createProduct('DRINK')} className="block w-full px-3 py-1.5 text-left text-xs hover:bg-gray-50">🍸 Getränk</button>
                <button onClick={() => createProduct('FOOD')} className="block w-full px-3 py-1.5 text-left text-xs hover:bg-gray-50">🍽️ Speise</button>
              </div>
            </div>"""

new_btn = """<button onClick={() => createProduct()} disabled={creating} className="flex h-6 w-6 items-center justify-center rounded-md text-white text-xs font-bold hover:opacity-80 disabled:opacity-50" style={{backgroundColor:'#8B6914'}}>+</button>"""

content = content.replace(old_btn, new_btn)
open('src/components/admin/product-list-panel.tsx', 'w').write(content)
print('List panel fixed')

# Fix 2: Product editor - bigger translate buttons
content = open('src/components/admin/product-editor.tsx').read()

for field in ['name', 'shortDescription', 'longDescription', 'servingSuggestion']:
    old = f"""<button type="button" onClick={{() => translateDeToEn('{field}')}} disabled={{translating.has('{field}')}} className="text-[10px] text-gray-400 hover:text-amber-700 disabled:opacity-50">{{translating.has('{field}') ? '...' : 'DE→EN'}}</button>"""
    new = f"""<button type="button" onClick={{() => translateDeToEn('{field}')}} disabled={{translating.has('{field}')}} className="rounded-md px-2 py-0.5 text-[11px] font-medium border border-amber-300 text-amber-700 bg-amber-50 hover:bg-amber-100 disabled:opacity-50 transition-colors">{{translating.has('{field}') ? '⏳ Übersetze...' : '🔄 DE → EN'}}</button>"""
    content = content.replace(old, new)

open('src/components/admin/product-editor.tsx', 'w').write(content)
print('Editor fixed')
PYEOF

npm run build && pm2 restart menucard-pro
echo "=== Done ==="
