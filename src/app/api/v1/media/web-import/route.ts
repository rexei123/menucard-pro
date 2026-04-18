import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import sharp from 'sharp';
import { mkdir } from 'fs/promises';
import path from 'path';
import crypto from 'crypto';

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { url, source: rawSource, sourceAuthor, sourceUrl, category } = await req.json();
  if (!url) return NextResponse.json({ error: 'URL required' }, { status: 400 });

  // MediaSource-Enum: UPLOAD, PIXABAY, PEXELS, WEB
  const validSources = ['UPLOAD', 'PIXABAY', 'PEXELS', 'WEB'];
  const source = validSources.includes(rawSource) ? rawSource : 'WEB';

  try {
    // Bild herunterladen (mit User-Agent, Timeout und Redirect-Handling)
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);
    let imgRes: Response;
    try {
      imgRes = await fetch(url, {
        signal: controller.signal,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
        },
        redirect: 'follow',
      });
    } catch (fetchErr: any) {
      console.error('Web import fetch error:', fetchErr.message, 'URL:', url);
      return NextResponse.json({ error: 'Download failed', details: fetchErr.message, url }, { status: 500 });
    } finally {
      clearTimeout(timeout);
    }
    if (!imgRes.ok) {
      console.error('Web import HTTP error:', imgRes.status, imgRes.statusText, 'URL:', url);
      return NextResponse.json({ error: 'Download failed', status: imgRes.status, statusText: imgRes.statusText, url }, { status: 500 });
    }
    const contentType = imgRes.headers.get('content-type') || '';
    if (!contentType.startsWith('image/') && !contentType.includes('octet-stream')) {
      console.error('Web import wrong content-type:', contentType, 'URL:', url);
      return NextResponse.json({ error: 'Not an image', contentType, url }, { status: 400 });
    }
    const buffer = Buffer.from(await imgRes.arrayBuffer());

    if (buffer.length > 10 * 1024 * 1024) {
      return NextResponse.json({ error: 'Bild zu groß (max 10MB)' }, { status: 400 });
    }

    const hash = crypto.createHash('md5').update(buffer).digest('hex').slice(0, 12);
    const filename = `${hash}-${Date.now()}`;
    const basePath = path.join(process.cwd(), 'public', 'uploads');
    const cat = category || 'PHOTO';
    const isLogo = cat === 'LOGO';

    await mkdir(path.join(basePath, 'original'), { recursive: true });
    await mkdir(path.join(basePath, 'formats'), { recursive: true });
    await mkdir(path.join(basePath, 'large'), { recursive: true });
    await mkdir(path.join(basePath, 'medium'), { recursive: true });
    await mkdir(path.join(basePath, 'thumb'), { recursive: true });

    const img = sharp(buffer).rotate();
    const meta = await img.metadata();
    const w = meta.width || 800;
    const h = meta.height || 600;
    const ext = isLogo ? 'png' : 'webp';

    // Original
    if (isLogo) {
      await img.clone().png().toFile(path.join(basePath, 'original', `${filename}.png`));
    } else {
      await img.clone().webp({ quality: 90 }).toFile(path.join(basePath, 'original', `${filename}.webp`));
    }

    const fmt = isLogo
      ? (clone: sharp.Sharp) => clone.png()
      : (clone: sharp.Sharp) => clone.webp({ quality: 85 });

    // 6 Formate generieren
    await fmt(img.clone().resize(1920, 1080, { fit: 'cover', position: 'center' }))
      .toFile(path.join(basePath, 'formats', `${filename}-16x9.${ext}`));
    await fmt(img.clone().resize(1200, 900, { fit: 'cover', position: 'center' }))
      .toFile(path.join(basePath, 'formats', `${filename}-4x3.${ext}`));
    await fmt(img.clone().resize(800, 800, { fit: 'cover', position: 'center' }))
      .toFile(path.join(basePath, 'formats', `${filename}-1x1.${ext}`));
    await fmt(img.clone().resize(600, 800, { fit: 'cover', position: 'center' }))
      .toFile(path.join(basePath, 'formats', `${filename}-3x4.${ext}`));
    await img.clone().resize(200, 200, { fit: 'cover', position: 'center' })
      .webp({ quality: 75 }).toFile(path.join(basePath, 'thumb', `${filename}.webp`));
    await img.clone().resize(1200, null, { withoutEnlargement: true })
      .webp({ quality: 85 }).toFile(path.join(basePath, 'large', `${filename}.webp`));
    await img.clone().resize(600, null, { withoutEnlargement: true })
      .webp({ quality: 80 }).toFile(path.join(basePath, 'medium', `${filename}.webp`));

    // Crop-Koordinaten
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

    // Titel aus URL extrahieren
    const urlParts = url.split('/');
    const autoTitle = sourceAuthor ? `${sourceAuthor} (${source || 'Web'})` : urlParts[urlParts.length - 1]?.split('?')[0] || 'Web-Bild';

    const media = await prisma.media.create({
      data: {
        tenantId: (session.user as any).tenantId,
        filename: `${filename}.${ext}`,
        originalName: autoTitle,
        title: autoTitle,
        mimeType: isLogo ? 'image/png' : 'image/webp',
        url: `/uploads/large/${filename}.webp`,
        thumbnailUrl: `/uploads/thumb/${filename}.webp`,
        width: w,
        height: h,
        sizeBytes: buffer.length,
        alt: autoTitle,
        formats: formats as any,
        category: cat as any,
        source: (source || 'WEB') as any,
        sourceUrl: sourceUrl || url,
        sourceAuthor: sourceAuthor || null,
      },
    });

    return NextResponse.json({
      id: media.id,
      url: media.url,
      thumbnailUrl: media.thumbnailUrl,
      formats,
    }, { status: 201 });

  } catch (e: any) {
    console.error('Web import error:', e);
    return NextResponse.json({ error: 'Import failed', details: e.message }, { status: 500 });
  }
}
