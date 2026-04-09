import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import ProductList from '@/components/admin/product-list';

export default async function ProductsPage() {
  const session = await getServerSession(authOptions);
  if (!session) return null;
  const tid = session.user.tenantId;

  const [products, groups, counts] = await Promise.all([
    prisma.product.findMany({
      where: { tenantId: tid },
      include: {
        translations: true,
        productGroup: { include: { translations: true, parent: { include: { translations: true } } } },
        prices: { include: { fillQuantity: true }, orderBy: { sortOrder: 'asc' } },
        productWineProfile: { select: { winery: true, vintage: true, region: true, country: true } },
        productBevDetail: { select: { brand: true, category: true } },
      },
      orderBy: [{ productGroup: { sortOrder: 'asc' } }, { sortOrder: 'asc' }],
    }),
    prisma.productGroup.findMany({
      where: { tenantId: tid },
      include: { translations: true, parent: { include: { translations: true } } },
      orderBy: { sortOrder: 'asc' },
    }),
    prisma.product.groupBy({
      by: ['type'],
      where: { tenantId: tid },
      _count: true,
    }),
  ]);

  const serialized = products.map(p => ({
    id: p.id,
    sku: p.sku,
    type: p.type,
    status: p.status,
    isHighlight: p.isHighlight,
    name: p.translations.find(t => t.languageCode === 'de')?.name || p.translations[0]?.name || '',
    nameEn: p.translations.find(t => t.languageCode === 'en')?.name || '',
    shortDesc: p.translations.find(t => t.languageCode === 'de')?.shortDescription || '',
    groupName: p.productGroup?.translations.find(t => t.languageCode === 'de')?.name || '',
    groupSlug: p.productGroup?.slug || '',
    parentGroupName: p.productGroup?.parent?.translations.find(t => t.languageCode === 'de')?.name || '',
    mainPrice: p.prices[0] ? Number(p.prices[0].price) : null,
    mainPriceLabel: p.prices[0]?.fillQuantity?.label || '',
    priceCount: p.prices.length,
    winery: p.productWineProfile?.winery || null,
    vintage: p.productWineProfile?.vintage || null,
    region: p.productWineProfile?.region || null,
    country: p.productWineProfile?.country || null,
    brand: p.productBevDetail?.brand || null,
    bevCategory: p.productBevDetail?.category || null,
  }));

  const groupOptions = groups.map(g => ({
    slug: g.slug,
    name: g.translations.find(t => t.languageCode === 'de')?.name || g.slug,
    parentName: g.parent?.translations.find(t => t.languageCode === 'de')?.name || null,
    hasChildren: groups.some(c => c.parentId === g.id),
  }));

  const typeCounts = Object.fromEntries(counts.map(c => [c.type, c._count]));

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold" style={{fontFamily: "'Playfair Display', serif"}}>Produkte</h1>
          <p className="text-sm text-gray-400 mt-1">{products.length} Produkte</p>
        </div>
      </div>
      <ProductList products={serialized} groups={groupOptions} typeCounts={typeCounts} />
    </div>
  );
}
