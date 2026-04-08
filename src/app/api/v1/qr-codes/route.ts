import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import { generateShortCode } from '@/lib/utils';

export async function GET() {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const qrCodes = await prisma.qRCode.findMany({
    where: { location: { tenantId: session.user.tenantId } },
    include: { location: true, menu: { include: { translations: true } } },
    orderBy: { createdAt: 'desc' },
  });
  return NextResponse.json(qrCodes);
}

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const body = await req.json();
  const { locationId, menuId, label, primaryColor, bgColor } = body;
  const location = await prisma.location.findFirst({ where: { id: locationId, tenantId: session.user.tenantId } });
  if (!location) return NextResponse.json({ error: 'Location not found' }, { status: 404 });
  let shortCode = body.shortCode || generateShortCode(8);
  const existing = await prisma.qRCode.findUnique({ where: { shortCode } });
  if (existing) shortCode = generateShortCode(10);
  const qrCode = await prisma.qRCode.create({
    data: { locationId, menuId: menuId || null, label: label || null, shortCode, primaryColor: primaryColor || '#000000', bgColor: bgColor || '#FFFFFF' },
    include: { location: true, menu: { include: { translations: true } } },
  });
  return NextResponse.json(qrCode, { status: 201 });
}
