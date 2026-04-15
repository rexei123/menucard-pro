#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Deploying Interactive Menu Editor ==="

echo "1/4 Creating Placement API..."

mkdir -p src/app/api/v1/placements
cat > src/app/api/v1/placements/route.ts << 'ENDFILE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const { menuSectionId, productId, sortOrder } = await req.json();
  if (!menuSectionId || !productId) return NextResponse.json({ error: 'Missing fields' }, { status: 400 });
  const existing = await prisma.menuPlacement.findUnique({ where: { menuSectionId_productId: { menuSectionId, productId } } });
  if (existing) return NextResponse.json({ error: 'Bereits zugeordnet' }, { status: 409 });
  const placement = await prisma.menuPlacement.create({ data: { menuSectionId, productId, sortOrder: sortOrder ?? 999, isVisible: true } });
  return NextResponse.json(placement, { status: 201 });
}
ENDFILE

mkdir -p "src/app/api/v1/placements/[id]"
cat > "src/app/api/v1/placements/[id]/route.ts" << 'ENDFILE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  await prisma.menuPlacement.delete({ where: { id: params.id } }).catch(() => null);
  return NextResponse.json({ success: true });
}

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const body = await req.json();
  const updated = await prisma.menuPlacement.update({ where: { id: params.id }, data: body });
  return NextResponse.json(updated);
}
ENDFILE

echo "2/4 Creating Menu Editor component..."

cat > src/components/admin/menu-editor.tsx << 'ENDOFCOMP'
'use client';

import { useState, useMemo } from 'react';
import Link from 'next/link';

type Placement = { id: string; productId: string; name: string; winery: string | null; vintage: number | null; price: number | null; type: string; sortOrder: number; isVisible: boolean };
type Section = { id: string; slug: string; name: string; icon: string | null; placements: Placement[] };
type BrowserProduct = { id: string; name: string; type: string; groupName: string; price: number | null; winery: string | null; vintage: number | null };
type MenuInfo = { id: string; name: string; slug: string; type: string; locationName: string; isActive: boolean; publicUrl: string; qrCodes: { id: string; label: string | null; shortCode: string }[]; sections: Section[] };

const TB: Record<string, { l: string; c: string }> = { WINE: { l: 'W', c: 'bg-purple-100 text-purple-700' }, DRINK: { l: 'G', c: 'bg-blue-100 text-blue-700' }, FOOD: { l: 'S', c: 'bg-orange-100 text-orange-700' }, OTHER: { l: '?', c: 'bg-gray-100 text-gray-600' } };
const fmtEur = (p: number) => new Intl.NumberFormat('de-AT', { style: 'currency', currency: 'EUR' }).format(p);

export default function MenuEditor({ menu, allProducts }: { menu: MenuInfo; allProducts: BrowserProduct[] }) {
  const [sections, setSections] = useState(menu.sections);
  const [dragId, setDragId] = useState<string | null>(null);
  const [dragFrom, setDragFrom] = useState<string | null>(null);
  const [insertAt, setInsertAt] = useState<{ sid: string; idx: number } | null>(null);
  const [browserDrop, setBrowserDrop] = useState(false);
  const [query, setQuery] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [addingTo, setAddingTo] = useState<string | null>(null);

  const assignedIds = useMemo(() => {
    const s = new Set<string>();
    sections.forEach(sec => sec.placements.forEach(p => s.add(p.productId)));
    return s;
  }, [sections]);

  const available = useMemo(() => {
    const q = query.toLowerCase().trim();
    return allProducts.filter(p => {
      if (assignedIds.has(p.id)) return false;
      if (typeFilter && p.type !== typeFilter) return false;
      if (q && !`${p.name} ${p.groupName} ${p.winery || ''}`.toLowerCase().includes(q)) return false;
      return true;
    });
  }, [allProducts, assignedIds, query, typeFilter]);

  // --- API calls ---
  const apiAdd = async (sectionId: string, productId: string, sortOrder: number) => {
    const res = await fetch('/api/v1/placements', { method: 'POST', credentials: 'include', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ menuSectionId: sectionId, productId, sortOrder }) });
    if (res.ok) return await res.json();
    return null;
  };
  const apiRemove = async (id: string) => { await fetch(`/api/v1/placements/${id}`, { method: 'DELETE', credentials: 'include' }); };
  const apiToggle = async (id: string, visible: boolean) => { await fetch(`/api/v1/placements/${id}`, { method: 'PATCH', credentials: 'include', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ isVisible: visible }) }); };

  // --- Drag handlers ---
  const onDragStart = (productId: string, fromSection: string | null) => { setDragId(productId); setDragFrom(fromSection); };
  const onDragEnd = () => { setDragId(null); setDragFrom(null); setInsertAt(null); setBrowserDrop(false); };

  const onDragOverSlot = (e: React.DragEvent, sid: string, idx: number) => {
    e.preventDefault(); e.dataTransfer.dropEffect = 'move';
    setInsertAt({ sid, idx });
  };

  const onDropSlot = async (e: React.DragEvent, sid: string, idx: number) => {
    e.preventDefault(); setInsertAt(null);
    if (!dragId) return;

    // If from same section = reorder
    const sec = sections.find(s => s.id === sid);
    const existingHere = sec?.placements.find(p => p.productId === dragId);
    if (existingHere) {
      setSections(prev => prev.map(s => {
        if (s.id !== sid) return s;
        const without = s.placements.filter(p => p.productId !== dragId);
        without.splice(idx > s.placements.indexOf(existingHere) ? idx - 1 : idx, 0, existingHere);
        return { ...s, placements: without.map((p, i) => ({ ...p, sortOrder: i })) };
      }));
      onDragEnd(); return;
    }

    // If from another section = move
    if (dragFrom) {
      let moving: Placement | null = null;
      sections.forEach(s => { const f = s.placements.find(p => p.productId === dragId); if (f) moving = f; });
      if (moving) {
        await apiRemove((moving as Placement).id);
        setSections(prev => prev.map(s => s.id === dragFrom ? { ...s, placements: s.placements.filter(p => p.productId !== dragId) } : s));
      }
    }

    // Add to section
    const prod = allProducts.find(p => p.id === dragId);
    if (!prod) { onDragEnd(); return; }
    const pl = await apiAdd(sid, dragId, idx);
    if (pl) {
      const np: Placement = { id: pl.id, productId: prod.id, name: prod.name, winery: prod.winery, vintage: prod.vintage, price: prod.price, type: prod.type, sortOrder: idx, isVisible: true };
      setSections(prev => prev.map(s => {
        if (s.id !== sid) return s;
        const pls = [...s.placements]; pls.splice(idx, 0, np);
        return { ...s, placements: pls.map((p, i) => ({ ...p, sortOrder: i })) };
      }));
    }
    onDragEnd();
  };

  // Drop on browser = remove
  const onDropBrowser = async (e: React.DragEvent) => {
    e.preventDefault(); setBrowserDrop(false);
    if (!dragId || !dragFrom) { onDragEnd(); return; }
    let pl: Placement | null = null;
    sections.forEach(s => { const f = s.placements.find(p => p.productId === dragId); if (f) pl = f; });
    if (pl) {
      await apiRemove((pl as Placement).id);
      setSections(prev => prev.map(s => ({ ...s, placements: s.placements.filter(p => p.productId !== dragId) })));
    }
    onDragEnd();
  };

  // Click add
  const clickAdd = async (productId: string, sectionId: string) => {
    const prod = allProducts.find(p => p.id === productId);
    if (!prod) return;
    const sec = sections.find(s => s.id === sectionId);
    const pl = await apiAdd(sectionId, productId, sec?.placements.length || 0);
    if (pl) {
      const np: Placement = { id: pl.id, productId: prod.id, name: prod.name, winery: prod.winery, vintage: prod.vintage, price: prod.price, type: prod.type, sortOrder: sec?.placements.length || 0, isVisible: true };
      setSections(prev => prev.map(s => s.id === sectionId ? { ...s, placements: [...s.placements, np] } : s));
    }
    setAddingTo(null);
  };

  // Remove
  const remove = async (placementId: string, sectionId: string) => {
    await apiRemove(placementId);
    setSections(prev => prev.map(s => s.id === sectionId ? { ...s, placements: s.placements.filter(p => p.id !== placementId) } : s));
  };

  // Toggle sold out
  const toggleSoldOut = async (placementId: string, sectionId: string, current: boolean) => {
    await apiToggle(placementId, !current);
    setSections(prev => prev.map(s => s.id === sectionId ? { ...s, placements: s.placements.map(p => p.id === placementId ? { ...p, isVisible: !current } : p) } : s));
  };

  const total = sections.reduce((s, sec) => s + sec.placements.length, 0);

  return (
    <div className="flex flex-1 h-full -m-6">
      {/* LEFT: Card Editor */}
      <div className="flex-[3] overflow-y-auto p-6 min-w-0">
        <div className="max-w-3xl space-y-4">
          <div className="flex items-start justify-between">
            <div>
              <h1 className="text-2xl font-bold" style={{fontFamily: "'Playfair Display', serif"}}>{menu.name}</h1>
              <p className="text-sm text-gray-400 mt-1">{menu.locationName} · {menu.type} · {sections.length} Sektionen · {total} Produkte</p>
            </div>
            <div className="flex gap-2">
              <a href={menu.publicUrl} target="_blank" className="rounded-lg border px-3 py-1.5 text-xs font-medium hover:bg-gray-50">Vorschau ↗</a>
              <span className={`rounded-full px-3 py-1.5 text-xs font-medium ${menu.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>{menu.isActive ? 'Aktiv' : 'Inaktiv'}</span>
            </div>
          </div>

          {menu.qrCodes.length > 0 && (
            <div className="flex gap-2 flex-wrap">{menu.qrCodes.map(qr => (
              <span key={qr.id} className="rounded-lg bg-gray-100 px-3 py-1 text-xs text-gray-600">📱 {qr.label || qr.shortCode}</span>
            ))}</div>
          )}

          {/* Sections */}
          {sections.map(sec => (
            <div key={sec.id} className={`rounded-xl border bg-white shadow-sm overflow-hidden transition-all ${dragId && !dragFrom ? 'ring-2 ring-blue-200' : ''}`}>
              <div className="border-b bg-gray-50/50 px-4 py-3 flex items-center justify-between">
                <div>
                  <h2 className="text-sm font-semibold">{sec.icon && <span className="mr-1">{sec.icon}</span>}{sec.name}</h2>
                  <p className="text-[10px] text-gray-400">{sec.placements.length} Produkte</p>
                </div>
              </div>

              {/* Drop zone before first item */}
              <div
                onDragOver={e => onDragOverSlot(e, sec.id, 0)}
                onDrop={e => onDropSlot(e, sec.id, 0)}
                className={`h-0 transition-all duration-200 ${insertAt?.sid === sec.id && insertAt?.idx === 0 ? 'h-12 bg-blue-50 border-2 border-dashed border-blue-300 flex items-center justify-center' : ''}`}
              >
                {insertAt?.sid === sec.id && insertAt?.idx === 0 && <span className="text-xs text-blue-400">Hier einfügen</span>}
              </div>

              {sec.placements.map((pl, i) => (
                <div key={pl.id}>
                  <div
                    draggable
                    onDragStart={() => onDragStart(pl.productId, sec.id)}
                    onDragEnd={onDragEnd}
                    className={`flex items-center justify-between px-4 py-2.5 border-b last:border-0 cursor-grab active:cursor-grabbing transition-all duration-150 ${!pl.isVisible ? 'opacity-40' : 'hover:bg-gray-50/50'}`}
                  >
                    <div className="flex items-center gap-3 flex-1 min-w-0">
                      <span className="text-gray-300 cursor-grab">⠿</span>
                      <span className={`flex-shrink-0 rounded px-1 py-0.5 text-[9px] font-bold ${TB[pl.type]?.c || TB.OTHER.c}`}>{TB[pl.type]?.l || '?'}</span>
                      <div className="min-w-0 relative">
                        <Link href={`/admin/items/${pl.productId}`} className="text-sm font-medium text-gray-800 hover:text-amber-700 truncate block">{pl.name}</Link>
                        {pl.winery && <p className="text-[11px] text-gray-400">{pl.winery}{pl.vintage ? ` ${pl.vintage}` : ''}</p>}
                        {!pl.isVisible && <div className="absolute inset-0 flex items-center"><span className="bg-red-100 text-red-600 text-[10px] font-bold px-2 py-0.5 rounded rotate-[-2deg]">AUSGETRUNKEN</span></div>}
                      </div>
                    </div>
                    <div className="flex items-center gap-2 flex-shrink-0">
                      {pl.price !== null && <span className="text-sm font-semibold text-gray-600 tabular-nums">{fmtEur(pl.price)}</span>}
                      <button onClick={() => toggleSoldOut(pl.id, sec.id, pl.isVisible)} title={pl.isVisible ? 'Als ausgetrunken markieren' : 'Wieder verfügbar'} className={`rounded p-1 text-[10px] transition-colors ${pl.isVisible ? 'text-gray-400 hover:text-orange-600 hover:bg-orange-50' : 'text-orange-600 bg-orange-50'}`}>
                        {pl.isVisible ? '🍷' : '↩️'}
                      </button>
                      <button onClick={() => remove(pl.id, sec.id)} title="Aus Karte entfernen" className="rounded p-1 text-gray-300 hover:text-red-500 hover:bg-red-50 transition-colors">✕</button>
                    </div>
                  </div>

                  {/* Drop zone after each item */}
                  <div
                    onDragOver={e => onDragOverSlot(e, sec.id, i + 1)}
                    onDrop={e => onDropSlot(e, sec.id, i + 1)}
                    className={`transition-all duration-200 ${insertAt?.sid === sec.id && insertAt?.idx === i + 1 ? 'h-12 bg-blue-50 border-2 border-dashed border-blue-300 flex items-center justify-center' : 'h-0'}`}
                  >
                    {insertAt?.sid === sec.id && insertAt?.idx === i + 1 && <span className="text-xs text-blue-400">Hier einfügen</span>}
                  </div>
                </div>
              ))}

              {sec.placements.length === 0 && (
                <div
                  onDragOver={e => onDragOverSlot(e, sec.id, 0)}
                  onDrop={e => onDropSlot(e, sec.id, 0)}
                  className={`px-4 py-6 text-center text-xs transition-colors ${dragId ? 'bg-blue-50 text-blue-400 border-2 border-dashed border-blue-300 m-2 rounded-lg' : 'text-gray-400'}`}
                >
                  {dragId ? 'Hier ablegen' : 'Keine Produkte – aus dem Browser rechts zuordnen'}
                </div>
              )}
            </div>
          ))}

          <div className="text-xs text-gray-300">ID: {menu.id} · Slug: {menu.slug}</div>
        </div>
      </div>

      {/* RIGHT: Product Browser */}
      <div
        onDragOver={e => { e.preventDefault(); if (dragFrom) setBrowserDrop(true); }}
        onDragLeave={() => setBrowserDrop(false)}
        onDrop={onDropBrowser}
        className={`flex-[1.2] min-w-[280px] max-w-[400px] flex flex-col border-l bg-white transition-colors ${browserDrop ? 'bg-red-50 border-l-red-300' : ''}`}
      >
        <div className="border-b px-3 py-3">
          <div className="flex items-center justify-between mb-2">
            <h2 className="text-sm font-semibold text-gray-700">{browserDrop ? '🗑️ Entfernen' : 'Produktpool'}</h2>
            <span className="text-[10px] text-gray-400">{available.length} verfügbar</span>
          </div>
          <div className="relative">
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="absolute left-2.5 top-1/2 -translate-y-1/2 opacity-30"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
            <input type="text" value={query} onChange={e => setQuery(e.target.value)} placeholder="Suchen..." className="w-full rounded-lg border bg-gray-50 py-1.5 pl-8 pr-2 text-xs outline-none focus:border-gray-400 focus:bg-white" />
          </div>
          <div className="mt-2 flex gap-1.5">
            <select value={typeFilter} onChange={e => setTypeFilter(e.target.value)} className="flex-1 rounded border bg-gray-50 px-1.5 py-1 text-[10px] outline-none">
              <option value="">Alle Typen</option>
              <option value="WINE">Wein</option>
              <option value="DRINK">Getränk</option>
              <option value="FOOD">Speise</option>
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
                onDragStart={() => onDragStart(p.id, null)}
                onDragEnd={onDragEnd}
                className="flex items-center gap-2 border-b px-3 py-2.5 cursor-grab active:cursor-grabbing hover:bg-gray-50 transition-colors"
              >
                <span className="text-gray-300 text-xs">⠿</span>
                <span className={`flex-shrink-0 rounded px-1 py-0.5 text-[9px] font-bold ${b.c}`}>{b.l}</span>
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-medium text-gray-800 truncate">{p.name}</p>
                  <p className="text-[10px] text-gray-400 truncate">{p.groupName}</p>
                </div>
                {p.price !== null && <span className="text-[10px] font-semibold text-gray-500 tabular-nums flex-shrink-0">{fmtEur(p.price)}</span>}
                {/* Click-add dropdown */}
                <div className="relative group">
                  <button className="text-gray-300 hover:text-green-600 text-sm">+</button>
                  <div className="absolute right-0 top-5 z-30 hidden group-hover:block rounded-lg border bg-white shadow-lg py-1 w-44">
                    {sections.map(s => (
                      <button key={s.id} onClick={() => clickAdd(p.id, s.id)} className="block w-full px-3 py-1.5 text-left text-xs hover:bg-gray-50 truncate">
                        → {s.name}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            );
          })}
          {available.length === 0 && <div className="px-4 py-8 text-center text-xs text-gray-400">Alle Produkte zugeordnet</div>}
        </div>
      </div>
    </div>
  );
}
ENDOFCOMP

echo "3/4 Updating menu detail page..."

cat > "src/app/admin/menus/[id]/page.tsx" << 'ENDFILE'
import { notFound } from 'next/navigation';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import MenuEditor from '@/components/admin/menu-editor';

export default async function MenuDetailPage({ params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return null;
  const tid = session.user.tenantId;

  const menu = await prisma.menu.findUnique({
    where: { id: params.id },
    include: {
      translations: true,
      location: { include: { tenant: true } },
      sections: {
        where: { isActive: true }, orderBy: { sortOrder: 'asc' },
        include: {
          translations: { where: { languageCode: 'de' } },
          placements: {
            orderBy: { sortOrder: 'asc' },
            include: { product: { include: {
              translations: { where: { languageCode: 'de' } },
              prices: { take: 1, orderBy: { sortOrder: 'asc' } },
              productWineProfile: { select: { winery: true, vintage: true } },
            } } },
          },
        },
      },
      qrCodes: true,
    },
  });
  if (!menu) return notFound();

  const allProducts = await prisma.product.findMany({
    where: { tenantId: tid, status: { not: 'ARCHIVED' } },
    include: {
      translations: { where: { languageCode: 'de' } },
      productGroup: { include: { translations: { where: { languageCode: 'de' } } } },
      prices: { take: 1, orderBy: { sortOrder: 'asc' } },
      productWineProfile: { select: { winery: true, vintage: true } },
    },
    orderBy: { sortOrder: 'asc' },
  });

  const tenant = menu.location.tenant;

  const menuData = {
    id: menu.id, name: menu.translations.find(t => t.languageCode === 'de')?.name || menu.slug,
    slug: menu.slug, type: menu.type, locationName: menu.location.name,
    isActive: menu.isActive, publicUrl: `/${tenant.slug}/${menu.location.slug}/${menu.slug}`,
    qrCodes: menu.qrCodes.map(q => ({ id: q.id, label: q.label, shortCode: q.shortCode })),
    sections: menu.sections.map(s => ({
      id: s.id, slug: s.slug, name: s.translations[0]?.name || s.slug, icon: s.icon,
      placements: s.placements.map(pl => ({
        id: pl.id, productId: pl.product.id,
        name: pl.product.translations[0]?.name || '',
        winery: pl.product.productWineProfile?.winery || null,
        vintage: pl.product.productWineProfile?.vintage || null,
        price: pl.priceOverride ? Number(pl.priceOverride) : pl.product.prices[0] ? Number(pl.product.prices[0].price) : null,
        type: pl.product.type, sortOrder: pl.sortOrder, isVisible: pl.isVisible,
      })),
    })),
  };

  const browserProducts = allProducts.map(p => ({
    id: p.id, name: p.translations[0]?.name || '',
    type: p.type, groupName: p.productGroup?.translations[0]?.name || '',
    price: p.prices[0] ? Number(p.prices[0].price) : null,
    winery: p.productWineProfile?.winery || null,
    vintage: p.productWineProfile?.vintage || null,
  }));

  return <MenuEditor menu={menuData} allProducts={browserProducts} />;
}
ENDFILE

echo "4/4 Building..."
npm run build && pm2 restart menucard-pro

echo ""
echo "=== Interactive Menu Editor deployed! ==="
echo "Test: /admin/menus → Karte anklicken"
