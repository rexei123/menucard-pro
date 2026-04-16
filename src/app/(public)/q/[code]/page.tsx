// @ts-nocheck
import { redirect, notFound } from 'next/navigation';
import prisma from '@/lib/prisma';

export default async function QRRedirectPage({ params }: { params: { code: string } }) {
  const qr = await prisma.qRCode.findUnique({
    where: { shortCode: params.code },
    include: {
      menu: { include: { location: { include: { tenant: true } } } },
    },
  });
  if (!qr || !qr.isActive) return notFound();

  // Scan-Counter erhöhen
  await prisma.qRCode.update({ where: { id: qr.id }, data: { scans: { increment: 1 } } });

  // v2: URL aus menu → location → tenant ableiten
  if (qr.menu) {
    const loc = qr.menu.location;
    const tenant = loc.tenant;
    redirect(`/${tenant.slug}/${loc.slug}/${qr.menu.slug}`);
  }

  return notFound();
}
