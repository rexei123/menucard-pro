'use client';

import { useState, useMemo, useRef } from 'react';
import Link from 'next/link';
import TemplatePickerDrawer from './template-picker-drawer';

type Placement = { id: string; productId: string; name: string; winery: string | null; vintage: number | null; price: number | null; type: string; sortOrder: number; isVisible: boolean };
type Section = { id: string; slug: string; name: string; icon: string | null; placements: Placement[] };
type BrowserProduct = { id: string; name: string; type: string; groupName: string; groupSlug: string; price: number | null; winery: string | null; vintage: number | null; status: string };
type MenuInfo = { id: string; name: string; slug: string; type: string; locationName: string; isActive: boolean; publicUrl: string; templateId: string | null; qrCodes: { id: string; label: string | null; shortCode: string }[]; sections: Section[] };

const TB: Record<string, { l: string; c: string }> = { WINE: { l: 'W', c: 'bg-purple-100 text-purple-700' }, DRINK: { l: 'G', c: 'bg-blue-100 text-blue-700' }, FOOD: { l: 'S', c: 'bg-orange-100 text-orange-700' }, OTHER: { l: '?', c: 'bg-gray-100 text-gray-600' } };
const fmtEur = (p: number) => new Intl.NumberFormat('de-AT', { style: 'currency', currency: 'EUR' }).format(p);

// Drop-Indicator style (UI-Design-konform, rosa)
const dropIndicatorActive = {
  background: 'linear-gradient(90deg, rgba(221,60,113,0.08), rgba(221,60,113,0.18))',
  border: '2px dashed var(--color-primary)',
  borderRadius: 8,
  margin: '4px 12px',
};

export default function MenuEditor({ menu, allProducts, groups }: { menu: MenuInfo; allProducts: BrowserProduct[]; groups: { slug: string; name: string; parentName: string | null }[] }) {
  const [sections, setSections] = useState(menu.sections);
  const [insertAt, setInsertAtState] = useState<{ sid: string; idx: number } | null>(null);
  const insertRef = useRef<{ sid: string; idx: number } | null>(null);
  const setInsertAt = (v: { sid: string; idx: number } | null) => { insertRef.current = v; setInsertAtState(v); };
  const [browserDrop, setBrowserDrop] = useState(false);
  const [query, setQuery] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [groupFilter, setGroupFilter] = useState('');
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [statusFilter, setStatusFilter] = useState('');
  const [poolWidth, setPoolWidth] = useState(500);
  const [resizing, setResizing] = useState(false);
  const dragRef = useRef<{ productId: string; fromSection: string | null } | null>(null);

  const assignedIds = useMemo(() => {
    const s = new Set<string>();
    sections.forEach(sec => sec.placements.forEach(p => s.add(p.productId)));
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
      if (assignedIds.has(p.id)) return false;
      if (typeFilter && p.type !== typeFilter) return false;
      if (groupFilter && p.groupSlug !== groupFilter) return false;
      if (statusFilter && p.status !== statusFilter) return false;
      if (q && !`${p.name} ${p.groupName} ${p.winery || ''}`.toLowerCase().includes(q)) return false;
      return true;
    });
  }, [allProducts, assignedIds, query, typeFilter, groupFilter, statusFilter]);

  // API
  const apiAdd = async (sectionId: string, productId: string, sortOrder: number) => {
    const res = await fetch('/api/v1/placements', { method: 'POST', credentials: 'include', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ menuSectionId: sectionId, productId, sortOrder }) });
    return res.ok ? await res.json() : null;
  };
  const apiRemove = async (id: string) => { await fetch(`/api/v1/placements/${id}`, { method: 'DELETE', credentials: 'include' }); };
  const apiPatch = async (id: string, data: any) => { await fetch(`/api/v1/placements/${id}`, { method: 'PATCH', credentials: 'include', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data) }); };

  // Drag
  const startDrag = (e: React.DragEvent, productId: string, fromSection: string | null) => {
    dragRef.current = { productId, fromSection };
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData('text/plain', productId);
  };

  const endDrag = () => {
    dragRef.current = null;
    setInsertAt(null);
    setBrowserDrop(false);
  };

  const overItem = (e: React.DragEvent, sid: string, idx: number) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
    const insertIdx = e.clientY < rect.top + rect.height / 2 ? idx : idx + 1;
    setInsertAt({ sid, idx: insertIdx });
  };

  const overEmpty = (e: React.DragEvent, sid: string) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
    setInsertAt({ sid, idx: 0 });
  };

  const dropAtInsert = async (e: React.DragEvent) => {
    e.preventDefault();
    const ins = insertRef.current;
    setInsertAt(null);
    const drag = dragRef.current;
    if (!drag || !ins) return;
    const { productId, fromSection } = drag;
    const sid = ins.sid;
    const idx = ins.idx;

    const sec = sections.find(s => s.id === sid);
    const existingHere = sec?.placements.find(p => p.productId === productId);
    if (existingHere && fromSection === sid) {
      setSections(prev => prev.map(s => {
        if (s.id !== sid) return s;
        const without = s.placements.filter(p => p.productId !== productId);
        const adjustedIdx = idx > s.placements.indexOf(existingHere) ? idx - 1 : idx;
        without.splice(adjustedIdx, 0, existingHere);
        return { ...s, placements: without.map((p, i) => ({ ...p, sortOrder: i })) };
      }));
      endDrag();
      return;
    }

    if (fromSection) {
      let moving: Placement | null = null;
      for (const s of sections) { const f = s.placements.find(p => p.productId === productId); if (f) { moving = f; break; } }
      if (moving) {
        await apiRemove(moving.id);
        setSections(prev => prev.map(s => s.id === fromSection ? { ...s, placements: s.placements.filter(p => p.productId !== productId) } : s));
      }
    }

    const prod = allProducts.find(p => p.id === productId);
    if (!prod) { endDrag(); return; }
    const pl = await apiAdd(sid, productId, idx);
    if (pl) {
      const np: Placement = { id: pl.id, productId: prod.id, name: prod.name, winery: prod.winery, vintage: prod.vintage, price: prod.price, type: prod.type, sortOrder: idx, isVisible: true };
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
    e.preventDefault();
    setBrowserDrop(false);
    const drag = dragRef.current;
    if (!drag || !drag.fromSection) { endDrag(); return; }
    let pl: Placement | null = null;
    let sid: string | null = null;
    for (const s of sections) { const f = s.placements.find(p => p.productId === drag.productId); if (f) { pl = f; sid = s.id; break; } }
    if (pl && sid) {
      await apiRemove(pl.id);
      setSections(prev => prev.map(s => s.id === sid ? { ...s, placements: s.placements.filter(p => p.productId !== drag.productId) } : s));
    }
    endDrag();
  };

  const clickAdd = async (productId: string, sectionId: string) => {
    const prod = allProducts.find(p => p.id === productId);
    if (!prod) return;
    const sec = sections.find(s => s.id === sectionId);
    const pl = await apiAdd(sectionId, productId, sec?.placements.length || 0);
    if (pl) {
      const np: Placement = { id: pl.id, productId: prod.id, name: prod.name, winery: prod.winery, vintage: prod.vintage, price: prod.price, type: prod.type, sortOrder: sec?.placements.length || 0, isVisible: true };
      setSections(prev => prev.map(s => s.id === sectionId ? { ...s, placements: [...s.placements, np] } : s));
    }
  };

  const remove = async (plId: string, sid: string) => {
    await apiRemove(plId);
    setSections(prev => prev.map(s => s.id === sid ? { ...s, placements: s.placements.filter(p => p.id !== plId) } : s));
  };

  const toggleVisible = async (plId: string, sid: string, current: boolean) => {
    await apiPatch(plId, { isVisible: !current });
    setSections(prev => prev.map(s => s.id === sid ? { ...s, placements: s.placements.map(p => p.id === plId ? { ...p, isVisible: !current } : p) } : s));
  };

  const startResize = (e: React.MouseEvent) => {
    e.preventDefault();
    setResizing(true);
    const startX = e.clientX;
    const startW = poolWidth;
    const onMove = (ev: MouseEvent) => setPoolWidth(Math.max(260, Math.min(600, startW - (ev.clientX - startX))));
    const onUp = () => { setResizing(false); document.removeEventListener('mousemove', onMove); document.removeEventListener('mouseup', onUp); };
    document.addEventListener('mousemove', onMove);
    document.addEventListener('mouseup', onUp);
  };

  const total = sections.reduce((s, sec) => s + sec.placements.length, 0);

  return (
    <div className="flex flex-1 h-full -m-6">
      {/* LEFT: Card Editor */}
      <div className="flex-1 overflow-y-auto p-6 min-w-0">
        <div className="max-w-3xl space-y-4">
          <div className="flex items-start justify-between">
            <div>
              <h1 className="text-3xl font-bold" style={{fontFamily: "'Playfair Display', serif"}}>{menu.name}</h1>
              <p className="text-base text-gray-400 mt-1">{menu.locationName} &middot; {menu.type} &middot; {sections.length} Sektionen &middot; {total} Produkte</p>
            </div>
            <div className="flex gap-2">
              <a href={menu.publicUrl} target="_blank" className="rounded-lg border px-3 py-1.5 text-sm font-medium hover:bg-gray-50">Vorschau &#8599;</a>
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
              <span className={`rounded-full px-3 py-1.5 text-sm font-medium ${menu.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>{menu.isActive ? 'Aktiv' : 'Inaktiv'}</span>
            </div>
          </div>

          {menu.qrCodes.length > 0 && (
            <div className="flex gap-2 flex-wrap">{menu.qrCodes.map(qr => <span key={qr.id} className="rounded-lg bg-gray-100 px-3 py-1 text-sm text-gray-600">{qr.label || qr.shortCode}</span>)}</div>
          )}

          {sections.map(sec => (
            <div key={sec.id} className="rounded-xl border bg-white shadow-sm overflow-visible">
              <div className="border-b bg-gray-50/50 px-4 py-3" onDragOver={e => overEmpty(e, sec.id)} onDrop={dropAtInsert}>
                <h2 className="text-base font-semibold flex items-center gap-2">
                  {sec.icon && (
                    <span
                      className="material-symbols-outlined select-none"
                      style={{
                        fontSize: 22,
                        color: 'var(--color-primary)',
                        fontVariationSettings: "'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 22",
                        lineHeight: 1,
                      }}
                    >
                      {sec.icon}
                    </span>
                  )}
                  <span>{sec.name}</span>
                </h2>
                <p className="text-sm text-gray-400">{sec.placements.length} Produkte</p>
              </div>

              {sec.placements.map((pl, i) => {
                const activeInsert = insertAt?.sid === sec.id && insertAt?.idx === i;
                return (
                  <div key={pl.id}>
                    <div
                      onDragOver={e => { e.preventDefault(); setInsertAt({ sid: sec.id, idx: i }); }}
                      onDrop={dropAtInsert}
                      style={{
                        height: activeInsert ? 48 : 0,
                        transition: 'height 0.25s ease',
                        overflow: 'hidden',
                        ...(activeInsert ? dropIndicatorActive : { background: 'transparent', border: 'none', margin: 0 }),
                      }}
                    />
                    <div draggable onDragStart={e => startDrag(e, pl.productId, sec.id)} onDragEnd={endDrag} onDragOver={e => overItem(e, sec.id, i)} onDrop={dropAtInsert}
                      className={`flex items-center justify-between px-4 py-2.5 border-b last:border-0 cursor-grab active:cursor-grabbing transition-all duration-150 group ${!pl.isVisible ? 'bg-red-50/30' : 'hover:bg-gray-50/50'}`}>
                      <div className="flex items-center gap-3 flex-1 min-w-0">
                        <span className="text-gray-300 cursor-grab group-hover:text-gray-500">&#x283F;</span>
                        <span className={`flex-shrink-0 rounded px-1 py-0.5 text-sm font-bold ${TB[pl.type]?.c || TB.OTHER.c}`}>{TB[pl.type]?.l || '?'}</span>
                        <div className="min-w-0 flex-1">
                          <div className="flex items-center gap-2">
                            <Link
                              href={`/admin/items/${pl.productId}`}
                              className={`text-base font-medium truncate transition-colors ${!pl.isVisible ? 'text-gray-400 line-through' : 'text-gray-800'}`}
                              style={!pl.isVisible ? {} : undefined}
                              onMouseEnter={e => { if (pl.isVisible) e.currentTarget.style.color = 'var(--color-primary)'; }}
                              onMouseLeave={e => { if (pl.isVisible) e.currentTarget.style.color = ''; }}
                            >
                              {pl.name}
                            </Link>
                            {!pl.isVisible && <span className="bg-red-100 text-red-600 text-sm font-bold px-1.5 py-0.5 rounded flex-shrink-0">AUSGETRUNKEN</span>}
                          </div>
                          {pl.winery && <p className="text-sm text-gray-400">{pl.winery}{pl.vintage ? ` ${pl.vintage}` : ''}</p>}
                        </div>
                      </div>
                      <div className="flex items-center gap-1.5 flex-shrink-0 opacity-60 group-hover:opacity-100 transition-opacity">
                        {pl.price !== null && <span className="text-base font-semibold text-gray-600 tabular-nums mr-1">{fmtEur(pl.price)}</span>}
                        <button onClick={() => toggleVisible(pl.id, sec.id, pl.isVisible)} title={pl.isVisible ? 'Als ausgetrunken markieren' : 'Wieder verfuegbar'}
                          className={`rounded-full w-6 h-6 flex items-center justify-center text-sm transition-all ${pl.isVisible ? 'bg-green-100 text-green-600 hover:bg-red-100 hover:text-red-500' : 'bg-red-100 text-red-600 hover:bg-green-100 hover:text-green-600'}`}>
                          {pl.isVisible ? '\u25CF' : '\u25CB'}
                        </button>
                        <button onClick={() => remove(pl.id, sec.id)} title="Entfernen" className="rounded p-1 text-gray-300 hover:text-red-500 hover:bg-red-50 transition-colors text-sm">&times;</button>
                      </div>
                    </div>
                  </div>
                );
              })}

              {(() => {
                const endIdx = sec.placements.length;
                const activeEnd = insertAt?.sid === sec.id && insertAt?.idx === endIdx && endIdx > 0;
                return (
                  <div
                    onDragOver={e => { e.preventDefault(); setInsertAt({ sid: sec.id, idx: endIdx }); }}
                    onDrop={dropAtInsert}
                    style={{
                      height: activeEnd ? 48 : 4,
                      transition: 'height 0.25s ease',
                      overflow: 'hidden',
                      ...(activeEnd ? dropIndicatorActive : { background: 'transparent', border: 'none', margin: 0 }),
                    }}
                  />
                );
              })()}

              {sec.placements.length === 0 && (
                <div onDragOver={e => overEmpty(e, sec.id)} onDrop={dropAtInsert}
                  className="px-4 py-6 text-center text-sm text-gray-400 border-2 border-dashed border-gray-200 m-2 rounded-lg">
                  Produkte hierher ziehen oder aus dem Pool rechts hinzufuegen
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* RIGHT: Product Pool */}
      <div onDragOver={e => { e.preventDefault(); if (dragRef.current?.fromSection) setBrowserDrop(true); }}
        onDragLeave={() => setBrowserDrop(false)} onDrop={dropBrowser}
        className={`relative flex flex-col border-l transition-colors flex-shrink-0 ${browserDrop ? 'bg-red-50 border-l-2 border-l-red-400' : 'bg-white'}`} style={{ width: poolWidth }}>
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
            <h2 className="text-base font-semibold text-gray-700">{browserDrop ? 'Hier ablegen = Entfernen' : 'Produktpool'}</h2>
            <span className="text-sm text-gray-400">{available.length}</span>
          </div>
          <div className="relative">
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="absolute left-2.5 top-1/2 -translate-y-1/2 opacity-30"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
            <input type="text" value={query} onChange={e => setQuery(e.target.value)} placeholder="Suchen..." className="w-full rounded-lg border bg-gray-50 py-1.5 pl-8 pr-2 text-sm outline-none focus:border-gray-400 focus:bg-white" />
          </div>
          <div className="mt-2 flex gap-1.5">
            <select value={typeFilter} onChange={e => { setTypeFilter(e.target.value); setGroupFilter(''); }} className="flex-1 rounded border bg-gray-50 px-1.5 py-1 text-sm outline-none">
              <option value="">Alle Typen</option>
              <option value="WINE">Wein</option>
              <option value="DRINK">Getraenk</option>
              <option value="FOOD">Speise</option>
            </select>
            <select value={groupFilter} onChange={e => setGroupFilter(e.target.value)} className="flex-1 rounded border bg-gray-50 px-1.5 py-1 text-sm outline-none">
              <option value="">Alle Gruppen</option>
              {filteredGroups.map(g => <option key={g.slug} value={g.slug}>{g.parentName ? `${g.parentName} \u2192 ${g.name}` : g.name}</option>)}
            </select>
            <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)} className="flex-1 rounded border bg-gray-50 px-1.5 py-1 text-sm outline-none">
              <option value="">Status</option>
              <option value="ACTIVE">Aktiv</option>
              <option value="DRAFT">Entwurf</option>
              <option value="SOLD_OUT">Ausverkauft</option>
            </select>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto">
          {available.map(p => {
            const b = TB[p.type] || TB.OTHER;
            return (
              <div key={p.id} draggable onDragStart={e => startDrag(e, p.id, null)} onDragEnd={endDrag}
                className="flex items-center gap-2 border-b px-3 py-2.5 cursor-grab active:cursor-grabbing hover:bg-gray-50 transition-colors group">
                <span className="text-gray-300 text-sm group-hover:text-gray-500">&#x283F;</span>
                <span className={`flex-shrink-0 rounded px-1 py-0.5 text-sm font-bold ${b.c}`}>{b.l}</span>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-800 truncate">{p.name}</p>
                  <p className="text-sm text-gray-400 truncate">{p.groupName}{p.winery ? ` \u00B7 ${p.winery}` : ''}</p>
                </div>
                {p.price !== null && <span className="text-sm font-semibold text-gray-500 tabular-nums flex-shrink-0">{fmtEur(p.price)}</span>}
                <div className="relative group/add">
                  <button className="text-gray-300 hover:text-[#22C55E] text-base font-bold">+</button>
                  <div className="absolute right-0 top-5 z-30 hidden group-hover/add:block rounded-lg border bg-white shadow-lg py-1 w-48">
                    {sections.map(s => <button key={s.id} onClick={() => clickAdd(p.id, s.id)} className="block w-full px-3 py-1.5 text-left text-sm hover:bg-gray-50 truncate">&rarr; {s.name}</button>)}
                  </div>
                </div>
              </div>
            );
          })}
          {available.length === 0 && <div className="px-4 py-8 text-center text-sm text-gray-400">{assignedIds.size === allProducts.length ? 'Alle Produkte zugeordnet' : 'Keine Treffer'}</div>}
        </div>
      </div>
    </div>
  );
}
