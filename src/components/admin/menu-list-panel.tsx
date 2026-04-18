'use client';

import { useState, useMemo } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import Link from 'next/link';

type MenuItem = {
  id: string; slug: string; type: string;
  name: string; locationName: string;
  sectionCount: number; itemCount: number;
  isActive: boolean;
};

const typeIcons: Record<string, string> = {
  FOOD: 'restaurant', DRINKS: 'local_bar', WINE: 'wine_bar', BAR: 'local_bar', EVENT: 'celebration',
  BREAKFAST: 'coffee', SPA: 'spa', ROOM_SERVICE: 'room_service', MINIBAR: 'kitchen',
  DAILY_SPECIAL: 'star', SEASONAL: 'eco',
};

const MENU_TYPES: { value: string; label: string }[] = [
  { value: 'FOOD', label: 'Speisekarte' },
  { value: 'WINE', label: 'Weinkarte' },
  { value: 'BAR', label: 'Barkarte' },
  { value: 'DRINKS', label: 'Getraenkekarte' },
  { value: 'BREAKFAST', label: 'Fruehstueckskarte' },
  { value: 'EVENT', label: 'Eventkarte' },
  { value: 'ROOM_SERVICE', label: 'Roomservice' },
  { value: 'SPA', label: 'Spa-Karte' },
  { value: 'MINIBAR', label: 'Minibar' },
  { value: 'DAILY_SPECIAL', label: 'Tageskarte' },
  { value: 'SEASONAL', label: 'Saisonkarte' },
];

export default function MenuListPanel({ menus }: { menus: MenuItem[] }) {
  const pathname = usePathname();
  const router = useRouter();
  const [width, setWidth] = useState(420);
  const [dragging, setDragging] = useState(false);
  const activeId = pathname.split('/admin/menus/')[1] || '';
  const [query, setQuery] = useState('');

  const [showCreate, setShowCreate] = useState(false);
  const [createForm, setCreateForm] = useState({ name: '', nameEn: '', type: 'FOOD' });
  const [creating, setCreating] = useState(false);
  const [createError, setCreateError] = useState<string | null>(null);

  const filtered = useMemo(() => {
    const q = query.toLowerCase().trim();
    if (!q) return menus;
    return menus.filter(m => m.name.toLowerCase().includes(q) || m.type.toLowerCase().includes(q) || m.locationName.toLowerCase().includes(q));
  }, [menus, query]);

  const startResize = (e: React.MouseEvent) => {
    e.preventDefault();
    setDragging(true);
    const startX = e.clientX;
    const startW = width;
    const onMove = (ev: MouseEvent) => setWidth(Math.max(260, Math.min(500, startW + ev.clientX - startX)));
    const onUp = () => { setDragging(false); document.removeEventListener('mousemove', onMove); document.removeEventListener('mouseup', onUp); };
    document.addEventListener('mousemove', onMove);
    document.addEventListener('mouseup', onUp);
  };

  const handleCreate = async () => {
    setCreating(true);
    setCreateError(null);
    try {
      const res = await fetch('/api/v1/menus', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(createForm),
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({ error: 'Fehler' }));
        throw new Error(err.error || 'Fehler beim Anlegen');
      }
      const menu = await res.json();
      setShowCreate(false);
      setCreateForm({ name: '', nameEn: '', type: 'FOOD' });
      router.refresh();
      router.push(`/admin/menus/${menu.id}`);
    } catch (e: any) {
      setCreateError(e.message);
    } finally {
      setCreating(false);
    }
  };

  return (
    <div className="relative flex h-full flex-shrink-0 flex-col border-r bg-white" style={{ width }}>
      <div className="border-b px-3 py-3">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-base font-semibold text-gray-700">Karten</h2>
            <p className="text-sm text-gray-400 mt-0.5">{menus.length} Karten</p>
          </div>
          <button
            onClick={() => { setShowCreate(true); setCreateError(null); }}
            className="inline-flex items-center gap-1 rounded-lg px-3 py-1.5 text-xs font-medium text-white transition-colors"
            style={{ backgroundColor: '#22C55E' }}
            title="Neue Karte anlegen"
          >
            <span className="material-symbols-outlined" style={{ fontSize: 16 }}>add</span>
            Neu
          </button>
        </div>
        <div className="relative mt-2">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="absolute left-2.5 top-1/2 -translate-y-1/2 opacity-30"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
          <input type="text" value={query} onChange={e => setQuery(e.target.value)} placeholder="Suchen..." className="w-full rounded-lg border bg-gray-50 py-1.5 pl-8 pr-2 text-sm outline-none focus:border-gray-400 focus:bg-white" />
        </div>
      </div>

      <div className="flex-1 overflow-y-auto">
        {filtered.map(m => {
          const active = activeId === m.id;
          const icon = typeIcons[m.type] || 'description';
          return (
            <Link
              key={m.id}
              href={`/admin/menus/${m.id}`}
              className={`block border-b px-3 py-3 transition-colors border-l-2 ${active ? 'border-l-[var(--color-primary)]' : 'hover:bg-gray-50 border-l-transparent'}`}
              style={active ? { backgroundColor: 'rgba(221,60,113,0.08)' } : {}}
            >
              <div className="flex items-start justify-between gap-2">
                <div className="flex items-center gap-2">
                  <span
                    className="material-symbols-outlined select-none"
                    style={{
                      fontSize: 22,
                      color: active ? 'var(--color-primary)' : 'var(--color-text-muted, #6B7280)',
                      fontVariationSettings: "'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 22",
                      lineHeight: 1,
                    }}
                  >
                    {icon}
                  </span>
                  <div>
                    <p className={`text-base leading-snug ${active ? 'font-semibold text-gray-900' : 'text-gray-800'}`}>{m.name}</p>
                    <p className="text-sm text-gray-400 mt-0.5">{m.locationName} &middot; {m.type}</p>
                  </div>
                </div>
                <span className={`flex-shrink-0 h-2 w-2 mt-2 rounded-full ${m.isActive ? 'bg-green-400' : 'bg-gray-300'}`} />
              </div>
              <div className="mt-1.5 pl-8 text-sm text-gray-400">
                {m.sectionCount} Sektionen &middot; {m.itemCount} Produkte
              </div>
            </Link>
          );
        })}
      </div>

      {showCreate && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
          onClick={() => setShowCreate(false)}
          style={{ fontFamily: "'Roboto', sans-serif" }}
        >
          <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl" onClick={e => e.stopPropagation()}>
            <h2 className="mb-4 text-lg font-bold">Neue Karte anlegen</h2>
            <div className="space-y-3">
              <div>
                <label className="mb-1 block text-xs font-medium text-gray-600">Name (Deutsch)</label>
                <input
                  type="text"
                  value={createForm.name}
                  onChange={e => setCreateForm({ ...createForm, name: e.target.value })}
                  placeholder="z.B. Sommer-Abendkarte"
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-pink-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-gray-600">Name (Englisch, optional)</label>
                <input
                  type="text"
                  value={createForm.nameEn}
                  onChange={e => setCreateForm({ ...createForm, nameEn: e.target.value })}
                  placeholder="e.g. Summer Dinner Menu"
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-pink-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-gray-600">Kartentyp</label>
                <select
                  value={createForm.type}
                  onChange={e => setCreateForm({ ...createForm, type: e.target.value })}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-pink-500 focus:outline-none"
                >
                  {MENU_TYPES.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
                </select>
              </div>
            </div>

            {createError && (
              <div className="mt-3 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700">
                {createError}
              </div>
            )}

            <div className="mt-6 flex justify-end gap-2">
              <button
                onClick={() => setShowCreate(false)}
                className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Abbrechen
              </button>
              <button
                onClick={handleCreate}
                disabled={creating || !createForm.name.trim()}
                className="rounded-lg px-4 py-2 text-sm font-medium text-white disabled:opacity-50"
                style={{ backgroundColor: '#22C55E' }}
              >
                {creating ? 'Lege an…' : 'Anlegen'}
              </button>
            </div>
          </div>
        </div>
      )}

      <div
        onMouseDown={startResize}
        className="absolute right-0 top-0 h-full w-1.5 cursor-col-resize transition-colors"
        style={{
          zIndex: 10,
          backgroundColor: dragging ? 'rgba(221,60,113,0.4)' : 'transparent'
        }}
        onMouseEnter={e => { if (!dragging) e.currentTarget.style.backgroundColor = 'rgba(221,60,113,0.2)'; }}
        onMouseLeave={e => { if (!dragging) e.currentTarget.style.backgroundColor = 'transparent'; }}
      />
    </div>
  );
}
