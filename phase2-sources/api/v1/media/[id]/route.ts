import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import { unlink } from 'fs/promises';
import path from 'path';

// GET – Einzelnes Bild mit Details
export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const media = await prisma.media.findUnique({
    where: { id: params.id },
    include: {
      productMedia: {
        include: {
          product: {
            select: {
              id: true,
              translations: { where: { languageCode: 'de' }, select: { name: true } },
            },
          },
        },
      },
    },
  });

  if (!media) return NextResponse.json({ error: 'Not found' }, { status: 404 });
  return NextResponse.json(media);
}

// PATCH – Metadaten aktualisieren
export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await req.json();
  const { title, alt, category, source } = body;

  const data: any = {};
  if (title !== undefined) data.title = title;
  if (alt !== undefined) data.alt = alt;
  if (category !== undefined) data.category = category;
  if (source !== undefined) data.source = source;

  const updated = await prisma.media.update({
    where: { id: params.id },
    data,
  });

  return NextResponse.json(updated);
}

// DELETE – Bild löschen
export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const media = await prisma.media.findUnique({
    where: { id: params.id },
    include: { productMedia: true },
  });

  if (!media) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  // Warnung wenn zugeordnet
  if (media.productMedia.length > 0) {
    const force = new URL(req.url).searchParams.get('force');
    if (force !== 'true') {
      return NextResponse.json({
        error: 'Bild ist noch zugeordnet',
        productCount: media.productMedia.length,
        hint: 'Verwende ?force=true um trotzdem zu löschen',
      }, { status: 409 });
    }
    // Zuordnungen löschen
    await prisma.productMedia.deleteMany({ where: { mediaId: params.id } });
  }

  // Dateien löschen
  const basePath = path.join(process.cwd(), 'public');
  const formats = (media.formats as any) || {};
  const filesToDelete = [
    media.url,
    media.thumbnailUrl,
    ...Object.values(formats).map((f: any) => f?.url).filter(Boolean),
  ];

  for (const fileUrl of filesToDelete) {
    try {
      if (fileUrl) await unlink(path.join(basePath, fileUrl));
    } catch (e) { /* Datei existiert nicht mehr */ }
  }

  await prisma.media.delete({ where: { id: params.id } });

  return NextResponse.json({ success: true });
}
