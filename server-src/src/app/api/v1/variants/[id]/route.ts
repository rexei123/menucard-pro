import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

// ─── PATCH: Einzelne Variante bearbeiten ───
export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const variant = await prisma.productVariant.findUnique({
    where: { id: params.id },
    include: { product: { select: { tenantId: true } } },
  });
  if (!variant || variant.product.tenantId !== session.user.tenantId) {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }

  const body = await req.json();
  const { prices, ...variantData } = body;

  await prisma.$transaction(async (tx) => {
    // Falls isDefault: bestehende Default-Varianten zuruecksetzen
    if (variantData.isDefault) {
      await tx.productVariant.updateMany({
        where: { productId: variant.productId, isDefault: true, id: { not: params.id } },
        data: { isDefault: false },
      });
    }

    const allowed = ['fillQuantityId', 'label', 'sku', 'sortOrder', 'isDefault', 'isSellable', 'isStockable', 'status'];
    const data: any = {};
    for (const k of allowed) { if (variantData[k] !== undefined) data[k] = variantData[k]; }
    if (Object.keys(data).length > 0) {
      await tx.productVariant.update({ where: { id: params.id }, data });
    }

    // Preise aktualisieren
    if (prices) {
      const keepIds = prices.filter((p: any) => p.id).map((p: any) => p.id);
      await tx.variantPrice.deleteMany({
        where: { variantId: params.id, id: { notIn: keepIds } },
      });
      for (const p of prices) {
        if (p.id) {
          await tx.variantPrice.update({
            where: { id: p.id },
            data: {
              sellPrice: p.sellPrice,
              costPrice: p.costPrice ?? null,
              fixedMarkup: p.fixedMarkup || null,
              percentMarkup: p.percentMarkup || null,
              priceLevelId: p.priceLevelId,
              taxRateId: p.taxRateId || null,
              pricingType: p.pricingType || 'FIXED',
            },
          });
        } else {
          await tx.variantPrice.create({
            data: {
              variantId: params.id,
              priceLevelId: p.priceLevelId,
              sellPrice: p.sellPrice,
              costPrice: p.costPrice ?? null,
              fixedMarkup: p.fixedMarkup || null,
              percentMarkup: p.percentMarkup || null,
              taxRateId: p.taxRateId || null,
              pricingType: p.pricingType || 'FIXED',
            },
          });
        }
      }
    }
  });

  return NextResponse.json({ success: true });
}

// ─── DELETE: Variante loeschen (mit Platzierungen und Preisen) ───
export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const variant = await prisma.productVariant.findUnique({
    where: { id: params.id },
    include: { product: { select: { tenantId: true, _count: { select: { variants: true } } } } },
  });
  if (!variant || variant.product.tenantId !== session.user.tenantId) {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }

  // Letzte Variante eines Produkts darf nicht geloescht werden
  if (variant.product._count.variants <= 1) {
    return NextResponse.json({ error: 'Letzte Variante kann nicht geloescht werden' }, { status: 400 });
  }

  await prisma.$transaction(async (tx) => {
    await tx.menuPlacement.deleteMany({ where: { variantId: params.id } });
    await tx.variantPrice.deleteMany({ where: { variantId: params.id } });
    await tx.stockLevel.deleteMany({ where: { variantId: params.id } });
    await tx.productVariant.delete({ where: { id: params.id } });
  });

  return NextResponse.json({ success: true });
}
