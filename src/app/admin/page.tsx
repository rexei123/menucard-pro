import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import Link from 'next/link';

export default async function DashboardPage() {
  const session = await getServerSession(authOptions);
  const tenantId = session!.user.tenantId;
  const [menuCount, itemCount] = await Promise.all([
    prisma.menu.count({ where: { location: { tenantId }, isArchived: false } }),
    prisma.menuItem.count({ where: { section: { menu: { location: { tenantId } } } } }),
  ]);

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-bold" style={{fontFamily: "'Playfair Display', serif"}}>Dashboard</h1>
        <p className="mt-1 text-sm text-gray-500">Willkommen, {session!.user.firstName}</p>
      </div>
      <div className="grid gap-4 sm:grid-cols-3">
        <div className="rounded-xl border bg-white p-5"><p className="text-2xl font-bold">{menuCount}</p><p className="text-sm text-gray-500">Karten</p></div>
        <div className="rounded-xl border bg-white p-5"><p className="text-2xl font-bold">{itemCount}</p><p className="text-sm text-gray-500">Artikel</p></div>
        <Link href="/admin/menus" className="rounded-xl border bg-white p-5 hover:shadow-md"><p className="text-sm font-medium">Karten verwalten &rarr;</p></Link>
      </div>
    </div>
  );
}
