// @ts-nocheck
// ============================================================================
// PATCH  /api/v1/sections/[id]  — Sektion aktualisieren (Name, Icon, sortOrder)
// DELETE /api/v1/sections/[id]  — Sektion löschen (Placements + Children kaskadieren)
// ----------------------------------------------------------------------------
// Tenant-Scope über section.menu.location.tenantId.
// DELETE mit ?force=true erlaubt Löschung auch bei Produkten/Unter-Sektionen.
// Ohne force: 409 mit requiresForce + Zähler, wenn nicht leer.
// ============================================================================

import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

async function getScopedSection(id: string, tenantId: string) {
  return prisma.menuSection.findFirst({
    where: { id, menu: { location: { tenantId } } },
    include: {
      translations: true,
      _count: { select: { placements: true, children: true } },
    },
  });
}

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;

  const section = await getScopedSection(params.id, tid);
  if (!section) return NextResponse.json({ error: 'Nicht gefunden' }, { status: 404 });

  const body = await req.json().catch(() => ({}));
  const data: any = {};
  if (typeof body.icon !== 'undefined') data.icon = body.icon || null;
  if (typeof body.sortOrder === 'number') data.sortOrder = body.sortOrder;

  const nameDe: string | undefined = typeof body.name === 'string' ? body.name.trim() : undefined;
  const nameEn: string | undefined = typeof body.nameEn === 'string' ? body.nameEn.trim() : undefined;

  if (nameDe !== undefined && nameDe.length > 80) {
    return NextResponse.json({ error: 'Name ist zu lang (max. 80 Zeichen)' }, { status: 400 });
  }
  if (nameEn !== undefined && nameEn.length > 80) {
    return NextResponse.json({ error: 'Name (EN) ist zu lang (max. 80 Zeichen)' }, { status: 400 });
  }

  const updated = await prisma.$transaction(async (tx) => {
    if (Object.keys(data).length > 0) {
      await tx.menuSection.update({ where: { id: section.id }, data });
    }
    if (nameDe !== undefined && nameDe.length > 0) {
      await tx.menuSectionTranslation.upsert({
        where: { sectionId_language: { sectionId: section.id, language: 'de' } },
        update: { name: nameDe, languageCode: 'de' },
        create: { sectionId: section.id, language: 'de', languageCode: 'de', name: nameDe },
      });
    }
    if (nameEn !== undefined && nameEn.length > 0) {
      await tx.menuSectionTranslation.upsert({
        where: { sectionId_language: { sectionId: section.id, language: 'en' } },
        update: { name: nameEn, languageCode: 'en' },
        create: { sectionId: section.id, language: 'en', languageCode: 'en', name: nameEn },
      });
    }
    return tx.menuSection.findUnique({
      where: { id: section.id },
      include: { translations: true, _count: { select: { placements: true, children: true } } },
    });
  });

  return NextResponse.json(updated);
}

// ---------------------------------------------------------------------------
// DELETE
// ---------------------------------------------------------------------------
// Rekursiv alle Unter-Sektionen einer Section-ID sammeln.
// Wir sammeln bottom-up, damit beim Löschen keine FK-Constraints greifen.
async function collectDescendants(sectionId: string): Promise<string[]> {
  const result: string[] = [];
  const queue: string[] = [sectionId];
  while (queue.length > 0) {
    const cur = queue.shift() as string;
    const kids = await prisma.menuSection.findMany({
      where: { parentId: cur },
      select: { id: true },
    });
    for (const k of kids) {
      result.push(k.id);
      queue.push(k.id);
    }
  }
  return result;
}

export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  try {
    const session = await getServerSession(authOptions);
    if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    const tid = session.user.tenantId;

    const section = await getScopedSection(params.id, tid);
    if (!section) return NextResponse.json({ error: 'Sektion nicht gefunden' }, { status: 404 });

    const url = new URL(req.url);
    const force = url.searchParams.get('force') === 'true';

    const hasPlacements = section._count.placements > 0;
    const hasChildren = section._count.children > 0;

    // Ohne force: Bei nicht-leer nachfragen (UI zeigt dann Confirm mit Zählern)
    if (!force && (hasPlacements || hasChildren)) {
      return NextResponse.json(
        {
          error: hasChildren && hasPlacements
            ? `Sektion enthält ${section._count.placements} Produkt(e) und ${section._count.children} Unter-Sektion(en).`
            : hasChildren
              ? `Sektion enthält ${section._count.children} Unter-Sektion(en).`
              : `Sektion enthält ${section._count.placements} Produkt(e).`,
          requiresForce: true,
          placementCount: section._count.placements,
          childCount: section._count.children,
        },
        { status: 409 },
      );
    }

    // Force oder leer → löschen.
    // parent-Relation hat kein onDelete: Cascade → Children explizit bottom-up löschen.
    if (hasChildren) {
      const descendants = await collectDescendants(section.id);
      // descendants ist bereits in BFS-Reihenfolge, wir löschen einfach alle auf einmal
      // (ihre Placements + Translations cascaden, und Reihenfolge spielt keine Rolle
      // weil wir erst descendants, dann Self löschen)
      if (descendants.length > 0) {
        await prisma.menuSection.deleteMany({ where: { id: { in: descendants } } });
      }
    }

    await prisma.menuSection.delete({ where: { id: section.id } });
    return NextResponse.json({ success: true });
  } catch (e: any) {
    console.error('[DELETE /sections/:id] error:', e?.message || e, e?.code);
    return NextResponse.json(
      { error: `Löschung fehlgeschlagen: ${e?.message || 'Unbekannter Fehler'}` },
      { status: 500 },
    );
  }
}
