// @ts-nocheck
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function GET(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;

  const { searchParams } = new URL(req.url);
  const type = searchParams.get('type') || undefined;
  const parentId = searchParams.get('parentId') || undefined;

  const nodes = await prisma.taxonomyNode.findMany({
    where: {
      tenantId: tid,
      ...(type ? { type } : {}),
      ...(parentId ? { parentId } : parentId === 'null' ? { parentId: null } : {}),
    },
    include: {
      translations: true,
      children: { include: { translations: true } },
      parent: { include: { translations: true } },
      _count: { select: { products: true } },
    },
    orderBy: [{ type: 'asc' }, { sortOrder: 'asc' }],
  });

  return NextResponse.json(nodes);
}

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;
  const body = await req.json();

  const { name, type, parentId, icon, translations } = body;
  if (!name || !type) {
    return NextResponse.json({ error: 'name und type sind erforderlich' }, { status: 400 });
  }

  // Slug generieren
  const baseSlug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
  let slug = baseSlug;
  let counter = 2;
  while (await prisma.taxonomyNode.findUnique({ where: { tenantId_type_slug: { tenantId: tid, type, slug } } })) {
    slug = `${baseSlug}-${counter}`;
    counter++;
  }

  // Depth berechnen
  let depth = 0;
  if (parentId) {
    const parent = await prisma.taxonomyNode.findUnique({ where: { id: parentId } });
    if (parent) depth = parent.depth + 1;
  }

  // Nächste sortOrder
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
        create: translations || [{ language: 'de', name }],
      },
    },
    include: { translations: true },
  });

  return NextResponse.json(node, { status: 201 });
}
