import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import { unlink } from 'fs/promises';
import path from 'path';

export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const pm = await prisma.productMedia.findUnique({ where: { id: params.id }, include: { media: true } });
  if (!pm) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  // Delete files
  if (pm.media?.filename) {
    const basePath = path.join(process.cwd(), 'public', 'uploads');
    for (const dir of ['original', 'large', 'medium', 'thumb']) {
      await unlink(path.join(basePath, dir, pm.media.filename)).catch(() => {});
    }
  }

  // Delete DB records
  await prisma.productMedia.delete({ where: { id: params.id } });
  if (pm.mediaId) await prisma.media.delete({ where: { id: pm.mediaId } }).catch(() => {});

  return NextResponse.json({ success: true });
}

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await req.json();
  const updated = await prisma.productMedia.update({ where: { id: params.id }, data: body });

  // If setting as primary, unset others
  if (body.isPrimary) {
    await prisma.productMedia.updateMany({
      where: { productId: updated.productId, id: { not: params.id } },
      data: { isPrimary: false },
    });
  }

  return NextResponse.json(updated);
}
