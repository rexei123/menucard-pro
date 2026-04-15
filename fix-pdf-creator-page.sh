#!/bin/bash
# Fix: PDF-Creator Seite erstellen
cd /var/www/menucard-pro

echo "=== PDF-Creator Seite ==="

mkdir -p src/app/admin/pdf-creator

cat > src/app/admin/pdf-creator/page.tsx << 'ENDOFFILE'
import { redirect } from 'next/navigation';
import prisma from '@/lib/prisma';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import Link from 'next/link';

export default async function PdfCreatorPage() {
  const session = await getServerSession(authOptions);
  if (!session?.user) redirect('/admin/login');

  const menus = await prisma.menu.findMany({
    include: {
      translations: true,
      location: { include: { tenant: true } },
    },
    orderBy: { createdAt: 'asc' },
  });

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">PDF-Creator</h1>
          <p className="text-sm text-gray-500 mt-1">PDF-Karten generieren, gestalten und herunterladen</p>
        </div>
      </div>

      <div className="space-y-3">
        {menus.map((menu) => {
          const name = menu.translations.find((t: any) => t.languageCode === 'de')?.name
            || menu.translations[0]?.name
            || menu.slug;
          const typeBadge = menu.type === 'WINE' ? 'WINE' : menu.type === 'BAR' ? 'BAR' : 'EVENT';
          const locationName = menu.location?.name || '';

          return (
            <div key={menu.id} className="flex items-center justify-between p-4 bg-white border border-gray-200 rounded-lg hover:shadow-sm transition-shadow">
              <div>
                <h3 className="font-semibold text-gray-900">{name}</h3>
                <p className="text-sm text-gray-500">{locationName} · {typeBadge}</p>
              </div>
              <div className="flex items-center gap-2">
                <a href={`/api/v1/menus/${menu.id}/pdf`} target="_blank" rel="noopener noreferrer"
                  className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 text-sm font-medium transition-colors inline-flex items-center gap-1.5">
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
                  PDF
                </a>
                <Link href={`/admin/menus/${menu.id}/design`}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-sm font-medium transition-colors inline-flex items-center gap-1.5">
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" /></svg>
                  Design bearbeiten
                </Link>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
ENDOFFILE

echo "  ✓ PDF-Creator Seite erstellt"

echo "[2/2] Build..."
npm run build 2>&1 | tail -15

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo ""
  echo "  ✅ PDF-Creator Seite LIVE!"
  echo "  → /admin/pdf-creator"
else
  echo ""
  echo "  ❌ Build fehlgeschlagen"
fi
