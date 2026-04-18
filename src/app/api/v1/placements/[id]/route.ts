// @ts-nocheck
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  await prisma.menuPlacement.delete({ where: { id: params.id } }).catch(() => null);
  return NextResponse.json({ success: true });
}

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await req.json();
  const updatable: any = {};
  if (body.sortOrder !== undefined) updatable.sortOrder = body.sortOrder;
  if (body.isVisible !== undefined) updatable.isVisible = body.isVisible;
  if (body.highlightType !== undefined) updatable.highlightType = body.highlightType;
  if (body.priceOverride !== undefined) updatable.priceOverride = body.priceOverride;

  const updated = await prisma.menuPlacement.update({
    where: { id: params.id },
    data: updatable,
  });
  return NextResponse.json(updated);
}
