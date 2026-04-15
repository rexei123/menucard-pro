import { notFound } from 'next/navigation';
import { Suspense } from 'react';
import prisma from '@/lib/prisma';
import Link from 'next/link';
import { formatPrice } from '@/lib/utils';
import LanguageSwitcher from '@/components/language-switcher';
import { resolveMenuDigitalConfig, configToCssVars } from '@/lib/template-resolver';

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
  MEDIUM_LIGHT: { de: 'Leicht bis Mittel', en: 'Light to Medium' },
  MEDIUM: { de: 'Mittel', en: 'Medium' },
  MEDIUM_FULL: { de: 'Mittel bis Voll', en: 'Medium to Full' },
  FULL: { de: 'Vollmundig', en: 'Full-Bodied' },
};

const sweetnessLabels: Record<string, Record<string, string>> = {
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
  wineProfile: { de: 'Weinprofil', en: 'Wine Profile' },
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

  // Find product
  const product = await prisma.product.findUnique({
    where: { id: params.itemId },
    include: {
      translations: true,
      prices: { include: { fillQuantity: true }, orderBy: { sortOrder: 'asc' } },
      productAllergens: { include: { allergen: { include: { translations: true } } } },
      productTags: { include: { tag: { include: { translations: true } } } },
      productWineProfile: true,
      productBevDetail: true,
      productMedia: { include: { media: true }, orderBy: { sortOrder: 'asc' } },
      pairingsFrom: { include: { target: { include: { translations: true, prices: { where: { isDefault: true }, take: 1, include: { fillQuantity: true } } } } } },
    },
  });
  if (!product) return notFound();

  // Find the section this product is placed in for the current menu
  // Runde 4: `template` zusaetzlich mitladen, damit die Item-Seite die
  // richtige Template-Font erhaelt (Modern=Montserrat, Minimal=Space Grotesk etc.)
  const menu = await prisma.menu.findUnique({
    where: { locationId_slug: { locationId: location.id, slug: params.menu } },
    include: { translations: true, template: true },
  });
  if (!menu) return notFound();

  const placement = await prisma.menuPlacement.findFirst({
    where: { product: { id: product.id }, menuSection: { menuId: menu.id } },
    include: { menuSection: true },
  });
  const sectionSlug = placement?.menuSection?.slug || '';

  const theme = await prisma.theme.findFirst({ where: { tenantId: tenant.id, isActive: true } });
  const accentColor = theme?.accentColor || '#8B6914';
  const langParam = lang === 'en' ? '?lang=en' : '';
  const priceLocale = lang === 'en' ? 'en-GB' : 'de-AT';

  // Runde 4: Template-spezifische Font-Klasse + CSS-Vars herleiten
  const digitalConfig = resolveMenuDigitalConfig(menu as any);
  const cssVars = configToCssVars(digitalConfig);
  const templateKey = (menu as any).template?.baseType || digitalConfig.template || 'elegant';

  const pName = t(product.translations);
  const pShort = t(product.translations, 'shortDescription');
  const pLong = t(product.translations, 'longDescription');
  const pServing = t(product.translations, 'servingSuggestion');
  const menuName = t(menu.translations);
  const wp = product.productWineProfile;

  return (
    <div
      className={`mc-template-root mc-template-${templateKey} min-h-screen pb-16`}
      style={{
        ...(cssVars as any),
        background: digitalConfig.colors?.pageBackground || theme?.backgroundColor || '#FAFAF8',
        color: theme?.textColor || '#1a1a1a',
        fontFamily: 'var(--mc-body-font, inherit)',
      }}
    >
      <header className="border-b px-4 py-4">
        <Link
          href={`/${params.tenant}/${params.location}/${params.menu}${langParam}${sectionSlug ? '#' + sectionSlug : ''}`}
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
            <h1 className="text-2xl font-bold tracking-tight" style={{ fontFamily: 'var(--mc-h1-font, inherit)' }}>{pName}</h1>
            {product.isHighlight && product.highlightType && (
              <span className="rounded-full px-3 py-1 text-xs font-semibold text-white" style={{backgroundColor: accentColor}}>{hlLabels[product.highlightType]?.[lang] || ''}</span>
            )}
            {product.status === 'SOLD_OUT' && <span className="rounded-full bg-red-100 px-3 py-1 text-xs font-medium text-red-600">{ui.soldOut[lang]}</span>}
          </div>
          {pShort && <p className="mt-2 text-base opacity-70">{pShort}</p>}
        </div>

        {/* Product Image */}
        {product.productMedia && product.productMedia.length > 0 && (
          <div className="mb-6 flex justify-center">
            <img
              src={product.productMedia[0].url?.replace('/uploads/large/', '/uploads/medium/') || product.productMedia[0].url || ''}
              alt={pName}
              className="max-h-80 rounded-xl object-contain"
              loading="lazy"
            />
          </div>
        )}

        {/* Long Description */}
        {pLong && (
          <div className="mb-6 rounded-xl border bg-white p-5 shadow-sm">
            <p className="text-sm leading-relaxed opacity-80 whitespace-pre-line">{pLong}</p>
          </div>
        )}

        {/* Serving Suggestion */}
        {pServing && (
          <div className="mb-6 rounded-xl border bg-white p-5 shadow-sm">
            <p className="text-sm italic opacity-60">{pServing}</p>
          </div>
        )}

        {/* Prices */}
        {product.prices.length > 0 && (
          <div className="mb-6 rounded-xl border bg-white p-5 shadow-sm">
            <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider opacity-40">{ui.prices[lang]}</h2>
            <div className="space-y-2">
              {product.prices.map(pp => (
                <div key={pp.id} className="flex items-baseline justify-between">
                  <span className="text-sm opacity-60">{pp.fillQuantity.label}</span>
                  <span className="text-lg font-bold tabular-nums" style={{ fontFamily: 'var(--mc-price-font, inherit)' }}>{formatPrice(Number(pp.price), 'EUR', priceLocale)}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Wine Profile */}
        {wp && (
          <div className="mb-6 rounded-xl border bg-white p-5 shadow-sm">
            <h2 className="mb-4 text-sm font-semibold uppercase tracking-wider opacity-40">{ui.wineProfile[lang]}</h2>
            <div className="grid grid-cols-2 gap-3">
              {wp.winery && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.winery[lang]}</p><p className="text-sm font-medium">{wp.winery}</p></div>}
              {wp.vintage && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.vintage[lang]}</p><p className="text-sm font-medium">{wp.vintage}</p></div>}
              {wp.grapeVarieties && wp.grapeVarieties.length > 0 && <div className="col-span-2"><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.grapes[lang]}</p><p className="text-sm font-medium">{wp.grapeVarieties.join(', ')}</p></div>}
              {wp.region && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.region[lang]}</p><p className="text-sm font-medium">{wp.region}</p></div>}
              {wp.country && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.country[lang]}</p><p className="text-sm font-medium">{wp.country}</p></div>}
              {wp.appellation && <div className="col-span-2"><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.appellation[lang]}</p><p className="text-sm font-medium">{wp.appellation}</p></div>}
              {wp.style && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.style[lang]}</p><p className="text-sm font-medium">{styleLabels[wp.style]?.[lang] || wp.style}</p></div>}
              {wp.body && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.body[lang]}</p><p className="text-sm font-medium">{bodyLabels[wp.body]?.[lang] || wp.body}</p></div>}
              {wp.sweetness && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.sweetness[lang]}</p><p className="text-sm font-medium">{sweetnessLabels[wp.sweetness]?.[lang] || wp.sweetness}</p></div>}
              {wp.bottleSize && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.bottleSize[lang]}</p><p className="text-sm font-medium">{wp.bottleSize}</p></div>}
              {wp.alcoholContent && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.alcohol[lang]}</p><p className="text-sm font-medium">{wp.alcoholContent}% vol.</p></div>}
              {wp.servingTemp && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.serving[lang]}</p><p className="text-sm font-medium">{wp.servingTemp}</p></div>}
            </div>
            {wp.tastingNotes && <div className="mt-4 border-t pt-4"><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.tasting[lang]}</p><p className="mt-1 text-sm leading-relaxed opacity-70">{wp.tastingNotes}</p></div>}
            {wp.foodPairing && <div className="mt-4 border-t pt-4"><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.foodPairing[lang]}</p><p className="mt-1 text-sm leading-relaxed opacity-70">{wp.foodPairing}</p></div>}
          </div>
        )}

        {/* Allergens */}
        {product.productAllergens.length > 0 && (
          <div className="mb-6 rounded-xl border bg-white p-5 shadow-sm">
            <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider opacity-40">{ui.allergens[lang]}</h2>
            <div className="flex flex-wrap gap-2">
              {product.productAllergens.map(a => (
                <span key={a.allergen.id} className="rounded-lg bg-amber-50 px-3 py-1.5 text-xs font-medium text-amber-800">
                  {a.allergen.icon && <span className="mr-1">{a.allergen.icon}</span>}
                  {t(a.allergen.translations)}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Tags */}
        {product.productTags.length > 0 && (
          <div className="mb-6 flex flex-wrap gap-2">
            {product.productTags.map(tg => (
              <span key={tg.tag.id} className="rounded-full border px-3 py-1.5 text-xs font-medium" style={{borderColor: tg.tag.color || '#e5e7eb', color: tg.tag.color || '#6b7280'}}>
                {tg.tag.icon && <span className="mr-1">{tg.tag.icon}</span>}
                {t(tg.tag.translations)}
              </span>
            ))}
          </div>
        )}

        {/* Pairings */}
        {product.pairingsFrom.length > 0 && (
          <div className="mb-6 rounded-xl border bg-white p-5 shadow-sm">
            <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider opacity-40">{ui.pairings[lang]}</h2>
            <div className="space-y-2">
              {product.pairingsFrom.map(p => {
                const tName = t(p.target.translations);
                const tPrice = p.target.prices[0];
                return (
                  <Link key={p.id} href={`/${params.tenant}/${params.location}/${params.menu}/item/${p.targetId}${langParam}`} className="flex items-baseline justify-between rounded-lg p-2 hover:bg-black/5 transition-colors">
                    <span className="text-sm font-medium">{tName}</span>
                    {tPrice && <span className="text-sm tabular-nums opacity-60">{formatPrice(Number(tPrice.price), 'EUR', priceLocale)}</span>}
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
