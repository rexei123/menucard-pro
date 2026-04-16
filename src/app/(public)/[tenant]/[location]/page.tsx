import { notFound } from 'next/navigation';
import { Suspense } from 'react';
import prisma from '@/lib/prisma';
import Link from 'next/link';
import LanguageSwitcher from '@/components/language-switcher';

const typeIcons: Record<string, string> = {
  FOOD: 'restaurant', DRINKS: 'local_bar', WINE: 'wine_bar',
  BREAKFAST: 'coffee', BAR: 'local_bar', SPA: 'spa',
  ROOM_SERVICE: 'room_service', MINIBAR: 'kitchen', EVENT: 'celebration',
  DAILY_SPECIAL: 'star', SEASONAL: 'eco',
};

export default async function LocationPage({
  params, searchParams,
}: {
  params: { tenant: string; location: string };
  searchParams: { lang?: string };
}) {
  const lang = searchParams.lang === 'en' ? 'en' : 'de';
  const t = (translations: any[], field: 'name' | 'description' = 'name') => {
    const found = translations.find((tr: any) => tr.languageCode === lang);
    const fb = translations.find((tr: any) => tr.languageCode === 'de');
    return (found?.[field] || fb?.[field]) ?? '';
  };

  const tenant = await prisma.tenant.findUnique({ where: { slug: params.tenant, isActive: true } });
  if (!tenant) return notFound();

  const location = await prisma.location.findUnique({
    where: { tenantId_slug: { tenantId: tenant.id, slug: params.location } },
    include: {
      translations: true,
      menus: {
        where: { isActive: true, isArchived: false },
        orderBy: { sortOrder: 'asc' },
        include: {
          translations: true,
          _count: { select: { sections: true } },
        },
      },
    },
  });
  if (!location) return notFound();

  const langParam = lang === 'en' ? '?lang=en' : '';

  return (
    <div className="min-h-screen" style={{ backgroundColor: 'var(--color-bg, #FFFFFF)' }}>
      {/* Header */}
      <header className="px-6 py-8 text-center">
        <p
          className="text-xs uppercase tracking-[0.25em] mb-3"
          style={{ color: 'var(--color-text-muted, #8E8E8E)', fontFamily: 'var(--font-display, Inter)' }}
        >
          {tenant.name}
        </p>
        <h1
          className="text-2xl font-bold"
          style={{ fontFamily: 'var(--font-heading)', color: 'var(--color-text, #1A1A1A)' }}
        >
          {t(location.translations)}
        </h1>
        <div
          className="mx-auto mt-3 w-10 h-0.5"
          style={{ backgroundColor: 'var(--color-primary, #DD3C71)' }}
        />
      </header>

      {/* Menü-Karten */}
      <main className="mx-auto max-w-lg px-4 pb-8 space-y-3">
        {location.menus.map((menu) => {
          const icon = typeIcons[menu.type] || 'description';
          const name = t(menu.translations);
          const desc = t(menu.translations, 'description');

          return (
            <Link
              key={menu.id}
              href={`/${tenant.slug}/${location.slug}/${menu.slug}${langParam}`}
              className="flex items-center gap-4 rounded-xl border p-5 transition-all hover:shadow-md"
              style={{
                backgroundColor: 'var(--color-surface, #FFFFFF)',
                borderColor: 'var(--color-border-subtle, rgba(0,0,0,0.04))',
              }}
            >
              <div
                className="flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-xl"
                style={{ backgroundColor: 'var(--color-primary-light, #FDF2F5)' }}
              >
                <span
                  className="material-symbols-outlined"
                  style={{ fontSize: 24, color: 'var(--color-primary, #DD3C71)' }}
                >
                  {icon}
                </span>
              </div>
              <div className="flex-1 min-w-0">
                <h2
                  className="text-base font-semibold"
                  style={{ fontFamily: 'var(--font-heading)', color: 'var(--color-text, #1A1A1A)' }}
                >
                  {name}
                </h2>
                {desc && (
                  <p className="mt-0.5 text-sm truncate" style={{ color: 'var(--color-text-muted, #8E8E8E)' }}>
                    {desc}
                  </p>
                )}
              </div>
              <span
                className="material-symbols-outlined flex-shrink-0"
                style={{ fontSize: 20, color: 'var(--color-text-muted, #8E8E8E)' }}
              >
                chevron_right
              </span>
            </Link>
          );
        })}
      </main>

      <Suspense fallback={null}>
        <LanguageSwitcher />
      </Suspense>
    </div>
  );
}
