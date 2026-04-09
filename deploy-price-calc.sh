#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Adding Price Calculation Logic ==="

python3 << 'PYEOF'
content = open('src/components/admin/product-editor.tsx').read()

# Replace the entire price section with new calculation UI
old_price_section = """<section className="rounded-xl border bg-white p-5 shadow-sm">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-sm font-semibold text-gray-500">Preise</h2>
          <button onClick={addPrice} className="text-xs font-medium px-3 py-1.5 rounded-lg text-white" style={{backgroundColor:'#8B6914'}}>+ Preis hinzufügen</button>
        </div>
        <div className="space-y-2">
          {data.prices.map((p, i) => (
            <div key={`price-${i}`} className="flex items-end gap-2 rounded-lg bg-gray-50 p-3">
              <div className="flex-1">
                <label className="block text-[10px] uppercase tracking-wider text-gray-400 mb-1">Füllmenge</label>
                <select value={p.fillQuantityId} onChange={e => { const fq = options.fillQuantities.find(f => f.id === e.target.value); setPrice(i, 'fillQuantityId', e.target.value); if (fq) setPrice(i, 'fillLabel', fq.label); }} className="w-full rounded-lg border px-2 py-1.5 text-sm outline-none">
                  {options.fillQuantities.map(fq => <option key={fq.id} value={fq.id}>{fq.label}</option>)}
                </select>
              </div>
              <div className="flex-1">
                <label className="block text-[10px] uppercase tracking-wider text-gray-400 mb-1">Preisebene</label>
                <select value={p.priceLevelId} onChange={e => { const pl = options.priceLevels.find(l => l.id === e.target.value); setPrice(i, 'priceLevelId', e.target.value); if (pl) setPrice(i, 'levelName', pl.name); }} className="w-full rounded-lg border px-2 py-1.5 text-sm outline-none">
                  {options.priceLevels.map(pl => <option key={pl.id} value={pl.id}>{pl.name}</option>)}
                </select>
              </div>
              <div className="w-24">
                <label className="block text-[10px] uppercase tracking-wider text-gray-400 mb-1">VK €</label>
                <input type="number" step="0.01" value={p.price} onChange={e => setPrice(i, 'price', Number(e.target.value))} className="w-full rounded-lg border px-2 py-1.5 text-sm outline-none text-right font-semibold" />
              </div>
              <div className="w-24">
                <label className="block text-[10px] uppercase tracking-wider text-gray-400 mb-1">EK €</label>
                <input type="number" step="0.01" value={p.purchasePrice ?? ''} onChange={e => setPrice(i, 'purchasePrice', e.target.value ? Number(e.target.value) : null)} className="w-full rounded-lg border px-2 py-1.5 text-sm outline-none text-right" />
              </div>
              <button onClick={() => removePrice(i)} className="text-red-400 hover:text-red-600 p-1.5 mb-0.5">✕</button>
            </div>
          ))}
          {data.prices.length === 0 && <p className="text-sm text-gray-400 text-center py-4">Keine Preise definiert</p>}
        </div>
      </section>"""

new_price_section = """<section className="rounded-xl border bg-white p-5 shadow-sm">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-sm font-semibold text-gray-500">Preise & Kalkulation</h2>
          <button onClick={addPrice} className="text-xs font-medium px-3 py-1.5 rounded-lg text-white" style={{backgroundColor:'#8B6914'}}>+ Preis hinzufügen</button>
        </div>
        <div className="space-y-3">
          {data.prices.map((p, i) => {
            const ek = p.purchasePrice ?? 0;
            const fix = p.fixedMarkup ?? 0;
            const pct = p.percentMarkup ?? 0;
            const hasCalc = ek > 0 && (fix > 0 || pct > 0);
            const calcVK = hasCalc ? (ek + fix) * (1 + pct / 100) : null;
            const marge = ek > 0 && p.price > 0 ? ((p.price - ek) / p.price * 100) : null;
            return (
            <div key={`price-${i}`} className="rounded-lg border bg-gray-50 p-3">
              <div className="flex items-end gap-2 mb-2">
                <div className="flex-1">
                  <label className="block text-[10px] uppercase tracking-wider text-gray-400 mb-1">Füllmenge</label>
                  <select value={p.fillQuantityId} onChange={e => { const fq = options.fillQuantities.find(f => f.id === e.target.value); setPrice(i, 'fillQuantityId', e.target.value); if (fq) setPrice(i, 'fillLabel', fq.label); }} className="w-full rounded-lg border px-2 py-1.5 text-sm outline-none bg-white">
                    {options.fillQuantities.map(fq => <option key={fq.id} value={fq.id}>{fq.label}</option>)}
                  </select>
                </div>
                <div className="flex-1">
                  <label className="block text-[10px] uppercase tracking-wider text-gray-400 mb-1">Preisebene</label>
                  <select value={p.priceLevelId} onChange={e => { const pl = options.priceLevels.find(l => l.id === e.target.value); setPrice(i, 'priceLevelId', e.target.value); if (pl) setPrice(i, 'levelName', pl.name); }} className="w-full rounded-lg border px-2 py-1.5 text-sm outline-none bg-white">
                    {options.priceLevels.map(pl => <option key={pl.id} value={pl.id}>{pl.name}</option>)}
                  </select>
                </div>
                <button onClick={() => removePrice(i)} className="text-red-400 hover:text-red-600 p-1.5 mb-0.5" title="Preis entfernen">✕</button>
              </div>
              <div className="flex items-end gap-2">
                <div className="w-[88px]">
                  <label className="block text-[10px] uppercase tracking-wider text-gray-400 mb-1">EK €</label>
                  <input type="number" step="0.01" value={p.purchasePrice ?? ''} onChange={e => {
                    const newEK = e.target.value ? Number(e.target.value) : null;
                    setPrice(i, 'purchasePrice', newEK);
                    if (newEK && (p.fixedMarkup || p.percentMarkup)) {
                      const newVK = (newEK + (p.fixedMarkup ?? 0)) * (1 + (p.percentMarkup ?? 0) / 100);
                      setPrice(i, 'price', Math.round(newVK * 10) / 10);
                    }
                  }} className="w-full rounded-lg border px-2 py-1.5 text-sm outline-none text-right bg-white" placeholder="0.00" />
                </div>
                <div className="w-[72px]">
                  <label className="block text-[10px] uppercase tracking-wider text-gray-400 mb-1">+ Fix €</label>
                  <input type="number" step="0.01" value={p.fixedMarkup ?? ''} onChange={e => {
                    const val = e.target.value ? Number(e.target.value) : null;
                    setPrice(i, 'fixedMarkup', val);
                    if (p.purchasePrice && val !== null) {
                      const newVK = (p.purchasePrice + val) * (1 + (p.percentMarkup ?? 0) / 100);
                      setPrice(i, 'price', Math.round(newVK * 10) / 10);
                    }
                  }} className="w-full rounded-lg border px-2 py-1.5 text-sm outline-none text-right bg-white" placeholder="0" />
                </div>
                <div className="w-[72px]">
                  <label className="block text-[10px] uppercase tracking-wider text-gray-400 mb-1">× Aufschlag %</label>
                  <input type="number" step="1" value={p.percentMarkup ?? ''} onChange={e => {
                    const val = e.target.value ? Number(e.target.value) : null;
                    setPrice(i, 'percentMarkup', val);
                    if (p.purchasePrice && val !== null) {
                      const newVK = (p.purchasePrice + (p.fixedMarkup ?? 0)) * (1 + val / 100);
                      setPrice(i, 'price', Math.round(newVK * 10) / 10);
                    }
                  }} className="w-full rounded-lg border px-2 py-1.5 text-sm outline-none text-right bg-white" placeholder="0" />
                </div>
                <div className="text-center px-1 pb-1.5 text-gray-400">=</div>
                <div className="w-[96px]">
                  <label className="block text-[10px] uppercase tracking-wider text-gray-400 mb-1">VK €</label>
                  <input type="number" step="0.01" value={p.price} onChange={e => setPrice(i, 'price', Number(e.target.value))} className="w-full rounded-lg border px-2 py-1.5 text-sm outline-none text-right font-bold bg-white" />
                </div>
                {marge !== null && (
                  <div className="pb-1.5 pl-1 w-[60px] text-right">
                    <span className={`text-xs font-semibold ${marge >= 65 ? 'text-green-600' : marge >= 50 ? 'text-amber-600' : 'text-red-500'}`}>
                      {marge.toFixed(0)}%
                    </span>
                    <p className="text-[9px] text-gray-400">Marge</p>
                  </div>
                )}
              </div>
            </div>
            );
          })}
          {data.prices.length === 0 && <p className="text-sm text-gray-400 text-center py-4">Keine Preise definiert</p>}
        </div>
      </section>"""

content = content.replace(old_price_section, new_price_section)

# Also need to add fixedMarkup and percentMarkup to Price type
content = content.replace(
    "type Price = { id: string | null; fillQuantityId: string; fillLabel: string; priceLevelId: string; levelName: string; price: number; purchasePrice: number | null; isDefault: boolean; sortOrder: number };",
    "type Price = { id: string | null; fillQuantityId: string; fillLabel: string; priceLevelId: string; levelName: string; price: number; purchasePrice: number | null; fixedMarkup: number | null; percentMarkup: number | null; isDefault: boolean; sortOrder: number };"
)

# Update addPrice to include new fields
content = content.replace(
    "price: 0, purchasePrice: null, isDefault: false, sortOrder: p.prices.length",
    "price: 0, purchasePrice: null, fixedMarkup: null, percentMarkup: null, isDefault: false, sortOrder: p.prices.length"
)

# Update save to include new fields
content = content.replace(
    "prices: data.prices.map(p => ({ id: p.id, fillQuantityId: p.fillQuantityId, priceLevelId: p.priceLevelId, price: p.price, purchasePrice: p.purchasePrice, isDefault: p.isDefault, sortOrder: p.sortOrder }))",
    "prices: data.prices.map(p => ({ id: p.id, fillQuantityId: p.fillQuantityId, priceLevelId: p.priceLevelId, price: p.price, purchasePrice: p.purchasePrice, fixedMarkup: p.fixedMarkup, percentMarkup: p.percentMarkup, isDefault: p.isDefault, sortOrder: p.sortOrder }))"
)

open('src/components/admin/product-editor.tsx', 'w').write(content)
print('Editor updated')
PYEOF

# Update server-side serialization to include fixedMarkup and percentMarkup
python3 << 'PYEOF'
content = open('src/app/admin/items/[id]/page.tsx').read()

content = content.replace(
    "price: Number(p.price), purchasePrice: p.purchasePrice ? Number(p.purchasePrice) : null, isDefault: p.isDefault, sortOrder: p.sortOrder",
    "price: Number(p.price), purchasePrice: p.purchasePrice ? Number(p.purchasePrice) : null, fixedMarkup: p.fixedMarkup ? Number(p.fixedMarkup) : null, percentMarkup: p.percentMarkup, isDefault: p.isDefault, sortOrder: p.sortOrder"
)

open('src/app/admin/items/[id]/page.tsx', 'w').write(content)
print('Detail page updated')
PYEOF

# Update API to save fixedMarkup and percentMarkup
python3 << 'PYEOF'
content = open('src/app/api/v1/products/[id]/route.ts').read()

content = content.replace(
    "data: { price: p.price, purchasePrice: p.purchasePrice || null, fillQuantityId: p.fillQuantityId, priceLevelId: p.priceLevelId, isDefault: p.isDefault || false, sortOrder: p.sortOrder || 0 },",
    "data: { price: p.price, purchasePrice: p.purchasePrice || null, fixedMarkup: p.fixedMarkup || null, percentMarkup: p.percentMarkup || null, fillQuantityId: p.fillQuantityId, priceLevelId: p.priceLevelId, isDefault: p.isDefault || false, sortOrder: p.sortOrder || 0 },"
)

content = content.replace(
    "data: { productId: params.id, price: p.price, purchasePrice: p.purchasePrice || null, fillQuantityId: p.fillQuantityId, priceLevelId: p.priceLevelId, isDefault: p.isDefault || false, sortOrder: p.sortOrder || 0 },",
    "data: { productId: params.id, price: p.price, purchasePrice: p.purchasePrice || null, fixedMarkup: p.fixedMarkup || null, percentMarkup: p.percentMarkup || null, fillQuantityId: p.fillQuantityId, priceLevelId: p.priceLevelId, isDefault: p.isDefault || false, sortOrder: p.sortOrder || 0 },"
)

open('src/app/api/v1/products/[id]/route.ts', 'w').write(content)
print('API updated')
PYEOF

npm run build && pm2 restart menucard-pro
echo "=== Price Calculation deployed ==="
