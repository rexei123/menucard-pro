#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Deploying New Admin Layout ==="

echo "1/5 Backing up..."
cp src/app/admin/layout.tsx /tmp/admin-layout.bak
cp src/app/admin/items/page.tsx /tmp/admin-items.bak

echo "2/5 Creating Icon Bar..."

mkdir -p src/components/admin

cat > src/components/admin/icon-bar.tsx << 'ENDFILE'
'use client';

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

  return (
    <div className="flex h-full w-14 flex-col items-center border-r bg-white py-3">
      {/* Logo */}
      <Link href="/admin" className="mb-6 flex h-9 w-9 items-center justify-center rounded-lg text-xs font-bold text-white" style={{ backgroundColor: '#8B6914' }}>
        M
      </Link>

      {/* Nav */}
      <nav className="flex flex-1 flex-col items-center gap-1">
        {navItems.map(item => {
          const active = item.match.test(pathname);
          return (
            <Link
              key={item.href}
              href={item.href}
              title={item.label}
              className={`flex h-10 w-10 items-center justify-center rounded-lg text-lg transition-colors ${active ? 'bg-amber-50' : 'hover:bg-gray-100'}`}
              style={active ? { boxShadow: 'inset 2px 0 0 #8B6914' } : {}}
            >
              {item.icon}
            </Link>
          );
        })}
      </nav>

      {/* User */}
      <div className="mt-auto flex flex-col items-center gap-2">
        <div title={`${userName} (${userRole})`} className="flex h-8 w-8 items-center justify-center rounded-full bg-gray-200 text-xs font-semibold text-gray-600">
          {userName.charAt(0).toUpperCase()}
        </div>
      </div>
    </div>
  );
}
ENDFILE

echo "3/5 Creating new Admin Layout..."

cat > src/app/admin/layout.tsx << 'ENDFILE'
import { redirect } from 'next/navigation';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { Providers } from '@/components/shared/providers';
import IconBar from '@/components/admin/icon-bar';

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const session = await getServerSession(authOptions);
  if (!session) redirect('/auth/login');

  return (
    <Providers>
      <div className="flex h-screen overflow-hidden bg-[#FAFAF8]">
        <IconBar
          userName={session.user.firstName || 'Admin'}
          userRole={session.user.role || 'OWNER'}
        />
        <div className="flex flex-1 overflow-hidden">
          {children}
        </div>
      </div>
    </Providers>
  );
}
ENDFILE

echo "4/5 Creating Product List Panel + Items Layout..."

cat > src/components/admin/product-list-panel.tsx << 'ENDFILE'
'use client';

import { useState, useMemo } from 'react';
import { usePathname } from 'next/navigation';
import Link from 'next/link';

type ProductItem = {
  id: string; sku: string | null; type: string; status: string;
  name: string; groupName: string; groupSlug: string;
  mainPrice: number | null; priceCount: number;
  winery: string | null; vintage: number | null;
};

type GroupOption = { slug: string; name: string; parentName: string | null };

const typeBadge: Record<string, { letter: string; cls: string }> = {
  WINE: { letter: 'W', cls: 'bg-purple-100 text-purple-700' },
  DRINK: { letter: 'G', cls: 'bg-blue-100 text-blue-700' },
  FOOD: { letter: 'S', cls: 'bg-orange-100 text-orange-700' },
  OTHER: { letter: '?', cls: 'bg-gray-100 text-gray-600' },
};

const statusDot: Record<string, string> = {
  ACTIVE: 'bg-green-400',
  SOLD_OUT: 'bg-red-400',
  ARCHIVED: 'bg-gray-300',
  DRAFT: 'bg-yellow-400',
};

function formatEur(price: number): string {
  return new Intl.NumberFormat('de-AT', { style: 'currency', currency: 'EUR' }).format(price);
}

export default function ProductListPanel({ products, groups }: { products: ProductItem[]; groups: GroupOption[] }) {
  const pathname = usePathname();
  const [query, setQuery] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [groupFilter, setGroupFilter] = useState('');

  const activeId = pathname.split('/admin/items/')[1] || '';

  const filteredGroups = useMemo(() => {
    if (!typeFilter) return groups;
    const typeProducts = products.filter(p => p.type === typeFilter);
    const activeSlugs = new Set(typeProducts.map(p => p.groupSlug));
    return groups.filter(g => activeSlugs.has(g.slug));
  }, [groups, products, typeFilter]);

  const filtered = useMemo(() => {
    const q = query.toLowerCase().trim();
    return products.filter(p => {
      if (q) {
        const s = `${p.name} ${p.sku || ''} ${p.winery || ''} ${p.groupName}`.toLowerCase();
        if (!s.includes(q)) return false;
      }
      if (typeFilter && p.type !== typeFilter) return false;
      if (groupFilter && p.groupSlug !== groupFilter) return false;
      return true;
    });
  }, [products, query, typeFilter, groupFilter]);

  return (
    <div className="flex h-full w-[300px] flex-shrink-0 flex-col border-r bg-white">
      {/* Header */}
      <div className="border-b px-3 py-3">
        <div className="flex items-center justify-between mb-2">
          <h2 className="text-sm font-semibold text-gray-700">Produkte</h2>
          <span className="text-[10px] text-gray-400">{filtered.length}/{products.length}</span>
        </div>
        {/* Search */}
        <div className="relative">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="absolute left-2.5 top-1/2 -translate-y-1/2 opacity-30"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
          <input
            type="text" value={query} onChange={e => setQuery(e.target.value)}
            placeholder="Suchen..."
            className="w-full rounded-lg border bg-gray-50 py-1.5 pl-8 pr-2 text-xs outline-none focus:border-gray-400 focus:bg-white"
          />
        </div>
        {/* Filters */}
        <div className="mt-2 flex gap-1.5">
          <select value={typeFilter} onChange={e => { setTypeFilter(e.target.value); setGroupFilter(''); }} className="flex-1 rounded border bg-gray-50 px-1.5 py-1 text-[10px] outline-none">
            <option value="">Alle Typen</option>
            <option value="WINE">Wein</option>
            <option value="DRINK">Getränk</option>
            <option value="FOOD">Speise</option>
          </select>
          <select value={groupFilter} onChange={e => setGroupFilter(e.target.value)} className="flex-1 rounded border bg-gray-50 px-1.5 py-1 text-[10px] outline-none">
            <option value="">Alle Gruppen</option>
            {filteredGroups.map(g => (
              <option key={g.slug} value={g.slug}>{g.parentName ? `${g.parentName} → ${g.name}` : g.name}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Product List */}
      <div className="flex-1 overflow-y-auto">
        {filtered.map(p => {
          const active = activeId === p.id;
          const badge = typeBadge[p.type] || typeBadge.OTHER;
          return (
            <Link
              key={p.id}
              href={`/admin/items/${p.id}`}
              className={`flex items-center gap-2.5 border-b px-3 py-2.5 transition-colors ${active ? 'bg-amber-50 border-l-2 border-l-amber-600' : 'hover:bg-gray-50 border-l-2 border-l-transparent'}`}
            >
              <span className={`flex-shrink-0 rounded px-1 py-0.5 text-[9px] font-bold ${badge.cls}`}>{badge.letter}</span>
              <div className="flex-1 min-w-0">
                <p className={`text-xs truncate ${active ? 'font-semibold text-gray-900' : 'text-gray-700'}`}>{p.name}</p>
                <div className="flex items-center gap-1.5 mt-0.5">
                  <span className={`h-1.5 w-1.5 rounded-full ${statusDot[p.status] || 'bg-gray-300'}`} />
                  <span className="text-[10px] text-gray-400 truncate">{p.groupName}</span>
                </div>
              </div>
              {p.mainPrice !== null && (
                <span className="flex-shrink-0 text-[10px] font-semibold text-gray-500 tabular-nums">{formatEur(p.mainPrice)}</span>
              )}
            </Link>
          );
        })}
        {filtered.length === 0 && (
          <div className="px-4 py-8 text-center text-xs text-gray-400">Keine Produkte</div>
        )}
      </div>
    </div>
  );
}
ENDFILE

# Items layout (List-Panel + Workspace)
cat > src/app/admin/items/layout.tsx << 'ENDFILE'
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import ProductListPanel from '@/components/admin/product-list-panel';

export default async function ItemsLayout({ children }: { children: React.ReactNode }) {
  const session = await getServerSession(authOptions);
  if (!session) return null;
  const tid = session.user.tenantId;

  const [products, groups] = await Promise.all([
    prisma.product.findMany({
      where: { tenantId: tid },
      include: {
        translations: { where: { languageCode: 'de' }, select: { name: true } },
        productGroup: { include: { translations: { where: { languageCode: 'de' }, select: { name: true } } } },
        prices: { take: 1, orderBy: { sortOrder: 'asc' }, select: { price: true } },
        productWineProfile: { select: { winery: true, vintage: true } },
      },
      orderBy: [{ sortOrder: 'asc' }],
    }),
    prisma.productGroup.findMany({
      where: { tenantId: tid },
      include: { translations: { where: { languageCode: 'de' }, select: { name: true } }, parent: { include: { translations: { where: { languageCode: 'de' }, select: { name: true } } } } },
      orderBy: { sortOrder: 'asc' },
    }),
  ]);

  const serialized = products.map(p => ({
    id: p.id,
    sku: p.sku,
    type: p.type,
    status: p.status,
    name: p.translations[0]?.name || '',
    groupName: p.productGroup?.translations[0]?.name || '',
    groupSlug: p.productGroup?.slug || '',
    mainPrice: p.prices[0] ? Number(p.prices[0].price) : null,
    priceCount: p.prices.length,
    winery: p.productWineProfile?.winery || null,
    vintage: p.productWineProfile?.vintage || null,
  }));

  const groupOpts = groups
    .filter(g => products.some(p => p.productGroupId === g.id))
    .map(g => ({
      slug: g.slug,
      name: g.translations[0]?.name || g.slug,
      parentName: g.parent?.translations[0]?.name || null,
    }));

  return (
    <div className="flex flex-1 overflow-hidden">
      <ProductListPanel products={serialized} groups={groupOpts} />
      <main className="flex-1 overflow-y-auto p-6">
        {children}
      </main>
    </div>
  );
}
ENDFILE

# Items index page (no product selected)
cat > src/app/admin/items/page.tsx << 'ENDFILE'
export default function ItemsIndexPage() {
  return (
    <div className="flex h-full items-center justify-center">
      <div className="text-center">
        <p className="text-5xl mb-4">📦</p>
        <h2 className="text-lg font-semibold text-gray-400">Produkt auswählen</h2>
        <p className="text-sm text-gray-300 mt-1">Wähle ein Produkt aus der Liste links</p>
      </div>
    </div>
  );
}
ENDFILE

echo "5/5 Updating remaining pages for new layout..."

# Dashboard page (needs wrapper since no list panel)
cat > src/app/admin/page.tsx << 'ENDFILE'
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import Link from 'next/link';

export default async function DashboardPage() {
  const session = await getServerSession(authOptions);
  if (!session) return null;
  const tid = session.user.tenantId;

  const [menuCount, productCount, qrCount] = await Promise.all([
    prisma.menu.count({ where: { location: { tenantId: tid } } }),
    prisma.product.count({ where: { tenantId: tid } }),
    prisma.qRCode.count({ where: { location: { tenantId: tid } } }),
  ]);

  return (
    <main className="flex-1 overflow-y-auto p-6">
      <div className="max-w-4xl">
        <h1 className="text-2xl font-bold" style={{fontFamily: "'Playfair Display', serif"}}>Dashboard</h1>
        <p className="text-sm text-gray-400 mt-1">Willkommen, {session.user.firstName}</p>

        <div className="mt-6 grid gap-4 sm:grid-cols-3">
          <Link href="/admin/menus" className="rounded-xl border bg-white p-5 shadow-sm hover:shadow-md transition-shadow">
            <p className="text-3xl font-bold">{menuCount}</p>
            <p className="text-sm text-gray-400 mt-1">Karten</p>
          </Link>
          <Link href="/admin/items" className="rounded-xl border bg-white p-5 shadow-sm hover:shadow-md transition-shadow">
            <p className="text-3xl font-bold">{productCount}</p>
            <p className="text-sm text-gray-400 mt-1">Produkte</p>
          </Link>
          <Link href="/admin/qr-codes" className="rounded-xl border bg-white p-5 shadow-sm hover:shadow-md transition-shadow">
            <p className="text-3xl font-bold">{qrCount}</p>
            <p className="text-sm text-gray-400 mt-1">QR-Codes</p>
          </Link>
        </div>
      </div>
    </main>
  );
}
ENDFILE

# QR-Codes page wrapper
cat > src/app/admin/qr-codes/layout.tsx << 'ENDFILE'
export default function QRLayout({ children }: { children: React.ReactNode }) {
  return <main className="flex-1 overflow-y-auto p-6">{children}</main>;
}
ENDFILE

# Menus page wrapper
cat > src/app/admin/menus/layout.tsx << 'ENDFILE'
export default function MenusLayout({ children }: { children: React.ReactNode }) {
  return <main className="flex-1 overflow-y-auto p-6">{children}</main>;
}
ENDFILE

# Analytics wrapper
cat > src/app/admin/analytics/layout.tsx << 'ENDFILE'
export default function AnalyticsLayout({ children }: { children: React.ReactNode }) {
  return <main className="flex-1 overflow-y-auto p-6">{children}</main>;
}
ENDFILE

# Settings wrapper
cat > src/app/admin/settings/layout.tsx << 'ENDFILE'
export default function SettingsLayout({ children }: { children: React.ReactNode }) {
  return <main className="flex-1 overflow-y-auto p-6">{children}</main>;
}
ENDFILE

# Import wrapper
cat > src/app/admin/import/layout.tsx << 'ENDFILE'
export default function ImportLayout({ children }: { children: React.ReactNode }) {
  return <main className="flex-1 overflow-y-auto p-6">{children}</main>;
}
ENDFILE

# Media wrapper
cat > src/app/admin/media/layout.tsx << 'ENDFILE'
export default function MediaLayout({ children }: { children: React.ReactNode }) {
  return <main className="flex-1 overflow-y-auto p-6">{children}</main>;
}
ENDFILE

# Update product editor - remove "← Alle Produkte" link since list panel handles navigation
sed -i 's|<a href="#" onClick={(e) => { e.preventDefault(); if (!dirty || confirm("Ungespeicherte Änderungen verwerfen?")) window.location.href="/admin/items"; }} className="text-xs text-gray-400 hover:text-gray-600 mb-2 inline-block">← Alle Produkte</a>||' src/components/admin/product-editor.tsx 2>/dev/null || true

echo "Building..."
npm run build && pm2 restart menucard-pro

echo ""
echo "=== New Admin Layout deployed! ==="
echo "Test: http://178.104.138.177/admin"
