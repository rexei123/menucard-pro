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
  BESTSELLER: { de: 'Bestseller', en: 'Bestseller' },
  SIGNATURE: { de: 'Signature', en: 'Signature' },
};

const ui: Record<string, Record<string, string>> = {
  back: { de: 'Zurück zur Karte', en: 'Back to menu' },
  soldOut: { de: 'Ausverkauft', en: 'Sold out' },
  winery: { de: 'Weingut', en: 'Winery' },
  vintage: { de: 'Jahrgang', en: 'Vintage' },
  region: { de: 'Region', en: 'Region' },
  tasting: { de: 'Verkostungsnotizen', en: 'Tasting Notes' },
  foodPairing: { de: 'Speiseempfehlung', en: 'Food Pairing' },
  allergens: { de: 'Allergene', en: 'Allergens' },
  prices: { de: 'Preise', en: 'Prices' },
  wineProfile: { de: 'Weinprofil', en: 'Wine Profile' },
  serving: { de: 'Serviervorschlag', en: 'Serving suggestion' },
  aging: { de: 'Ausbau', en: 'Aging' },
  certification: { de: 'Zertifizierung', en: 'Certification' },
  servingTemp: { de: 'Trinktemperatur', en: 'Serving Temperature' },
  variants: { de: 'Varianten', en: 'Variants' },
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
    const found = translations.find((tr: any) => (tr.languageCode || tr.language) === lang);
    const fb = translations.find((tr: any) => (tr.languageCode || tr.language) === 'de');
    return (found?.[field] || fb?.[field]) ?? '';
  };

  const tenant = await prisma.tenant.findUnique({ where: { slug: params.tenant, isActive: true } });
  if (!tenant) return notFound();
  const location = await prisma.location.findUnique({ where: { tenantId_slug: { tenantId: tenant.id, slug: params.location } } });
  if (!location) return notFound();

  // v2: Produkt mit allen Varianten und deren Preisen laden
  const product = await prisma.product.findUnique({
    where: { id: params.itemId },
    include: {
      translations: true,
      variants: {
        where: { isSellable: true },
        orderBy: { sortOrder: 'asc' },
        include: {
          fillQuantity: true,
          prices: { orderBy: { priceLevelId: 'asc' } },
        },
      },
      allergens: { include: { allergen: { include: { translations: true } } } },
      tags: true,
      wineProfile: true,
      beverageDetail: true,
      productMedia: { include: { media: true }, orderBy: { sortOrder: 'asc' } },
      taxonomy: { include: { node: { include: { translations: true, parent: { include: { translations: true } } } } } },
    },
  });
  if (!product) return notFound();

  // Menu laden fuer Template-Konfiguration
  const menu = await prisma.menu.findUnique({
    where: { locationId_slug: { locationId: location.id, slug: params.menu } },
    include: { translations: true, template: true },
  });
  if (!menu) return notFound();

  // Sektion finden fuer Zurueck-Link
  const placement = await prisma.menuPlacement.findFirst({
    where: {
      variant: { productId: product.id },
      section: { menuId: menu.id },
    },
    include: { section: true },
  });
  const sectionSlug = placement?.section?.slug || '';

  const theme = await prisma.theme.findFirst({ where: { tenantId: tenant.id, isActive: true } });
  const accentColor = theme?.accentColor || '#8B6914';
  const langParam = lang === 'en' ? '?lang=en' : '';
  const priceLocale = lang === 'en' ? 'en-GB' : 'de-AT';

  // Template-Config
  const digitalConfig = resolveMenuDigitalConfig(menu as any);
  const cssVars = configToCssVars(digitalConfig);
  const templateKey = (menu as any).template?.baseType || digitalConfig.template || 'elegant';

  const pName = t(product.translations);
  const pShort = t(product.translations, 'shortDescription');
  const pLong = t(product.translations, 'longDescription');
  const pServing = t(product.translations, 'servingSuggestion');
  const menuName = t(menu.translations);
  const wp = product.wineProfile;
  const bd = product.beverageDetail;

  // Taxonomie-Infos fuer Weinprofil-Erweiterung
  const grapeNodes = product.taxonomy.filter((tx: any) => tx.node.type === 'GRAPE').map((tx: any) => t(tx.node.translations) || tx.node.name);
  const regionNodes = product.taxonomy.filter((tx: any) => tx.node.type === 'REGION').map((tx: any) => t(tx.node.translations) || tx.node.name);
  const styleNodes = product.taxonomy.filter((tx: any) => tx.node.type === 'STYLE').map((tx: any) => t(tx.node.translations) || tx.node.name);

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
            {product.highlightType && product.highlightType !== 'NONE' && (
              <span className="rounded-full px-3 py-1 text-xs font-semibold text-white" style={{ backgroundColor: accentColor }}>{hlLabels[product.highlightType]?.[lang] || ''}</span>
            )}
            {(product.status === 'ARCHIVED' || product.variants.every((v: any) => !v.isSellable)) && <span className="rounded-full bg-red-100 px-3 py-1 text-xs font-medium text-red-600">{ui.soldOut[lang]}</span>}
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

        {/* v2: Preise ueber Varianten */}
        {product.variants.length > 0 && (
          <div className="mb-6 rounded-xl border bg-white p-5 shadow-sm">
            <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider opacity-40">{ui.prices[lang]}</h2>
            <div className="space-y-2">
              {product.variants.map((v: any) => {
                const label = v.fillQuantity?.label || v.label || '';
                const price = v.prices[0]; // erster Preis (Restaurant-Level)
                if (!price) return null;
                return (
                  <div key={v.id} className="flex items-baseline justify-between">
                    <span className="text-sm opacity-60">{label}</span>
                    <span className="text-lg font-bold tabular-nums" style={{ fontFamily: 'var(--mc-price-font, inherit)' }}>{formatPrice(Number(price.sellPrice), 'EUR', priceLocale)}</span>
                  </div>
                );
              })}
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
              {grapeNodes.length > 0 && <div className="col-span-2"><p className="text-[10px] uppercase tracking-wider opacity-40">{lang === 'de' ? 'Rebsorten' : 'Grape Varieties'}</p><p className="text-sm font-medium">{grapeNodes.join(', ')}</p></div>}
              {regionNodes.length > 0 && <div className="col-span-2"><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.region[lang]}</p><p className="text-sm font-medium">{regionNodes.join(' / ')}</p></div>}
              {styleNodes.length > 0 && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{lang === 'de' ? 'Stil' : 'Style'}</p><p className="text-sm font-medium">{styleNodes.join(', ')}</p></div>}
              {wp.aging && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.aging[lang]}</p><p className="text-sm font-medium">{wp.aging}</p></div>}
              {wp.servingTemp && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.servingTemp[lang]}</p><p className="text-sm font-medium">{wp.servingTemp}</p></div>}
              {wp.certification && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.certification[lang]}</p><p className="text-sm font-medium">{wp.certification}</p></div>}
            </div>
            {wp.tastingNotes && <div className="mt-4 border-t pt-4"><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.tasting[lang]}</p><p className="mt-1 text-sm leading-relaxed opacity-70">{wp.tastingNotes}</p></div>}
            {wp.foodPairing && <div className="mt-4 border-t pt-4"><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.foodPairing[lang]}</p><p className="mt-1 text-sm leading-relaxed opacity-70">{wp.foodPairing}</p></div>}
          </div>
        )}

        {/* Beverage Detail */}
        {bd && (
          <div className="mb-6 rounded-xl border bg-white p-5 shadow-sm">
            <div className="grid grid-cols-2 gap-3">
              {bd.brand && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{lang === 'de' ? 'Marke' : 'Brand'}</p><p className="text-sm font-medium">{bd.brand}</p></div>}
              {bd.alcoholContent && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{lang === 'de' ? 'Alkoholgehalt' : 'Alcohol'}</p><p className="text-sm font-medium">{Number(bd.alcoholContent)}% vol.</p></div>}
              {bd.servingStyle && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{lang === 'de' ? 'Servierart' : 'Serving Style'}</p><p className="text-sm font-medium">{bd.servingStyle}</p></div>}
              {bd.garnish && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{lang === 'de' ? 'Garnitur' : 'Garnish'}</p><p className="text-sm font-medium">{bd.garnish}</p></div>}
              {bd.glassType && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{lang === 'de' ? 'Glas' : 'Glass'}</p><p className="text-sm font-medium">{bd.glassType}</p></div>}
            </div>
          </div>
        )}

        {/* Allergens */}
        {product.allergens.length > 0 && (
          <div className="mb-6 rounded-xl border bg-white p-5 shadow-sm">
            <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider opacity-40">{ui.allergens[lang]}</h2>
            <div className="flex flex-wrap gap-2">
              {product.allergens.map((a: any) => (
                <span key={a.allergen.id} className="rounded-lg bg-amber-50 px-3 py-1.5 text-xs font-medium text-amber-800">
                  {a.allergen.icon && <span className="mr-1 material-symbols-outlined text-sm align-middle">{a.allergen.icon}</span>}
                  {t(a.allergen.translations)}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Tags */}
        {product.tags.length > 0 && (
          <div className="mb-6 flex flex-wrap gap-2">
            {product.tags.map((tg: any) => (
              <span key={tg.id} className="rounded-full border px-3 py-1.5 text-xs font-medium" style={{ borderColor: '#e5e7eb', color: '#6b7280' }}>
                {tg.tag}
              </span>
            ))}
          </div>
        )}
      </main>

      <Suspense fallback={null}>
        <LanguageSwitcher />
      </Suspense>
    </div>
  );
}
