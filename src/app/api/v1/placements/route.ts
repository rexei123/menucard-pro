import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const { menuSectionId, productId, sortOrder } = await req.json();
  if (!menuSectionId || !productId) return NextResponse.json({ error: 'Missing fields' }, { status: 400 });
  const existing = await prisma.menuPlacement.findUnique({ where: { menuSectionId_productId: { menuSectionId, productId } } });
  if (existing) return NextResponse.json({ error: 'Bereits zugeordnet' }, { status: 409 });
  const placement = await prisma.menuPlacement.create({ data: { menuSectionId, productId, sortOrder: sortOrder ?? 999, isVisible: true } });
  return NextResponse.json(placement, { status: 201 });
}
