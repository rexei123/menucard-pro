// @ts-nocheck
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

// GET /api/v1/placements — Listen-Endpoint fuer alle Placements des Mandanten
// Query-Parameter:
//   ?menuId=<id>        nur Placements einer Karte
//   ?sectionId=<id>     nur Placements einer Sektion
//   ?variantId=<id>     nur Placements einer Variante
//   ?limit/offset       Pagination (default 500 / 0)
export async function GET(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;

  const url = new URL(req.url);
  const menuId = url.searchParams.get('menuId');
  const sectionId = url.searchParams.get('sectionId');
  const variantId = url.searchParams.get('variantId');
  const limit = Math.min(parseInt(url.searchParams.get('limit') || '500'), 1000);
  const offset = parseInt(url.searchParams.get('offset') || '0');

  const where: any = {
    section: { menu: { location: { tenantId: tid } } },
  };
  if (sectionId) where.sectionId = sectionId;
  if (variantId) where.variantId = variantId;
  if (menuId) where.section = { menuId, menu: { location: { tenantId: tid } } };

  const [items, total] = await Promise.all([
    prisma.menuPlacement.findMany({
      where,
      include: {
        section: {
          include: {
            menu: { select: { id: true, slug: true, type: true } },
            translations: true,
          },
        },
        variant: {
          include: {
            product: {
              select: {
                id: true, sku: true, type: true, status: true,
                translations: true,
              },
            },
            fillQuantity: true,
            prices: { include: { priceLevel: true } },
          },
        },
      },
      orderBy: [{ sectionId: 'asc' }, { sortOrder: 'asc' }],
      take: limit,
      skip: offset,
    }),
    prisma.menuPlacement.count({ where }),
  ]);

  return NextResponse.json({ items, total, limit, offset });
}

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await req.json();
  // v2: sectionId + variantId statt menuSectionId + productId
  const sectionId = body.sectionId || body.menuSectionId;
  const variantId = body.variantId;

  if (!sectionId || !variantId) {
    return NextResponse.json({ error: 'sectionId und variantId sind erforderlich' }, { status: 400 });
  }

  const existing = await prisma.menuPlacement.findUnique({
    where: { sectionId_variantId: { sectionId, variantId } },
  });
  if (existing) return NextResponse.json({ error: 'Bereits zugeordnet' }, { status: 409 });

  const placement = await prisma.menuPlacement.create({
    data: {
      sectionId,
      variantId,
      sortOrder: body.sortOrder ?? 999,
      isVisible: true,
      highlightType: body.highlightType || 'NONE',
    },
    include: {
      variant: {
        include: {
          product: { include: { translations: true } },
          fillQuantity: true,
          prices: { include: { priceLevel: true } },
        },
      },
    },
  });
  return NextResponse.json(placement, { status: 201 });
}
