import { notFound } from 'next/navigation';
import prisma from '@/lib/prisma';
import Link from 'next/link';
import { formatPrice } from '@/lib/utils';

export default async function MenuPage({ params }: { params: { tenant: string; location: string; menu: string } }) {
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
  const menuName = menu.translations.find(t => t.languageCode === 'de')?.name || menu.slug;
  const hl: Record<string, string> = { RECOMMENDATION: 'Empfehlung', NEW: 'Neu', POPULAR: 'Beliebt', PREMIUM: 'Premium', SEASONAL: 'Saison', CHEFS_CHOICE: "Chef's Choice" };

  return (
    <div className="min-h-screen pb-16" style={{ background: theme?.backgroundColor || '#FAFAF8', color: theme?.textColor || '#1a1a1a' }}>
      <header className="border-b px-6 py-6 text-center">
        <Link href={`/${tenant.slug}/${location.slug}`} className="text-xs uppercase tracking-widest opacity-40">{tenant.name}</Link>
        <h1 className="mt-2 text-3xl font-bold tracking-tight" style={{fontFamily: "'Playfair Display', serif"}}>{menuName}</h1>
      </header>
      {menu.sections.length > 1 && (
        <nav className="sticky top-0 z-10 border-b bg-white/90 backdrop-blur-md">
          <div className="flex overflow-x-auto px-4 py-2 gap-1">
            {menu.sections.map(s => (
              <a key={s.id} href={`#${s.slug}`} className="flex-shrink-0 rounded-full px-4 py-2 text-sm font-medium hover:bg-black/5" style={{whiteSpace:'nowrap'}}>
                {s.icon && <span className="mr-1">{s.icon}</span>}{s.translations.find(t => t.languageCode === 'de')?.name || s.slug}
              </a>
            ))}
          </div>
        </nav>
      )}
      <main className="mx-auto max-w-2xl px-4">
        {menu.sections.map(section => {
          const sName = section.translations.find(t => t.languageCode === 'de')?.name || section.slug;
          return (
            <section key={section.id} id={section.slug} className="scroll-mt-16 py-8">
              <div className="mb-6 text-center">
                {section.icon && <span className="text-2xl">{section.icon}</span>}
                <h2 className="text-xl font-bold tracking-tight" style={{fontFamily: "'Playfair Display', serif"}}>{sName}</h2>
                <div className="mx-auto mt-3 h-px w-16" style={{backgroundColor: (theme?.accentColor || '#8B6914') + '40'}} />
              </div>
              <div className="space-y-2">
                {section.items.map(item => {
                  const iName = item.translations.find(t => t.languageCode === 'de')?.name || '';
                  const iDesc = item.translations.find(t => t.languageCode === 'de')?.shortDescription;
                  const defPrice = item.priceVariants.find(p => p.isDefault) || item.priceVariants[0];
                  const multiPrice = item.priceVariants.length > 1;
                  return (
                    <div key={item.id} className={`rounded-xl border bg-white p-4 shadow-sm ${item.isSoldOut ? 'opacity-50' : ''}`}>
                      <div className="flex items-start justify-between gap-3">
                        <div>
                          <div className="flex items-center gap-2 flex-wrap">
                            <h3 className="text-base font-semibold" style={{fontFamily: "'Playfair Display', serif"}}>{iName}</h3>
                            {item.isHighlight && item.highlightType && (
                              <span className="rounded-full px-2 py-0.5 text-[10px] font-semibold text-white" style={{backgroundColor: theme?.accentColor || '#8B6914'}}>{hl[item.highlightType] || ''}</span>
                            )}
                            {item.isSoldOut && <span className="rounded-full bg-red-100 px-2 py-0.5 text-[10px] font-medium text-red-600">Ausverkauft</span>}
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
                              {item.tags.map(t => (
                                <span key={t.tag.id} className="rounded-full bg-gray-100 px-2 py-0.5 text-[10px] font-medium">{t.tag.icon} {t.tag.translations.find(tr => tr.languageCode === 'de')?.name}</span>
                              ))}
                            </div>
                          )}
                        </div>
                      </div>
                      <div className="mt-3 flex flex-wrap items-baseline gap-3">
                        {multiPrice ? item.priceVariants.map(pv => (
                          <div key={pv.id} className="text-sm">
                            <span className="font-semibold tabular-nums">{formatPrice(Number(pv.price))}</span>
                            {(pv.label || pv.volume) && <span className="ml-1 text-xs opacity-40">{pv.label || pv.volume}</span>}
                          </div>
                        )) : defPrice && <span className="text-sm font-semibold tabular-nums">{formatPrice(Number(defPrice.price))}</span>}
                      </div>
                    </div>
                  );
                })}
              </div>
            </section>
          );
        })}
        <div className="border-t py-8 text-center">
          <p className="text-xs opacity-30">Alle Preise in Euro inkl. MwSt.</p>
          <p className="mt-1 text-xs opacity-20">Powered by MenuCard Pro</p>
        </div>
      </main>
    </div>
  );
}
