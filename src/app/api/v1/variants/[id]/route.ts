// @ts-nocheck
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const variant = await prisma.productVariant.findUnique({
    where: { id: params.id },
    include: {
      product: { include: { translations: true } },
      fillQuantity: true,
      prices: { include: { priceLevel: true, taxRate: true } },
      placements: { include: { section: { include: { menu: true } } } },
    },
  });
  if (!variant) return NextResponse.json({ error: 'Nicht gefunden' }, { status: 404 });

  return NextResponse.json(variant);
}

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;

  const variant = await prisma.productVariant.findUnique({
    where: { id: params.id },
    include: { product: true },
  });
  if (!variant || variant.product.tenantId !== tid) {
    return NextResponse.json({ error: 'Nicht gefunden' }, { status: 404 });
  }

  const body = await req.json();
  const { prices, ...variantData } = body;

  // Basisfelder aktualisieren
  const updatable: any = {};
  if (variantData.label !== undefined) updatable.label = variantData.label;
  if (variantData.sku !== undefined) updatable.sku = variantData.sku;
  if (variantData.fillQuantityId !== undefined) updatable.fillQuantityId = variantData.fillQuantityId || null;
  if (variantData.sortOrder !== undefined) updatable.sortOrder = variantData.sortOrder;
  if (variantData.isDefault !== undefined) updatable.isDefault = variantData.isDefault;
  if (variantData.isSellable !== undefined) updatable.isSellable = variantData.isSellable;
  if (variantData.status !== undefined) updatable.status = variantData.status;

  // Wenn isDefault, alle anderen auf false
  if (variantData.isDefault === true) {
    await prisma.productVariant.updateMany({
      where: { productId: variant.productId, isDefault: true, id: { not: params.id } },
      data: { isDefault: false },
    });
  }

  if (Object.keys(updatable).length > 0) {
    await prisma.productVariant.update({ where: { id: params.id }, data: updatable });
  }

  // Preise upserten
  if (prices) {
    const keepIds = prices.filter((p: any) => p.id).map((p: any) => p.id);
    await prisma.variantPrice.deleteMany({
      where: { variantId: params.id, id: { notIn: keepIds } },
    });
    for (const p of prices) {
      if (p.id) {
        await prisma.variantPrice.update({
          where: { id: p.id },
          data: {
            sellPrice: p.sellPrice,
            costPrice: p.costPrice ?? null,
            fixedMarkup: p.fixedMarkup ?? null,
            percentMarkup: p.percentMarkup ?? null,
            priceLevelId: p.priceLevelId,
            taxRateId: p.taxRateId ?? null,
          },
        });
      } else {
        await prisma.variantPrice.create({
          data: {
            variantId: params.id,
            priceLevelId: p.priceLevelId,
            sellPrice: p.sellPrice,
            costPrice: p.costPrice ?? null,
            fixedMarkup: p.fixedMarkup ?? null,
            percentMarkup: p.percentMarkup ?? null,
            taxRateId: p.taxRateId ?? null,
          },
        });
      }
    }
  }

  const updated = await prisma.productVariant.findUnique({
    where: { id: params.id },
    include: { fillQuantity: true, prices: { include: { priceLevel: true } } },
  });
  return NextResponse.json(updated);
}

export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;

  const variant = await prisma.productVariant.findUnique({
    where: { id: params.id },
    include: { product: true, _count: { select: { placements: true } } },
  });
  if (!variant || variant.product.tenantId !== tid) {
    return NextResponse.json({ error: 'Nicht gefunden' }, { status: 404 });
  }

  if (variant._count.placements > 0) {
    return NextResponse.json(
      { error: `Kann nicht gelöscht werden — ${variant._count.placements} Platzierungen vorhanden` },
      { status: 409 }
    );
  }

  // Preise löschen, dann Variante
  await prisma.variantPrice.deleteMany({ where: { variantId: params.id } });
  await prisma.productVariant.delete({ where: { id: params.id } });

  return NextResponse.json({ success: true });
}
