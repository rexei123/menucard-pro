import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import sharp from 'sharp';
import { readFile, chmod } from 'fs/promises';
import path from 'path';

const FORMAT_SIZES: Record<string, { width: number; height: number }> = {
  '16:9': { width: 1920, height: 1080 },
  '4:3': { width: 1200, height: 900 },
  '1:1': { width: 800, height: 800 },
  '3:4': { width: 600, height: 800 },
};

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { format, cropX, cropY, cropW, cropH } = await req.json();

  if (!format || !FORMAT_SIZES[format]) {
    return NextResponse.json({ error: 'Invalid format. Use: 16:9, 4:3, 1:1, 3:4' }, { status: 400 });
  }
  if (cropX === undefined || cropY === undefined || cropW === undefined || cropH === undefined) {
    return NextResponse.json({ error: 'cropX, cropY, cropW, cropH required' }, { status: 400 });
  }

  const media = await prisma.media.findUnique({ where: { id: params.id } });
  if (!media) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  const formats = (media.formats as any) || {};
  const originalUrl = formats.original?.url;
  if (!originalUrl) return NextResponse.json({ error: 'Original not found' }, { status: 404 });

  try {
    const basePath = path.join(process.cwd(), 'public');
    const originalPath = path.join(basePath, originalUrl);
    const buffer = await readFile(originalPath);

    const targetSize = FORMAT_SIZES[format];
    const isLogo = media.category === 'LOGO';
    const formatUrl = formats[format]?.url;
    if (!formatUrl) return NextResponse.json({ error: 'Format URL not found' }, { status: 404 });

    const outputPath = path.join(basePath, formatUrl);

    const cropped = sharp(buffer)
      .rotate()
      .extract({ left: Math.round(cropX), top: Math.round(cropY), width: Math.round(cropW), height: Math.round(cropH) })
      .resize(targetSize.width, targetSize.height, { fit: 'fill' });

    if (isLogo) {
      await cropped.png().toFile(outputPath);
    } else {
      await cropped.webp({ quality: 85 }).toFile(outputPath);
    }

    // Berechtigungen fuer Nginx
    try { await chmod(outputPath, 0o644); } catch {}

    formats[format] = {
      ...formats[format],
      cropX: Math.round(cropX),
      cropY: Math.round(cropY),
      cropW: Math.round(cropW),
      cropH: Math.round(cropH),
    };

    await prisma.media.update({
      where: { id: params.id },
      data: { formats: formats as any },
    });

    return NextResponse.json({ success: true, format: formats[format] });
  } catch (e: any) {
    console.error('Crop error:', e);
    return NextResponse.json({ error: 'Crop failed', details: e.message }, { status: 500 });
  }
}
