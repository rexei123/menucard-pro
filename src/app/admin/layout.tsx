import { redirect } from 'next/navigation';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { Providers } from '@/components/shared/providers';
import Link from 'next/link';

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const session = await getServerSession(authOptions);
  if (!session) redirect('/auth/login');

  return (
    <Providers>
      <div className="flex h-screen overflow-hidden bg-[#FAFAF8]">
        <aside className="hidden w-64 flex-shrink-0 border-r bg-white lg:flex lg:flex-col">
          <div className="flex h-16 items-center border-b px-6">
            <Link href="/admin" className="flex items-center gap-2">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-[#8B6914] text-xs font-bold text-white">M</div>
              <span className="text-lg font-semibold" style={{fontFamily: "'Playfair Display', serif"}}>MenuCard Pro</span>
            </Link>
          </div>
          <nav className="flex-1 space-y-1 px-3 py-4">
            <Link href="/admin" className="flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium hover:bg-gray-100">Dashboard</Link>
            <Link href="/admin/menus" className="flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium hover:bg-gray-100">Karten</Link>
            <Link href="/admin/items" className="flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium hover:bg-gray-100">Artikel</Link>
            <Link href="/admin/qr-codes" className="flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium hover:bg-gray-100">QR-Codes</Link>
            <Link href="/admin/analytics" className="flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium hover:bg-gray-100">Analytics</Link>
            <Link href="/admin/settings" className="flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium hover:bg-gray-100">Einstellungen</Link>
          </nav>
          <div className="border-t px-4 py-3">
            <p className="text-xs text-gray-400">{session.user.firstName} {session.user.lastName}</p>
            <p className="text-xs text-gray-300">{session.user.role}</p>
          </div>
        </aside>
        <main className="flex-1 overflow-y-auto p-6">{children}</main>
      </div>
    </Providers>
  );
}
