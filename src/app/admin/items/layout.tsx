// @ts-nocheck
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import ProductListPanel from '@/components/admin/product-list-panel';

export default async function ItemsLayout({ children }: { children: React.ReactNode }) {
  const session = await getServerSession(authOptions);
  if (!session) return null;
  const tid = session.user.tenantId;

  let products: any[] = [];
  let categories: any[] = [];

  try {
    [products, categories] = await Promise.all([
      prisma.product.findMany({
        where: { tenantId: tid },
        include: {
          translations: true,
          taxonomy: {
            include: { node: { include: { translations: true } } },
          },
          variants: {
            where: { isDefault: true },
            take: 1,
            include: { prices: { take: 1 } },
          },
          wineProfile: true,
        },
        orderBy: { updatedAt: 'desc' },
      }),
      prisma.taxonomyNode.findMany({
        where: { tenantId: tid, type: 'CATEGORY' },
        include: {
          translations: true,
          parent: { include: { translations: true } },
        },
        orderBy: { sortOrder: 'asc' },
      }),
    ]);
  } catch (e: any) {
    console.error('Items layout query error:', e.message);
  }

  const serialized = products.map((p: any) => {
    const catTax = p.taxonomy?.find((t: any) => t.node?.type === 'CATEGORY');
    const catNode = catTax?.node;
    const catName = catNode?.translations?.find((t: any) => t.language === 'de')?.name || '';
    const defVariant = p.variants?.[0];
    const productName = p.translations?.find((t: any) => t.language === 'de')?.name
      || p.translations?.find((t: any) => t.languageCode === 'de')?.name
      || p.translations?.[0]?.name || '';

    return {
      id: p.id,
      sku: p.sku,
      type: p.type,
      status: p.status,
      name: productName,
      groupName: catName,
      groupSlug: catNode?.slug || '',
      mainPrice: defVariant?.prices?.[0]?.sellPrice ? Number(defVariant.prices[0].sellPrice) : null,
      priceCount: defVariant?.prices?.length || 0,
      winery: p.wineProfile?.winery || null,
      vintage: p.wineProfile?.vintage || null,
      menuNames: [],
    };
  });

  const groupOpts = categories.map((g: any) => ({
    slug: g.slug,
    name: g.translations?.find((t: any) => t.language === 'de')?.name || g.slug,
    parentName: g.parent?.translations?.find((t: any) => t.language === 'de')?.name || null,
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
