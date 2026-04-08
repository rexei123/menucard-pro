import { notFound } from 'next/navigation';
import { Suspense } from 'react';
import prisma from '@/lib/prisma';
import Link from 'next/link';
import LanguageSwitcher from '@/components/language-switcher';
import MenuContent from '@/components/menu-content';

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
        items: { where: { isActive: true }, orderBy: { sortOrder: 'asc' }, include: {
          translations: true,
          priceVariants: { orderBy: { sortOrder: 'asc' } },
          allergens: { include: { allergen: { include: { translations: true } } } },
          tags: { include: { tag: { include: { translations: true } } } },
          wineProfile: true,
        } },
      } },
    },
  });
  if (!menu) return notFound();
  const theme = await prisma.theme.findFirst({ where: { tenantId: tenant.id, isActive: true } });
  const menuName = t(menu.translations);
  const langParam = lang === 'en' ? '?lang=en' : '';
  const priceLocale = lang === 'en' ? 'en-GB' : 'de-AT';
  const accentColor = theme?.accentColor || '#8B6914';
  const isWineMenu = menu.type === 'WINE';

  // Serialize sections for client component (convert Decimal to number)
  const serializedSections = menu.sections.map(s => ({
    id: s.id,
    slug: s.slug,
    icon: s.icon,
    translations: s.translations.map(st => ({ languageCode: st.languageCode, name: st.name, description: st.description })),
    items: s.items.map(item => ({
      id: item.id,
      isHighlight: item.isHighlight,
      highlightType: item.highlightType,
      isSoldOut: item.isSoldOut,
      translations: item.translations.map(it => ({ languageCode: it.languageCode, name: it.name, shortDescription: it.shortDescription, longDescription: it.longDescription })),
      priceVariants: item.priceVariants.map(pv => ({ id: pv.id, label: pv.label, price: Number(pv.price), volume: pv.volume, isDefault: pv.isDefault })),
      allergens: item.allergens.map(a => ({ allergen: { id: a.allergen.id, icon: a.allergen.icon, translations: a.allergen.translations.map(at => ({ languageCode: at.languageCode, name: at.name })) } })),
      tags: item.tags.map(tg => ({ tag: { id: tg.tag.id, icon: tg.tag.icon, color: tg.tag.color, translations: tg.tag.translations.map(tt => ({ languageCode: tt.languageCode, name: tt.name })) } })),
      wineProfile: item.wineProfile ? { winery: item.wineProfile.winery, vintage: item.wineProfile.vintage, grapeVarieties: item.wineProfile.grapeVarieties, region: item.wineProfile.region, country: item.wineProfile.country, appellation: item.wineProfile.appellation, style: item.wineProfile.style, body: item.wineProfile.body, sweetness: item.wineProfile.sweetness } : null,
    })),
  }));

  return (
    <div className="min-h-screen pb-16" style={{ background: theme?.backgroundColor || '#FAFAF8', color: theme?.textColor || '#1a1a1a' }}>
      <header className="border-b px-6 py-6 text-center">
        <Link href={`/${tenant.slug}/${location.slug}${langParam}`} className="text-xs uppercase tracking-widest opacity-40">{tenant.name}</Link>
        <h1 className="mt-2 text-3xl font-bold tracking-tight" style={{fontFamily: "'Playfair Display', serif"}}>{menuName}</h1>
      </header>

      <MenuContent
        sections={serializedSections}
        lang={lang}
        langParam={langParam}
        priceLocale={priceLocale}
        accentColor={accentColor}
        tenantSlug={tenant.slug}
        locationSlug={location.slug}
        menuSlug={menu.slug}
        isWineMenu={isWineMenu}
      />

      <div className="mx-auto max-w-2xl px-4">
        <div className="border-t py-8 text-center">
          <p className="text-xs opacity-30">{ui.prices[lang]}</p>
          <p className="mt-1 text-xs opacity-20">{ui.powered[lang]}</p>
        </div>
      </div>

      <Suspense fallback={null}>
        <LanguageSwitcher />
      </Suspense>
    </div>
  );
}
