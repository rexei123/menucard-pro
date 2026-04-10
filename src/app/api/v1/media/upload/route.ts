import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import sharp from 'sharp';
import { writeFile, mkdir } from 'fs/promises';
import path from 'path';
import crypto from 'crypto';

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const formData = await req.formData();
  const file = formData.get('file') as File;
  const productId = formData.get('productId') as string;
  const mediaType = (formData.get('mediaType') as string) || 'OTHER';

  if (!file || !productId) return NextResponse.json({ error: 'File and productId required' }, { status: 400 });
  if (file.size > 4 * 1024 * 1024) return NextResponse.json({ error: 'Max 4MB' }, { status: 400 });

  const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
  if (!allowed.includes(file.type)) return NextResponse.json({ error: 'Only JPEG, PNG, WebP, GIF' }, { status: 400 });

  try {
    const buffer = Buffer.from(await file.arrayBuffer());
    const hash = crypto.createHash('md5').update(buffer).digest('hex').slice(0, 12);
    const filename = `${hash}-${Date.now()}`;
    const basePath = path.join(process.cwd(), 'public', 'uploads');

    // Ensure dirs exist
    await mkdir(path.join(basePath, 'original'), { recursive: true });
    await mkdir(path.join(basePath, 'large'), { recursive: true });
    await mkdir(path.join(basePath, 'medium'), { recursive: true });
    await mkdir(path.join(basePath, 'thumb'), { recursive: true });

    // Process with sharp - strip EXIF, convert to WebP
    const img = sharp(buffer).rotate(); // auto-rotate based on EXIF

    // Get metadata
    const meta = await img.metadata();

    // Original (stripped EXIF, WebP)
    await img.clone().webp({ quality: 90 }).toFile(path.join(basePath, 'original', `${filename}.webp`));

    // Large (1200px)
    await img.clone().resize(1200, null, { withoutEnlargement: true }).webp({ quality: 85 }).toFile(path.join(basePath, 'large', `${filename}.webp`));

    // Medium (600px)
    await img.clone().resize(600, null, { withoutEnlargement: true }).webp({ quality: 80 }).toFile(path.join(basePath, 'medium', `${filename}.webp`));

    // Thumb (200px)
    await img.clone().resize(200, 200, { fit: 'cover' }).webp({ quality: 75 }).toFile(path.join(basePath, 'thumb', `${filename}.webp`));

    // Save to DB
    const media = await prisma.media.create({
      data: {
        tenantId: session.user.tenantId,
        filename: `${filename}.webp`,
        mimeType: 'image/webp',
        url: `/uploads/large/${filename}.webp`,
        thumbnailUrl: `/uploads/thumb/${filename}.webp`,
        width: meta.width || null,
        height: meta.height || null,
        sizeBytes: buffer.length,
        alt: file.name.replace(/\.[^.]+$/, ''),
      },
    });

    // Link to product
    const existingCount = await prisma.productMedia.count({ where: { productId } });
    const productMedia = await prisma.productMedia.create({
      data: {
        productId,
        mediaId: media.id,
        mediaType: mediaType as any,
        url: `/uploads/large/${filename}.webp`,
        alt: file.name.replace(/\.[^.]+$/, ''),
        sortOrder: existingCount,
        isPrimary: existingCount === 0,
      },
    });

    return NextResponse.json({
      id: productMedia.id,
      mediaId: media.id,
      url: `/uploads/large/${filename}.webp`,
      thumbUrl: `/uploads/thumb/${filename}.webp`,
      mediumUrl: `/uploads/medium/${filename}.webp`,
      mediaType,
      isPrimary: existingCount === 0,
      sortOrder: existingCount,
    }, { status: 201 });
  } catch (e: any) {
    console.error('Upload error:', e);
    return NextResponse.json({ error: 'Upload failed', details: e.message }, { status: 500 });
  }
}
