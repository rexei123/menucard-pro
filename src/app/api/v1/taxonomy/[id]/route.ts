// @ts-nocheck
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const node = await prisma.taxonomyNode.findUnique({
    where: { id: params.id },
    include: {
      translations: true,
      children: { include: { translations: true }, orderBy: { sortOrder: 'asc' } },
      parent: { include: { translations: true } },
      products: { include: { product: { include: { translations: true } } } },
    },
  });
  if (!node) return NextResponse.json({ error: 'Nicht gefunden' }, { status: 404 });

  return NextResponse.json(node);
}

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const node = await prisma.taxonomyNode.findUnique({ where: { id: params.id } });
  if (!node || node.tenantId !== session.user.tenantId) {
    return NextResponse.json({ error: 'Nicht gefunden' }, { status: 404 });
  }

  const body = await req.json();
  const { translations, ...nodeData } = body;

  // Basisfelder aktualisieren
  const updatable: any = {};
  if (nodeData.name !== undefined) updatable.name = nodeData.name;
  if (nodeData.icon !== undefined) updatable.icon = nodeData.icon;
  if (nodeData.sortOrder !== undefined) updatable.sortOrder = nodeData.sortOrder;

  if (Object.keys(updatable).length > 0) {
    await prisma.taxonomyNode.update({ where: { id: params.id }, data: updatable });
  }

  // Übersetzungen upserten
  if (translations) {
    for (const t of translations) {
      await prisma.taxonomyNodeTranslation.upsert({
        where: { nodeId_language: { nodeId: params.id, language: t.language } },
        update: { name: t.name },
        create: { nodeId: params.id, language: t.language, name: t.name },
      });
    }
  }

  const updated = await prisma.taxonomyNode.findUnique({
    where: { id: params.id },
    include: { translations: true },
  });
  return NextResponse.json(updated);
}

export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const node = await prisma.taxonomyNode.findUnique({
    where: { id: params.id },
    include: { _count: { select: { products: true, children: true } } },
  });
  if (!node || node.tenantId !== session.user.tenantId) {
    return NextResponse.json({ error: 'Nicht gefunden' }, { status: 404 });
  }

  if (node._count.products > 0) {
    return NextResponse.json(
      { error: `Kann nicht gelöscht werden — ${node._count.products} Produkte zugeordnet` },
      { status: 409 }
    );
  }
  if (node._count.children > 0) {
    return NextResponse.json(
      { error: `Kann nicht gelöscht werden — ${node._count.children} Unterknoten vorhanden` },
      { status: 409 }
    );
  }

  await prisma.taxonomyNodeTranslation.deleteMany({ where: { nodeId: params.id } });
  await prisma.taxonomyNode.delete({ where: { id: params.id } });

  return NextResponse.json({ success: true });
}
