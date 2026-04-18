import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

// ─── POST: Neue Variante zu bestehendem Produkt hinzufuegen ───
export async function POST(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const product = await prisma.product.findFirst({
    where: { id: params.id, tenantId: session.user.tenantId },
    include: { variants: { orderBy: { sortOrder: 'desc' }, take: 1 } },
  });
  if (!product) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  const body = await req.json();
  const nextSort = (product.variants[0]?.sortOrder ?? -1) + 1;

  const variant = await prisma.$transaction(async (tx) => {
    // Falls isDefault: bestehende Default-Varianten zuruecksetzen
    if (body.isDefault) {
      await tx.productVariant.updateMany({
        where: { productId: params.id, isDefault: true },
        data: { isDefault: false },
      });
    }

    const v = await tx.productVariant.create({
      data: {
        productId: params.id,
        fillQuantityId: body.fillQuantityId || null,
        label: body.label || null,
        sku: body.sku || null,
        sortOrder: body.sortOrder ?? nextSort,
        isDefault: body.isDefault ?? false,
        isSellable: body.isSellable ?? true,
        isStockable: body.isStockable ?? false,
      },
    });

    // Preise direkt anlegen
    if (body.prices && body.prices.length > 0) {
      await tx.variantPrice.createMany({
        data: body.prices.map((p: any) => ({
          variantId: v.id,
          priceLevelId: p.priceLevelId,
          sellPrice: p.sellPrice,
          costPrice: p.costPrice ?? null,
          fixedMarkup: p.fixedMarkup || null,
          percentMarkup: p.percentMarkup || null,
          taxRateId: p.taxRateId || null,
          pricingType: p.pricingType || 'FIXED',
        })),
      });
    }

    return v;
  });

  return NextResponse.json({ id: variant.id, productId: params.id }, { status: 201 });
}

// ─── GET: Alle Varianten eines Produkts ───
export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const product = await prisma.product.findFirst({
    where: { id: params.id, tenantId: session.user.tenantId },
  });
  if (!product) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  const variants = await prisma.productVariant.findMany({
    where: { productId: params.id },
    include: {
      fillQuantity: true,
      prices: { include: { priceLevel: true, taxRate: true }, orderBy: { priceLevelId: 'asc' } },
    },
    orderBy: { sortOrder: 'asc' },
  });

  return NextResponse.json(variants);
}
