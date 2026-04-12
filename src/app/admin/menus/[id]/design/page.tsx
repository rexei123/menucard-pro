import { notFound, redirect } from 'next/navigation';
import prisma from '@/lib/prisma';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import Link from 'next/link';
import DesignTabs from '@/components/admin/design-tabs';

export default async function DesignEditorPage({
  params,
}: {
  params: { id: string };
}) {
  const session = await getServerSession(authOptions);
  if (!session?.user) redirect('/admin/login');

  const menu = await prisma.menu.findUnique({
    where: { id: params.id },
    include: {
      translations: true,
      location: { include: { tenant: true } },
    },
  });
  if (!menu) return notFound();

  const menuName = menu.translations.find(t => t.languageCode === 'de')?.name
    || menu.translations[0]?.name
    || menu.slug
    || 'Karte';

  return (
    <div className="flex flex-col h-screen">
      <div className="flex items-center justify-between border-b bg-white px-4 py-3">
        <div className="flex items-center gap-3">
          <Link href={`/admin/menus/${menu.id}`}
            className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700">
            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" /></svg>
            Zurück
          </Link>
          <div className="h-4 border-l border-gray-300" />
          <h1 className="text-sm font-semibold">{menuName} – Design</h1>
        </div>
      </div>
      <DesignTabs
        menuId={menu.id}
        tenantSlug={menu.location.tenant.slug}
        locationSlug={menu.location.slug}
        menuSlug={menu.slug}
      />
    </div>
  );
}
