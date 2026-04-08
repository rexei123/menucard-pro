#!/bin/bash
# =====================================================
# MenuCard Pro - Language Switcher Feature
# Single deploy script - contains all files
# Run: bash deploy-lang.sh
# =====================================================

set -e
cd /var/www/menucard-pro

echo "=== Deploying Language Switcher (DE/EN) ==="

# Backup
echo "1/4 Backing up..."
mkdir -p /tmp/menucard-backup-lang
cp -f "src/app/(public)/[tenant]/page.tsx" /tmp/menucard-backup-lang/tenant.bak 2>/dev/null || true
cp -f "src/app/(public)/[tenant]/[location]/page.tsx" /tmp/menucard-backup-lang/location.bak 2>/dev/null || true
cp -f "src/app/(public)/[tenant]/[location]/[menu]/page.tsx" /tmp/menucard-backup-lang/menu.bak 2>/dev/null || true

# Ensure directories
mkdir -p src/components

# === FILE 1: Language Switcher Component ===
echo "2/4 Writing files..."

cat > src/components/language-switcher.tsx << 'ENDFILE'
'use client';

import { usePathname, useSearchParams, useRouter } from 'next/navigation';

export default function LanguageSwitcher() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const router = useRouter();
  const current = searchParams.get('lang') === 'en' ? 'en' : 'de';

  const toggle = () => {
    const next = current === 'de' ? 'en' : 'de';
    const params = new URLSearchParams(searchParams.toString());
    if (next === 'de') {
      params.delete('lang');
    } else {
      params.set('lang', next);
    }
    const qs = params.toString();
    router.replace(qs ? `${pathname}?${qs}` : pathname, { scroll: false });
  };

  return (
    <button
      onClick={toggle}
      className="fixed bottom-4 right-4 z-50 flex items-center gap-1.5 rounded-full border bg-white/95 px-3 py-2 text-xs font-medium shadow-lg backdrop-blur-sm transition-all hover:shadow-xl active:scale-95"
      aria-label={current === 'de' ? 'Switch to English' : 'Auf Deutsch wechseln'}
    >
      <span className="text-sm">{current === 'de' ? '🇬🇧' : '🇦🇹'}</span>
      <span className="uppercase tracking-wide">{current === 'de' ? 'EN' : 'DE'}</span>
    </button>
  );
}
ENDFILE

# === FILE 2: Tenant Page ===
cat > "src/app/(public)/[tenant]/page.tsx" << 'ENDFILE'
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
  const t = (translations: { languageCode: string; name?: string; description?: string }[], field: 'name' | 'description' = 'name') => {
    const found = translations.find(tr => tr.languageCode === lang);
    const fb = translations.find(tr => tr.languageCode === 'de');
    return (found?.[field] || fb?.[field]) ?? '';
  };

  const tenant = await prisma.tenant.findUnique({
    where: { slug: params.tenant, isActive: true },
    include: {
      themes: { where: { isActive: true }, take: 1 },
      locations: { where: { isActive: true }, orderBy: { sortOrder: 'asc' }, include: { translations: true, menus: { where: { isActive: true, isArchived: false }, include: { translations: true } } } },
    },
  });
  if (!tenant) return notFound();
  const theme = tenant.themes[0];
  const langParam = lang === 'en' ? '?lang=en' : '';
  const menuLabel = lang === 'en' ? 'menus' : 'Karten';

  return (
    <div className="min-h-screen" style={{ background: theme?.backgroundColor || '#FAFAF8' }}>
      <header className="border-b px-6 py-8 text-center">
        <h1 className="text-3xl font-bold tracking-tight" style={{fontFamily: "'Playfair Display', serif"}}>{tenant.name}</h1>
      </header>
      <main className="mx-auto max-w-lg px-4 py-8 space-y-4">
        {tenant.locations.map((loc) => (
          <Link key={loc.id} href={`/${tenant.slug}/${loc.slug}${langParam}`} className="block rounded-2xl border bg-white p-6 shadow-sm hover:shadow-md">
            <h2 className="text-lg font-semibold" style={{fontFamily: "'Playfair Display', serif"}}>{t(loc.translations)}</h2>
            <p className="mt-1 text-sm text-gray-500">{t(loc.translations, 'description')}</p>
            <p className="mt-2 text-xs text-gray-400">{loc.menus.length} {menuLabel}</p>
          </Link>
        ))}
      </main>
      <Suspense fallback={null}>
        <LanguageSwitcher />
      </Suspense>
    </div>
  );
}
ENDFILE

# === FILE 3: Location Page ===
cat > "src/app/(public)/[tenant]/[location]/page.tsx" << 'ENDFILE'
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
  const t = (translations: { languageCode: string; name?: string; description?: string }[], field: 'name' | 'description' = 'name') => {
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
ENDFILE

# === FILE 4: Menu Page ===
cat > "src/app/(public)/[tenant]/[location]/[menu]/page.tsx" << 'ENDFILE'
import { notFound } from 'next/navigation';
import { Suspense } from 'react';
import prisma from '@/lib/prisma';
import Link from 'next/link';
import { formatPrice } from '@/lib/utils';
import LanguageSwitcher from '@/components/language-switcher';

const hlLabels: Record<string, Record<string, string>> = {
  RECOMMENDATION: { de: 'Empfehlung', en: 'Recommended' },
  NEW: { de: 'Neu', en: 'New' },
  POPULAR: { de: 'Beliebt', en: 'Popular' },
  PREMIUM: { de: 'Premium', en: 'Premium' },
  SEASONAL: { de: 'Saison', en: 'Seasonal' },
  CHEFS_CHOICE: { de: "Chef's Choice", en: "Chef's Choice" },
};

const ui: Record<string, Record<string, string>> = {
  soldOut: { de: 'Ausverkauft', en: 'Sold out' },
  prices: { de: 'Alle Preise in Euro inkl. MwSt.', en: 'All prices in EUR incl. taxes.' },
  powered: { de: 'Powered by MenuCard Pro', en: 'Powered by MenuCard Pro' },
};

export default async function MenuPage({
  params,
  searchParams,
}: {
  params: { tenant: string; location: string; menu: string };
  searchParams: { lang?: string };
}) {
  const lang = searchParams.lang === 'en' ? 'en' : 'de';
  const t = (translations: { languageCode: string; name?: string; shortDescription?: string; description?: string }[], field: 'name' | 'shortDescription' | 'description' = 'name') => {
    const found = translations.find(tr => tr.languageCode === lang);
    const fb = translations.find(tr => tr.languageCode === 'de');
    return (found?.[field] || fb?.[field]) ?? '';
  };

  const tenant = await prisma.tenant.findUnique({ where: { slug: params.tenant, isActive: true } });
  if (!tenant) return notFound();
  const location = await prisma.location.findUnique({ where: { tenantId_slug: { tenantId: tenant.id, slug: params.location } } });
  if (!location) return notFound();
  const menu = await prisma.menu.findUnique({
    where: { locationId_slug: { locationId: location.id, slug: params.menu } },
    include: {
      translations: true,
      sections: { where: { isActive: true }, orderBy: { sortOrder: 'asc' }, include: {
        translations: true,
        items: { where: { isActive: true }, orderBy: { sortOrder: 'asc' }, include: {
          translations: true,
          priceVariants: { orderBy: { sortOrder: 'asc' } },
          allergens: { include: { allergen: { include: { translations: true } } } },
          tags: { include: { tag: { include: { translations: true } } } },
          wineProfile: true,
        } },
      } },
    },
  });
  if (!menu) return notFound();
  const theme = await prisma.theme.findFirst({ where: { tenantId: tenant.id, isActive: true } });
  const menuName = t(menu.translations);
  const langParam = lang === 'en' ? '?lang=en' : '';
  const priceLocale = lang === 'en' ? 'en-GB' : 'de-AT';

  return (
    <div className="min-h-screen pb-16" style={{ background: theme?.backgroundColor || '#FAFAF8', color: theme?.textColor || '#1a1a1a' }}>
      <header className="border-b px-6 py-6 text-center">
        <Link href={`/${tenant.slug}/${location.slug}${langParam}`} className="text-xs uppercase tracking-widest opacity-40">{tenant.name}</Link>
        <h1 className="mt-2 text-3xl font-bold tracking-tight" style={{fontFamily: "'Playfair Display', serif"}}>{menuName}</h1>
      </header>
      {menu.sections.length > 1 && (
        <nav className="sticky top-0 z-10 border-b bg-white/90 backdrop-blur-md">
          <div className="flex overflow-x-auto px-4 py-2 gap-1">
            {menu.sections.map(s => (
              <a key={s.id} href={`#${s.slug}`} className="flex-shrink-0 rounded-full px-4 py-2 text-sm font-medium hover:bg-black/5" style={{whiteSpace:'nowrap'}}>
                {s.icon && <span className="mr-1">{s.icon}</span>}{t(s.translations)}
              </a>
            ))}
          </div>
        </nav>
      )}
      <main className="mx-auto max-w-2xl px-4">
        {menu.sections.map(section => {
          const sName = t(section.translations);
          const sDesc = t(section.translations, 'description');
          return (
            <section key={section.id} id={section.slug} className="scroll-mt-16 py-8">
              <div className="mb-6 text-center">
                {section.icon && <span className="text-2xl">{section.icon}</span>}
                <h2 className="text-xl font-bold tracking-tight" style={{fontFamily: "'Playfair Display', serif"}}>{sName}</h2>
                {sDesc && <p className="mt-1 text-sm opacity-50">{sDesc}</p>}
                <div className="mx-auto mt-3 h-px w-16" style={{backgroundColor: (theme?.accentColor || '#8B6914') + '40'}} />
              </div>
              <div className="space-y-2">
                {section.items.map(item => {
                  const iName = t(item.translations);
                  const iDesc = t(item.translations, 'shortDescription');
                  const defPrice = item.priceVariants.find(p => p.isDefault) || item.priceVariants[0];
                  const multiPrice = item.priceVariants.length > 1;
                  return (
                    <div key={item.id} className={`rounded-xl border bg-white p-4 shadow-sm ${item.isSoldOut ? 'opacity-50' : ''}`}>
                      <div className="flex items-start justify-between gap-3">
                        <div>
                          <div className="flex items-center gap-2 flex-wrap">
                            <h3 className="text-base font-semibold" style={{fontFamily: "'Playfair Display', serif"}}>{iName}</h3>
                            {item.isHighlight && item.highlightType && (
                              <span className="rounded-full px-2 py-0.5 text-[10px] font-semibold text-white" style={{backgroundColor: theme?.accentColor || '#8B6914'}}>{hlLabels[item.highlightType]?.[lang] || ''}</span>
                            )}
                            {item.isSoldOut && <span className="rounded-full bg-red-100 px-2 py-0.5 text-[10px] font-medium text-red-600">{ui.soldOut[lang]}</span>}
                          </div>
                          {iDesc && <p className="mt-1 text-sm opacity-60">{iDesc}</p>}
                          {item.wineProfile && (
                            <div className="mt-2 flex flex-wrap gap-x-3 text-xs opacity-50">
                              {item.wineProfile.winery && <span>{item.wineProfile.winery}</span>}
                              {item.wineProfile.vintage && <span>{item.wineProfile.vintage}</span>}
                              {item.wineProfile.region && <span>{item.wineProfile.region}</span>}
                            </div>
                          )}
                          {item.allergens.length > 0 && (
                            <div className="mt-2 flex flex-wrap gap-1">
                              {item.allergens.map(a => (
                                <span key={a.allergen.id} className="rounded bg-amber-50 px-1.5 py-0.5 text-[10px] text-amber-700">{t(a.allergen.translations)}</span>
                              ))}
                            </div>
                          )}
                          {item.tags.length > 0 && (
                            <div className="mt-2 flex flex-wrap gap-1">
                              {item.tags.map(tg => (
                                <span key={tg.tag.id} className="rounded-full bg-gray-100 px-2 py-0.5 text-[10px] font-medium">{tg.tag.icon} {t(tg.tag.translations)}</span>
                              ))}
                            </div>
                          )}
                        </div>
                      </div>
                      <div className="mt-3 flex flex-wrap items-baseline gap-3">
                        {multiPrice ? item.priceVariants.map(pv => (
                          <div key={pv.id} className="text-sm">
                            <span className="font-semibold tabular-nums">{formatPrice(Number(pv.price), 'EUR', priceLocale)}</span>
                            {(pv.label || pv.volume) && <span className="ml-1 text-xs opacity-40">{pv.label || pv.volume}</span>}
                          </div>
                        )) : defPrice && <span className="text-sm font-semibold tabular-nums">{formatPrice(Number(defPrice.price), 'EUR', priceLocale)}</span>}
                      </div>
                    </div>
                  );
                })}
              </div>
            </section>
          );
        })}
        <div className="border-t py-8 text-center">
          <p className="text-xs opacity-30">{ui.prices[lang]}</p>
          <p className="mt-1 text-xs opacity-20">{ui.powered[lang]}</p>
        </div>
      </main>
      <Suspense fallback={null}>
        <LanguageSwitcher />
      </Suspense>
    </div>
  );
}
ENDFILE

echo "3/4 Building..."
npm run build

echo "4/4 Restarting..."
pm2 restart menucard-pro

echo ""
echo "=== Language Switcher deployed! ==="
echo ""
echo "Test DE: http://178.104.138.177/hotel-sonnblick/restaurant/weinkarte"
echo "Test EN: http://178.104.138.177/hotel-sonnblick/restaurant/weinkarte?lang=en"
