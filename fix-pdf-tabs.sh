#!/bin/bash
# Fix: Design-Tabs als Client-Wrapper + Server-Page wiederherstellen
cd /var/www/menucard-pro

echo "=== Fix PDF Tabs ==="

# 1. Design-Tabs Client-Komponente
cat > src/components/admin/design-tabs.tsx << 'ENDOFFILE'
'use client';

import { useState } from 'react';
import DesignEditor from '@/components/admin/design-editor';
import AnalogDesignEditor from '@/components/admin/analog-design-editor';

type Props = {
  menuId: string;
  tenantSlug: string;
  locationSlug: string;
  menuSlug: string;
};

export default function DesignTabs({ menuId, tenantSlug, locationSlug, menuSlug }: Props) {
  const [activeTab, setActiveTab] = useState<'digital' | 'pdf'>('digital');

  return (
    <div className="flex flex-col flex-1 overflow-hidden">
      <div className="flex justify-center py-3 border-b bg-gray-50">
        <div className="flex bg-gray-200 rounded-lg p-1">
          <button onClick={() => setActiveTab('digital')}
            className={`px-5 py-2 rounded-md text-sm font-medium transition-all ${
              activeTab === 'digital' ? 'bg-white shadow-sm text-blue-600' : 'text-gray-600 hover:text-gray-900'
            }`}>
            🖥️ Digital
          </button>
          <button onClick={() => setActiveTab('pdf')}
            className={`px-5 py-2 rounded-md text-sm font-medium transition-all ${
              activeTab === 'pdf' ? 'bg-white shadow-sm text-blue-600' : 'text-gray-600 hover:text-gray-900'
            }`}>
            📄 PDF / Druck
          </button>
        </div>
      </div>
      <div className="flex-1 overflow-hidden">
        {activeTab === 'digital' ? (
          <DesignEditor menuId={menuId} tenantSlug={tenantSlug} locationSlug={locationSlug} menuSlug={menuSlug} />
        ) : (
          <AnalogDesignEditor menuId={menuId} />
        )}
      </div>
    </div>
  );
}
ENDOFFILE

echo "  ✓ design-tabs.tsx erstellt"

# 2. Server-Page wiederherstellen mit Tabs
cat > src/app/admin/menus/\[id\]/design/page.tsx << 'ENDOFFILE'
import { notFound, redirect } from 'next/navigation';
import prisma from '@/lib/prisma';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import Link from 'next/link';
import DesignTabs from '@/components/admin/design-tabs';

export default async function DesignEditorPage({
  params,
}: {
  params: { id: string };
}) {
  const session = await getServerSession(authOptions);
  if (!session?.user) redirect('/admin/login');

  const menu = await prisma.menu.findUnique({
    where: { id: params.id },
    include: {
      translations: true,
      location: { include: { tenant: true } },
    },
  });
  if (!menu) return notFound();

  const menuName = menu.translations.find(t => t.languageCode === 'de')?.name
    || menu.translations[0]?.name
    || menu.slug
    || 'Karte';

  return (
    <div className="flex flex-col h-screen">
      <div className="flex items-center justify-between border-b bg-white px-4 py-3">
        <div className="flex items-center gap-3">
          <Link href={`/admin/menus/${menu.id}`}
            className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700">
            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" /></svg>
            Zurück
          </Link>
          <div className="h-4 border-l border-gray-300" />
          <h1 className="text-sm font-semibold">{menuName} – Design</h1>
        </div>
      </div>
      <DesignTabs
        menuId={menu.id}
        tenantSlug={menu.location.tenant.slug}
        locationSlug={menu.location.slug}
        menuSlug={menu.slug}
      />
    </div>
  );
}
ENDOFFILE

echo "  ✓ page.tsx wiederhergestellt mit Tabs"

# 3. Build
echo "[3/3] Build..."
npm run build 2>&1 | tail -20

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo ""
  echo "  ✅ Fix erfolgreich! Tabs sollten jetzt funktionieren."
else
  echo ""
  echo "  ❌ Build fehlgeschlagen – siehe Fehler oben."
fi
