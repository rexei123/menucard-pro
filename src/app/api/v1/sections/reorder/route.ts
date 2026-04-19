// @ts-nocheck
// ============================================================================
// POST /api/v1/sections/reorder
// ----------------------------------------------------------------------------
// Batch-Reorder der Sektionen einer Karte. Body:
//   { menuId: string, sectionIds: string[] }
//
// Die Reihenfolge in sectionIds definiert den neuen sortOrder (Index 0..n).
// Tenant-Scope: Karte muss dem eigenen Mandanten gehören, alle sectionIds
// müssen zu dieser Karte gehören.
// ============================================================================

import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;

  const body = await req.json().catch(() => ({}));
  const menuId: string = body.menuId;
  const sectionIds: string[] = Array.isArray(body.sectionIds) ? body.sectionIds : [];

  if (!menuId || sectionIds.length === 0) {
    return NextResponse.json({ error: 'menuId und sectionIds erforderlich' }, { status: 400 });
  }

  // Karte muss dem Mandanten gehören
  const menu = await prisma.menu.findFirst({
    where: { id: menuId, location: { tenantId: tid } },
    select: { id: true },
  });
  if (!menu) return NextResponse.json({ error: 'Karte nicht gefunden' }, { status: 404 });

  // Alle Sektionen einmal laden und verifizieren, dass sie zur Karte gehören
  const existing = await prisma.menuSection.findMany({
    where: { menuId, id: { in: sectionIds } },
    select: { id: true },
  });
  if (existing.length !== sectionIds.length) {
    return NextResponse.json({ error: 'Unbekannte Sektionen im Payload' }, { status: 400 });
  }

  // In einer Transaktion alle sortOrder setzen
  await prisma.$transaction(
    sectionIds.map((id, idx) =>
      prisma.menuSection.update({ where: { id }, data: { sortOrder: idx } }),
    ),
  );

  return NextResponse.json({ success: true, count: sectionIds.length });
}
