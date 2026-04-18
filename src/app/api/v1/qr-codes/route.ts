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

  // Standorte des Mandanten ermitteln (QRCode hat locationId, aber keine Prisma-Relation "location")
  const tenantLocations = await prisma.location.findMany({
    where: { tenantId: tid },
    select: { id: true, name: true, slug: true, tenantId: true },
  });
  const tenantLocationIds = tenantLocations.map((l) => l.id);
  const locationMap = new Map(tenantLocations.map((l) => [l.id, l]));

  const qrCodes = await prisma.qRCode.findMany({
    where: {
      OR: [
        { locationId: { in: tenantLocationIds } },
        { menu: { location: { tenantId: tid } } },
      ],
    },
    include: {
      menu: { include: { translations: true, location: true } },
    },
    orderBy: { createdAt: 'desc' },
  });

  // location-Objekt aus Map nachtragen (API-Kompatibilitaet zum alten Format)
  const enriched = qrCodes.map((qr) => ({
    ...qr,
    location: qr.locationId ? locationMap.get(qr.locationId) || null : null,
  }));

  return NextResponse.json(enriched);
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
      menu: { include: { translations: true, location: true } },
    },
  });

  // location-Objekt nachtragen
  const location = qrCode.locationId
    ? await prisma.location.findUnique({ where: { id: qrCode.locationId } })
    : null;

  return NextResponse.json({ ...qrCode, location }, { status: 201 });
}
