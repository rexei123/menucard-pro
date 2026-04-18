import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

// ─── POST: Neues Produkt mit Default-Variante anlegen ───
export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;

  const body = await req.json();
  const type = body.type || 'OTHER';

  // Auto-generate SKU
  const lastProduct = await prisma.product.findFirst({
    where: { tenantId: tid, sku: { startsWith: 'SB-' } },
    orderBy: { sku: 'desc' },
    select: { sku: true },
  });
  const lastNum = lastProduct?.sku ? parseInt(lastProduct.sku.replace('SB-', '')) : 0;
  const sku = 'SB-' + String(lastNum + 1).padStart(4, '0');

  // Transaktion: Product + Default-Variante + Translations
  const product = await prisma.$transaction(async (tx) => {
    const p = await tx.product.create({
      data: {
        tenantId: tid,
        sku,
        type,
        status: 'DRAFT',
        translations: {
          create: [
            { language: 'de', languageCode: 'de', name: body.name || 'Neues Produkt' },
            { language: 'en', languageCode: 'en', name: body.nameEn || 'New Product' },
          ],
        },
      },
    });

    // Default-Variante (Standard-Portion/Einheit)
    const fillQuantityId = body.fillQuantityId || null;
    const variant = await tx.productVariant.create({
      data: {
        productId: p.id,
        fillQuantityId,
        label: body.variantLabel || null,
        sku: sku + '-01',
        sortOrder: 0,
        isDefault: true,
        isSellable: true,
      },
    });

    // Falls ein Preis mitgegeben wird, direkt anlegen
    if (body.price && body.priceLevelId) {
      await tx.variantPrice.create({
        data: {
          variantId: variant.id,
          priceLevelId: body.priceLevelId,
          sellPrice: body.price,
          costPrice: body.purchasePrice || null,
        },
      });
    }

    return { ...p, defaultVariantId: variant.id };
  });

  return NextResponse.json({
    id: product.id,
    sku: product.sku,
    defaultVariantId: product.defaultVariantId,
  }, { status: 201 });
}

// ─── GET: Alle Produkte mit Varianten und Taxonomie ───
export async function GET(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;

  const { searchParams } = new URL(req.url);
  const type = searchParams.get('type');
  const status = searchParams.get('status');
  const taxonomyNodeId = searchParams.get('taxonomyNodeId');

  const where: any = { tenantId: tid };
  if (type) where.type = type;
  if (status) where.status = status;
  if (taxonomyNodeId) where.taxonomy = { some: { nodeId: taxonomyNodeId } };

  const products = await prisma.product.findMany({
    where,
    include: {
      translations: true,
      variants: {
        orderBy: { sortOrder: 'asc' },
        include: {
          fillQuantity: true,
          prices: { include: { priceLevel: true } },
        },
      },
      taxonomy: { include: { node: { include: { translations: true } } } },
      allergens: { include: { allergen: { include: { translations: true } } } },
      wineProfile: true,
      beverageDetail: true,
      productMedia: { where: { isPrimary: true }, take: 1 },
    },
    orderBy: { createdAt: 'desc' },
  });

  // Flache Darstellung fuer Admin-Kompatibilitaet
  const result = products.map((p) => {
    const deName = p.translations.find(t => t.languageCode === 'de')?.name || '';
    const enName = p.translations.find(t => t.languageCode === 'en')?.name || '';
    const defaultVariant = p.variants.find(v => v.isDefault) || p.variants[0];
    const mainPrice = defaultVariant?.prices?.[0];
    const primaryCategory = p.taxonomy.find(t => t.isPrimary)?.node;

    return {
      id: p.id,
      sku: p.sku,
      type: p.type,
      status: p.status,
      highlightType: p.highlightType,
      name: deName,
      nameEn: enName,
      translations: p.translations,
      // COMPAT: v1-Admin erwartet mainPrice + priceCount
      mainPrice: mainPrice ? Number(mainPrice.sellPrice) : null,
      priceCount: defaultVariant?.prices?.length || 0,
      variantCount: p.variants.length,
      // v2: Taxonomie statt productGroup
      categoryName: primaryCategory?.translations?.[0]?.name || primaryCategory?.name || null,
      categorySlug: primaryCategory?.slug || null,
      // Image
      image: p.productMedia?.[0]?.url || null,
      createdAt: p.createdAt,
    };
  });

  return NextResponse.json(result);
}
