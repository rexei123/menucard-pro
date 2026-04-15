import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

export async function GET(_req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const menu = await prisma.menu.findUnique({
    where: { id: params.id },
    include: { template: true },
  });
  if (!menu) return NextResponse.json({ error: 'Karte nicht gefunden' }, { status: 404 });

  return NextResponse.json({ template: menu.template, templateId: menu.templateId });
}

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await req.json();
  const { templateId } = body;
  if (!templateId) return NextResponse.json({ error: 'templateId erforderlich' }, { status: 400 });

  const template = await prisma.designTemplate.findUnique({ where: { id: templateId } });
  if (!template) return NextResponse.json({ error: 'Vorlage nicht gefunden' }, { status: 404 });
  if (template.isArchived) {
    return NextResponse.json({ error: 'Archivierte Vorlagen koennen Karten nicht zugewiesen werden.' }, { status: 400 });
  }

  const updated = await prisma.menu.update({
    where: { id: params.id },
    data: { templateId },
    include: { template: true },
  });

  return NextResponse.json({ menu: updated });
}
