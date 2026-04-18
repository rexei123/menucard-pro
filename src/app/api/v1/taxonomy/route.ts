// @ts-nocheck
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

// Rekursive Kinder laden (max 4 Ebenen)
function buildInclude(depth) {
  if (depth <= 0) return { translations: true, _count: { select: { products: true, children: true } } };
  return {
    translations: true,
    _count: { select: { products: true, children: true } },
    children: {
      include: buildInclude(depth - 1),
      orderBy: { sortOrder: 'asc' },
    },
  };
}

export async function GET(req) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;

  const { searchParams } = new URL(req.url);
  const type = searchParams.get('type') || undefined;
  const parentId = searchParams.get('parentId') || undefined;
  const tree = searchParams.get('tree') === 'true';

  if (tree) {
    // Baum-Modus: Nur Root-Nodes laden, Kinder rekursiv includen
    const where = { tenantId: tid, parentId: null };
    if (type) where.type = type;

    const roots = await prisma.taxonomyNode.findMany({
      where,
      include: buildInclude(4),
      orderBy: [{ type: 'asc' }, { sortOrder: 'asc' }],
    });
    return NextResponse.json(roots);
  }

  // Flacher Modus (Kompatibilität)
  const nodes = await prisma.taxonomyNode.findMany({
    where: {
      tenantId: tid,
      ...(type ? { type } : {}),
      ...(parentId ? { parentId } : parentId === 'null' ? { parentId: null } : {}),
    },
    include: {
      translations: true,
      children: { include: { translations: true }, orderBy: { sortOrder: 'asc' } },
      parent: { include: { translations: true } },
      _count: { select: { products: true } },
    },
    orderBy: [{ type: 'asc' }, { sortOrder: 'asc' }],
  });

  return NextResponse.json(nodes);
}

export async function POST(req) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;
  const body = await req.json();

  const { name, type, parentId, icon, translations } = body;
  if (!name || !type) {
    return NextResponse.json({ error: 'name und type sind erforderlich' }, { status: 400 });
  }

  // Slug generieren (ASCII-safe)
  const baseSlug = name
    .toLowerCase()
    .replace(/ä/g, 'ae').replace(/ö/g, 'oe').replace(/ü/g, 'ue').replace(/ß/g, 'ss')
    .replace(/é/g, 'e').replace(/è/g, 'e').replace(/à/g, 'a')
    .replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
  let slug = baseSlug;
  let counter = 2;
  while (await prisma.taxonomyNode.findUnique({ where: { tenantId_type_slug: { tenantId: tid, type, slug } } })) {
    slug = `${baseSlug}-${counter}`;
    counter++;
  }

  // Depth aus Parent berechnen
  let depth = 0;
  if (parentId) {
    const parent = await prisma.taxonomyNode.findUnique({ where: { id: parentId } });
    if (parent) depth = parent.depth + 1;
  }

  // Nächste sortOrder unter gleichem Parent
  const maxSort = await prisma.taxonomyNode.findFirst({
    where: { tenantId: tid, type, parentId: parentId || null },
    orderBy: { sortOrder: 'desc' },
    select: { sortOrder: true },
  });

  const node = await prisma.taxonomyNode.create({
    data: {
      tenantId: tid,
      name,
      slug,
      type,
      parentId: parentId || null,
      depth,
      sortOrder: (maxSort?.sortOrder ?? -1) + 1,
      icon: icon || null,
      translations: {
        create: translations && translations.length > 0
          ? translations
          : [{ language: 'de', name }, { language: 'en', name }],
      },
    },
    include: { translations: true, _count: { select: { products: true, children: true } } },
  });

  return NextResponse.json(node, { status: 201 });
}
