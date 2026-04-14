import { notFound } from 'next/navigation';
import { Suspense } from 'react';
import prisma from '@/lib/prisma';
import Link from 'next/link';
import LanguageSwitcher from '@/components/language-switcher';
import MenuContent from '@/components/menu-content';
import { resolveMenuDigitalConfig, configToCssVars } from '@/lib/template-resolver';

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
      template: true,
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
  const digitalConfig = resolveMenuDigitalConfig(menu as any);
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
