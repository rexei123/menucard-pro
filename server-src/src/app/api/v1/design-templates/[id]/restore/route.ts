import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

const MAX_CUSTOM_ACTIVE = 6;

export async function POST(_req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const template = await prisma.designTemplate.findUnique({ where: { id: params.id } });
  if (!template) return NextResponse.json({ error: 'Not found' }, { status: 404 });
  if (!template.isArchived) return NextResponse.json({ error: 'Nicht archiviert.' }, { status: 400 });

  if (template.type === 'CUSTOM') {
    const activeCount = await prisma.designTemplate.count({
      where: { type: 'CUSTOM', isArchived: false },
    });
    if (activeCount >= MAX_CUSTOM_ACTIVE) {
      return NextResponse.json(
        { error: `Maximal ${MAX_CUSTOM_ACTIVE} aktive eigene Vorlagen. Bitte archivieren Sie zuerst eine andere Vorlage.` },
        { status: 409 }
      );
    }
  }

  const restored = await prisma.designTemplate.update({
    where: { id: params.id },
    data: { isArchived: false },
  });

  return NextResponse.json({ template: restored });
}
