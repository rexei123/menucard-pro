import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

const MAX_CUSTOM_ACTIVE = 6;

export async function GET(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { searchParams } = new URL(req.url);
  const includeArchived = searchParams.get('includeArchived') === 'true';

  const templates = await prisma.designTemplate.findMany({
    where: includeArchived ? {} : { isArchived: false },
    orderBy: [{ type: 'asc' }, { name: 'asc' }],
    include: {
      _count: { select: { menus: true } },
    },
  });

  return NextResponse.json({ templates });
}

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await req.json();
  const { name, baseType, config } = body;

  if (!name || !baseType || !config) {
    return NextResponse.json({ error: 'name, baseType und config erforderlich' }, { status: 400 });
  }

  // Cap pruefen
  const activeCustomCount = await prisma.designTemplate.count({
    where: { type: 'CUSTOM', isArchived: false },
  });
  if (activeCustomCount >= MAX_CUSTOM_ACTIVE) {
    return NextResponse.json(
      { error: `Maximal ${MAX_CUSTOM_ACTIVE} eigene Vorlagen aktiv. Bitte archivieren Sie zuerst eine bestehende Vorlage.` },
      { status: 409 }
    );
  }

  // Namens-Kollision (name ist in v2 nicht unique, wir verhindern Duplikate trotzdem)
  const existing = await prisma.designTemplate.findFirst({ where: { name } });
  if (existing) {
    return NextResponse.json({ error: 'Eine Vorlage mit diesem Namen existiert bereits.' }, { status: 409 });
  }

  // Eindeutigen key aus dem Namen generieren (slug-artig)
  const baseKey = String(name).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '') || 'template';
  let key = baseKey;
  let keyCounter = 2;
  while (await prisma.designTemplate.findUnique({ where: { key } })) {
    key = `${baseKey}-${keyCounter}`;
    keyCounter++;
    if (keyCounter > 50) break;
  }

  const template = await prisma.designTemplate.create({
    data: {
      name,
      key,
      type: 'CUSTOM',
      baseType,
      config,
    },
  });

  return NextResponse.json({ template }, { status: 201 });
}
