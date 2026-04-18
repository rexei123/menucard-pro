import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function POST(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { mediaId, mediaType, isPrimary } = await req.json();
  if (!mediaId) return NextResponse.json({ error: 'mediaId required' }, { status: 400 });

  const media = await prisma.media.findUnique({ where: { id: mediaId } });
  if (!media) return NextResponse.json({ error: 'Media not found' }, { status: 404 });

  const existing = await prisma.productMedia.findFirst({
    where: { productId: params.id, mediaId },
  });
  if (existing) return NextResponse.json({ error: 'Bereits zugeordnet' }, { status: 409 });

  const count = await prisma.productMedia.count({ where: { productId: params.id } });

  if (isPrimary) {
    await prisma.productMedia.updateMany({
      where: { productId: params.id, isPrimary: true },
      data: { isPrimary: false },
    });
  }

  const pm = await prisma.productMedia.create({
    data: {
      productId: params.id,
      mediaId,
      mediaType: (mediaType || 'OTHER') as any,
      url: media.url,
      alt: media.alt,
      sortOrder: count,
      isPrimary: isPrimary || count === 0,
    },
  });

  return NextResponse.json(pm, { status: 201 });
}

export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const productMedia = await prisma.productMedia.findMany({
    where: { productId: params.id },
    include: { media: true },
    orderBy: [{ isPrimary: 'desc' }, { sortOrder: 'asc' }],
  });

  return NextResponse.json(productMedia);
}
