import { NextAuthOptions } from 'next-auth';
import CredentialsProvider from 'next-auth/providers/credentials';
import bcrypt from 'bcryptjs';
import prisma from './prisma';

declare module 'next-auth' {
  interface User { id: string; email: string; firstName: string; lastName: string; role: string; tenantId: string; tenantSlug: string; }
  interface Session { user: User; }
}
declare module 'next-auth/jwt' {
  interface JWT { id: string; role: string; tenantId: string; tenantSlug: string; firstName: string; lastName: string; }
}

export const authOptions: NextAuthOptions = {
  providers: [
    CredentialsProvider({
      name: 'credentials',
      credentials: { email: { label: 'Email', type: 'email' }, password: { label: 'Password', type: 'password' } },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) throw new Error('E-Mail und Passwort erforderlich');
        const user = await prisma.user.findUnique({ where: { email: credentials.email }, include: { tenant: true } });
        if (!user || !user.isActive) throw new Error('Ungltige Zugangsdaten');
        const isValid = await bcrypt.compare(credentials.password, user.passwordHash);
        if (!isValid) throw new Error('Ungltige Zugangsdaten');
        await prisma.user.update({ where: { id: user.id }, data: { lastLoginAt: new Date() } });
        return { id: user.id, email: user.email, firstName: user.firstName, lastName: user.lastName, role: user.role, tenantId: user.tenantId, tenantSlug: user.tenant.slug };
      },
    }),
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) { token.id = user.id; token.role = user.role; token.tenantId = user.tenantId; token.tenantSlug = user.tenantSlug; token.firstName = user.firstName; token.lastName = user.lastName; }
      return token;
    },
    async session({ session, token }) {
      session.user = { id: token.id, email: token.email ?? '', firstName: token.firstName, lastName: token.lastName, role: token.role, tenantId: token.tenantId, tenantSlug: token.tenantSlug };
      return session;
    },
  },
  pages: { signIn: '/auth/login', error: '/auth/login' },
  session: { strategy: 'jwt', maxAge: 24 * 60 * 60 },
  secret: process.env.NEXTAUTH_SECRET,
};

export function hasMinRole(userRole: string, requiredRole: string): boolean {
  const h: Record<string, number> = { OWNER: 40, ADMIN: 30, MANAGER: 20, EDITOR: 10 };
  return (h[userRole] ?? 0) >= (h[requiredRole] ?? 0);
}
