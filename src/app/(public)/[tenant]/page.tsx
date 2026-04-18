import { notFound } from 'next/navigation';
import { Suspense } from 'react';
import prisma from '@/lib/prisma';
import Link from 'next/link';
import LanguageSwitcher from '@/components/language-switcher';

export default async function TenantPage({
  params,
  searchParams,
}: {
  params: { tenant: string };
  searchParams: { lang?: string };
}) {
  const lang = searchParams.lang === 'en' ? 'en' : 'de';
  const t = (translations: any[], field: 'name' | 'description' = 'name') => {
    const found = translations.find(tr => tr.languageCode === lang);
    const fb = translations.find(tr => tr.languageCode === 'de');
    return (found?.[field] || fb?.[field]) ?? '';
  };

  const tenant = await prisma.tenant.findUnique({
    where: { slug: params.tenant },
    include: {
      themes: { where: { isActive: true }, take: 1 },
      locations: {
        orderBy: { createdAt: 'asc' },
        include: {
          translations: true,
          menus: {
            where: { status: { not: 'ARCHIVED' } },
            orderBy: { sortOrder: 'asc' },
            include: { translations: true },
          },
        },
      },
    },
  });
  if (!tenant) return notFound();
  const theme = tenant.themes[0];
  const themeCfg: any = theme?.config ?? {};
  const langParam = lang === 'en' ? '?lang=en' : '';
  const menuLabel = (n: number) =>
    lang === 'en'
      ? (n === 1 ? 'menu' : 'menus')
      : (n === 1 ? 'Karte' : 'Karten');

  return (
    <div className="min-h-screen" style={{ background: themeCfg.backgroundColor || '#FAFAF8' }}>
      <header className="border-b px-6 py-8 text-center">
        <h1 className="text-3xl font-bold tracking-tight" style={{fontFamily: "'Playfair Display', serif"}}>{tenant.name}</h1>
      </header>
      <main className="mx-auto max-w-lg px-4 py-8 space-y-4">
        {tenant.locations.map((loc) => (
          <Link key={loc.id} href={`/${tenant.slug}/${loc.slug}${langParam}`} className="block rounded-2xl border bg-white p-6 shadow-sm hover:shadow-md">
            <h2 className="text-lg font-semibold" style={{fontFamily: "'Playfair Display', serif"}}>{t(loc.translations)}</h2>
            <p className="mt-1 text-sm text-gray-500">{t(loc.translations, 'description')}</p>
            <p className="mt-2 text-xs text-gray-400">{loc.menus.length} {menuLabel(loc.menus.length)}</p>
          </Link>
        ))}
      </main>
      <Suspense fallback={null}>
        <LanguageSwitcher />
      </Suspense>
    </div>
  );
}
