// @ts-nocheck
'use client';
import ProductImages from '@/components/admin/product-images';
import { useState, useEffect, useMemo } from 'react';

// === Types v2 ===
type Translation = { language: string; name: string; shortDescription: string | null; longDescription: string | null; servingSuggestion: string | null; recipe: string | null; notes: string | null };
type VariantPrice = { id: string | null; priceLevelId: string; priceLevelName: string; sellPrice: number; costPrice: number | null; fixedMarkup: number | null; percentMarkup: number | null };
type Variant = { id: string | null; label: string | null; sku: string | null; fillQuantityId: string | null; fillQuantityLabel: string | null; isDefault: boolean; sortOrder: number; status: string; prices: VariantPrice[] };
type WineProfile = { winery: string | null; vintage: number | null; aging: string | null; tastingNotes: string | null; servingTemp: string | null; foodPairing: string | null; certification: string | null };
type BevDetail = { brand: string | null; alcoholContent: number | null; servingStyle: string | null; garnish: string | null; glassType: string | null };

type ProductData = {
  id: string; sku: string | null; type: string; status: string; highlightType: string;
  translations: Translation[]; variants: Variant[]; taxonomyNodeIds: string[];
  wineProfile: WineProfile | null; bevDetail: BevDetail | null;
  tags: string[]; images: any[]; createdAt: string;
};

type TaxNode = { id: string; name: string; type: string; slug: string; parentId: string | null; depth: number; children?: TaxNode[] };
type Options = {
  taxonomyNodes: TaxNode[];
  priceLevels: { id: string; name: string; slug: string }[];
  fillQuantities: { id: string; label: string; slug: string; volumeMl: number | null }[];
};

const statusOpts = [
  { value: 'ACTIVE', label: 'Aktiv' },
  { value: 'DRAFT', label: 'Entwurf' },
  { value: 'ARCHIVED', label: 'Archiviert' },
];
const typeOpts = [
  { value: 'FOOD', label: 'Speise' },
  { value: 'DRINK', label: 'Getränk' },
  { value: 'WINE', label: 'Wein' },
  { value: 'SPIRIT', label: 'Spirituose' },
  { value: 'BEER', label: 'Bier' },
  { value: 'COFFEE', label: 'Kaffee' },
  { value: 'OTHER', label: 'Andere' },
];
const taxonomyTypeLabels: Record<string, string> = {
  CATEGORY: 'Kategorien', REGION: 'Regionen', GRAPE: 'Rebsorten',
  STYLE: 'Stil', CUISINE: 'Küche', DIET: 'Ernährung',
  OCCASION: 'Anlass', CUSTOM: 'Sonstige',
};

const emptyWP: WineProfile = { winery: null, vintage: null, aging: null, tastingNotes: null, servingTemp: null, foodPairing: null, certification: null };
const emptyBev: BevDetail = { brand: null, alcoholContent: null, servingStyle: null, garnish: null, glassType: null };

// === Hierarchie-Hilfsfunktionen ===
function buildTree(nodes: TaxNode[]): Record<string, TaxNode[]> {
  const map = new Map<string, TaxNode>();
  for (const n of nodes) map.set(n.id, { ...n, children: [] });
  const roots: Record<string, TaxNode[]> = {};
  for (const n of nodes) {
    const node = map.get(n.id)!;
    if (n.parentId && map.has(n.parentId)) {
      map.get(n.parentId)!.children!.push(node);
    } else {
      if (!roots[n.type]) roots[n.type] = [];
      roots[n.type].push(node);
    }
  }
  return roots;
}

function getBreadcrumb(nodeId: string, nodeMap: Map<string, TaxNode>): string[] {
  const path: string[] = [];
  let current = nodeMap.get(nodeId);
  while (current) {
    path.unshift(current.name);
    current = current.parentId ? nodeMap.get(current.parentId) : undefined;
  }
  return path;
}

// === Hierarchische Pill-Gruppe ===
function TaxonomyGroup({ node, depth, selectedIds, onToggle }: { node: TaxNode; depth: number; selectedIds: string[]; onToggle: (id: string) => void }) {
  const hasChildren = node.children && node.children.length > 0;
  const isSelected = selectedIds.includes(node.id);
  const [open, setOpen] = useState(true);

  if (hasChildren) {
    // Gruppen-Header (nicht direkt auswählbar wenn Kinder vorhanden)
    return (
      <div className={depth > 0 ? 'ml-3 mt-1.5' : 'mt-1.5'}>
        <button
          type="button"
          onClick={() => setOpen(!open)}
          className="flex items-center gap-1 text-xs font-medium text-gray-500 hover:text-gray-700 mb-1"
        >
          <span className="material-symbols-outlined" style={{ fontSize: 14 }}>{open ? 'expand_more' : 'chevron_right'}</span>
          {node.name}
          {node.taxLabel && <span className="text-[9px] px-1 py-0 rounded bg-amber-50 text-amber-600 border border-amber-200 ml-1">{node.taxLabel}</span>}
        </button>
        {open && (
          <div className="flex flex-wrap gap-1.5 ml-4">
            {node.children!.map(child => (
              <TaxonomyGroup key={child.id} node={child} depth={depth + 1} selectedIds={selectedIds} onToggle={onToggle} />
            ))}
          </div>
        )}
      </div>
    );
  }

  // Blatt-Node (auswählbar)
  return (
    <button
      key={node.id}
      type="button"
      onClick={() => onToggle(node.id)}
      className={`rounded-full px-3 py-1 text-xs font-medium border transition-colors ${
        isSelected
          ? 'bg-pink-50 border-pink-300 text-pink-700'
          : 'bg-gray-50 border-gray-200 text-gray-500 hover:bg-gray-100'
      }`}
    >
      {node.name}
      {isSelected && <span className="ml-1">&times;</span>}
    </button>
  );
}

export default function ProductEditor({ product: initial, options }: { product: ProductData; options: Options }) {
  const [data, setData] = useState(initial);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState('');
  const [dirty, setDirty] = useState(false);
  const [translating, setTranslating] = useState<Set<string>>(new Set());
  const [duplicating, setDuplicating] = useState(false);
  const [showDuplicateDialog, setShowDuplicateDialog] = useState(false);
  const [newVintage, setNewVintage] = useState<number | null>(null);

  useEffect(() => {
    const unload = (e: BeforeUnloadEvent) => { if (dirty) { e.preventDefault(); e.returnValue = ''; } };
    window.addEventListener('beforeunload', unload);
    return () => window.removeEventListener('beforeunload', unload);
  }, [dirty]);

  const de = data.translations.find(t => t.language === 'de') || { language: 'de', name: '', shortDescription: null, longDescription: null, servingSuggestion: null, recipe: null, notes: null };
  const en = data.translations.find(t => t.language === 'en') || { language: 'en', name: '', shortDescription: null, longDescription: null, servingSuggestion: null, recipe: null, notes: null };
  const wp = data.wineProfile || emptyWP;
  const bev = data.bevDetail || emptyBev;

  const set = (field: string, value: any) => { setData(p => ({ ...p, [field]: value })); setDirty(true); };

  const setTrans = (lang: string, field: string, value: string) => {
    setData(p => {
      const exists = p.translations.find(t => t.language === lang);
      if (exists) {
        return { ...p, translations: p.translations.map(t => t.language === lang ? { ...t, [field]: value || null } : t) };
      }
      return { ...p, translations: [...p.translations, { language: lang, name: '', shortDescription: null, longDescription: null, servingSuggestion: null, recipe: null, notes: null, [field]: value || null }] };
    });
    setDirty(true);
  };

  const translateDeToEn = async (field: string) => {
    const deVal = (data.translations.find(t => t.language === 'de') as any)?.[field] || '';
    if (!deVal.trim()) return;
    setTranslating(prev => new Set(prev).add(field));
    try {
      const res = await fetch('/api/v1/translate', { method: 'POST', credentials: 'include', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ text: deVal, from: 'de', to: 'en' }) });
      if (res.ok) { const { translated } = await res.json(); setTrans('en', field, translated); }
    } catch {}
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

  // === Variant Helpers ===
  const setVariant = (idx: number, field: string, value: any) => {
    setData(p => ({ ...p, variants: p.variants.map((v, i) => i === idx ? { ...v, [field]: value } : v) }));
    setDirty(true);
  };

  const setVariantPrice = (vIdx: number, pIdx: number, field: string, value: any) => {
    setData(p => ({
      ...p,
      variants: p.variants.map((v, vi) => vi === vIdx ? {
        ...v, prices: v.prices.map((pr, pi) => pi === pIdx ? { ...pr, [field]: value } : pr),
      } : v),
    }));
    setDirty(true);
  };

  const addVariant = () => {
    setData(p => ({
      ...p,
      variants: [...p.variants, {
        id: null, label: null, sku: null,
        fillQuantityId: options.fillQuantities[0]?.id || null,
        fillQuantityLabel: options.fillQuantities[0]?.label || null,
        isDefault: p.variants.length === 0, sortOrder: p.variants.length, status: 'ACTIVE',
        prices: options.priceLevels.map(pl => ({
          id: null, priceLevelId: pl.id, priceLevelName: pl.name,
          sellPrice: 0, costPrice: null, fixedMarkup: null, percentMarkup: null,
        })),
      }],
    }));
    setDirty(true);
  };

  const removeVariant = (idx: number) => {
    if (!confirm('Variante entfernen?')) return;
    setData(p => ({ ...p, variants: p.variants.filter((_, i) => i !== idx) }));
    setDirty(true);
  };

  // === Taxonomy Helpers ===
  const toggleTaxonomy = (nodeId: string) => {
    setData(p => {
      const ids = p.taxonomyNodeIds.includes(nodeId)
        ? p.taxonomyNodeIds.filter(id => id !== nodeId)
        : [...p.taxonomyNodeIds, nodeId];
      return { ...p, taxonomyNodeIds: ids };
    });
    setDirty(true);
  };

  // Baum + Map aufbauen
  const { treeByType, nodeMap } = useMemo(() => {
    const map = new Map<string, TaxNode>();
    for (const n of options.taxonomyNodes) map.set(n.id, n);
    const tree = buildTree(options.taxonomyNodes);
    return { treeByType: tree, nodeMap: map };
  }, [options.taxonomyNodes]);

  // Breadcrumbs für ausgewählte Nodes
  const selectedBreadcrumbs = useMemo(() => {
    const result: { nodeId: string; type: string; path: string[] }[] = [];
    for (const id of data.taxonomyNodeIds) {
      const node = nodeMap.get(id);
      if (node) {
        result.push({ nodeId: id, type: node.type, path: getBreadcrumb(id, nodeMap) });
      }
    }
    return result;
  }, [data.taxonomyNodeIds, nodeMap]);

  // === Save v2 ===
  const save = async () => {
    setSaving(true); setError('');
    try {
      const res = await fetch(`/api/v1/products/${data.id}`, {
        method: 'PATCH', credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          status: data.status, type: data.type, highlightType: data.highlightType,
          translations: data.translations,
          taxonomy: data.taxonomyNodeIds,
          wineProfile: data.wineProfile,
          beverageDetail: data.bevDetail,
        }),
      });
      if (!res.ok) { const d = await res.json(); setError(d.error || 'Fehler beim Speichern'); setSaving(false); return; }

      for (const v of data.variants) {
        if (v.id) {
          await fetch(`/api/v1/variants/${v.id}`, {
            method: 'PATCH', credentials: 'include',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              label: v.label, sku: v.sku, fillQuantityId: v.fillQuantityId,
              isDefault: v.isDefault, sortOrder: v.sortOrder, status: v.status,
              prices: v.prices.map(p => ({
                id: p.id, priceLevelId: p.priceLevelId, sellPrice: p.sellPrice,
                costPrice: p.costPrice, fixedMarkup: p.fixedMarkup, percentMarkup: p.percentMarkup,
              })),
            }),
          });
        } else {
          await fetch('/api/v1/variants', {
            method: 'POST', credentials: 'include',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              productId: data.id, fillQuantityId: v.fillQuantityId,
              label: v.label, sku: v.sku, isDefault: v.isDefault,
              prices: v.prices.filter(p => p.sellPrice > 0).map(p => ({
                priceLevelId: p.priceLevelId, sellPrice: p.sellPrice,
                costPrice: p.costPrice, fixedMarkup: p.fixedMarkup, percentMarkup: p.percentMarkup,
              })),
            }),
          });
        }
      }

      setSaved(true); setDirty(false);
      setTimeout(() => setSaved(false), 2000);
    } catch { setError('Netzwerkfehler'); }
    finally { setSaving(false); }
  };

  const deleteProduct = async () => {
    const name = de.name || 'Produkt';
    if (!confirm(`Produkt "${name}" wirklich dauerhaft löschen?`)) return;
    if (!confirm('ENDGÜLTIG LÖSCHEN? Diese Aktion kann NICHT rückgängig gemacht werden!')) return;
    try {
      const res = await fetch(`/api/v1/products/${data.id}`, { method: 'DELETE', credentials: 'include' });
      if (res.ok) window.location.href = '/admin/items';
      else { const d = await res.json(); setError(d.error || 'Löschen fehlgeschlagen'); }
    } catch { setError('Netzwerkfehler'); }
  };

  // === Duplicate (Jahrgangs-Duplikation) ===
  const duplicateProduct = async () => {
    setDuplicating(true); setError('');
    try {
      const res = await fetch(`/api/v1/products/${data.id}/duplicate`, {
        method: 'POST', credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ vintage: newVintage }),
      });
      if (res.ok) {
        const result = await res.json();
        setShowDuplicateDialog(false);
        window.location.href = `/admin/items/${result.id}`;
      } else {
        const d = await res.json();
        setError(d.error || 'Duplikation fehlgeschlagen');
      }
    } catch { setError('Netzwerkfehler'); }
    finally { setDuplicating(false); }
  };

  // === Translation field helper ===
  const TransField = ({ label, field, lang, multiline }: { label: string; field: string; lang: 'de' | 'en'; multiline?: boolean }) => {
    const val = (data.translations.find(t => t.language === lang) as any)?.[field] || '';
    const Tag = multiline ? 'textarea' : 'input';
    return (
      <div>
        <div className="flex items-center justify-between mb-1">
          <label className="text-xs font-medium uppercase tracking-wider text-gray-400">{label}</label>
          {lang === 'en' && (
            <button type="button" onClick={() => translateDeToEn(field)} disabled={translating.has(field)}
              className="rounded px-2 py-0.5 text-xs font-medium border border-gray-300 text-gray-500 bg-gray-50 hover:bg-gray-100 disabled:opacity-50">
              {translating.has(field) ? '...' : 'DE→EN'}
            </button>
          )}
        </div>
        <Tag value={val} onChange={(e: any) => setTrans(lang, field, e.target.value)}
          {...(multiline ? { rows: 3 } : {})}
          className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-gray-400 resize-y" />
      </div>
    );
  };

  return (
    <div className="space-y-6 max-w-4xl pb-24" style={{ fontFamily: "'Roboto', sans-serif" }}>
      {/* Header */}
      <div>
        <a href="/admin/items" onClick={(e) => { if (dirty && !confirm("Ungespeicherte Änderungen verwerfen?")) e.preventDefault(); }}
          className="text-sm text-gray-400 hover:text-gray-600 mb-2 inline-flex items-center gap-1">
          <span className="material-symbols-outlined" style={{ fontSize: 16 }}>arrow_back</span>
          Alle Produkte
        </a>
        <div className="flex items-center gap-3">
          <h1 className="text-2xl font-bold text-gray-900">{de.name || 'Produkt'}</h1>
          {(data.type === 'WINE' || data.wineProfile) && (
            <button
              type="button"
              onClick={() => {
                const currentVintage = data.wineProfile?.vintage;
                setNewVintage(currentVintage ? currentVintage + 1 : new Date().getFullYear());
                setShowDuplicateDialog(true);
              }}
              className="flex items-center gap-1 rounded-lg px-3 py-1.5 text-xs font-medium text-white transition-colors"
              style={{ backgroundColor: '#22C55E' }}
              onMouseEnter={e => (e.currentTarget.style.backgroundColor = '#16A34A')}
              onMouseLeave={e => (e.currentTarget.style.backgroundColor = '#22C55E')}
            >
              <span className="material-symbols-outlined" style={{ fontSize: 14 }}>content_copy</span>
              Neuen Jahrgang anlegen
            </button>
          )}
        </div>
        <p className="text-sm text-gray-400 mt-0.5">{data.sku}</p>
      </div>

      {/* Jahrgangs-Duplikat Dialog */}
      {showDuplicateDialog && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/30 backdrop-blur-sm">
          <div className="bg-white rounded-xl shadow-xl border border-gray-200 p-6 w-full max-w-md">
            <h3 className="text-lg font-bold text-gray-900 flex items-center gap-2 mb-1">
              <span className="material-symbols-outlined" style={{ fontSize: 22, color: '#DD3C71' }}>content_copy</span>
              Neuen Jahrgang anlegen
            </h3>
            <p className="text-sm text-gray-500 mb-4">
              Erstellt eine Kopie von &bdquo;{de.name}&ldquo; mit neuem Jahrgang. Alle Daten (Beschreibung, Taxonomie, Preise, Weinprofil) werden &uuml;bernommen.
            </p>

            <div className="mb-4">
              <label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Neuer Jahrgang</label>
              <input
                type="number"
                value={newVintage ?? ''}
                onChange={e => setNewVintage(e.target.value ? Number(e.target.value) : null)}
                placeholder="z.B. 2023"
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-gray-400"
                autoFocus
              />
              <p className="text-xs text-gray-400 mt-1">
                {data.wineProfile?.vintage
                  ? `Aktueller Jahrgang: ${data.wineProfile.vintage}`
                  : 'Kein Jahrgang hinterlegt'}
              </p>
            </div>

            <div className="flex items-center gap-2 text-xs text-gray-400 mb-4">
              <span className="material-symbols-outlined" style={{ fontSize: 14 }}>info</span>
              Das neue Produkt wird als Entwurf erstellt und öffnet sich direkt im Editor.
            </div>

            {error && <p className="text-sm text-red-600 mb-3">{error}</p>}

            <div className="flex gap-2 justify-end">
              <button
                type="button"
                onClick={() => { setShowDuplicateDialog(false); setError(''); }}
                className="rounded-lg border border-gray-200 px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-50"
              >
                Abbrechen
              </button>
              <button
                type="button"
                onClick={duplicateProduct}
                disabled={duplicating}
                className="rounded-lg px-4 py-2 text-sm font-medium text-white disabled:opacity-50 transition-colors"
                style={{ backgroundColor: '#22C55E' }}
              >
                {duplicating ? 'Dupliziere...' : 'Jahrgang anlegen'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Einstellungen */}
      <section className="rounded-xl border border-gray-200 bg-white p-5">
        <h2 className="mb-3 text-sm font-semibold text-gray-500 flex items-center gap-1.5">
          <span className="material-symbols-outlined" style={{ fontSize: 18 }}>settings</span>
          Produkt-Einstellungen
        </h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          <div>
            <label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Status</label>
            <select value={data.status} onChange={e => set('status', e.target.value)} className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none">
              {statusOpts.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Typ</label>
            <select value={data.type} onChange={e => set('type', e.target.value)} className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none">
              {typeOpts.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Highlight</label>
            <select value={data.highlightType} onChange={e => set('highlightType', e.target.value)} className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none">
              <option value="NONE">Keines</option>
              <option value="RECOMMENDATION">Empfehlung</option>
              <option value="NEW">Neu</option>
              <option value="PREMIUM">Premium</option>
              <option value="BESTSELLER">Bestseller</option>
              <option value="SIGNATURE">Signature</option>
            </select>
          </div>
        </div>
      </section>

      {/* Taxonomie — Hierarchisch */}
      <section className="rounded-xl border border-gray-200 bg-white p-5">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-sm font-semibold text-gray-500 flex items-center gap-1.5">
            <span className="material-symbols-outlined" style={{ fontSize: 18 }}>category</span>
            Klassifizierung
          </h2>
          <a href="/admin/settings/taxonomy" className="text-xs text-gray-400 hover:text-pink-600 flex items-center gap-1">
            <span className="material-symbols-outlined" style={{ fontSize: 14 }}>settings</span>
            Verwalten
          </a>
        </div>

        {/* Ausgewählte Breadcrumbs */}
        {selectedBreadcrumbs.length > 0 && (
          <div className="mb-4 flex flex-wrap gap-1.5">
            {selectedBreadcrumbs.map(({ nodeId, type, path }) => (
              <span key={nodeId} className="inline-flex items-center gap-1 rounded-full bg-pink-50 border border-pink-200 px-2.5 py-1 text-xs">
                <span className="text-pink-400 text-[10px]">{taxonomyTypeLabels[type]?.slice(0, 3)}</span>
                <span className="text-pink-700 font-medium">{path.join(' › ')}</span>
                <button type="button" onClick={() => toggleTaxonomy(nodeId)} className="text-pink-400 hover:text-pink-700 ml-0.5">&times;</button>
              </span>
            ))}
          </div>
        )}

        {/* Hierarchische Gruppen */}
        {Object.entries(treeByType).map(([type, roots]) => (
          <div key={type} className="mb-3 last:mb-0">
            <label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1.5">
              {taxonomyTypeLabels[type] || type}
            </label>
            <div className="flex flex-wrap gap-1.5">
              {roots.map(node => (
                <TaxonomyGroup
                  key={node.id}
                  node={node}
                  depth={0}
                  selectedIds={data.taxonomyNodeIds}
                  onToggle={toggleTaxonomy}
                />
              ))}
            </div>
          </div>
        ))}
        {Object.keys(treeByType).length === 0 && <p className="text-sm text-gray-400">Keine Taxonomie-Knoten vorhanden</p>}
      </section>

      {/* Übersetzungen */}
      <div className="grid gap-6 lg:grid-cols-2">
        <section className="rounded-xl border border-gray-200 bg-white p-5">
          <h2 className="mb-3 text-sm font-semibold text-gray-500">Deutsch</h2>
          <div className="space-y-3">
            <TransField label="Name" field="name" lang="de" />
            <TransField label="Kurzbeschreibung" field="shortDescription" lang="de" />
            <TransField label="Langbeschreibung" field="longDescription" lang="de" multiline />
            <TransField label="Servierempfehlung" field="servingSuggestion" lang="de" />
          </div>
        </section>
        <section className="rounded-xl border border-gray-200 bg-white p-5">
          <h2 className="mb-3 text-sm font-semibold text-gray-500">English</h2>
          <div className="space-y-3">
            <TransField label="Name" field="name" lang="en" />
            <TransField label="Short Description" field="shortDescription" lang="en" />
            <TransField label="Long Description" field="longDescription" lang="en" multiline />
            <TransField label="Serving Suggestion" field="servingSuggestion" lang="en" />
          </div>
        </section>
      </div>

      {/* Varianten (v2 HERZSTÜCK) */}
      <section className="rounded-xl border border-gray-200 bg-white p-5">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-sm font-semibold text-gray-500 flex items-center gap-1.5">
            <span className="material-symbols-outlined" style={{ fontSize: 18 }}>layers</span>
            Varianten & Preise
          </h2>
          <button onClick={addVariant} className="flex items-center gap-1 text-xs font-medium px-3 py-1.5 rounded-lg text-white" style={{ backgroundColor: '#22C55E' }}>
            <span className="material-symbols-outlined" style={{ fontSize: 14 }}>add</span>
            Variante
          </button>
        </div>

        <div className="space-y-4">
          {data.variants.map((v, vi) => (
            <div key={v.id || `new-${vi}`} className={`rounded-lg border p-4 ${v.isDefault ? 'border-pink-200 bg-pink-50/30' : 'border-gray-200 bg-gray-50'}`}>
              {/* Variant Header */}
              <div className="flex items-center gap-3 mb-3">
                {v.isDefault && (
                  <span className="flex items-center gap-1 text-xs font-medium text-pink-600">
                    <span className="material-symbols-outlined" style={{ fontSize: 14 }}>star</span>
                    Standard
                  </span>
                )}
                <div className="flex-1 grid grid-cols-3 gap-2">
                  <div>
                    <label className="block text-xs text-gray-400 mb-0.5">Füllmenge</label>
                    <select value={v.fillQuantityId || ''} onChange={e => {
                      const fq = options.fillQuantities.find(f => f.id === e.target.value);
                      setVariant(vi, 'fillQuantityId', e.target.value || null);
                      setVariant(vi, 'fillQuantityLabel', fq?.label || null);
                    }} className="w-full rounded border border-gray-200 px-2 py-1.5 text-sm outline-none bg-white">
                      <option value="">– Keine –</option>
                      {options.fillQuantities.map(fq => <option key={fq.id} value={fq.id}>{fq.label}</option>)}
                    </select>
                  </div>
                  <div>
                    <label className="block text-xs text-gray-400 mb-0.5">Label</label>
                    <input value={v.label || ''} onChange={e => setVariant(vi, 'label', e.target.value || null)} placeholder="z.B. Glas" className="w-full rounded border border-gray-200 px-2 py-1.5 text-sm outline-none bg-white" />
                  </div>
                  <div>
                    <label className="block text-xs text-gray-400 mb-0.5">SKU</label>
                    <input value={v.sku || ''} onChange={e => setVariant(vi, 'sku', e.target.value || null)} className="w-full rounded border border-gray-200 px-2 py-1.5 text-sm outline-none bg-white" />
                  </div>
                </div>
                <div className="flex items-center gap-1">
                  {!v.isDefault && (
                    <button type="button" onClick={() => {
                      setData(p => ({ ...p, variants: p.variants.map((vv, i) => ({ ...vv, isDefault: i === vi })) }));
                      setDirty(true);
                    }} className="text-xs text-gray-400 hover:text-pink-600 px-1" title="Als Standard setzen">
                      <span className="material-symbols-outlined" style={{ fontSize: 16 }}>star_border</span>
                    </button>
                  )}
                  <button type="button" onClick={() => removeVariant(vi)} className="text-gray-400 hover:text-red-500 px-1" title="Entfernen">
                    <span className="material-symbols-outlined" style={{ fontSize: 16 }}>delete</span>
                  </button>
                </div>
              </div>

              {/* Variant Prices */}
              <div className="space-y-2">
                {v.prices.map((p, pi) => {
                  const ek = p.costPrice ?? 0;
                  const marge = ek > 0 && p.sellPrice > 0 ? ((p.sellPrice - ek) / p.sellPrice * 100) : null;
                  return (
                    <div key={p.id || `vp-${vi}-${pi}`} className="flex items-end gap-2">
                      <div className="w-24">
                        <label className="block text-xs text-gray-400 mb-0.5">{p.priceLevelName}</label>
                      </div>
                      <div className="w-20">
                        <label className="block text-xs text-gray-400 mb-0.5">EK</label>
                        <input type="number" step="0.01" value={p.costPrice ?? ''} onChange={e => {
                          const newEK = e.target.value ? Number(e.target.value) : null;
                          setVariantPrice(vi, pi, 'costPrice', newEK);
                          if (newEK && (p.fixedMarkup || p.percentMarkup)) {
                            setVariantPrice(vi, pi, 'sellPrice', Math.round((newEK + (p.fixedMarkup ?? 0)) * (1 + (p.percentMarkup ?? 0) / 100) * 10) / 10);
                          }
                        }} className="w-full rounded border border-gray-200 px-2 py-1.5 text-sm outline-none text-right bg-white" placeholder="0" />
                      </div>
                      <div className="w-16">
                        <label className="block text-xs text-gray-400 mb-0.5">+Fix</label>
                        <input type="number" step="0.01" value={p.fixedMarkup ?? ''} onChange={e => {
                          const val = e.target.value ? Number(e.target.value) : null;
                          setVariantPrice(vi, pi, 'fixedMarkup', val);
                          if (p.costPrice && val !== null) {
                            setVariantPrice(vi, pi, 'sellPrice', Math.round((p.costPrice + val) * (1 + (p.percentMarkup ?? 0) / 100) * 10) / 10);
                          }
                        }} className="w-full rounded border border-gray-200 px-2 py-1.5 text-sm outline-none text-right bg-white" placeholder="0" />
                      </div>
                      <div className="w-16">
                        <label className="block text-xs text-gray-400 mb-0.5">&times;%</label>
                        <input type="number" step="1" value={p.percentMarkup ?? ''} onChange={e => {
                          const val = e.target.value ? Number(e.target.value) : null;
                          setVariantPrice(vi, pi, 'percentMarkup', val);
                          if (p.costPrice && val !== null) {
                            setVariantPrice(vi, pi, 'sellPrice', Math.round((p.costPrice + (p.fixedMarkup ?? 0)) * (1 + val / 100) * 10) / 10);
                          }
                        }} className="w-full rounded border border-gray-200 px-2 py-1.5 text-sm outline-none text-right bg-white" placeholder="0" />
                      </div>
                      <div className="text-gray-300 pb-1.5">=</div>
                      <div className="w-24">
                        <label className="block text-xs text-gray-400 mb-0.5">VK</label>
                        <input type="number" step="0.01" value={p.sellPrice} onChange={e => setVariantPrice(vi, pi, 'sellPrice', Number(e.target.value))}
                          className="w-full rounded border border-gray-200 px-2 py-1.5 text-sm outline-none text-right font-bold bg-white" />
                      </div>
                      {marge !== null && (
                        <div className="w-14 pb-1.5 text-right">
                          <span className={`text-xs font-semibold ${marge >= 65 ? 'text-green-600' : marge >= 50 ? 'text-amber-600' : 'text-red-500'}`}>{marge.toFixed(0)}%</span>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          ))}
          {data.variants.length === 0 && (
            <p className="text-sm text-gray-400 text-center py-4">Keine Varianten &mdash; Klicken Sie &bdquo;Variante&ldquo; um die erste zu erstellen</p>
          )}
        </div>
      </section>

      {/* Wine Profile */}
      {(data.type === 'WINE' || data.wineProfile) && (
        <section className="rounded-xl border border-gray-200 bg-white p-5">
          <h2 className="mb-3 text-sm font-semibold text-gray-500 flex items-center gap-1.5">
            <span className="material-symbols-outlined" style={{ fontSize: 18 }}>wine_bar</span>
            Weinprofil
          </h2>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
            <div><label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Weingut</label>
              <input value={wp.winery || ''} onChange={e => setWP('winery', e.target.value)} className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none" /></div>
            <div><label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Jahrgang</label>
              <input type="number" value={wp.vintage ?? ''} onChange={e => setWP('vintage', e.target.value ? Number(e.target.value) : null)} className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none" /></div>
            <div><label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Ausbau</label>
              <input value={wp.aging || ''} onChange={e => setWP('aging', e.target.value)} className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none" /></div>
            <div><label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Trinktemperatur</label>
              <input value={wp.servingTemp || ''} onChange={e => setWP('servingTemp', e.target.value)} className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none" /></div>
            <div><label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Zertifizierung</label>
              <input value={wp.certification || ''} onChange={e => setWP('certification', e.target.value)} className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none" /></div>
          </div>
          <div className="mt-3 space-y-3">
            <div><label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Verkostungsnotizen</label>
              <textarea value={wp.tastingNotes || ''} onChange={e => setWP('tastingNotes', e.target.value)} rows={3} className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none resize-y" /></div>
            <div><label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Speiseempfehlung</label>
              <textarea value={wp.foodPairing || ''} onChange={e => setWP('foodPairing', e.target.value)} rows={2} className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none resize-y" /></div>
          </div>
        </section>
      )}

      {/* Beverage Detail */}
      {(data.type === 'DRINK' || data.type === 'SPIRIT' || data.type === 'BEER' || data.type === 'COFFEE' || data.bevDetail) && (
        <section className="rounded-xl border border-gray-200 bg-white p-5">
          <h2 className="mb-3 text-sm font-semibold text-gray-500 flex items-center gap-1.5">
            <span className="material-symbols-outlined" style={{ fontSize: 18 }}>local_bar</span>
            Getränkedetail
          </h2>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
            <div><label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Marke</label>
              <input value={bev.brand || ''} onChange={e => setBev('brand', e.target.value)} className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none" /></div>
            <div><label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Alkohol %</label>
              <input type="number" step="0.1" value={bev.alcoholContent ?? ''} onChange={e => setBev('alcoholContent', e.target.value ? Number(e.target.value) : null)} className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none" /></div>
            <div><label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Servierstil</label>
              <input value={bev.servingStyle || ''} onChange={e => setBev('servingStyle', e.target.value)} className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none" /></div>
            <div><label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Garnitur</label>
              <input value={bev.garnish || ''} onChange={e => setBev('garnish', e.target.value)} className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none" /></div>
            <div><label className="block text-xs font-medium uppercase tracking-wider text-gray-400 mb-1">Glastyp</label>
              <input value={bev.glassType || ''} onChange={e => setBev('glassType', e.target.value)} className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none" /></div>
          </div>
        </section>
      )}

      {/* Bilder */}
      {initial.images && <ProductImages productId={data.id} initialImages={initial.images} />}

      {/* Footer */}
      <div className="flex items-center justify-between">
        <span className="text-xs text-gray-300">ID: {data.id} · Erstellt: {new Date(data.createdAt).toLocaleDateString('de-AT')}</span>
        <button onClick={deleteProduct} className="rounded-lg border border-red-200 px-3 py-1.5 text-xs font-medium text-red-500 hover:bg-red-50 transition-colors flex items-center gap-1">
          <span className="material-symbols-outlined" style={{ fontSize: 14 }}>delete</span>
          Produkt löschen
        </button>
      </div>

      {/* Sticky Save Bar */}
      {(dirty || saved || error) && (
        <div className="fixed bottom-0 left-0 right-0 border-t bg-white/95 backdrop-blur-md px-6 py-3 flex items-center justify-between z-50">
          <div>
            {error && <span className="text-sm text-red-600">{error}</span>}
            {saved && <span className="text-sm text-green-600 flex items-center gap-1"><span className="material-symbols-outlined" style={{ fontSize: 16 }}>check_circle</span>Gespeichert</span>}
          </div>
          <div className="flex gap-2">
            <button onClick={() => { if (!dirty || confirm("Änderungen verwerfen?")) window.location.href = "/admin/items"; }}
              className="rounded-lg border px-4 py-2 text-sm font-medium hover:bg-gray-50">Abbrechen</button>
            <button onClick={save} disabled={saving}
              className="rounded-lg px-6 py-2 text-sm font-medium text-white disabled:opacity-50 transition-colors" style={{ backgroundColor: '#22C55E' }}>
              {saving ? 'Speichere...' : 'Speichern'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
