#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Deploying: New Product + Menu Management ==="

echo "1/4 Creating Product API (POST)..."

# Add POST handler to create new products
cat > "src/app/api/v1/products/route.ts" << 'ENDFILE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;

  const body = await req.json();
  const type = body.type || 'OTHER';

  // Auto-generate SKU
  const lastProduct = await prisma.product.findFirst({
    where: { tenantId: tid, sku: { startsWith: 'SB-' } },
    orderBy: { sku: 'desc' },
    select: { sku: true },
  });
  const lastNum = lastProduct?.sku ? parseInt(lastProduct.sku.replace('SB-', '')) : 0;
  const sku = 'SB-' + String(lastNum + 1).padStart(4, '0');

  const product = await prisma.product.create({
    data: {
      tenantId: tid,
      sku,
      type,
      status: 'DRAFT',
      translations: {
        create: [
          { languageCode: 'de', name: body.name || 'Neues Produkt' },
          { languageCode: 'en', name: body.nameEn || 'New Product' },
        ],
      },
    },
  });

  return NextResponse.json({ id: product.id, sku: product.sku }, { status: 201 });
}
ENDFILE

echo "2/4 Adding + button to product list panel..."

python3 << 'PYEOF'
content = open('src/components/admin/product-list-panel.tsx').read()

# Add router import
content = content.replace(
    "import { usePathname } from 'next/navigation';",
    "import { usePathname, useRouter } from 'next/navigation';"
)

# Add router and creating state
content = content.replace(
    "const pathname = usePathname();",
    "const pathname = usePathname();\n  const router = useRouter();\n  const [creating, setCreating] = useState(false);"
)

# Add create function after the activeId line
content = content.replace(
    "const activeId = pathname.split('/admin/items/')[1] || '';",
    """const activeId = pathname.split('/admin/items/')[1] || '';

  const createProduct = async (type: string) => {
    setCreating(true);
    try {
      const res = await fetch('/api/v1/products', {
        method: 'POST', credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type }),
      });
      if (res.ok) {
        const data = await res.json();
        router.push('/admin/items/' + data.id);
        router.refresh();
      }
    } finally { setCreating(false); }
  };"""
)

# Replace the header section to add + button
old_header = '''<div className="flex items-center justify-between mb-2">
          <h2 className="text-sm font-semibold text-gray-700">Produkte</h2>
          <span className="text-[10px] text-gray-400">{filtered.length}/{products.length}</span>
        </div>'''

new_header = '''<div className="flex items-center justify-between mb-2">
          <h2 className="text-sm font-semibold text-gray-700">Produkte</h2>
          <div className="flex items-center gap-2">
            <span className="text-[10px] text-gray-400">{filtered.length}/{products.length}</span>
            <div className="relative group">
              <button disabled={creating} className="flex h-6 w-6 items-center justify-center rounded-md text-white text-xs font-bold hover:opacity-80 disabled:opacity-50" style={{backgroundColor:'#8B6914'}}>+</button>
              <div className="absolute right-0 top-7 z-20 hidden group-hover:block rounded-lg border bg-white shadow-lg py-1 w-32">
                <button onClick={() => createProduct('WINE')} className="block w-full px-3 py-1.5 text-left text-xs hover:bg-gray-50">🍷 Wein</button>
                <button onClick={() => createProduct('DRINK')} className="block w-full px-3 py-1.5 text-left text-xs hover:bg-gray-50">🍸 Getränk</button>
                <button onClick={() => createProduct('FOOD')} className="block w-full px-3 py-1.5 text-left text-xs hover:bg-gray-50">🍽️ Speise</button>
              </div>
            </div>
          </div>
        </div>'''

content = content.replace(old_header, new_header)
open('src/components/admin/product-list-panel.tsx', 'w').write(content)
print('Product list panel updated')
PYEOF

echo "3/4 Creating Menu Management..."

# Menu list panel component
cat > src/components/admin/menu-list-panel.tsx << 'ENDFILE'
'use client';

import { useState } from 'react';
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
  const [width, setWidth] = useState(340);
  const [dragging, setDragging] = useState(false);
  const activeId = pathname.split('/admin/menus/')[1] || '';

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
        <h2 className="text-sm font-semibold text-gray-700">Karten</h2>
        <p className="text-[10px] text-gray-400 mt-0.5">{menus.length} Karten</p>
      </div>

      <div className="flex-1 overflow-y-auto">
        {menus.map(m => {
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
                  <span className="text-lg">{icon}</span>
                  <div>
                    <p className={`text-[15px] leading-snug ${active ? 'font-semibold text-gray-900' : 'text-gray-800'}`}>{m.name}</p>
                    <p className="text-[12px] text-gray-400 mt-0.5">{m.locationName} · {m.type}</p>
                  </div>
                </div>
                <span className={`flex-shrink-0 h-2 w-2 mt-2 rounded-full ${m.isActive ? 'bg-green-400' : 'bg-gray-300'}`} />
              </div>
              <div className="mt-1.5 pl-8 text-[12px] text-gray-400">
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
ENDFILE

# Menu items layout
cat > src/app/admin/menus/layout.tsx << 'ENDFILE'
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import MenuListPanel from '@/components/admin/menu-list-panel';

export default async function MenusLayout({ children }: { children: React.ReactNode }) {
  const session = await getServerSession(authOptions);
  if (!session) return null;
  const tid = session.user.tenantId;

  const menus = await prisma.menu.findMany({
    where: { location: { tenantId: tid } },
    include: {
      translations: { where: { languageCode: 'de' } },
      location: true,
      sections: {
        include: { _count: { select: { placements: true } } },
      },
    },
    orderBy: { sortOrder: 'asc' },
  });

  const serialized = menus.map(m => ({
    id: m.id,
    slug: m.slug,
    type: m.type,
    name: m.translations[0]?.name || m.slug,
    locationName: m.location.name,
    sectionCount: m.sections.length,
    itemCount: m.sections.reduce((sum, s) => sum + s._count.placements, 0),
    isActive: m.isActive,
  }));

  return (
    <div className="flex flex-1 overflow-hidden">
      <MenuListPanel menus={serialized} />
      <main className="flex-1 overflow-y-auto p-6">
        {children}
      </main>
    </div>
  );
}
ENDFILE

# Menu index page (no menu selected)
cat > src/app/admin/menus/page.tsx << 'ENDFILE'
export default function MenusIndexPage() {
  return (
    <div className="flex h-full items-center justify-center">
      <div className="text-center">
        <p className="text-5xl mb-4">📋</p>
        <h2 className="text-lg font-semibold text-gray-400">Karte auswählen</h2>
        <p className="text-sm text-gray-300 mt-1">Wähle eine Karte aus der Liste links</p>
      </div>
    </div>
  );
}
ENDFILE

# Menu detail page
mkdir -p "src/app/admin/menus/[id]"
cat > "src/app/admin/menus/[id]/page.tsx" << 'ENDFILE'
import { notFound } from 'next/navigation';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import Link from 'next/link';

export default async function MenuDetailPage({ params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return null;

  const menu = await prisma.menu.findUnique({
    where: { id: params.id },
    include: {
      translations: true,
      location: { include: { tenant: true } },
      sections: {
        where: { isActive: true },
        orderBy: { sortOrder: 'asc' },
        include: {
          translations: { where: { languageCode: 'de' } },
          placements: {
            where: { isVisible: true },
            orderBy: { sortOrder: 'asc' },
            include: {
              product: {
                include: {
                  translations: { where: { languageCode: 'de' } },
                  prices: { take: 1, orderBy: { sortOrder: 'asc' } },
                  productWineProfile: { select: { winery: true, vintage: true } },
                },
              },
            },
          },
        },
      },
      qrCodes: true,
    },
  });
  if (!menu) return notFound();

  const menuName = menu.translations.find(t => t.languageCode === 'de')?.name || menu.slug;
  const tenant = menu.location.tenant;
  const publicUrl = `/${tenant.slug}/${menu.location.slug}/${menu.slug}`;
  const totalProducts = menu.sections.reduce((sum, s) => sum + s.placements.length, 0);

  return (
    <div className="max-w-4xl space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold" style={{fontFamily: "'Playfair Display', serif"}}>{menuName}</h1>
          <p className="text-sm text-gray-400 mt-1">
            {menu.location.name} · {menu.type} · {menu.sections.length} Sektionen · {totalProducts} Produkte
          </p>
        </div>
        <div className="flex gap-2">
          <a href={publicUrl} target="_blank" className="rounded-lg border px-3 py-1.5 text-xs font-medium hover:bg-gray-50">
            Vorschau ↗
          </a>
          <span className={`rounded-full px-3 py-1.5 text-xs font-medium ${menu.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
            {menu.isActive ? 'Aktiv' : 'Inaktiv'}
          </span>
        </div>
      </div>

      {/* QR Codes */}
      {menu.qrCodes.length > 0 && (
        <div className="flex gap-2">
          {menu.qrCodes.map(qr => (
            <span key={qr.id} className="rounded-lg bg-gray-100 px-3 py-1 text-xs text-gray-600">
              📱 {qr.label || qr.shortCode}
            </span>
          ))}
        </div>
      )}

      {/* Sections with Products */}
      {menu.sections.map(section => {
        const sName = section.translations[0]?.name || section.slug;
        return (
          <div key={section.id} className="rounded-xl border bg-white shadow-sm overflow-hidden">
            <div className="border-b bg-gray-50/50 px-4 py-3 flex items-center justify-between">
              <div>
                <h2 className="text-sm font-semibold">{section.icon && <span className="mr-1">{section.icon}</span>}{sName}</h2>
                <p className="text-[10px] text-gray-400">{section.placements.length} Produkte</p>
              </div>
            </div>
            <div className="divide-y">
              {section.placements.map((pl, i) => {
                const p = pl.product;
                const pName = p.translations[0]?.name || '';
                const price = pl.priceOverride ? Number(pl.priceOverride) : p.prices[0] ? Number(p.prices[0].price) : null;
                const winery = p.productWineProfile?.winery;
                const vintage = p.productWineProfile?.vintage;
                return (
                  <div key={pl.id} className="flex items-center justify-between px-4 py-2.5 hover:bg-gray-50/50">
                    <div className="flex items-center gap-3 flex-1 min-w-0">
                      <span className="text-xs text-gray-300 w-5 text-right">{i + 1}</span>
                      <div className="min-w-0">
                        <Link href={`/admin/items/${p.id}`} className="text-sm font-medium text-gray-800 hover:text-amber-700 truncate block">{pName}</Link>
                        {winery && <p className="text-[11px] text-gray-400">{winery}{vintage ? ` ${vintage}` : ''}</p>}
                      </div>
                    </div>
                    {price !== null && (
                      <span className="text-sm font-semibold text-gray-600 tabular-nums flex-shrink-0">
                        {new Intl.NumberFormat('de-AT', { style: 'currency', currency: 'EUR' }).format(price)}
                      </span>
                    )}
                  </div>
                );
              })}
              {section.placements.length === 0 && (
                <div className="px-4 py-4 text-center text-xs text-gray-400">Keine Produkte in dieser Sektion</div>
              )}
            </div>
          </div>
        );
      })}

      <div className="text-xs text-gray-300">
        ID: {menu.id} · Slug: {menu.slug}
      </div>
    </div>
  );
}
ENDFILE

echo "4/4 Building..."
npm run build && pm2 restart menucard-pro

echo ""
echo "=== Deployed! ==="
echo "Test:"
echo "  Neues Produkt: /admin/items → + Button oben rechts"
echo "  Kartenverwaltung: /admin/menus → Karte anklicken"
