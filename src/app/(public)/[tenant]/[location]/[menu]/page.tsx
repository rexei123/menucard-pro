// @ts-nocheck
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
    const found = translations.find((tr: any) => (tr.language || tr.languageCode) === lang);
    const fb = translations.find((tr: any) => (tr.language || tr.languageCode) === 'de');
    return (found?.[field] || fb?.[field]) ?? '';
  };

  const tenant = await prisma.tenant.findUnique({ where: { slug: params.tenant } });
  if (!tenant) return notFound();

  const location = await prisma.location.findUnique({ where: { tenantId_slug: { tenantId: tenant.id, slug: params.location } } });
  if (!location) return notFound();

  // v2: Verschachtelte Sektionen bis 3 Ebenen tief, Placements über variant→product
  const menu = await prisma.menu.findUnique({
    where: { locationId_slug: { locationId: location.id, slug: params.menu } },
    include: {
      translations: true,
      template: true,
      sections: {
        orderBy: { sortOrder: 'asc' },
        include: {
          translations: true,
          children: {
            orderBy: { sortOrder: 'asc' },
            include: {
              translations: true,
              children: {
                orderBy: { sortOrder: 'asc' },
                include: {
                  translations: true,
                  placements: {
                    where: { isVisible: true },
                    orderBy: { sortOrder: 'asc' },
                    include: {
                      variant: {
                        include: {
                          product: {
                            include: {
                              translations: true,
                              wineProfile: true,
                              allergens: { include: { allergen: { include: { translations: true } } } },
                              tags: true,
                              productMedia: { where: { isPrimary: true }, take: 1 },
                            },
                          },
                          fillQuantity: true,
                          prices: { orderBy: { priceLevel: { sortOrder: 'asc' } } },
                        },
                      },
                    },
                  },
                },
              },
              placements: {
                where: { isVisible: true },
                orderBy: { sortOrder: 'asc' },
                include: {
                  variant: {
                    include: {
                      product: {
                        include: {
                          translations: true,
                          wineProfile: true,
                          allergens: { include: { allergen: { include: { translations: true } } } },
                          tags: true,
                          productMedia: { where: { isPrimary: true }, take: 1 },
                        },
                      },
                      fillQuantity: true,
                      prices: { orderBy: { priceLevel: { sortOrder: 'asc' } } },
                    },
                  },
                },
              },
            },
          },
          placements: {
            where: { isVisible: true },
            orderBy: { sortOrder: 'asc' },
            include: {
              variant: {
                include: {
                  product: {
                    include: {
                      translations: true,
                      wineProfile: true,
                      allergens: { include: { allergen: { include: { translations: true } } } },
                      tags: true,
                      productMedia: { where: { isPrimary: true }, take: 1 },
                    },
                  },
                  fillQuantity: true,
                  prices: { orderBy: { priceLevel: { sortOrder: 'asc' } } },
                },
              },
            },
          },
        },
      },
    },
  });
  if (!menu) return notFound();

  const digitalConfig = resolveMenuDigitalConfig(menu as any);
  const cssVars = configToCssVars(digitalConfig);
  const menuName = digitalConfig.header.title || t(menu.translations);
  const subtitle = digitalConfig.header.subtitle || null;
  const langParam = lang === 'en' ? '?lang=en' : '';
  const priceLocale = lang === 'en' ? 'en-GB' : 'de-AT';
  const isWineMenu = menu.type === 'WINE';

  // v2: Serialize placement — variant→product statt direkt product
  function serializePlacement(pl: any) {
    const v = pl.variant;
    const p = v.product;
    const firstPrice = v.prices?.[0];
    return {
      id: p.id,
      variantId: v.id,
      isHighlight: !!pl.highlightType && pl.highlightType !== 'NONE',
      highlightType: pl.highlightType,
      isSoldOut: p.status === 'ARCHIVED' || v.status === 'ARCHIVED' || !pl.isVisible,
      translations: p.translations.map((pt: any) => ({
        languageCode: pt.language || pt.languageCode,
        name: pt.name,
        shortDescription: pt.shortDescription,
        longDescription: pt.longDescription,
      })),
      // v2: Varianten-Label als zusätzliche Info (z.B. "Glas 0,125l")
      variantLabel: v.fillQuantity?.label || v.label || null,
      priceVariants: [{
        id: v.id,
        label: v.fillQuantity?.label || v.label || 'Standard',
        price: pl.priceOverride ? Number(pl.priceOverride) : (firstPrice ? Number(firstPrice.sellPrice) : 0),
        volume: v.fillQuantity?.volumeMl ? `${v.fillQuantity.volumeMl}ml` : null,
        isDefault: v.isDefault,
      }],
      allergens: (p.allergens || []).map((a: any) => ({
        allergen: {
          id: a.allergen.id,
          icon: a.allergen.icon,
          translations: a.allergen.translations.map((at: any) => ({
            languageCode: at.language || at.languageCode,
            name: at.name,
          })),
        },
      })),
      tags: (p.tags || []).map((tg: any) => ({
        tag: { id: tg.id, icon: null, color: null, translations: [{ languageCode: 'de', name: tg.tag }] },
      })),
      image: (() => {
        const pm = p.productMedia?.[0];
        if (!pm) return null;
        const url = pm.url || '';
        return url.replace('/uploads/large/', '/uploads/medium/');
      })(),
      wineProfile: p.wineProfile ? {
        winery: p.wineProfile.winery,
        vintage: p.wineProfile.vintage,
        tastingNotes: p.wineProfile.tastingNotes,
        servingTemp: p.wineProfile.servingTemp,
        foodPairing: p.wineProfile.foodPairing,
      } : null,
    };
  }

  // v2: Flattening — nur Sektionen mit Placements ausgeben (rekursiv)
  function flattenSections(sections: any[]): any[] {
    const result: any[] = [];
    function walk(s: any) {
      const items = (s.placements || []).map(serializePlacement);
      if (items.length > 0) {
        result.push({
          id: s.id,
          slug: s.slug,
          icon: s.icon,
          translations: s.translations.map((st: any) => ({
            languageCode: st.language || st.languageCode,
            name: st.name,
            description: st.description,
          })),
          items,
        });
      }
      (s.children || []).forEach(walk);
    }
    sections.forEach(walk);
    return result;
  }

  const serializedSections = flattenSections(
    menu.sections.filter((s: any) => !s.parentId)
  );

  const headerHeight = digitalConfig.header.height;
  const headerClasses = headerHeight === 'large'
    ? 'relative min-h-[40vh] flex flex-col items-center justify-center'
    : headerHeight === 'small'
      ? 'px-6 py-4 text-center'
      : 'px-6 py-6 text-center';

  return (
    <div className="min-h-screen pb-16" style={{ ...cssVars, background: 'var(--mc-bg)', color: 'var(--mc-h3-color)' } as React.CSSProperties}>
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
