'use client';

import { useState, useMemo, useEffect } from 'react';
import Link from 'next/link';

type Translation = { languageCode: string; name: string; shortDescription: string | null; longDescription: string | null; servingSuggestion: string | null };
type Price = { id: string | null; fillQuantityId: string; fillLabel: string; priceLevelId: string; levelName: string; price: number; purchasePrice: number | null; fixedMarkup: number | null; percentMarkup: number | null; isDefault: boolean; sortOrder: number };
type WineProfile = { winery: string | null; vintage: number | null; grapeVarieties: string[]; region: string | null; country: string | null; appellation: string | null; style: string | null; body: string | null; sweetness: string | null; bottleSize: string | null; alcoholContent: number | null; servingTemp: string | null; tastingNotes: string | null; foodPairing: string | null };
type BevDetail = { brand: string | null; producer: string | null; category: string | null; alcoholContent: number | null; servingTemp: string | null; carbonated: boolean; origin: string | null };
type Placement = { menuName: string; sectionName: string; isVisible: boolean };

type ProductData = {
  id: string; sku: string | null; type: string; status: string;
  isHighlight: boolean; highlightType: string | null; productGroupId: string | null;
  translations: Translation[]; prices: Price[];
  wineProfile: WineProfile | null; bevDetail: BevDetail | null;
  internalNotes: string | null; placements: Placement[]; tags: { name: string; icon: string | null }[]; createdAt: string;
};

type Options = {
  groups: { id: string; slug: string; name: string; parentName: string | null }[];
  priceLevels: { id: string; name: string; slug: string }[];
  fillQuantities: { id: string; label: string; volume: string | null }[];
};

const statusOpts = [
  { value: 'ACTIVE', label: 'Aktiv' },
  { value: 'SOLD_OUT', label: 'Ausverkauft' },
  { value: 'ARCHIVED', label: 'Archiviert' },
  { value: 'DRAFT', label: 'Entwurf' },
];
const typeOpts = [
  { value: 'WINE', label: 'Wein' },
  { value: 'DRINK', label: 'Getränk' },
  { value: 'FOOD', label: 'Speise' },
  { value: 'OTHER', label: 'Andere' },
];
const styleOpts = [
  { value: '', label: '–' },
  { value: 'RED', label: 'Rotwein' },
  { value: 'WHITE', label: 'Weißwein' },
  { value: 'ROSE', label: 'Rosé' },
  { value: 'SPARKLING', label: 'Schaumwein' },
  { value: 'DESSERT', label: 'Dessertwein' },
  { value: 'FORTIFIED', label: 'Likörwein' },
  { value: 'ORANGE', label: 'Orange Wine' },
  { value: 'NATURAL', label: 'Naturwein' },
];
const bodyOpts = [
  { value: '', label: '–' },
  { value: 'LIGHT', label: 'Leicht' },
  { value: 'MEDIUM_LIGHT', label: 'Leicht bis Mittel' },
  { value: 'MEDIUM', label: 'Mittel' },
  { value: 'MEDIUM_FULL', label: 'Mittel bis Voll' },
  { value: 'FULL', label: 'Vollmundig' },
];
const sweetOpts = [
  { value: '', label: '–' },
  { value: 'DRY', label: 'Trocken' },
  { value: 'OFF_DRY', label: 'Halbtrocken' },
  { value: 'MEDIUM_DRY', label: 'Halbtrocken' },
  { value: 'MEDIUM_SWEET', label: 'Lieblich' },
  { value: 'SWEET', label: 'Süß' },
];
const bevCatOpts = [
  { value: '', label: '–' },
  { value: 'BEER', label: 'Bier' },
  { value: 'SPIRIT', label: 'Spirituose' },
  { value: 'COCKTAIL', label: 'Cocktail' },
  { value: 'SOFT_DRINK', label: 'Alkoholfrei' },
  { value: 'JUICE', label: 'Saft' },
  { value: 'WATER', label: 'Wasser' },
  { value: 'HOT_DRINK', label: 'Heißgetränk' },
  { value: 'SMOOTHIE', label: 'Smoothie' },
  { value: 'OTHER', label: 'Sonstige' },
];

const emptyWP: WineProfile = { winery: null, vintage: null, grapeVarieties: [], region: null, country: null, appellation: null, style: null, body: null, sweetness: null, bottleSize: null, alcoholContent: null, servingTemp: null, tastingNotes: null, foodPairing: null };
const emptyBev: BevDetail = { brand: null, producer: null, category: null, alcoholContent: null, servingTemp: null, carbonated: false, origin: null };

export default function ProductEditor({ product: initial, options }: { product: ProductData; options: Options }) {
  const [data, setData] = useState(initial);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState('');
  const [dirty, setDirty] = useState(false);
  const [deChanged, setDeChanged] = useState<Set<string>>(new Set());
  const [enSynced, setEnSynced] = useState<Set<string>>(new Set());

  useEffect(() => {
    const unload = (e: BeforeUnloadEvent) => { if (dirty) { e.preventDefault(); e.returnValue = ''; } };
    const clickGuard = (e: MouseEvent) => {
      if (!dirty) return;
      const link = (e.target as HTMLElement).closest('a[href]');
      if (link && !link.getAttribute('href')?.startsWith('#')) {
        if (!confirm('Ungespeicherte Änderungen verwerfen?')) {
          e.preventDefault();
          e.stopPropagation();
        }
      }
    };
    window.addEventListener('beforeunload', unload);
    document.addEventListener('click', clickGuard, true);
    return () => { window.removeEventListener('beforeunload', unload); document.removeEventListener('click', clickGuard, true); };
  }, [dirty]);



  const de = data.translations.find(t => t.languageCode === 'de') || { languageCode: 'de', name: '', shortDescription: null, longDescription: null, servingSuggestion: null };
  const en = data.translations.find(t => t.languageCode === 'en') || { languageCode: 'en', name: '', shortDescription: null, longDescription: null, servingSuggestion: null };
  const wp = data.wineProfile || emptyWP;
  const bev = data.bevDetail || emptyBev;

  const set = (field: string, value: any) => { setData(p => ({ ...p, [field]: value })); setDirty(true); };

  const setTrans = (lang: string, field: string, value: string) => {
    setData(p => {
      const exists = p.translations.find(t => t.languageCode === lang);
      if (exists) {
        return { ...p, translations: p.translations.map(t => t.languageCode === lang ? { ...t, [field]: value || null } : t) };
      }
      return { ...p, translations: [...p.translations, { languageCode: lang, name: '', shortDescription: null, longDescription: null, servingSuggestion: null, [field]: value || null }] };
    });
    if (lang === 'de') { setDeChanged(prev => new Set(prev).add(field)); setEnSynced(prev => { const n = new Set(prev); n.delete(field); return n; }); }
    if (lang === 'en') { setDeChanged(prev => { const n = new Set(prev); n.delete(field); return n; }); setEnSynced(prev => new Set(prev).add(field)); }
    setDirty(true);
  };

  const [translating, setTranslating] = useState<Set<string>>(new Set());

  const translateDeToEn = async (field: string) => {
    const deVal = (data.translations.find(t => t.languageCode === 'de') as any)?.[field] || '';
    if (!deVal.trim()) return;
    setTranslating(prev => new Set(prev).add(field));
    try {
      const res = await fetch('/api/v1/translate', {
        method: 'POST', credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: deVal, from: 'de', to: 'en' }),
      });
      if (res.ok) {
        const { translated } = await res.json();
        setTrans('en', field, translated);
        setDeChanged(prev => { const n = new Set(prev); n.delete(field); return n; });
        setEnSynced(prev => new Set(prev).add(field));
      }
    } catch { /* fallback: copy as-is */
      setTrans('en', field, deVal);
    }
    setTranslating(prev => { const n = new Set(prev); n.delete(field); return n; });
  };

  const setWP = (field: string, value: any) => {
    setData(p => ({ ...p, wineProfile: { ...(p.wineProfile || emptyWP), [field]: value === '' ? null : value } }));
    setDirty(true);
  };

  const setBev = (field: string, value: any) => {
    setData(p => ({ ...p, bevDetail: { ...(p.bevDetail || emptyBev), [field]: value === '' ? null : value } }));
    setDirty(true);
  };

  const setPrice = (idx: number, field: string, value: any) => {
    setData(p => ({ ...p, prices: p.prices.map((pr, i) => i === idx ? { ...pr, [field]: value } : pr) }));
    setDirty(true);
  };

  const addPrice = () => {
    setData(p => ({ ...p, prices: [...p.prices, { id: null, fillQuantityId: options.fillQuantities[0]?.id || '', fillLabel: options.fillQuantities[0]?.label || '', priceLevelId: options.priceLevels[0]?.id || '', levelName: options.priceLevels[0]?.name || '', price: 0, purchasePrice: null, fixedMarkup: null, percentMarkup: null, isDefault: false, sortOrder: p.prices.length }] }));
    setDirty(true);
  };

  const removePrice = (idx: number) => {
    setData(p => ({ ...p, prices: p.prices.filter((_, i) => i !== idx) }));
    setDirty(true);
  };

  const save = async () => {
    setSaving(true); setError(''); setDirty(true);
    try {
      const res = await fetch(`/api/v1/products/${data.id}`, {
        method: 'PATCH', credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          status: data.status, type: data.type, productGroupId: data.productGroupId,
          isHighlight: data.isHighlight, highlightType: data.highlightType, internalNotes: data.internalNotes || null,
          translations: data.translations,
          prices: data.prices.map(p => ({ id: p.id, fillQuantityId: p.fillQuantityId, priceLevelId: p.priceLevelId, price: p.price, purchasePrice: p.purchasePrice, fixedMarkup: p.fixedMarkup, percentMarkup: p.percentMarkup, isDefault: p.isDefault, sortOrder: p.sortOrder })),
          wineProfile: data.wineProfile,
          beverageDetail: data.bevDetail,
        }),
      });
      if (res.ok) { setSaved(true); setDirty(false); setDeChanged(new Set()); setEnSynced(new Set()); setTimeout(() => setSaved(false), 2000); }
      else { const d = await res.json(); setError(d.error || 'Fehler'); }
    } catch { setError('Netzwerkfehler'); }
    finally { setSaving(false); }
  };

  const deleteProduct = async () => {
    const name = (data.translations.find(t => t.languageCode === 'de') as any)?.name || 'Produkt';
    if (!confirm(`Produkt "${name}" wirklich dauerhaft löschen?\n\nAlle Daten (Preise, Übersetzungen, Kartenplatzierungen) werden unwiderruflich gelöscht.`)) return;
    if (!confirm('ENDGÜLTIG LÖSCHEN?\n\nDiese Aktion kann NICHT rückgängig gemacht werden!')) return;
    try {
      const res = await fetch(`/api/v1/products/${data.id}`, { method: 'DELETE', credentials: 'include' });
      if (res.ok) window.location.href = '/admin/items';
      else { const d = await res.json(); setError(d.error || 'Löschen fehlgeschlagen'); }
    } catch { setError('Netzwerkfehler'); }
  };

  return (
    <div className="space-y-6 max-w-4xl pb-24">
      {/* Header */}
      <div>
        <a href="#" onClick={(e) => { e.preventDefault(); if (!dirty || confirm("Ungespeicherte Änderungen verwerfen?")) window.location.href="/admin/items"; }} className="text-sm text-gray-400 hover:text-gray-600 mb-2 inline-block">← Alle Produkte</a>
        <h1 className="text-3xl font-bold" style={{fontFamily: "'Playfair Display', serif"}}>{de.name || 'Produkt'}</h1>
        <p className="text-base text-gray-400 mt-1">{data.sku}</p>
      </div>

      {/* Settings */}
      <section className="rounded-xl border bg-white p-5 shadow-sm">
        <h2 className="mb-3 text-base font-semibold text-gray-500">Produkt-Einstellungen</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          <div>
            <label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Status</label>
            <select value={data.status} onChange={e => set('status', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none">
              {statusOpts.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Typ</label>
            <select value={data.type} onChange={e => set('type', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none">
              {typeOpts.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Produktgruppe</label>
            <select value={data.productGroupId || ''} onChange={e => set('productGroupId', e.target.value || null)} className="w-full rounded-lg border px-3 py-2 text-base outline-none">
              <option value="">– Keine –</option>
              {options.groups.map(g => <option key={g.id} value={g.id}>{g.parentName ? `${g.parentName} → ${g.name}` : g.name}</option>)}
            </select>
          </div>
          <div className="flex items-end pb-2">
            <label className="flex items-center gap-2 text-base cursor-pointer">
              <input type="checkbox" checked={data.isHighlight} onChange={e => set('isHighlight', e.target.checked)} className="rounded" />
              Highlight
            </label>
          </div>
        </div>
      </section>

      {/* Translations DE */}
      <div className="grid gap-6 lg:grid-cols-2">
        <section className="rounded-xl border bg-white p-5 shadow-sm">
          <h2 className="mb-3 text-base font-semibold text-gray-500">🇦🇹 Deutsch</h2>
          <div className="space-y-3">
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Name</label>
              <input value={de.name} onChange={e => setTrans('de', 'name', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Kurzbeschreibung</label>
              <input value={de.shortDescription || ''} onChange={e => setTrans('de', 'shortDescription', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Langbeschreibung</label>
              <textarea value={de.longDescription || ''} onChange={e => setTrans('de', 'longDescription', e.target.value)} rows={4} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400 resize-y" /></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Servierempfehlung</label>
              <input value={de.servingSuggestion || ''} onChange={e => setTrans('de', 'servingSuggestion', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
          </div>
        </section>
        <section className="rounded-xl border bg-white p-5 shadow-sm">
          <h2 className="mb-3 text-base font-semibold text-gray-500">🇬🇧 English</h2>
          <div className="space-y-3">
            <div><div className="flex items-center justify-between mb-1"><label className="text-sm uppercase tracking-wider text-gray-400">Name</label><div className="flex items-center gap-1">{deChanged.has('name') && <span className="text-sm text-amber-600">⚠️ DE geändert</span>}<button type="button" onClick={() => translateDeToEn('name')} disabled={translating.has('name')} className={`rounded-md px-2 py-0.5 text-sm font-medium border transition-colors disabled:opacity-50 ${enSynced.has('name') && !deChanged.has('name') ? 'border-green-300 text-green-700 bg-green-50 hover:bg-green-100' : deChanged.has('name') ? 'border-amber-300 text-amber-700 bg-amber-50 hover:bg-amber-100' : 'border-gray-300 text-gray-500 bg-gray-50 hover:bg-gray-100'}`}>{translating.has('name') ? '⏳ Übersetze...' : enSynced.has('name') && !deChanged.has('name') ? '✅ Übersetzt' : '🔄 DE → EN'}</button></div></div>
              <input value={en.name} onChange={e => setTrans('en', 'name', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
            <div><div className="flex items-center justify-between mb-1"><label className="text-sm uppercase tracking-wider text-gray-400">Short Description</label><div className="flex items-center gap-1">{deChanged.has('shortDescription') && <span className="text-sm text-amber-600">⚠️ DE geändert</span>}<button type="button" onClick={() => translateDeToEn('shortDescription')} disabled={translating.has('shortDescription')} className={`rounded-md px-2 py-0.5 text-sm font-medium border transition-colors disabled:opacity-50 ${enSynced.has('shortDescription') && !deChanged.has('shortDescription') ? 'border-green-300 text-green-700 bg-green-50 hover:bg-green-100' : deChanged.has('shortDescription') ? 'border-amber-300 text-amber-700 bg-amber-50 hover:bg-amber-100' : 'border-gray-300 text-gray-500 bg-gray-50 hover:bg-gray-100'}`}>{translating.has('shortDescription') ? '⏳ Übersetze...' : enSynced.has('shortDescription') && !deChanged.has('shortDescription') ? '✅ Übersetzt' : '🔄 DE → EN'}</button></div></div>
              <input value={en.shortDescription || ''} onChange={e => setTrans('en', 'shortDescription', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
            <div><div className="flex items-center justify-between mb-1"><label className="text-sm uppercase tracking-wider text-gray-400">Long Description</label><div className="flex items-center gap-1">{deChanged.has('longDescription') && <span className="text-sm text-amber-600">⚠️ DE geändert</span>}<button type="button" onClick={() => translateDeToEn('longDescription')} disabled={translating.has('longDescription')} className={`rounded-md px-2 py-0.5 text-sm font-medium border transition-colors disabled:opacity-50 ${enSynced.has('longDescription') && !deChanged.has('longDescription') ? 'border-green-300 text-green-700 bg-green-50 hover:bg-green-100' : deChanged.has('longDescription') ? 'border-amber-300 text-amber-700 bg-amber-50 hover:bg-amber-100' : 'border-gray-300 text-gray-500 bg-gray-50 hover:bg-gray-100'}`}>{translating.has('longDescription') ? '⏳ Übersetze...' : enSynced.has('longDescription') && !deChanged.has('longDescription') ? '✅ Übersetzt' : '🔄 DE → EN'}</button></div></div>
              <textarea value={en.longDescription || ''} onChange={e => setTrans('en', 'longDescription', e.target.value)} rows={4} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400 resize-y" /></div>
            <div><div className="flex items-center justify-between mb-1"><label className="text-sm uppercase tracking-wider text-gray-400">Serving Suggestion</label><div className="flex items-center gap-1">{deChanged.has('servingSuggestion') && <span className="text-sm text-amber-600">⚠️ DE geändert</span>}<button type="button" onClick={() => translateDeToEn('servingSuggestion')} disabled={translating.has('servingSuggestion')} className={`rounded-md px-2 py-0.5 text-sm font-medium border transition-colors disabled:opacity-50 ${enSynced.has('servingSuggestion') && !deChanged.has('servingSuggestion') ? 'border-green-300 text-green-700 bg-green-50 hover:bg-green-100' : deChanged.has('servingSuggestion') ? 'border-amber-300 text-amber-700 bg-amber-50 hover:bg-amber-100' : 'border-gray-300 text-gray-500 bg-gray-50 hover:bg-gray-100'}`}>{translating.has('servingSuggestion') ? '⏳ Übersetze...' : enSynced.has('servingSuggestion') && !deChanged.has('servingSuggestion') ? '✅ Übersetzt' : '🔄 DE → EN'}</button></div></div>
              <input value={en.servingSuggestion || ''} onChange={e => setTrans('en', 'servingSuggestion', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
          </div>
        </section>
      </div>

      {/* Prices */}
      <section className="rounded-xl border bg-white p-5 shadow-sm">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-base font-semibold text-gray-500">Preise & Kalkulation</h2>
          <button onClick={addPrice} className="text-sm font-medium px-3 py-1.5 rounded-lg text-white" style={{backgroundColor:'#8B6914'}}>+ Preis hinzufügen</button>
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
                  <label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Füllmenge</label>
                  <select value={p.fillQuantityId} onChange={e => { const fq = options.fillQuantities.find(f => f.id === e.target.value); setPrice(i, 'fillQuantityId', e.target.value); if (fq) setPrice(i, 'fillLabel', fq.label); }} className="w-full rounded-lg border px-2 py-1.5 text-base outline-none bg-white">
                    {options.fillQuantities.map(fq => <option key={fq.id} value={fq.id}>{fq.label}</option>)}
                  </select>
                </div>
                <div className="flex-1">
                  <label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Preisebene</label>
                  <select value={p.priceLevelId} onChange={e => { const pl = options.priceLevels.find(l => l.id === e.target.value); setPrice(i, 'priceLevelId', e.target.value); if (pl) setPrice(i, 'levelName', pl.name); }} className="w-full rounded-lg border px-2 py-1.5 text-base outline-none bg-white">
                    {options.priceLevels.map(pl => <option key={pl.id} value={pl.id}>{pl.name}</option>)}
                  </select>
                </div>
                <button onClick={() => removePrice(i)} className="text-red-400 hover:text-red-600 p-1.5 mb-0.5" title="Preis entfernen">✕</button>
              </div>
              <div className="flex items-end gap-2">
                <div className="w-[88px]">
                  <label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">EK €</label>
                  <input type="number" step="0.01" value={p.purchasePrice ?? ''} onChange={e => {
                    const newEK = e.target.value ? Number(e.target.value) : null;
                    setPrice(i, 'purchasePrice', newEK);
                    if (newEK && (p.fixedMarkup || p.percentMarkup)) {
                      const newVK = (newEK + (p.fixedMarkup ?? 0)) * (1 + (p.percentMarkup ?? 0) / 100);
                      setPrice(i, 'price', Math.round(newVK * 10) / 10);
                    }
                  }} className="w-full rounded-lg border px-2 py-1.5 text-base outline-none text-right bg-white" placeholder="0.00" />
                </div>
                <div className="w-[72px]">
                  <label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">+ Fix €</label>
                  <input type="number" step="0.01" value={p.fixedMarkup ?? ''} onChange={e => {
                    const val = e.target.value ? Number(e.target.value) : null;
                    setPrice(i, 'fixedMarkup', val);
                    if (p.purchasePrice && val !== null) {
                      const newVK = (p.purchasePrice + val) * (1 + (p.percentMarkup ?? 0) / 100);
                      setPrice(i, 'price', Math.round(newVK * 10) / 10);
                    }
                  }} className="w-full rounded-lg border px-2 py-1.5 text-base outline-none text-right bg-white" placeholder="0" />
                </div>
                <div className="w-[72px]">
                  <label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">× Aufschlag %</label>
                  <input type="number" step="1" value={p.percentMarkup ?? ''} onChange={e => {
                    const val = e.target.value ? Number(e.target.value) : null;
                    setPrice(i, 'percentMarkup', val);
                    if (p.purchasePrice && val !== null) {
                      const newVK = (p.purchasePrice + (p.fixedMarkup ?? 0)) * (1 + val / 100);
                      setPrice(i, 'price', Math.round(newVK * 10) / 10);
                    }
                  }} className="w-full rounded-lg border px-2 py-1.5 text-base outline-none text-right bg-white" placeholder="0" />
                </div>
                <div className="text-center px-1 pb-1.5 text-gray-400">=</div>
                <div className="w-[96px]">
                  <label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">VK €</label>
                  <input type="number" step="0.01" value={p.price} onChange={e => setPrice(i, 'price', Number(e.target.value))} className="w-full rounded-lg border px-2 py-1.5 text-base outline-none text-right font-bold bg-white" />
                </div>
                {marge !== null && (
                  <div className="pb-1.5 pl-1 w-[60px] text-right">
                    <span className={`text-sm font-semibold ${marge >= 65 ? 'text-green-600' : marge >= 50 ? 'text-amber-600' : 'text-red-500'}`}>
                      {marge.toFixed(0)}%
                    </span>
                    <p className="text-sm text-gray-400">Marge</p>
                  </div>
                )}
              </div>
            </div>
            );
          })}
          {data.prices.length === 0 && <p className="text-base text-gray-400 text-center py-4">Keine Preise definiert</p>}
        </div>
      </section>

      {/* Wine Profile */}
      {(data.type === 'WINE' || data.wineProfile) && (
        <section className="rounded-xl border bg-white p-5 shadow-sm">
          <h2 className="mb-3 text-base font-semibold text-gray-500">Weinprofil</h2>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Weingut</label>
              <input value={wp.winery || ''} onChange={e => setWP('winery', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Jahrgang</label>
              <input type="number" value={wp.vintage ?? ''} onChange={e => setWP('vintage', e.target.value ? Number(e.target.value) : null)} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Rebsorten (kommagetrennt)</label>
              <input value={wp.grapeVarieties?.join(', ') || ''} onChange={e => setWP('grapeVarieties', e.target.value.split(',').map(s => s.trim()).filter(Boolean))} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Region</label>
              <input value={wp.region || ''} onChange={e => setWP('region', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Land</label>
              <input value={wp.country || ''} onChange={e => setWP('country', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Appellation</label>
              <input value={wp.appellation || ''} onChange={e => setWP('appellation', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Stil</label>
              <select value={wp.style || ''} onChange={e => setWP('style', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none">
                {styleOpts.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Körper</label>
              <select value={wp.body || ''} onChange={e => setWP('body', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none">
                {bodyOpts.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Süße</label>
              <select value={wp.sweetness || ''} onChange={e => setWP('sweetness', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none">
                {sweetOpts.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Flaschengröße</label>
              <input value={wp.bottleSize || ''} onChange={e => setWP('bottleSize', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Alkohol %</label>
              <input type="number" step="0.1" value={wp.alcoholContent ?? ''} onChange={e => setWP('alcoholContent', e.target.value ? Number(e.target.value) : null)} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Trinktemperatur</label>
              <input value={wp.servingTemp || ''} onChange={e => setWP('servingTemp', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
          </div>
          <div className="mt-3 space-y-3">
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Verkostungsnotizen</label>
              <textarea value={wp.tastingNotes || ''} onChange={e => setWP('tastingNotes', e.target.value)} rows={3} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400 resize-y" /></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Speiseempfehlung</label>
              <textarea value={wp.foodPairing || ''} onChange={e => setWP('foodPairing', e.target.value)} rows={2} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400 resize-y" /></div>
          </div>
        </section>
      )}

      {/* Beverage Detail */}
      {(data.type === 'DRINK' || data.bevDetail) && (
        <section className="rounded-xl border bg-white p-5 shadow-sm">
          <h2 className="mb-3 text-base font-semibold text-gray-500">Getränkedetail</h2>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Marke</label>
              <input value={bev.brand || ''} onChange={e => setBev('brand', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Produzent</label>
              <input value={bev.producer || ''} onChange={e => setBev('producer', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Kategorie</label>
              <select value={bev.category || ''} onChange={e => setBev('category', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none">
                {bevCatOpts.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Alkohol %</label>
              <input type="number" step="0.1" value={bev.alcoholContent ?? ''} onChange={e => setBev('alcoholContent', e.target.value ? Number(e.target.value) : null)} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
            <div><label className="block text-sm uppercase tracking-wider text-gray-400 mb-1">Herkunft</label>
              <input value={bev.origin || ''} onChange={e => setBev('origin', e.target.value)} className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400" /></div>
            <div className="flex items-end pb-2">
              <label className="flex items-center gap-2 text-base cursor-pointer">
                <input type="checkbox" checked={bev.carbonated} onChange={e => setBev('carbonated', e.target.checked)} className="rounded" />
                Kohlensäure
              </label>
            </div>
          </div>
        </section>
      )}

      {/* Rezeptur */}
      <section className="rounded-xl border bg-white p-5 shadow-sm">
        <h2 className="mb-3 text-base font-semibold text-gray-500">📝 Rezeptur / Interne Notizen</h2>
        <textarea
          value={data.internalNotes || ''}
          onChange={e => { set('internalNotes', e.target.value || null); }}
          rows={6}
          placeholder={"Zutaten, Mengen, Zubereitung...\n\nBeispiel Cocktail:\n4cl Gin\n2cl Zitronensaft\n1,5cl Zuckersirup\n→ Shaken, auf Eis, Zitronenzeste"}
          className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400 resize-y font-mono"
        />
        <p className="mt-1.5 text-sm text-gray-400">Nur intern sichtbar – wird nicht an Gäste angezeigt</p>
      </section>

      {/* Placements (read-only) */}
      {data.placements.length > 0 && (
        <section className="rounded-xl border bg-white p-5 shadow-sm">
          <h2 className="mb-3 text-base font-semibold text-gray-500">Kartenplatzierungen</h2>
          <div className="space-y-1">
            {data.placements.map((pl, i) => (
              <div key={i} className="flex items-center justify-between rounded-lg bg-gray-50 px-3 py-2 text-base">
                <span>{pl.menuName} → {pl.sectionName}</span>
                <span className={pl.isVisible ? 'text-green-600 text-sm' : 'text-gray-400 text-sm'}>{pl.isVisible ? 'Sichtbar' : 'Versteckt'}</span>
              </div>
            ))}
          </div>
        </section>
      )}

      <div className="flex items-center justify-between">
        <span className="text-sm text-gray-300">ID: {data.id} · Erstellt: {new Date(data.createdAt).toLocaleDateString('de-AT')}</span>
        <button onClick={deleteProduct} className="rounded-lg border border-red-200 px-3 py-1.5 text-sm font-medium text-red-500 hover:bg-red-50 hover:text-red-700 transition-colors">🗑️ Produkt löschen</button>
      </div>

      {/* Sticky Save Bar */}
      {(dirty || saved || error) && <div className="fixed bottom-0 left-0 right-0 border-t bg-white/95 backdrop-blur-md px-6 py-3 flex items-center justify-between z-50 animate-in slide-in-from-bottom">
        <div>
          {error && <span className="text-base text-red-600">{error}</span>}
          {saved && <span className="text-base text-green-600">✓ Gespeichert</span>}
        </div>
        <div className="flex gap-2">
          <button onClick={() => { if (!dirty || confirm("Ungespeicherte Änderungen verwerfen?")) window.location.href="/admin/items"; }} className="rounded-lg border px-4 py-2 text-base font-medium hover:bg-gray-50">Abbrechen</button>
          <button onClick={save} disabled={saving} className="rounded-lg px-6 py-2 text-base font-medium text-white disabled:opacity-50 transition-colors" style={{backgroundColor:'#8B6914'}}>
            {saving ? 'Speichere...' : 'Speichern'}
          </button>
        </div>
      </div>}
    </div>
  );
}
