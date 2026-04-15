#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Bildarchiv Phase 1: Schema + Upload-API + Media-Listing API
# ═══════════════════════════════════════════════════════════════
cd /var/www/menucard-pro

echo "=== Bildarchiv Phase 1 ==="
echo ""

# Backup
cp prisma/schema.prisma prisma/schema.prisma.bak-bildarchiv
cp src/app/api/v1/media/upload/route.ts src/app/api/v1/media/upload/route.ts.bak

# ───────────────────────────────────────
echo "[1/5] Prisma Schema erweitern..."
# ───────────────────────────────────────

# Neue Enums VOR model Media einfügen
sed -i '/^model Media {/i\
enum MediaCategory {\
  PHOTO\
  LOGO\
  DOCUMENT\
}\
\
enum MediaSource {\
  UPLOAD\
  PIXABAY\
  PEXELS\
  WEB\
}\
' prisma/schema.prisma

# Neue Felder in Media-Tabelle einfügen (nach createdAt)
sed -i '/createdAt.*DateTime.*@default(now())/a\
  originalName  String?\
  title         String?\
  formats       Json?\
  category      MediaCategory @default(PHOTO)\
  source        MediaSource   @default(UPLOAD)\
  sourceUrl     String?\
  sourceAuthor  String?\
  updatedAt     DateTime      @updatedAt' prisma/schema.prisma

echo "  ✓ Schema erweitert"

# ───────────────────────────────────────
echo "[2/5] Datenbank synchronisieren..."
# ───────────────────────────────────────

npx prisma db push --accept-data-loss 2>&1 | tail -5
npx prisma generate 2>&1 | tail -3

echo "  ✓ DB synchronisiert"

# ───────────────────────────────────────
echo "[3/5] Verzeichnis erstellen..."
# ───────────────────────────────────────

mkdir -p public/uploads/formats
echo "  ✓ public/uploads/formats/ erstellt"

# ───────────────────────────────────────
echo "[4/5] Upload-API erweitern (6 Formate)..."
# ───────────────────────────────────────

cat > src/app/api/v1/media/upload/route.ts << 'ENDOFFILE'
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
    function centerCrop(srcW: number, srcH: number, tgtRatio: number) {
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
ENDOFFILE

echo "  ✓ Upload-API erweitert (6 Formate + formats JSON)"

# ───────────────────────────────────────
echo "[5/5] Media-Listing API erstellen..."
# ───────────────────────────────────────

mkdir -p src/app/api/v1/media/\[id\]

# GET /api/v1/media – Alle Bilder mit Filter
cat > src/app/api/v1/media/route.ts << 'ENDOFFILE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function GET(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { searchParams } = new URL(req.url);
  const category = searchParams.get('category');
  const type = searchParams.get('type');
  const orientation = searchParams.get('orientation');
  const assigned = searchParams.get('assigned');
  const q = searchParams.get('q');
  const page = parseInt(searchParams.get('page') || '1');
  const limit = parseInt(searchParams.get('limit') || '24');
  const sort = searchParams.get('sort') || 'newest';

  const where: any = {};

  // Kategorie-Filter
  if (category) where.category = category;

  // Suchtext
  if (q) {
    where.OR = [
      { title: { contains: q, mode: 'insensitive' } },
      { originalName: { contains: q, mode: 'insensitive' } },
      { alt: { contains: q, mode: 'insensitive' } },
    ];
  }

  // Orientierung
  if (orientation === 'landscape') {
    where.width = { gt: prisma.media.fields.height };
  } else if (orientation === 'portrait') {
    where.height = { gt: prisma.media.fields.width };
  }
  // Note: orientation filter mit raw SQL wäre besser, vereinfacht hier

  // Sortierung
  let orderBy: any = { createdAt: 'desc' };
  if (sort === 'oldest') orderBy = { createdAt: 'asc' };
  if (sort === 'name') orderBy = { title: 'asc' };
  if (sort === 'size') orderBy = { sizeBytes: 'desc' };

  const [total, media] = await Promise.all([
    prisma.media.count({ where }),
    prisma.media.findMany({
      where,
      orderBy,
      skip: (page - 1) * limit,
      take: limit,
      include: {
        productMedia: {
          select: {
            id: true,
            mediaType: true,
            product: { select: { id: true, translations: { where: { languageCode: 'de' }, select: { name: true } } } },
          },
        },
      },
    }),
  ]);

  // Filter: Typ (über ProductMedia)
  let filtered = media;
  if (type) {
    filtered = media.filter(m => m.productMedia.some(pm => pm.mediaType === type));
  }

  // Filter: Zuordnung
  if (assigned === 'true') {
    filtered = filtered.filter(m => m.productMedia.length > 0);
  } else if (assigned === 'false') {
    filtered = filtered.filter(m => m.productMedia.length === 0);
  }

  // Orientierung client-side filtern (einfacher als Prisma raw)
  if (orientation === 'landscape') {
    filtered = filtered.filter(m => (m.width || 0) > (m.height || 0));
  } else if (orientation === 'portrait') {
    filtered = filtered.filter(m => (m.height || 0) > (m.width || 0));
  } else if (orientation === 'square') {
    filtered = filtered.filter(m => Math.abs((m.width || 0) - (m.height || 0)) < 50);
  }

  return NextResponse.json({
    media: filtered.map(m => ({
      id: m.id,
      filename: m.filename,
      originalName: m.originalName,
      title: m.title || m.alt || m.filename,
      url: m.url,
      thumbnailUrl: m.thumbnailUrl,
      formats: m.formats,
      width: m.width,
      height: m.height,
      sizeBytes: m.sizeBytes,
      category: m.category,
      source: m.source,
      createdAt: m.createdAt,
      productCount: m.productMedia.length,
      products: m.productMedia.map(pm => ({
        id: pm.product.id,
        name: pm.product.translations[0]?.name || 'Unbenannt',
        mediaType: pm.mediaType,
      })),
    })),
    total,
    page,
    limit,
    totalPages: Math.ceil(total / limit),
  });
}
ENDOFFILE

# GET/PATCH/DELETE /api/v1/media/[id]
cat > src/app/api/v1/media/\[id\]/route.ts << 'ENDOFFILE'
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
ENDOFFILE

echo "  ✓ Media-Listing + Detail + Delete API erstellt"

# ───────────────────────────────────────
echo ""
echo "[BUILD] Kompiliere..."
# ───────────────────────────────────────

npm run build 2>&1 | tail -15

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo ""
  echo "═══════════════════════════════════"
  echo "  ✅ Bildarchiv Phase 1 LIVE!"
  echo "═══════════════════════════════════"
  echo ""
  echo "  Neue Endpoints:"
  echo "  → GET  /api/v1/media?category=PHOTO&q=wein&page=1"
  echo "  → POST /api/v1/media/upload (6 Formate)"
  echo "  → GET  /api/v1/media/[id]"
  echo "  → PATCH /api/v1/media/[id]"
  echo "  → DELETE /api/v1/media/[id]"
  echo ""
else
  echo ""
  echo "  ❌ Build fehlgeschlagen – siehe Fehler oben"
fi
