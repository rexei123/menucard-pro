'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';

type Product = {
  id: string; sku: string | null; type: string; status: string;
  isHighlight: boolean; name: string; nameEn: string; shortDesc: string;
  groupName: string; groupSlug: string; parentGroupName: string;
  mainPrice: number | null; mainPriceLabel: string; priceCount: number;
  winery: string | null; vintage: number | null; region: string | null;
  country: string | null; brand: string | null; bevCategory: string | null;
};

type GroupOption = { slug: string; name: string; parentName: string | null; hasChildren: boolean };

const typeLabels: Record<string, string> = { WINE: 'Wein', DRINK: 'Getränk', FOOD: 'Speise', OTHER: 'Andere' };
const statusLabels: Record<string, string> = { ACTIVE: 'Aktiv', SOLD_OUT: 'Ausverkauft', ARCHIVED: 'Archiv', DRAFT: 'Entwurf' };
const statusColors: Record<string, string> = { ACTIVE: 'bg-green-100 text-green-700', SOLD_OUT: 'bg-red-100 text-red-600', ARCHIVED: 'bg-gray-100 text-gray-500', DRAFT: 'bg-yellow-100 text-yellow-700' };

function formatEur(price: number): string {
  return new Intl.NumberFormat('de-AT', { style: 'currency', currency: 'EUR' }).format(price);
}

export default function ProductList({ products, groups, typeCounts }: { products: Product[]; groups: GroupOption[]; typeCounts: Record<string, number> }) {
  const [query, setQuery] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [groupFilter, setGroupFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  const filtered = useMemo(() => {
    const q = query.toLowerCase().trim();
    return products.filter(p => {
      if (q) {
        const searchable = `${p.name} ${p.nameEn} ${p.shortDesc} ${p.sku || ''} ${p.winery || ''} ${p.region || ''} ${p.country || ''} ${p.brand || ''}`.toLowerCase();
        if (!searchable.includes(q)) return false;
      }
      if (typeFilter && p.type !== typeFilter) return false;
      if (groupFilter && p.groupSlug !== groupFilter) return false;
      if (statusFilter && p.status !== statusFilter) return false;
      return true;
    });
  }, [products, query, typeFilter, groupFilter, statusFilter]);

  const isActive = query || typeFilter || groupFilter || statusFilter;

  return (
    <div>
      {/* Search & Filters */}
      <div className="rounded-xl border bg-white p-4 shadow-sm mb-4">
        <div className="flex flex-wrap gap-3">
          {/* Search */}
          <div className="relative flex-1 min-w-[200px]">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="absolute left-3 top-1/2 -translate-y-1/2 opacity-30"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
            <input type="text" value={query} onChange={e => setQuery(e.target.value)} placeholder="Suche nach Name, SKU, Weingut, Region..." className="w-full rounded-lg border bg-gray-50 py-2 pl-10 pr-3 text-base outline-none focus:border-gray-400 focus:bg-white" />
          </div>
          {/* Type */}
          <select value={typeFilter} onChange={e => setTypeFilter(e.target.value)} className="rounded-lg border bg-gray-50 px-3 py-2 text-base outline-none">
            <option value="">Alle Typen ({products.length})</option>
            {Object.entries(typeLabels).map(([k, v]) => (
              <option key={k} value={k}>{v} ({typeCounts[k] || 0})</option>
            ))}
          </select>
          {/* Group */}
          <select value={groupFilter} onChange={e => setGroupFilter(e.target.value)} className="rounded-lg border bg-gray-50 px-3 py-2 text-base outline-none">
            <option value="">Alle Gruppen</option>
            {groups.filter(g => !g.hasChildren || g.parentName).map(g => (
              <option key={g.slug} value={g.slug}>{g.parentName ? `${g.parentName} → ${g.name}` : g.name}</option>
            ))}
          </select>
          {/* Status */}
          <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)} className="rounded-lg border bg-gray-50 px-3 py-2 text-base outline-none">
            <option value="">Alle Status</option>
            {Object.entries(statusLabels).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
          </select>
        </div>
        {isActive && (
          <div className="mt-3 flex items-center justify-between">
            <span className="text-sm text-gray-400">{filtered.length} / {products.length} Produkte</span>
            <button onClick={() => { setQuery(''); setTypeFilter(''); setGroupFilter(''); setStatusFilter(''); }} className="text-sm font-medium text-gray-500 hover:text-gray-800">Filter zurücksetzen</button>
          </div>
        )}
      </div>

      {/* Product Table */}
      <div className="rounded-xl border bg-white shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-base">
            <thead>
              <tr className="border-b bg-gray-50/50 text-left">
                <th className="px-4 py-3 font-medium text-gray-500 text-sm uppercase tracking-wider">Produkt</th>
                <th className="px-4 py-3 font-medium text-gray-500 text-sm uppercase tracking-wider hidden lg:table-cell">Gruppe</th>
                <th className="px-4 py-3 font-medium text-gray-500 text-sm uppercase tracking-wider hidden md:table-cell">Details</th>
                <th className="px-4 py-3 font-medium text-gray-500 text-sm uppercase tracking-wider text-right">Preis</th>
                <th className="px-4 py-3 font-medium text-gray-500 text-sm uppercase tracking-wider text-center">Status</th>
                <th className="px-4 py-3 font-medium text-gray-500 text-sm uppercase tracking-wider w-10"></th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {filtered.map(p => (
                <tr key={p.id} className="hover:bg-gray-50/50 transition-colors">
                  {/* Name + Type */}
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <span className={`flex-shrink-0 rounded px-1.5 py-0.5 text-sm font-bold ${
                        p.type === 'WINE' ? 'bg-purple-100 text-purple-700' :
                        p.type === 'DRINK' ? 'bg-blue-100 text-blue-700' :
                        p.type === 'FOOD' ? 'bg-orange-100 text-orange-700' :
                        'bg-gray-100 text-gray-600'
                      }`}>{typeLabels[p.type]?.[0] || '?'}</span>
                      <div className="min-w-0">
                        <Link href={`/admin/items/${p.id}`} className="font-medium text-gray-900 hover:text-[#8B6914] truncate block">{p.name}</Link>
                        {p.sku && <p className="text-sm text-gray-300 font-mono">{p.sku}</p>}
                      </div>
                    </div>
                  </td>
                  {/* Group */}
                  <td className="px-4 py-3 hidden lg:table-cell">
                    <span className="text-sm text-gray-500">{p.parentGroupName ? `${p.parentGroupName} → ` : ''}{p.groupName}</span>
                  </td>
                  {/* Details */}
                  <td className="px-4 py-3 hidden md:table-cell">
                    <div className="text-sm text-gray-400">
                      {p.winery && <span>{p.winery}{p.vintage ? ` ${p.vintage}` : ''}</span>}
                      {p.brand && <span>{p.brand}</span>}
                      {p.region && <span className="ml-1">· {p.region}</span>}
                      {p.country && <span className="ml-1">· {p.country}</span>}
                      {!p.winery && !p.brand && p.shortDesc && <span className="truncate block max-w-[200px]">{p.shortDesc}</span>}
                    </div>
                  </td>
                  {/* Price */}
                  <td className="px-4 py-3 text-right">
                    {p.mainPrice !== null && (
                      <div>
                        <span className="font-semibold tabular-nums">{formatEur(p.mainPrice)}</span>
                        {p.priceCount > 1 && <span className="text-sm text-gray-400 ml-1">+{p.priceCount - 1}</span>}
                      </div>
                    )}
                  </td>
                  {/* Status */}
                  <td className="px-4 py-3 text-center">
                    <span className={`inline-block rounded-full px-2 py-0.5 text-sm font-medium ${statusColors[p.status] || 'bg-gray-100'}`}>
                      {statusLabels[p.status] || p.status}
                    </span>
                  </td>
                  {/* Edit link */}
                  <td className="px-4 py-3">
                    <Link href={`/admin/items/${p.id}`} className="text-gray-300 hover:text-gray-600">
                      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m9 18 6-6-6-6"/></svg>
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {filtered.length === 0 && (
          <div className="px-6 py-12 text-center">
            <p className="text-base text-gray-400">Keine Produkte gefunden</p>
          </div>
        )}
      </div>
    </div>
  );
}
