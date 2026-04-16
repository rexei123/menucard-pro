// @ts-nocheck
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import { generateShortCode } from '@/lib/utils';

export async function GET() {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;

  // v2: QR-Codes koennen locationId ODER menuId haben
  const qrCodes = await prisma.qRCode.findMany({
    where: {
      OR: [
        { location: { tenantId: tid } },
        { menu: { location: { tenantId: tid } } },
      ],
    },
    include: {
      location: true,
      menu: { include: { translations: true, location: true } },
    },
    orderBy: { createdAt: 'desc' },
  });
  return NextResponse.json(qrCodes);
}

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;
  const body = await req.json();
  const { menuId, label } = body;
  let { locationId } = body;

  // Location validieren oder aus Menu ableiten
  if (!locationId && menuId) {
    const menu = await prisma.menu.findUnique({
      where: { id: menuId },
      include: { location: true },
    });
    if (menu?.location?.tenantId === tid) {
      locationId = menu.locationId;
    }
  }

  if (locationId) {
    const location = await prisma.location.findFirst({ where: { id: locationId, tenantId: tid } });
    if (!location) return NextResponse.json({ error: 'Location not found' }, { status: 404 });
  }

  let shortCode = body.shortCode || generateShortCode(8);
  const existing = await prisma.qRCode.findUnique({ where: { shortCode } });
  if (existing) shortCode = generateShortCode(10);

  const qrCode = await prisma.qRCode.create({
    data: {
      locationId: locationId || null,
      menuId: menuId || null,
      label: label || null,
      shortCode,
      config: body.config || null,
    },
    include: {
      location: true,
      menu: { include: { translations: true, location: true } },
    },
  });
  return NextResponse.json(qrCode, { status: 201 });
}
