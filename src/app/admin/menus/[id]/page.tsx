import { notFound } from 'next/navigation';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import MenuEditor from '@/components/admin/menu-editor';

export default async function MenuDetailPage({ params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return null;
  const tid = session.user.tenantId;

  const menu = await prisma.menu.findUnique({
    where: { id: params.id },
    include: {
      translations: true,
      location: { include: { tenant: true } },
      sections: {
        where: { isActive: true }, orderBy: { sortOrder: 'asc' },
        include: {
          translations: { where: { languageCode: 'de' } },
          placements: {
            orderBy: { sortOrder: 'asc' },
            include: { product: { include: {
              translations: { where: { languageCode: 'de' } },
              prices: { take: 1, orderBy: { sortOrder: 'asc' } },
              productWineProfile: { select: { winery: true, vintage: true } },
            } } },
          },
        },
      },
      qrCodes: true,
    },
  });
  if (!menu) return notFound();

  const allGroups = await prisma.productGroup.findMany({
    where: { tenantId: tid },
    include: { translations: { where: { languageCode: 'de' } }, parent: { include: { translations: { where: { languageCode: 'de' } } } } },
    orderBy: { sortOrder: 'asc' },
  });

  const allProducts = await prisma.product.findMany({
    where: { tenantId: tid, status: { not: 'ARCHIVED' } },
    include: {
      translations: { where: { languageCode: 'de' } },
      productGroup: { include: { translations: { where: { languageCode: 'de' } } } },
      prices: { take: 1, orderBy: { sortOrder: 'asc' } },
      productWineProfile: { select: { winery: true, vintage: true } },
    },
    orderBy: { sortOrder: 'asc' },
  });

  const tenant = menu.location.tenant;

  const menuData = {
    id: menu.id, name: menu.translations.find(t => t.languageCode === 'de')?.name || menu.slug,
    slug: menu.slug, type: menu.type, locationName: menu.location.name,
    isActive: menu.isActive, publicUrl: `/${tenant.slug}/${menu.location.slug}/${menu.slug}`,
    qrCodes: menu.qrCodes.map(q => ({ id: q.id, label: q.label, shortCode: q.shortCode })),
    sections: menu.sections.map(s => ({
      id: s.id, slug: s.slug, name: s.translations[0]?.name || s.slug, icon: s.icon,
      placements: s.placements.map(pl => ({
        id: pl.id, productId: pl.product.id,
        name: pl.product.translations[0]?.name || '',
        winery: pl.product.productWineProfile?.winery || null,
        vintage: pl.product.productWineProfile?.vintage || null,
        price: pl.priceOverride ? Number(pl.priceOverride) : pl.product.prices[0] ? Number(pl.product.prices[0].price) : null,
        type: pl.product.type, sortOrder: pl.sortOrder, isVisible: pl.isVisible,
      })),
    })),
  };

  const browserProducts = allProducts.map(p => ({
    id: p.id, name: p.translations[0]?.name || '',
    type: p.type, groupName: p.productGroup?.translations[0]?.name || '',
    groupSlug: p.productGroup?.slug || '',
    price: p.prices[0] ? Number(p.prices[0].price) : null,
    winery: p.productWineProfile?.winery || null,
    vintage: p.productWineProfile?.vintage || null,
    status: p.status,
  }));

  const groupOpts = allGroups
    .filter(g => allProducts.some(p => p.productGroupId === g.id))
    .map(g => ({ slug: g.slug, name: g.translations[0]?.name || g.slug, parentName: g.parent?.translations[0]?.name || null }));

  return <MenuEditor menu={menuData} allProducts={browserProducts} groups={groupOpts} />;
}
