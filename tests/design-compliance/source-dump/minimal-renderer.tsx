'use client';
import Link from 'next/link';

type PriceVariant = { id: string; label: string | null; price: number; volume: string | null; isDefault: boolean };
type Translation = { languageCode: string; name: string; shortDescription?: string | null; longDescription?: string | null };
type AllergenData = { allergen: { id: string; icon?: string | null; translations: { languageCode: string; name: string }[] } };
type TagData = { tag: { id: string; icon?: string | null; color?: string | null; translations: { languageCode: string; name: string }[] } };
type WineProfile = { winery?: string | null; vintage?: number | null; grapeVarieties?: string[]; region?: string | null; country?: string | null; appellation?: string | null; style?: string | null; body?: string | null; sweetness?: string | null };
type Item = { id: string; isHighlight: boolean; highlightType?: string | null; isSoldOut: boolean; image?: string | null; translations: Translation[]; priceVariants: PriceVariant[]; allergens: AllergenData[]; tags: TagData[]; wineProfile?: WineProfile | null };
type Section = { id: string; slug: string; icon?: string | null; translations: Translation[]; items: Item[] };

const hlLabels: Record<string, Record<string, string>> = {
  RECOMMENDATION: { de: 'Empfehlung', en: 'Recommended' },
  NEW: { de: 'Neu', en: 'New' },
  POPULAR: { de: 'Beliebt', en: 'Popular' },
  PREMIUM: { de: 'Premium', en: 'Premium' },
  SEASONAL: { de: 'Saison', en: 'Seasonal' },
  CHEFS_CHOICE: { de: "Chef's Choice", en: "Chef's Choice" },
};

function formatPrice(price: number, locale: string): string {
  return new Intl.NumberFormat(locale, { style: 'currency', currency: 'EUR', minimumFractionDigits: 2 }).format(price);
}

interface MinimalItemProps {
  item: Item;
  lang: string;
  priceLocale: string;
  detailHref: string;
  showShortDesc: boolean;
  showAllPrices: boolean;
  showFillQuantity: boolean;
  wineDetails: string[];
  t: (translations: any[], field?: string) => string;
}

export function MinimalItem({ item, lang, priceLocale, detailHref, showShortDesc, showAllPrices, showFillQuantity, wineDetails, t }: MinimalItemProps) {
  const iName = t(item.translations);
  const iDesc = t(item.translations, 'shortDescription');
  const defPrice = item.priceVariants.find(p => p.isDefault) || item.priceVariants[0];
  const multiPrice = item.priceVariants.length > 1;

  return (
    <Link
      key={item.id}
      href={detailHref}
      className={`block py-4 border-b transition-colors hover:bg-gray-50/50 ${item.isSoldOut ? 'opacity-40' : ''}`}
      style={{ borderColor: 'rgba(0,0,0,0.06)' }}
    >
      {/* Name + Price */}
      <div className="flex items-start justify-between gap-4">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <h3
              className="text-base font-bold tracking-tight"
              style={{ fontFamily: "'Montserrat', sans-serif", color: '#171A1F' }}
            >
              {iName}
            </h3>
            {item.isHighlight && item.highlightType && (
              <span
                className="text-[9px] font-bold px-1.5 py-0.5 uppercase tracking-wider"
                style={{
                  backgroundColor: item.highlightType === 'NEW' ? '#DD3C71' : '#171A1F',
                  color: '#FFFFFF',
                }}
              >
                {hlLabels[item.highlightType]?.[lang] || ''}
              </span>
            )}
          </div>
        </div>
        <div className="flex-shrink-0">
          {showAllPrices && multiPrice ? (
            <div className="space-y-0.5 text-right">
              {item.priceVariants.map(pv => (
                <div key={pv.id} className="text-sm">
                  <span className="font-bold tabular-nums" style={{ color: '#171A1F' }}>
                    {formatPrice(pv.price, priceLocale)}
                  </span>
                  {showFillQuantity && (pv.label || pv.volume) && (
                    <span className="ml-1 text-xs text-gray-400">{pv.label || pv.volume}</span>
                  )}
                </div>
              ))}
            </div>
          ) : defPrice && (
            <span className="text-sm font-bold tabular-nums" style={{ color: '#171A1F' }}>
              {formatPrice(defPrice.price, priceLocale)}
            </span>
          )}
        </div>
      </div>

      {/* Description */}
      {showShortDesc && iDesc && (
        <p className="mt-1 text-sm leading-relaxed" style={{ color: '#666666' }}>
          {iDesc}
        </p>
      )}

      {/* Wine Details */}
      {item.wineProfile && (
        <div className="mt-1.5 flex flex-wrap gap-x-3 text-xs" style={{ color: '#999' }}>
          {wineDetails.includes('winery') && item.wineProfile.winery && <span>{item.wineProfile.winery}</span>}
          {wineDetails.includes('vintage') && item.wineProfile.vintage && <span>{item.wineProfile.vintage}</span>}
          {wineDetails.includes('grape') && item.wineProfile.grapeVarieties?.length ? <span>{item.wineProfile.grapeVarieties.join(', ')}</span> : null}
          {wineDetails.includes('region') && item.wineProfile.region && <span>{item.wineProfile.region}</span>}
        </div>
      )}

      {/* Tags + Allergens inline */}
      {(item.tags.length > 0 || item.allergens.length > 0) && (
        <div className="mt-1.5 flex items-center gap-2 flex-wrap">
          {item.tags.map(tg => (
            <span
              key={tg.tag.id}
              className="text-[10px] font-bold uppercase tracking-widest"
              style={{ color: '#999' }}
            >
              {t(tg.tag.translations)}
            </span>
          ))}
          {item.allergens.length > 0 && (
            <span className="text-[10px] font-medium" style={{ color: '#AAA' }}>
              [{item.allergens.map(a => t(a.allergen.translations).charAt(0).toUpperCase()).join(', ')}]
            </span>
          )}
        </div>
      )}
    </Link>
  );
}

interface MinimalSectionProps {
  section: Section;
  lang: string;
  priceLocale: string;
  tenantSlug: string;
  locationSlug: string;
  menuSlug: string;
  langParam: string;
  showShortDesc: boolean;
  showAllPrices: boolean;
  showFillQuantity: boolean;
  wineDetails: string[];
  t: (translations: any[], field?: string) => string;
}

export function MinimalSection({ section, lang, priceLocale, tenantSlug, locationSlug, menuSlug, langParam, showShortDesc, showAllPrices, showFillQuantity, wineDetails, t }: MinimalSectionProps) {
  const sName = t(section.translations);
  const itemCount = section.items.length;

  return (
    <section key={section.id} id={section.slug} className="scroll-mt-32 pt-10 pb-4">
      {/* Section Header – bold + count badge */}
      <div className="flex items-center gap-3 mb-6">
        <h2
          className="text-2xl font-bold tracking-tight"
          style={{ fontFamily: "'Montserrat', sans-serif", color: '#171A1F' }}
        >
          {sName.toUpperCase()}
        </h2>
        <span
          className="text-[10px] font-medium px-1.5 py-0.5 rounded tracking-widest"
          style={{ backgroundColor: '#F3F4F6', color: '#565D6D' }}
        >
          {itemCount}
        </span>
      </div>

      {/* Items */}
      <div>
        {section.items.map(item => (
          <MinimalItem
            key={item.id}
            item={item}
            lang={lang}
            priceLocale={priceLocale}
            detailHref={`/${tenantSlug}/${locationSlug}/${menuSlug}/item/${item.id}${langParam}`}
            showShortDesc={showShortDesc}
            showAllPrices={showAllPrices}
            showFillQuantity={showFillQuantity}
            wineDetails={wineDetails}
            t={t}
          />
        ))}
      </div>
    </section>
  );
}
