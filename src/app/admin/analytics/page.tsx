// @ts-nocheck
import { redirect } from 'next/navigation';
import prisma from '@/lib/prisma';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

export default async function AnalyticsPage() {
  const session = await getServerSession(authOptions);
  if (!session?.user) redirect('/admin/login');
  const tid = session.user.tenantId;

  // Parallele Datenabfragen
  const [products, menus, qrCodes, sections, variants, events] = await Promise.all([
    prisma.product.findMany({
      where: { tenantId: tid },
      select: { id: true, type: true, status: true, createdAt: true },
    }),
    prisma.menu.findMany({
      where: { location: { tenantId: tid } },
      include: {
        translations: true,
        location: true,
        sections: { where: { isActive: true }, include: { _count: { select: { placements: true } } } },
      },
    }),
    prisma.qRCode.findMany({
      where: {
        OR: [
          { location: { tenantId: tid } },
          { menu: { location: { tenantId: tid } } },
        ],
      },
      select: { id: true, shortCode: true, scans: true, isActive: true, menuId: true, createdAt: true },
    }),
    prisma.menuSection.findMany({
      where: { menu: { location: { tenantId: tid } }, isActive: true },
      select: { id: true },
    }),
    prisma.productVariant.findMany({
      where: { product: { tenantId: tid } },
      select: { id: true, prices: { select: { sellPrice: true } } },
    }),
    prisma.analyticsEvent.findMany({
      where: { tenantId: tid },
      orderBy: { createdAt: 'desc' },
      take: 50,
      select: { id: true, type: true, data: true, createdAt: true },
    }),
  ]);

  // KPIs berechnen
  const totalProducts = products.length;
  const activeProducts = products.filter(p => p.status === 'ACTIVE').length;
  const totalMenus = menus.length;
  const totalQrCodes = qrCodes.length;
  const activeQrCodes = qrCodes.filter(q => q.isActive).length;
  const totalScans = qrCodes.reduce((sum, q) => sum + (q.scans || 0), 0);
  const totalSections = sections.length;
  const totalVariants = variants.length;

  // Produkte nach Typ
  const typeCounts: Record<string, number> = {};
  products.forEach(p => { typeCounts[p.type] = (typeCounts[p.type] || 0) + 1; });
  const typeLabels: Record<string, string> = { WINE: 'Wein', DRINK: 'Getränk', FOOD: 'Speise', OTHER: 'Sonstige' };
  const typeColors: Record<string, string> = { WINE: '#7C3AED', DRINK: '#2563EB', FOOD: '#F59E0B', OTHER: '#6B7280' };

  // Produkte nach Status
  const statusCounts: Record<string, number> = {};
  products.forEach(p => { statusCounts[p.status] = (statusCounts[p.status] || 0) + 1; });
  const statusLabels: Record<string, string> = { ACTIVE: 'Aktiv', DRAFT: 'Entwurf', ARCHIVED: 'Archiv' };
  const statusColors: Record<string, string> = { ACTIVE: '#22C55E', DRAFT: '#F59E0B', ARCHIVED: '#6B7280' };

  // QR-Codes sortiert nach Scans
  const topQrCodes = [...qrCodes]
    .sort((a, b) => (b.scans || 0) - (a.scans || 0))
    .slice(0, 5);

  // Menü-Statistiken
  const menuStats = menus.map(m => {
    const name = m.translations.find((t: any) => (t.language || t.languageCode) === 'de')?.name || m.slug;
    const placements = m.sections.reduce((sum: number, s: any) => sum + (s._count?.placements || 0), 0);
    const qrCount = qrCodes.filter(q => q.menuId === m.id).length;
    const scanCount = qrCodes.filter(q => q.menuId === m.id).reduce((s, q) => s + (q.scans || 0), 0);
    return { id: m.id, name, type: m.type, locationName: m.location?.name || '', placements, qrCount, scanCount };
  });

  // Durchschnittspreis
  const allPrices = variants.flatMap(v => v.prices.map(p => Number(p.sellPrice)));
  const avgPrice = allPrices.length > 0 ? allPrices.reduce((a, b) => a + b, 0) / allPrices.length : 0;

  // Neueste Produkte (letzte 7 Tage)
  const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
  const recentProducts = products.filter(p => new Date(p.createdAt) > weekAgo).length;

  return (
    <div className="p-6 max-w-6xl mx-auto" style={{ fontFamily: "'Roboto', sans-serif" }}>
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold" style={{ color: '#171A1F' }}>Analytics</h1>
        <p className="text-sm mt-1" style={{ color: '#565D6D' }}>
          Übersicht über Ihre Speisekarten, Produkte und QR-Codes
        </p>
      </div>

      {/* KPI-Karten */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {[
          { icon: 'inventory_2', label: 'Produkte', value: totalProducts, sub: `${activeProducts} aktiv`, iconBg: '#FDF2F5', iconColor: '#DD3C71' },
          { icon: 'menu_book', label: 'Speisekarten', value: totalMenus, sub: `${totalSections} Sektionen`, iconBg: '#DBEAFE', iconColor: '#2563EB' },
          { icon: 'qr_code_2', label: 'QR-Codes', value: totalQrCodes, sub: `${activeQrCodes} aktiv`, iconBg: '#ECFDF5', iconColor: '#22C55E' },
          { icon: 'visibility', label: 'Scans gesamt', value: totalScans.toLocaleString('de-AT'), sub: `${totalVariants} Varianten`, iconBg: '#FFF7ED', iconColor: '#F59E0B' },
        ].map((kpi, i) => (
          <div
            key={i}
            className="rounded-xl p-4 flex items-center gap-4"
            style={{ backgroundColor: '#FFF', border: '1px solid #E5E7EB', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}
          >
            <div className="w-11 h-11 rounded-lg flex items-center justify-center flex-shrink-0" style={{ backgroundColor: kpi.iconBg }}>
              <span className="material-symbols-outlined" style={{ fontSize: 24, color: kpi.iconColor }}>{kpi.icon}</span>
            </div>
            <div>
              <div className="text-2xl font-bold" style={{ color: '#171A1F' }}>{kpi.value}</div>
              <div className="text-xs" style={{ color: '#999' }}>{kpi.label}</div>
              <div className="text-[10px] mt-0.5" style={{ color: '#BBB' }}>{kpi.sub}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Zwei-Spalten-Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">

        {/* Produkte nach Typ */}
        <div className="rounded-xl p-5" style={{ backgroundColor: '#FFF', border: '1px solid #E5E7EB', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
          <div className="flex items-center gap-2 mb-4">
            <span className="material-symbols-outlined" style={{ fontSize: 20, color: '#DD3C71' }}>category</span>
            <h2 className="text-base font-bold" style={{ color: '#171A1F' }}>Produkte nach Typ</h2>
          </div>
          <div className="space-y-3">
            {Object.entries(typeCounts).sort((a, b) => b[1] - a[1]).map(([type, count]) => {
              const pct = totalProducts > 0 ? Math.round((count / totalProducts) * 100) : 0;
              return (
                <div key={type}>
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-sm font-medium" style={{ color: '#171A1F' }}>{typeLabels[type] || type}</span>
                    <span className="text-sm font-bold" style={{ color: '#171A1F' }}>{count} <span className="text-xs font-normal" style={{ color: '#999' }}>({pct}%)</span></span>
                  </div>
                  <div className="h-2 rounded-full" style={{ backgroundColor: '#F3F3F6' }}>
                    <div className="h-2 rounded-full transition-all" style={{ width: `${pct}%`, backgroundColor: typeColors[type] || '#999' }} />
                  </div>
                </div>
              );
            })}
          </div>
          {recentProducts > 0 && (
            <div className="mt-4 pt-3 flex items-center gap-2" style={{ borderTop: '1px solid #F3F3F6' }}>
              <span className="material-symbols-outlined" style={{ fontSize: 16, color: '#22C55E' }}>trending_up</span>
              <span className="text-xs" style={{ color: '#565D6D' }}>{recentProducts} neue Produkte in den letzten 7 Tagen</span>
            </div>
          )}
        </div>

        {/* Produkte nach Status */}
        <div className="rounded-xl p-5" style={{ backgroundColor: '#FFF', border: '1px solid #E5E7EB', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
          <div className="flex items-center gap-2 mb-4">
            <span className="material-symbols-outlined" style={{ fontSize: 20, color: '#DD3C71' }}>monitoring</span>
            <h2 className="text-base font-bold" style={{ color: '#171A1F' }}>Status-Verteilung</h2>
          </div>
          <div className="space-y-3">
            {Object.entries(statusCounts).sort((a, b) => b[1] - a[1]).map(([status, count]) => {
              const pct = totalProducts > 0 ? Math.round((count / totalProducts) * 100) : 0;
              return (
                <div key={status}>
                  <div className="flex items-center justify-between mb-1">
                    <div className="flex items-center gap-2">
                      <span className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: statusColors[status] || '#999' }} />
                      <span className="text-sm font-medium" style={{ color: '#171A1F' }}>{statusLabels[status] || status}</span>
                    </div>
                    <span className="text-sm font-bold" style={{ color: '#171A1F' }}>{count} <span className="text-xs font-normal" style={{ color: '#999' }}>({pct}%)</span></span>
                  </div>
                  <div className="h-2 rounded-full" style={{ backgroundColor: '#F3F3F6' }}>
                    <div className="h-2 rounded-full transition-all" style={{ width: `${pct}%`, backgroundColor: statusColors[status] || '#999' }} />
                  </div>
                </div>
              );
            })}
          </div>
          <div className="mt-4 pt-3 flex items-center gap-4" style={{ borderTop: '1px solid #F3F3F6' }}>
            <div className="flex items-center gap-1.5">
              <span className="material-symbols-outlined" style={{ fontSize: 16, color: '#DD3C71' }}>euro</span>
              <span className="text-xs" style={{ color: '#565D6D' }}>Ø Preis: <strong>{avgPrice.toFixed(2).replace('.', ',')} €</strong></span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="material-symbols-outlined" style={{ fontSize: 16, color: '#2563EB' }}>layers</span>
              <span className="text-xs" style={{ color: '#565D6D' }}>{totalVariants} Varianten</span>
            </div>
          </div>
        </div>
      </div>

      {/* Speisekarten-Tabelle */}
      <div className="rounded-xl mb-8" style={{ backgroundColor: '#FFF', border: '1px solid #E5E7EB', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
        <div className="flex items-center gap-2 p-5 pb-3">
          <span className="material-symbols-outlined" style={{ fontSize: 20, color: '#DD3C71' }}>menu_book</span>
          <h2 className="text-base font-bold" style={{ color: '#171A1F' }}>Speisekarten</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b" style={{ borderColor: '#F3F3F6' }}>
                <th className="px-5 py-3 text-left font-medium text-xs uppercase tracking-wider" style={{ color: '#999' }}>Karte</th>
                <th className="px-5 py-3 text-left font-medium text-xs uppercase tracking-wider" style={{ color: '#999' }}>Standort</th>
                <th className="px-5 py-3 text-center font-medium text-xs uppercase tracking-wider" style={{ color: '#999' }}>Typ</th>
                <th className="px-5 py-3 text-center font-medium text-xs uppercase tracking-wider" style={{ color: '#999' }}>Produkte</th>
                <th className="px-5 py-3 text-center font-medium text-xs uppercase tracking-wider" style={{ color: '#999' }}>QR-Codes</th>
                <th className="px-5 py-3 text-center font-medium text-xs uppercase tracking-wider" style={{ color: '#999' }}>Scans</th>
              </tr>
            </thead>
            <tbody>
              {menuStats.map(m => {
                const typeBadge: Record<string, { label: string; bg: string; color: string }> = {
                  WINE: { label: 'Wein', bg: '#F3E8FF', color: '#7C3AED' },
                  BAR: { label: 'Bar', bg: '#DBEAFE', color: '#2563EB' },
                  EVENT: { label: 'Event', bg: '#FEF3C7', color: '#D97706' },
                };
                const badge = typeBadge[m.type] || typeBadge.EVENT;
                return (
                  <tr key={m.id} className="border-b" style={{ borderColor: '#F3F3F6' }}>
                    <td className="px-5 py-3 font-medium" style={{ color: '#171A1F' }}>{m.name}</td>
                    <td className="px-5 py-3" style={{ color: '#565D6D' }}>{m.locationName}</td>
                    <td className="px-5 py-3 text-center">
                      <span className="text-[10px] font-bold uppercase px-2 py-0.5 rounded" style={{ backgroundColor: badge.bg, color: badge.color }}>{badge.label}</span>
                    </td>
                    <td className="px-5 py-3 text-center font-semibold" style={{ color: '#171A1F' }}>{m.placements}</td>
                    <td className="px-5 py-3 text-center font-semibold" style={{ color: '#171A1F' }}>{m.qrCount}</td>
                    <td className="px-5 py-3 text-center font-bold" style={{ color: '#DD3C71' }}>{m.scanCount.toLocaleString('de-AT')}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Top QR-Codes */}
      {topQrCodes.length > 0 && (
        <div className="rounded-xl" style={{ backgroundColor: '#FFF', border: '1px solid #E5E7EB', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
          <div className="flex items-center gap-2 p-5 pb-3">
            <span className="material-symbols-outlined" style={{ fontSize: 20, color: '#DD3C71' }}>leaderboard</span>
            <h2 className="text-base font-bold" style={{ color: '#171A1F' }}>Top QR-Codes nach Scans</h2>
          </div>
          <div className="px-5 pb-5 space-y-3">
            {topQrCodes.map((qr, i) => {
              const maxScans = topQrCodes[0]?.scans || 1;
              const pct = Math.round(((qr.scans || 0) / maxScans) * 100);
              return (
                <div key={qr.id} className="flex items-center gap-3">
                  <span className="w-6 text-center text-sm font-bold" style={{ color: i === 0 ? '#DD3C71' : '#999' }}>
                    {i + 1}.
                  </span>
                  <span className="text-sm font-mono w-20" style={{ color: '#565D6D' }}>{qr.shortCode}</span>
                  <div className="flex-1 h-2 rounded-full" style={{ backgroundColor: '#F3F3F6' }}>
                    <div
                      className="h-2 rounded-full"
                      style={{ width: `${pct}%`, backgroundColor: i === 0 ? '#DD3C71' : '#F3A4BE' }}
                    />
                  </div>
                  <span className="text-sm font-bold w-16 text-right" style={{ color: '#171A1F' }}>
                    {(qr.scans || 0).toLocaleString('de-AT')}
                  </span>
                  <span
                    className="w-2 h-2 rounded-full flex-shrink-0"
                    style={{ backgroundColor: qr.isActive ? '#22C55E' : '#EF4444' }}
                  />
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
