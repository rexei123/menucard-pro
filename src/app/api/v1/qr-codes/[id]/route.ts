// @ts-nocheck
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

// Prueft, ob ein QR-Code zum Mandanten gehoert (via locationId oder menu.location.tenantId).
// QRCode hat keine Prisma-Relation "location", deshalb separate Pruefung.
async function getTenantQr(id: string, tenantId: string) {
  const qr = await prisma.qRCode.findUnique({
    where: { id },
    include: { menu: { include: { location: true } } },
  });
  if (!qr) return null;

  if (qr.locationId) {
    const loc = await prisma.location.findUnique({ where: { id: qr.locationId } });
    if (loc?.tenantId === tenantId) return qr;
  }
  if (qr.menu?.location?.tenantId === tenantId) return qr;
  return null;
}

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const body = await req.json();
  const qr = await getTenantQr(params.id, session.user.tenantId);
  if (!qr) return NextResponse.json({ error: 'Not found' }, { status: 404 });
  const updated = await prisma.qRCode.update({ where: { id: params.id }, data: body });
  return NextResponse.json(updated);
}

export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const qr = await getTenantQr(params.id, session.user.tenantId);
  if (!qr) return NextResponse.json({ error: 'Not found' }, { status: 404 });
  await prisma.qRCode.delete({ where: { id: params.id } });
  return NextResponse.json({ success: true });
}
