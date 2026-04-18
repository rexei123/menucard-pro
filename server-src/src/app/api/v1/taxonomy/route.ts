import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

// ─── GET: Taxonomie-Baum abfragen ───
// ?type=CATEGORY — nur bestimmten Typ
// ?parentId=xxx — nur Kinder eines Knotens
// ?flat=true — flache Liste statt Baum
export async function GET(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;

  const { searchParams } = new URL(req.url);
  const type = searchParams.get('type');
  const parentId = searchParams.get('parentId');
  const flat = searchParams.get('flat') === 'true';

  const where: any = { tenantId: tid };
  if (type) where.type = type;
  if (parentId) where.parentId = parentId;
  else if (!flat) where.parentId = null; // nur Root-Knoten

  const nodes = await prisma.taxonomyNode.findMany({
    where,
    include: {
      translations: true,
      children: {
        include: {
          translations: true,
          children: {
            include: {
              translations: true,
              children: {
                include: { translations: true },
                orderBy: { sortOrder: 'asc' },
              },
            },
            orderBy: { sortOrder: 'asc' },
          },
        },
        orderBy: { sortOrder: 'asc' },
      },
      _count: { select: { products: true } },
    },
    orderBy: { sortOrder: 'asc' },
  });

  return NextResponse.json(nodes);
}

// ─── POST: Neuen Taxonomie-Knoten anlegen ───
export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;

  const body = await req.json();
  if (!body.name || !body.type) {
    return NextResponse.json({ error: 'name und type erforderlich' }, { status: 400 });
  }

  const slug = body.slug || body.name.toLowerCase()
    .replace(/[äÄ]/g, 'ae').replace(/[öÖ]/g, 'oe').replace(/[üÜ]/g, 'ue').replace(/ß/g, 'ss')
    .replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

  // Tiefe ermitteln
  let depth = 0;
  if (body.parentId) {
    const parent = await prisma.taxonomyNode.findUnique({ where: { id: body.parentId }, select: { depth: true } });
    depth = (parent?.depth ?? -1) + 1;
  }

  const node = await prisma.taxonomyNode.create({
    data: {
      tenantId: tid,
      name: body.name,
      slug,
      type: body.type,
      parentId: body.parentId || null,
      depth,
      sortOrder: body.sortOrder ?? 0,
      icon: body.icon || null,
      translations: {
        create: [
          { language: 'de', name: body.name },
          ...(body.nameEn ? [{ language: 'en', name: body.nameEn }] : []),
        ],
      },
    },
    include: { translations: true },
  });

  return NextResponse.json(node, { status: 201 });
}
