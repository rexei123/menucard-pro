'use client';

// ============================================================================
// MenuEditor — Karten-Editor mit Sektions- und Produktplatzierungs-Management
// ----------------------------------------------------------------------------
// Funktionen:
//   * Sektionen anlegen (mit Name + Icon)
//   * Sektions-Namen inline umbenennen
//   * Sektions-Icon per Picker wechseln
//   * Sektionen per Drag & Drop umsortieren (Griff links im Header)
//   * Sektionen löschen (mit Warnung wenn Produkte enthalten)
//   * Produkt-Varianten aus dem Pool per Drag & Drop platzieren
//   * Produkte innerhalb und zwischen Sektionen umsortieren / verschieben
//   * Produkte als "ausgetrunken" markieren oder entfernen
//
// Quellsystem für Gästeansicht + PDF + Inhaltsverzeichnis:
//   MenuSection.sortOrder + MenuSectionTranslation.name (DE/EN) + icon
// ============================================================================

import { useState, useMemo, useRef } from 'react';
import Link from 'next/link';
import TemplatePickerDrawer from './template-picker-drawer';

// v2: Placement referenziert variantId statt productId
type Placement = {
  id: string;
  variantId: string;
  productId: string;
  name: string;
  variantLabel: string | null;
  winery: string | null;
  vintage: number | null;
  price: number | null;
  type: string;
  sortOrder: number;
  isVisible: boolean;
};

type Section = {
  id: string;
  slug: string;
  name: string;
  icon: string | null;
  placements: Placement[];
};

// v2: BrowserProduct ist eine Variante (id = variantId)
type BrowserProduct = {
  id: string;
  productId: string;
  name: string;
  variantLabel: string | null;
  isDefault: boolean;
  type: string;
  groupName: string;
  groupSlug: string;
  price: number | null;
  winery: string | null;
  vintage: number | null;
  status: string;
};

type MenuInfo = {
  id: string;
  name: string;
  slug: string;
  type: string;
  locationName: string;
  isActive: boolean;
  publicUrl: string;
  templateId: string | null;
  qrCodes: { id: string; label: string | null; shortCode: string }[];
  sections: Section[];
};

// Typ-Badges für Produkt-Varianten
const TB: Record<string, { l: string; c: string }> = {
  WINE:    { l: 'W',  c: 'bg-purple-100 text-purple-700' },
  DRINK:   { l: 'G',  c: 'bg-blue-100 text-blue-700' },
  FOOD:    { l: 'S',  c: 'bg-orange-100 text-orange-700' },
  SPIRIT:  { l: 'SP', c: 'bg-amber-100 text-amber-700' },
  BEER:    { l: 'B',  c: 'bg-yellow-100 text-yellow-700' },
  COFFEE:  { l: 'K',  c: 'bg-stone-100 text-stone-700' },
  OTHER:   { l: '?',  c: 'bg-gray-100 text-gray-600' },
};

// Kuratiertes Icon-Set für Karten-Sektionen (Material Symbols)
const MENU_ICONS: { group: string; icons: string[] }[] = [
  { group: 'Speisen',      icons: ['restaurant_menu', 'dinner_dining', 'lunch_dining', 'breakfast_dining', 'brunch_dining', 'local_dining', 'ramen_dining', 'set_meal', 'soup_kitchen', 'rice_bowl', 'bakery_dining', 'kebab_dining', 'tapas', 'local_pizza', 'icecream', 'cake', 'egg_alt', 'grass'] },
  { group: 'Getränke',     icons: ['wine_bar', 'local_bar', 'sports_bar', 'liquor', 'local_drink', 'emoji_food_beverage'] },
  { group: 'Kaffee & Tee', icons: ['coffee', 'local_cafe', 'emoji_food_beverage', 'coffee_maker'] },
  { group: 'Spezial',      icons: ['star', 'auto_awesome', 'favorite', 'spa', 'eco', 'pets', 'celebration'] },
];

const fmtEur = (p: number) => new Intl.NumberFormat('de-AT', { style: 'currency', currency: 'EUR' }).format(p);

const placementInsertStyle = {
  background: 'linear-gradient(90deg, rgba(221,60,113,0.08), rgba(221,60,113,0.18))',
  border: '2px dashed var(--color-primary)',
  borderRadius: 8,
  margin: '4px 12px',
};

const sectionInsertStyle: React.CSSProperties = {
  height: 12,
  borderRadius: 6,
  margin: '6px 0',
  background: 'linear-gradient(90deg, rgba(34,197,94,0.15), rgba(34,197,94,0.35))',
  border: '2px dashed #22C55E',
};

export default function MenuEditor({
  menu,
  allProducts,
  groups,
}: {
  menu: MenuInfo;
  allProducts: BrowserProduct[];
  groups: { slug: string; name: string; parentName: string | null }[];
}) {
  // -------- State ----------------------------------------------------------
  const [sections, setSections] = useState<Section[]>(menu.sections);

  // Placement-Drag
  const [insertAt, setInsertAtState] = useState<{ sid: string; idx: number } | null>(null);
  const insertRef = useRef<{ sid: string; idx: number } | null>(null);
  const setInsertAt = (v: { sid: string; idx: number } | null) => { insertRef.current = v; setInsertAtState(v); };
  const dragRef = useRef<{ variantId: string; fromSection: string | null } | null>(null);
  const [browserDrop, setBrowserDrop] = useState(false);

  // Section-Drag
  const sectionDragRef = useRef<string | null>(null);
  const [sectionInsertAt, setSectionInsertAtState] = useState<number | null>(null);
  const sectionInsertRef = useRef<number | null>(null);
  const setSectionInsertAt = (v: number | null) => { sectionInsertRef.current = v; setSectionInsertAtState(v); };

  // Inline-Edit / Picker / Confirm
  const [editingSectionId, setEditingSectionId] = useState<string | null>(null);
  const [editingName, setEditingName] = useState('');
  const [iconPickerFor, setIconPickerFor] = useState<string | null>(null);
  const [deleteConfirmFor, setDeleteConfirmFor] = useState<string | null>(null);
  const [adding, setAdding] = useState(false);
  const [newSectionName, setNewSectionName] = useState('');
  const [newSectionIcon, setNewSectionIcon] = useState<string | null>('restaurant_menu');

  // Pool-Filter
  const [query, setQuery] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [groupFilter, setGroupFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [drawerOpen, setDrawerOpen] = useState(false);

  // Pool-Resize
  const [poolWidth, setPoolWidth] = useState(500);
  const [resizing, setResizing] = useState(false);

  // Feedback
  const [error, setError] = useState<string | null>(null);

  // -------- Derived -------------------------------------------------------
  const assignedVariantIds = useMemo(() => {
    const s = new Set<string>();
    sections.forEach(sec => sec.placements.forEach(p => s.add(p.variantId)));
    return s;
  }, [sections]);

  const filteredGroups = useMemo(() => {
    if (!typeFilter) return groups;
    const typeProds = allProducts.filter(p => p.type === typeFilter);
    const slugs = new Set(typeProds.map(p => p.groupSlug));
    return groups.filter(g => slugs.has(g.slug));
  }, [groups, allProducts, typeFilter]);

  const available = useMemo(() => {
    const q = query.toLowerCase().trim();
    return allProducts.filter(p => {
      if (assignedVariantIds.has(p.id)) return false;
      if (typeFilter && p.type !== typeFilter) return false;
      if (groupFilter && p.groupSlug !== groupFilter) return false;
      if (statusFilter && p.status !== statusFilter) return false;
      if (q && !`${p.name} ${p.variantLabel || ''} ${p.groupName} ${p.winery || ''}`.toLowerCase().includes(q)) return false;
      return true;
    });
  }, [allProducts, assignedVariantIds, query, typeFilter, groupFilter, statusFilter]);

  const total = sections.reduce((s, sec) => s + sec.placements.length, 0);

  // -------- API-Helpers (Placements) --------------------------------------
  const apiAdd = async (sectionId: string, variantId: string, sortOrder: number) => {
    const res = await fetch('/api/v1/placements', {
      method: 'POST',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ sectionId, variantId, sortOrder }),
    });
    return res.ok ? await res.json() : null;
  };
  const apiRemove = async (id: string) => {
    await fetch(`/api/v1/placements/${id}`, { method: 'DELETE', credentials: 'include' });
  };
  const apiPatch = async (id: string, data: any) => {
    await fetch(`/api/v1/placements/${id}`, {
      method: 'PATCH',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
  };

  // -------- API-Helpers (Sections) ----------------------------------------
  const apiCreateSection = async (name: string, icon: string | null) => {
    const res = await fetch('/api/v1/sections', {
      method: 'POST',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ menuId: menu.id, name, icon }),
    });
    if (!res.ok) {
      const b = await res.json().catch(() => null);
      setError(b?.error || 'Sektion konnte nicht angelegt werden');
      return null;
    }
    return await res.json();
  };

  const apiUpdateSection = async (id: string, data: { name?: string; icon?: string | null }) => {
    const res = await fetch(`/api/v1/sections/${id}`, {
      method: 'PATCH',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!res.ok) {
      const b = await res.json().catch(() => null);
      setError(b?.error || 'Sektion konnte nicht aktualisiert werden');
      return null;
    }
    return await res.json();
  };

  const apiDeleteSection = async (id: string, force = false) => {
    const url = `/api/v1/sections/${id}${force ? '?force=true' : ''}`;
    try {
      const res = await fetch(url, { method: 'DELETE', credentials: 'include' });
      if (!res.ok) {
        const b = await res.json().catch(() => null);
        return {
          ok: false,
          status: res.status,
          error: b?.error || `HTTP ${res.status}`,
          requiresForce: !!b?.requiresForce,
          placementCount: b?.placementCount ?? 0,
          childCount: b?.childCount ?? 0,
          childNames: Array.isArray(b?.childNames) ? (b.childNames as string[]) : [],
          descendantCount: b?.descendantCount ?? 0,
          descendantPlacementCount: b?.descendantPlacementCount ?? 0,
        };
      }
      return { ok: true };
    } catch (e: any) {
      return { ok: false, status: 0, error: `Netzwerkfehler: ${e?.message || 'unbekannt'}` };
    }
  };

  const apiReorderSections = async (order: string[]) => {
    await fetch('/api/v1/sections/reorder', {
      method: 'POST',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ menuId: menu.id, sectionIds: order }),
    });
  };

  // -------- Section-Actions -----------------------------------------------
  const submitNewSection = async () => {
    const name = newSectionName.trim();
    if (!name) return;
    const created = await apiCreateSection(name, newSectionIcon);
    if (created) {
      setSections(prev => [
        ...prev,
        {
          id: created.id,
          slug: created.slug,
          icon: created.icon,
          name,
          placements: [],
        },
      ]);
      setNewSectionName('');
      setNewSectionIcon('restaurant_menu');
      setAdding(false);
    }
  };

  const startRename = (sec: Section) => {
    setEditingSectionId(sec.id);
    setEditingName(sec.name);
    setIconPickerFor(null);
  };

  const submitRename = async () => {
    const id = editingSectionId;
    const name = editingName.trim();
    if (!id) return;
    if (!name) { setEditingSectionId(null); return; }
    const prev = sections.find(s => s.id === id);
    if (prev && prev.name === name) { setEditingSectionId(null); return; }
    setSections(p => p.map(s => s.id === id ? { ...s, name } : s));
    setEditingSectionId(null);
    await apiUpdateSection(id, { name });
  };

  const pickIcon = async (sectionId: string, icon: string | null) => {
    setIconPickerFor(null);
    setSections(p => p.map(s => s.id === sectionId ? { ...s, icon } : s));
    await apiUpdateSection(sectionId, { icon });
  };

  const deleteSection = async (id: string, force = false) => {
    const res = await apiDeleteSection(id, force);
    if (!res.ok) {
      if (res.requiresForce) {
        const pc = res.placementCount ?? 0;
        const cc = res.childCount ?? 0;
        const names: string[] = res.childNames ?? [];
        const dc = res.descendantCount ?? cc;
        const dpc = res.descendantPlacementCount ?? 0;

        // Name der zu löschenden Sektion ermitteln (für klarere Warnung)
        const sec = sections.find((s) => s.id === id);
        const secName = sec?.name || 'diese Sektion';

        if (cc > 0) {
          // STUFE 1: Cascade-Warnung mit expliziter Liste der Unter-Sektionen
          const listPreview = names.slice(0, 10).map((n) => `  • ${n}`).join('\n');
          const moreHint = names.length > 10 ? `\n  … und ${names.length - 10} weitere` : '';
          const totalSections = 1 + dc; // self + all descendants
          const totalPlacements = pc + dpc;

          const stage1Msg =
            `ACHTUNG: "${secName}" enthält ${cc} direkte Unter-Sektion(en):\n\n${listPreview}${moreHint}\n\n` +
            `Beim Löschen werden insgesamt entfernt:\n` +
            `  • ${totalSections} Sektion(en) (inkl. aller Unter-Sektionen)\n` +
            `  • ${totalPlacements} Produkt-Zuordnung(en)\n\n` +
            `Diese Aktion kann NICHT rückgängig gemacht werden.\n\n` +
            `Trotzdem fortfahren?`;
          if (!window.confirm(stage1Msg)) {
            setDeleteConfirmFor(null);
            return;
          }

          // STUFE 2: Zweite Bestätigung mit Sektions-Namen zur expliziten Freigabe
          const stage2Msg =
            `Bestätigen Sie die Löschung von "${secName}" und ${dc} Unter-Sektion(en)?\n\n` +
            `Klicken Sie OK nur, wenn Sie sicher sind.`;
          if (!window.confirm(stage2Msg)) {
            setDeleteConfirmFor(null);
            return;
          }

          return deleteSection(id, true);
        }

        // Nur Produkte (keine Kinder) → einfache Bestätigung reicht
        const msg = `"${secName}" enthält ${pc} Produkt-Zuordnung(en). Löschung entfernt die Zuordnungen, die Produkte selbst bleiben erhalten.\n\nFortfahren?`;
        if (window.confirm(msg)) return deleteSection(id, true);
        setDeleteConfirmFor(null);
        return;
      }
      setError(res.error || 'Löschung fehlgeschlagen');
      setDeleteConfirmFor(null);
      return;
    }
    setSections(p => p.filter(s => s.id !== id));
    setDeleteConfirmFor(null);
  };

  // -------- Drag (Placements) ---------------------------------------------
  const startDrag = (e: React.DragEvent, variantId: string, fromSection: string | null) => {
    dragRef.current = { variantId, fromSection };
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/plain', variantId);
  };

  const endDrag = () => {
    dragRef.current = null;
    setInsertAt(null);
    setBrowserDrop(false);
  };

  const overItem = (e: React.DragEvent, sid: string, idx: number) => {
    if (!dragRef.current) return;
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
    const insertIdx = e.clientY < rect.top + rect.height / 2 ? idx : idx + 1;
    setInsertAt({ sid, idx: insertIdx });
  };

  const overEmpty = (e: React.DragEvent, sid: string) => {
    if (!dragRef.current) return;
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    setInsertAt({ sid, idx: 0 });
  };

  const dropAtInsert = async (e: React.DragEvent) => {
    if (!dragRef.current) return;
    e.preventDefault();
    const ins = insertRef.current;
    setInsertAt(null);
    const drag = dragRef.current;
    if (!drag || !ins) return;
    const { variantId, fromSection } = drag;
    const sid = ins.sid;
    const idx = ins.idx;

    const sec = sections.find(s => s.id === sid);
    const existingHere = sec?.placements.find(p => p.variantId === variantId);
    if (existingHere && fromSection === sid) {
      setSections(prev => prev.map(s => {
        if (s.id !== sid) return s;
        const without = s.placements.filter(p => p.variantId !== variantId);
        const adjustedIdx = idx > s.placements.indexOf(existingHere) ? idx - 1 : idx;
        without.splice(adjustedIdx, 0, existingHere);
        return { ...s, placements: without.map((p, i) => ({ ...p, sortOrder: i })) };
      }));
      endDrag();
      return;
    }

    if (fromSection) {
      let moving: Placement | null = null;
      for (const s of sections) {
        const f = s.placements.find(p => p.variantId === variantId);
        if (f) { moving = f; break; }
      }
      if (moving) {
        await apiRemove(moving.id);
        setSections(prev => prev.map(s => s.id === fromSection
          ? { ...s, placements: s.placements.filter(p => p.variantId !== variantId) }
          : s));
      }
    }

    const prod = allProducts.find(p => p.id === variantId);
    if (!prod) { endDrag(); return; }
    const pl = await apiAdd(sid, variantId, idx);
    if (pl) {
      const np: Placement = {
        id: pl.id,
        variantId: prod.id,
        productId: prod.productId,
        name: prod.name,
        variantLabel: prod.variantLabel,
        winery: prod.winery,
        vintage: prod.vintage,
        price: prod.price,
        type: prod.type,
        sortOrder: idx,
        isVisible: true,
      };
      setSections(prev => prev.map(s => {
        if (s.id !== sid) return s;
        const pls = [...s.placements];
        pls.splice(idx, 0, np);
        return { ...s, placements: pls.map((p, i) => ({ ...p, sortOrder: i })) };
      }));
    }
    endDrag();
  };

  const dropBrowser = async (e: React.DragEvent) => {
    if (!dragRef.current) return;
    e.preventDefault();
    setBrowserDrop(false);
    const drag = dragRef.current;
    if (!drag || !drag.fromSection) { endDrag(); return; }
    let pl: Placement | null = null;
    let sid: string | null = null;
    for (const s of sections) {
      const f = s.placements.find(p => p.variantId === drag.variantId);
      if (f) { pl = f; sid = s.id; break; }
    }
    if (pl && sid) {
      await apiRemove(pl.id);
      setSections(prev => prev.map(s => s.id === sid
        ? { ...s, placements: s.placements.filter(p => p.variantId !== drag.variantId) }
        : s));
    }
    endDrag();
  };

  const clickAdd = async (variantId: string, sectionId: string) => {
    const prod = allProducts.find(p => p.id === variantId);
    if (!prod) return;
    const sec = sections.find(s => s.id === sectionId);
    const pl = await apiAdd(sectionId, variantId, sec?.placements.length || 0);
    if (pl) {
      const np: Placement = {
        id: pl.id,
        variantId: prod.id,
        productId: prod.productId,
        name: prod.name,
        variantLabel: prod.variantLabel,
        winery: prod.winery,
        vintage: prod.vintage,
        price: prod.price,
        type: prod.type,
        sortOrder: sec?.placements.length || 0,
        isVisible: true,
      };
      setSections(prev => prev.map(s => s.id === sectionId
        ? { ...s, placements: [...s.placements, np] } : s));
    }
  };

  const removePlacement = async (plId: string, sid: string) => {
    await apiRemove(plId);
    setSections(prev => prev.map(s => s.id === sid
      ? { ...s, placements: s.placements.filter(p => p.id !== plId) } : s));
  };

  const toggleVisible = async (plId: string, sid: string, current: boolean) => {
    await apiPatch(plId, { isVisible: !current });
    setSections(prev => prev.map(s => s.id === sid
      ? { ...s, placements: s.placements.map(p => p.id === plId ? { ...p, isVisible: !current } : p) }
      : s));
  };

  // -------- Drag (Sections) ------------------------------------------------
  const startSectionDrag = (e: React.DragEvent, sectionId: string) => {
    sectionDragRef.current = sectionId;
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('application/x-section', sectionId);
    // Nicht das komplette gruppenhafte Section-Element verwenden, Browser entscheidet selbst
  };

  const endSectionDrag = () => {
    sectionDragRef.current = null;
    setSectionInsertAt(null);
  };

  const overSectionGap = (e: React.DragEvent, idx: number) => {
    if (!sectionDragRef.current) return;
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    setSectionInsertAt(idx);
  };

  const dropSectionAtGap = async (e: React.DragEvent) => {
    if (!sectionDragRef.current) return;
    e.preventDefault();
    const draggedId = sectionDragRef.current;
    const insertIdx = sectionInsertRef.current;
    endSectionDrag();
    if (insertIdx == null) return;

    const srcIdx = sections.findIndex(s => s.id === draggedId);
    if (srcIdx < 0) return;
    const adjustedIdx = insertIdx > srcIdx ? insertIdx - 1 : insertIdx;
    if (adjustedIdx === srcIdx) return;

    const next = [...sections];
    const [moved] = next.splice(srcIdx, 1);
    next.splice(adjustedIdx, 0, moved);
    setSections(next);

    await apiReorderSections(next.map(s => s.id));
  };

  // -------- Pool-Resize ----------------------------------------------------
  const startResize = (e: React.MouseEvent) => {
    e.preventDefault();
    setResizing(true);
    const startX = e.clientX;
    const startW = poolWidth;
    const onMove = (ev: MouseEvent) => setPoolWidth(Math.max(260, Math.min(600, startW - (ev.clientX - startX))));
    const onUp = () => {
      setResizing(false);
      document.removeEventListener('mousemove', onMove);
      document.removeEventListener('mouseup', onUp);
    };
    document.addEventListener('mousemove', onMove);
    document.addEventListener('mouseup', onUp);
  };

  // -------- Render ---------------------------------------------------------
  return (
    <div className="flex flex-1 h-full -m-6" style={{ fontFamily: "'Roboto', sans-serif" }}>
      {/* LEFT: Card Editor */}
      <div className="flex-1 overflow-y-auto p-6 min-w-0">
        <div className="max-w-3xl space-y-4">
          {/* Header */}
          <div className="flex items-start justify-between">
            <div>
              <h1 className="text-3xl font-bold">{menu.name}</h1>
              <p className="text-base text-gray-400 mt-1">
                {menu.locationName} &middot; {menu.type} &middot; {sections.length} Sektionen &middot; {total} Produkte
              </p>
            </div>
            <div className="flex gap-2">
              <a href={menu.publicUrl} target="_blank" rel="noreferrer"
                className="rounded-lg border px-3 py-1.5 text-sm font-medium hover:bg-gray-50">
                Vorschau &#8599;
              </a>
              <button
                type="button"
                onClick={() => setDrawerOpen(true)}
                className="rounded-lg px-3 py-1.5 text-sm font-medium inline-flex items-center gap-1 transition-colors"
                style={{
                  border: '1px solid var(--color-primary)',
                  color: 'var(--color-primary)',
                  backgroundColor: 'transparent',
                }}
                onMouseEnter={e => { e.currentTarget.style.backgroundColor = 'rgba(221,60,113,0.08)'; }}
                onMouseLeave={e => { e.currentTarget.style.backgroundColor = 'transparent'; }}
              >
                <span className="material-symbols-outlined" style={{ fontSize: 16, fontVariationSettings: "'FILL' 0, 'wght' 500" }}>palette</span>
                Vorlage
              </button>
              {drawerOpen && (
                <TemplatePickerDrawer
                  menuId={menu.id}
                  currentTemplateId={menu.templateId}
                  onClose={() => setDrawerOpen(false)}
                />
              )}
              <span className={`rounded-full px-3 py-1.5 text-sm font-medium ${menu.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                {menu.isActive ? 'Aktiv' : 'Inaktiv'}
              </span>
            </div>
          </div>

          {menu.qrCodes.length > 0 && (
            <div className="flex gap-2 flex-wrap">
              {menu.qrCodes.map(qr => (
                <span key={qr.id} className="rounded-lg bg-gray-100 px-3 py-1 text-sm text-gray-600">
                  {qr.label || qr.shortCode}
                </span>
              ))}
            </div>
          )}

          {/* Fehler-Hinweis */}
          {error && (
            <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-2 text-sm text-red-700 flex items-center justify-between">
              <span>{error}</span>
              <button onClick={() => setError(null)} className="text-red-500 hover:text-red-700">
                <span className="material-symbols-outlined" style={{ fontSize: 18 }}>close</span>
              </button>
            </div>
          )}

          {/* Info-Hinweis zur Navigation */}
          <div className="rounded-lg border border-gray-200 bg-gray-50 px-4 py-2.5 text-sm text-gray-600 flex items-start gap-2">
            <span className="material-symbols-outlined text-gray-400" style={{ fontSize: 18, marginTop: 1 }}>info</span>
            <span>
              <strong>Sektionen</strong> sind die Kategorien Ihrer Karte (Vorspeisen, Hauptgerichte, Weine etc.).
              Reihenfolge und Bezeichnung erscheinen genauso in der Gästeansicht, im Inhaltsverzeichnis und im PDF.
            </span>
          </div>

          {/* Section List */}
          {sections.length === 0 && !adding && (
            <div className="rounded-xl border-2 border-dashed border-gray-300 px-6 py-12 text-center">
              <span className="material-symbols-outlined text-gray-300" style={{ fontSize: 48 }}>layers</span>
              <h3 className="mt-2 text-lg font-semibold text-gray-600">Noch keine Sektionen</h3>
              <p className="mt-1 text-sm text-gray-400">
                Legen Sie Ihre erste Kategorie an, um Produkte zu platzieren.
              </p>
              <button
                onClick={() => setAdding(true)}
                className="mt-4 inline-flex items-center gap-1 rounded-lg px-4 py-2 text-sm font-medium text-white"
                style={{ backgroundColor: '#22C55E' }}
              >
                <span className="material-symbols-outlined" style={{ fontSize: 18 }}>add</span>
                Erste Sektion anlegen
              </button>
            </div>
          )}

          {/* Sections */}
          {sections.map((sec, secIdx) => {
            const isEditing = editingSectionId === sec.id;
            const showIconPicker = iconPickerFor === sec.id;

            return (
              <div key={sec.id}>
                {/* Drop-Zone oberhalb dieser Sektion */}
                <div
                  onDragOver={e => overSectionGap(e, secIdx)}
                  onDrop={dropSectionAtGap}
                  style={sectionInsertAt === secIdx ? sectionInsertStyle : { height: 8 }}
                />

                <div className="rounded-xl border bg-white shadow-sm overflow-visible">
                  {/* Section Header */}
                  <div className="border-b bg-gray-50/50 px-3 py-3 flex items-center gap-2">
                    {/* Drag-Handle */}
                    <button
                      draggable
                      onDragStart={e => startSectionDrag(e, sec.id)}
                      onDragEnd={endSectionDrag}
                      title="Sektion verschieben"
                      className="cursor-grab active:cursor-grabbing text-gray-300 hover:text-gray-600 p-1 -ml-1"
                    >
                      <span className="material-symbols-outlined" style={{ fontSize: 22 }}>drag_indicator</span>
                    </button>

                    {/* Icon-Picker-Button */}
                    <div className="relative">
                      <button
                        onClick={() => { setIconPickerFor(showIconPicker ? null : sec.id); setEditingSectionId(null); }}
                        title="Icon ändern"
                        className="w-9 h-9 rounded-lg border border-gray-200 hover:border-gray-400 hover:bg-white flex items-center justify-center transition-colors"
                      >
                        {sec.icon ? (
                          <span
                            className="material-symbols-outlined"
                            style={{
                              fontSize: 22,
                              color: 'var(--color-primary)',
                              fontVariationSettings: "'FILL' 0, 'wght' 400",
                              lineHeight: 1,
                            }}
                          >
                            {sec.icon}
                          </span>
                        ) : (
                          <span className="material-symbols-outlined text-gray-300" style={{ fontSize: 20 }}>image</span>
                        )}
                      </button>

                      {showIconPicker && (
                        <div className="absolute z-40 mt-1 left-0 w-80 rounded-xl border bg-white shadow-xl p-3 max-h-96 overflow-y-auto">
                          <div className="flex items-center justify-between mb-2">
                            <h4 className="text-sm font-semibold text-gray-700">Icon wählen</h4>
                            <button onClick={() => setIconPickerFor(null)} className="text-gray-400 hover:text-gray-600">
                              <span className="material-symbols-outlined" style={{ fontSize: 18 }}>close</span>
                            </button>
                          </div>
                          <button
                            onClick={() => pickIcon(sec.id, null)}
                            className="mb-2 w-full rounded border border-gray-200 py-1.5 text-xs text-gray-500 hover:bg-gray-50"
                          >
                            Kein Icon
                          </button>
                          {MENU_ICONS.map(grp => (
                            <div key={grp.group} className="mb-3 last:mb-0">
                              <p className="text-[10px] font-semibold uppercase tracking-wide text-gray-400 mb-1">{grp.group}</p>
                              <div className="grid grid-cols-8 gap-1">
                                {grp.icons.map(ic => (
                                  <button
                                    key={ic}
                                    onClick={() => pickIcon(sec.id, ic)}
                                    title={ic}
                                    className={`w-8 h-8 rounded flex items-center justify-center transition-colors ${sec.icon === ic ? 'bg-pink-50 ring-2 ring-pink-300' : 'hover:bg-gray-100'}`}
                                  >
                                    <span className="material-symbols-outlined" style={{ fontSize: 18, color: 'var(--color-primary)' }}>{ic}</span>
                                  </button>
                                ))}
                              </div>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>

                    {/* Name + Rename */}
                    <div className="flex-1 min-w-0">
                      {isEditing ? (
                        <div className="flex items-center gap-2">
                          <input
                            autoFocus
                            type="text"
                            value={editingName}
                            onChange={e => setEditingName(e.target.value)}
                            onKeyDown={e => {
                              if (e.key === 'Enter') submitRename();
                              if (e.key === 'Escape') setEditingSectionId(null);
                            }}
                            onBlur={submitRename}
                            maxLength={80}
                            className="flex-1 rounded border border-gray-300 px-2 py-1 text-base font-semibold outline-none focus:border-[#DD3C71]"
                          />
                        </div>
                      ) : (
                        <button
                          onClick={() => startRename(sec)}
                          title="Umbenennen"
                          className="text-left w-full group/title"
                        >
                          <h2 className="text-base font-semibold text-gray-800 flex items-center gap-1.5 truncate">
                            <span className="truncate">{sec.name}</span>
                            <span className="material-symbols-outlined text-gray-300 opacity-0 group-hover/title:opacity-100 transition-opacity" style={{ fontSize: 16 }}>edit</span>
                          </h2>
                          <p className="text-sm text-gray-400">{sec.placements.length} Produkte</p>
                        </button>
                      )}
                    </div>

                    {/* Delete */}
                    {deleteConfirmFor === sec.id ? (
                      <div className="flex items-center gap-1">
                        <span className="text-sm text-gray-600 mr-1">Sicher?</span>
                        <button
                          onClick={() => deleteSection(sec.id, false)}
                          className="rounded px-2 py-1 text-sm font-semibold text-white"
                          style={{ backgroundColor: '#DD3C71' }}
                        >
                          Löschen
                        </button>
                        <button
                          onClick={() => setDeleteConfirmFor(null)}
                          className="rounded border px-2 py-1 text-sm text-gray-600 hover:bg-gray-50"
                        >
                          Abbrechen
                        </button>
                      </div>
                    ) : (
                      <button
                        onClick={() => setDeleteConfirmFor(sec.id)}
                        title="Sektion löschen"
                        className="rounded p-1.5 text-gray-300 hover:text-red-500 hover:bg-red-50 transition-colors"
                      >
                        <span className="material-symbols-outlined" style={{ fontSize: 20 }}>delete</span>
                      </button>
                    )}
                  </div>

                  {/* Placements */}
                  {sec.placements.map((pl, i) => {
                    const activeInsert = insertAt?.sid === sec.id && insertAt?.idx === i;
                    return (
                      <div key={pl.id}>
                        <div
                          onDragOver={e => { if (!dragRef.current) return; e.preventDefault(); setInsertAt({ sid: sec.id, idx: i }); }}
                          onDrop={dropAtInsert}
                          style={{
                            height: activeInsert ? 48 : 0,
                            transition: 'height 0.25s ease',
                            overflow: 'hidden',
                            ...(activeInsert ? placementInsertStyle : { background: 'transparent', border: 'none', margin: 0 }),
                          }}
                        />
                        <div
                          draggable
                          onDragStart={e => startDrag(e, pl.variantId, sec.id)}
                          onDragEnd={endDrag}
                          onDragOver={e => overItem(e, sec.id, i)}
                          onDrop={dropAtInsert}
                          className={`flex items-center justify-between px-4 py-2.5 border-b last:border-0 cursor-grab active:cursor-grabbing transition-all duration-150 group ${!pl.isVisible ? 'bg-red-50/30' : 'hover:bg-gray-50/50'}`}
                        >
                          <div className="flex items-center gap-3 flex-1 min-w-0">
                            <span className="text-gray-300 cursor-grab group-hover:text-gray-500">&#x283F;</span>
                            <span className={`flex-shrink-0 rounded px-1 py-0.5 text-sm font-bold ${TB[pl.type]?.c || TB.OTHER.c}`}>
                              {TB[pl.type]?.l || '?'}
                            </span>
                            <div className="min-w-0 flex-1">
                              <div className="flex items-center gap-2">
                                <Link
                                  href={`/admin/items/${pl.productId}`}
                                  className={`text-base font-medium truncate transition-colors ${!pl.isVisible ? 'text-gray-400 line-through' : 'text-gray-800'}`}
                                  onMouseEnter={e => { if (pl.isVisible) e.currentTarget.style.color = 'var(--color-primary)'; }}
                                  onMouseLeave={e => { if (pl.isVisible) e.currentTarget.style.color = ''; }}
                                >
                                  {pl.name}
                                </Link>
                                {pl.variantLabel && (
                                  <span className="rounded bg-gray-100 px-1.5 py-0.5 text-xs text-gray-500 flex-shrink-0">
                                    {pl.variantLabel}
                                  </span>
                                )}
                                {!pl.isVisible && (
                                  <span className="bg-red-100 text-red-600 text-sm font-bold px-1.5 py-0.5 rounded flex-shrink-0">
                                    AUSGETRUNKEN
                                  </span>
                                )}
                              </div>
                              {pl.winery && (
                                <p className="text-sm text-gray-400">
                                  {pl.winery}{pl.vintage ? ` ${pl.vintage}` : ''}
                                </p>
                              )}
                            </div>
                          </div>
                          <div className="flex items-center gap-1.5 flex-shrink-0 opacity-60 group-hover:opacity-100 transition-opacity">
                            {pl.price !== null && (
                              <span className="text-base font-semibold text-gray-600 tabular-nums mr-1">{fmtEur(pl.price)}</span>
                            )}
                            <button
                              onClick={() => toggleVisible(pl.id, sec.id, pl.isVisible)}
                              title={pl.isVisible ? 'Als ausgetrunken markieren' : 'Wieder verfügbar'}
                              className={`rounded-full w-6 h-6 flex items-center justify-center text-sm transition-all ${pl.isVisible ? 'bg-green-100 text-green-600 hover:bg-red-100 hover:text-red-500' : 'bg-red-100 text-red-600 hover:bg-green-100 hover:text-green-600'}`}
                            >
                              {pl.isVisible ? '\u25CF' : '\u25CB'}
                            </button>
                            <button
                              onClick={() => removePlacement(pl.id, sec.id)}
                              title="Entfernen"
                              className="rounded p-1 text-gray-300 hover:text-red-500 hover:bg-red-50 transition-colors text-sm"
                            >
                              &times;
                            </button>
                          </div>
                        </div>
                      </div>
                    );
                  })}

                  {/* Drop-Zone am Ende der Sektion */}
                  {(() => {
                    const endIdx = sec.placements.length;
                    const activeEnd = insertAt?.sid === sec.id && insertAt?.idx === endIdx && endIdx > 0;
                    return (
                      <div
                        onDragOver={e => { if (!dragRef.current) return; e.preventDefault(); setInsertAt({ sid: sec.id, idx: endIdx }); }}
                        onDrop={dropAtInsert}
                        style={{
                          height: activeEnd ? 48 : 4,
                          transition: 'height 0.25s ease',
                          overflow: 'hidden',
                          ...(activeEnd ? placementInsertStyle : { background: 'transparent', border: 'none', margin: 0 }),
                        }}
                      />
                    );
                  })()}

                  {sec.placements.length === 0 && (
                    <div
                      onDragOver={e => overEmpty(e, sec.id)}
                      onDrop={dropAtInsert}
                      className="px-4 py-6 text-center text-sm text-gray-400 border-2 border-dashed border-gray-200 m-2 rounded-lg"
                    >
                      Produkte hierher ziehen oder aus dem Pool rechts hinzufügen
                    </div>
                  )}
                </div>
              </div>
            );
          })}

          {/* Drop-Zone nach letzter Sektion */}
          {sections.length > 0 && (
            <div
              onDragOver={e => overSectionGap(e, sections.length)}
              onDrop={dropSectionAtGap}
              style={sectionInsertAt === sections.length ? sectionInsertStyle : { height: 8 }}
            />
          )}

          {/* Neue Sektion anlegen */}
          {adding ? (
            <div className="rounded-xl border bg-white shadow-sm p-4">
              <h3 className="text-sm font-semibold text-gray-700 mb-3">Neue Sektion</h3>
              <div className="flex items-start gap-3">
                {/* Icon-Preview + Quick-Picker */}
                <div className="flex-shrink-0">
                  <button
                    onClick={() => setNewSectionIcon(newSectionIcon === null ? 'restaurant_menu' : null)}
                    title="Icon umschalten"
                    className="w-12 h-12 rounded-lg border-2 border-dashed border-gray-300 hover:border-gray-400 flex items-center justify-center"
                  >
                    {newSectionIcon ? (
                      <span className="material-symbols-outlined" style={{ fontSize: 26, color: 'var(--color-primary)' }}>{newSectionIcon}</span>
                    ) : (
                      <span className="material-symbols-outlined text-gray-300" style={{ fontSize: 22 }}>image</span>
                    )}
                  </button>
                  <div className="mt-1 flex flex-wrap gap-1 w-12">
                    {/* Zugang zum vollen Picker nach Erstellen - hier nur 1 Reset-Knopf */}
                  </div>
                </div>
                <div className="flex-1 min-w-0">
                  <input
                    autoFocus
                    type="text"
                    value={newSectionName}
                    onChange={e => setNewSectionName(e.target.value)}
                    onKeyDown={e => {
                      if (e.key === 'Enter') submitNewSection();
                      if (e.key === 'Escape') { setAdding(false); setNewSectionName(''); }
                    }}
                    placeholder="z.B. Vorspeisen, Hauptgerichte, Offene Weine..."
                    maxLength={80}
                    className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-[#DD3C71]"
                  />
                  <div className="mt-2 grid grid-cols-12 gap-1">
                    {MENU_ICONS.flatMap(g => g.icons).slice(0, 24).map(ic => (
                      <button
                        key={ic}
                        onClick={() => setNewSectionIcon(ic)}
                        title={ic}
                        className={`h-8 rounded flex items-center justify-center transition-colors ${newSectionIcon === ic ? 'bg-pink-50 ring-2 ring-pink-300' : 'hover:bg-gray-100'}`}
                      >
                        <span className="material-symbols-outlined" style={{ fontSize: 16, color: 'var(--color-primary)' }}>{ic}</span>
                      </button>
                    ))}
                  </div>
                  <div className="mt-3 flex items-center gap-2">
                    <button
                      onClick={submitNewSection}
                      disabled={!newSectionName.trim()}
                      className="rounded-lg px-4 py-2 text-sm font-medium text-white disabled:opacity-40"
                      style={{ backgroundColor: '#22C55E' }}
                    >
                      Anlegen
                    </button>
                    <button
                      onClick={() => { setAdding(false); setNewSectionName(''); }}
                      className="rounded-lg border px-4 py-2 text-sm text-gray-600 hover:bg-gray-50"
                    >
                      Abbrechen
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ) : sections.length > 0 ? (
            <button
              onClick={() => setAdding(true)}
              className="w-full rounded-xl border-2 border-dashed border-gray-300 px-4 py-4 text-sm font-medium text-gray-500 hover:border-[#22C55E] hover:bg-green-50 hover:text-[#22C55E] transition-colors flex items-center justify-center gap-2"
            >
              <span className="material-symbols-outlined" style={{ fontSize: 20 }}>add_circle</span>
              Neue Sektion anlegen
            </button>
          ) : null}
        </div>
      </div>

      {/* RIGHT: Product/Variant Pool */}
      <div
        onDragOver={e => { if (!dragRef.current) return; e.preventDefault(); if (dragRef.current?.fromSection) setBrowserDrop(true); }}
        onDragLeave={() => setBrowserDrop(false)}
        onDrop={dropBrowser}
        className={`relative flex flex-col border-l transition-colors flex-shrink-0 ${browserDrop ? 'bg-red-50 border-l-2 border-l-red-400' : 'bg-white'}`}
        style={{ width: poolWidth }}
      >
        <div
          onMouseDown={startResize}
          className="absolute left-0 top-0 h-full w-1.5 cursor-col-resize transition-colors"
          style={{
            zIndex: 10,
            backgroundColor: resizing ? 'rgba(221,60,113,0.4)' : 'transparent',
          }}
          onMouseEnter={e => { if (!resizing) e.currentTarget.style.backgroundColor = 'rgba(221,60,113,0.2)'; }}
          onMouseLeave={e => { if (!resizing) e.currentTarget.style.backgroundColor = 'transparent'; }}
        />
        <div className="border-b px-3 py-3">
          <div className="flex items-center justify-between mb-2">
            <h2 className="text-base font-semibold text-gray-700">
              {browserDrop ? 'Hier ablegen = Entfernen' : 'Variantenpool'}
            </h2>
            <span className="text-sm text-gray-400">{available.length}</span>
          </div>
          <div className="relative">
            <span className="material-symbols-outlined absolute left-2.5 top-1/2 -translate-y-1/2 opacity-30" style={{ fontSize: 16 }}>search</span>
            <input
              type="text"
              value={query}
              onChange={e => setQuery(e.target.value)}
              placeholder="Suchen..."
              className="w-full rounded-lg border bg-gray-50 py-1.5 pl-8 pr-2 text-sm outline-none focus:border-gray-400 focus:bg-white"
            />
          </div>
          <div className="mt-2 flex gap-1.5">
            <select
              value={typeFilter}
              onChange={e => { setTypeFilter(e.target.value); setGroupFilter(''); }}
              className="flex-1 rounded border bg-gray-50 px-1.5 py-1 text-sm outline-none"
            >
              <option value="">Alle Typen</option>
              <option value="WINE">Wein</option>
              <option value="DRINK">Getränk</option>
              <option value="FOOD">Speise</option>
              <option value="SPIRIT">Spirituose</option>
              <option value="BEER">Bier</option>
              <option value="COFFEE">Kaffee</option>
            </select>
            <select
              value={groupFilter}
              onChange={e => setGroupFilter(e.target.value)}
              className="flex-1 rounded border bg-gray-50 px-1.5 py-1 text-sm outline-none"
            >
              <option value="">Alle Gruppen</option>
              {filteredGroups.map(g => (
                <option key={g.slug} value={g.slug}>
                  {g.parentName ? `${g.parentName} \u2192 ${g.name}` : g.name}
                </option>
              ))}
            </select>
            <select
              value={statusFilter}
              onChange={e => setStatusFilter(e.target.value)}
              className="flex-1 rounded border bg-gray-50 px-1.5 py-1 text-sm outline-none"
            >
              <option value="">Status</option>
              <option value="ACTIVE">Aktiv</option>
              <option value="DRAFT">Entwurf</option>
              <option value="ARCHIVED">Archiviert</option>
            </select>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto">
          {available.map(p => {
            const b = TB[p.type] || TB.OTHER;
            return (
              <div
                key={p.id}
                draggable
                onDragStart={e => startDrag(e, p.id, null)}
                onDragEnd={endDrag}
                className="flex items-center gap-2 border-b px-3 py-2.5 cursor-grab active:cursor-grabbing hover:bg-gray-50 transition-colors group"
              >
                <span className="text-gray-300 text-sm group-hover:text-gray-500">&#x283F;</span>
                <span className={`flex-shrink-0 rounded px-1 py-0.5 text-sm font-bold ${b.c}`}>{b.l}</span>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-1.5">
                    <p className="text-sm font-medium text-gray-800 truncate">{p.name}</p>
                    {p.variantLabel && (
                      <span className="rounded bg-gray-100 px-1 py-0.5 text-xs text-gray-500 flex-shrink-0">
                        {p.variantLabel}
                      </span>
                    )}
                  </div>
                  <p className="text-sm text-gray-400 truncate">
                    {p.groupName}{p.winery ? ` \u00B7 ${p.winery}` : ''}
                  </p>
                </div>
                {p.price !== null && (
                  <span className="text-sm font-semibold text-gray-500 tabular-nums flex-shrink-0">
                    {fmtEur(p.price)}
                  </span>
                )}
                <div className="relative group/add">
                  <button className="text-gray-300 hover:text-[#22C55E] text-base font-bold">+</button>
                  <div className="absolute right-0 top-5 z-30 hidden group-hover/add:block rounded-lg border bg-white shadow-lg py-1 w-48">
                    {sections.length === 0 ? (
                      <div className="px-3 py-2 text-sm text-gray-400">Zuerst Sektion anlegen</div>
                    ) : (
                      sections.map(s => (
                        <button
                          key={s.id}
                          onClick={() => clickAdd(p.id, s.id)}
                          className="block w-full px-3 py-1.5 text-left text-sm hover:bg-gray-50 truncate"
                        >
                          &rarr; {s.name}
                        </button>
                      ))
                    )}
                  </div>
                </div>
              </div>
            );
          })}
          {available.length === 0 && (
            <div className="px-4 py-8 text-center text-sm text-gray-400">
              {assignedVariantIds.size === allProducts.length ? 'Alle Varianten zugeordnet' : 'Keine Treffer'}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
