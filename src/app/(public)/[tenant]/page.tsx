import { notFound } from 'next/navigation';
import prisma from '@/lib/prisma';
import Link from 'next/link';

export default async function TenantPage({ params }: { params: { tenant: string } }) {
  const tenant = await prisma.tenant.findUnique({
    where: { slug: params.tenant, isActive: true },
    include: {
      themes: { where: { isActive: true }, take: 1 },
      locations: { where: { isActive: true }, orderBy: { sortOrder: 'asc' }, include: { translations: true, menus: { where: { isActive: true, isArchived: false }, include: { translations: true } } } },
    },
  });
  if (!tenant) return notFound();
  const theme = tenant.themes[0];

  return (
    <div className="min-h-screen" style={{ background: theme?.backgroundColor || '#FAFAF8' }}>
      <header className="border-b px-6 py-8 text-center">
        <h1 className="text-3xl font-bold tracking-tight" style={{fontFamily: "'Playfair Display', serif"}}>{tenant.name}</h1>
      </header>
      <main className="mx-auto max-w-lg px-4 py-8 space-y-4">
        {tenant.locations.map((loc) => (
          <Link key={loc.id} href={`/${tenant.slug}/${loc.slug}`} className="block rounded-2xl border bg-white p-6 shadow-sm hover:shadow-md">
            <h2 className="text-lg font-semibold" style={{fontFamily: "'Playfair Display', serif"}}>{loc.translations.find(t => t.languageCode === 'de')?.name || loc.name}</h2>
            <p className="mt-1 text-sm text-gray-500">{loc.translations.find(t => t.languageCode === 'de')?.description}</p>
            <p className="mt-2 text-xs text-gray-400">{loc.menus.length} Karten</p>
          </Link>
        ))}
      </main>
    </div>
  );
}
