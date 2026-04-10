import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import Link from 'next/link';

export default async function DashboardPage() {
  const session = await getServerSession(authOptions);
  if (!session) return null;
  const tid = session.user.tenantId;

  const [menuCount, productCount, qrCount] = await Promise.all([
    prisma.menu.count({ where: { location: { tenantId: tid } } }),
    prisma.product.count({ where: { tenantId: tid } }),
    prisma.qRCode.count({ where: { location: { tenantId: tid } } }),
  ]);

  return (
    <main className="flex-1 overflow-y-auto p-6">
      <div className="max-w-4xl">
        <h1 className="text-3xl font-bold" style={{fontFamily: "'Playfair Display', serif"}}>Dashboard</h1>
        <p className="text-base text-gray-400 mt-1">Willkommen, {session.user.firstName}</p>

        <div className="mt-6 grid gap-4 sm:grid-cols-3">
          <Link href="/admin/menus" className="rounded-xl border bg-white p-5 shadow-sm hover:shadow-md transition-shadow">
            <p className="text-3xl font-bold">{menuCount}</p>
            <p className="text-base text-gray-400 mt-1">Karten</p>
          </Link>
          <Link href="/admin/items" className="rounded-xl border bg-white p-5 shadow-sm hover:shadow-md transition-shadow">
            <p className="text-3xl font-bold">{productCount}</p>
            <p className="text-base text-gray-400 mt-1">Produkte</p>
          </Link>
          <Link href="/admin/qr-codes" className="rounded-xl border bg-white p-5 shadow-sm hover:shadow-md transition-shadow">
            <p className="text-3xl font-bold">{qrCount}</p>
            <p className="text-base text-gray-400 mt-1">QR-Codes</p>
          </Link>
        </div>
      </div>
    </main>
  );
}
