#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Deploying Product Edit Feature ==="

echo "1/3 Creating API..."

# === API Route: PATCH /api/v1/products/[id] ===
mkdir -p "src/app/api/v1/products/[id]"
cat > "src/app/api/v1/products/[id]/route.ts" << 'ENDFILE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const product = await prisma.product.findFirst({
    where: { id: params.id, tenantId: session.user.tenantId },
  });
  if (!product) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  const body = await req.json();
  const { translations, prices, wineProfile, beverageDetail, ...productData } = body;

  // Update product base fields
  if (Object.keys(productData).length > 0) {
    await prisma.product.update({ where: { id: params.id }, data: productData });
  }

  // Update translations
  if (translations) {
    for (const t of translations) {
      await prisma.productTranslation.upsert({
        where: { productId_languageCode: { productId: params.id, languageCode: t.languageCode } },
        update: { name: t.name, shortDescription: t.shortDescription || null, longDescription: t.longDescription || null, servingSuggestion: t.servingSuggestion || null },
        create: { productId: params.id, languageCode: t.languageCode, name: t.name, shortDescription: t.shortDescription || null, longDescription: t.longDescription || null, servingSuggestion: t.servingSuggestion || null },
      });
    }
  }

  // Update wine profile
  if (wineProfile !== undefined) {
    if (wineProfile === null) {
      await prisma.productWineProfile.deleteMany({ where: { productId: params.id } });
    } else {
      await prisma.productWineProfile.upsert({
        where: { productId: params.id },
        update: wineProfile,
        create: { productId: params.id, ...wineProfile },
      });
    }
  }

  // Update beverage detail
  if (beverageDetail !== undefined) {
    if (beverageDetail === null) {
      await prisma.productBeverageDetail.deleteMany({ where: { productId: params.id } });
    } else {
      await prisma.productBeverageDetail.upsert({
        where: { productId: params.id },
        update: beverageDetail,
        create: { productId: params.id, ...beverageDetail },
      });
    }
  }

  // Update prices
  if (prices) {
    // Delete removed prices
    const keepIds = prices.filter((p: any) => p.id).map((p: any) => p.id);
    await prisma.productPrice.deleteMany({
      where: { productId: params.id, id: { notIn: keepIds } },
    });
    // Upsert prices
    for (const p of prices) {
      if (p.id) {
        await prisma.productPrice.update({
          where: { id: p.id },
          data: { price: p.price, purchasePrice: p.purchasePrice || null, fillQuantityId: p.fillQuantityId, priceLevelId: p.priceLevelId, isDefault: p.isDefault || false, sortOrder: p.sortOrder || 0 },
        });
      } else {
        await prisma.productPrice.create({
          data: { productId: params.id, price: p.price, purchasePrice: p.purchasePrice || null, fillQuantityId: p.fillQuantityId, priceLevelId: p.priceLevelId, isDefault: p.isDefault || false, sortOrder: p.sortOrder || 0 },
        });
      }
    }
  }

  return NextResponse.json({ success: true });
}
ENDFILE

echo "2/3 Writing edit page..."

# === Editable Product Detail Page ===
cat > "src/app/admin/items/[id]/page.tsx" << 'ENDFILE'
import { notFound } from 'next/navigation';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import ProductEditor from '@/components/admin/product-editor';

export default async function ProductDetailPage({ params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return null;
  const tid = session.user.tenantId;

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

  const [groups, priceLevels, fillQuantities] = await Promise.all([
    prisma.productGroup.findMany({ where: { tenantId: tid }, include: { translations: true, parent: { include: { translations: true } } }, orderBy: { sortOrder: 'asc' } }),
    prisma.priceLevel.findMany({ where: { tenantId: tid }, orderBy: { sortOrder: 'asc' } }),
    prisma.fillQuantity.findMany({ where: { tenantId: tid }, orderBy: { sortOrder: 'asc' } }),
  ]);

  // Serialize
  const data = {
    id: product.id, sku: product.sku, type: product.type, status: product.status,
    isHighlight: product.isHighlight, highlightType: product.highlightType,
    productGroupId: product.productGroupId,
    translations: product.translations.map(t => ({ languageCode: t.languageCode, name: t.name, shortDescription: t.shortDescription, longDescription: t.longDescription, servingSuggestion: t.servingSuggestion })),
    prices: product.prices.map(p => ({ id: p.id, fillQuantityId: p.fillQuantityId, fillLabel: p.fillQuantity.label, priceLevelId: p.priceLevelId, levelName: p.priceLevel.name, price: Number(p.price), purchasePrice: p.purchasePrice ? Number(p.purchasePrice) : null, isDefault: p.isDefault, sortOrder: p.sortOrder })),
    wineProfile: product.productWineProfile ? {
      winery: product.productWineProfile.winery, vintage: product.productWineProfile.vintage,
      grapeVarieties: product.productWineProfile.grapeVarieties,
      region: product.productWineProfile.region, country: product.productWineProfile.country,
      appellation: product.productWineProfile.appellation, style: product.productWineProfile.style,
      body: product.productWineProfile.body, sweetness: product.productWineProfile.sweetness,
      bottleSize: product.productWineProfile.bottleSize, alcoholContent: product.productWineProfile.alcoholContent,
      servingTemp: product.productWineProfile.servingTemp, tastingNotes: product.productWineProfile.tastingNotes,
      foodPairing: product.productWineProfile.foodPairing,
    } : null,
    bevDetail: product.productBevDetail ? {
      brand: product.productBevDetail.brand, producer: product.productBevDetail.producer,
      category: product.productBevDetail.category, alcoholContent: product.productBevDetail.alcoholContent,
      servingTemp: product.productBevDetail.servingTemp, carbonated: product.productBevDetail.carbonated,
      origin: product.productBevDetail.origin,
    } : null,
    placements: product.placements.map(pl => ({
      menuName: pl.menuSection.menu.translations.find(t => t.languageCode === 'de')?.name || '',
      sectionName: pl.menuSection.translations.find(t => t.languageCode === 'de')?.name || '',
      isVisible: pl.isVisible,
    })),
    tags: product.productTags.map(t => ({ name: t.tag.translations.find(tr => tr.languageCode === 'de')?.name || '', icon: t.tag.icon })),
    createdAt: product.createdAt.toISOString(),
  };

  const opts = {
    groups: groups.map(g => ({ id: g.id, slug: g.slug, name: g.translations.find(t => t.languageCode === 'de')?.name || g.slug, parentName: g.parent?.translations.find(t => t.languageCode === 'de')?.name || null })),
    priceLevels: priceLevels.map(pl => ({ id: pl.id, name: pl.name, slug: pl.slug })),
    fillQuantities: fillQuantities.map(fq => ({ id: fq.id, label: fq.label, volume: fq.volume })),
  };

  return <ProductEditor product={data} options={opts} />;
}
ENDFILE

# === Product Editor Client Component ===
cat > src/components/admin/product-editor.tsx << 'ENDFILE'
'use client';

import { useState } from 'react';
import Link from 'next/link';

type Translation = { languageCode: string; name: string; shortDescription: string | null; longDescription: string | null; servingSuggestion: string | null };
type Price = { id: string | null; fillQuantityId: string; fillLabel: string; priceLevelId: string; levelName: string; price: number; purchasePrice: number | null; isDefault: boolean; sortOrder: number };
type WineProfile = { winery: string | null; vintage: number | null; grapeVarieties: string[]; region: string | null; country: string | null; appellation: string | null; style: string | null; body: string | null; sweetness: string | null; bottleSize: string | null; alcoholContent: number | null; servingTemp: string | null; tastingNotes: string | null; foodPairing: string | null };
type BevDetail = { brand: string | null; producer: string | null; category: string | null; alcoholContent: number | null; servingTemp: string | null; carbonated: boolean; origin: string | null };
type Placement = { menuName: string; sectionName: string; isVisible: boolean };
type Tag = { name: string; icon: string | null };

type ProductData = {
  id: string; sku: string | null; type: string; status: string;
  isHighlight: boolean; highlightType: string | null; productGroupId: string | null;
  translations: Translation[]; prices: Price[];
  wineProfile: WineProfile | null; bevDetail: BevDetail | null;
  placements: Placement[]; tags: Tag[]; createdAt: string;
};

type Options = {
  groups: { id: string; slug: string; name: string; parentName: string | null }[];
  priceLevels: { id: string; name: string; slug: string }[];
  fillQuantities: { id: string; label: string; volume: string | null }[];
};

const statusOpts = ['ACTIVE', 'SOLD_OUT', 'ARCHIVED', 'DRAFT'];
const typeOpts = ['WINE', 'DRINK', 'FOOD', 'OTHER'];
const styleOpts = ['RED', 'WHITE', 'ROSE', 'SPARKLING', 'DESSERT', 'FORTIFIED', 'ORANGE', 'NATURAL'];
const bodyOpts = ['LIGHT', 'MEDIUM_LIGHT', 'MEDIUM', 'MEDIUM_FULL', 'FULL'];
const sweetOpts = ['DRY', 'OFF_DRY', 'MEDIUM_DRY', 'MEDIUM_SWEET', 'SWEET'];
const bevCatOpts = ['BEER', 'SPIRIT', 'COCKTAIL', 'SOFT_DRINK', 'JUICE', 'WATER', 'HOT_DRINK', 'SMOOTHIE', 'OTHER'];

export default function ProductEditor({ product: initial, options }: { product: ProductData; options: Options }) {
  const [product, setProduct] = useState(initial);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState('');

  const de = product.translations.find(t => t.languageCode === 'de') || { languageCode: 'de', name: '', shortDescription: null, longDescription: null, servingSuggestion: null };
  const en = product.translations.find(t => t.languageCode === 'en') || { languageCode: 'en', name: '', shortDescription: null, longDescription: null, servingSuggestion: null };

  const updateTranslation = (lang: string, field: string, value: string) => {
    setProduct(p => ({
      ...p,
      translations: p.translations.map(t => t.languageCode === lang ? { ...t, [field]: value || null } : t)
        .concat(p.translations.find(t => t.languageCode === lang) ? [] : [{ languageCode: lang, name: value, shortDescription: null, longDescription: null, servingSuggestion: null }]),
    }));
    setSaved(false);
  };

  const updateWP = (field: string, value: any) => {
    setProduct(p => ({ ...p, wineProfile: { ...(p.wineProfile || { winery: null, vintage: null, grapeVarieties: [], region: null, country: null, appellation: null, style: null, body: null, sweetness: null, bottleSize: null, alcoholContent: null, servingTemp: null, tastingNotes: null, foodPairing: null }), [field]: value || null } }));
    setSaved(false);
  };

  const updateBev = (field: string, value: any) => {
    setProduct(p => ({ ...p, bevDetail: { ...(p.bevDetail || { brand: null, producer: null, category: null, alcoholContent: null, servingTemp: null, carbonated: false, origin: null }), [field]: value } }));
    setSaved(false);
  };

  const updatePrice = (idx: number, field: string, value: any) => {
    setProduct(p => ({ ...p, prices: p.prices.map((pr, i) => i === idx ? { ...pr, [field]: value } : pr) }));
    setSaved(false);
  };

  const addPrice = () => {
    setProduct(p => ({
      ...p, prices: [...p.prices, { id: null, fillQuantityId: options.fillQuantities[0]?.id || '', fillLabel: options.fillQuantities[0]?.label || '', priceLevelId: options.priceLevels[0]?.id || '', levelName: options.priceLevels[0]?.name || '', price: 0, purchasePrice: null, isDefault: false, sortOrder: p.prices.length }],
    }));
    setSaved(false);
  };

  const removePrice = (idx: number) => {
    setProduct(p => ({ ...p, prices: p.prices.filter((_, i) => i !== idx) }));
    setSaved(false);
  };

  const save = async () => {
    setSaving(true); setError(''); setSaved(false);
    try {
      const res = await fetch(`/api/v1/products/${product.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          status: product.status,
          type: product.type,
          productGroupId: product.productGroupId,
          isHighlight: product.isHighlight,
          highlightType: product.highlightType,
          translations: product.translations,
          prices: product.prices.map(p => ({ id: p.id, fillQuantityId: p.fillQuantityId, priceLevelId: p.priceLevelId, price: p.price, purchasePrice: p.purchasePrice, isDefault: p.isDefault, sortOrder: p.sortOrder })),
          wineProfile: product.wineProfile,
          beverageDetail: product.bevDetail,
        }),
      });
      if (res.ok) { setSaved(true); setTimeout(() => setSaved(false), 3000); }
      else { const d = await res.json(); setError(d.error || 'Fehler beim Speichern'); }
    } catch { setError('Netzwerkfehler'); }
    finally { setSaving(false); }
  };

  const Input = ({ label, value, onChange, type = 'text', className = '' }: any) => (
    <div className={className}>
      <label className="block text-[10px] uppercase tracking-wider text-gray-400 mb-1">{label}</label>
      <input type={type} value={value || ''} onChange={e => onChange(type === 'number' ? (e.target.value ? Number(e.target.value) : null) : e.target.value)} className="w-full rounded-lg border px-3 py-2 text-sm outline-none focus:border-gray-400" />
    </div>
  );

  const TextArea = ({ label, value, onChange, rows = 3 }: any) => (
    <div>
      <label className="block text-[10px] uppercase tracking-wider text-gray-400 mb-1">{label}</label>
      <textarea value={value || ''} onChange={e => onChange(e.target.value)} rows={rows} className="w-full rounded-lg border px-3 py-2 text-sm outline-none focus:border-gray-400 resize-y" />
    </div>
  );

  const Select = ({ label, value, onChange, options: opts, className = '' }: any) => (
    <div className={className}>
      <label className="block text-[10px] uppercase tracking-wider text-gray-400 mb-1">{label}</label>
      <select value={value || ''} onChange={e => onChange(e.target.value || null)} className="w-full rounded-lg border px-3 py-2 text-sm outline-none">
        {opts.map((o: any) => <option key={o.value ?? o} value={o.value ?? o}>{o.label ?? o}</option>)}
      </select>
    </div>
  );

  return (
    <div className="space-y-6 max-w-4xl pb-24">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <Link href="/admin/items" className="text-xs text-gray-400 hover:text-gray-600 mb-2 inline-block">← Alle Produkte</Link>
          <h1 className="text-2xl font-bold" style={{fontFamily: "'Playfair Display', serif"}}>{de.name || 'Produkt'}</h1>
          <p className="text-sm text-gray-400 mt-1">{product.sku} · {product.type}</p>
        </div>
      </div>

      {/* Status & Type & Group */}
      <div className="rounded-xl border bg-white p-5 shadow-sm">
        <h2 className="mb-3 text-sm font-semibold text-gray-500">Produkt-Einstellungen</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          <Select label="Status" value={product.status} onChange={(v: string) => { setProduct(p => ({ ...p, status: v })); setSaved(false); }} options={statusOpts.map(s => ({ value: s, label: s }))} />
          <Select label="Typ" value={product.type} onChange={(v: string) => { setProduct(p => ({ ...p, type: v })); setSaved(false); }} options={typeOpts.map(s => ({ value: s, label: s }))} />
          <Select label="Produktgruppe" value={product.productGroupId || ''} onChange={(v: string) => { setProduct(p => ({ ...p, productGroupId: v || null })); setSaved(false); }} options={[{ value: '', label: '– Keine –' }, ...options.groups.map(g => ({ value: g.id, label: g.parentName ? `${g.parentName} → ${g.name}` : g.name }))]} />
          <div className="flex items-end gap-2">
            <label className="flex items-center gap-2 text-sm cursor-pointer">
              <input type="checkbox" checked={product.isHighlight} onChange={e => { setProduct(p => ({ ...p, isHighlight: e.target.checked })); setSaved(false); }} className="rounded" />
              Highlight
            </label>
          </div>
        </div>
      </div>

      {/* Translations */}
      <div className="grid gap-6 lg:grid-cols-2">
        <div className="rounded-xl border bg-white p-5 shadow-sm">
          <h2 className="mb-3 text-sm font-semibold text-gray-500">🇦🇹 Deutsch</h2>
          <div className="space-y-3">
            <Input label="Name" value={de.name} onChange={(v: string) => updateTranslation('de', 'name', v)} />
            <Input label="Kurzbeschreibung" value={de.shortDescription} onChange={(v: string) => updateTranslation('de', 'shortDescription', v)} />
            <TextArea label="Langbeschreibung" value={de.longDescription} onChange={(v: string) => updateTranslation('de', 'longDescription', v)} />
            <Input label="Servierempfehlung" value={de.servingSuggestion} onChange={(v: string) => updateTranslation('de', 'servingSuggestion', v)} />
          </div>
        </div>
        <div className="rounded-xl border bg-white p-5 shadow-sm">
          <h2 className="mb-3 text-sm font-semibold text-gray-500">🇬🇧 English</h2>
          <div className="space-y-3">
            <Input label="Name" value={en.name} onChange={(v: string) => updateTranslation('en', 'name', v)} />
            <Input label="Short Description" value={en.shortDescription} onChange={(v: string) => updateTranslation('en', 'shortDescription', v)} />
            <TextArea label="Long Description" value={en.longDescription} onChange={(v: string) => updateTranslation('en', 'longDescription', v)} />
            <Input label="Serving Suggestion" value={en.servingSuggestion} onChange={(v: string) => updateTranslation('en', 'servingSuggestion', v)} />
          </div>
        </div>
      </div>

      {/* Prices */}
      <div className="rounded-xl border bg-white p-5 shadow-sm">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-sm font-semibold text-gray-500">Preise</h2>
          <button onClick={addPrice} className="text-xs font-medium px-3 py-1 rounded-lg text-white" style={{backgroundColor:'#8B6914'}}>+ Preis</button>
        </div>
        <div className="space-y-2">
          {product.prices.map((p, i) => (
            <div key={i} className="flex items-end gap-2 rounded-lg bg-gray-50 p-3">
              <div className="flex-1">
                <label className="block text-[10px] uppercase tracking-wider text-gray-400 mb-1">Füllmenge</label>
                <select value={p.fillQuantityId} onChange={e => { const fq = options.fillQuantities.find(f => f.id === e.target.value); updatePrice(i, 'fillQuantityId', e.target.value); if (fq) updatePrice(i, 'fillLabel', fq.label); }} className="w-full rounded-lg border px-2 py-1.5 text-sm outline-none">
                  {options.fillQuantities.map(fq => <option key={fq.id} value={fq.id}>{fq.label}</option>)}
                </select>
              </div>
              <div className="flex-1">
                <label className="block text-[10px] uppercase tracking-wider text-gray-400 mb-1">Preisebene</label>
                <select value={p.priceLevelId} onChange={e => { const pl = options.priceLevels.find(l => l.id === e.target.value); updatePrice(i, 'priceLevelId', e.target.value); if (pl) updatePrice(i, 'levelName', pl.name); }} className="w-full rounded-lg border px-2 py-1.5 text-sm outline-none">
                  {options.priceLevels.map(pl => <option key={pl.id} value={pl.id}>{pl.name}</option>)}
                </select>
              </div>
              <div className="w-24">
                <label className="block text-[10px] uppercase tracking-wider text-gray-400 mb-1">VK €</label>
                <input type="number" step="0.01" value={p.price} onChange={e => updatePrice(i, 'price', Number(e.target.value))} className="w-full rounded-lg border px-2 py-1.5 text-sm outline-none text-right font-semibold" />
              </div>
              <div className="w-24">
                <label className="block text-[10px] uppercase tracking-wider text-gray-400 mb-1">EK €</label>
                <input type="number" step="0.01" value={p.purchasePrice || ''} onChange={e => updatePrice(i, 'purchasePrice', e.target.value ? Number(e.target.value) : null)} className="w-full rounded-lg border px-2 py-1.5 text-sm outline-none text-right" />
              </div>
              <button onClick={() => removePrice(i)} className="text-red-400 hover:text-red-600 p-1.5">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* Wine Profile */}
      {(product.type === 'WINE' || product.wineProfile) && (
        <div className="rounded-xl border bg-white p-5 shadow-sm">
          <h2 className="mb-3 text-sm font-semibold text-gray-500">Weinprofil</h2>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
            <Input label="Weingut" value={product.wineProfile?.winery} onChange={(v: string) => updateWP('winery', v)} />
            <Input label="Jahrgang" type="number" value={product.wineProfile?.vintage} onChange={(v: number) => updateWP('vintage', v)} />
            <Input label="Rebsorten (kommagetrennt)" value={product.wineProfile?.grapeVarieties?.join(', ')} onChange={(v: string) => updateWP('grapeVarieties', v.split(',').map((s: string) => s.trim()).filter(Boolean))} className="col-span-2 md:col-span-1" />
            <Input label="Region" value={product.wineProfile?.region} onChange={(v: string) => updateWP('region', v)} />
            <Input label="Land" value={product.wineProfile?.country} onChange={(v: string) => updateWP('country', v)} />
            <Input label="Appellation" value={product.wineProfile?.appellation} onChange={(v: string) => updateWP('appellation', v)} />
            <Select label="Stil" value={product.wineProfile?.style} onChange={(v: string) => updateWP('style', v)} options={[{ value: '', label: '–' }, ...styleOpts.map(s => ({ value: s, label: s }))]} />
            <Select label="Körper" value={product.wineProfile?.body} onChange={(v: string) => updateWP('body', v)} options={[{ value: '', label: '–' }, ...bodyOpts.map(s => ({ value: s, label: s }))]} />
            <Select label="Süße" value={product.wineProfile?.sweetness} onChange={(v: string) => updateWP('sweetness', v)} options={[{ value: '', label: '–' }, ...sweetOpts.map(s => ({ value: s, label: s }))]} />
            <Input label="Flaschengröße" value={product.wineProfile?.bottleSize} onChange={(v: string) => updateWP('bottleSize', v)} />
            <Input label="Alkohol %" type="number" value={product.wineProfile?.alcoholContent} onChange={(v: number) => updateWP('alcoholContent', v)} />
            <Input label="Trinktemperatur" value={product.wineProfile?.servingTemp} onChange={(v: string) => updateWP('servingTemp', v)} />
          </div>
          <div className="mt-3 space-y-3">
            <TextArea label="Verkostungsnotizen" value={product.wineProfile?.tastingNotes} onChange={(v: string) => updateWP('tastingNotes', v)} />
            <TextArea label="Speiseempfehlung" value={product.wineProfile?.foodPairing} onChange={(v: string) => updateWP('foodPairing', v)} rows={2} />
          </div>
        </div>
      )}

      {/* Beverage Detail */}
      {(product.type === 'DRINK' || product.bevDetail) && (
        <div className="rounded-xl border bg-white p-5 shadow-sm">
          <h2 className="mb-3 text-sm font-semibold text-gray-500">Getränkedetail</h2>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
            <Input label="Marke" value={product.bevDetail?.brand} onChange={(v: string) => updateBev('brand', v)} />
            <Input label="Produzent" value={product.bevDetail?.producer} onChange={(v: string) => updateBev('producer', v)} />
            <Select label="Kategorie" value={product.bevDetail?.category} onChange={(v: string) => updateBev('category', v)} options={[{ value: '', label: '–' }, ...bevCatOpts.map(s => ({ value: s, label: s }))]} />
            <Input label="Alkohol %" type="number" value={product.bevDetail?.alcoholContent} onChange={(v: number) => updateBev('alcoholContent', v)} />
            <Input label="Herkunft" value={product.bevDetail?.origin} onChange={(v: string) => updateBev('origin', v)} />
            <label className="flex items-center gap-2 text-sm cursor-pointer self-end pb-2">
              <input type="checkbox" checked={product.bevDetail?.carbonated || false} onChange={e => updateBev('carbonated', e.target.checked)} className="rounded" />
              Kohlensäure
            </label>
          </div>
        </div>
      )}

      {/* Placements (read-only) */}
      {product.placements.length > 0 && (
        <div className="rounded-xl border bg-white p-5 shadow-sm">
          <h2 className="mb-3 text-sm font-semibold text-gray-500">Kartenplatzierungen</h2>
          <div className="space-y-1">
            {product.placements.map((pl, i) => (
              <div key={i} className="flex items-center justify-between rounded-lg bg-gray-50 px-3 py-2 text-sm">
                <span>{pl.menuName} → {pl.sectionName}</span>
                <span className={pl.isVisible ? 'text-green-600 text-xs' : 'text-gray-400 text-xs'}>{pl.isVisible ? 'Sichtbar' : 'Versteckt'}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Footer */}
      <div className="text-xs text-gray-300">ID: {product.id} · Erstellt: {new Date(product.createdAt).toLocaleDateString('de-AT')}</div>

      {/* Sticky Save Bar */}
      <div className="fixed bottom-0 left-0 right-0 border-t bg-white/95 backdrop-blur-md px-6 py-3 flex items-center justify-between z-50">
        <div>
          {error && <span className="text-sm text-red-600">{error}</span>}
          {saved && <span className="text-sm text-green-600">✓ Gespeichert</span>}
        </div>
        <div className="flex gap-2">
          <Link href="/admin/items" className="rounded-lg border px-4 py-2 text-sm font-medium">Abbrechen</Link>
          <button onClick={save} disabled={saving} className="rounded-lg px-6 py-2 text-sm font-medium text-white disabled:opacity-50" style={{backgroundColor:'#8B6914'}}>
            {saving ? 'Speichere...' : 'Speichern'}
          </button>
        </div>
      </div>
    </div>
  );
}
ENDFILE

echo "3/3 Building..."
npm run build && pm2 restart menucard-pro

echo ""
echo "=== Product Editor deployed! ==="
echo "Test: http://178.104.138.177/admin/items → Produkt anklicken → Bearbeiten"
