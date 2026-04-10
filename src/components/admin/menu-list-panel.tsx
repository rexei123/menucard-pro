'use client';

import { useState, useMemo } from 'react';
import { usePathname } from 'next/navigation';
import Link from 'next/link';

type MenuItem = {
  id: string; slug: string; type: string;
  name: string; locationName: string;
  sectionCount: number; itemCount: number;
  isActive: boolean;
};

const typeIcons: Record<string, string> = {
  FOOD: '🍽️', DRINKS: '🍸', WINE: '🍷', BAR: '🍸', EVENT: '🎉',
  BREAKFAST: '☕', SPA: '💆', ROOM_SERVICE: '🛎️', MINIBAR: '🧊',
  DAILY_SPECIAL: '⭐', SEASONAL: '🌿',
};

export default function MenuListPanel({ menus }: { menus: MenuItem[] }) {
  const pathname = usePathname();
  const [width, setWidth] = useState(420);
  const [dragging, setDragging] = useState(false);
  const activeId = pathname.split('/admin/menus/')[1] || '';
  const [query, setQuery] = useState('');

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

  return (
    <div className="relative flex h-full flex-shrink-0 flex-col border-r bg-white" style={{ width }}>
      <div className="border-b px-3 py-3">
        <h2 className="text-base font-semibold text-gray-700">Karten</h2>
        <p className="text-sm text-gray-400 mt-0.5">{menus.length} Karten</p>
        <div className="relative mt-2">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="absolute left-2.5 top-1/2 -translate-y-1/2 opacity-30"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
          <input type="text" value={query} onChange={e => setQuery(e.target.value)} placeholder="Suchen..." className="w-full rounded-lg border bg-gray-50 py-1.5 pl-8 pr-2 text-sm outline-none focus:border-gray-400 focus:bg-white" />
        </div>
      </div>

      <div className="flex-1 overflow-y-auto">
        {filtered.map(m => {
          const active = activeId === m.id;
          const icon = typeIcons[m.type] || '📄';
          return (
            <Link
              key={m.id}
              href={`/admin/menus/${m.id}`}
              className={`block border-b px-3 py-3 transition-colors ${active ? 'bg-amber-50 border-l-2 border-l-amber-600' : 'hover:bg-gray-50 border-l-2 border-l-transparent'}`}
            >
              <div className="flex items-start justify-between gap-2">
                <div className="flex items-center gap-2">
                  <span className="text-xl">{icon}</span>
                  <div>
                    <p className={`text-base leading-snug ${active ? 'font-semibold text-gray-900' : 'text-gray-800'}`}>{m.name}</p>
                    <p className="text-sm text-gray-400 mt-0.5">{m.locationName} · {m.type}</p>
                  </div>
                </div>
                <span className={`flex-shrink-0 h-2 w-2 mt-2 rounded-full ${m.isActive ? 'bg-green-400' : 'bg-gray-300'}`} />
              </div>
              <div className="mt-1.5 pl-8 text-sm text-gray-400">
                {m.sectionCount} Sektionen · {m.itemCount} Produkte
              </div>
            </Link>
          );
        })}
      </div>

      <div onMouseDown={startResize} className={`absolute right-0 top-0 h-full w-1.5 cursor-col-resize hover:bg-amber-200 transition-colors ${dragging ? 'bg-amber-300' : ''}`} style={{ zIndex: 10 }} />
    </div>
  );
}
