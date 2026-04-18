// @ts-nocheck
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function GET(req, { params }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const node = await prisma.taxonomyNode.findUnique({
    where: { id: params.id },
    include: {
      translations: true,
      children: { include: { translations: true, _count: { select: { products: true } } }, orderBy: { sortOrder: 'asc' } },
      parent: { include: { translations: true } },
      _count: { select: { products: true, children: true } },
    },
  });
  if (!node) return NextResponse.json({ error: 'Nicht gefunden' }, { status: 404 });

  return NextResponse.json(node);
}

export async function PATCH(req, { params }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const node = await prisma.taxonomyNode.findUnique({ where: { id: params.id } });
  if (!node || node.tenantId !== session.user.tenantId) {
    return NextResponse.json({ error: 'Nicht gefunden' }, { status: 404 });
  }

  const body = await req.json();
  const { translations, ...nodeData } = body;

  const updatable = {};
  if (nodeData.name !== undefined) updatable.name = nodeData.name;
  if (nodeData.icon !== undefined) updatable.icon = nodeData.icon;
  if (nodeData.sortOrder !== undefined) updatable.sortOrder = nodeData.sortOrder;
  if (nodeData.taxRate !== undefined) updatable.taxRate = nodeData.taxRate;
  if (nodeData.taxLabel !== undefined) updatable.taxLabel = nodeData.taxLabel;

  // parentId ändern (Node umhängen) + Depth-Kaskade
  if (nodeData.parentId !== undefined) {
    updatable.parentId = nodeData.parentId || null;
    if (nodeData.parentId) {
      const newParent = await prisma.taxonomyNode.findUnique({ where: { id: nodeData.parentId } });
      updatable.depth = newParent ? newParent.depth + 1 : 0;
    } else {
      updatable.depth = 0;
    }
  }

  if (Object.keys(updatable).length > 0) {
    await prisma.taxonomyNode.update({ where: { id: params.id }, data: updatable });
  }

  // Kinder-Depth rekursiv anpassen wenn parentId geändert
  if (nodeData.parentId !== undefined) {
    const updateChildrenDepth = async (pid, pDepth) => {
      const kids = await prisma.taxonomyNode.findMany({ where: { parentId: pid } });
      for (const kid of kids) {
        await prisma.taxonomyNode.update({ where: { id: kid.id }, data: { depth: pDepth + 1 } });
        await updateChildrenDepth(kid.id, pDepth + 1);
      }
    };
    const freshNode = await prisma.taxonomyNode.findUnique({ where: { id: params.id } });
    if (freshNode) await updateChildrenDepth(params.id, freshNode.depth);
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
    include: { translations: true, _count: { select: { products: true, children: true } } },
  });
  return NextResponse.json(updated);
}

export async function DELETE(req, { params }) {
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
