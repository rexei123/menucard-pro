// @ts-nocheck
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

// GET /api/v1/products — Listen-Endpoint fuer alle Produkte des Mandanten
// Query-Parameter:
//   ?type=WINE|FOOD|DRINK|SPIRIT|BEER|COFFEE|OTHER
//   ?status=ACTIVE|DRAFT|ARCHIVED
//   ?q=<search>  (sucht in Translations.name + sku)
//   ?limit=<n> (default 200)
//   ?offset=<n> (default 0)
export async function GET(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;

  const url = new URL(req.url);
  const type = url.searchParams.get('type');
  const status = url.searchParams.get('status');
  const q = url.searchParams.get('q');
  const limit = Math.min(parseInt(url.searchParams.get('limit') || '200'), 500);
  const offset = parseInt(url.searchParams.get('offset') || '0');

  const where: any = { tenantId: tid };
  if (type) where.type = type;
  if (status) where.status = status;
  if (q) {
    where.OR = [
      { sku: { contains: q, mode: 'insensitive' } },
      { translations: { some: { name: { contains: q, mode: 'insensitive' } } } },
    ];
  }

  const [items, total] = await Promise.all([
    prisma.product.findMany({
      where,
      include: {
        translations: true,
        variants: {
          include: {
            fillQuantity: true,
            prices: { include: { priceLevel: true } },
          },
          orderBy: { sortOrder: 'asc' },
        },
        taxonomy: { include: { node: true } },
        wineProfile: true,
        beverageDetail: true,
      },
      orderBy: { updatedAt: 'desc' },
      take: limit,
      skip: offset,
    }),
    prisma.product.count({ where }),
  ]);

  return NextResponse.json({ items, total, limit, offset });
}

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

  // v2: Produkt + Standard-Variante + optionale Preise in einem Schritt
  const product = await prisma.product.create({
    data: {
      tenantId: tid,
      sku,
      type,
      status: 'DRAFT',
      translations: {
        create: [
          { language: 'de', name: body.name || 'Neues Produkt' },
          { language: 'en', name: body.nameEn || 'New Product' },
        ],
      },
      // v2: Immer mindestens eine Default-Variante erstellen
      variants: {
        create: [{
          isDefault: true,
          label: body.variantLabel || null,
          sortOrder: 0,
          ...(body.sellPrice ? {
            prices: {
              create: [{
                priceLevelId: body.priceLevelId,
                sellPrice: body.sellPrice,
                costPrice: body.costPrice || null,
              }],
            },
          } : {}),
        }],
      },
    },
    include: {
      translations: true,
      variants: { include: { prices: true } },
    },
  });

  return NextResponse.json({ id: product.id, sku: product.sku }, { status: 201 });
}
