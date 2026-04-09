'use client';

import { useState, useMemo } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import Link from 'next/link';

type ProductItem = {
  id: string; sku: string | null; type: string; status: string;
  name: string; groupName: string; groupSlug: string;
  mainPrice: number | null; priceCount: number;
  winery: string | null; vintage: number | null; menuNames: string[];
};

type GroupOption = { slug: string; name: string; parentName: string | null };

const typeBadge: Record<string, { letter: string; cls: string }> = {
  WINE: { letter: 'W', cls: 'bg-purple-100 text-purple-700' },
  DRINK: { letter: 'G', cls: 'bg-blue-100 text-blue-700' },
  FOOD: { letter: 'S', cls: 'bg-orange-100 text-orange-700' },
  OTHER: { letter: '?', cls: 'bg-gray-100 text-gray-600' },
};

const statusDot: Record<string, string> = {
  ACTIVE: 'bg-green-400',
  SOLD_OUT: 'bg-red-400',
  ARCHIVED: 'bg-gray-300',
  DRAFT: 'bg-yellow-400',
};

function formatEur(price: number): string {
  return new Intl.NumberFormat('de-AT', { style: 'currency', currency: 'EUR' }).format(price);
}

export default function ProductListPanel({ products, groups }: { products: ProductItem[]; groups: GroupOption[] }) {
  const [width, setWidth] = useState(400);
  const [dragging, setDragging] = useState(false);

  const startResize = (e: React.MouseEvent) => {
    e.preventDefault();
    setDragging(true);
    const startX = e.clientX;
    const startW = width;
    const onMove = (ev: MouseEvent) => {
      const newW = Math.max(260, Math.min(600, startW + ev.clientX - startX));
      setWidth(newW);
    };
    const onUp = () => {
      setDragging(false);
      document.removeEventListener('mousemove', onMove);
      document.removeEventListener('mouseup', onUp);
    };
    document.addEventListener('mousemove', onMove);
    document.addEventListener('mouseup', onUp);
  };
  const pathname = usePathname();
  const router = useRouter();
  const [creating, setCreating] = useState(false);
  const [query, setQuery] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [groupFilter, setGroupFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  const activeId = pathname.split('/admin/items/')[1] || '';

  const createProduct = async () => {
    setCreating(true);
    try {
      const res = await fetch('/api/v1/products', {
        method: 'POST', credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type: 'OTHER' }),
      });
      if (res.ok) {
        const data = await res.json();
        router.push('/admin/items/' + data.id);
        router.refresh();
      }
    } finally { setCreating(false); }
  };

  const filteredGroups = useMemo(() => {
    if (!typeFilter) return groups;
    const typeProducts = products.filter(p => p.type === typeFilter);
    const activeSlugs = new Set(typeProducts.map(p => p.groupSlug));
    return groups.filter(g => activeSlugs.has(g.slug));
  }, [groups, products, typeFilter]);

  const filtered = useMemo(() => {
    const q = query.toLowerCase().trim();
    return products.filter(p => {
      if (q) {
        const s = `${p.name} ${p.sku || ''} ${p.winery || ''} ${p.groupName}`.toLowerCase();
        if (!s.includes(q)) return false;
      }
      if (typeFilter && p.type !== typeFilter) return false;
      if (groupFilter && p.groupSlug !== groupFilter) return false;
      if (statusFilter && p.status !== statusFilter) return false;
      return true;
    });
  }, [products, query, typeFilter, groupFilter, statusFilter]);

  return (
    <div className="relative flex h-full flex-shrink-0 flex-col border-r bg-white" style={{ width }}>
      {/* Header */}
      <div className="border-b px-3 py-3">
        <div className="flex items-center justify-between mb-2">
          <h2 className="text-sm font-semibold text-gray-700">Produkte</h2>
          <div className="flex items-center gap-2">
            <span className="text-[10px] text-gray-400">{filtered.length}/{products.length}</span>
            <button onClick={() => createProduct()} disabled={creating} className="flex items-center gap-1 rounded-lg px-2.5 py-1 text-[11px] font-semibold text-white hover:opacity-80 disabled:opacity-50 bg-green-600">{creating ? "..." : "+ Artikel"}</button>
          </div>
        </div>
        {/* Search */}
        <div className="relative">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="absolute left-2.5 top-1/2 -translate-y-1/2 opacity-30"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
          <input
            type="text" value={query} onChange={e => setQuery(e.target.value)}
            placeholder="Suchen..."
            className="w-full rounded-lg border bg-gray-50 py-1.5 pl-8 pr-2 text-xs outline-none focus:border-gray-400 focus:bg-white"
          />
        </div>
        {/* Filters */}
        <div className="mt-2 flex gap-1.5">
          <select value={typeFilter} onChange={e => { setTypeFilter(e.target.value); setGroupFilter(''); }} className="flex-1 rounded border bg-gray-50 px-1.5 py-1 text-[10px] outline-none">
            <option value="">Alle Typen</option>
            <option value="WINE">Wein</option>
            <option value="DRINK">Getränk</option>
            <option value="FOOD">Speise</option>
          </select>
          <select value={groupFilter} onChange={e => setGroupFilter(e.target.value)} className="flex-1 rounded border bg-gray-50 px-1.5 py-1 text-[10px] outline-none">
            <option value="">Alle Gruppen</option>
            {filteredGroups.map(g => (
              <option key={g.slug} value={g.slug}>{g.parentName ? `${g.parentName} → ${g.name}` : g.name}</option>
            ))}
          </select>
          <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)} className="flex-1 rounded border bg-gray-50 px-1.5 py-1 text-[10px] outline-none">
            <option value="">Status</option>
            <option value="ACTIVE">Aktiv</option>
            <option value="DRAFT">Entwurf</option>
            <option value="SOLD_OUT">Ausverkauft</option>
            <option value="ARCHIVED">Archiv</option>
          </select>
        </div>
      </div>

      {/* Product List */}
      <div className="flex-1 overflow-y-auto">
        {filtered.map(p => {
          const active = activeId === p.id;
          const badge = typeBadge[p.type] || typeBadge.OTHER;
          return (
            <Link
              key={p.id}
              href={`/admin/items/${p.id}`}
              className={`block border-b px-3 py-3 transition-colors ${active ? 'bg-amber-50 border-l-2 border-l-amber-600' : 'hover:bg-gray-50 border-l-2 border-l-transparent'}`}
            >
              <div className="flex items-start justify-between gap-2">
                <div className="flex items-center gap-2">
                  <span className={`flex-shrink-0 rounded px-1.5 py-0.5 text-[10px] font-bold ${badge.cls}`}>{badge.letter}</span>
                  <p className={`text-[15px] leading-snug ${active ? 'font-semibold text-gray-900' : 'text-gray-800'}`}>{p.name}</p>
                </div>
                <span className={`flex-shrink-0 h-2 w-2 mt-1.5 rounded-full ${statusDot[p.status] || 'bg-gray-300'}`} />
              </div>
              <div className="mt-1.5 pl-7 flex items-center gap-2">
                <span className="text-[13px] text-gray-400">{p.groupName}</span>
              </div>
              <div className="mt-1 pl-7 flex items-center justify-between">
                <span className="text-[12px] text-gray-400">{p.menuNames.length > 0 ? p.menuNames.join(', ') : ''}{p.winery && p.menuNames.length > 0 ? ' · ' : ''}{p.winery ? `${p.winery}${p.vintage ? ` ${p.vintage}` : ''}` : ''}</span>
                {p.mainPrice !== null && (
                  <span className="text-[13px] font-semibold text-gray-600 tabular-nums">{formatEur(p.mainPrice)}</span>
                )}
              </div>
            </Link>
          );
        })}
        {filtered.length === 0 && (
          <div className="px-4 py-8 text-center text-xs text-gray-400">Keine Produkte</div>
        )}
      </div>
      {/* Drag handle */}
      <div
        onMouseDown={startResize}
        className={`absolute right-0 top-0 h-full w-1.5 cursor-col-resize hover:bg-amber-200 transition-colors ${dragging ? 'bg-amber-300' : ''}`}
        style={{ zIndex: 10 }}
      />
    </div>
  );
}
