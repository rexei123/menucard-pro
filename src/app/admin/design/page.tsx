import { redirect } from 'next/navigation';
import prisma from '@/lib/prisma';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import Link from 'next/link';

export default async function DesignOverviewPage() {
  const session = await getServerSession(authOptions);
  if (!session?.user) redirect('/admin/login');

  const user = await prisma.user.findUnique({
    where: { email: session.user.email! },
    include: { tenant: true },
  });
  if (!user?.tenantId) redirect('/admin/login');

  const menus = await prisma.menu.findMany({
    where: {
      location: { tenantId: user.tenantId },
    },
    include: {
      translations: true,
      location: true,
    },
    orderBy: { createdAt: 'desc' },
  });

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="mx-auto max-w-3xl px-4 py-8">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-xl font-bold text-gray-900">Karten-Design</h1>
          <Link href="/admin" className="text-sm text-gray-500 hover:text-gray-700">
            ← Zurück zum Admin
          </Link>
        </div>
        <div className="space-y-3">
          {menus.map(menu => {
            const name = menu.translations.find(t => t.languageCode === 'de')?.name
              || menu.translations[0]?.name
              || menu.slug
              || 'Karte';
            return (
              <div key={menu.id} className="flex items-center justify-between rounded-lg border bg-white p-4 hover:shadow-sm transition-all">
                <div>
                  <div className="font-medium text-gray-900">{name}</div>
                  <div className="text-sm text-gray-500">{menu.location.name} · {menu.type}</div>
                </div>
                <div className="flex items-center gap-3">
                  <a href={`/api/v1/menus/${menu.id}/pdf`} target="_blank" rel="noopener noreferrer"
                    className="flex items-center gap-1 rounded-lg border border-gray-200 px-3 py-1.5 text-xs text-gray-600 hover:bg-gray-50 transition-colors">
                    PDF
                  </a>
                  <Link href={`/admin/menus/${menu.id}/design`}
                    className="flex items-center gap-1 text-sm text-blue-500 hover:underline">
                    Design bearbeiten
                    <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
                  </Link>
                </div>
              </div>
            );
          })}
          {menus.length === 0 && (
            <div className="text-center py-12 text-gray-400">
              Noch keine Karten vorhanden.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
