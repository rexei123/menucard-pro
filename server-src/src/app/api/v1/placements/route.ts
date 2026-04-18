import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

// ─── POST: Variante auf Kartensektion platzieren ───
// Akzeptiert sectionId + variantId (v2)
// ODER menuSectionId + productId (v1-Compat: auto-resolve auf Default-Variante)
export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await req.json();
  let sectionId = body.sectionId || body.menuSectionId;
  let variantId = body.variantId;
  const sortOrder = body.sortOrder ?? 999;

  if (!sectionId) return NextResponse.json({ error: 'sectionId fehlt' }, { status: 400 });

  // v1-Compat: productId → Default-Variante auflösen
  if (!variantId && body.productId) {
    const defaultVariant = await prisma.productVariant.findFirst({
      where: { productId: body.productId, isDefault: true },
    });
    if (!defaultVariant) {
      // Fallback: erste Variante nehmen
      const firstVariant = await prisma.productVariant.findFirst({
        where: { productId: body.productId },
        orderBy: { sortOrder: 'asc' },
      });
      if (!firstVariant) {
        return NextResponse.json({ error: 'Produkt hat keine Variante' }, { status: 400 });
      }
      variantId = firstVariant.id;
    } else {
      variantId = defaultVariant.id;
    }
  }

  if (!variantId) return NextResponse.json({ error: 'variantId fehlt' }, { status: 400 });

  // Duplikat-Check
  const existing = await prisma.menuPlacement.findUnique({
    where: { sectionId_variantId: { sectionId, variantId } },
  });
  if (existing) return NextResponse.json({ error: 'Bereits zugeordnet' }, { status: 409 });

  const placement = await prisma.menuPlacement.create({
    data: {
      sectionId,
      variantId,
      sortOrder,
      isVisible: body.isVisible ?? true,
      highlightType: body.highlightType || 'NONE',
      priceOverride: body.priceOverride || null,
      channels: body.channels || ['DIGITAL', 'PRINT'],
    },
  });

  return NextResponse.json(placement, { status: 201 });
}
