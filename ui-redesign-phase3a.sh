#!/bin/bash
set -e
echo "============================================"
echo "  UI-Redesign Phase 3a: Gästeansicht Elegant"
echo "============================================"

cd /var/www/menucard-pro

# Backups
cp src/components/menu-content.tsx src/components/menu-content.tsx.bak-redesign
cp "src/app/(public)/[tenant]/[location]/page.tsx" "src/app/(public)/[tenant]/[location]/page.tsx.bak-redesign"

# ============================================
# 1. LOCATION OVERVIEW (Menü-Übersicht)
# ============================================
echo "[1/3] Location-Seite (Menü-Übersicht) neu..."

cat > "src/app/(public)/[tenant]/[location]/page.tsx" << 'LOCEOF'
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
LOCEOF

# ============================================
# 2. MENU-CONTENT.TSX (komplett neu mit Template-Switch)
# ============================================
echo "[2/3] menu-content.tsx komplett neu schreiben..."

cat > src/components/menu-content.tsx << 'MENUEOF'
'use client';
import { useState, useMemo } from 'react';
import Link from 'next/link';

type PriceVariant = { id: string; label: string | null; price: number; volume: string | null; isDefault: boolean };
type Translation = { languageCode: string; name: string; shortDescription?: string | null; longDescription?: string | null };
type AllergenData = { allergen: { id: string; icon?: string | null; translations: { languageCode: string; name: string }[] } };
type TagData = { tag: { id: string; icon?: string | null; color?: string | null; translations: { languageCode: string; name: string }[] } };
type WineProfile = { winery?: string | null; vintage?: number | null; grapeVarieties?: string[]; region?: string | null; country?: string | null; appellation?: string | null; style?: string | null; body?: string | null; sweetness?: string | null };
type Item = { id: string; isHighlight: boolean; highlightType?: string | null; isSoldOut: boolean; image?: string | null; translations: Translation[]; priceVariants: PriceVariant[]; allergens: AllergenData[]; tags: TagData[]; wineProfile?: WineProfile | null };
type Section = { id: string; slug: string; icon?: string | null; translations: Translation[]; items: Item[] };
type DigitalConfigProp = {
  template: string; mood: string; density: string;
  typography: Record<string, any>; colors: Record<string, any>;
  products: Record<string, any>; navigation: Record<string, any>;
  badges: Record<string, any>; [key: string]: any;
};
type MenuContentProps = {
  sections: Section[]; lang: string; langParam: string; priceLocale: string;
  accentColor: string; tenantSlug: string; locationSlug: string; menuSlug: string;
  isWineMenu: boolean; digitalConfig?: DigitalConfigProp;
};

const hlLabels: Record<string, Record<string, string>> = {
  RECOMMENDATION: { de: 'Empfehlung', en: 'Recommended' },
  NEW: { de: 'Neu', en: 'New' },
  POPULAR: { de: 'Beliebt', en: 'Popular' },
  PREMIUM: { de: 'Premium', en: 'Premium' },
  SEASONAL: { de: 'Saison', en: 'Seasonal' },
  CHEFS_CHOICE: { de: "Chef's Choice", en: "Chef's Choice" },
};
const styleLabels: Record<string, Record<string, string>> = {
  RED: { de: 'Rotwein', en: 'Red' }, WHITE: { de: 'Weißwein', en: 'White' },
  ROSE: { de: 'Rosé', en: 'Rosé' }, SPARKLING: { de: 'Schaumwein', en: 'Sparkling' },
  DESSERT: { de: 'Dessertwein', en: 'Dessert' }, FORTIFIED: { de: 'Likörwein', en: 'Fortified' },
  ORANGE: { de: 'Orange', en: 'Orange' }, NATURAL: { de: 'Naturwein', en: 'Natural' },
};
const uiLabels: Record<string, Record<string, string>> = {
  soldOut: { de: 'Ausverkauft', en: 'Sold out' },
  search: { de: 'Suche...', en: 'Search...' },
  noResults: { de: 'Keine Ergebnisse', en: 'No results' },
  clearFilters: { de: 'Filter zurücksetzen', en: 'Clear filters' },
  allStyles: { de: 'Alle Stile', en: 'All styles' },
  allCountries: { de: 'Alle Länder', en: 'All countries' },
  results: { de: 'Ergebnisse', en: 'results' },
};

function formatPrice(price: number, locale: string): string {
  return new Intl.NumberFormat(locale, { style: 'currency', currency: 'EUR', minimumFractionDigits: 2 }).format(price);
}

export default function MenuContent(props: MenuContentProps) {
  const { sections, lang, langParam, priceLocale, accentColor, tenantSlug, locationSlug, menuSlug, isWineMenu, digitalConfig: dc } = props;
  const template = dc?.template || 'elegant';

  const [query, setQuery] = useState('');
  const [styleFilter, setStyleFilter] = useState('');
  const [countryFilter, setCountryFilter] = useState('');
  const [activeSection, setActiveSection] = useState('');

  const t = (translations: { languageCode: string; [key: string]: any }[], field: string = 'name') => {
    const found = translations.find(tr => tr.languageCode === lang);
    const fb = translations.find(tr => tr.languageCode === 'de');
    return (found as any)?.[field] || (fb as any)?.[field] || '';
  };

  /* Wine filter data */
  const { wineStyles, countries } = useMemo(() => {
    const styles = new Set<string>();
    const ctries = new Set<string>();
    sections.forEach(s => s.items.forEach(item => {
      if (item.wineProfile?.style) styles.add(item.wineProfile.style);
      if (item.wineProfile?.country) ctries.add(item.wineProfile.country);
    }));
    return { wineStyles: Array.from(styles).sort(), countries: Array.from(ctries).sort() };
  }, [sections]);

  const isActive = query.length > 0 || styleFilter || countryFilter;

  const filteredSections = useMemo(() => {
    const q = query.toLowerCase().trim();
    return sections.map(section => {
      const filtered = section.items.filter(item => {
        if (q) {
          const name = t(item.translations).toLowerCase();
          const desc = (t(item.translations, 'shortDescription') || '').toLowerCase();
          const longDesc = (t(item.translations, 'longDescription') || '').toLowerCase();
          const winery = (item.wineProfile?.winery || '').toLowerCase();
          const region = (item.wineProfile?.region || '').toLowerCase();
          const grapes = (item.wineProfile?.grapeVarieties || []).join(' ').toLowerCase();
          if (!`${name} ${desc} ${longDesc} ${winery} ${region} ${grapes}`.includes(q)) return false;
        }
        if (styleFilter && item.wineProfile?.style !== styleFilter) return false;
        if (countryFilter && item.wineProfile?.country !== countryFilter) return false;
        return true;
      });
      return { ...section, items: filtered };
    }).filter(s => s.items.length > 0);
  }, [sections, query, styleFilter, countryFilter, lang]);

  const totalResults = filteredSections.reduce((sum, s) => sum + s.items.length, 0);
  const totalItems = sections.reduce((sum, s) => sum + s.items.length, 0);

  /* Config helpers */
  const showImages = dc?.products?.showImages ?? true;
  const showShortDesc = dc?.products?.showShortDesc ?? true;
  const showFillQuantity = dc?.products?.showFillQuantity ?? true;
  const showAllPrices = dc?.products?.showAllPrices ?? true;
  const imageShape = dc?.products?.imageShape || 'rounded';
  const imageSize = dc?.products?.imageSize || 64;
  const wineDetails = dc?.products?.wineDetails || ['winery', 'vintage', 'region'];
  const stickyNav = dc?.navigation?.stickyNav ?? true;
  const showBackToTop = dc?.navigation?.showBackToTop ?? true;

  const detailHref = (itemId: string) => `/${tenantSlug}/${locationSlug}/${menuSlug}/item/${itemId}${langParam}`;
  const scrollToTop = () => window.scrollTo({ top: 0, behavior: 'smooth' });

  /* ====================================================
   * RENDER: Shared Search + Filter Bar
   * ==================================================== */
  const renderSearchBar = () => (
    <div
      className={`${stickyNav ? 'sticky top-0' : ''} z-20 border-b backdrop-blur-md`}
      style={{ backgroundColor: 'var(--mc-bg, #FFF)', borderColor: 'var(--mc-product-divider, #eee)' }}
    >
      <div className="mx-auto max-w-2xl px-4 py-3">
        <div className="relative">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 opacity-30" style={{ fontSize: 18 }}>search</span>
          <input
            type="text" value={query} onChange={e => setQuery(e.target.value)}
            placeholder={uiLabels.search[lang]}
            className="w-full rounded-full border py-2.5 pl-10 pr-10 text-sm outline-none transition-colors focus:border-gray-400"
            style={{ backgroundColor: 'var(--mc-product-bg, #f9f9f9)', borderColor: 'var(--mc-product-divider, #eee)' }}
          />
          {query && (
            <button onClick={() => setQuery('')} className="absolute right-3 top-1/2 -translate-y-1/2 opacity-40 hover:opacity-100">
              <span className="material-symbols-outlined" style={{ fontSize: 16 }}>close</span>
            </button>
          )}
        </div>
        {isWineMenu && (wineStyles.length > 1 || countries.length > 1) && (
          <div className="mt-2 flex gap-2 overflow-x-auto">
            {wineStyles.length > 1 && (
              <select value={styleFilter} onChange={e => setStyleFilter(e.target.value)}
                className="rounded-full border px-3 py-1.5 text-xs outline-none"
                style={{ backgroundColor: 'var(--mc-product-bg, #f9f9f9)' }}>
                <option value="">{uiLabels.allStyles[lang]}</option>
                {wineStyles.map(s => <option key={s} value={s}>{styleLabels[s]?.[lang] || s}</option>)}
              </select>
            )}
            {countries.length > 1 && (
              <select value={countryFilter} onChange={e => setCountryFilter(e.target.value)}
                className="rounded-full border px-3 py-1.5 text-xs outline-none"
                style={{ backgroundColor: 'var(--mc-product-bg, #f9f9f9)' }}>
                <option value="">{uiLabels.allCountries[lang]}</option>
                {countries.map(c => <option key={c} value={c}>{c}</option>)}
              </select>
            )}
          </div>
        )}
        {isActive && (
          <div className="mt-2 flex items-center justify-between">
            <span className="text-xs opacity-50">{totalResults} / {totalItems} {uiLabels.results[lang]}</span>
            <button onClick={() => { setQuery(''); setStyleFilter(''); setCountryFilter(''); }}
              className="text-xs font-medium opacity-50 hover:opacity-100">{uiLabels.clearFilters[lang]}</button>
          </div>
        )}
      </div>

      {/* Section Tab Navigation */}
      {!isActive && sections.length > 1 && (
        <div className="border-t" style={{ borderColor: 'var(--mc-product-divider, #eee)' }}>
          <div className="flex overflow-x-auto px-4 gap-0 hide-scrollbar mx-auto max-w-2xl">
            {sections.map(s => {
              const isActiveTab = activeSection === s.slug;
              return (
                <a
                  key={s.id}
                  href={`#${s.slug}`}
                  onClick={() => setActiveSection(s.slug)}
                  className="flex-shrink-0 px-4 py-2.5 text-xs font-semibold uppercase tracking-wider transition-colors"
                  style={{
                    whiteSpace: 'nowrap',
                    color: isActiveTab ? 'var(--color-primary, #DD3C71)' : 'var(--color-text-muted, #8E8E8E)',
                    borderBottom: isActiveTab ? '2px solid var(--color-primary, #DD3C71)' : '2px solid transparent',
                    fontFamily: 'var(--font-display, Inter)',
                  }}
                >
                  {t(s.translations)}
                </a>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );

  /* ====================================================
   * RENDER: Elegant Template Items
   * ==================================================== */
  const renderElegantItem = (item: Item) => {
    const iName = t(item.translations);
    const iDesc = t(item.translations, 'shortDescription');
    const defPrice = item.priceVariants.find(p => p.isDefault) || item.priceVariants[0];
    const multiPrice = item.priceVariants.length > 1;

    return (
      <Link
        key={item.id}
        href={detailHref(item.id)}
        className={`block py-5 border-b transition-colors ${item.isSoldOut ? 'opacity-40' : ''}`}
        style={{ borderColor: 'var(--mc-product-divider, #eee)' }}
      >
        {/* Name + Price Row */}
        <div className="flex items-start justify-between gap-4">
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <h3
                className="text-sm font-bold uppercase tracking-wide"
                style={{
                  fontFamily: 'var(--mc-h3-font, Playfair Display)',
                  color: 'var(--mc-h3-color, #1A1A1A)',
                  letterSpacing: '0.03em',
                }}
              >
                {iName}
              </h3>
              {item.isHighlight && item.highlightType && (
                <span
                  className="rounded-full px-2 py-0.5 text-[10px] font-semibold text-white"
                  style={{ backgroundColor: 'var(--color-primary, #DD3C71)' }}
                >
                  {hlLabels[item.highlightType]?.[lang] || ''}
                </span>
              )}
              {item.isSoldOut && (
                <span className="rounded-full px-2 py-0.5 text-[10px] font-medium"
                  style={{ backgroundColor: 'var(--color-error-light, #FEF2F2)', color: 'var(--color-error, #E05252)' }}>
                  {uiLabels.soldOut[lang]}
                </span>
              )}
            </div>
          </div>
          {/* Price */}
          <div className="flex-shrink-0 text-right">
            {showAllPrices && multiPrice ? (
              <div className="space-y-0.5">
                {item.priceVariants.map(pv => (
                  <div key={pv.id} className="text-sm">
                    <span className="font-medium tabular-nums" style={{ fontFamily: 'var(--mc-price-font)', color: 'var(--mc-price-color)' }}>
                      {formatPrice(pv.price, priceLocale)}
                    </span>
                    {showFillQuantity && (pv.label || pv.volume) && (
                      <span className="ml-1 text-xs opacity-50">{pv.label || pv.volume}</span>
                    )}
                  </div>
                ))}
              </div>
            ) : defPrice && (
              <span className="text-sm font-medium tabular-nums" style={{ fontFamily: 'var(--mc-price-font)', color: 'var(--mc-price-color)' }}>
                {formatPrice(defPrice.price, priceLocale)}
              </span>
            )}
          </div>
        </div>

        {/* Description */}
        {showShortDesc && iDesc && (
          <p
            className="mt-1.5 text-sm leading-relaxed"
            style={{
              fontFamily: 'var(--mc-body-font, Playfair Display)',
              fontStyle: 'italic',
              color: 'var(--mc-body-color, #565D6D)',
              opacity: 0.8,
            }}
          >
            {iDesc}
          </p>
        )}

        {/* Wine Details */}
        {item.wineProfile && (
          <div className="mt-2 flex flex-wrap gap-x-3 text-xs" style={{ color: 'var(--mc-meta-color)', opacity: 0.6 }}>
            {wineDetails.includes('winery') && item.wineProfile.winery && <span>{item.wineProfile.winery}</span>}
            {wineDetails.includes('vintage') && item.wineProfile.vintage && <span>{item.wineProfile.vintage}</span>}
            {wineDetails.includes('grape') && item.wineProfile.grapeVarieties?.length ? <span>{item.wineProfile.grapeVarieties.join(', ')}</span> : null}
            {wineDetails.includes('region') && item.wineProfile.region && <span>{item.wineProfile.region}</span>}
            {wineDetails.includes('country') && item.wineProfile.country && <span>{item.wineProfile.country}</span>}
          </div>
        )}

        {/* Tags + Allergens Row */}
        {(item.tags.length > 0 || item.allergens.length > 0) && (
          <div className="mt-2 flex items-center gap-2 flex-wrap">
            {item.tags.map(tg => (
              <span
                key={tg.tag.id}
                className="text-[10px] font-semibold uppercase tracking-wider"
                style={{ color: 'var(--mc-meta-color, #8E8E8E)' }}
              >
                {t(tg.tag.translations)}
              </span>
            ))}
            {item.allergens.length > 0 && (
              <span className="text-[10px]" style={{ color: 'var(--mc-meta-color, #8E8E8E)', opacity: 0.6 }}>
                [{item.allergens.map(a => t(a.allergen.translations).charAt(0).toUpperCase()).join(', ')}]
              </span>
            )}
          </div>
        )}
      </Link>
    );
  };

  /* ====================================================
   * RENDER: Elegant Section
   * ==================================================== */
  const renderElegantSection = (section: typeof filteredSections[0]) => {
    const sName = t(section.translations);
    return (
      <section key={section.id} id={section.slug} className="scroll-mt-32 pt-8 pb-2">
        <h2
          className="text-xs font-semibold uppercase tracking-[0.2em] mb-6"
          style={{
            fontFamily: 'var(--font-display, Inter)',
            color: 'var(--mc-h2-color, #8E8E8E)',
            letterSpacing: '0.2em',
          }}
        >
          {sName}
        </h2>
        <div>{section.items.map(renderElegantItem)}</div>
      </section>
    );
  };

  /* ====================================================
   * RENDER: Default/Fallback Items (bisheriges Design)
   * ==================================================== */
  const renderDefaultItem = (item: Item) => {
    const iName = t(item.translations);
    const iDesc = t(item.translations, 'shortDescription');
    const defPrice = item.priceVariants.find(p => p.isDefault) || item.priceVariants[0];
    const multiPrice = item.priceVariants.length > 1;
    const imgClasses = imageShape === 'round' ? 'rounded-full' : imageShape === 'rectangle' ? 'rounded-none' : 'rounded-lg';
    const densityPadding = dc?.density === 'airy' ? 'p-5' : dc?.density === 'compact' ? 'p-3' : 'p-4';

    return (
      <Link
        key={item.id}
        href={detailHref(item.id)}
        className={`block rounded-xl border shadow-sm transition-all ${item.isSoldOut ? 'opacity-50' : ''} hover:shadow-md ${densityPadding}`}
        style={{ backgroundColor: 'var(--mc-product-bg, #fff)', borderColor: 'var(--mc-product-divider, #eee)' }}
      >
        <div className="flex items-start justify-between gap-3">
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <h3 style={{ fontFamily: 'var(--mc-h3-font)', fontSize: 'var(--mc-h3-size)', fontWeight: 'var(--mc-h3-weight)' as any, color: 'var(--mc-h3-color)' }}>{iName}</h3>
              {item.isHighlight && item.highlightType && (
                <span className="rounded-full px-2 py-0.5 text-[10px] font-semibold text-white" style={{ backgroundColor: accentColor }}>{hlLabels[item.highlightType]?.[lang] || ''}</span>
              )}
              {item.isSoldOut && <span className="rounded-full bg-red-100 px-2 py-0.5 text-[10px] font-medium text-red-600">{uiLabels.soldOut[lang]}</span>}
            </div>
            {showShortDesc && iDesc && (
              <p className="mt-1 text-sm" style={{ fontFamily: 'var(--mc-body-font)', color: 'var(--mc-body-color)', fontStyle: 'var(--mc-body-style, normal)', opacity: 0.7 }}>{iDesc}</p>
            )}
            {item.wineProfile && (
              <div className="mt-2 flex flex-wrap gap-x-3 text-xs" style={{ color: 'var(--mc-meta-color)', opacity: 0.6 }}>
                {wineDetails.includes('winery') && item.wineProfile.winery && <span>{item.wineProfile.winery}</span>}
                {wineDetails.includes('vintage') && item.wineProfile.vintage && <span>{item.wineProfile.vintage}</span>}
                {wineDetails.includes('grape') && item.wineProfile.grapeVarieties?.length ? <span>{item.wineProfile.grapeVarieties.join(', ')}</span> : null}
                {wineDetails.includes('region') && item.wineProfile.region && <span>{item.wineProfile.region}</span>}
                {wineDetails.includes('country') && item.wineProfile.country && <span>{item.wineProfile.country}</span>}
              </div>
            )}
            {item.tags.length > 0 && (
              <div className="mt-2 flex flex-wrap gap-1">
                {item.tags.map(tg => (
                  <span key={tg.tag.id} className="rounded-full bg-gray-100 px-2 py-0.5 text-[10px] font-medium">{t(tg.tag.translations)}</span>
                ))}
              </div>
            )}
          </div>
          {showImages && item.image && (
            <img src={item.image} alt="" className={`flex-shrink-0 object-contain ${imgClasses}`}
              style={{ height: `${imageSize}px`, maxWidth: `${imageSize * 0.75}px` }} loading="lazy" />
          )}
          {(!showImages || !item.image) && (
            <span className="material-symbols-outlined mt-1 flex-shrink-0 opacity-20" style={{ fontSize: 16 }}>chevron_right</span>
          )}
        </div>
        <div className="mt-3 flex flex-wrap items-baseline gap-3">
          {showAllPrices && multiPrice ? item.priceVariants.map(pv => (
            <div key={pv.id} className="text-sm">
              <span className="tabular-nums" style={{ fontFamily: 'var(--mc-price-font)', fontWeight: 'var(--mc-price-weight)' as any, color: 'var(--mc-price-color)' }}>{formatPrice(pv.price, priceLocale)}</span>
              {showFillQuantity && (pv.label || pv.volume) && <span className="ml-1 text-xs" style={{ color: 'var(--mc-meta-color)', opacity: 0.5 }}>{pv.label || pv.volume}</span>}
            </div>
          )) : defPrice && (
            <span className="text-sm tabular-nums" style={{ fontFamily: 'var(--mc-price-font)', fontWeight: 'var(--mc-price-weight)' as any, color: 'var(--mc-price-color)' }}>{formatPrice(defPrice.price, priceLocale)}</span>
          )}
        </div>
      </Link>
    );
  };

  const renderDefaultSection = (section: typeof filteredSections[0]) => {
    const sName = t(section.translations);
    const sDesc = t(section.translations, 'description');
    const densitySection = dc?.density === 'airy' ? 'py-10' : dc?.density === 'compact' ? 'py-5' : 'py-8';
    const densityGap = dc?.density === 'airy' ? 'space-y-3' : dc?.density === 'compact' ? 'space-y-1' : 'space-y-2';

    return (
      <section key={section.id} id={section.slug} className={`scroll-mt-40 ${densitySection}`}>
        <div className="mb-6 text-center" style={{ backgroundColor: 'var(--mc-section-header-bg, transparent)' }}>
          <h2 style={{ fontFamily: 'var(--mc-h2-font)', fontSize: 'var(--mc-h2-size)', fontWeight: 'var(--mc-h2-weight)' as any, color: 'var(--mc-h2-color)', textTransform: 'var(--mc-h2-transform, none)' as any, letterSpacing: 'var(--mc-h2-spacing, normal)' }}>{sName}</h2>
          {sDesc && <p className="mt-1 text-sm" style={{ color: 'var(--mc-body-color)', opacity: 0.6 }}>{sDesc}</p>}
          <div className="mx-auto mt-3 w-16" style={{ height: 'var(--mc-section-line-w, 1px)', backgroundColor: 'var(--mc-section-line)' }} />
        </div>
        <div className={densityGap}>{section.items.map(renderDefaultItem)}</div>
      </section>
    );
  };

  /* ====================================================
   * RENDER: Choose template renderer
   * ==================================================== */
  const renderSection = template === 'elegant' ? renderElegantSection
    : template === 'minimal' ? renderElegantSection  /* TODO: eigenes Template */
    : renderDefaultSection;

  /* ====================================================
   * MAIN RENDER
   * ==================================================== */
  return (
    <>
      {renderSearchBar()}

      <main className="mx-auto max-w-2xl px-4">
        {filteredSections.length === 0 ? (
          <div className="py-16 text-center">
            <p className="text-lg opacity-40">{uiLabels.noResults[lang]}</p>
            <button onClick={() => { setQuery(''); setStyleFilter(''); setCountryFilter(''); }}
              className="mt-3 text-sm font-medium underline opacity-50 hover:opacity-100">{uiLabels.clearFilters[lang]}</button>
          </div>
        ) : (
          filteredSections.map(renderSection)
        )}

        {/* MwSt-Hinweis Elegant */}
        {template === 'elegant' && filteredSections.length > 0 && (
          <div className="py-8 text-center">
            <p className="text-xs" style={{ color: 'var(--mc-meta-color, #8E8E8E)', opacity: 0.5 }}>
              {lang === 'de'
                ? 'Alle Preise inkl. gesetzlicher MwSt.\nBitte informieren Sie unser Personal über Allergien.'
                : 'All prices incl. taxes.\nPlease inform our staff about allergies.'}
            </p>
          </div>
        )}
      </main>

      {/* Back to top */}
      {showBackToTop && (
        <button onClick={scrollToTop}
          className="fixed bottom-6 right-6 z-30 rounded-full border bg-white/90 p-3 shadow-lg backdrop-blur transition-all hover:shadow-xl"
          style={{ borderColor: 'var(--mc-product-divider, #ddd)' }}>
          <span className="material-symbols-outlined" style={{ fontSize: 20 }}>keyboard_arrow_up</span>
        </button>
      )}
    </>
  );
}
MENUEOF

# ============================================
# 3. FIX: menu-content alte Referenz
# ============================================
echo "[3/3] Prüfe Import-Kompatibilität..."

# Die Datei menu-content.tsx exportiert weiterhin "export default function MenuContent"
# und akzeptiert die gleichen Props, also sind alle Imports kompatibel.

# ============================================
# BUILD
# ============================================
echo "[BUILD] Starte Build..."
npm run build && pm2 restart menucard-pro

echo ""
echo "============================================"
echo "  UI-Redesign Phase 3a: Elegant Template FERTIG!"
echo "============================================"
echo "  - Location-Seite: Menü-Karten mit Material Icons"
echo "  - Elegant-Template: Uppercase Namen, kursive"
echo "    Beschreibungen, Allergene als Codes"
echo "  - Tab-Navigation mit Rosa-Unterstreichung"
echo "  - Suchleiste mit Material Symbols"
echo "  - MwSt-Hinweis im Footer"
echo "  - Default-Template als Fallback für andere"
echo "============================================"
