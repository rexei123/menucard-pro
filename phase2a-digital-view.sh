#!/bin/bash
# MenuCard Pro – Phase 2a: Digitale Ansicht Config-Driven
# Gästeansicht liest designConfig und wendet Styles dynamisch an
# Datum: 11.04.2026

set -e
cd /var/www/menucard-pro

echo "=== Phase 2a: Config-Driven Gästeansicht ==="

# === 1. Config-to-CSS Helper ===
echo "[1/4] Config-to-CSS Helper erstellen..."

mkdir -p src/lib

cat > src/lib/design-config-reader.ts << 'ENDOFFILE'
import { DesignConfig, DigitalConfig, mergeConfig, getTemplate } from './design-templates';

/**
 * Resolves a menu's designConfig: loads template defaults, merges with overrides.
 * Returns the complete DigitalConfig ready for rendering.
 */
export function resolveDigitalConfig(designConfig: any): DigitalConfig {
  const templateName = designConfig?.digital?.template || 'elegant';
  const template = getTemplate(templateName);
  return mergeConfig(template.digital, designConfig?.digital || {});
}

/**
 * Converts a DigitalConfig into CSS custom properties.
 * These are set on the page wrapper so all children can reference them.
 */
export function configToCssVars(config: DigitalConfig): Record<string, string> {
  const vars: Record<string, string> = {};

  // Typography
  const typoLevels = ['h1', 'h2', 'h3', 'body', 'price', 'meta'] as const;
  for (const level of typoLevels) {
    const t = config.typography[level];
    vars[`--mc-${level}-font`] = `'${t.font}', ${t.font.includes('Sans') || t.font === 'Inter' || t.font === 'Lato' ? 'sans-serif' : 'serif'}`;
    vars[`--mc-${level}-size`] = `${t.size}px`;
    vars[`--mc-${level}-weight`] = String(t.weight || 400);
    vars[`--mc-${level}-color`] = t.color;
    if (t.transform) vars[`--mc-${level}-transform`] = t.transform;
    if (t.spacing) vars[`--mc-${level}-spacing`] = `${t.spacing}em`;
    if (t.style) vars[`--mc-${level}-style`] = t.style;
  }

  // Colors
  vars['--mc-bg'] = config.colors.pageBackground;
  vars['--mc-header-bg'] = config.colors.headerBackground;
  vars['--mc-header-text'] = config.colors.headerText;
  vars['--mc-section-header-bg'] = config.colors.sectionHeaderBg;
  vars['--mc-section-line'] = config.colors.sectionLine;
  vars['--mc-section-line-w'] = `${config.colors.sectionLineWidth}px`;
  vars['--mc-product-bg'] = config.colors.productBg;
  vars['--mc-product-hover'] = config.colors.productHover;
  vars['--mc-product-divider'] = config.colors.productDivider;
  vars['--mc-price-line'] = config.colors.priceLine;
  vars['--mc-price-line-color'] = config.colors.priceLineColor;
  vars['--mc-accent'] = config.colors.accentPrimary;
  vars['--mc-accent-recommend'] = config.colors.accentRecommend;
  vars['--mc-accent-new'] = config.colors.accentNew;
  vars['--mc-accent-premium'] = config.colors.accentPremium;

  // Density
  const densityMap = { airy: '1.25', normal: '1', compact: '0.8' };
  vars['--mc-density'] = densityMap[config.density] || '1';

  return vars;
}

/**
 * Returns density-based spacing classes
 */
export function getDensityClasses(density: string): { section: string; item: string; padding: string } {
  switch (density) {
    case 'airy': return { section: 'py-10', item: 'space-y-3', padding: 'p-5' };
    case 'compact': return { section: 'py-5', item: 'space-y-1', padding: 'p-3' };
    default: return { section: 'py-8', item: 'space-y-2', padding: 'p-4' };
  }
}
ENDOFFILE

# === 2. Gästeansicht (page.tsx) mit Config ===
echo "[2/4] Gästeansicht mit Config-Reader aktualisieren..."

cat > 'src/app/(public)/[tenant]/[location]/[menu]/page.tsx' << 'ENDOFFILE'
import { notFound } from 'next/navigation';
import { Suspense } from 'react';
import prisma from '@/lib/prisma';
import Link from 'next/link';
import LanguageSwitcher from '@/components/language-switcher';
import MenuContent from '@/components/menu-content';
import { resolveDigitalConfig, configToCssVars } from '@/lib/design-config-reader';

const ui: Record<string, Record<string, string>> = {
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
        placements: { orderBy: { sortOrder: 'asc' }, include: {
          product: { include: {
            translations: true,
            prices: { include: { fillQuantity: true }, orderBy: { sortOrder: 'asc' } },
            productAllergens: { include: { allergen: { include: { translations: true } } } },
            productTags: { include: { tag: { include: { translations: true } } } },
            productWineProfile: true,
            productMedia: { where: { isPrimary: true }, take: 1, orderBy: { sortOrder: 'asc' } },
          } },
        } },
      } },
    },
  });
  if (!menu) return notFound();

  // Resolve design config: merge template defaults with menu overrides
  const digitalConfig = resolveDigitalConfig(menu.designConfig);
  const cssVars = configToCssVars(digitalConfig);

  const menuName = digitalConfig.header.title || t(menu.translations);
  const subtitle = digitalConfig.header.subtitle || null;
  const langParam = lang === 'en' ? '?lang=en' : '';
  const priceLocale = lang === 'en' ? 'en-GB' : 'de-AT';
  const isWineMenu = menu.type === 'WINE';

  // Serialize placements
  const serializedSections = menu.sections.map(s => ({
    id: s.id,
    slug: s.slug,
    icon: s.icon,
    translations: s.translations.map(st => ({ languageCode: st.languageCode, name: st.name, description: st.description })),
    items: s.placements.map(pl => {
      const p = pl.product;
      return {
        id: p.id,
        isHighlight: p.isHighlight || !!pl.highlightType,
        highlightType: pl.highlightType || p.highlightType,
        isSoldOut: p.status === 'SOLD_OUT' || !pl.isVisible,
        translations: p.translations.map(pt => ({
          languageCode: pt.languageCode,
          name: pt.name,
          shortDescription: pt.shortDescription,
          longDescription: pt.longDescription,
        })),
        priceVariants: p.prices.map(pp => ({
          id: pp.id,
          label: pp.fillQuantity.label,
          price: pl.priceOverride ? Number(pl.priceOverride) : Number(pp.price),
          volume: pp.fillQuantity.volume,
          isDefault: pp.isDefault,
        })),
        allergens: p.productAllergens.map(a => ({
          allergen: {
            id: a.allergen.id,
            icon: a.allergen.icon,
            translations: a.allergen.translations.map(at => ({ languageCode: at.languageCode, name: at.name })),
          },
        })),
        tags: p.productTags.map(tg => ({
          tag: {
            id: tg.tag.id,
            icon: tg.tag.icon,
            color: tg.tag.color,
            translations: tg.tag.translations.map(tt => ({ languageCode: tt.languageCode, name: tt.name })),
          },
        })),
        image: (() => {
          const pm = (p as any).productMedia?.[0];
          if (!pm) return null;
          const url = pm.url || '';
          return url.replace('/uploads/large/', '/uploads/medium/');
        })(),
        wineProfile: p.productWineProfile ? {
          winery: p.productWineProfile.winery,
          vintage: p.productWineProfile.vintage,
          grapeVarieties: p.productWineProfile.grapeVarieties,
          region: p.productWineProfile.region,
          country: p.productWineProfile.country,
          appellation: p.productWineProfile.appellation,
          style: p.productWineProfile.style,
          body: p.productWineProfile.body,
          sweetness: p.productWineProfile.sweetness,
        } : null,
      };
    }),
  }));

  // Header height variants
  const headerHeight = digitalConfig.header.height;
  const headerClasses = headerHeight === 'large'
    ? 'relative min-h-[40vh] flex flex-col items-center justify-center'
    : headerHeight === 'small'
      ? 'px-6 py-4 text-center'
      : 'px-6 py-6 text-center';

  return (
    <div className="min-h-screen pb-16" style={{ ...cssVars, background: 'var(--mc-bg)', color: 'var(--mc-h3-color)' } as React.CSSProperties}>
      {/* Header */}
      <header className={`border-b ${headerClasses}`} style={{ backgroundColor: 'var(--mc-header-bg)', color: 'var(--mc-header-text)' }}>
        {headerHeight === 'large' && digitalConfig.header.backgroundImage && (
          <div className="absolute inset-0 bg-cover bg-center" style={{
            backgroundImage: `url(${digitalConfig.header.backgroundImage})`,
            opacity: digitalConfig.header.overlayOpacity,
          }} />
        )}
        <div className="relative z-10">
          {digitalConfig.header.logo && (
            <div className={`mb-3 flex ${digitalConfig.header.logoPosition === 'left' ? 'justify-start' : digitalConfig.header.logoPosition === 'right' ? 'justify-end' : 'justify-center'}`}>
              <img src={digitalConfig.header.logo} alt="" style={{ height: `${digitalConfig.header.logoSize}px` }} className="object-contain" />
            </div>
          )}
          <Link href={`/${tenant.slug}/${location.slug}${langParam}`}
            className="text-xs uppercase tracking-widest"
            style={{ opacity: 0.4 }}>
            {tenant.name}
          </Link>
          <h1 className="mt-2" style={{
            fontFamily: 'var(--mc-h1-font)',
            fontSize: 'var(--mc-h1-size)',
            fontWeight: 'var(--mc-h1-weight)' as any,
            letterSpacing: 'var(--mc-h1-spacing)',
            textTransform: (digitalConfig.typography.h1.transform || 'none') as any,
          }}>{menuName}</h1>
          {subtitle && (
            <p className="mt-1 text-sm" style={{ opacity: 0.6 }}>{subtitle}</p>
          )}
        </div>
      </header>

      <MenuContent
        sections={serializedSections}
        lang={lang}
        langParam={langParam}
        priceLocale={priceLocale}
        accentColor={cssVars['--mc-accent']}
        tenantSlug={tenant.slug}
        locationSlug={location.slug}
        menuSlug={menu.slug}
        isWineMenu={isWineMenu}
        digitalConfig={JSON.parse(JSON.stringify(digitalConfig))}
      />

      {/* Footer */}
      {digitalConfig.footer.show && (
        <div className="mx-auto max-w-2xl px-4">
          <div className="border-t py-8 text-center" style={{ borderColor: 'var(--mc-product-divider)' }}>
            {digitalConfig.footer.text && (
              <p className="text-xs" style={{ color: 'var(--mc-meta-color)', opacity: 0.6 }}>{digitalConfig.footer.text}</p>
            )}
            {digitalConfig.footer.showPriceNote && (
              <p className="mt-1 text-xs" style={{ opacity: 0.3 }}>{ui.prices[lang]}</p>
            )}
            <p className="mt-1 text-xs" style={{ opacity: 0.2 }}>{ui.powered[lang]}</p>
          </div>
        </div>
      )}

      <Suspense fallback={null}>
        <LanguageSwitcher />
      </Suspense>
    </div>
  );
}
ENDOFFILE

# === 3. MenuContent mit Config-Support ===
echo "[3/4] MenuContent Config-aware machen..."

cat > src/components/menu-content.tsx << 'ENDOFFILE'
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
  template: string;
  mood: string;
  density: string;
  typography: Record<string, any>;
  colors: Record<string, any>;
  products: Record<string, any>;
  navigation: Record<string, any>;
  badges: Record<string, any>;
  [key: string]: any;
};

type MenuContentProps = {
  sections: Section[];
  lang: string;
  langParam: string;
  priceLocale: string;
  accentColor: string;
  tenantSlug: string;
  locationSlug: string;
  menuSlug: string;
  isWineMenu: boolean;
  digitalConfig?: DigitalConfigProp;
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

function formatPriceLocal(price: number, locale: string): string {
  return new Intl.NumberFormat(locale, { style: 'currency', currency: 'EUR', minimumFractionDigits: 2 }).format(price);
}

export default function MenuContent({ sections, lang, langParam, priceLocale, accentColor, tenantSlug, locationSlug, menuSlug, isWineMenu, digitalConfig: dc }: MenuContentProps) {
  const [query, setQuery] = useState('');
  const [styleFilter, setStyleFilter] = useState('');
  const [countryFilter, setCountryFilter] = useState('');

  // Config helpers with fallbacks
  const showImages = dc?.products?.showImages ?? true;
  const showShortDesc = dc?.products?.showShortDesc ?? true;
  const showFillQuantity = dc?.products?.showFillQuantity ?? true;
  const showAllPrices = dc?.products?.showAllPrices ?? true;
  const imageShape = dc?.products?.imageShape || 'rounded';
  const imageSize = dc?.products?.imageSize || 64;
  const wineDetails = dc?.products?.wineDetails || ['winery', 'vintage', 'region'];
  const density = dc?.density || 'normal';
  const stickyNav = dc?.navigation?.stickyNav ?? true;
  const showBackToTop = dc?.navigation?.showBackToTop ?? true;
  const navStyle = dc?.navigation?.tocStyle || 'pills';

  const densityPadding = density === 'airy' ? 'p-5' : density === 'compact' ? 'p-3' : 'p-4';
  const densityGap = density === 'airy' ? 'space-y-3' : density === 'compact' ? 'space-y-1' : 'space-y-2';
  const densitySection = density === 'airy' ? 'py-10' : density === 'compact' ? 'py-5' : 'py-8';

  const imgClasses = imageShape === 'round' ? 'rounded-full' : imageShape === 'rectangle' ? 'rounded-none' : 'rounded-lg';

  const t = (translations: { languageCode: string; name?: string; shortDescription?: string | null; description?: string | null }[], field: string = 'name') => {
    const found = translations.find(tr => tr.languageCode === lang);
    const fb = translations.find(tr => tr.languageCode === 'de');
    return (found as any)?.[field] || (fb as any)?.[field] || '';
  };

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

  // Scroll to top handler
  const scrollToTop = () => window.scrollTo({ top: 0, behavior: 'smooth' });

  return (
    <>
      {/* Search & Filter Bar */}
      <div className={`${stickyNav ? 'sticky top-0' : ''} z-20 border-b backdrop-blur-md`}
        style={{ backgroundColor: 'var(--mc-bg, #FFFFFF)', borderColor: 'var(--mc-product-divider, #eee)' }}>
        <div className="mx-auto max-w-2xl px-4 py-3">
          <div className="relative">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="absolute left-3 top-1/2 -translate-y-1/2 opacity-30"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
            <input type="text" value={query} onChange={e => setQuery(e.target.value)} placeholder={uiLabels.search[lang]}
              className="w-full rounded-full border py-2.5 pl-10 pr-10 text-sm outline-none transition-colors focus:border-gray-400"
              style={{ backgroundColor: 'var(--mc-product-bg, #f9f9f9)' }} />
            {query && (
              <button onClick={() => setQuery('')} className="absolute right-3 top-1/2 -translate-y-1/2 rounded-full p-0.5 opacity-40 hover:opacity-100">
                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
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
              <button onClick={() => { setQuery(''); setStyleFilter(''); setCountryFilter(''); }} className="text-xs font-medium opacity-50 hover:opacity-100">{uiLabels.clearFilters[lang]}</button>
            </div>
          )}
        </div>
        {/* Section Nav */}
        {!isActive && sections.length > 1 && (
          <div className="border-t" style={{ borderColor: 'var(--mc-product-divider, #eee)' }}>
            <div className="flex overflow-x-auto px-4 py-2 gap-1 hide-scrollbar">
              {sections.map(s => (
                <a key={s.id} href={`#${s.slug}`}
                  className={`flex-shrink-0 text-sm font-medium ${navStyle === 'pills' ? 'rounded-full px-4 py-2 hover:bg-black/5' : 'px-3 py-2 border-b-2 border-transparent hover:border-current'}`}
                  style={{ whiteSpace: 'nowrap' }}>
                  {s.icon && <span className="mr-1">{s.icon}</span>}{t(s.translations)}
                </a>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Content */}
      <main className="mx-auto max-w-2xl px-4">
        {filteredSections.length === 0 ? (
          <div className="py-16 text-center">
            <p className="text-lg opacity-40">{uiLabels.noResults[lang]}</p>
            <button onClick={() => { setQuery(''); setStyleFilter(''); setCountryFilter(''); }} className="mt-3 text-sm font-medium underline opacity-50 hover:opacity-100">{uiLabels.clearFilters[lang]}</button>
          </div>
        ) : (
          filteredSections.map(section => {
            const sName = t(section.translations);
            const sDesc = t(section.translations, 'description');
            return (
              <section key={section.id} id={section.slug} className={`scroll-mt-40 ${densitySection}`}>
                <div className="mb-6 text-center" style={{ backgroundColor: 'var(--mc-section-header-bg, transparent)' }}>
                  {section.icon && <span className="text-2xl">{section.icon}</span>}
                  <h2 style={{
                    fontFamily: 'var(--mc-h2-font)',
                    fontSize: 'var(--mc-h2-size)',
                    fontWeight: 'var(--mc-h2-weight)' as any,
                    color: 'var(--mc-h2-color)',
                    textTransform: 'var(--mc-h2-transform, none)' as any,
                    letterSpacing: 'var(--mc-h2-spacing, normal)',
                  }}>{sName}</h2>
                  {sDesc && <p className="mt-1 text-sm" style={{ color: 'var(--mc-body-color)', opacity: 0.6 }}>{sDesc}</p>}
                  <div className="mx-auto mt-3 w-16" style={{
                    height: 'var(--mc-section-line-w, 1px)',
                    backgroundColor: 'var(--mc-section-line)',
                  }} />
                </div>
                <div className={densityGap}>
                  {section.items.map(item => {
                    const iName = t(item.translations);
                    const iDesc = t(item.translations, 'shortDescription');
                    const defPrice = item.priceVariants.find(p => p.isDefault) || item.priceVariants[0];
                    const multiPrice = item.priceVariants.length > 1;
                    const detailHref = `/${tenantSlug}/${locationSlug}/${menuSlug}/item/${item.id}${langParam}`;

                    return (
                      <Link key={item.id} href={detailHref}
                        className={`block rounded-xl border shadow-sm transition-all ${item.isSoldOut ? 'opacity-50' : ''} hover:shadow-md cursor-pointer ${densityPadding}`}
                        style={{
                          backgroundColor: 'var(--mc-product-bg, #fff)',
                          borderColor: 'var(--mc-product-divider, #eee)',
                        }}
                        onMouseEnter={e => (e.currentTarget.style.backgroundColor = dc?.colors?.productHover || '#FFF5E6')}
                        onMouseLeave={e => (e.currentTarget.style.backgroundColor = dc?.colors?.productBg || 'transparent')}
                      >
                        <div className="flex items-start justify-between gap-3">
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2 flex-wrap">
                              <h3 style={{
                                fontFamily: 'var(--mc-h3-font)',
                                fontSize: 'var(--mc-h3-size)',
                                fontWeight: 'var(--mc-h3-weight)' as any,
                                color: 'var(--mc-h3-color)',
                              }}>{iName}</h3>
                              {item.isHighlight && item.highlightType && (
                                <span className="rounded-full px-2 py-0.5 text-[10px] font-semibold text-white"
                                  style={{ backgroundColor: accentColor }}>
                                  {hlLabels[item.highlightType]?.[lang] || ''}
                                </span>
                              )}
                              {item.isSoldOut && <span className="rounded-full bg-red-100 px-2 py-0.5 text-[10px] font-medium text-red-600">{uiLabels.soldOut[lang]}</span>}
                            </div>
                            {showShortDesc && iDesc && (
                              <p className="mt-1 text-sm" style={{
                                fontFamily: 'var(--mc-body-font)',
                                color: 'var(--mc-body-color)',
                                fontStyle: 'var(--mc-body-style, normal)',
                                opacity: 0.7,
                              }}>{iDesc}</p>
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
                                  <span key={tg.tag.id} className="rounded-full bg-gray-100 px-2 py-0.5 text-[10px] font-medium">{tg.tag.icon} {t(tg.tag.translations)}</span>
                                ))}
                              </div>
                            )}
                          </div>
                          {showImages && item.image && (
                            <img src={item.image} alt=""
                              className={`flex-shrink-0 object-contain ${imgClasses}`}
                              style={{ height: `${imageSize}px`, maxWidth: `${imageSize * 0.75}px` }}
                              loading="lazy" />
                          )}
                          {(!showImages || !item.image) && (
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="mt-1 flex-shrink-0 opacity-20"><path d="m9 18 6-6-6-6"/></svg>
                          )}
                        </div>
                        <div className="mt-3 flex flex-wrap items-baseline gap-3">
                          {showAllPrices && multiPrice ? item.priceVariants.map(pv => (
                            <div key={pv.id} className="text-sm">
                              <span className="tabular-nums" style={{
                                fontFamily: 'var(--mc-price-font)',
                                fontWeight: 'var(--mc-price-weight)' as any,
                                color: 'var(--mc-price-color)',
                              }}>{formatPriceLocal(pv.price, priceLocale)}</span>
                              {showFillQuantity && (pv.label || pv.volume) && (
                                <span className="ml-1 text-xs" style={{ color: 'var(--mc-meta-color)', opacity: 0.5 }}>{pv.label || pv.volume}</span>
                              )}
                            </div>
                          )) : defPrice && (
                            <span className="text-sm tabular-nums" style={{
                              fontFamily: 'var(--mc-price-font)',
                              fontWeight: 'var(--mc-price-weight)' as any,
                              color: 'var(--mc-price-color)',
                            }}>{formatPriceLocal(defPrice.price, priceLocale)}</span>
                          )}
                        </div>
                      </Link>
                    );
                  })}
                </div>
              </section>
            );
          })
        )}
      </main>

      {/* Back to top button */}
      {showBackToTop && (
        <button onClick={scrollToTop}
          className="fixed bottom-6 right-6 z-30 rounded-full border bg-white/90 p-3 shadow-lg backdrop-blur transition-all hover:shadow-xl"
          style={{ borderColor: 'var(--mc-product-divider, #ddd)' }}
          aria-label="Nach oben">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m18 15-6-6-6 6"/></svg>
        </button>
      )}
    </>
  );
}
ENDOFFILE

# === 4. Build + Restart ===
echo "[4/4] Build + Restart..."
npm run build 2>&1 | tail -10
pm2 restart menucard-pro

echo ""
echo "=== Phase 2a fertig! ==="
echo "Gästeansicht ist jetzt config-driven."
echo "Alle Karten verwenden automatisch das 'Elegant'-Template als Default."
echo "Über die API PATCH /api/v1/menus/[id]/design kann die Config geändert werden."
