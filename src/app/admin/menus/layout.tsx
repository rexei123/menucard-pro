import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import MenuListPanel from '@/components/admin/menu-list-panel';

export default async function MenusLayout({ children }: { children: React.ReactNode }) {
  const session = await getServerSession(authOptions);
  if (!session) return null;
  const tid = session.user.tenantId;

  const menus = await prisma.menu.findMany({
    where: { location: { tenantId: tid } },
    include: {
      translations: { where: { languageCode: 'de' } },
      location: true,
      sections: {
        include: { _count: { select: { placements: true } } },
      },
    },
    orderBy: { sortOrder: 'asc' },
  });

  const serialized = menus.map(m => ({
    id: m.id,
    slug: m.slug,
    type: m.type,
    name: m.translations[0]?.name || m.slug,
    locationName: m.location.name,
    sectionCount: m.sections.length,
    itemCount: m.sections.reduce((sum, s) => sum + s._count.placements, 0),
    isActive: m.isActive,
  }));

  return (
    <div className="flex flex-1 overflow-hidden">
      <MenuListPanel menus={serialized} />
      <main className="flex-1 overflow-y-auto p-6">
        {children}
      </main>
    </div>
  );
}
