// @ts-nocheck
import { notFound } from 'next/navigation';
import { Suspense } from 'react';
import prisma from '@/lib/prisma';
import Link from 'next/link';
import { formatPrice } from '@/lib/utils';
import LanguageSwitcher from '@/components/language-switcher';

const hlLabels: Record<string, Record<string, string>> = {
  RECOMMENDATION: { de: 'Empfehlung', en: 'Recommended' },
  NEW: { de: 'Neu', en: 'New' },
  PREMIUM: { de: 'Premium', en: 'Premium' },
  BESTSELLER: { de: 'Bestseller', en: 'Bestseller' },
  SIGNATURE: { de: 'Signature', en: 'Signature' },
};

const ui: Record<string, Record<string, string>> = {
  back: { de: 'Zurück zur Karte', en: 'Back to menu' },
  soldOut: { de: 'Ausverkauft', en: 'Sold out' },
  winery: { de: 'Weingut', en: 'Winery' },
  vintage: { de: 'Jahrgang', en: 'Vintage' },
  serving: { de: 'Trinktemperatur', en: 'Serving Temperature' },
  tasting: { de: 'Verkostungsnotizen', en: 'Tasting Notes' },
  foodPairing: { de: 'Speiseempfehlung', en: 'Food Pairing' },
  allergens: { de: 'Allergene', en: 'Allergens' },
  prices: { de: 'Preise', en: 'Prices' },
  wineProfile: { de: 'Weinprofil', en: 'Wine Profile' },
  certification: { de: 'Zertifizierung', en: 'Certification' },
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
    const found = translations.find((tr: any) => (tr.language || tr.languageCode) === lang);
    const fb = translations.find((tr: any) => (tr.language || tr.languageCode) === 'de');
    return (found?.[field] || fb?.[field]) ?? '';
  };

  const tenant = await prisma.tenant.findUnique({ where: { slug: params.tenant } });
  if (!tenant) return notFound();
  const location = await prisma.location.findUnique({ where: { tenantId_slug: { tenantId: tenant.id, slug: params.location } } });
  if (!location) return notFound();

  // v2: Produkt mit allen Varianten und Preisen
  const product = await prisma.product.findUnique({
    where: { id: params.itemId },
    include: {
      translations: true,
      variants: {
        include: {
          fillQuantity: true,
          prices: { include: { priceLevel: true } },
        },
        orderBy: { sortOrder: 'asc' },
      },
      wineProfile: true,
      beverageDetail: true,
      allergens: { include: { allergen: { include: { translations: true } } } },
      tags: true,
      taxonomy: { include: { node: { include: { translations: true } } } },
      productMedia: { include: { media: true }, orderBy: { sortOrder: 'asc' } },
    },
  });
  if (!product) return notFound();

  const menu = await prisma.menu.findUnique({
    where: { locationId_slug: { locationId: location.id, slug: params.menu } },
    include: { translations: true },
  });
  if (!menu) return notFound();

  // v2: Sektion über variant-basiertes Placement finden
  const placement = await prisma.menuPlacement.findFirst({
    where: {
      variant: { productId: product.id },
      section: { menuId: menu.id },
    },
    include: { section: true },
  });
  const sectionSlug = placement?.section?.slug || '';

  const theme = await prisma.theme.findFirst({ where: { tenantId: tenant.id, isActive: true } });
  const themeCfg: any = theme?.config ?? {};
  const accentColor = themeCfg.accentColor || '#8B6914';
  const langParam = lang === 'en' ? '?lang=en' : '';
  const priceLocale = lang === 'en' ? 'en-GB' : 'de-AT';

  const pName = t(product.translations);
  const pShort = t(product.translations, 'shortDescription');
  const pLong = t(product.translations, 'longDescription');
  const pServing = t(product.translations, 'servingSuggestion');
  const menuName = t(menu.translations);
  const wp = product.wineProfile;

  return (
    <div className="min-h-screen pb-16" style={{ background: themeCfg.backgroundColor || '#FAFAF8', color: themeCfg.textColor || '#1a1a1a' }}>
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
            <h1 className="text-2xl font-bold tracking-tight" style={{fontFamily: "'Playfair Display', serif"}}>{pName}</h1>
            {product.highlightType && product.highlightType !== 'NONE' && (
              <span className="rounded-full px-3 py-1 text-xs font-semibold text-white" style={{backgroundColor: accentColor}}>{hlLabels[product.highlightType]?.[lang] || ''}</span>
            )}
            {product.status === 'ARCHIVED' && <span className="rounded-full bg-red-100 px-3 py-1 text-xs font-medium text-red-600">{ui.soldOut[lang]}</span>}
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

        {/* v2: Preise über Varianten */}
        {product.variants.length > 0 && (
          <div className="mb-6 rounded-xl border bg-white p-5 shadow-sm">
            <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider opacity-40">{ui.prices[lang]}</h2>
            <div className="space-y-2">
              {product.variants.map((v: any) => {
                const price = v.prices?.[0];
                if (!price) return null;
                const label = v.fillQuantity?.label || v.label || 'Standard';
                return (
                  <div key={v.id} className="flex items-baseline justify-between">
                    <span className="text-sm opacity-60">{label}</span>
                    <span className="text-lg font-bold tabular-nums" style={{fontFamily: "'Playfair Display', serif"}}>
                      {formatPrice(Number(price.sellPrice), 'EUR', priceLocale)}
                    </span>
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
              {wp.aging && <div className="col-span-2"><p className="text-[10px] uppercase tracking-wider opacity-40">Ausbau</p><p className="text-sm font-medium">{wp.aging}</p></div>}
              {wp.servingTemp && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.serving[lang]}</p><p className="text-sm font-medium">{wp.servingTemp}</p></div>}
              {wp.certification && <div><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.certification[lang]}</p><p className="text-sm font-medium">{wp.certification}</p></div>}
            </div>
            {wp.tastingNotes && <div className="mt-4 border-t pt-4"><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.tasting[lang]}</p><p className="mt-1 text-sm leading-relaxed opacity-70">{wp.tastingNotes}</p></div>}
            {wp.foodPairing && <div className="mt-4 border-t pt-4"><p className="text-[10px] uppercase tracking-wider opacity-40">{ui.foodPairing[lang]}</p><p className="mt-1 text-sm leading-relaxed opacity-70">{wp.foodPairing}</p></div>}
          </div>
        )}

        {/* Taxonomy Tags */}
        {product.taxonomy && product.taxonomy.length > 0 && (
          <div className="mb-6 flex flex-wrap gap-2">
            {product.taxonomy.map((pt: any) => {
              const nodeName = t(pt.node.translations);
              return (
                <span key={pt.nodeId} className="rounded-full border px-3 py-1.5 text-xs font-medium" style={{borderColor: '#e5e7eb', color: '#6b7280'}}>
                  {nodeName}
                </span>
              );
            })}
          </div>
        )}

        {/* Allergens */}
        {product.allergens && product.allergens.length > 0 && (
          <div className="mb-6 rounded-xl border bg-white p-5 shadow-sm">
            <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider opacity-40">{ui.allergens[lang]}</h2>
            <div className="flex flex-wrap gap-2">
              {product.allergens.map((a: any) => (
                <span key={a.allergen.id} className="inline-flex items-center gap-1 rounded-lg bg-amber-50 px-3 py-1.5 text-xs font-medium text-amber-800">
                  {a.allergen.icon && (
                    <span className="material-symbols-outlined" style={{ fontSize: 14, lineHeight: 1 }}>
                      {a.allergen.icon}
                    </span>
                  )}
                  <span>{t(a.allergen.translations)}</span>
                </span>
              ))}
            </div>
          </div>
        )}

        {/* Tags */}
        {product.tags && product.tags.length > 0 && (
          <div className="mb-6 flex flex-wrap gap-2">
            {product.tags.map((tg: any) => (
              <span key={tg.id} className="rounded-full border px-3 py-1.5 text-xs font-medium" style={{borderColor: '#e5e7eb', color: '#6b7280'}}>
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
