#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Deploying Image System ==="

echo "1/6 Installing sharp..."
npm install sharp@0.33.2 --save

echo "2/6 Creating upload directories..."
mkdir -p public/uploads/original public/uploads/large public/uploads/medium public/uploads/thumb

echo "3/6 Creating Media Upload API..."

mkdir -p src/app/api/v1/media
cat > src/app/api/v1/media/upload/route.ts << 'ENDFILE'
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
ENDFILE

# Media delete + update API
mkdir -p "src/app/api/v1/media/[id]"
cat > "src/app/api/v1/media/[id]/route.ts" << 'ENDFILE'
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
ENDFILE

echo "4/6 Creating Image Upload Component..."

cat > src/components/admin/product-images.tsx << 'ENDFILE'
'use client';

import { useState, useRef } from 'react';

type ImageData = {
  id: string;
  mediaId: string | null;
  url: string;
  thumbUrl: string;
  mediaType: string;
  isPrimary: boolean;
  sortOrder: number;
};

const typeLabels: Record<string, string> = {
  LABEL: 'Etikett',
  BOTTLE: 'Flasche',
  SERVING: 'Serviervorschlag',
  AMBIANCE: 'Ambiente',
  LOGO: 'Logo',
  DOCUMENT: 'Dokument',
  OTHER: 'Sonstige',
};

const typeOptions = Object.entries(typeLabels).map(([value, label]) => ({ value, label }));

export default function ProductImages({ productId, initialImages }: { productId: string; initialImages: ImageData[] }) {
  const [images, setImages] = useState<ImageData[]>(initialImages);
  const [uploading, setUploading] = useState(false);
  const [dragOver, setDragOver] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  const upload = async (files: FileList | File[]) => {
    setUploading(true);
    for (const file of Array.from(files)) {
      if (file.size > 4 * 1024 * 1024) { alert(`${file.name}: Max 4MB`); continue; }
      const form = new FormData();
      form.append('file', file);
      form.append('productId', productId);
      form.append('mediaType', 'OTHER');

      try {
        const res = await fetch('/api/v1/media/upload', { method: 'POST', credentials: 'include', body: form });
        if (res.ok) {
          const data = await res.json();
          setImages(prev => [...prev, data]);
        } else {
          const err = await res.json();
          alert(err.error || 'Upload fehlgeschlagen');
        }
      } catch { alert('Upload fehlgeschlagen'); }
    }
    setUploading(false);
  };

  const remove = async (id: string) => {
    const res = await fetch(`/api/v1/media/${id}`, { method: 'DELETE', credentials: 'include' });
    if (res.ok) setImages(prev => prev.filter(img => img.id !== id));
  };

  const setPrimary = async (id: string) => {
    const res = await fetch(`/api/v1/media/${id}`, {
      method: 'PATCH', credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ isPrimary: true }),
    });
    if (res.ok) setImages(prev => prev.map(img => ({ ...img, isPrimary: img.id === id })));
  };

  const setType = async (id: string, mediaType: string) => {
    const res = await fetch(`/api/v1/media/${id}`, {
      method: 'PATCH', credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ mediaType }),
    });
    if (res.ok) setImages(prev => prev.map(img => img.id === id ? { ...img, mediaType } : img));
  };

  const onDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
    if (e.dataTransfer.files?.length) upload(e.dataTransfer.files);
  };

  return (
    <section className="rounded-xl border bg-white p-5 shadow-sm">
      <div className="flex items-center justify-between mb-3">
        <h2 className="text-base font-semibold text-gray-500">📸 Bilder</h2>
        <button onClick={() => fileRef.current?.click()} disabled={uploading}
          className="rounded-lg px-3 py-1.5 text-sm font-medium text-white disabled:opacity-50" style={{backgroundColor:'#8B6914'}}>
          {uploading ? '⏳ Lädt...' : '+ Bild hochladen'}
        </button>
        <input ref={fileRef} type="file" accept="image/*" multiple className="hidden" onChange={e => e.target.files && upload(e.target.files)} />
      </div>

      {/* Image Grid */}
      {images.length > 0 && (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3 mb-3">
          {images.map(img => (
            <div key={img.id} className={`relative group rounded-lg border overflow-hidden ${img.isPrimary ? 'ring-2 ring-amber-400' : ''}`}>
              <img src={img.thumbUrl || img.url} alt="" className="w-full h-32 object-cover" />
              {img.isPrimary && (
                <span className="absolute top-1 left-1 bg-amber-400 text-white text-[10px] font-bold px-1.5 py-0.5 rounded">⭐ Hauptbild</span>
              )}
              {/* Hover Overlay */}
              <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center justify-center gap-1.5">
                {!img.isPrimary && (
                  <button onClick={() => setPrimary(img.id)} className="text-sm text-white bg-amber-500 rounded px-2 py-1 hover:bg-amber-600">⭐ Hauptbild</button>
                )}
                <select value={img.mediaType} onChange={e => setType(img.id, e.target.value)}
                  className="text-sm rounded px-2 py-1 bg-white/90 text-gray-800 outline-none">
                  {typeOptions.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
                </select>
                <button onClick={() => remove(img.id)} className="text-sm text-white bg-red-500 rounded px-2 py-1 hover:bg-red-600">✕ Löschen</button>
              </div>
              <div className="px-2 py-1 bg-gray-50 text-[10px] text-gray-500 text-center">
                {typeLabels[img.mediaType] || img.mediaType}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Drop Zone */}
      <div
        onDragOver={e => { e.preventDefault(); setDragOver(true); }}
        onDragLeave={() => setDragOver(false)}
        onDrop={onDrop}
        onClick={() => fileRef.current?.click()}
        className={`rounded-lg border-2 border-dashed p-6 text-center cursor-pointer transition-colors ${dragOver ? 'border-blue-400 bg-blue-50' : 'border-gray-200 hover:border-gray-400 hover:bg-gray-50'}`}
      >
        <p className="text-base text-gray-400">{uploading ? '⏳ Wird hochgeladen...' : dragOver ? '📥 Hier ablegen' : '📸 Bilder hierher ziehen oder klicken'}</p>
        <p className="text-sm text-gray-300 mt-1">JPEG, PNG, WebP · Max 4MB · Automatisch optimiert</p>
      </div>
    </section>
  );
}
ENDFILE

echo "5/6 Adding images to product editor..."

python3 << 'PYEOF'
# Update product detail page to load and pass images
c = open('src/app/admin/items/[id]/page.tsx').read()

# Add productMedia to includes if not already there
if 'productMedia' not in c.split('product = await')[1].split('});')[0]:
    c = c.replace(
        "productBevDetail: true,",
        "productBevDetail: true,\n      productMedia: { include: { media: true }, orderBy: { sortOrder: 'asc' } },"
    )

# Add images to serialized data
if 'images:' not in c:
    c = c.replace(
        "createdAt: product.createdAt.toISOString(),",
        """images: (product.productMedia || []).map((pm: any) => ({
      id: pm.id,
      mediaId: pm.mediaId,
      url: pm.url || pm.media?.url || '',
      thumbUrl: pm.media?.thumbnailUrl || pm.url || '',
      mediaType: pm.mediaType,
      isPrimary: pm.isPrimary,
      sortOrder: pm.sortOrder,
    })),
    createdAt: product.createdAt.toISOString(),"""
    )

# Add ProductImages import and component
if 'ProductImages' not in c:
    c = c.replace(
        "import ProductEditor from '@/components/admin/product-editor';",
        "import ProductEditor from '@/components/admin/product-editor';\nimport ProductImages from '@/components/admin/product-images';"
    )
    c = c.replace(
        "return <ProductEditor product={data} options={opts} />;",
        "return <>\n    <ProductEditor product={data} options={opts} />\n    <ProductImages productId={product.id} initialImages={data.images || []} />\n  </>;"
    )

open('src/app/admin/items/[id]/page.tsx', 'w').write(c)
print('Detail page updated')
PYEOF

echo "6/6 Building..."
npm run build; pm2 restart menucard-pro

echo ""
echo "=== Image System deployed! ==="
echo "Test: /admin/items → Produkt öffnen → Bilder-Bereich unten"
