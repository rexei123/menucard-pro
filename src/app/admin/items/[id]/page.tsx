import { notFound } from 'next/navigation';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import ProductEditor from '@/components/admin/product-editor';

export default async function ProductDetailPage({ params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return null;
  const tid = session.user.tenantId;

  const product = await prisma.product.findUnique({
    where: { id: params.id },
    include: {
      translations: true,
      productGroup: { include: { translations: true, parent: { include: { translations: true } } } },
      prices: { include: { fillQuantity: true, priceLevel: true }, orderBy: { sortOrder: 'asc' } },
      productAllergens: { include: { allergen: { include: { translations: true } } } },
      productTags: { include: { tag: { include: { translations: true } } } },
      productWineProfile: true,
      productBevDetail: true,
      productMedia: { include: { media: true }, orderBy: { sortOrder: 'asc' } },
      placements: { include: { menuSection: { include: { translations: true, menu: { include: { translations: true } } } } } },
    },
  });
  if (!product) return notFound();

  const [groups, priceLevels, fillQuantities] = await Promise.all([
    prisma.productGroup.findMany({ where: { tenantId: tid }, include: { translations: true, parent: { include: { translations: true } } }, orderBy: { sortOrder: 'asc' } }),
    prisma.priceLevel.findMany({ where: { tenantId: tid }, orderBy: { sortOrder: 'asc' } }),
    prisma.fillQuantity.findMany({ where: { tenantId: tid }, orderBy: { sortOrder: 'asc' } }),
  ]);

  // Serialize
  const data = {
    id: product.id, sku: product.sku, type: product.type, status: product.status,
    isHighlight: product.isHighlight, highlightType: product.highlightType,
    productGroupId: product.productGroupId,
    translations: product.translations.map(t => ({ languageCode: t.languageCode, name: t.name, shortDescription: t.shortDescription, longDescription: t.longDescription, servingSuggestion: t.servingSuggestion })),
    prices: product.prices.map(p => ({ id: p.id, fillQuantityId: p.fillQuantityId, fillLabel: p.fillQuantity.label, priceLevelId: p.priceLevelId, levelName: p.priceLevel.name, price: Number(p.price), purchasePrice: p.purchasePrice ? Number(p.purchasePrice) : null, fixedMarkup: p.fixedMarkup ? Number(p.fixedMarkup) : null, percentMarkup: p.percentMarkup, isDefault: p.isDefault, sortOrder: p.sortOrder })),
    wineProfile: product.productWineProfile ? {
      winery: product.productWineProfile.winery, vintage: product.productWineProfile.vintage,
      grapeVarieties: product.productWineProfile.grapeVarieties,
      region: product.productWineProfile.region, country: product.productWineProfile.country,
      appellation: product.productWineProfile.appellation, style: product.productWineProfile.style,
      body: product.productWineProfile.body, sweetness: product.productWineProfile.sweetness,
      bottleSize: product.productWineProfile.bottleSize, alcoholContent: product.productWineProfile.alcoholContent,
      servingTemp: product.productWineProfile.servingTemp, tastingNotes: product.productWineProfile.tastingNotes,
      foodPairing: product.productWineProfile.foodPairing,
    } : null,
    bevDetail: product.productBevDetail ? {
      brand: product.productBevDetail.brand, producer: product.productBevDetail.producer,
      category: product.productBevDetail.category, alcoholContent: product.productBevDetail.alcoholContent,
      servingTemp: product.productBevDetail.servingTemp, carbonated: product.productBevDetail.carbonated,
      origin: product.productBevDetail.origin,
    } : null,
    placements: product.placements.map(pl => ({
      menuName: pl.menuSection.menu.translations.find(t => t.languageCode === 'de')?.name || '',
      sectionName: pl.menuSection.translations.find(t => t.languageCode === 'de')?.name || '',
      isVisible: pl.isVisible,
    })),
    tags: product.productTags.map(t => ({ name: t.tag.translations.find(tr => tr.languageCode === 'de')?.name || '', icon: t.tag.icon })),
    internalNotes: product.internalNotes,
    images: (product.productMedia || []).map((pm: any) => ({
      id: pm.id,
      mediaId: pm.mediaId,
      url: pm.url || pm.media?.url || '',
      thumbUrl: pm.media?.thumbnailUrl || pm.url || '',
      mediaType: pm.mediaType,
      isPrimary: pm.isPrimary,
      sortOrder: pm.sortOrder,
    })),
    createdAt: product.createdAt.toISOString(),
  };

  const opts = {
    groups: groups.map(g => ({ id: g.id, slug: g.slug, name: g.translations.find(t => t.languageCode === 'de')?.name || g.slug, parentName: g.parent?.translations.find(t => t.languageCode === 'de')?.name || null })),
    priceLevels: priceLevels.map(pl => ({ id: pl.id, name: pl.name, slug: pl.slug })),
    fillQuantities: fillQuantities.map(fq => ({ id: fq.id, label: fq.label, volume: fq.volume })),
  };

  return <ProductEditor product={data} options={opts} images={data.images || []} />;
}
