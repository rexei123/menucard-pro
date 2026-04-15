#!/bin/bash
set -e
echo "============================================"
echo "  UI-Redesign Phase 3d: Classic Template"
echo "============================================"

cd /var/www/menucard-pro

# ============================================
# 1. CLASSIC RENDERER
# ============================================
echo "[1/2] Classic-Renderer erstellen..."
mkdir -p src/components/templates

cat > src/components/templates/classic-renderer.tsx << 'CLASSICEOF'
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
  POPULAR: { de: 'Klassiker', en: 'Classic' },
  PREMIUM: { de: 'Premium', en: 'Premium' },
  SEASONAL: { de: 'Saison', en: 'Seasonal' },
  CHEFS_CHOICE: { de: "Chef's Choice", en: "Chef's Choice" },
};

const soldOutLabel: Record<string, string> = { de: 'Ausverkauft', en: 'Sold out' };

function formatPrice(price: number, locale: string): string {
  return new Intl.NumberFormat(locale, { style: 'currency', currency: 'EUR', minimumFractionDigits: 2 }).format(price);
}

/* ====================================================
 * ClassicItem – Fine Dining Stil mit Nummerierung
 * ==================================================== */
interface ClassicItemProps {
  item: Item;
  index: number;
  lang: string;
  priceLocale: string;
  detailHref: string;
  showShortDesc: boolean;
  t: (translations: any[], field?: string) => string;
}

export function ClassicItem({ item, index, lang, priceLocale, detailHref, showShortDesc, t }: ClassicItemProps) {
  const iName = t(item.translations);
  const iDesc = t(item.translations, 'shortDescription');
  const defPrice = item.priceVariants.find(p => p.isDefault) || item.priceVariants[0];
  const num = String(index + 1).padStart(2, '0');

  return (
    <Link
      href={detailHref}
      className={`group block py-5 ${item.isSoldOut ? 'opacity-40' : ''}`}
      style={{ borderBottom: '1px solid rgba(0,0,0,0.06)' }}
    >
      <div className="flex gap-4">
        {/* Nummerierung */}
        <div
          className="flex-shrink-0 w-8 text-right"
          style={{
            fontFamily: "'Playfair Display', serif",
            fontSize: '13px',
            fontWeight: 400,
            color: '#BBB',
            paddingTop: '2px',
          }}
        >
          {num}
        </div>

        {/* Bild (optional, klein) */}
        {item.image && (
          <div className="flex-shrink-0 w-16 h-16 rounded-lg overflow-hidden">
            <img src={item.image} alt="" className="w-full h-full object-cover" loading="lazy" />
          </div>
        )}

        {/* Content */}
        <div className="flex-1 min-w-0">
          <div className="flex justify-between items-baseline gap-3">
            {/* Name + Highlight */}
            <div className="flex items-baseline gap-2 min-w-0">
              <h3
                className="text-[15px] font-semibold uppercase tracking-wide truncate"
                style={{
                  fontFamily: "'Playfair Display', serif",
                  color: '#171A1F',
                  letterSpacing: '0.04em',
                }}
              >
                {iName}
              </h3>
              {item.isHighlight && item.highlightType && (
                <span
                  className="flex-shrink-0 text-[9px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-sm"
                  style={{
                    backgroundColor: item.highlightType === 'NEW' ? '#DD3C71' : 'transparent',
                    color: item.highlightType === 'NEW' ? '#FFF' : '#DD3C71',
                    border: item.highlightType === 'NEW' ? 'none' : '1px solid #DD3C71',
                  }}
                >
                  {hlLabels[item.highlightType]?.[lang] || ''}
                </span>
              )}
              {item.isSoldOut && (
                <span
                  className="flex-shrink-0 text-[9px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-sm"
                  style={{ backgroundColor: '#EF4444', color: '#FFF' }}
                >
                  {soldOutLabel[lang]}
                </span>
              )}
            </div>

            {/* Preis */}
            {defPrice && (
              <span
                className="flex-shrink-0 text-[15px] font-semibold whitespace-nowrap"
                style={{
                  fontFamily: "'Playfair Display', serif",
                  color: '#171A1F',
                }}
              >
                {formatPrice(defPrice.price, priceLocale)}
              </span>
            )}
          </div>

          {/* Beschreibung – kursiv, Fine-Dining-Stil */}
          {showShortDesc && iDesc && (
            <p
              className="mt-1 text-sm leading-relaxed"
              style={{
                fontFamily: "'Playfair Display', serif",
                fontStyle: 'italic',
                color: '#7A7A7A',
                fontWeight: 400,
              }}
            >
              {iDesc}
            </p>
          )}

          {/* Wine Details */}
          {item.wineProfile && (
            <div className="mt-1.5 flex flex-wrap gap-x-2 text-[11px]" style={{ color: '#999' }}>
              {item.wineProfile.winery && (
                <span style={{ fontStyle: 'italic' }}>{item.wineProfile.winery}</span>
              )}
              {item.wineProfile.vintage && <span>{item.wineProfile.vintage}</span>}
              {item.wineProfile.grapeVarieties?.length ? (
                <span>{item.wineProfile.grapeVarieties.join(', ')}</span>
              ) : null}
              {item.wineProfile.region && item.wineProfile.country && (
                <span>{item.wineProfile.region}, {item.wineProfile.country}</span>
              )}
            </div>
          )}

          {/* Tags + Allergene */}
          <div className="mt-2 flex items-center gap-3 flex-wrap">
            {item.tags.length > 0 && (
              <div className="flex gap-1.5">
                {item.tags.map(tg => (
                  <span
                    key={tg.tag.id}
                    className="text-[9px] font-semibold uppercase tracking-wider px-2 py-0.5"
                    style={{
                      border: '1px solid #DEE1E6',
                      color: '#565D6D',
                      borderRadius: '2px',
                    }}
                  >
                    {t(tg.tag.translations)}
                  </span>
                ))}
              </div>
            )}
            {item.allergens.length > 0 && (
              <span className="text-[10px]" style={{ color: '#AAA' }}>
                {item.allergens.map(a => t(a.allergen.translations).charAt(0)).join(', ')}
              </span>
            )}
          </div>
        </div>

        {/* Chevron */}
        <div className="flex-shrink-0 flex items-center opacity-0 group-hover:opacity-100 transition-opacity">
          <span className="material-symbols-outlined" style={{ fontSize: 18, color: '#CCC' }}>chevron_right</span>
        </div>
      </div>
    </Link>
  );
}

/* ====================================================
 * ClassicSection – Sektions-Header mit Dekoration
 * ==================================================== */
interface ClassicSectionProps {
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

export function ClassicSection({ section, lang, priceLocale, tenantSlug, locationSlug, menuSlug, langParam, showShortDesc, t }: ClassicSectionProps) {
  const sName = t(section.translations);
  const sDesc = t(section.translations, 'shortDescription');

  return (
    <section key={section.id} id={section.slug} className="scroll-mt-32 pt-10 pb-6">
      {/* Dekorativer Section Header */}
      <div className="text-center mb-8">
        {/* Dekorative Linie oben */}
        <div className="flex items-center justify-center gap-4 mb-4">
          <div className="h-px w-12" style={{ backgroundColor: '#DEE1E6' }} />
          <span className="material-symbols-outlined" style={{ fontSize: 16, color: '#CCC' }}>
            {section.icon || 'restaurant'}
          </span>
          <div className="h-px w-12" style={{ backgroundColor: '#DEE1E6' }} />
        </div>

        <h2
          className="text-2xl font-bold uppercase tracking-widest"
          style={{
            fontFamily: "'Playfair Display', serif",
            color: '#171A1F',
            letterSpacing: '0.12em',
          }}
        >
          {sName}
        </h2>

        {/* Beschreibung der Kategorie */}
        {sDesc && (
          <p
            className="mt-2 text-sm max-w-md mx-auto"
            style={{
              fontFamily: "'Playfair Display', serif",
              fontStyle: 'italic',
              color: '#999',
            }}
          >
            {sDesc}
          </p>
        )}

        {/* Kleine dekorative Linie unter dem Titel */}
        <div
          className="mx-auto mt-3 w-8 h-0.5"
          style={{ backgroundColor: '#DD3C71' }}
        />
      </div>

      {/* Items */}
      <div style={{ backgroundColor: '#FDFBF7', borderRadius: '8px', padding: '4px 16px' }}>
        {section.items.map((item, idx) => (
          <ClassicItem
            key={item.id}
            item={item}
            index={idx}
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
CLASSICEOF

# ============================================
# 2. MENU-CONTENT.TSX – Classic einbinden
# ============================================
echo "[2/2] menu-content.tsx: Classic-Template einbinden..."

# Import hinzufügen
sed -i "s/import { ModernSection } from '.\/templates\/modern-renderer';/import { ModernSection } from '.\/templates\/modern-renderer';\nimport { ClassicSection } from '.\/templates\/classic-renderer';/" src/components/menu-content.tsx

# Classic-Render-Funktion + Template-Switch aktualisieren
cat > /tmp/add-classic.py << 'PYEOF'
with open('src/components/menu-content.tsx', 'r') as f:
    content = f.read()

classic_fn = '''
  /* ====================================================
   * RENDER: Classic Template Sections (delegiert an Komponente)
   * ==================================================== */
  const renderClassicSection = (section: typeof filteredSections[0]) => (
    <ClassicSection
      key={section.id}
      section={section}
      lang={lang}
      priceLocale={priceLocale}
      tenantSlug={tenantSlug}
      locationSlug={locationSlug}
      menuSlug={menuSlug}
      langParam={langParam}
      showShortDesc={showShortDesc}
      t={t}
    />
  );

'''

marker = "  /* ====================================================\n   * RENDER: Choose template renderer"
content = content.replace(marker, classic_fn + "  /* ====================================================\n   * RENDER: Choose template renderer")

# Template-Switch aktualisieren: classic vor modern einfügen
content = content.replace(
    ": template === 'modern' ? renderModernSection",
    ": template === 'classic' ? renderClassicSection\n    : template === 'modern' ? renderModernSection"
)

with open('src/components/menu-content.tsx', 'w') as f:
    f.write(content)
print("Classic template integrated")
PYEOF
python3 /tmp/add-classic.py
rm -f /tmp/add-classic.py

# ============================================
# BUILD
# ============================================
echo "[BUILD] Starte Build..."
npm run build && pm2 restart menucard-pro

echo ""
echo "============================================"
echo "  UI-Redesign Phase 3d: Classic Template FERTIG!"
echo "============================================"
echo "  - ClassicSection + ClassicItem Komponenten"
echo "  - Fine Dining Nummerierung (01, 02, 03...)"
echo "  - Playfair Display Serif-Schrift"
echo "  - Kursive Beschreibungen"
echo "  - Cream-Hintergrund (#FDFBF7)"
echo "  - Dekorative Sektions-Header mit Akzentlinie"
echo "  - Rosa Akzent (#DD3C71) für Highlights"
echo "  - Hover-Chevron für Detailansicht"
echo "============================================"
