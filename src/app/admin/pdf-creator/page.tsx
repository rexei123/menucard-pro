// @ts-nocheck
import { redirect } from 'next/navigation';
import prisma from '@/lib/prisma';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import Link from 'next/link';

const typeBadges: Record<string, { label: string; bg: string; color: string }> = {
  WINE: { label: 'Wein', bg: '#F3E8FF', color: '#7C3AED' },
  BAR: { label: 'Bar', bg: '#DBEAFE', color: '#2563EB' },
  EVENT: { label: 'Event', bg: '#FEF3C7', color: '#D97706' },
};

export default async function PdfCreatorPage() {
  const session = await getServerSession(authOptions);
  if (!session?.user) redirect('/admin/login');

  const menus = await prisma.menu.findMany({
    include: {
      translations: true,
      location: { include: { tenant: true } },
      sections: { select: { _count: { select: { placements: true } } } },
    },
    orderBy: { createdAt: 'asc' },
  });

  return (
    <div className="p-6 max-w-4xl mx-auto" style={{ fontFamily: "'Roboto', sans-serif" }}>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold" style={{ color: '#171A1F' }}>PDF-Creator</h1>
          <p className="text-sm mt-1" style={{ color: '#565D6D' }}>PDF-Karten generieren, gestalten und herunterladen</p>
        </div>
        <span
          className="flex items-center gap-1.5 text-xs font-medium px-3 py-1.5 rounded-full"
          style={{ backgroundColor: '#FDF2F5', color: '#DD3C71' }}
        >
          <span className="material-symbols-outlined" style={{ fontSize: 14 }}>picture_as_pdf</span>
          {menus.length} Karten
        </span>
      </div>

      <div className="space-y-3">
        {menus.map((menu) => {
          const name = menu.translations.find((t: any) => t.language === 'de' || t.languageCode === 'de')?.name
            || menu.translations[0]?.name
            || menu.slug;
          const badge = typeBadges[menu.type] || typeBadges.EVENT;
          const locationName = menu.location?.name || '';
          const placementCount = menu.sections.reduce((sum: number, s: any) => sum + (s._count?.placements || 0), 0);

          return (
            <div
              key={menu.id}
              className="flex items-center justify-between p-4 rounded-xl transition-all hover:shadow-md"
              style={{ backgroundColor: '#FFF', border: '1px solid #E5E7EB', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}
            >
              <div className="flex items-center gap-4">
                <div
                  className="w-10 h-10 rounded-lg flex items-center justify-center"
                  style={{ backgroundColor: '#FDF2F5' }}
                >
                  <span className="material-symbols-outlined" style={{ fontSize: 22, color: '#DD3C71' }}>menu_book</span>
                </div>
                <div>
                  <h3 className="font-semibold" style={{ color: '#171A1F' }}>{name}</h3>
                  <div className="flex items-center gap-2 mt-0.5">
                    <span className="text-xs" style={{ color: '#999' }}>{locationName}</span>
                    <span
                      className="text-[10px] font-bold uppercase px-1.5 py-0.5 rounded"
                      style={{ backgroundColor: badge.bg, color: badge.color }}
                    >
                      {badge.label}
                    </span>
                    <span className="text-xs" style={{ color: '#BBB' }}>{placementCount} Produkte</span>
                  </div>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <a
                  href={`/api/v1/menus/${menu.id}/pdf`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-semibold transition-colors hover:opacity-80"
                  style={{ backgroundColor: '#DD3C71', color: '#FFF' }}
                >
                  <span className="material-symbols-outlined" style={{ fontSize: 16 }}>picture_as_pdf</span>
                  PDF
                </a>
                <Link
                  href={`/admin/menus/${menu.id}`}
                  className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium transition-colors"
                  style={{ backgroundColor: '#F3F3F6', color: '#565D6D' }}
                >
                  <span className="material-symbols-outlined" style={{ fontSize: 16 }}>edit</span>
                  Karte
                </Link>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
