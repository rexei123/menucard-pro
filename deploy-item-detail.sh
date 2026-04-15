#!/bin/bash
# =====================================================
# MenuCard Pro - T-030 Artikeldetail-Seite
# Run: bash deploy-item-detail.sh
# =====================================================

set -e
cd /var/www/menucard-pro

echo "=== Deploying Item Detail Page ==="

# Backup
echo "1/4 Backing up..."
mkdir -p /tmp/menucard-backup-detail
cp -f "src/app/(public)/[tenant]/[location]/[menu]/page.tsx" /tmp/menucard-backup-detail/menu-page.bak 2>/dev/null || true

# Create detail page directory
mkdir -p "src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]"

echo "2/4 Writing files..."

# === FILE 1: Item Detail Page ===
cat > "src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx" << 'ENDFILE'
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

const styleLabels: Record<string, Record<string, string>> = {
  RED: { de: 'Rotwein', en: 'Red Wine' },
  WHITE: { de: 'Weisswein', en: 'White Wine' },
  ROSE: { de: 'Rose', en: 'Rose' },
  SPARKLING: { de: 'Schaumwein', en: 'Sparkling Wine' },
  DESSERT: { de: 'Dessertwein', en: 'Dessert Wine' },
  FORTIFIED: { de: 'Likoerwein', en: 'Fortified Wine' },
  ORANGE: { de: 'Orange Wine', en: 'Orange Wine' },
  NATURAL: { de: 'Naturwein', en: 'Natural Wine' },
};

const bodyLabels: Record<string, Record<string, string>> = {
  LIGHT: { de: 'Leicht', en: 'Light' },
  LIGHT_MEDIUM: { de: 'Leicht bis Mittel', en: 'Light to Medium' },
  MEDIUM: { de: 'Mittel', en: 'Medium' },
  MEDIUM_FULL: { de: 'Mittel bis Voll', en: 'Medium to Full' },
  FULL: { de: 'Vollmundig', en: 'Full-Bodied' },
};

const sweetnessLabels: Record<string, Record<string, string>> = {
  BONE_DRY: { de: 'Extra trocken', en: 'Bone Dry' },
  DRY: { de: 'Trocken', en: 'Dry' },
  OFF_DRY: { de: 'Halbtrocken', en: 'Off-Dry' },
  MEDIUM_DRY: { de: 'Halbtrocken', en: 'Medium Dry' },
  MEDIUM_SWEET: { de: 'Lieblich', en: 'Medium Sweet' },
  SWEET: { de: 'Suess', en: 'Sweet' },
};

const ui: Record<string, Record<string, string>> = {
  back: { de: 'Zurueck zur Karte', en: 'Back to menu' },
  soldOut: { de: 'Ausverkauft', en: 'Sold out' },
  winery: { de: 'Weingut', en: 'Winery' },
  vintage: { de: 'Jahrgang', en: 'Vintage' },
  grapes: { de: 'Rebsorten', en: 'Grape Varieties' },
  region: { de: 'Region', en: 'Region' },
  country: { de: 'Land', en: 'Country' },
  appellation: { de: 'Appellation', en: 'Appellation' },
  style: { de: 'Stil', en: 'Style' },
  body: { de: 'Koerper', en: 'Body' },
  sweetness: { de: 'Suesse', en: 'Sweetness' },
  bottleSize: { de: 'Flaschengroesse', en: 'Bottle Size' },
  alcohol: { de: 'Alkoholgehalt', en: 'Alcohol Content' },
  serving: { de: 'Trinktemperatur', en: 'Serving Temperature' },
  tasting: { de: 'Verkostungsnotizen', en: 'Tasting Notes' },
  foodPairing: { de: 'Speiseempfehlung', en: 'Food Pairing' },
  allergens: { de: 'Allergene', en: 'Allergens' },
  pairings: { de: 'Passt dazu', en: 'Pairs well with' },
  prices: { de: 'Preise', en: 'Prices' },
};

export default async function ItemDetailPage({
  params,
  searchParams,
}: {
  params: { tenant: string; location: string; menu: string; itemId: string };
  searchParams: { lang?: string };
}) {
  const lang = searchParams.lang === 'en' ? 'en' : 'de';
  const t = (translations: any[], field: string = 'name') => {
    const found = translations.find((tr: any) => tr.languageCode === lang);
    const fb = translations.find((tr: any) => tr.languageCode === 'de');
    return (found?.[field] || fb?.[field]) ?? '';
  };

  const tenant = await prisma.tenant.findUnique({ where: { slug: params.tenant, isActive: true } });
  if (!tenant) return notFound();
  const location = await prisma.location.findUnique({ where: { tenantId_slug: { tenantId: tenant.id, slug: params.location } } });
  if (!location) return notFound();

  const item = await prisma.menuItem.findUnique({
    where: { id: params.itemId },
    include: {
      translations: true,
      priceVariants: { orderBy: { sortOrder: 'asc' } },
      allergens: { include: { allergen: { include: { translations: true } } } },
      tags: { include: { tag: { include: { translations: true } } } },
      wineProfile: true,
      beverageDetail: true,
      media: { include: { media: true }, orderBy: { sortOrder: 'asc' } },
      pairings: { include: { targetItem: { include: { translations: true, priceVariants: { where: { isDefault: true }, take: 1 } } } } },
      section: { include: { menu: { include: { translations: true } } } },
    },
  });
  if (!item) return notFound();
  if (item.section.menu.locationId !== location.id) return notFound();

  const theme = await prisma.theme.findFirst({ where: { tenantId: tenant.id, isActive: true } });
  const accentColor = theme?.accentColor || '#8B6914';
  const langParam = lang === 'en' ? '?lang=en' : '';
  const priceLocale = lang === 'en' ? 'en-GB' : 'de-AT';

  const iName = t(item.translations);
  const iShort = t(item.translations, 'shortDescription');
  const iLong = t(item.translations, 'longDescription');
  const iServing = t(item.translations, 'servingSuggestion');
  const menuName = t(item.section.menu.translations);
  const wp = item.wineProfile;

  return (
    <div className="min-h-screen pb-16" style={{ background: theme?.backgroundColor || '#FAFAF8', color: theme?.textColor || '#1a1a1a' }}>
      {/* Back Navigation */}
      <header className="border-b px-4 py-4">
        <Link
          href={`/${params.tenant}/${params.location}/${params.menu}${langParam}#${item.section.slug}`}
          className="inline-flex items-center gap-2 text-sm opacity-60 hover:opacity-100 transition-opacity"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m15 18-6-6 6-6"/></svg>
          {ui.back[lang]}
        </Link>
        <p className="mt-1 text-xs opacity-30">{menuName}</p>
      </header>

      <main className="mx-auto max-w-2xl px-4 py-6">
        {/* Title & Badges */}
        <div className="mb-6">
          <div className="flex items-center gap-3 flex-wrap">
            <h1 className="text-2xl font-bold tracking-tight" style={{fontFamily: "'Playfair Display', serif"}}>{iName}</h1>
            {item.isHighlight && item.highlightType && (
              <span className="rounded-full px-3 py-1 text-xs font-semibold text-white" style={{backgroundColor: accentColor}}>{hlLabels[item.highlightType]?.[lang] || ''}</span>
            )}
            {item.isSoldOut && <span className="rounded-full bg-red-100 px-3 py-1 text-xs font-medium text-red-600">{ui.soldOut[lang]}</span>}
          </div>
          {iShort && <p className="mt-2 text-base opacity-70">{iShort}</p>}
        </div>

        {/* Long Description */}
        {iLong && (
          <div className="mb-6 rounded-xl border bg-white p-5 shadow-sm">
            <p className="text-sm leading-relaxed opacity-80 whitespace-pre-line">{iLong}</p>
          </div>
        )}

        {/* Serving Suggestion */}
        {iServing && (
          <div className="mb-6 rounded-xl border bg-white p-5 shadow-sm">
            <p className="text-sm italic opacity-60">{iServing}</p>
          </div>
        )}

        {/* Prices */}
        {item.priceVariants.length > 0 && (
          <div className="mb-6 rounded-xl border bg-white p-5 shadow-sm">
            <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider opacity-40">{ui.prices[lang]}</h2>
            <div className="space-y-2">
              {item.priceVariants.map(pv => (
                <div key={pv.id} className="flex items-baseline justify-between">
                  <span className="text-sm opacity-60">{pv.label || pv.volume || ''}</span>
                  <span className="text-lg font-bold tabular-nums" style={{fontFamily: "'Playfair Display', serif"}}>{formatPrice(Number(pv.price), 'EUR', priceLocale)}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Wine Profile */}
        {wp && (
          <div className="mb-6 rounded-xl border bg-white p-5 shadow-sm">
            <h2 className="mb-4 text-sm font-semibold uppercase tracking-wider opacity-40">{lang === 'en' ? 'Wine Profile' : 'Weinprofil'}</h2>
            <div className="grid grid-cols-2 gap-3">
              {wp.winery && (
                <div>
                  <p className="text-[10px] uppercase tracking-wider opacity-40">{ui.winery[lang]}</p>
                  <p className="text-sm font-medium">{wp.winery}</p>
                </div>
              )}
              {wp.vintage && (
                <div>
                  <p className="text-[10px] uppercase tracking-wider opacity-40">{ui.vintage[lang]}</p>
                  <p className="text-sm font-medium">{wp.vintage}</p>
                </div>
              )}
              {wp.grapeVarieties && wp.grapeVarieties.length > 0 && (
                <div className="col-span-2">
                  <p className="text-[10px] uppercase tracking-wider opacity-40">{ui.grapes[lang]}</p>
                  <p className="text-sm font-medium">{wp.grapeVarieties.join(', ')}</p>
                </div>
              )}
              {wp.region && (
                <div>
                  <p className="text-[10px] uppercase tracking-wider opacity-40">{ui.region[lang]}</p>
                  <p className="text-sm font-medium">{wp.region}</p>
                </div>
              )}
              {wp.country && (
                <div>
                  <p className="text-[10px] uppercase tracking-wider opacity-40">{ui.country[lang]}</p>
                  <p className="text-sm font-medium">{wp.country}</p>
                </div>
              )}
              {wp.appellation && (
                <div className="col-span-2">
                  <p className="text-[10px] uppercase tracking-wider opacity-40">{ui.appellation[lang]}</p>
                  <p className="text-sm font-medium">{wp.appellation}</p>
                </div>
              )}
              {wp.style && (
                <div>
                  <p className="text-[10px] uppercase tracking-wider opacity-40">{ui.style[lang]}</p>
                  <p className="text-sm font-medium">{styleLabels[wp.style]?.[lang] || wp.style}</p>
                </div>
              )}
              {wp.body && (
                <div>
                  <p className="text-[10px] uppercase tracking-wider opacity-40">{ui.body[lang]}</p>
                  <p className="text-sm font-medium">{bodyLabels[wp.body]?.[lang] || wp.body}</p>
                </div>
              )}
              {wp.sweetness && (
                <div>
                  <p className="text-[10px] uppercase tracking-wider opacity-40">{ui.sweetness[lang]}</p>
                  <p className="text-sm font-medium">{sweetnessLabels[wp.sweetness]?.[lang] || wp.sweetness}</p>
                </div>
              )}
              {wp.bottleSize && (
                <div>
                  <p className="text-[10px] uppercase tracking-wider opacity-40">{ui.bottleSize[lang]}</p>
                  <p className="text-sm font-medium">{wp.bottleSize}</p>
                </div>
              )}
              {wp.alcoholContent && (
                <div>
                  <p className="text-[10px] uppercase tracking-wider opacity-40">{ui.alcohol[lang]}</p>
                  <p className="text-sm font-medium">{wp.alcoholContent}% vol.</p>
                </div>
              )}
              {wp.servingTemp && (
                <div>
                  <p className="text-[10px] uppercase tracking-wider opacity-40">{ui.serving[lang]}</p>
                  <p className="text-sm font-medium">{wp.servingTemp}</p>
                </div>
              )}
            </div>
            {wp.tastingNotes && (
              <div className="mt-4 border-t pt-4">
                <p className="text-[10px] uppercase tracking-wider opacity-40">{ui.tasting[lang]}</p>
                <p className="mt-1 text-sm leading-relaxed opacity-70">{wp.tastingNotes}</p>
              </div>
            )}
            {wp.foodPairing && (
              <div className="mt-4 border-t pt-4">
                <p className="text-[10px] uppercase tracking-wider opacity-40">{ui.foodPairing[lang]}</p>
                <p className="mt-1 text-sm leading-relaxed opacity-70">{wp.foodPairing}</p>
              </div>
            )}
          </div>
        )}

        {/* Allergens */}
        {item.allergens.length > 0 && (
          <div className="mb-6 rounded-xl border bg-white p-5 shadow-sm">
            <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider opacity-40">{ui.allergens[lang]}</h2>
            <div className="flex flex-wrap gap-2">
              {item.allergens.map(a => (
                <span key={a.allergen.id} className="rounded-lg bg-amber-50 px-3 py-1.5 text-xs font-medium text-amber-800">
                  {a.allergen.icon && <span className="mr-1">{a.allergen.icon}</span>}
                  {t(a.allergen.translations)}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Tags */}
        {item.tags.length > 0 && (
          <div className="mb-6 flex flex-wrap gap-2">
            {item.tags.map(tg => (
              <span key={tg.tag.id} className="rounded-full border px-3 py-1.5 text-xs font-medium" style={{borderColor: tg.tag.color || '#e5e7eb', color: tg.tag.color || '#6b7280'}}>
                {tg.tag.icon && <span className="mr-1">{tg.tag.icon}</span>}
                {t(tg.tag.translations)}
              </span>
            ))}
          </div>
        )}

        {/* Pairings */}
        {item.pairings.length > 0 && (
          <div className="mb-6 rounded-xl border bg-white p-5 shadow-sm">
            <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider opacity-40">{ui.pairings[lang]}</h2>
            <div className="space-y-2">
              {item.pairings.map(p => {
                const pName = t(p.targetItem.translations);
                const pPrice = p.targetItem.priceVariants[0];
                return (
                  <Link key={p.id} href={`/${params.tenant}/${params.location}/${params.menu}/item/${p.targetItemId}${langParam}`} className="flex items-baseline justify-between rounded-lg p-2 hover:bg-black/5 transition-colors">
                    <span className="text-sm font-medium">{pName}</span>
                    {pPrice && <span className="text-sm tabular-nums opacity-60">{formatPrice(Number(pPrice.price), 'EUR', priceLocale)}</span>}
                  </Link>
                );
              })}
            </div>
          </div>
        )}
      </main>

      <Suspense fallback={null}>
        <LanguageSwitcher />
      </Suspense>
    </div>
  );
}
ENDFILE

# === FILE 2: Updated Menu Page (items now clickable) ===
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
  const t = (translations: any[], field: string = 'name') => {
    const found = translations.find((tr: any) => tr.languageCode === lang);
    const fb = translations.find((tr: any) => tr.languageCode === 'de');
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
  const accentColor = theme?.accentColor || '#8B6914';

  const hasDetail = (item: any) => {
    const longDesc = t(item.translations, 'longDescription');
    return !!(longDesc || item.wineProfile || item.allergens.length > 0);
  };

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
                <div className="mx-auto mt-3 h-px w-16" style={{backgroundColor: accentColor + '40'}} />
              </div>
              <div className="space-y-2">
                {section.items.map(item => {
                  const iName = t(item.translations);
                  const iDesc = t(item.translations, 'shortDescription');
                  const defPrice = item.priceVariants.find(p => p.isDefault) || item.priceVariants[0];
                  const multiPrice = item.priceVariants.length > 1;
                  const clickable = hasDetail(item);
                  const Wrapper = clickable ? Link : 'div';
                  const wrapperProps = clickable ? { href: `/${tenant.slug}/${location.slug}/${menu.slug}/item/${item.id}${langParam}` } : {};
                  return (
                    <Wrapper key={item.id} {...wrapperProps as any} className={`block rounded-xl border bg-white p-4 shadow-sm transition-all ${item.isSoldOut ? 'opacity-50' : ''} ${clickable ? 'hover:shadow-md hover:border-gray-300 cursor-pointer' : ''}`}>
                      <div className="flex items-start justify-between gap-3">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 flex-wrap">
                            <h3 className="text-base font-semibold" style={{fontFamily: "'Playfair Display', serif"}}>{iName}</h3>
                            {item.isHighlight && item.highlightType && (
                              <span className="rounded-full px-2 py-0.5 text-[10px] font-semibold text-white" style={{backgroundColor: accentColor}}>{hlLabels[item.highlightType]?.[lang] || ''}</span>
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
                          {item.tags.length > 0 && (
                            <div className="mt-2 flex flex-wrap gap-1">
                              {item.tags.map(tg => (
                                <span key={tg.tag.id} className="rounded-full bg-gray-100 px-2 py-0.5 text-[10px] font-medium">{tg.tag.icon} {t(tg.tag.translations)}</span>
                              ))}
                            </div>
                          )}
                        </div>
                        {clickable && (
                          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="mt-1 flex-shrink-0 opacity-20"><path d="m9 18 6-6-6-6"/></svg>
                        )}
                      </div>
                      <div className="mt-3 flex flex-wrap items-baseline gap-3">
                        {multiPrice ? item.priceVariants.map(pv => (
                          <div key={pv.id} className="text-sm">
                            <span className="font-semibold tabular-nums">{formatPrice(Number(pv.price), 'EUR', priceLocale)}</span>
                            {(pv.label || pv.volume) && <span className="ml-1 text-xs opacity-40">{pv.label || pv.volume}</span>}
                          </div>
                        )) : defPrice && <span className="text-sm font-semibold tabular-nums">{formatPrice(Number(defPrice.price), 'EUR', priceLocale)}</span>}
                      </div>
                    </Wrapper>
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
echo "=== Item Detail Page deployed! ==="
echo "Items mit longDescription oder WineProfile sind jetzt klickbar."
echo "Test: http://178.104.138.177/hotel-sonnblick/restaurant/weinkarte"
