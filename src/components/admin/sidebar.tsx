'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';
import {
  LayoutDashboard,
  BookOpen,
  UtensilsCrossed,
  QrCode,
  BarChart3,
  Image,
  Upload,
  Settings,
  Palette,
  Languages,
  ShieldAlert,
  Users,
} from 'lucide-react';

const navigation = [
  { name: 'Dashboard', href: '/admin', icon: LayoutDashboard },
  { name: 'Karten', href: '/admin/menus', icon: BookOpen },
  { name: 'Artikel', href: '/admin/items', icon: UtensilsCrossed },
  { name: 'QR-Codes', href: '/admin/qr-codes', icon: QrCode },
  { name: 'Analytics', href: '/admin/analytics', icon: BarChart3 },
  { name: 'Medien', href: '/admin/media', icon: Image },
  { name: 'Import', href: '/admin/import', icon: Upload },
  { name: 'Karten-Design', href: '/admin/design', icon: Palette },
];

const settingsNav = [
  { name: 'Einstellungen', href: '/admin/settings', icon: Settings },
  { name: 'Branding', href: '/admin/settings/theme', icon: Palette },
  { name: 'Sprachen', href: '/admin/settings/languages', icon: Languages },
  { name: 'Allergene', href: '/admin/settings/allergens', icon: ShieldAlert },
  { name: 'Benutzer', href: '/admin/settings/users', icon: Users },
];

export function AdminSidebar() {
  const pathname = usePathname();

  return (
    <aside className="hidden w-64 flex-shrink-0 border-r border-sidebar-border bg-sidebar lg:flex lg:flex-col">
      {/* Logo */}
      <div className="flex h-16 items-center border-b border-sidebar-border px-6">
        <Link href="/admin" className="flex items-center gap-2">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-[#8B6914] text-sm font-bold text-white">
            M
          </div>
          <span className="font-heading text-xl font-semibold">MenuCard Pro</span>
        </Link>
      </div>

      {/* Navigation */}
      <nav className="flex flex-1 flex-col gap-1 overflow-y-auto px-3 py-4">
        <div className="space-y-1">
          {navigation.map((item) => {
            const isActive = pathname === item.href || (item.href !== '/admin' && pathname.startsWith(item.href));
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  'flex items-center gap-3 rounded-lg px-3 py-2.5 text-base font-medium transition-colors',
                  isActive
                    ? 'bg-accent/10 text-accent'
                    : 'text-sidebar-foreground/70 hover:bg-sidebar-border/50 hover:text-sidebar-foreground'
                )}
              >
                <item.icon className="h-4 w-4 flex-shrink-0" />
                {item.name}
              </Link>
            );
          })}
        </div>

        <div className="my-4 border-t border-sidebar-border" />

        <div className="space-y-1">
          <p className="px-3 text-sm font-semibold uppercase tracking-wider text-muted-foreground">
            Verwaltung
          </p>
          {settingsNav.map((item) => {
            const isActive = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  'flex items-center gap-3 rounded-lg px-3 py-2.5 text-base font-medium transition-colors',
                  isActive
                    ? 'bg-accent/10 text-accent'
                    : 'text-sidebar-foreground/70 hover:bg-sidebar-border/50 hover:text-sidebar-foreground'
                )}
              >
                <item.icon className="h-4 w-4 flex-shrink-0" />
                {item.name}
              </Link>
            );
          })}
        </div>
      </nav>

      {/* Footer */}
      <div className="border-t border-sidebar-border px-4 py-3">
        <p className="text-sm text-muted-foreground">MenuCard Pro v0.1.0</p>
      </div>
    </aside>
  );
}
