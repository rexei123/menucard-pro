import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

const MAX_CUSTOM_ACTIVE = 6;

export async function POST(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const source = await prisma.designTemplate.findUnique({ where: { id: params.id } });
  if (!source) return NextResponse.json({ error: 'Quell-Vorlage nicht gefunden' }, { status: 404 });

  const activeCount = await prisma.designTemplate.count({
    where: { type: 'CUSTOM', isArchived: false },
  });
  if (activeCount >= MAX_CUSTOM_ACTIVE) {
    return NextResponse.json(
      { error: `Maximal ${MAX_CUSTOM_ACTIVE} aktive eigene Vorlagen. Bitte archivieren Sie zuerst eine bestehende Vorlage.` },
      { status: 409 }
    );
  }

  const body = await req.json().catch(() => ({}));
  let baseName = typeof body.name === 'string' && body.name ? body.name : `${source.name} (Kopie)`;

  // eindeutigen Namen finden
  let name = baseName;
  let counter = 2;
  while (await prisma.designTemplate.findUnique({ where: { name } })) {
    name = `${baseName} ${counter}`;
    counter++;
    if (counter > 20) break;
  }

  const copy = await prisma.designTemplate.create({
    data: {
      name,
      type: 'CUSTOM',
      baseType: source.baseType,
      config: source.config as any,
      createdBy: session.user?.email ?? null,
    },
  });

  return NextResponse.json({ template: copy }, { status: 201 });
}
