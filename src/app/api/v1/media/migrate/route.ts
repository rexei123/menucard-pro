import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import sharp from 'sharp';
import { readFile, mkdir, access, chmod } from 'fs/promises';
import path from 'path';

const centerCrop = function(srcW: number, srcH: number, tgtRatio: number) {
  const srcRatio = srcW / srcH;
  let cropW: number, cropH: number, cropX: number, cropY: number;
  if (srcRatio > tgtRatio) {
    cropH = srcH; cropW = Math.round(srcH * tgtRatio);
    cropX = Math.round((srcW - cropW) / 2); cropY = 0;
  } else {
    cropW = srcW; cropH = Math.round(srcW / tgtRatio);
    cropX = 0; cropY = Math.round((srcH - cropH) / 2);
  }
  return { cropX, cropY, cropW, cropH };
};

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const basePath = path.join(process.cwd(), 'public');
  await mkdir(path.join(basePath, 'uploads', 'formats'), { recursive: true });

  const mediaList = await prisma.media.findMany({
    where: {
      OR: [
        { formats: { equals: null } },
        { formats: { equals: {} } },
      ],
    },
    take: 50,
  });

  if (mediaList.length === 0) {
    return NextResponse.json({ message: 'Keine Migration noetig', migrated: 0, remaining: 0 });
  }

  let migrated = 0;
  let errors = 0;
  const errorDetails: string[] = [];

  for (const media of mediaList) {
    try {
      let originalPath = '';
      const possiblePaths = [
        path.join(basePath, 'uploads', 'original', media.filename),
        path.join(basePath, 'uploads', 'large', media.filename),
        path.join(basePath, media.url),
      ];

      for (const p of possiblePaths) {
        try { await access(p); originalPath = p; break; } catch {}
      }

      if (!originalPath) {
        errors++;
        errorDetails.push(media.filename + ': Datei nicht gefunden');
        continue;
      }

      const buffer = await readFile(originalPath);
      const img = sharp(buffer).rotate();
      const meta = await img.metadata();
      const w = meta.width || 800;
      const h = meta.height || 600;

      const filenameBase = media.filename.replace(/\.[^.]+$/, '');
      const isLogo = media.category === 'LOGO';
      const ext = isLogo ? 'png' : 'webp';

      const processImg = function(clone: any) {
        return isLogo ? clone.png() : clone.webp({ quality: 85 });
      };

      const fmtDir = path.join(basePath, 'uploads', 'formats');

      const f16x9 = path.join(fmtDir, filenameBase + '-16x9.' + ext);
      await processImg(img.clone().resize(1920, 1080, { fit: 'cover', position: 'center' })).toFile(f16x9);

      const f4x3 = path.join(fmtDir, filenameBase + '-4x3.' + ext);
      await processImg(img.clone().resize(1200, 900, { fit: 'cover', position: 'center' })).toFile(f4x3);

      const f1x1 = path.join(fmtDir, filenameBase + '-1x1.' + ext);
      await processImg(img.clone().resize(800, 800, { fit: 'cover', position: 'center' })).toFile(f1x1);

      const f3x4 = path.join(fmtDir, filenameBase + '-3x4.' + ext);
      await processImg(img.clone().resize(600, 800, { fit: 'cover', position: 'center' })).toFile(f3x4);

      // Berechtigungen fuer Nginx
      try {
        await chmod(f16x9, 0o644);
        await chmod(f4x3, 0o644);
        await chmod(f1x1, 0o644);
        await chmod(f3x4, 0o644);
      } catch {}

      const formats = {
        original: { url: '/uploads/original/' + media.filename, width: w, height: h },
        '16:9': { url: '/uploads/formats/' + filenameBase + '-16x9.' + ext, width: 1920, height: 1080, ...centerCrop(w, h, 16/9) },
        '4:3': { url: '/uploads/formats/' + filenameBase + '-4x3.' + ext, width: 1200, height: 900, ...centerCrop(w, h, 4/3) },
        '1:1': { url: '/uploads/formats/' + filenameBase + '-1x1.' + ext, width: 800, height: 800, ...centerCrop(w, h, 1) },
        '3:4': { url: '/uploads/formats/' + filenameBase + '-3x4.' + ext, width: 600, height: 800, ...centerCrop(w, h, 3/4) },
        thumb: { url: media.thumbnailUrl || '/uploads/thumb/' + media.filename, width: 200, height: 200 },
      };

      await prisma.media.update({
        where: { id: media.id },
        data: {
          formats: formats as any,
          width: w,
          height: h,
          originalName: media.originalName || media.filename,
          title: media.title || media.alt || media.filename.replace(/\.[^.]+$/, ''),
        },
      });

      migrated++;
    } catch (e: any) {
      console.error('Migration error for ' + media.id + ':', e);
      errors++;
      errorDetails.push(media.filename + ': ' + e.message);
    }
  }

  const remaining = await prisma.media.count({
    where: { OR: [{ formats: { equals: null } }, { formats: { equals: {} } }] },
  });

  return NextResponse.json({ migrated, errors, remaining, errorDetails });
}
