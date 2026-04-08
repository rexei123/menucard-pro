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
  WHITE: { de: 'Weißwein', en: 'White Wine' },
  ROSE: { de: 'Rosé', en: 'Rosé' },
  SPARKLING: { de: 'Schaumwein', en: 'Sparkling Wine' },
  DESSERT: { de: 'Dessertwein', en: 'Dessert Wine' },
  FORTIFIED: { de: 'Likörwein', en: 'Fortified Wine' },
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
  SWEET: { de: 'Süß', en: 'Sweet' },
};

const ui: Record<string, Record<string, string>> = {
  back: { de: 'Zurück zur Karte', en: 'Back to menu' },
  soldOut: { de: 'Ausverkauft', en: 'Sold out' },
  winery: { de: 'Weingut', en: 'Winery' },
  vintage: { de: 'Jahrgang', en: 'Vintage' },
  grapes: { de: 'Rebsorten', en: 'Grape Varieties' },
  region: { de: 'Region', en: 'Region' },
  country: { de: 'Land', en: 'Country' },
  appellation: { de: 'Appellation', en: 'Appellation' },
  style: { de: 'Stil', en: 'Style' },
  body: { de: 'Körper', en: 'Body' },
  sweetness: { de: 'Süße', en: 'Sweetness' },
  bottleSize: { de: 'Flaschengröße', en: 'Bottle Size' },
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
