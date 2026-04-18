// @ts-nocheck
import { notFound } from 'next/navigation';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import MenuEditor from '@/components/admin/menu-editor';

export default async function MenuDetailPage({ params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return null;
  const tid = session.user.tenantId;

  const t = (translations: any[], field = 'name') => {
    const de = translations?.find((tr: any) => tr.language === 'de' || tr.languageCode === 'de');
    return de?.[field] || translations?.[0]?.[field] || '';
  };

  let menu: any = null;
  try {
    menu = await prisma.menu.findUnique({
      where: { id: params.id },
      include: {
        translations: true,
        location: { include: { tenant: true } },
        sections: {
          orderBy: { sortOrder: 'asc' },
          include: {
            translations: { where: { language: 'de' } },
            placements: {
              orderBy: { sortOrder: 'asc' },
              include: {
                variant: {
                  include: {
                    product: {
                      include: {
                        translations: { where: { language: 'de' } },
                        wineProfile: { select: { winery: true, vintage: true } },
                      },
                    },
                    fillQuantity: true,
                    prices: { take: 1 },
                  },
                },
              },
            },
          },
        },
        qrCodes: true,
      },
    });
  } catch (e: any) {
    console.error('Menu detail query error:', e.message);
  }
  if (!menu) return notFound();

  let categories: any[] = [];
  let allProducts: any[] = [];

  try {
    [categories, allProducts] = await Promise.all([
      prisma.taxonomyNode.findMany({
        where: { tenantId: tid, type: 'CATEGORY' },
        include: {
          translations: { where: { language: 'de' } },
          parent: { include: { translations: { where: { language: 'de' } } } },
        },
        orderBy: { sortOrder: 'asc' },
      }),
      prisma.product.findMany({
        where: { tenantId: tid, status: { not: 'ARCHIVED' } },
        include: {
          translations: { where: { language: 'de' } },
          taxonomy: {
            include: { node: { include: { translations: { where: { language: 'de' } } } } },
          },
          variants: {
            orderBy: { sortOrder: 'asc' },
            include: {
              fillQuantity: true,
              prices: { take: 1 },
            },
          },
          wineProfile: { select: { winery: true, vintage: true } },
        },
        orderBy: { updatedAt: 'desc' },
      }),
    ]);
  } catch (e: any) {
    console.error('Menu detail options error:', e.message);
  }

  const tenant = menu.location.tenant;

  const menuData = {
    id: menu.id,
    name: t(menu.translations),
    slug: menu.slug,
    type: menu.type,
    locationName: menu.location.name,
    isActive: menu.status === 'ACTIVE',
    status: menu.status,
    publicUrl: `/${tenant.slug}/${menu.location.slug}/${menu.slug}`,
    templateId: menu.templateId || null,
    qrCodes: (menu.qrCodes || []).map((q: any) => ({ id: q.id, label: q.label, shortCode: q.shortCode })),
    sections: menu.sections.map((s: any) => ({
      id: s.id,
      slug: s.slug,
      name: t(s.translations),
      icon: s.icon,
      placements: s.placements.map((pl: any) => {
        const v = pl.variant;
        const p = v?.product;
        return {
          id: pl.id,
          variantId: v?.id || '',
          productId: p?.id || '',
          name: t(p?.translations || []),
          variantLabel: v?.fillQuantity?.label || v?.label || null,
          winery: p?.wineProfile?.winery || null,
          vintage: p?.wineProfile?.vintage || null,
          price: pl.priceOverride ? Number(pl.priceOverride) : v?.prices?.[0] ? Number(v.prices[0].sellPrice) : null,
          type: p?.type || 'FOOD',
          sortOrder: pl.sortOrder,
          isVisible: pl.isVisible,
        };
      }),
    })),
  };

  // v2: Produkte mit allen Varianten als flache Liste
  const browserProducts = allProducts.flatMap((p: any) => {
    const catNode = p.taxonomy?.find((tx: any) => tx.node?.type === 'CATEGORY')?.node;
    const groupName = catNode ? t(catNode.translations) : '';
    const groupSlug = catNode?.slug || '';

    return (p.variants || []).map((v: any) => ({
      id: v.id, // variantId als Schlüssel
      productId: p.id,
      name: t(p.translations),
      variantLabel: v.fillQuantity?.label || v.label || null,
      isDefault: v.isDefault,
      type: p.type,
      groupName,
      groupSlug,
      price: v.prices?.[0] ? Number(v.prices[0].sellPrice) : null,
      winery: p.wineProfile?.winery || null,
      vintage: p.wineProfile?.vintage || null,
      status: p.status,
    }));
  });

  const groupOpts = categories.map((g: any) => ({
    slug: g.slug,
    name: t(g.translations),
    parentName: g.parent ? t(g.parent.translations) : null,
  }));

  return <MenuEditor menu={menuData} allProducts={browserProducts} groups={groupOpts} />;
}
