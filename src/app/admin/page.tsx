import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import Link from 'next/link';

export default async function DashboardPage() {
  const session = await getServerSession(authOptions);
  if (!session) return null;

  const tid = session.user.tenantId;
  const firstName = session.user.firstName || 'Admin';

  const [menuCount, productCount, qrCount, mediaCount, groupCount, translationCount] = await Promise.all([
    prisma.menu.count({ where: { location: { tenantId: tid } } }),
    prisma.product.count({ where: { tenantId: tid } }),
    prisma.qRCode.count({ where: { location: { tenantId: tid } } }),
    prisma.media.count({ where: { tenantId: tid } }),
    prisma.productGroup.count({ where: { tenantId: tid } }),
    prisma.productTranslation.count({ where: { product: { tenantId: tid } } }),
  ]);

  /* Letzte 5 bearbeitete Produkte */
  const recentProducts = await prisma.product.findMany({
    where: { tenantId: tid },
    orderBy: { updatedAt: 'desc' },
    take: 5,
    include: {
      translations: { where: { languageCode: 'de' }, take: 1 },
      prices: { take: 1 },
      productMedia: {
        where: { isPrimary: true },
        take: 1,
        include: { media: true },
      },
    },
  });

  /* Aktives Template ermitteln */
  const firstMenu = await prisma.menu.findFirst({
    where: { location: { tenantId: tid } },
    select: { designConfig: true, name: true },
  });

  const designConfig = firstMenu?.designConfig as any;
  const templateName = designConfig?.digital?.template || 'elegant';
  const templateLabels: Record<string, string> = {
    elegant: 'Elegant',
    modern: 'Modern',
    classic: 'Klassisch',
    minimal: 'Minimalistisch',
  };

  /* Tagesgruß */
  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Guten Morgen' : hour < 18 ? 'Guten Tag' : 'Guten Abend';

  return (
    <main className="flex-1 overflow-y-auto p-6 lg:p-8">
      <div className="max-w-6xl mx-auto">

        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center gap-2 mb-1">
            <span className="material-symbols-outlined" style={{ fontSize: 28, color: 'var(--color-primary)' }}>restaurant</span>
            <h1 className="text-2xl font-bold" style={{ fontFamily: 'var(--font-heading)', color: 'var(--color-text)' }}>
              Übersicht
            </h1>
          </div>
          <p className="text-lg mt-3" style={{ fontFamily: 'var(--font-heading)', color: 'var(--color-text)' }}>
            {greeting}, {firstName}!
          </p>
          <p className="text-sm mt-0.5" style={{ color: 'var(--color-text-secondary)' }}>
            Hier ist die Zusammenfassung für Ihr Restaurant.
          </p>
        </div>

        {/* KPI Cards */}
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 mb-8">
          <KpiCard icon="inventory_2" iconBg="#FDF2F5" iconColor="var(--color-primary)" label="Produkte" value={productCount} href="/admin/items" />
          <KpiCard icon="menu_book" iconBg="#EFF6FF" iconColor="var(--color-info)" label="Karten" value={menuCount} href="/admin/menus" />
          <KpiCard icon="qr_code_2" iconBg="#F0FDF4" iconColor="var(--color-success)" label="QR-Codes" value={qrCount} href="/admin/qr-codes" />
          <KpiCard icon="photo_library" iconBg="#FDF2F5" iconColor="var(--color-primary)" label="Bilder" value={mediaCount} href="/admin/media" />
        </div>

        {/* Content Grid */}
        <div className="grid gap-6 lg:grid-cols-5">

          {/* Letzte Änderungen – 3 Spalten */}
          <div
            className="lg:col-span-3 rounded-xl border p-6"
            style={{ backgroundColor: 'var(--color-surface)', borderColor: 'var(--color-border-subtle)', boxShadow: 'var(--shadow-card)' }}
          >
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-base font-semibold" style={{ color: 'var(--color-text)' }}>Letzte Änderungen</h2>
              <Link
                href="/admin/items"
                className="text-sm font-medium"
                style={{ color: 'var(--color-primary)' }}
              >
                Alle ansehen
              </Link>
            </div>
            <div className="space-y-3">
              {recentProducts.map((product) => {
                const name = product.translations[0]?.name || 'Unbenannt';
                const price = product.prices[0]?.amount ? `${Number(product.prices[0].amount).toFixed(2).replace('.', ',')} €` : '';
                const thumb = product.productMedia[0]?.media?.thumbnailPath;
                const updatedAt = new Date(product.updatedAt);
                const timeAgo = getTimeAgo(updatedAt);

                return (
                  <Link
                    key={product.id}
                    href={`/admin/items?product=${product.id}`}
                    className="flex items-center gap-3 rounded-lg px-3 py-2.5 transition-colors"
                    style={{ backgroundColor: 'transparent' }}
                    onMouseEnter={(e: any) => e.currentTarget.style.backgroundColor = 'var(--color-bg-subtle)'}
                    onMouseLeave={(e: any) => e.currentTarget.style.backgroundColor = 'transparent'}
                  >
                    {thumb ? (
                      <img
                        src={thumb.startsWith('/') ? thumb : `/${thumb}`}
                        alt=""
                        className="w-10 h-10 rounded-lg object-cover flex-shrink-0"
                      />
                    ) : (
                      <div
                        className="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0"
                        style={{ backgroundColor: 'var(--color-bg-muted)' }}
                      >
                        <span className="material-symbols-outlined" style={{ fontSize: 20, color: 'var(--color-text-muted)' }}>restaurant</span>
                      </div>
                    )}
                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-medium truncate" style={{ color: 'var(--color-text)' }}>{name}</p>
                      <p className="text-xs" style={{ color: 'var(--color-text-muted)' }}>{timeAgo}</p>
                    </div>
                    {price && (
                      <span className="text-sm font-medium flex-shrink-0" style={{ color: 'var(--color-text)' }}>{price}</span>
                    )}
                  </Link>
                );
              })}
              {recentProducts.length === 0 && (
                <p className="text-sm py-4 text-center" style={{ color: 'var(--color-text-muted)' }}>Noch keine Produkte vorhanden.</p>
              )}
            </div>
          </div>

          {/* Rechte Spalte – 2 Spalten */}
          <div className="lg:col-span-2 space-y-6">

            {/* Live-Design Status */}
            <div
              className="rounded-xl border p-6"
              style={{ backgroundColor: 'var(--color-surface)', borderColor: 'var(--color-border-subtle)', boxShadow: 'var(--shadow-card)' }}
            >
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-base font-semibold" style={{ color: 'var(--color-text)' }}>Live-Design Status</h2>
                <span
                  className="text-xs font-medium px-2.5 py-0.5 rounded-full"
                  style={{ backgroundColor: 'var(--color-success-light)', color: 'var(--color-success)' }}
                >
                  Aktiv
                </span>
              </div>
              <div className="flex items-center gap-3 mb-4">
                <div
                  className="w-12 h-12 rounded-lg flex items-center justify-center"
                  style={{ backgroundColor: 'var(--color-bg-muted)' }}
                >
                  <span className="material-symbols-outlined" style={{ fontSize: 24, color: 'var(--color-text-secondary)' }}>web</span>
                </div>
                <div>
                  <p className="text-sm font-semibold" style={{ color: 'var(--color-text)' }}>
                    Template: {templateLabels[templateName] || templateName}
                  </p>
                  <p className="text-xs" style={{ color: 'var(--color-text-muted)' }}>
                    {templateName === 'elegant' && 'Minimalistischer Luxus mit feinen Linien'}
                    {templateName === 'modern' && 'Bildorientiertes Design mit mutigen Typografien'}
                    {templateName === 'classic' && 'Traditionelle Eleganz mit Serif-Schriften'}
                    {templateName === 'minimal' && 'Reine Text-Hierarchie, maximale Lesbarkeit'}
                  </p>
                </div>
              </div>
              <div className="flex gap-2">
                <Link
                  href="/admin/design"
                  className="flex items-center gap-1.5 text-xs font-medium px-3 py-1.5 rounded-lg border transition-colors"
                  style={{ borderColor: 'var(--color-border)', color: 'var(--color-text-secondary)' }}
                >
                  <span className="material-symbols-outlined" style={{ fontSize: 16 }}>visibility</span>
                  Vorschau
                </Link>
                <Link
                  href="/admin/design"
                  className="text-xs font-medium px-3 py-1.5"
                  style={{ color: 'var(--color-primary)' }}
                >
                  Design wechseln
                </Link>
              </div>
            </div>

            {/* Schnellzugriff */}
            <div
              className="rounded-xl border p-6"
              style={{ backgroundColor: 'var(--color-surface)', borderColor: 'var(--color-border-subtle)', boxShadow: 'var(--shadow-card)' }}
            >
              <h2 className="text-base font-semibold mb-4" style={{ color: 'var(--color-text)' }}>Schnellzugriff</h2>
              <div className="grid grid-cols-2 gap-3">
                <Link
                  href="/admin/items"
                  className="flex flex-col items-center gap-2 rounded-xl py-4 px-3 text-white transition-transform hover:scale-[1.02]"
                  style={{ background: 'linear-gradient(135deg, var(--color-primary), var(--color-primary-hover))' }}
                >
                  <span className="material-symbols-outlined" style={{ fontSize: 28 }}>add_circle</span>
                  <span className="text-xs font-semibold text-center">Menü bearbeiten</span>
                </Link>
                <Link
                  href="/admin/design"
                  className="flex flex-col items-center gap-2 rounded-xl py-4 px-3 text-white transition-transform hover:scale-[1.02]"
                  style={{ background: 'linear-gradient(135deg, #7C3AED, #6D28D9)' }}
                >
                  <span className="material-symbols-outlined" style={{ fontSize: 28 }}>palette</span>
                  <span className="text-xs font-semibold text-center">Design anpassen</span>
                </Link>
              </div>
              <Link
                href="/admin/media"
                className="flex items-center justify-between mt-3 rounded-lg px-3 py-2.5 border transition-colors"
                style={{ borderColor: 'var(--color-border-subtle)' }}
                onMouseEnter={(e: any) => e.currentTarget.style.backgroundColor = 'var(--color-bg-subtle)'}
                onMouseLeave={(e: any) => e.currentTarget.style.backgroundColor = 'transparent'}
              >
                <div className="flex items-center gap-2.5">
                  <span className="material-symbols-outlined" style={{ fontSize: 20, color: 'var(--color-text-secondary)' }}>photo_library</span>
                  <div>
                    <p className="text-sm font-medium" style={{ color: 'var(--color-text)' }}>Bildarchiv</p>
                    <p className="text-xs" style={{ color: 'var(--color-text-muted)' }}>{mediaCount} Bilder verfügbar</p>
                  </div>
                </div>
                <span className="material-symbols-outlined" style={{ fontSize: 18, color: 'var(--color-text-muted)' }}>chevron_right</span>
              </Link>
            </div>

            {/* Datenübersicht */}
            <div
              className="rounded-xl border p-6"
              style={{ backgroundColor: 'var(--color-surface)', borderColor: 'var(--color-border-subtle)', boxShadow: 'var(--shadow-card)' }}
            >
              <h2 className="text-base font-semibold mb-4" style={{ color: 'var(--color-text)' }}>Daten</h2>
              <div className="space-y-2.5">
                <DataRow icon="category" label="Produktgruppen" value={groupCount} />
                <DataRow icon="translate" label="Übersetzungen" value={translationCount} />
                <DataRow icon="language" label="Sprachen" value="DE / EN" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}

/* Hilfskomponenten */

function KpiCard({ icon, iconBg, iconColor, label, value, href }: {
  icon: string; iconBg: string; iconColor: string; label: string; value: number; href: string;
}) {
  return (
    <Link
      href={href}
      className="rounded-xl border p-5 transition-all hover:shadow-md"
      style={{ backgroundColor: 'var(--color-surface)', borderColor: 'var(--color-border-subtle)', boxShadow: 'var(--shadow-card)' }}
    >
      <div className="flex items-center justify-between mb-3">
        <div
          className="w-10 h-10 rounded-lg flex items-center justify-center"
          style={{ backgroundColor: iconBg }}
        >
          <span className="material-symbols-outlined" style={{ fontSize: 22, color: iconColor }}>
            {icon}
          </span>
        </div>
      </div>
      <p className="text-sm" style={{ color: 'var(--color-text-muted)' }}>{label}</p>
      <p className="text-2xl font-bold mt-0.5" style={{ color: 'var(--color-text)', fontFamily: 'var(--font-body)' }}>
        {value}
      </p>
    </Link>
  );
}

function DataRow({ icon, label, value }: { icon: string; label: string; value: string | number }) {
  return (
    <div className="flex items-center justify-between py-1">
      <div className="flex items-center gap-2">
        <span className="material-symbols-outlined" style={{ fontSize: 18, color: 'var(--color-text-muted)' }}>{icon}</span>
        <span className="text-sm" style={{ color: 'var(--color-text-secondary)' }}>{label}</span>
      </div>
      <span className="text-sm font-medium" style={{ color: 'var(--color-text)' }}>{value}</span>
    </div>
  );
}

function getTimeAgo(date: Date): string {
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMin = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMin / 60);
  const diffDays = Math.floor(diffHours / 24);

  if (diffMin < 1) return 'Gerade eben';
  if (diffMin < 60) return `Vor ${diffMin} Min.`;
  if (diffHours < 24) return `Vor ${diffHours} Std.`;
  if (diffDays === 1) return 'Gestern';
  if (diffDays < 7) return `Vor ${diffDays} Tagen`;
  return date.toLocaleDateString('de-AT', { day: '2-digit', month: '2-digit', year: 'numeric' });
}
