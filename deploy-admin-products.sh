#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Deploying Admin Product Management ==="

echo "1/3 Backing up..."
cp src/app/admin/items/page.tsx /tmp/admin-items.bak 2>/dev/null || true

echo "2/3 Writing files..."

# === FILE 1: Admin Products List Page (Server Component) ===
cat > src/app/admin/items/page.tsx << 'ENDFILE'
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import ProductList from '@/components/admin/product-list';

export default async function ProductsPage() {
  const session = await getServerSession(authOptions);
  if (!session) return null;
  const tid = session.user.tenantId;

  const [products, groups, counts] = await Promise.all([
    prisma.product.findMany({
      where: { tenantId: tid },
      include: {
        translations: true,
        productGroup: { include: { translations: true } },
        prices: { include: { fillQuantity: true }, orderBy: { sortOrder: 'asc' } },
        productWineProfile: { select: { winery: true, vintage: true, region: true, country: true } },
        productBevDetail: { select: { brand: true, category: true } },
      },
      orderBy: [{ productGroup: { sortOrder: 'asc' } }, { sortOrder: 'asc' }],
    }),
    prisma.productGroup.findMany({
      where: { tenantId: tid },
      include: { translations: true, parent: { include: { translations: true } } },
      orderBy: { sortOrder: 'asc' },
    }),
    prisma.product.groupBy({
      by: ['type'],
      where: { tenantId: tid },
      _count: true,
    }),
  ]);

  const serialized = products.map(p => ({
    id: p.id,
    sku: p.sku,
    type: p.type,
    status: p.status,
    isHighlight: p.isHighlight,
    name: p.translations.find(t => t.languageCode === 'de')?.name || p.translations[0]?.name || '',
    nameEn: p.translations.find(t => t.languageCode === 'en')?.name || '',
    shortDesc: p.translations.find(t => t.languageCode === 'de')?.shortDescription || '',
    groupName: p.productGroup?.translations.find(t => t.languageCode === 'de')?.name || '',
    groupSlug: p.productGroup?.slug || '',
    parentGroupName: p.productGroup?.parent?.translations.find(t => t.languageCode === 'de')?.name || '',
    mainPrice: p.prices[0] ? Number(p.prices[0].price) : null,
    mainPriceLabel: p.prices[0]?.fillQuantity?.label || '',
    priceCount: p.prices.length,
    winery: p.productWineProfile?.winery || null,
    vintage: p.productWineProfile?.vintage || null,
    region: p.productWineProfile?.region || null,
    country: p.productWineProfile?.country || null,
    brand: p.productBevDetail?.brand || null,
    bevCategory: p.productBevDetail?.category || null,
  }));

  const groupOptions = groups.map(g => ({
    slug: g.slug,
    name: g.translations.find(t => t.languageCode === 'de')?.name || g.slug,
    parentName: g.parent?.translations.find(t => t.languageCode === 'de')?.name || null,
    hasChildren: groups.some(c => c.parentId === g.id),
  }));

  const typeCounts = Object.fromEntries(counts.map(c => [c.type, c._count]));

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold" style={{fontFamily: "'Playfair Display', serif"}}>Produkte</h1>
          <p className="text-sm text-gray-400 mt-1">{products.length} Produkte</p>
        </div>
      </div>
      <ProductList products={serialized} groups={groupOptions} typeCounts={typeCounts} />
    </div>
  );
}
ENDFILE

# === FILE 2: ProductList Client Component ===
cat > src/components/admin/product-list.tsx << 'ENDFILE'
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
            <input type="text" value={query} onChange={e => setQuery(e.target.value)} placeholder="Suche nach Name, SKU, Weingut, Region..." className="w-full rounded-lg border bg-gray-50 py-2 pl-10 pr-3 text-sm outline-none focus:border-gray-400 focus:bg-white" />
          </div>
          {/* Type */}
          <select value={typeFilter} onChange={e => setTypeFilter(e.target.value)} className="rounded-lg border bg-gray-50 px-3 py-2 text-sm outline-none">
            <option value="">Alle Typen ({products.length})</option>
            {Object.entries(typeLabels).map(([k, v]) => (
              <option key={k} value={k}>{v} ({typeCounts[k] || 0})</option>
            ))}
          </select>
          {/* Group */}
          <select value={groupFilter} onChange={e => setGroupFilter(e.target.value)} className="rounded-lg border bg-gray-50 px-3 py-2 text-sm outline-none">
            <option value="">Alle Gruppen</option>
            {groups.filter(g => !g.hasChildren || g.parentName).map(g => (
              <option key={g.slug} value={g.slug}>{g.parentName ? `${g.parentName} → ${g.name}` : g.name}</option>
            ))}
          </select>
          {/* Status */}
          <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)} className="rounded-lg border bg-gray-50 px-3 py-2 text-sm outline-none">
            <option value="">Alle Status</option>
            {Object.entries(statusLabels).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
          </select>
        </div>
        {isActive && (
          <div className="mt-3 flex items-center justify-between">
            <span className="text-xs text-gray-400">{filtered.length} / {products.length} Produkte</span>
            <button onClick={() => { setQuery(''); setTypeFilter(''); setGroupFilter(''); setStatusFilter(''); }} className="text-xs font-medium text-gray-500 hover:text-gray-800">Filter zurücksetzen</button>
          </div>
        )}
      </div>

      {/* Product Table */}
      <div className="rounded-xl border bg-white shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-gray-50/50 text-left">
                <th className="px-4 py-3 font-medium text-gray-500 text-xs uppercase tracking-wider">Produkt</th>
                <th className="px-4 py-3 font-medium text-gray-500 text-xs uppercase tracking-wider hidden lg:table-cell">Gruppe</th>
                <th className="px-4 py-3 font-medium text-gray-500 text-xs uppercase tracking-wider hidden md:table-cell">Details</th>
                <th className="px-4 py-3 font-medium text-gray-500 text-xs uppercase tracking-wider text-right">Preis</th>
                <th className="px-4 py-3 font-medium text-gray-500 text-xs uppercase tracking-wider text-center">Status</th>
                <th className="px-4 py-3 font-medium text-gray-500 text-xs uppercase tracking-wider w-10"></th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {filtered.map(p => (
                <tr key={p.id} className="hover:bg-gray-50/50 transition-colors">
                  {/* Name + Type */}
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <span className={`flex-shrink-0 rounded px-1.5 py-0.5 text-[10px] font-bold ${
                        p.type === 'WINE' ? 'bg-purple-100 text-purple-700' :
                        p.type === 'DRINK' ? 'bg-blue-100 text-blue-700' :
                        p.type === 'FOOD' ? 'bg-orange-100 text-orange-700' :
                        'bg-gray-100 text-gray-600'
                      }`}>{typeLabels[p.type]?.[0] || '?'}</span>
                      <div className="min-w-0">
                        <Link href={`/admin/items/${p.id}`} className="font-medium text-gray-900 hover:text-[#8B6914] truncate block">{p.name}</Link>
                        {p.sku && <p className="text-[10px] text-gray-300 font-mono">{p.sku}</p>}
                      </div>
                    </div>
                  </td>
                  {/* Group */}
                  <td className="px-4 py-3 hidden lg:table-cell">
                    <span className="text-xs text-gray-500">{p.parentGroupName ? `${p.parentGroupName} → ` : ''}{p.groupName}</span>
                  </td>
                  {/* Details */}
                  <td className="px-4 py-3 hidden md:table-cell">
                    <div className="text-xs text-gray-400">
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
                        {p.priceCount > 1 && <span className="text-[10px] text-gray-400 ml-1">+{p.priceCount - 1}</span>}
                      </div>
                    )}
                  </td>
                  {/* Status */}
                  <td className="px-4 py-3 text-center">
                    <span className={`inline-block rounded-full px-2 py-0.5 text-[10px] font-medium ${statusColors[p.status] || 'bg-gray-100'}`}>
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
            <p className="text-sm text-gray-400">Keine Produkte gefunden</p>
          </div>
        )}
      </div>
    </div>
  );
}
ENDFILE

# === FILE 3: Product Detail/Edit Page (Placeholder with data) ===
mkdir -p "src/app/admin/items/[id]"
cat > "src/app/admin/items/[id]/page.tsx" << 'ENDFILE'
import { notFound } from 'next/navigation';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import Link from 'next/link';

export default async function ProductDetailPage({ params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return null;

  const product = await prisma.product.findUnique({
    where: { id: params.id },
    include: {
      translations: true,
      productGroup: { include: { translations: true, parent: { include: { translations: true } } } },
      prices: { include: { fillQuantity: true, priceLevel: true }, orderBy: { sortOrder: 'asc' } },
      productAllergens: { include: { allergen: { include: { translations: true } } } },
      productTags: { include: { tag: { include: { translations: true } } } },
      productWineProfile: true,
      productBevDetail: true,
      placements: { include: { menuSection: { include: { translations: true, menu: { include: { translations: true } } } } } },
    },
  });
  if (!product) return notFound();

  const de = product.translations.find(t => t.languageCode === 'de');
  const en = product.translations.find(t => t.languageCode === 'en');
  const groupName = product.productGroup?.translations.find(t => t.languageCode === 'de')?.name || '-';
  const parentGroupName = product.productGroup?.parent?.translations.find(t => t.languageCode === 'de')?.name;
  const wp = product.productWineProfile;
  const bd = product.productBevDetail;

  const Field = ({ label, value }: { label: string; value: string | number | null | undefined }) => {
    if (!value) return null;
    return (
      <div>
        <p className="text-[10px] uppercase tracking-wider text-gray-400 mb-0.5">{label}</p>
        <p className="text-sm">{value}</p>
      </div>
    );
  };

  return (
    <div className="space-y-6 max-w-4xl">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <Link href="/admin/items" className="text-xs text-gray-400 hover:text-gray-600 mb-2 inline-block">← Alle Produkte</Link>
          <h1 className="text-2xl font-bold" style={{fontFamily: "'Playfair Display', serif"}}>{de?.name || 'Produkt'}</h1>
          <p className="text-sm text-gray-400 mt-1">
            {product.sku} · {product.type} · {parentGroupName ? `${parentGroupName} → ` : ''}{groupName}
          </p>
        </div>
        <span className={`rounded-full px-3 py-1 text-xs font-medium ${
          product.status === 'ACTIVE' ? 'bg-green-100 text-green-700' :
          product.status === 'SOLD_OUT' ? 'bg-red-100 text-red-600' :
          product.status === 'ARCHIVED' ? 'bg-gray-100 text-gray-500' :
          'bg-yellow-100 text-yellow-700'
        }`}>{product.status}</span>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Translations DE */}
        <div className="rounded-xl border bg-white p-5 shadow-sm">
          <h2 className="mb-3 text-sm font-semibold text-gray-500 flex items-center gap-2">🇦🇹 Deutsch</h2>
          <div className="space-y-3">
            <Field label="Name" value={de?.name} />
            <Field label="Kurzbeschreibung" value={de?.shortDescription} />
            {de?.longDescription && <div><p className="text-[10px] uppercase tracking-wider text-gray-400 mb-0.5">Langbeschreibung</p><p className="text-sm whitespace-pre-line opacity-70">{de.longDescription}</p></div>}
            <Field label="Servierempfehlung" value={de?.servingSuggestion} />
          </div>
        </div>

        {/* Translations EN */}
        <div className="rounded-xl border bg-white p-5 shadow-sm">
          <h2 className="mb-3 text-sm font-semibold text-gray-500 flex items-center gap-2">🇬🇧 English</h2>
          <div className="space-y-3">
            <Field label="Name" value={en?.name} />
            <Field label="Short Description" value={en?.shortDescription} />
            {en?.longDescription && <div><p className="text-[10px] uppercase tracking-wider text-gray-400 mb-0.5">Long Description</p><p className="text-sm whitespace-pre-line opacity-70">{en.longDescription}</p></div>}
            <Field label="Serving Suggestion" value={en?.servingSuggestion} />
          </div>
        </div>
      </div>

      {/* Prices */}
      {product.prices.length > 0 && (
        <div className="rounded-xl border bg-white p-5 shadow-sm">
          <h2 className="mb-3 text-sm font-semibold text-gray-500">Preise</h2>
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b text-left text-xs text-gray-400 uppercase">
                <th className="pb-2">Füllmenge</th>
                <th className="pb-2">Preisebene</th>
                <th className="pb-2 text-right">VK-Preis</th>
                <th className="pb-2 text-right">EK-Preis</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {product.prices.map(pp => (
                <tr key={pp.id}>
                  <td className="py-2">{pp.fillQuantity.label}</td>
                  <td className="py-2 text-gray-500">{pp.priceLevel.name}</td>
                  <td className="py-2 text-right font-semibold tabular-nums">€ {Number(pp.price).toFixed(2)}</td>
                  <td className="py-2 text-right text-gray-400 tabular-nums">{pp.purchasePrice ? `€ ${Number(pp.purchasePrice).toFixed(2)}` : '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Wine Profile */}
      {wp && (
        <div className="rounded-xl border bg-white p-5 shadow-sm">
          <h2 className="mb-3 text-sm font-semibold text-gray-500">Weinprofil</h2>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
            <Field label="Weingut" value={wp.winery} />
            <Field label="Jahrgang" value={wp.vintage} />
            <Field label="Rebsorten" value={wp.grapeVarieties?.join(', ')} />
            <Field label="Region" value={wp.region} />
            <Field label="Land" value={wp.country} />
            <Field label="Appellation" value={wp.appellation} />
            <Field label="Stil" value={wp.style} />
            <Field label="Körper" value={wp.body} />
            <Field label="Süße" value={wp.sweetness} />
            <Field label="Flaschengröße" value={wp.bottleSize} />
            <Field label="Alkohol" value={wp.alcoholContent ? `${wp.alcoholContent}%` : null} />
            <Field label="Trinktemperatur" value={wp.servingTemp} />
          </div>
          {wp.tastingNotes && <div className="mt-3 border-t pt-3"><Field label="Verkostungsnotizen" value={wp.tastingNotes} /></div>}
          {wp.foodPairing && <div className="mt-3 border-t pt-3"><Field label="Speiseempfehlung" value={wp.foodPairing} /></div>}
        </div>
      )}

      {/* Beverage Detail */}
      {bd && (
        <div className="rounded-xl border bg-white p-5 shadow-sm">
          <h2 className="mb-3 text-sm font-semibold text-gray-500">Getränkedetail</h2>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
            <Field label="Marke" value={bd.brand} />
            <Field label="Produzent" value={bd.producer} />
            <Field label="Kategorie" value={bd.category} />
            <Field label="Alkohol" value={bd.alcoholContent ? `${bd.alcoholContent}%` : null} />
            <Field label="Herkunft" value={bd.origin} />
            <Field label="Kohlensäure" value={bd.carbonated ? 'Ja' : 'Nein'} />
          </div>
        </div>
      )}

      {/* Placements */}
      {product.placements.length > 0 && (
        <div className="rounded-xl border bg-white p-5 shadow-sm">
          <h2 className="mb-3 text-sm font-semibold text-gray-500">Kartenplatzierungen</h2>
          <div className="space-y-2">
            {product.placements.map(pl => (
              <div key={pl.id} className="flex items-center justify-between rounded-lg bg-gray-50 px-3 py-2">
                <span className="text-sm">
                  {pl.menuSection.menu.translations.find(t => t.languageCode === 'de')?.name || pl.menuSection.menu.slug}
                  <span className="text-gray-400"> → </span>
                  {pl.menuSection.translations.find(t => t.languageCode === 'de')?.name || pl.menuSection.slug}
                </span>
                <span className={`text-xs ${pl.isVisible ? 'text-green-600' : 'text-gray-400'}`}>
                  {pl.isVisible ? 'Sichtbar' : 'Versteckt'}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Tags & Allergens */}
      <div className="grid gap-6 lg:grid-cols-2">
        {product.productTags.length > 0 && (
          <div className="rounded-xl border bg-white p-5 shadow-sm">
            <h2 className="mb-3 text-sm font-semibold text-gray-500">Tags</h2>
            <div className="flex flex-wrap gap-2">
              {product.productTags.map(t => (
                <span key={t.tag.id} className="rounded-full bg-gray-100 px-3 py-1 text-xs font-medium">
                  {t.tag.icon} {t.tag.translations.find(tr => tr.languageCode === 'de')?.name}
                </span>
              ))}
            </div>
          </div>
        )}
      </div>

      <div className="border-t pt-4 text-xs text-gray-300">
        ID: {product.id} · Erstellt: {product.createdAt.toLocaleDateString('de-AT')}
      </div>
    </div>
  );
}
ENDFILE

echo "3/3 Building..."
npm run build && pm2 restart menucard-pro

echo ""
echo "=== Admin Product Management deployed! ==="
echo "Test: http://178.104.138.177/admin/items"
