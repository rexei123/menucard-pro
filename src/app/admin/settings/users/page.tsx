import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { redirect } from 'next/navigation';
import UsersAdmin from '@/components/admin/users-admin';

export default async function Page() {
  const session = await getServerSession(authOptions);
  if (!session?.user) redirect('/auth/login');

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold" style={{ fontFamily: "'Playfair Display', serif" }}>Benutzer</h1>
        <p className="mt-1 text-sm text-gray-500">Mitarbeiter und Rollen verwalten</p>
      </div>
      <UsersAdmin
        currentUserId={session.user.id}
        currentUserRole={session.user.role}
      />
    </div>
  );
}
