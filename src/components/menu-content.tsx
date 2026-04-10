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
  RED: { de: 'Rotwein', en: 'Red' },
  WHITE: { de: 'Weißwein', en: 'White' },
  ROSE: { de: 'Rosé', en: 'Rosé' },
  SPARKLING: { de: 'Schaumwein', en: 'Sparkling' },
  DESSERT: { de: 'Dessertwein', en: 'Dessert' },
  FORTIFIED: { de: 'Likörwein', en: 'Fortified' },
  ORANGE: { de: 'Orange', en: 'Orange' },
  NATURAL: { de: 'Naturwein', en: 'Natural' },
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

export default function MenuContent({ sections, lang, langParam, priceLocale, accentColor, tenantSlug, locationSlug, menuSlug, isWineMenu }: MenuContentProps) {
  const [query, setQuery] = useState('');
  const [styleFilter, setStyleFilter] = useState('');
  const [countryFilter, setCountryFilter] = useState('');

  const t = (translations: { languageCode: string; name?: string; shortDescription?: string | null; description?: string | null }[], field: string = 'name') => {
    const found = translations.find(tr => tr.languageCode === lang);
    const fb = translations.find(tr => tr.languageCode === 'de');
    return (found as any)?.[field] || (fb as any)?.[field] || '';
  };

  // Collect unique wine styles and countries for filter
  const { wineStyles, countries } = useMemo(() => {
    const styles = new Set<string>();
    const ctries = new Set<string>();
    sections.forEach(s => s.items.forEach(item => {
      if (item.wineProfile?.style) styles.add(item.wineProfile.style);
      if (item.wineProfile?.country) ctries.add(item.wineProfile.country);
    }));
    return { wineStyles: Array.from(styles).sort(), countries: Array.from(ctries).sort() };
  }, [sections]);

  const hasDetail = (item: Item) => { return true; // all items clickable
    const longDesc = t(item.translations, 'longDescription');
    return !!(longDesc || item.wineProfile || item.allergens.length > 0);
  };

  const isActive = query.length > 0 || styleFilter || countryFilter;

  // Filter logic
  const filteredSections = useMemo(() => {
    const q = query.toLowerCase().trim();
    return sections.map(section => {
      const filtered = section.items.filter(item => {
        // Text search
        if (q) {
          const name = t(item.translations).toLowerCase();
          const desc = (t(item.translations, 'shortDescription') || '').toLowerCase();
          const longDesc = (t(item.translations, 'longDescription') || '').toLowerCase();
          const winery = (item.wineProfile?.winery || '').toLowerCase();
          const region = (item.wineProfile?.region || '').toLowerCase();
          const grapes = (item.wineProfile?.grapeVarieties || []).join(' ').toLowerCase();
          const searchable = `${name} ${desc} ${longDesc} ${winery} ${region} ${grapes}`;
          if (!searchable.includes(q)) return false;
        }
        // Wine style filter
        if (styleFilter && item.wineProfile?.style !== styleFilter) return false;
        // Country filter
        if (countryFilter && item.wineProfile?.country !== countryFilter) return false;
        return true;
      });
      return { ...section, items: filtered };
    }).filter(s => s.items.length > 0);
  }, [sections, query, styleFilter, countryFilter, lang]);

  const totalResults = filteredSections.reduce((sum, s) => sum + s.items.length, 0);
  const totalItems = sections.reduce((sum, s) => sum + s.items.length, 0);

  return (
    <>
      {/* Search & Filter Bar */}
      <div className="sticky top-0 z-20 border-b bg-white/95 backdrop-blur-md">
        <div className="mx-auto max-w-2xl px-4 py-3">
          {/* Search Input */}
          <div className="relative">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="absolute left-3 top-1/2 -translate-y-1/2 opacity-30"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
            <input
              type="text"
              value={query}
              onChange={e => setQuery(e.target.value)}
              placeholder={uiLabels.search[lang]}
              className="w-full rounded-full border bg-gray-50 py-2.5 pl-10 pr-10 text-sm outline-none transition-colors focus:border-gray-400 focus:bg-white"
            />
            {query && (
              <button onClick={() => setQuery('')} className="absolute right-3 top-1/2 -translate-y-1/2 rounded-full p-0.5 opacity-40 hover:opacity-100">
                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
              </button>
            )}
          </div>

          {/* Wine Filters */}
          {isWineMenu && (wineStyles.length > 1 || countries.length > 1) && (
            <div className="mt-2 flex gap-2 overflow-x-auto">
              {wineStyles.length > 1 && (
                <select
                  value={styleFilter}
                  onChange={e => setStyleFilter(e.target.value)}
                  className="rounded-full border bg-gray-50 px-3 py-1.5 text-xs outline-none"
                >
                  <option value="">{uiLabels.allStyles[lang]}</option>
                  {wineStyles.map(s => (
                    <option key={s} value={s}>{styleLabels[s]?.[lang] || s}</option>
                  ))}
                </select>
              )}
              {countries.length > 1 && (
                <select
                  value={countryFilter}
                  onChange={e => setCountryFilter(e.target.value)}
                  className="rounded-full border bg-gray-50 px-3 py-1.5 text-xs outline-none"
                >
                  <option value="">{uiLabels.allCountries[lang]}</option>
                  {countries.map(c => (
                    <option key={c} value={c}>{c}</option>
                  ))}
                </select>
              )}
            </div>
          )}

          {/* Active filter info */}
          {isActive && (
            <div className="mt-2 flex items-center justify-between">
              <span className="text-xs opacity-50">{totalResults} / {totalItems} {uiLabels.results[lang]}</span>
              <button onClick={() => { setQuery(''); setStyleFilter(''); setCountryFilter(''); }} className="text-xs font-medium opacity-50 hover:opacity-100">
                {uiLabels.clearFilters[lang]}
              </button>
            </div>
          )}
        </div>

        {/* Section Nav (only when not filtering) */}
        {!isActive && sections.length > 1 && (
          <div className="border-t">
            <div className="flex overflow-x-auto px-4 py-2 gap-1 hide-scrollbar">
              {sections.map(s => (
                <a key={s.id} href={`#${s.slug}`} className="flex-shrink-0 rounded-full px-4 py-2 text-sm font-medium hover:bg-black/5" style={{whiteSpace:'nowrap'}}>
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
            <button onClick={() => { setQuery(''); setStyleFilter(''); setCountryFilter(''); }} className="mt-3 text-sm font-medium underline opacity-50 hover:opacity-100">
              {uiLabels.clearFilters[lang]}
            </button>
          </div>
        ) : (
          filteredSections.map(section => {
            const sName = t(section.translations);
            const sDesc = t(section.translations, 'description');
            return (
              <section key={section.id} id={section.slug} className="scroll-mt-40 py-8">
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
                    const wrapperProps = clickable ? { href: `/${tenantSlug}/${locationSlug}/${menuSlug}/item/${item.id}${langParam}` } : {};
                    return (
                      <Wrapper key={item.id} {...wrapperProps as any} className={`block rounded-xl border bg-white p-4 shadow-sm transition-all ${item.isSoldOut ? 'opacity-50' : ''} ${clickable ? 'hover:shadow-md hover:border-gray-300 cursor-pointer' : ''}`}>
                        <div className="flex items-start justify-between gap-3">
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2 flex-wrap">
                              <h3 className="text-base font-semibold" style={{fontFamily: "'Playfair Display', serif"}}>{iName}</h3>
                              {item.isHighlight && item.highlightType && (
                                <span className="rounded-full px-2 py-0.5 text-[10px] font-semibold text-white" style={{backgroundColor: accentColor}}>{hlLabels[item.highlightType]?.[lang] || ''}</span>
                              )}
                              {item.isSoldOut && <span className="rounded-full bg-red-100 px-2 py-0.5 text-[10px] font-medium text-red-600">{uiLabels.soldOut[lang]}</span>}
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
                          {item.image && (
                            <img
                              src={item.image}
                              alt=""
                              className="h-20 w-auto max-w-[3rem] flex-shrink-0 rounded-lg object-contain"
                              loading="lazy"
                            />
                          )}
                          {clickable && !item.image && (
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="mt-1 flex-shrink-0 opacity-20"><path d="m9 18 6-6-6-6"/></svg>
                          )}
                        </div>
                        <div className="mt-3 flex flex-wrap items-baseline gap-3">
                          {multiPrice ? item.priceVariants.map(pv => (
                            <div key={pv.id} className="text-sm">
                              <span className="font-semibold tabular-nums">{formatPriceLocal(pv.price, priceLocale)}</span>
                              {(pv.label || pv.volume) && <span className="ml-1 text-xs opacity-40">{pv.label || pv.volume}</span>}
                            </div>
                          )) : defPrice && <span className="text-sm font-semibold tabular-nums">{formatPriceLocal(defPrice.price, priceLocale)}</span>}
                        </div>
                      </Wrapper>
                    );
                  })}
                </div>
              </section>
            );
          })
        )}
      </main>
    </>
  );
}
