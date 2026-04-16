'use client';
import Link from 'next/link';

type PriceVariant = { id: string; label: string | null; price: number; volume: string | null; isDefault: boolean };
type Translation = { language?: string; languageCode?: string; name: string; shortDescription?: string | null; longDescription?: string | null };
type AllergenData = { allergen: { id: string; icon?: string | null; translations: { language?: string; languageCode?: string; name: string }[] } };
type TagData = { tag: { id: string; icon?: string | null; color?: string | null; translations: { language?: string; languageCode?: string; name: string }[] } };
type WineProfile = { winery?: string | null; vintage?: number | null; aging?: string | null; tastingNotes?: string | null; servingTemp?: string | null; foodPairing?: string[] | null; certification?: string | null; grapeVarieties?: string[]; region?: string | null; country?: string | null; appellation?: string | null; style?: string | null; body?: string | null; sweetness?: string | null };
type Item = { id: string; highlightType?: string | null; isSoldOut: boolean; image?: string | null; translations: Translation[]; priceVariants: PriceVariant[]; allergens: AllergenData[]; tags: TagData[]; wineProfile?: WineProfile | null };
type Section = { id: string; slug: string; icon?: string | null; translations: Translation[]; items: Item[] };

const hlLabels: Record<string, Record<string, string>> = {
  RECOMMENDATION: { de: 'Empfehlung', en: 'Recommended' },
  NEW: { de: 'Neu', en: 'New' },
  BESTSELLER: { de: 'Bestseller', en: 'Bestseller' },
  PREMIUM: { de: 'Premium', en: 'Premium' },
  SIGNATURE: { de: 'Signature', en: 'Signature' },
};

const soldOutLabel: Record<string, string> = { de: 'Ausverkauft', en: 'Sold out' };

function formatPrice(price: number, locale: string): string {
  return new Intl.NumberFormat(locale, { style: 'currency', currency: 'EUR', minimumFractionDigits: 2 }).format(price);
}

interface ModernItemProps {
  item: Item;
  lang: string;
  priceLocale: string;
  detailHref: string;
  showShortDesc: boolean;
  t: (translations: any[], field?: string) => string;
}

export function ModernItem({ item, lang, priceLocale, detailHref, showShortDesc, t }: ModernItemProps) {
  const iName = t(item.translations);
  const iDesc = t(item.translations, 'shortDescription');
  const defPrice = item.priceVariants.find(p => p.isDefault) || item.priceVariants[0];

  return (
    <Link
      key={item.id}
      href={detailHref}
      className={`block rounded-xl overflow-hidden shadow-md hover:shadow-lg transition-all border border-gray-100 ${item.isSoldOut ? 'opacity-50' : ''}`}
      style={{ backgroundColor: '#FFFFFF' }}
    >
      {/* Bild */}
      {item.image ? (
        <div className="relative h-48 w-full overflow-hidden">
          <img src={item.image} alt="" className="w-full h-full object-cover" loading="lazy" />
          <div className="absolute top-0 left-0 w-full h-12 bg-gradient-to-b from-black/30 to-transparent" />
          {/* Tag oben links */}
          {item.highlightType && item.highlightType !== 'NONE' && (
            <div
              className="absolute top-3 left-3 px-2.5 py-0.5 rounded-full shadow-sm"
              style={{
                backgroundColor: item.highlightType === 'NEW' ? '#DD3C71'
                  : item.highlightType === 'BESTSELLER' ? '#F59E0B'
                  : 'rgba(255,255,255,0.9)',
                color: ['NEW', 'BESTSELLER', 'PREMIUM'].includes(item.highlightType || '') ? '#FFF' : '#171A1F',
              }}
            >
              <span className="text-[10px] font-bold uppercase tracking-wider">
                {hlLabels[item.highlightType]?.[lang] || ''}
              </span>
            </div>
          )}
          {item.isSoldOut && (
            <div className="absolute top-3 right-3 px-2.5 py-0.5 rounded-full bg-red-500 text-white">
              <span className="text-[10px] font-bold">{soldOutLabel[lang]}</span>
            </div>
          )}
        </div>
      ) : (
        <div className="h-32 w-full flex items-center justify-center" style={{ backgroundColor: '#F3F3F6' }}>
          <span className="material-symbols-outlined" style={{ fontSize: 40, color: '#CCC' }}>restaurant</span>
        </div>
      )}

      {/* Content */}
      <div className="p-4">
        <div className="flex justify-between items-start mb-1.5">
          <h3 className="text-base font-bold leading-tight" style={{ fontFamily: "'Montserrat', sans-serif", color: '#171A1F' }}>
            {iName}
          </h3>
          {defPrice && (
            <span className="text-base font-black whitespace-nowrap ml-2" style={{ fontFamily: "'Montserrat', sans-serif", color: '#DD3C71' }}>
              {formatPrice(defPrice.price, priceLocale)}
            </span>
          )}
        </div>

        {showShortDesc && iDesc && (
          <p className="text-sm leading-relaxed mb-3" style={{ color: '#565D6D' }}>
            {iDesc}
          </p>
        )}

        {/* Tags */}
        {item.tags.length > 0 && (
          <div className="flex flex-wrap gap-1.5 mb-3">
            {item.tags.map(tg => (
              <span
                key={tg.tag.id}
                className="rounded-full px-2.5 py-0.5 text-[10px] font-semibold"
                style={{ backgroundColor: '#F3F3F6', color: '#565D6D' }}
              >
                {t(tg.tag.translations)}
              </span>
            ))}
          </div>
        )}

        {/* Wine Details */}
        {item.wineProfile && (
          <div className="flex flex-wrap gap-x-3 text-xs mb-3" style={{ color: '#999' }}>
            {item.wineProfile.winery && <span>{item.wineProfile.winery}</span>}
            {item.wineProfile.vintage && <span>{item.wineProfile.vintage}</span>}
            {item.wineProfile.grapeVarieties?.length ? <span>{item.wineProfile.grapeVarieties.join(', ')}</span> : null}
            {item.wineProfile.region && <span>{item.wineProfile.region}</span>}
          </div>
        )}

        {/* Footer */}
        <div className="pt-3 border-t flex justify-between items-center" style={{ borderColor: 'rgba(0,0,0,0.06)' }}>
          {item.allergens.length > 0 ? (
            <span className="text-[11px]" style={{ color: '#8E8E8E' }}>
              Allergene: {item.allergens.map(a => t(a.allergen.translations).charAt(0)).join(', ')}
            </span>
          ) : <span />}
          <span className="flex items-center gap-1 text-sm font-bold" style={{ color: '#DD3C71' }}>
            Details
            <span className="material-symbols-outlined" style={{ fontSize: 16 }}>chevron_right</span>
          </span>
        </div>
      </div>
    </Link>
  );
}

interface ModernSectionProps {
  section: Section;
  lang: string;
  priceLocale: string;
  tenantSlug: string;
  locationSlug: string;
  menuSlug: string;
  langParam: string;
  showShortDesc: boolean;
  t: (translations: any[], field?: string) => string;
}

export function ModernSection({ section, lang, priceLocale, tenantSlug, locationSlug, menuSlug, langParam, showShortDesc, t }: ModernSectionProps) {
  const sName = t(section.translations);

  return (
    <section key={section.id} id={section.slug} className="scroll-mt-32 pt-8 pb-4">
      {/* Section Header */}
      <div className="flex items-center gap-4 mb-6">
        <h2
          className="text-xl font-black uppercase tracking-tight whitespace-nowrap"
          style={{ fontFamily: "'Montserrat', sans-serif", color: '#171A1F' }}
        >
          {sName}
        </h2>
        <div className="h-1 flex-1 rounded-full" style={{ backgroundColor: '#F3F3F6' }} />
      </div>

      {/* Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
        {section.items.map(item => (
          <ModernItem
            key={item.id}
            item={item}
            lang={lang}
            priceLocale={priceLocale}
            detailHref={`/${tenantSlug}/${locationSlug}/${menuSlug}/item/${item.id}${langParam}`}
            showShortDesc={showShortDesc}
            t={t}
          />
        ))}
      </div>
    </section>
  );
}
