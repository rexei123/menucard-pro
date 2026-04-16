import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const body = await req.json();
  const qr = await prisma.qRCode.findFirst({ where: { id: params.id, location: { tenantId: session.user.tenantId } } });
  if (!qr) return NextResponse.json({ error: 'Not found' }, { status: 404 });
  const updated = await prisma.qRCode.update({ where: { id: params.id }, data: body });
  return NextResponse.json(updated);
}

export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const qr = await prisma.qRCode.findFirst({ where: { id: params.id, location: { tenantId: session.user.tenantId } } });
  if (!qr) return NextResponse.json({ error: 'Not found' }, { status: 404 });
  await prisma.qRCode.delete({ where: { id: params.id } });
  return NextResponse.json({ success: true });
}
