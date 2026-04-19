// @ts-nocheck
// ============================================================================
// POST /api/v1/sections
// ----------------------------------------------------------------------------
// Neue Sektion (Kategorie) innerhalb einer Karte anlegen.
// Body: { menuId, name, nameEn?, icon?, parentId? }
//
// Slug wird aus dem Namen generiert, bei Kollision mit -2, -3, ... inkrementiert.
// sortOrder = max(sortOrder der Geschwister) + 1.
// Tenant-Scope: Sektion darf nur in eigenen Menüs angelegt werden.
// ============================================================================

import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

function slugify(input: string): string {
  return (input || '')
    .toLowerCase()
    .replace(/ä/g, 'ae')
    .replace(/ö/g, 'oe')
    .replace(/ü/g, 'ue')
    .replace(/ß/g, 'ss')
    .replace(/é/g, 'e')
    .replace(/è/g, 'e')
    .replace(/à/g, 'a')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '')
    .slice(0, 60) || 'sektion';
}

async function assertMenuInTenant(menuId: string, tenantId: string) {
  const m = await prisma.menu.findFirst({
    where: { id: menuId, location: { tenantId } },
    select: { id: true },
  });
  return !!m;
}

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;

  const body = await req.json().catch(() => ({}));
  const menuId: string = body.menuId;
  const name: string = (body.name || '').trim();
  const nameEn: string = (body.nameEn || '').trim();
  const icon: string | null = body.icon || null;
  const parentId: string | null = body.parentId || null;

  if (!menuId || !name) {
    return NextResponse.json({ error: 'menuId und name sind erforderlich' }, { status: 400 });
  }
  if (name.length > 80) {
    return NextResponse.json({ error: 'Name ist zu lang (max. 80 Zeichen)' }, { status: 400 });
  }

  const okMenu = await assertMenuInTenant(menuId, tid);
  if (!okMenu) return NextResponse.json({ error: 'Karte nicht gefunden' }, { status: 404 });

  // Depth aus Parent
  let depth = 0;
  if (parentId) {
    const parent = await prisma.menuSection.findFirst({
      where: { id: parentId, menuId },
      select: { depth: true },
    });
    if (!parent) return NextResponse.json({ error: 'Parent-Sektion nicht gefunden' }, { status: 404 });
    depth = parent.depth + 1;
    if (depth > 2) {
      return NextResponse.json({ error: 'Maximale Verschachtelungstiefe erreicht' }, { status: 400 });
    }
  }

  // Unique Slug pro Menu
  const baseSlug = slugify(name);
  let slug = baseSlug;
  let counter = 2;
  while (await prisma.menuSection.findUnique({ where: { menuId_slug: { menuId, slug } } })) {
    slug = `${baseSlug}-${counter}`;
    counter++;
  }

  // Naechste sortOrder unter gleichem Parent
  const maxSort = await prisma.menuSection.findFirst({
    where: { menuId, parentId: parentId || null },
    orderBy: { sortOrder: 'desc' },
    select: { sortOrder: true },
  });

  const section = await prisma.menuSection.create({
    data: {
      menuId,
      parentId: parentId || null,
      slug,
      icon: icon || null,
      depth,
      sortOrder: (maxSort?.sortOrder ?? -1) + 1,
      translations: {
        create: [
          { language: 'de', languageCode: 'de', name },
          { language: 'en', languageCode: 'en', name: nameEn || name },
        ],
      },
    },
    include: { translations: true },
  });

  return NextResponse.json(section, { status: 201 });
}
