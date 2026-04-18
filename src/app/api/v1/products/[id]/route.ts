// @ts-nocheck
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const product = await prisma.product.findFirst({
    where: { id: params.id, tenantId: session.user.tenantId },
    include: {
      translations: true,
      variants: {
        include: {
          fillQuantity: true,
          prices: { include: { priceLevel: true, taxRate: true } },
        },
        orderBy: { sortOrder: 'asc' },
      },
      wineProfile: true,
      beverageDetail: true,
      taxonomy: { include: { node: { include: { translations: true } } } },
      allergens: { include: { allergen: { include: { translations: true } } } },
      tags: true,
      productMedia: { include: { media: true }, orderBy: { sortOrder: 'asc' } },
    },
  });
  if (!product) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  return NextResponse.json(product);
}

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const product = await prisma.product.findFirst({
    where: { id: params.id, tenantId: session.user.tenantId },
  });
  if (!product) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  const body = await req.json();
  const { translations, wineProfile, beverageDetail, taxonomy, variants, ...productData } = body;

  // Produkt-Basisfelder aktualisieren
  const updatable: any = {};
  if (productData.type !== undefined) updatable.type = productData.type;
  if (productData.status !== undefined) updatable.status = productData.status;
  if (productData.sku !== undefined) updatable.sku = productData.sku;
  if (productData.highlightType !== undefined) updatable.highlightType = productData.highlightType;
  if (productData.supplierId !== undefined) updatable.supplierId = productData.supplierId || null;

  if (Object.keys(updatable).length > 0) {
    await prisma.product.update({ where: { id: params.id }, data: updatable });
  }

  // Übersetzungen upserten (v2: language statt languageCode)
  if (translations) {
    for (const t of translations) {
      const lang = t.language || t.languageCode || 'de';
      await prisma.productTranslation.upsert({
        where: { productId_language: { productId: params.id, language: lang } },
        update: {
          name: t.name,
          shortDescription: t.shortDescription ?? null,
          longDescription: t.longDescription ?? null,
          servingSuggestion: t.servingSuggestion ?? null,
          recipe: t.recipe ?? null,
          notes: t.notes ?? null,
        },
        create: {
          productId: params.id,
          language: lang,
          name: t.name,
          shortDescription: t.shortDescription ?? null,
          longDescription: t.longDescription ?? null,
          servingSuggestion: t.servingSuggestion ?? null,
          recipe: t.recipe ?? null,
          notes: t.notes ?? null,
        },
      });
    }
  }

  // Weinprofil
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

  // Getränkedetail
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

  // v2: Taxonomie-Zuordnungen (Array von nodeIds)
  if (taxonomy !== undefined) {
    // Alle bestehenden löschen und neu setzen
    await prisma.productTaxonomy.deleteMany({ where: { productId: params.id } });
    if (Array.isArray(taxonomy) && taxonomy.length > 0) {
      await prisma.productTaxonomy.createMany({
        data: taxonomy.map((t: any, i: number) => ({
          productId: params.id,
          nodeId: typeof t === 'string' ? t : t.nodeId,
          isPrimary: typeof t === 'string' ? i === 0 : (t.isPrimary ?? false),
        })),
      });
    }
  }

  return NextResponse.json({ success: true });
}

export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const product = await prisma.product.findFirst({
    where: { id: params.id, tenantId: session.user.tenantId },
  });
  if (!product) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  // v2: Kaskadiert — Varianten, Preise, Placements, etc. werden durch onDelete: Cascade gelöscht
  // Nur Relations ohne Cascade manuell löschen
  await prisma.productTaxonomy.deleteMany({ where: { productId: params.id } });
  await prisma.productAllergen.deleteMany({ where: { productId: params.id } });
  await prisma.productTag.deleteMany({ where: { productId: params.id } });
  await prisma.productCustomFieldValue.deleteMany({ where: { productId: params.id } });
  await prisma.productMedia.deleteMany({ where: { productId: params.id } });
  await prisma.product.delete({ where: { id: params.id } });

  return NextResponse.json({ success: true });
}
