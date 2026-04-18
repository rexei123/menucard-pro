// @ts-nocheck
import { notFound } from 'next/navigation';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import ProductEditor from '@/components/admin/product-editor';

export default async function ProductDetailPage({ params }) {
  const session = await getServerSession(authOptions);
  if (!session) return null;
  const tid = session.user.tenantId;

  let product = null;
  try {
    product = await prisma.product.findUnique({
      where: { id: params.id },
      include: {
        translations: true,
        taxonomy: { include: { node: { include: { translations: true } } } },
        variants: {
          include: {
            fillQuantity: true,
            prices: { include: { priceLevel: true } },
          },
          orderBy: { sortOrder: 'asc' },
        },
        allergens: { include: { allergen: { include: { translations: true } } } },
        tags: true,
        wineProfile: true,
        beverageDetail: true,
        productMedia: { orderBy: { sortOrder: 'asc' } },
      },
    });
  } catch (e) {
    console.error('Product detail query error:', e.message);
  }
  if (!product) return notFound();

  let taxonomyNodes = [];
  let priceLevels = [];
  let fillQuantities = [];

  try {
    [taxonomyNodes, priceLevels, fillQuantities] = await Promise.all([
      prisma.taxonomyNode.findMany({
        where: { tenantId: tid },
        include: { translations: true },
        orderBy: [{ type: 'asc' }, { depth: 'asc' }, { sortOrder: 'asc' }],
      }),
      prisma.priceLevel.findMany({ where: { tenantId: tid }, orderBy: { sortOrder: 'asc' } }),
      prisma.fillQuantity.findMany({ where: { tenantId: tid }, orderBy: { sortOrder: 'asc' } }),
    ]);
  } catch (e) {
    console.error('Product detail options error:', e.message);
  }

  const t = (translations, field = 'name') => {
    const de = translations?.find((tr) => tr.language === 'de' || tr.languageCode === 'de');
    return de?.[field] || translations?.[0]?.[field] || '';
  };

  // v2: Daten direkt durchreichen
  const data = {
    id: product.id,
    sku: product.sku,
    type: product.type,
    status: product.status,
    highlightType: product.highlightType || 'NONE',
    translations: product.translations.map((tr) => ({
      language: tr.language || tr.languageCode,
      name: tr.name,
      shortDescription: tr.shortDescription,
      longDescription: tr.longDescription,
      servingSuggestion: tr.servingSuggestion,
      recipe: tr.recipe,
      notes: tr.notes,
    })),
    // v2: Varianten mit Preisen
    variants: (product.variants || []).map((v) => ({
      id: v.id,
      label: v.label,
      sku: v.sku,
      fillQuantityId: v.fillQuantityId,
      fillQuantityLabel: v.fillQuantity?.label || null,
      isDefault: v.isDefault,
      sortOrder: v.sortOrder,
      status: v.status,
      prices: (v.prices || []).map((vp) => ({
        id: vp.id,
        priceLevelId: vp.priceLevelId,
        priceLevelName: vp.priceLevel?.name || '',
        sellPrice: Number(vp.sellPrice),
        costPrice: vp.costPrice ? Number(vp.costPrice) : null,
        fixedMarkup: vp.fixedMarkup ? Number(vp.fixedMarkup) : null,
        percentMarkup: vp.percentMarkup ? Number(vp.percentMarkup) : null,
      })),
    })),
    // v2: Taxonomie-IDs
    taxonomyNodeIds: (product.taxonomy || []).map((pt) => pt.nodeId),
    wineProfile: product.wineProfile ? {
      winery: product.wineProfile.winery,
      vintage: product.wineProfile.vintage,
      aging: product.wineProfile.aging,
      tastingNotes: product.wineProfile.tastingNotes,
      servingTemp: product.wineProfile.servingTemp,
      foodPairing: product.wineProfile.foodPairing,
      certification: product.wineProfile.certification,
    } : null,
    bevDetail: product.beverageDetail ? {
      brand: product.beverageDetail.brand,
      alcoholContent: product.beverageDetail.alcoholContent ? Number(product.beverageDetail.alcoholContent) : null,
      servingStyle: product.beverageDetail.servingStyle,
      garnish: product.beverageDetail.garnish,
      glassType: product.beverageDetail.glassType,
    } : null,
    tags: (product.tags || []).map((tg) => tg.tag),
    images: (product.productMedia || []).map((pm) => ({
      id: pm.id,
      mediaId: pm.mediaId,
      url: pm.url || '',
      thumbUrl: pm.url || '',
      mediaType: pm.mediaType,
      isPrimary: pm.isPrimary,
      sortOrder: pm.sortOrder,
    })),
    createdAt: product.createdAt.toISOString(),
  };

  // v2: Taxonomie-Nodes mit Hierarchie-Daten
  const opts = {
    taxonomyNodes: taxonomyNodes.map((n) => ({
      id: n.id,
      name: t(n.translations),
      type: n.type,
      slug: n.slug,
      parentId: n.parentId,
      depth: n.depth,
      taxLabel: n.taxLabel || null,
    })),
    priceLevels: priceLevels.map((pl) => ({ id: pl.id, name: pl.name, slug: pl.slug })),
    fillQuantities: fillQuantities.map((fq) => ({ id: fq.id, label: fq.label, slug: fq.slug, volumeMl: fq.volumeMl })),
  };

  return <ProductEditor product={data} options={opts} />;
}
