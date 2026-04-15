import { redirect } from 'next/navigation';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { Providers } from '@/components/shared/providers';
import IconBar from '@/components/admin/icon-bar';

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const session = await getServerSession(authOptions);
  if (!session) redirect('/auth/login');

  return (
    <Providers>
      <div className="admin-roboto flex h-screen overflow-hidden" style={{ backgroundColor: 'var(--color-bg-subtle)' }}>
        <IconBar
          userName={session.user.firstName || 'Admin'}
          userRole={session.user.role || 'OWNER'}
        />
        <div className="flex flex-1 overflow-hidden">
          {children}
        </div>
      </div>
    </Providers>
  );
}
