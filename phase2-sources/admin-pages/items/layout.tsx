import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import ProductListPanel from '@/components/admin/product-list-panel';

export default async function ItemsLayout({ children }: { children: React.ReactNode }) {
  const session = await getServerSession(authOptions);
  if (!session) return null;
  const tid = session.user.tenantId;

  const [products, groups] = await Promise.all([
    prisma.product.findMany({
      where: { tenantId: tid },
      include: {
        translations: { where: { languageCode: 'de' }, select: { name: true } },
        productGroup: { include: { translations: { where: { languageCode: 'de' }, select: { name: true } } } },
        prices: { take: 1, orderBy: { sortOrder: 'asc' }, select: { price: true } },
        productWineProfile: { select: { winery: true, vintage: true } },
        placements: { select: { menuSection: { select: { menu: { select: { translations: { where: { languageCode: 'de' }, select: { name: true } } } } } } } },
      },
      orderBy: [{ sortOrder: 'asc' }],
    }),
    prisma.productGroup.findMany({
      where: { tenantId: tid },
      include: { translations: { where: { languageCode: 'de' }, select: { name: true } }, parent: { include: { translations: { where: { languageCode: 'de' }, select: { name: true } } } } },
      orderBy: { sortOrder: 'asc' },
    }),
  ]);

  const serialized = products.map(p => ({
    id: p.id,
    sku: p.sku,
    type: p.type,
    status: p.status,
    name: p.translations[0]?.name || '',
    groupName: p.productGroup?.translations[0]?.name || '',
    groupSlug: p.productGroup?.slug || '',
    mainPrice: p.prices[0] ? Number(p.prices[0].price) : null,
    priceCount: p.prices.length,
    winery: p.productWineProfile?.winery || null,
    vintage: p.productWineProfile?.vintage || null,
    menuNames: Array.from(new Set(p.placements.map(pl => pl.menuSection.menu.translations[0]?.name).filter(Boolean))),
  }));

  const groupOpts = groups
    .filter(g => products.some(p => p.productGroupId === g.id))
    .map(g => ({
      slug: g.slug,
      name: g.translations[0]?.name || g.slug,
      parentName: g.parent?.translations[0]?.name || null,
    }));

  return (
    <div className="flex flex-1 overflow-hidden">
      <ProductListPanel products={serialized} groups={groupOpts} />
      <main className="flex-1 overflow-y-auto p-6">
        {children}
      </main>
    </div>
  );
}
