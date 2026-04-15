#!/bin/bash
# MenuCard Pro - Vollständiges Setup-Script
# Führe dieses Script auf dem Server aus:
# bash setup.sh

set -e
echo "🚀 MenuCard Pro - Setup startet..."

PROJECT_DIR="/var/www/menucard-pro"
cd "$PROJECT_DIR"

# ============================================
# POSTCSS CONFIG
# ============================================
cat > postcss.config.js << 'POSTCSS'
module.exports = { plugins: { tailwindcss: {}, autoprefixer: {} } };
POSTCSS

# ============================================
# ESLINT
# ============================================
cat > .eslintrc.json << 'ESLINT'
{"extends":"next/core-web-vitals"}
ESLINT

# ============================================
# SRC DIRECTORY STRUCTURE
# ============================================
mkdir -p src/app/admin/{menus,items,qr-codes,analytics,media,import}
mkdir -p src/app/admin/settings/{theme,languages,allergens,users}
mkdir -p src/app/auth/login
mkdir -p "src/app/auth/api/[...nextauth]"
mkdir -p "src/app/(public)/[tenant]/[location]/[menu]/[item]"
mkdir -p "src/app/(public)/q/[code]"
mkdir -p src/app/api/v1/{menus,items,analytics}
mkdir -p "src/app/api/v1/menus/[id]"
mkdir -p "src/app/api/v1/items/[id]"
mkdir -p "src/app/api/v1/public/[...slug]"
mkdir -p src/components/{ui,public,admin,shared}
mkdir -p src/{lib,services,schemas,hooks,stores,types,config,i18n}

echo "✓ Verzeichnisstruktur erstellt"

# ============================================
# src/lib/prisma.ts
# ============================================
cat > src/lib/prisma.ts << 'FILE'
import { PrismaClient } from '@prisma/client';
const globalForPrisma = globalThis as unknown as { prisma: PrismaClient | undefined };
export const prisma = globalForPrisma.prisma ?? new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
});
if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;
export default prisma;
FILE

# ============================================
# src/lib/utils.ts
# ============================================
cat > src/lib/utils.ts << 'FILE'
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';
import slugify from 'slugify';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function createSlug(text: string): string {
  return slugify(text, { lower: true, strict: true, locale: 'de' });
}

export function generateShortCode(length = 8): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  let result = '';
  for (let i = 0; i < length; i++) result += chars.charAt(Math.floor(Math.random() * chars.length));
  return result;
}

export function formatPrice(price: number | string, currency = 'EUR', locale = 'de-AT'): string {
  const numPrice = typeof price === 'string' ? parseFloat(price) : price;
  return new Intl.NumberFormat(locale, { style: 'currency', currency, minimumFractionDigits: 2 }).format(numPrice);
}
FILE

# ============================================
# src/lib/auth.ts
# ============================================
cat > src/lib/auth.ts << 'FILE'
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
FILE

# ============================================
# src/lib/s3.ts
# ============================================
cat > src/lib/s3.ts << 'FILE'
export function getMediaUrl(key: string): string {
  return `${process.env.S3_ENDPOINT}/${process.env.S3_BUCKET}/${key}`;
}
FILE

# ============================================
# src/config/allergens.ts
# ============================================
cat > src/config/allergens.ts << 'FILE'
export const EU_ALLERGENS = [
  { code: 'A', icon: '🌾', translations: { de: { name: 'Glutenhaltiges Getreide', description: 'Weizen, Roggen, Gerste, Hafer, Dinkel' }, en: { name: 'Cereals containing gluten', description: 'Wheat, rye, barley, oats, spelt' } } },
  { code: 'B', icon: '🦐', translations: { de: { name: 'Krebstiere', description: '' }, en: { name: 'Crustaceans', description: '' } } },
  { code: 'C', icon: '🥚', translations: { de: { name: 'Eier', description: '' }, en: { name: 'Eggs', description: '' } } },
  { code: 'D', icon: '🐟', translations: { de: { name: 'Fisch', description: '' }, en: { name: 'Fish', description: '' } } },
  { code: 'E', icon: '🥜', translations: { de: { name: 'Erdnuesse', description: '' }, en: { name: 'Peanuts', description: '' } } },
  { code: 'F', icon: '🫘', translations: { de: { name: 'Soja', description: '' }, en: { name: 'Soybeans', description: '' } } },
  { code: 'G', icon: '🥛', translations: { de: { name: 'Milch', description: 'einschliesslich Laktose' }, en: { name: 'Milk', description: 'including lactose' } } },
  { code: 'H', icon: '🌰', translations: { de: { name: 'Schalenfruechte', description: 'Mandeln, Haselnuesse, Walnuesse, Cashew, Pecan, Para, Pistazien, Macadamia' }, en: { name: 'Tree nuts', description: '' } } },
  { code: 'L', icon: '🥬', translations: { de: { name: 'Sellerie', description: '' }, en: { name: 'Celery', description: '' } } },
  { code: 'M', icon: '🫒', translations: { de: { name: 'Senf', description: '' }, en: { name: 'Mustard', description: '' } } },
  { code: 'N', icon: '🌱', translations: { de: { name: 'Sesamsamen', description: '' }, en: { name: 'Sesame seeds', description: '' } } },
  { code: 'O', icon: '🧪', translations: { de: { name: 'Schwefeldioxid und Sulphite', description: '> 10 mg/kg oder 10 mg/l' }, en: { name: 'Sulphur dioxide and sulphites', description: '' } } },
  { code: 'P', icon: '🫛', translations: { de: { name: 'Lupinen', description: '' }, en: { name: 'Lupin', description: '' } } },
  { code: 'R', icon: '🐚', translations: { de: { name: 'Weichtiere', description: '' }, en: { name: 'Molluscs', description: '' } } },
];
FILE

# ============================================
# src/config/constants.ts
# ============================================
cat > src/config/constants.ts << 'FILE'
export const APP_NAME = 'MenuCard Pro';
export const DEFAULT_LOCALE = 'de';
export const SUPPORTED_LOCALES = ['de', 'en'] as const;
FILE

# ============================================
# src/app/globals.css
# ============================================
cat > src/app/globals.css << 'FILE'
@tailwind base;
@tailwind components;
@tailwind utilities;

@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;500;600;700&family=Source+Sans+3:wght@300;400;500;600;700&display=swap');

@layer base {
  :root {
    --font-heading: 'Playfair Display', serif;
    --font-body: 'Source Sans 3', sans-serif;
    --background: 40 20% 98%;
    --foreground: 0 0% 10%;
    --card: 0 0% 100%;
    --card-foreground: 0 0% 10%;
    --primary: 0 0% 10%;
    --primary-foreground: 0 0% 98%;
    --secondary: 40 10% 94%;
    --secondary-foreground: 0 0% 10%;
    --muted: 40 10% 94%;
    --muted-foreground: 0 0% 45%;
    --accent: 43 74% 31%;
    --accent-foreground: 0 0% 98%;
    --destructive: 0 84% 60%;
    --destructive-foreground: 0 0% 98%;
    --border: 40 10% 88%;
    --input: 40 10% 88%;
    --ring: 43 74% 31%;
    --radius: 0.5rem;
    --sidebar: 0 0% 98%;
    --sidebar-foreground: 0 0% 10%;
    --sidebar-border: 40 10% 90%;
    --sidebar-accent: 43 74% 31%;
  }
}

@layer base {
  * { @apply border-border; }
  body { @apply bg-background text-foreground antialiased; font-family: var(--font-body); }
  h1, h2, h3, h4, h5, h6 { font-family: var(--font-heading); }
}
FILE

# ============================================
# src/app/layout.tsx
# ============================================
cat > src/app/layout.tsx << 'FILE'
import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: { default: 'MenuCard Pro', template: '%s | MenuCard Pro' },
  description: 'Digitale Speise-, Getraenke- und Weinkarten',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="de" suppressHydrationWarning>
      <body className="min-h-screen">{children}</body>
    </html>
  );
}
FILE

# ============================================
# src/app/page.tsx (Landing)
# ============================================
cat > src/app/page.tsx << 'FILE'
import Link from 'next/link';

export default function HomePage() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-[#FAFAF8] px-6 text-center">
      <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-[#1a1a1a] text-2xl font-bold text-white">M</div>
      <h1 className="mt-6 text-4xl font-bold tracking-tight text-[#1a1a1a]" style={{fontFamily: "'Playfair Display', serif"}}>MenuCard Pro</h1>
      <p className="mt-3 max-w-md text-lg text-gray-500">Digitale Speise-, Getraenke- und Weinkarten fuer die gehobene Hotellerie</p>
      <div className="mt-8 flex gap-3">
        <Link href="/hotel-sonnblick" className="rounded-xl bg-[#1a1a1a] px-6 py-3 text-sm font-semibold text-white hover:bg-[#333]">Demo ansehen</Link>
        <Link href="/auth/login" className="rounded-xl border border-gray-300 px-6 py-3 text-sm font-semibold text-[#1a1a1a] hover:bg-gray-100">Admin Login</Link>
      </div>
    </div>
  );
}
FILE

# ============================================
# src/app/not-found.tsx
# ============================================
cat > src/app/not-found.tsx << 'FILE'
import Link from 'next/link';
export default function NotFound() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-[#FAFAF8] px-6 text-center">
      <p className="text-6xl font-bold text-[#8B6914]" style={{fontFamily: "'Playfair Display', serif"}}>404</p>
      <h1 className="mt-4 text-2xl font-bold text-[#1a1a1a]">Seite nicht gefunden</h1>
      <Link href="/" className="mt-6 rounded-xl bg-[#1a1a1a] px-6 py-3 text-sm font-semibold text-white hover:bg-[#333]">Zur Startseite</Link>
    </div>
  );
}
FILE

# ============================================
# src/components/shared/providers.tsx
# ============================================
cat > src/components/shared/providers.tsx << 'FILE'
'use client';
import { SessionProvider } from 'next-auth/react';
export function Providers({ children }: { children: React.ReactNode }) {
  return <SessionProvider>{children}</SessionProvider>;
}
FILE

# ============================================
# src/app/auth/api/[...nextauth]/route.ts
# ============================================
cat > "src/app/auth/api/[...nextauth]/route.ts" << 'FILE'
import NextAuth from 'next-auth';
import { authOptions } from '@/lib/auth';
const handler = NextAuth(authOptions);
export { handler as GET, handler as POST };
FILE

# ============================================
# src/app/auth/login/page.tsx
# ============================================
cat > src/app/auth/login/page.tsx << 'FILE'
'use client';
import { useState } from 'react';
import { signIn } from 'next-auth/react';
import { useRouter } from 'next/navigation';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      const result = await signIn('credentials', { email, password, redirect: false });
      if (result?.error) setError('Falsche E-Mail oder Passwort');
      else { router.push('/admin'); router.refresh(); }
    } catch { setError('Ein Fehler ist aufgetreten'); }
    finally { setLoading(false); }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-[#FAFAF8]">
      <div className="w-full max-w-md space-y-8 px-6">
        <div className="text-center">
          <h1 className="text-3xl font-bold tracking-tight text-gray-900" style={{fontFamily: "'Playfair Display', serif"}}>MenuCard Pro</h1>
          <p className="mt-2 text-sm text-gray-500">Melden Sie sich an</p>
        </div>
        <form onSubmit={handleSubmit} className="mt-8 space-y-6">
          {error && <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>}
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">E-Mail</label>
              <input type="email" required value={email} onChange={e => setEmail(e.target.value)} className="mt-1 block w-full rounded-lg border border-gray-300 px-4 py-3 focus:border-[#8B6914] focus:outline-none focus:ring-1 focus:ring-[#8B6914]" placeholder="admin@hotel-sonnblick.at" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Passwort</label>
              <input type="password" required value={password} onChange={e => setPassword(e.target.value)} className="mt-1 block w-full rounded-lg border border-gray-300 px-4 py-3 focus:border-[#8B6914] focus:outline-none focus:ring-1 focus:ring-[#8B6914]" />
            </div>
          </div>
          <button type="submit" disabled={loading} className="flex w-full justify-center rounded-lg bg-[#1a1a1a] px-4 py-3 text-sm font-semibold text-white hover:bg-[#333] disabled:opacity-50">
            {loading ? 'Anmelden...' : 'Anmelden'}
          </button>
        </form>
      </div>
    </div>
  );
}
FILE

# ============================================
# src/middleware.ts
# ============================================
cat > src/middleware.ts << 'FILE'
export { default } from 'next-auth/middleware';
export const config = { matcher: ['/admin/:path*'] };
FILE

# ============================================
# src/app/admin/layout.tsx
# ============================================
cat > src/app/admin/layout.tsx << 'FILE'
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
FILE

# ============================================
# src/app/admin/page.tsx (Dashboard)
# ============================================
cat > src/app/admin/page.tsx << 'FILE'
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
FILE

# ============================================
# Admin placeholder pages
# ============================================
for page in menus items qr-codes analytics media import settings; do
cat > "src/app/admin/$page/page.tsx" << PAGEFILE
export default function Page() {
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold" style={{fontFamily: "'Playfair Display', serif"}}>${page}</h1>
      <div className="rounded-xl border border-dashed bg-gray-50 px-6 py-12 text-center">
        <p className="text-sm text-gray-400">Wird implementiert</p>
      </div>
    </div>
  );
}
PAGEFILE
done

for page in theme languages allergens users; do
  cp "src/app/admin/settings/page.tsx" "src/app/admin/settings/$page/page.tsx"
done

# ============================================
# PUBLIC: Tenant page
# ============================================
cat > "src/app/(public)/[tenant]/page.tsx" << 'FILE'
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
FILE

# ============================================
# PUBLIC: Location page
# ============================================
cat > "src/app/(public)/[tenant]/[location]/page.tsx" << 'FILE'
import { notFound } from 'next/navigation';
import prisma from '@/lib/prisma';
import Link from 'next/link';

const icons: Record<string, string> = { FOOD: '🍽️', DRINKS: '🥤', WINE: '🍷', BREAKFAST: '🥐', BAR: '🍸', SPA: '🧖', ROOM_SERVICE: '🛎️', MINIBAR: '🧊', EVENT: '🎉' };

export default async function LocationPage({ params }: { params: { tenant: string; location: string } }) {
  const tenant = await prisma.tenant.findUnique({ where: { slug: params.tenant, isActive: true } });
  if (!tenant) return notFound();
  const location = await prisma.location.findUnique({
    where: { tenantId_slug: { tenantId: tenant.id, slug: params.location } },
    include: { translations: true, menus: { where: { isActive: true, isArchived: false }, orderBy: { sortOrder: 'asc' }, include: { translations: true } } },
  });
  if (!location) return notFound();

  return (
    <div className="min-h-screen bg-[#FAFAF8]">
      <header className="border-b px-6 py-6 text-center">
        <Link href={`/${tenant.slug}`} className="text-xs uppercase tracking-widest text-gray-400">{tenant.name}</Link>
        <h1 className="mt-2 text-2xl font-bold" style={{fontFamily: "'Playfair Display', serif"}}>{location.translations.find(t => t.languageCode === 'de')?.name || location.name}</h1>
      </header>
      <main className="mx-auto max-w-lg px-4 py-6 space-y-3">
        {location.menus.map((menu) => (
          <Link key={menu.id} href={`/${tenant.slug}/${location.slug}/${menu.slug}`} className="flex items-center gap-4 rounded-2xl border bg-white p-5 shadow-sm hover:shadow-md">
            <span className="text-3xl">{icons[menu.type] || '📄'}</span>
            <div>
              <h2 className="text-lg font-semibold" style={{fontFamily: "'Playfair Display', serif"}}>{menu.translations.find(t => t.languageCode === 'de')?.name || menu.slug}</h2>
              <p className="mt-0.5 text-sm text-gray-400">{menu.translations.find(t => t.languageCode === 'de')?.description}</p>
            </div>
          </Link>
        ))}
      </main>
    </div>
  );
}
FILE

# ============================================
# PUBLIC: Menu view (the main guest page)
# ============================================
cat > "src/app/(public)/[tenant]/[location]/[menu]/page.tsx" << 'FILE'
import { notFound } from 'next/navigation';
import prisma from '@/lib/prisma';
import Link from 'next/link';
import { formatPrice } from '@/lib/utils';

export default async function MenuPage({ params }: { params: { tenant: string; location: string; menu: string } }) {
  const tenant = await prisma.tenant.findUnique({ where: { slug: params.tenant, isActive: true } });
  if (!tenant) return notFound();
  const location = await prisma.location.findUnique({ where: { tenantId_slug: { tenantId: tenant.id, slug: params.location } } });
  if (!location) return notFound();
  const menu = await prisma.menu.findUnique({
    where: { locationId_slug: { locationId: location.id, slug: params.menu } },
    include: {
      translations: true,
      sections: { where: { isActive: true }, orderBy: { sortOrder: 'asc' }, include: {
        translations: true,
        items: { where: { isActive: true }, orderBy: { sortOrder: 'asc' }, include: {
          translations: true,
          priceVariants: { orderBy: { sortOrder: 'asc' } },
          allergens: { include: { allergen: { include: { translations: true } } } },
          tags: { include: { tag: { include: { translations: true } } } },
          wineProfile: true,
        } },
      } },
    },
  });
  if (!menu) return notFound();
  const theme = await prisma.theme.findFirst({ where: { tenantId: tenant.id, isActive: true } });
  const menuName = menu.translations.find(t => t.languageCode === 'de')?.name || menu.slug;
  const hl: Record<string, string> = { RECOMMENDATION: 'Empfehlung', NEW: 'Neu', POPULAR: 'Beliebt', PREMIUM: 'Premium', SEASONAL: 'Saison', CHEFS_CHOICE: "Chef's Choice" };

  return (
    <div className="min-h-screen pb-16" style={{ background: theme?.backgroundColor || '#FAFAF8', color: theme?.textColor || '#1a1a1a' }}>
      <header className="border-b px-6 py-6 text-center">
        <Link href={`/${tenant.slug}/${location.slug}`} className="text-xs uppercase tracking-widest opacity-40">{tenant.name}</Link>
        <h1 className="mt-2 text-3xl font-bold tracking-tight" style={{fontFamily: "'Playfair Display', serif"}}>{menuName}</h1>
      </header>
      {menu.sections.length > 1 && (
        <nav className="sticky top-0 z-10 border-b bg-white/90 backdrop-blur-md">
          <div className="flex overflow-x-auto px-4 py-2 gap-1">
            {menu.sections.map(s => (
              <a key={s.id} href={`#${s.slug}`} className="flex-shrink-0 rounded-full px-4 py-2 text-sm font-medium hover:bg-black/5" style={{whiteSpace:'nowrap'}}>
                {s.icon && <span className="mr-1">{s.icon}</span>}{s.translations.find(t => t.languageCode === 'de')?.name || s.slug}
              </a>
            ))}
          </div>
        </nav>
      )}
      <main className="mx-auto max-w-2xl px-4">
        {menu.sections.map(section => {
          const sName = section.translations.find(t => t.languageCode === 'de')?.name || section.slug;
          return (
            <section key={section.id} id={section.slug} className="scroll-mt-16 py-8">
              <div className="mb-6 text-center">
                {section.icon && <span className="text-2xl">{section.icon}</span>}
                <h2 className="text-xl font-bold tracking-tight" style={{fontFamily: "'Playfair Display', serif"}}>{sName}</h2>
                <div className="mx-auto mt-3 h-px w-16" style={{backgroundColor: (theme?.accentColor || '#8B6914') + '40'}} />
              </div>
              <div className="space-y-2">
                {section.items.map(item => {
                  const iName = item.translations.find(t => t.languageCode === 'de')?.name || '';
                  const iDesc = item.translations.find(t => t.languageCode === 'de')?.shortDescription;
                  const defPrice = item.priceVariants.find(p => p.isDefault) || item.priceVariants[0];
                  const multiPrice = item.priceVariants.length > 1;
                  return (
                    <div key={item.id} className={`rounded-xl border bg-white p-4 shadow-sm ${item.isSoldOut ? 'opacity-50' : ''}`}>
                      <div className="flex items-start justify-between gap-3">
                        <div>
                          <div className="flex items-center gap-2 flex-wrap">
                            <h3 className="text-base font-semibold" style={{fontFamily: "'Playfair Display', serif"}}>{iName}</h3>
                            {item.isHighlight && item.highlightType && (
                              <span className="rounded-full px-2 py-0.5 text-[10px] font-semibold text-white" style={{backgroundColor: theme?.accentColor || '#8B6914'}}>{hl[item.highlightType] || ''}</span>
                            )}
                            {item.isSoldOut && <span className="rounded-full bg-red-100 px-2 py-0.5 text-[10px] font-medium text-red-600">Ausverkauft</span>}
                          </div>
                          {iDesc && <p className="mt-1 text-sm opacity-60">{iDesc}</p>}
                          {item.wineProfile && (
                            <div className="mt-2 flex flex-wrap gap-x-3 text-xs opacity-50">
                              {item.wineProfile.winery && <span>{item.wineProfile.winery}</span>}
                              {item.wineProfile.vintage && <span>{item.wineProfile.vintage}</span>}
                              {item.wineProfile.region && <span>{item.wineProfile.region}</span>}
                            </div>
                          )}
                          {item.tags.length > 0 && (
                            <div className="mt-2 flex flex-wrap gap-1">
                              {item.tags.map(t => (
                                <span key={t.tag.id} className="rounded-full bg-gray-100 px-2 py-0.5 text-[10px] font-medium">{t.tag.icon} {t.tag.translations.find(tr => tr.languageCode === 'de')?.name}</span>
                              ))}
                            </div>
                          )}
                        </div>
                      </div>
                      <div className="mt-3 flex flex-wrap items-baseline gap-3">
                        {multiPrice ? item.priceVariants.map(pv => (
                          <div key={pv.id} className="text-sm">
                            <span className="font-semibold tabular-nums">{formatPrice(Number(pv.price))}</span>
                            {(pv.label || pv.volume) && <span className="ml-1 text-xs opacity-40">{pv.label || pv.volume}</span>}
                          </div>
                        )) : defPrice && <span className="text-sm font-semibold tabular-nums">{formatPrice(Number(defPrice.price))}</span>}
                      </div>
                    </div>
                  );
                })}
              </div>
            </section>
          );
        })}
        <div className="border-t py-8 text-center">
          <p className="text-xs opacity-30">Alle Preise in Euro inkl. MwSt.</p>
          <p className="mt-1 text-xs opacity-20">Powered by MenuCard Pro</p>
        </div>
      </main>
    </div>
  );
}
FILE

# ============================================
# PUBLIC: QR Redirect
# ============================================
cat > "src/app/(public)/q/[code]/page.tsx" << 'FILE'
import { redirect, notFound } from 'next/navigation';
import prisma from '@/lib/prisma';

export default async function QRRedirectPage({ params }: { params: { code: string } }) {
  const qr = await prisma.qRCode.findUnique({
    where: { shortCode: params.code },
    include: { location: { include: { tenant: true } }, menu: true },
  });
  if (!qr || !qr.isActive) return notFound();
  await prisma.qRCode.update({ where: { id: qr.id }, data: { scans: { increment: 1 } } });
  const url = qr.menu ? `/${qr.location.tenant.slug}/${qr.location.slug}/${qr.menu.slug}` : `/${qr.location.tenant.slug}/${qr.location.slug}`;
  redirect(url);
}
FILE

# ============================================
# SEED SCRIPT
# ============================================
cat > prisma/seed.ts << 'SEEDFILE'
import { PrismaClient, MenuType, ItemType, WineStyle, WineBody, WineSweetness, BeverageCategory, UserRole } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding...');

  const tenant = await prisma.tenant.upsert({
    where: { slug: 'hotel-sonnblick' }, update: {},
    create: { name: 'Hotel Sonnblick', slug: 'hotel-sonnblick', website: 'https://www.hotel-sonnblick.at', email: 'info@hotel-sonnblick.at', phone: '+43 6541 6340' },
  });

  await prisma.tenantLanguage.upsert({ where: { tenantId_code: { tenantId: tenant.id, code: 'de' } }, update: {}, create: { tenantId: tenant.id, code: 'de', name: 'Deutsch', isDefault: true } });
  await prisma.tenantLanguage.upsert({ where: { tenantId_code: { tenantId: tenant.id, code: 'en' } }, update: {}, create: { tenantId: tenant.id, code: 'en', name: 'English' } });

  await prisma.theme.deleteMany({ where: { tenantId: tenant.id } });
  await prisma.theme.create({ data: { tenantId: tenant.id, name: 'Sonnblick Elegant', primaryColor: '#1a1a1a', accentColor: '#8B6914', backgroundColor: '#FAFAF8', textColor: '#1a1a1a' } });

  const pwHash = await bcrypt.hash('Sonnblick2024!', 12);
  await prisma.user.upsert({ where: { email: 'admin@hotel-sonnblick.at' }, update: {}, create: { tenantId: tenant.id, email: 'admin@hotel-sonnblick.at', passwordHash: pwHash, firstName: 'Admin', lastName: 'Sonnblick', role: UserRole.OWNER } });

  const restaurant = await prisma.location.upsert({
    where: { tenantId_slug: { tenantId: tenant.id, slug: 'restaurant' } }, update: {},
    create: { tenantId: tenant.id, name: 'Restaurant', slug: 'restaurant', address: 'Dorfstrasse 174, 5753 Saalbach' },
  });
  await prisma.locationTranslation.upsert({ where: { locationId_languageCode: { locationId: restaurant.id, languageCode: 'de' } }, update: {}, create: { locationId: restaurant.id, languageCode: 'de', name: 'Restaurant', description: 'Unser Restaurant mit regionaler Kueche' } });
  await prisma.locationTranslation.upsert({ where: { locationId_languageCode: { locationId: restaurant.id, languageCode: 'en' } }, update: {}, create: { locationId: restaurant.id, languageCode: 'en', name: 'Restaurant', description: 'Our restaurant with regional cuisine' } });

  const speisekarte = await prisma.menu.create({ data: {
    locationId: restaurant.id, type: MenuType.FOOD, slug: 'speisekarte', publishedAt: new Date(),
    translations: { create: [
      { languageCode: 'de', name: 'Speisekarte', description: 'Unsere aktuelle Speisekarte' },
      { languageCode: 'en', name: 'Menu', description: 'Our current menu' },
    ] },
  } });

  const vorspeisen = await prisma.menuSection.create({ data: {
    menuId: speisekarte.id, slug: 'vorspeisen', sortOrder: 0, icon: '🥗',
    translations: { create: [{ languageCode: 'de', name: 'Vorspeisen' }, { languageCode: 'en', name: 'Starters' }] },
  } });

  await prisma.menuItem.create({ data: {
    sectionId: vorspeisen.id, type: ItemType.FOOD, sortOrder: 0, isHighlight: true, highlightType: 'SEASONAL',
    translations: { create: [
      { languageCode: 'de', name: 'Kuerbiscremesuppe', shortDescription: 'mit Kuerbiskernoel und geroesteten Kernen' },
      { languageCode: 'en', name: 'Pumpkin Cream Soup', shortDescription: 'with pumpkin seed oil and roasted seeds' },
    ] },
    priceVariants: { create: [{ price: 12.50, currency: 'EUR', isDefault: true }] },
  } });

  await prisma.menuItem.create({ data: {
    sectionId: vorspeisen.id, type: ItemType.FOOD, sortOrder: 1, isHighlight: true, highlightType: 'RECOMMENDATION',
    translations: { create: [
      { languageCode: 'de', name: 'Beef Tartare', shortDescription: 'vom Pinzgauer Rind, klassisch angemacht' },
      { languageCode: 'en', name: 'Beef Tartare', shortDescription: 'from Pinzgau cattle, classically prepared' },
    ] },
    priceVariants: { create: [{ price: 18.90, currency: 'EUR', isDefault: true }] },
  } });

  const hauptspeisen = await prisma.menuSection.create({ data: {
    menuId: speisekarte.id, slug: 'hauptspeisen', sortOrder: 1, icon: '🍽️',
    translations: { create: [{ languageCode: 'de', name: 'Hauptspeisen' }, { languageCode: 'en', name: 'Main Courses' }] },
  } });

  await prisma.menuItem.create({ data: {
    sectionId: hauptspeisen.id, type: ItemType.FOOD, sortOrder: 0, isHighlight: true, highlightType: 'POPULAR',
    translations: { create: [
      { languageCode: 'de', name: 'Wiener Schnitzel', shortDescription: 'vom Kalb, mit Petersilkartoffeln und Preiselbeeren' },
      { languageCode: 'en', name: 'Wiener Schnitzel', shortDescription: 'veal, with parsley potatoes and lingonberries' },
    ] },
    priceVariants: { create: [{ price: 28.50, currency: 'EUR', isDefault: true }] },
  } });

  await prisma.menuItem.create({ data: {
    sectionId: hauptspeisen.id, type: ItemType.FOOD, sortOrder: 1,
    translations: { create: [
      { languageCode: 'de', name: 'Tafelspitz', shortDescription: 'mit Apfelkren und Schnittlauchsauce' },
      { languageCode: 'en', name: 'Boiled Beef', shortDescription: 'with apple horseradish and chive sauce' },
    ] },
    priceVariants: { create: [{ price: 26.90, currency: 'EUR', isDefault: true }] },
  } });

  await prisma.menuItem.create({ data: {
    sectionId: hauptspeisen.id, type: ItemType.FOOD, sortOrder: 2, isHighlight: true, highlightType: 'CHEFS_CHOICE',
    translations: { create: [
      { languageCode: 'de', name: 'Gebratener Saibling', shortDescription: 'auf Blattspinat mit Mandelbutter' },
      { languageCode: 'en', name: 'Pan-fried Arctic Char', shortDescription: 'on spinach with almond butter' },
    ] },
    priceVariants: { create: [{ price: 29.50, currency: 'EUR', isDefault: true }] },
  } });

  await prisma.menuItem.create({ data: {
    sectionId: hauptspeisen.id, type: ItemType.FOOD, sortOrder: 3,
    translations: { create: [
      { languageCode: 'de', name: 'Pinzgauer Kaesespaetzle', shortDescription: 'mit Bergkaese und Roestzwiebeln' },
      { languageCode: 'en', name: 'Cheese Spaetzle', shortDescription: 'with mountain cheese and fried onions' },
    ] },
    priceVariants: { create: [{ price: 19.50, currency: 'EUR', isDefault: true }] },
  } });

  const desserts = await prisma.menuSection.create({ data: {
    menuId: speisekarte.id, slug: 'desserts', sortOrder: 2, icon: '🍰',
    translations: { create: [{ languageCode: 'de', name: 'Desserts' }, { languageCode: 'en', name: 'Desserts' }] },
  } });

  await prisma.menuItem.create({ data: {
    sectionId: desserts.id, type: ItemType.FOOD, sortOrder: 0, isHighlight: true, highlightType: 'RECOMMENDATION',
    translations: { create: [
      { languageCode: 'de', name: 'Salzburger Nockerl', shortDescription: 'luftig-leicht mit Himbeerroester' },
      { languageCode: 'en', name: 'Salzburg Souffle', shortDescription: 'light and fluffy with raspberry compote' },
    ] },
    priceVariants: { create: [{ price: 14.90, currency: 'EUR', isDefault: true }] },
  } });

  await prisma.menuItem.create({ data: {
    sectionId: desserts.id, type: ItemType.FOOD, sortOrder: 1,
    translations: { create: [
      { languageCode: 'de', name: 'Kaiserschmarrn', shortDescription: 'mit Zwetschkenroester' },
      { languageCode: 'en', name: 'Kaiserschmarrn', shortDescription: 'with plum compote' },
    ] },
    priceVariants: { create: [{ price: 15.50, currency: 'EUR', isDefault: true }] },
  } });

  // Weinkarte
  const weinkarte = await prisma.menu.create({ data: {
    locationId: restaurant.id, type: MenuType.WINE, slug: 'weinkarte', sortOrder: 1, publishedAt: new Date(),
    translations: { create: [{ languageCode: 'de', name: 'Weinkarte' }, { languageCode: 'en', name: 'Wine List' }] },
  } });

  const rotweine = await prisma.menuSection.create({ data: {
    menuId: weinkarte.id, slug: 'rotweine', sortOrder: 0, icon: '🍷',
    translations: { create: [{ languageCode: 'de', name: 'Rotweine' }, { languageCode: 'en', name: 'Red Wines' }] },
  } });

  await prisma.menuItem.create({ data: {
    sectionId: rotweine.id, type: ItemType.WINE, sortOrder: 0, isHighlight: true, highlightType: 'RECOMMENDATION',
    translations: { create: [
      { languageCode: 'de', name: 'Blaufraenkisch Reserve', shortDescription: 'Weingut Moric, Burgenland 2019' },
      { languageCode: 'en', name: 'Blaufraenkisch Reserve', shortDescription: 'Weingut Moric, Burgenland 2019' },
    ] },
    priceVariants: { create: [
      { label: 'Glas', price: 9.50, currency: 'EUR', volume: '0.15l', sortOrder: 0 },
      { label: 'Flasche', price: 48.00, currency: 'EUR', volume: '0.75l', sortOrder: 1, isDefault: true },
    ] },
    wineProfile: { create: { winery: 'Weingut Moric', vintage: 2019, grapeVarieties: ['Blaufraenkisch'], region: 'Burgenland', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.MEDIUM_FULL, sweetness: WineSweetness.DRY, alcoholContent: 13.5, servingTemp: '16-18C', tastingNotes: 'Dunkle Beeren, schwarzer Pfeffer, feine Eiche', foodPairing: 'Rind, Wild, reifer Kaese' } },
  } });

  // QR Code
  await prisma.qRCode.create({ data: { locationId: restaurant.id, menuId: speisekarte.id, label: 'Restaurant Tisch', shortCode: 'SB-REST1', primaryColor: '#1a1a1a', bgColor: '#FAFAF8' } });

  console.log('Seed done! Login: admin@hotel-sonnblick.at / Sonnblick2024!');
}

main().catch(e => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());
SEEDFILE

echo "✓ Alle Dateien erstellt"
echo ""
echo "Starte Build..."

# Generate Prisma Client
npx prisma generate

# Seed the database
npx tsx prisma/seed.ts

# Build the app
npx next build

echo ""
echo "============================================"
echo "Setup abgeschlossen!"
echo "Starte mit: cd /var/www/menucard-pro && npx next start -p 3000"
echo "============================================"
