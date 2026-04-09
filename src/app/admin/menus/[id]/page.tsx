import { notFound } from 'next/navigation';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import Link from 'next/link';

export default async function MenuDetailPage({ params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return null;

  const menu = await prisma.menu.findUnique({
    where: { id: params.id },
    include: {
      translations: true,
      location: { include: { tenant: true } },
      sections: {
        where: { isActive: true },
        orderBy: { sortOrder: 'asc' },
        include: {
          translations: { where: { languageCode: 'de' } },
          placements: {
            where: { isVisible: true },
            orderBy: { sortOrder: 'asc' },
            include: {
              product: {
                include: {
                  translations: { where: { languageCode: 'de' } },
                  prices: { take: 1, orderBy: { sortOrder: 'asc' } },
                  productWineProfile: { select: { winery: true, vintage: true } },
                },
              },
            },
          },
        },
      },
      qrCodes: true,
    },
  });
  if (!menu) return notFound();

  const menuName = menu.translations.find(t => t.languageCode === 'de')?.name || menu.slug;
  const tenant = menu.location.tenant;
  const publicUrl = `/${tenant.slug}/${menu.location.slug}/${menu.slug}`;
  const totalProducts = menu.sections.reduce((sum, s) => sum + s.placements.length, 0);

  return (
    <div className="max-w-4xl space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold" style={{fontFamily: "'Playfair Display', serif"}}>{menuName}</h1>
          <p className="text-sm text-gray-400 mt-1">
            {menu.location.name} · {menu.type} · {menu.sections.length} Sektionen · {totalProducts} Produkte
          </p>
        </div>
        <div className="flex gap-2">
          <a href={publicUrl} target="_blank" className="rounded-lg border px-3 py-1.5 text-xs font-medium hover:bg-gray-50">
            Vorschau ↗
          </a>
          <span className={`rounded-full px-3 py-1.5 text-xs font-medium ${menu.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
            {menu.isActive ? 'Aktiv' : 'Inaktiv'}
          </span>
        </div>
      </div>

      {/* QR Codes */}
      {menu.qrCodes.length > 0 && (
        <div className="flex gap-2">
          {menu.qrCodes.map(qr => (
            <span key={qr.id} className="rounded-lg bg-gray-100 px-3 py-1 text-xs text-gray-600">
              📱 {qr.label || qr.shortCode}
            </span>
          ))}
        </div>
      )}

      {/* Sections with Products */}
      {menu.sections.map(section => {
        const sName = section.translations[0]?.name || section.slug;
        return (
          <div key={section.id} className="rounded-xl border bg-white shadow-sm overflow-hidden">
            <div className="border-b bg-gray-50/50 px-4 py-3 flex items-center justify-between">
              <div>
                <h2 className="text-sm font-semibold">{section.icon && <span className="mr-1">{section.icon}</span>}{sName}</h2>
                <p className="text-[10px] text-gray-400">{section.placements.length} Produkte</p>
              </div>
            </div>
            <div className="divide-y">
              {section.placements.map((pl, i) => {
                const p = pl.product;
                const pName = p.translations[0]?.name || '';
                const price = pl.priceOverride ? Number(pl.priceOverride) : p.prices[0] ? Number(p.prices[0].price) : null;
                const winery = p.productWineProfile?.winery;
                const vintage = p.productWineProfile?.vintage;
                return (
                  <div key={pl.id} className="flex items-center justify-between px-4 py-2.5 hover:bg-gray-50/50">
                    <div className="flex items-center gap-3 flex-1 min-w-0">
                      <span className="text-xs text-gray-300 w-5 text-right">{i + 1}</span>
                      <div className="min-w-0">
                        <Link href={`/admin/items/${p.id}`} className="text-sm font-medium text-gray-800 hover:text-amber-700 truncate block">{pName}</Link>
                        {winery && <p className="text-[11px] text-gray-400">{winery}{vintage ? ` ${vintage}` : ''}</p>}
                      </div>
                    </div>
                    {price !== null && (
                      <span className="text-sm font-semibold text-gray-600 tabular-nums flex-shrink-0">
                        {new Intl.NumberFormat('de-AT', { style: 'currency', currency: 'EUR' }).format(price)}
                      </span>
                    )}
                  </div>
                );
              })}
              {section.placements.length === 0 && (
                <div className="px-4 py-4 text-center text-xs text-gray-400">Keine Produkte in dieser Sektion</div>
              )}
            </div>
          </div>
        );
      })}

      <div className="text-xs text-gray-300">
        ID: {menu.id} · Slug: {menu.slug}
      </div>
    </div>
  );
}
