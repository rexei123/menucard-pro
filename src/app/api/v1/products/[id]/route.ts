import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const product = await prisma.product.findFirst({
    where: { id: params.id, tenantId: session.user.tenantId },
  });
  if (!product) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  const body = await req.json();
  const { translations, prices, wineProfile, beverageDetail, ...productData } = body;

  // Update product base fields
  if (Object.keys(productData).length > 0) {
    await prisma.product.update({ where: { id: params.id }, data: productData });
  }

  // Update translations
  if (translations) {
    for (const t of translations) {
      await prisma.productTranslation.upsert({
        where: { productId_languageCode: { productId: params.id, languageCode: t.languageCode } },
        update: { name: t.name, shortDescription: t.shortDescription || null, longDescription: t.longDescription || null, servingSuggestion: t.servingSuggestion || null },
        create: { productId: params.id, languageCode: t.languageCode, name: t.name, shortDescription: t.shortDescription || null, longDescription: t.longDescription || null, servingSuggestion: t.servingSuggestion || null },
      });
    }
  }

  // Update wine profile
  if (wineProfile !== undefined) {
    if (wineProfile === null) {
      await prisma.productWineProfile.deleteMany({ where: { productId: params.id } });
    } else {
      await prisma.productWineProfile.upsert({
        where: { productId: params.id },
        update: wineProfile,
        create: { productId: params.id, ...wineProfile },
      });
    }
  }

  // Update beverage detail
  if (beverageDetail !== undefined) {
    if (beverageDetail === null) {
      await prisma.productBeverageDetail.deleteMany({ where: { productId: params.id } });
    } else {
      await prisma.productBeverageDetail.upsert({
        where: { productId: params.id },
        update: beverageDetail,
        create: { productId: params.id, ...beverageDetail },
      });
    }
  }

  // Update prices
  if (prices) {
    // Delete removed prices
    const keepIds = prices.filter((p: any) => p.id).map((p: any) => p.id);
    await prisma.productPrice.deleteMany({
      where: { productId: params.id, id: { notIn: keepIds } },
    });
    // Upsert prices
    for (const p of prices) {
      if (p.id) {
        await prisma.productPrice.update({
          where: { id: p.id },
          data: { price: p.price, purchasePrice: p.purchasePrice || null, fillQuantityId: p.fillQuantityId, priceLevelId: p.priceLevelId, isDefault: p.isDefault || false, sortOrder: p.sortOrder || 0 },
        });
      } else {
        await prisma.productPrice.create({
          data: { productId: params.id, price: p.price, purchasePrice: p.purchasePrice || null, fillQuantityId: p.fillQuantityId, priceLevelId: p.priceLevelId, isDefault: p.isDefault || false, sortOrder: p.sortOrder || 0 },
        });
      }
    }
  }

  return NextResponse.json({ success: true });
}
