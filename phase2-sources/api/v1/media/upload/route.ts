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
  const productId = formData.get('productId') as string | null;
  const mediaType = (formData.get('mediaType') as string) || 'OTHER';
  const category = (formData.get('category') as string) || 'PHOTO';
  const title = formData.get('title') as string | null;

  if (!file) return NextResponse.json({ error: 'File required' }, { status: 400 });
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
    await mkdir(path.join(basePath, 'formats'), { recursive: true });
    await mkdir(path.join(basePath, 'large'), { recursive: true });
    await mkdir(path.join(basePath, 'medium'), { recursive: true });
    await mkdir(path.join(basePath, 'thumb'), { recursive: true });

    const img = sharp(buffer).rotate();
    const meta = await img.metadata();
    const w = meta.width || 800;
    const h = meta.height || 600;
    const isLogo = category === 'LOGO';

    // Original
    if (isLogo) {
      await img.clone().png().toFile(path.join(basePath, 'original', `${filename}.png`));
    } else {
      await img.clone().webp({ quality: 90 }).toFile(path.join(basePath, 'original', `${filename}.webp`));
    }

    const ext = isLogo ? 'png' : 'webp';
    const fmt = isLogo
      ? (clone: sharp.Sharp) => clone.png()
      : (clone: sharp.Sharp) => clone.webp({ quality: 85 });

    // 16:9 (1920×1080)
    const f16x9 = { width: Math.min(1920, w), height: Math.min(1080, h) };
    await fmt(img.clone().resize(1920, 1080, { fit: 'cover', position: 'center' }))
      .toFile(path.join(basePath, 'formats', `${filename}-16x9.${ext}`));

    // 4:3 (1200×900)
    await fmt(img.clone().resize(1200, 900, { fit: 'cover', position: 'center' }))
      .toFile(path.join(basePath, 'formats', `${filename}-4x3.${ext}`));

    // 1:1 (800×800)
    await fmt(img.clone().resize(800, 800, { fit: 'cover', position: 'center' }))
      .toFile(path.join(basePath, 'formats', `${filename}-1x1.${ext}`));

    // 3:4 (600×800)
    await fmt(img.clone().resize(600, 800, { fit: 'cover', position: 'center' }))
      .toFile(path.join(basePath, 'formats', `${filename}-3x4.${ext}`));

    // Thumb (200×200)
    await img.clone().resize(200, 200, { fit: 'cover', position: 'center' })
      .webp({ quality: 75 }).toFile(path.join(basePath, 'thumb', `${filename}.webp`));

    // Large (1200px) + Medium (600px) – Rückwärtskompatibilität
    await img.clone().resize(1200, null, { withoutEnlargement: true })
      .webp({ quality: 85 }).toFile(path.join(basePath, 'large', `${filename}.webp`));
    await img.clone().resize(600, null, { withoutEnlargement: true })
      .webp({ quality: 80 }).toFile(path.join(basePath, 'medium', `${filename}.webp`));

    // Crop-Koordinaten berechnen (zentriert)
    const centerCrop = function(srcW: number, srcH: number, tgtRatio: number) {
      const srcRatio = srcW / srcH;
      let cropW, cropH, cropX, cropY;
      if (srcRatio > tgtRatio) {
        cropH = srcH; cropW = Math.round(srcH * tgtRatio);
        cropX = Math.round((srcW - cropW) / 2); cropY = 0;
      } else {
        cropW = srcW; cropH = Math.round(srcW / tgtRatio);
        cropX = 0; cropY = Math.round((srcH - cropH) / 2);
      }
      return { cropX, cropY, cropW, cropH };
    }

    const formats = {
      original: { url: `/uploads/original/${filename}.${ext}`, width: w, height: h },
      '16:9': { url: `/uploads/formats/${filename}-16x9.${ext}`, width: 1920, height: 1080, ...centerCrop(w, h, 16/9) },
      '4:3': { url: `/uploads/formats/${filename}-4x3.${ext}`, width: 1200, height: 900, ...centerCrop(w, h, 4/3) },
      '1:1': { url: `/uploads/formats/${filename}-1x1.${ext}`, width: 800, height: 800, ...centerCrop(w, h, 1) },
      '3:4': { url: `/uploads/formats/${filename}-3x4.${ext}`, width: 600, height: 800, ...centerCrop(w, h, 3/4) },
      thumb: { url: `/uploads/thumb/${filename}.webp`, width: 200, height: 200 },
    };

    // Save to DB
    const media = await prisma.media.create({
      data: {
        tenantId: (session.user as any).tenantId,
        filename: `${filename}.${ext}`,
        originalName: file.name,
        title: title || file.name.replace(/\.[^.]+$/, ''),
        mimeType: isLogo ? 'image/png' : 'image/webp',
        url: `/uploads/large/${filename}.webp`,
        thumbnailUrl: `/uploads/thumb/${filename}.webp`,
        width: w,
        height: h,
        sizeBytes: buffer.length,
        alt: file.name.replace(/\.[^.]+$/, ''),
        formats: formats as any,
        category: category as any,
        source: 'UPLOAD' as any,
      },
    });

    // Link to product (optional – nur wenn productId mitgegeben)
    let productMedia = null;
    if (productId) {
      const existingCount = await prisma.productMedia.count({ where: { productId } });
      productMedia = await prisma.productMedia.create({
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
    }

    return NextResponse.json({
      id: productMedia?.id || media.id,
      mediaId: media.id,
      url: `/uploads/large/${filename}.webp`,
      thumbUrl: `/uploads/thumb/${filename}.webp`,
      mediumUrl: `/uploads/medium/${filename}.webp`,
      formats,
      mediaType,
      isPrimary: productMedia?.isPrimary || false,
      sortOrder: productMedia?.sortOrder || 0,
    }, { status: 201 });

  } catch (e: any) {
    console.error('Upload error:', e);
    return NextResponse.json({ error: 'Upload failed', details: e.message }, { status: 500 });
  }
}
