import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function DELETE(
  req: NextRequest,
  { params }: { params: { id: string; productMediaId: string } }
) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  await prisma.productMedia.delete({ where: { id: params.productMediaId } });
  return NextResponse.json({ success: true });
}

export async function PATCH(
  req: NextRequest,
  { params }: { params: { id: string; productMediaId: string } }
) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { mediaType, isPrimary } = await req.json();
  const data: any = {};
  if (mediaType !== undefined) data.mediaType = mediaType;

  if (isPrimary) {
    await prisma.productMedia.updateMany({
      where: { productId: params.id, isPrimary: true },
      data: { isPrimary: false },
    });
    data.isPrimary = true;
  }

  const updated = await prisma.productMedia.update({
    where: { id: params.productMediaId },
    data,
  });

  return NextResponse.json(updated);
}
