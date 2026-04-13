'use client';
import { useState } from 'react';
import { usePathname } from 'next/navigation';
import Link from 'next/link';
import { Icon } from '@/components/ui/icon';

type NavItem = { href: string; icon: string; label: string; match: RegExp };

const navItems: NavItem[] = [
  { href: '/admin', icon: 'dashboard', label: 'Dashboard', match: /^\/admin$/ },
  { href: '/admin/items', icon: 'restaurant_menu', label: 'Menüverwaltung', match: /^\/admin\/items/ },
  { href: '/admin/menus', icon: 'menu_book', label: 'Karten', match: /^\/admin\/menus/ },
  { href: '/admin/media', icon: 'photo_library', label: 'Bildarchiv', match: /^\/admin\/media/ },
  { href: '/admin/qr-codes', icon: 'qr_code_2', label: 'QR-Codes', match: /^\/admin\/qr-codes/ },
  { href: '/admin/design', icon: 'palette', label: 'Templates', match: /^\/admin\/design/ },
  { href: '/admin/import', icon: 'upload_file', label: 'CSV-Import', match: /^\/admin\/import/ },
  { href: '/admin/pdf-creator', icon: 'picture_as_pdf', label: 'PDF-Creator', match: /^\/admin\/pdf-creator/ },
  { href: '/admin/settings', icon: 'settings', label: 'Einstellungen', match: /^\/admin\/settings/ },
];

export default function IconBar({ userName, userRole }: { userName: string; userRole: string }) {
  const pathname = usePathname();
  const [collapsed, setCollapsed] = useState(false);

  const roleLabel = userRole === 'OWNER' ? 'Administrator' : userRole === 'MANAGER' ? 'Manager' : 'Mitarbeiter';

  return (
    <div
      className="flex h-full flex-col border-r transition-all duration-normal"
      style={{
        width: collapsed ? 'var(--sidebar-collapsed-width)' : 'var(--sidebar-width)',
        backgroundColor: 'var(--color-sidebar-bg)',
        borderColor: 'var(--color-sidebar-border)',
      }}
    >
      {/* Logo */}
      <div className={`flex items-center ${collapsed ? 'justify-center py-4' : 'px-4 py-4 gap-2.5'}`}>
        <div
          className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-lg"
          style={{ backgroundColor: 'var(--color-primary)' }}
        >
          <Icon name="restaurant" size={18} className="text-white" />
        </div>
        {!collapsed && (
          <div className="min-w-0">
            <span
              className="text-sm font-bold block truncate"
              style={{ color: 'var(--color-primary)', fontFamily: 'var(--font-heading)' }}
            >
              MenuCard Pro
            </span>
            <span
              className="text-xs block"
              style={{ color: 'var(--color-text-muted)', fontSize: '0.65rem', letterSpacing: '0.05em', textTransform: 'uppercase' }}
            >
              Admin Panel
            </span>
          </div>
        )}
      </div>

      {/* Toggle */}
      <button
        onClick={() => setCollapsed(!collapsed)}
        className="mx-auto mb-2 flex h-6 w-6 items-center justify-center rounded-md transition-colors"
        style={{ color: 'var(--color-text-muted)' }}
        onMouseEnter={e => (e.currentTarget.style.backgroundColor = 'var(--color-bg-muted)')}
        onMouseLeave={e => (e.currentTarget.style.backgroundColor = 'transparent')}
        title={collapsed ? 'Sidebar ausklappen' : 'Sidebar einklappen'}
      >
        <Icon name={collapsed ? 'chevron_right' : 'chevron_left'} size={16} weight={300} />
      </button>

      {/* Navigation */}
      <nav className="flex flex-1 flex-col gap-0.5 px-2 overflow-y-auto">
        {navItems.map(item => {
          const active = item.match.test(pathname);
          return (
            <Link
              key={item.href}
              href={item.href}
              title={collapsed ? item.label : undefined}
              className="flex items-center gap-2.5 rounded-lg px-2.5 py-2 text-sm transition-all duration-fast"
              style={{
                backgroundColor: active ? 'var(--color-sidebar-active-bg)' : 'transparent',
                color: active ? 'var(--color-sidebar-active-text)' : 'var(--color-sidebar-text)',
                fontWeight: active ? 500 : 400,
              }}
              onMouseEnter={e => {
                if (!active) {
                  e.currentTarget.style.backgroundColor = 'var(--color-sidebar-hover-bg)';
                }
              }}
              onMouseLeave={e => {
                if (!active) {
                  e.currentTarget.style.backgroundColor = 'transparent';
                }
              }}
            >
              <Icon
                name={item.icon}
                size={22}
                weight={active ? 500 : 400}
                fill={active}
                className="flex-shrink-0"
              />
              {!collapsed && <span className="truncate">{item.label}</span>}
            </Link>
          );
        })}
      </nav>

      {/* Divider */}
      <div className="mx-3 my-2 border-t" style={{ borderColor: 'var(--color-sidebar-border)' }} />

      {/* User Info + Actions */}
      <div className={`pb-3 ${collapsed ? 'flex flex-col items-center gap-1.5 px-1' : 'px-3'}`}>
        {collapsed ? (
          <>
            <div
              title={`${userName} (${roleLabel})`}
              className="flex h-8 w-8 items-center justify-center rounded-full text-xs font-semibold"
              style={{ backgroundColor: 'var(--color-primary-light)', color: 'var(--color-primary)' }}
            >
              {userName.charAt(0).toUpperCase()}
            </div>
            <button
              onClick={() => window.location.reload()}
              title="Neu laden"
              className="flex h-8 w-8 items-center justify-center rounded-full transition-colors"
              style={{ color: 'var(--color-text-muted)' }}
              onMouseEnter={e => (e.currentTarget.style.backgroundColor = 'var(--color-bg-muted)')}
              onMouseLeave={e => (e.currentTarget.style.backgroundColor = 'transparent')}
            >
              <Icon name="refresh" size={18} />
            </button>
            <button
              onClick={() => { if(confirm('Abmelden?')) window.location.href='/api/auth/signout'; }}
              title="Abmelden"
              className="flex h-8 w-8 items-center justify-center rounded-full transition-colors"
              style={{ color: 'var(--color-text-muted)' }}
              onMouseEnter={e => (e.currentTarget.style.backgroundColor = 'var(--color-error-light)')}
              onMouseLeave={e => (e.currentTarget.style.backgroundColor = 'transparent')}
            >
              <Icon name="logout" size={18} />
            </button>
          </>
        ) : (
          <>
            {/* User */}
            <div className="flex items-center gap-2.5 mb-2.5 px-0.5">
              <div
                className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full text-sm font-semibold"
                style={{ backgroundColor: 'var(--color-primary-light)', color: 'var(--color-primary)' }}
              >
                {userName.charAt(0).toUpperCase()}
              </div>
              <div className="min-w-0">
                <p className="text-sm font-medium truncate" style={{ color: 'var(--color-text)' }}>
                  {userName}
                </p>
                <p className="text-xs" style={{ color: 'var(--color-text-muted)' }}>
                  {roleLabel}
                </p>
              </div>
            </div>
            {/* Actions */}
            <div className="flex gap-1">
              <button
                onClick={() => window.location.reload()}
                className="flex flex-1 items-center justify-center gap-1.5 rounded-lg px-2 py-1.5 text-xs transition-colors"
                style={{ color: 'var(--color-text-secondary)' }}
                onMouseEnter={e => (e.currentTarget.style.backgroundColor = 'var(--color-bg-muted)')}
                onMouseLeave={e => (e.currentTarget.style.backgroundColor = 'transparent')}
              >
                <Icon name="refresh" size={16} />
                <span>Aktualisieren</span>
              </button>
              <button
                onClick={() => { if(confirm('Abmelden?')) window.location.href='/api/auth/signout'; }}
                className="flex flex-1 items-center justify-center gap-1.5 rounded-lg px-2 py-1.5 text-xs transition-colors"
                style={{ color: 'var(--color-text-secondary)' }}
                onMouseEnter={e => {
                  e.currentTarget.style.backgroundColor = 'var(--color-error-light)';
                  e.currentTarget.style.color = 'var(--color-error)';
                }}
                onMouseLeave={e => {
                  e.currentTarget.style.backgroundColor = 'transparent';
                  e.currentTarget.style.color = 'var(--color-text-secondary)';
                }}
              >
                <Icon name="logout" size={16} />
                <span>Abmelden</span>
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
