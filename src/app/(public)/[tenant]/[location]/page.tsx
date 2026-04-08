import { notFound } from 'next/navigation';
import { Suspense } from 'react';
import prisma from '@/lib/prisma';
import Link from 'next/link';
import LanguageSwitcher from '@/components/language-switcher';

const icons: Record<string, string> = { FOOD: '🍽️', DRINKS: '🥤', WINE: '🍷', BREAKFAST: '🥐', BAR: '🍸', SPA: '🧖', ROOM_SERVICE: '🛎️', MINIBAR: '🧊', EVENT: '🎉' };

export default async function LocationPage({
  params,
  searchParams,
}: {
  params: { tenant: string; location: string };
  searchParams: { lang?: string };
}) {
  const lang = searchParams.lang === 'en' ? 'en' : 'de';
  const t = (translations: any[], field: 'name' | 'description' = 'name') => {
    const found = translations.find(tr => tr.languageCode === lang);
    const fb = translations.find(tr => tr.languageCode === 'de');
    return (found?.[field] || fb?.[field]) ?? '';
  };

  const tenant = await prisma.tenant.findUnique({ where: { slug: params.tenant, isActive: true } });
  if (!tenant) return notFound();
  const location = await prisma.location.findUnique({
    where: { tenantId_slug: { tenantId: tenant.id, slug: params.location } },
    include: { translations: true, menus: { where: { isActive: true, isArchived: false }, orderBy: { sortOrder: 'asc' }, include: { translations: true } } },
  });
  if (!location) return notFound();
  const langParam = lang === 'en' ? '?lang=en' : '';

  return (
    <div className="min-h-screen bg-[#FAFAF8]">
      <header className="border-b px-6 py-6 text-center">
        <Link href={`/${tenant.slug}${langParam}`} className="text-xs uppercase tracking-widest text-gray-400">{tenant.name}</Link>
        <h1 className="mt-2 text-2xl font-bold" style={{fontFamily: "'Playfair Display', serif"}}>{t(location.translations)}</h1>
      </header>
      <main className="mx-auto max-w-lg px-4 py-6 space-y-3">
        {location.menus.map((menu) => (
          <Link key={menu.id} href={`/${tenant.slug}/${location.slug}/${menu.slug}${langParam}`} className="flex items-center gap-4 rounded-2xl border bg-white p-5 shadow-sm hover:shadow-md">
            <span className="text-3xl">{icons[menu.type] || '📄'}</span>
            <div>
              <h2 className="text-lg font-semibold" style={{fontFamily: "'Playfair Display', serif"}}>{t(menu.translations)}</h2>
              <p className="mt-0.5 text-sm text-gray-400">{t(menu.translations, 'description')}</p>
            </div>
          </Link>
        ))}
      </main>
      <Suspense fallback={null}>
        <LanguageSwitcher />
      </Suspense>
    </div>
  );
}
