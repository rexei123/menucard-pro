import { redirect, notFound } from 'next/navigation';
import prisma from '@/lib/prisma';

export default async function QRRedirectPage({ params }: { params: { code: string } }) {
  const qr = await prisma.qRCode.findUnique({
    where: { shortCode: params.code },
    include: { location: { include: { tenant: true } }, menu: true },
  });
  if (!qr || !qr.isActive) return notFound();
  await prisma.qRCode.update({ where: { id: qr.id }, data: { scans: { increment: 1 } } });
  const url = qr.menu ? `/${qr.location.tenant.slug}/${qr.location.slug}/${qr.menu.slug}` : `/${qr.location.tenant.slug}/${qr.location.slug}`;
  redirect(url);
}
