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
