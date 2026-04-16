// @ts-nocheck
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

// POST /api/v1/variants — Neue Variante zu einem Produkt hinzufügen
export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;
  const body = await req.json();

  const { productId, fillQuantityId, label, sku, isDefault, prices } = body;
  if (!productId) {
    return NextResponse.json({ error: 'productId ist erforderlich' }, { status: 400 });
  }

  // Produkt prüfen
  const product = await prisma.product.findFirst({ where: { id: productId, tenantId: tid } });
  if (!product) return NextResponse.json({ error: 'Produkt nicht gefunden' }, { status: 404 });

  // Nächste sortOrder
  const maxSort = await prisma.productVariant.findFirst({
    where: { productId },
    orderBy: { sortOrder: 'desc' },
    select: { sortOrder: true },
  });

  // Wenn isDefault, alle anderen auf false setzen
  if (isDefault) {
    await prisma.productVariant.updateMany({
      where: { productId, isDefault: true },
      data: { isDefault: false },
    });
  }

  const variant = await prisma.productVariant.create({
    data: {
      productId,
      fillQuantityId: fillQuantityId || null,
      label: label || null,
      sku: sku || null,
      sortOrder: (maxSort?.sortOrder ?? -1) + 1,
      isDefault: isDefault ?? false,
      prices: prices ? {
        create: prices.map((p: any) => ({
          priceLevelId: p.priceLevelId,
          sellPrice: p.sellPrice,
          costPrice: p.costPrice || null,
          fixedMarkup: p.fixedMarkup || null,
          percentMarkup: p.percentMarkup || null,
          taxRateId: p.taxRateId || null,
        })),
      } : undefined,
    },
    include: {
      fillQuantity: true,
      prices: { include: { priceLevel: true } },
    },
  });

  return NextResponse.json(variant, { status: 201 });
}
