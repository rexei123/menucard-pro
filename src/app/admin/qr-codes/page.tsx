import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import QRCodeAdmin from '@/components/admin/qr-code-admin';

export default async function QRCodesPage() {
  const session = await getServerSession(authOptions);
  if (!session) return null;
  
  const [qrCodes, locations, menus] = await Promise.all([
    prisma.qRCode.findMany({
      where: { location: { tenantId: session.user.tenantId } },
      include: { location: true, menu: { include: { translations: true } } },
      orderBy: { createdAt: 'desc' },
    }),
    prisma.location.findMany({
      where: { tenantId: session.user.tenantId, isActive: true },
      orderBy: { sortOrder: 'asc' },
    }),
    prisma.menu.findMany({
      where: { location: { tenantId: session.user.tenantId }, isActive: true },
      include: { translations: true, location: true },
      orderBy: { sortOrder: 'asc' },
    }),
  ]);

  const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || 'http://178.104.138.177';

  // Serialize
  const data = qrCodes.map(qr => ({
    id: qr.id,
    label: qr.label,
    shortCode: qr.shortCode,
    locationName: qr.location.name,
    locationId: qr.location.id,
    menuName: qr.menu?.translations.find(t => t.languageCode === 'de')?.name || null,
    menuId: qr.menuId,
    primaryColor: qr.primaryColor || '#000000',
    bgColor: qr.bgColor || '#FFFFFF',
    scans: qr.scans,
    isActive: qr.isActive,
    url: `${baseUrl}/q/${qr.shortCode}`,
  }));

  const locationOptions = locations.map(l => ({ id: l.id, name: l.name }));
  const menuOptions = menus.map(m => ({
    id: m.id,
    name: m.translations.find(t => t.languageCode === 'de')?.name || m.slug,
    locationId: m.locationId,
  }));

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold" style={{fontFamily: "'Playfair Display', serif"}}>QR-Codes</h1>
      <QRCodeAdmin
        initialData={data}
        locations={locationOptions}
        menus={menuOptions}
        baseUrl={baseUrl}
      />
    </div>
  );
}
