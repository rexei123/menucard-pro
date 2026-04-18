import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

function deepMergeTpl(target: any, source: any): any {
  if (!source) return target;
  if (!target) return source;
  const result = { ...target };
  for (const key of Object.keys(source)) {
    if (source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])) {
      result[key] = deepMergeTpl(target[key] || {}, source[key]);
    } else {
      result[key] = source[key];
    }
  }
  return result;
}

export async function GET(_req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const template = await prisma.designTemplate.findUnique({
    where: { id: params.id },
    include: { _count: { select: { menus: true } }, menus: { select: { id: true, slug: true } } },
  });
  if (!template) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  return NextResponse.json({ template });
}

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const template = await prisma.designTemplate.findUnique({ where: { id: params.id } });
  if (!template) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  if (template.type === 'SYSTEM') {
    return NextResponse.json({ error: 'System-Vorlagen koennen nicht bearbeitet werden. Bitte duplizieren.' }, { status: 403 });
  }

  const body = await req.json();
  const data: any = {};
  if (typeof body.name === 'string') data.name = body.name;
  if (typeof body.baseType === 'string') data.baseType = body.baseType;
  if (body.config !== undefined) data.config = deepMergeTpl((template.config as any) || {}, body.config);

  // Namenskollision (name ist nicht unique - findFirst + NOT id)
  if (data.name && data.name !== template.name) {
    const conflict = await prisma.designTemplate.findFirst({
      where: { name: data.name, NOT: { id: params.id } },
    });
    if (conflict) return NextResponse.json({ error: 'Name bereits vergeben.' }, { status: 409 });
  }

  const updated = await prisma.designTemplate.update({
    where: { id: params.id },
    data,
  });

  return NextResponse.json({ template: updated });
}

export async function DELETE(_req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const template = await prisma.designTemplate.findUnique({
    where: { id: params.id },
    include: { _count: { select: { menus: true } } },
  });
  if (!template) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  if (template.type === 'SYSTEM') {
    return NextResponse.json({ error: 'System-Vorlagen koennen nicht geloescht werden.' }, { status: 403 });
  }
  if (template._count.menus > 0) {
    return NextResponse.json(
      { error: `Diese Vorlage wird von ${template._count.menus} Karte(n) genutzt. Bitte weisen Sie die Karten zuerst einer anderen Vorlage zu.` },
      { status: 409 }
    );
  }

  // Soft-Delete: archivieren
  const archived = await prisma.designTemplate.update({
    where: { id: params.id },
    data: { isArchived: true },
  });

  return NextResponse.json({ template: archived, archived: true });
}
