import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

// ─── PATCH: Platzierung bearbeiten ───
export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await req.json();
  const allowed = ['sortOrder', 'isVisible', 'highlightType', 'priceOverride', 'channels'];
  const data: any = {};
  for (const k of allowed) {
    if (body[k] !== undefined) data[k] = body[k];
  }

  const updated = await prisma.menuPlacement.update({
    where: { id: params.id },
    data,
  });
  return NextResponse.json(updated);
}

// ─── DELETE: Platzierung entfernen ───
export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  await prisma.menuPlacement.delete({ where: { id: params.id } }).catch(() => null);
  return NextResponse.json({ success: true });
}
