'use client';

import { useState } from 'react';
import { usePathname } from 'next/navigation';
import Link from 'next/link';

const navItems = [
  { href: '/admin', icon: '📊', label: 'Dashboard', match: /^\/admin$/ },
  { href: '/admin/items', icon: '📦', label: 'Produkte', match: /^\/admin\/items/ },
  { href: '/admin/menus', icon: '📋', label: 'Karten', match: /^\/admin\/menus/ },
  { href: '/admin/qr-codes', icon: '📱', label: 'QR-Codes', match: /^\/admin\/qr-codes/ },
  { href: '/admin/analytics', icon: '📈', label: 'Analytics', match: /^\/admin\/analytics/ },
  { href: '/admin/settings', icon: '⚙️', label: 'Einstellungen', match: /^\/admin\/settings/ },
];

export default function IconBar({ userName, userRole }: { userName: string; userRole: string }) {
  const pathname = usePathname();
  const [expanded, setExpanded] = useState(true);

  return (
    <div className={`flex h-full flex-col border-r bg-white py-3 transition-all duration-200 ${expanded ? 'w-48' : 'w-14'}`}>
      {/* Logo + Toggle */}
      <div className={`mb-4 flex items-center ${expanded ? 'px-3 gap-2' : 'justify-center'}`}>
        <button onClick={() => setExpanded(!expanded)} className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-lg text-sm font-bold text-white" style={{ backgroundColor: '#8B6914' }}>
          M
        </button>
        {expanded && <span className="text-base font-semibold truncate" style={{fontFamily: "'Playfair Display', serif"}}>MenuCard Pro</span>}
      </div>
      <button onClick={() => setExpanded(!expanded)} className="mx-auto mb-3 flex h-6 w-6 items-center justify-center rounded-md hover:bg-gray-100 text-gray-400 transition-colors">
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">{expanded ? <path d="m11 17-5-5 5-5M18 17l-5-5 5-5"/> : <path d="m13 17 5-5-5-5M6 17l5-5-5-5"/>}</svg>
      </button>

      {/* Nav */}
      <nav className="flex flex-1 flex-col gap-0.5 px-2">
        {navItems.map(item => {
          const active = item.match.test(pathname);
          return (
            <Link
              key={item.href}
              href={item.href}
              title={expanded ? undefined : item.label}
              className={`flex items-center gap-2.5 rounded-lg px-2 py-2 text-base transition-colors ${active ? 'bg-amber-50 font-medium' : 'hover:bg-gray-100 text-gray-600'}`}
              style={active ? { boxShadow: 'inset 3px 0 0 #8B6914' } : {}}
            >
              <span className="text-xl flex-shrink-0 w-6 text-center">{item.icon}</span>
              {expanded && <span className="truncate">{item.label}</span>}
            </Link>
          );
        })}
      </nav>

      {/* User */}
      <div className={`mt-auto border-t pt-3 ${expanded ? 'px-3' : 'flex flex-col items-center gap-2'}`}>
        {expanded ? (
          <div>
            <p className="text-sm font-medium text-gray-700 truncate">{userName}</p>
            <p className="text-sm text-gray-400">{userRole}</p>
            <button onClick={() => { window.location.reload(); }} title="Seite neu laden" className="w-full rounded-lg border px-3 py-1.5 text-sm text-gray-500 hover:bg-blue-50 hover:text-blue-600 transition-colors mb-1">🔄 Neu laden</button>
            <button onClick={() => { if(confirm('Abmelden?')) window.location.href='/api/auth/signout'; }} className="mt-2 w-full rounded-lg border px-3 py-1.5 text-sm text-gray-500 hover:bg-red-50 hover:text-red-600 transition-colors">Abmelden</button>
          </div>
        ) : (
          <>
            <div title={`${userName} (${userRole})`} className="flex h-8 w-8 items-center justify-center rounded-full bg-gray-200 text-sm font-semibold text-gray-600">
              {userName.charAt(0).toUpperCase()}
            </div>
            <button onClick={() => { window.location.reload(); }} title="Seite neu laden" className="w-full rounded-lg border px-3 py-1.5 text-sm text-gray-500 hover:bg-blue-50 hover:text-blue-600 transition-colors mb-1">🔄 Neu laden</button>
            <button onClick={() => { if(confirm('Abmelden?')) window.location.href='/api/auth/signout'; }} title="Abmelden" className="flex h-8 w-8 items-center justify-center rounded-full hover:bg-red-50 text-gray-400 hover:text-red-500 transition-colors">⏻</button>
          </>
        )}
      </div>
    </div>
  );
}
