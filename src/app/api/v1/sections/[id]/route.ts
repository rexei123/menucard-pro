// @ts-nocheck
// ============================================================================
// PATCH  /api/v1/sections/[id]  — Sektion aktualisieren (Name, Icon, sortOrder)
// DELETE /api/v1/sections/[id]  — Sektion löschen (Placements kaskadieren)
// ----------------------------------------------------------------------------
// Tenant-Scope über section.menu.location.tenantId.
// DELETE mit ?force=true erlaubt Löschung auch wenn noch Produkte platziert sind.
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

  // Name-Updates via Translation upsert
  const nameDe: string | undefined = typeof body.name === 'string' ? body.name.trim() : undefined;
  const nameEn: string | undefined = typeof body.nameEn === 'string' ? body.nameEn.trim() : undefined;

  if (nameDe !== undefined && nameDe.length > 80) {
    return NextResponse.json({ error: 'Name ist zu lang (max. 80 Zeichen)' }, { status: 400 });
  }
  if (nameEn !== undefined && nameEn.length > 80) {
    return NextResponse.json({ error: 'Name (EN) ist zu lang (max. 80 Zeichen)' }, { status: 400 });
  }

  // Transaktion: Sektion + ggf. Translations
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

export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;

  const section = await getScopedSection(params.id, tid);
  if (!section) return NextResponse.json({ error: 'Nicht gefunden' }, { status: 404 });

  const url = new URL(req.url);
  const force = url.searchParams.get('force') === 'true';

  if (section._count.children > 0) {
    return NextResponse.json(
      { error: 'Unter-Sektionen vorhanden. Bitte zuerst Unter-Sektionen entfernen.' },
      { status: 400 },
    );
  }
  if (section._count.placements > 0 && !force) {
    return NextResponse.json(
      {
        error: 'Sektion enthält Produkte',
        requiresForce: true,
        placementCount: section._count.placements,
      },
      { status: 409 },
    );
  }

  // Platzierungen kaskadieren über Prisma-Relation (onDelete: Cascade)
  await prisma.menuSection.delete({ where: { id: section.id } });
  return NextResponse.json({ success: true });
}
