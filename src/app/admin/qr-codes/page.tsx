// @ts-nocheck
'use client';

import { useEffect, useState } from 'react';

type QrCode = {
  id: string;
  shortCode: string;
  label: string | null;
  isActive: boolean;
  scans: number;
  locationId: string | null;
  menuId: string | null;
  menu?: { id: string; slug: string; translations: { language?: string; languageCode?: string; name: string }[]; location?: { name: string; tenant?: { slug: string } } } | null;
  location?: { id: string; name: string; slug: string; tenant?: { slug: string } } | null;
  config: any;
  createdAt: string;
  updatedAt: string;
};

type MenuOption = {
  id: string;
  slug: string;
  type: string;
  name: string;
  locationName: string;
};

function formatDate(dateStr: string): string {
  try {
    return new Date(dateStr).toLocaleDateString('de-AT', { day: '2-digit', month: '2-digit', year: 'numeric' });
  } catch { return dateStr; }
}

function getMenuName(qr: QrCode): string | null {
  if (!qr.menu) return null;
  const de = qr.menu.translations?.find((t: any) => t.language === 'de' || t.languageCode === 'de');
  return de?.name || qr.menu.translations?.[0]?.name || qr.menu.slug || null;
}

function getDisplayName(qr: QrCode): string {
  return qr.label || getMenuName(qr) || qr.shortCode;
}

function getQrUrl(qr: QrCode): string {
  return `https://menu.hotel-sonnblick.at/q/${qr.shortCode}`;
}

function getLocationName(qr: QrCode): string | null {
  if (qr.menu?.location?.name) return qr.menu.location.name;
  if (qr.location?.name) return qr.location.name;
  return null;
}

/* ─── QR Card ─── */
function QrCard({ qr, onToggle, onDelete }: { qr: QrCode; onToggle: (id: string) => void; onDelete: (id: string) => void }) {
  const displayName = getDisplayName(qr);
  const menuName = getMenuName(qr);
  const locationName = getLocationName(qr);
  const qrUrl = getQrUrl(qr);
  const [copied, setCopied] = useState(false);

  const copyUrl = () => {
    navigator.clipboard.writeText(qrUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };

  return (
    <div
      className="rounded-xl overflow-hidden transition-all hover:shadow-md"
      style={{
        fontFamily: "'Roboto', sans-serif",
        backgroundColor: '#FFFFFF',
        border: qr.isActive ? '2px solid #DD3C71' : '1px solid #E5E7EB',
        boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
      }}
    >
      {/* QR-Vorschau */}
      <div
        className="relative h-40 flex flex-col items-center justify-center"
        style={{ backgroundColor: '#F9FAFB' }}
      >
        <div
          className="w-28 h-28 rounded-xl flex items-center justify-center"
          style={{ backgroundColor: '#FFF', boxShadow: '0 2px 8px rgba(0,0,0,0.08)' }}
        >
          <img
            src={`https://api.qrserver.com/v1/create-qr-code/?size=112x112&data=${encodeURIComponent(qrUrl)}&margin=4`}
            alt={`QR: ${displayName}`}
            width={112}
            height={112}
            className="rounded-lg"
            style={{ opacity: qr.isActive ? 1 : 0.35 }}
          />
        </div>
        {/* Status-Badge */}
        <span
          className="absolute top-3 right-3 flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider"
          style={{
            backgroundColor: qr.isActive ? '#ECFDF5' : '#FEF2F2',
            color: qr.isActive ? '#22C55E' : '#EF4444',
          }}
        >
          <span
            className="w-1.5 h-1.5 rounded-full"
            style={{ backgroundColor: qr.isActive ? '#22C55E' : '#EF4444' }}
          />
          {qr.isActive ? 'Aktiv' : 'Inaktiv'}
        </span>
        {/* Delete button */}
        <button
          onClick={() => onDelete(qr.id)}
          className="absolute top-3 left-3 flex items-center justify-center w-7 h-7 rounded-full transition-colors"
          style={{ backgroundColor: 'rgba(0,0,0,0.06)', color: '#999' }}
          onMouseEnter={e => { e.currentTarget.style.backgroundColor = '#FEF2F2'; e.currentTarget.style.color = '#EF4444'; }}
          onMouseLeave={e => { e.currentTarget.style.backgroundColor = 'rgba(0,0,0,0.06)'; e.currentTarget.style.color = '#999'; }}
          title="QR-Code löschen"
        >
          <span className="material-symbols-outlined" style={{ fontSize: 16 }}>delete</span>
        </button>
      </div>

      {/* Content */}
      <div className="p-4">
        <h3
          className="text-base font-bold mb-1 truncate"
          style={{ color: '#171A1F' }}
        >
          {displayName}
        </h3>

        {menuName && (
          <div className="flex items-center gap-1.5 mb-2">
            <span className="material-symbols-outlined" style={{ fontSize: 14, color: '#DD3C71' }}>menu_book</span>
            <span className="text-xs" style={{ color: '#565D6D' }}>{menuName}</span>
          </div>
        )}

        {locationName && (
          <div className="flex items-center gap-1.5 mb-3">
            <span className="material-symbols-outlined" style={{ fontSize: 14, color: '#999' }}>location_on</span>
            <span className="text-xs" style={{ color: '#999' }}>{locationName}</span>
          </div>
        )}

        {/* Stats */}
        <div className="flex items-center gap-4 mb-3 py-2" style={{ borderTop: '1px solid #F3F3F6', borderBottom: '1px solid #F3F3F6' }}>
          <div className="flex items-center gap-1.5">
            <span className="material-symbols-outlined" style={{ fontSize: 16, color: '#DD3C71' }}>visibility</span>
            <span className="text-sm font-bold" style={{ color: '#171A1F' }}>{(qr.scans || 0).toLocaleString('de-AT')}</span>
            <span className="text-[11px]" style={{ color: '#999' }}>Scans</span>
          </div>
          <div className="text-[11px]" style={{ color: '#BBB' }}>
            Erstellt: {formatDate(qr.createdAt)}
          </div>
        </div>

        {/* Short-Code */}
        <div className="mb-3">
          <span className="text-[10px] uppercase tracking-wider font-medium" style={{ color: '#999' }}>Code: </span>
          <span className="text-xs font-mono font-medium" style={{ color: '#565D6D' }}>{qr.shortCode}</span>
        </div>

        {/* Actions */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => onToggle(qr.id)}
            className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg text-xs font-semibold transition-colors"
            style={{
              backgroundColor: qr.isActive ? '#FEF2F2' : '#ECFDF5',
              color: qr.isActive ? '#EF4444' : '#22C55E',
            }}
          >
            <span className="material-symbols-outlined" style={{ fontSize: 14 }}>
              {qr.isActive ? 'pause_circle' : 'play_circle'}
            </span>
            {qr.isActive ? 'Deaktivieren' : 'Aktivieren'}
          </button>
          <button
            className="flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg text-xs font-semibold transition-colors"
            style={{ backgroundColor: copied ? '#ECFDF5' : '#F3F3F6', color: copied ? '#22C55E' : '#565D6D' }}
            onClick={copyUrl}
          >
            <span className="material-symbols-outlined" style={{ fontSize: 14 }}>{copied ? 'check' : 'content_copy'}</span>
            {copied ? 'Kopiert' : 'URL'}
          </button>
          <a
            href={`https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=${encodeURIComponent(qrUrl)}&format=png`}
            download={`qr-${qr.shortCode}.png`}
            className="flex items-center justify-center w-9 h-9 rounded-lg transition-colors"
            style={{ backgroundColor: '#F3F3F6', color: '#565D6D' }}
            onMouseEnter={e => (e.currentTarget.style.backgroundColor = '#E5E7EB')}
            onMouseLeave={e => (e.currentTarget.style.backgroundColor = '#F3F3F6')}
          >
            <span className="material-symbols-outlined" style={{ fontSize: 16 }}>download</span>
          </a>
        </div>
      </div>
    </div>
  );
}

/* ─── Create Modal ─── */
function CreateModal({ menus, onClose, onCreate }: {
  menus: MenuOption[];
  onClose: () => void;
  onCreate: (data: { menuId?: string; label?: string }) => Promise<void>;
}) {
  const [menuId, setMenuId] = useState('');
  const [label, setLabel] = useState('');
  const [saving, setSaving] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      await onCreate({ menuId: menuId || undefined, label: label.trim() || undefined });
      onClose();
    } catch {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center" style={{ backgroundColor: 'rgba(0,0,0,0.4)' }}>
      <div
        className="rounded-2xl shadow-xl w-full max-w-md mx-4"
        style={{ backgroundColor: '#FFF', fontFamily: "'Roboto', sans-serif" }}
      >
        {/* Header */}
        <div className="flex items-center justify-between p-5 border-b" style={{ borderColor: '#F3F3F6' }}>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg flex items-center justify-center" style={{ backgroundColor: '#ECFDF5' }}>
              <span className="material-symbols-outlined" style={{ fontSize: 22, color: '#22C55E' }}>qr_code_2</span>
            </div>
            <div>
              <h2 className="text-lg font-bold" style={{ color: '#171A1F' }}>Neuer QR-Code</h2>
              <p className="text-xs" style={{ color: '#999' }}>Verknüpfen Sie eine Speisekarte</p>
            </div>
          </div>
          <button onClick={onClose} className="flex items-center justify-center w-8 h-8 rounded-lg hover:bg-gray-100 transition-colors">
            <span className="material-symbols-outlined" style={{ fontSize: 20, color: '#999' }}>close</span>
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-5 space-y-4">
          {/* Menu Selection */}
          <div>
            <label className="block text-sm font-medium mb-1.5" style={{ color: '#171A1F' }}>
              Speisekarte <span className="text-xs font-normal" style={{ color: '#999' }}>(optional)</span>
            </label>
            <select
              value={menuId}
              onChange={e => setMenuId(e.target.value)}
              className="w-full rounded-lg border px-3 py-2.5 text-sm outline-none transition-colors focus:border-[#DD3C71]"
              style={{ borderColor: '#E5E7EB', backgroundColor: '#FAFAFA' }}
            >
              <option value="">Keine Karte verknüpfen</option>
              {menus.map(m => (
                <option key={m.id} value={m.id}>
                  {m.name} — {m.locationName} ({m.type === 'WINE' ? 'Wein' : m.type === 'BAR' ? 'Bar' : 'Event'})
                </option>
              ))}
            </select>
          </div>

          {/* Label */}
          <div>
            <label className="block text-sm font-medium mb-1.5" style={{ color: '#171A1F' }}>
              Bezeichnung <span className="text-xs font-normal" style={{ color: '#999' }}>(optional)</span>
            </label>
            <input
              type="text"
              value={label}
              onChange={e => setLabel(e.target.value)}
              placeholder="z.B. Tisch 5, Eingang, Terrasse..."
              className="w-full rounded-lg border px-3 py-2.5 text-sm outline-none transition-colors focus:border-[#DD3C71]"
              style={{ borderColor: '#E5E7EB', backgroundColor: '#FAFAFA' }}
            />
          </div>

          {/* Info */}
          <div className="flex items-start gap-2.5 p-3 rounded-lg" style={{ backgroundColor: '#F0F9FF' }}>
            <span className="material-symbols-outlined flex-shrink-0" style={{ fontSize: 18, color: '#3B82F6', marginTop: 1 }}>info</span>
            <p className="text-xs leading-relaxed" style={{ color: '#565D6D' }}>
              Der Short-Code wird automatisch generiert. Der QR-Code leitet auf die verknüpfte Speisekarte weiter.
            </p>
          </div>

          {/* Actions */}
          <div className="flex items-center gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2.5 rounded-lg text-sm font-medium transition-colors"
              style={{ backgroundColor: '#F3F3F6', color: '#565D6D' }}
            >
              Abbrechen
            </button>
            <button
              type="submit"
              disabled={saving}
              className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg text-sm font-semibold text-white transition-colors disabled:opacity-50"
              style={{ backgroundColor: '#22C55E' }}
            >
              {saving ? (
                <div className="animate-spin rounded-full h-4 w-4 border-2" style={{ borderColor: 'rgba(255,255,255,0.3)', borderTopColor: '#FFF' }} />
              ) : (
                <>
                  <span className="material-symbols-outlined" style={{ fontSize: 16 }}>add</span>
                  Erstellen
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

/* ─── Main Page ─── */
export default function QrCodesPage() {
  const [qrCodes, setQrCodes] = useState<QrCode[]>([]);
  const [menus, setMenus] = useState<MenuOption[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'active' | 'inactive'>('all');
  const [showCreate, setShowCreate] = useState(false);

  useEffect(() => {
    Promise.all([
      fetch('/api/v1/qr-codes').then(r => r.json()),
      fetch('/api/v1/menus').then(r => r.json()),
    ]).then(([qrData, menuData]) => {
      const items = Array.isArray(qrData) ? qrData : qrData.qrCodes || qrData.items || [];
      setQrCodes(items);

      const menuList = (Array.isArray(menuData) ? menuData : menuData.menus || []).map((m: any) => {
        const de = m.translations?.find((t: any) => t.language === 'de' || t.languageCode === 'de');
        return {
          id: m.id,
          slug: m.slug,
          type: m.type,
          name: de?.name || m.translations?.[0]?.name || m.slug,
          locationName: m.location?.name || '',
        };
      });
      setMenus(menuList);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, []);

  const handleToggle = async (id: string) => {
    const qr = qrCodes.find(q => q.id === id);
    if (!qr) return;
    try {
      await fetch(`/api/v1/qr-codes/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ isActive: !qr.isActive }),
      });
      setQrCodes(prev => prev.map(q => q.id === id ? { ...q, isActive: !q.isActive } : q));
    } catch (err) {
      console.error('Toggle failed', err);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('QR-Code wirklich löschen?')) return;
    try {
      await fetch(`/api/v1/qr-codes/${id}`, { method: 'DELETE' });
      setQrCodes(prev => prev.filter(q => q.id !== id));
    } catch (err) {
      console.error('Delete failed', err);
    }
  };

  const handleCreate = async (data: { menuId?: string; label?: string }) => {
    const res = await fetch('/api/v1/qr-codes', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error('Create failed');
    const newQr = await res.json();
    setQrCodes(prev => [newQr, ...prev]);
  };

  const filtered = qrCodes.filter(q => {
    if (filter === 'active') return q.isActive;
    if (filter === 'inactive') return !q.isActive;
    return true;
  });

  const activeCount = qrCodes.filter(q => q.isActive).length;
  const totalScans = qrCodes.reduce((sum, q) => sum + (q.scans || 0), 0);

  return (
    <div className="p-6 max-w-6xl mx-auto" style={{ fontFamily: "'Roboto', sans-serif" }}>
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold mb-1" style={{ color: '#171A1F' }}>
            QR-Codes
          </h1>
          <p className="text-sm" style={{ color: '#565D6D' }}>
            Erstellen und verwalten Sie QR-Codes für Ihre digitalen Speisekarten
          </p>
        </div>
        <button
          onClick={() => setShowCreate(true)}
          className="flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-semibold transition-colors"
          style={{ backgroundColor: '#22C55E', color: '#FFF' }}
          onMouseEnter={e => (e.currentTarget.style.backgroundColor = '#16A34A')}
          onMouseLeave={e => (e.currentTarget.style.backgroundColor = '#22C55E')}
        >
          <span className="material-symbols-outlined" style={{ fontSize: 18 }}>add</span>
          Neuer QR-Code
        </button>
      </div>

      {/* KPI-Leiste */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        <div
          className="rounded-xl p-4 flex items-center gap-4"
          style={{ backgroundColor: '#FFF', border: '1px solid #E5E7EB', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}
        >
          <div className="w-10 h-10 rounded-lg flex items-center justify-center" style={{ backgroundColor: '#FDF2F5' }}>
            <span className="material-symbols-outlined" style={{ fontSize: 22, color: '#DD3C71' }}>qr_code_2</span>
          </div>
          <div>
            <div className="text-2xl font-bold" style={{ color: '#171A1F' }}>{qrCodes.length}</div>
            <div className="text-xs" style={{ color: '#999' }}>QR-Codes gesamt</div>
          </div>
        </div>
        <div
          className="rounded-xl p-4 flex items-center gap-4"
          style={{ backgroundColor: '#FFF', border: '1px solid #E5E7EB', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}
        >
          <div className="w-10 h-10 rounded-lg flex items-center justify-center" style={{ backgroundColor: '#ECFDF5' }}>
            <span className="material-symbols-outlined" style={{ fontSize: 22, color: '#22C55E' }}>check_circle</span>
          </div>
          <div>
            <div className="text-2xl font-bold" style={{ color: '#171A1F' }}>{activeCount}</div>
            <div className="text-xs" style={{ color: '#999' }}>Aktiv</div>
          </div>
        </div>
        <div
          className="rounded-xl p-4 flex items-center gap-4"
          style={{ backgroundColor: '#FFF', border: '1px solid #E5E7EB', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}
        >
          <div className="w-10 h-10 rounded-lg flex items-center justify-center" style={{ backgroundColor: '#FFF7ED' }}>
            <span className="material-symbols-outlined" style={{ fontSize: 22, color: '#F59E0B' }}>visibility</span>
          </div>
          <div>
            <div className="text-2xl font-bold" style={{ color: '#171A1F' }}>{totalScans.toLocaleString('de-AT')}</div>
            <div className="text-xs" style={{ color: '#999' }}>Scans gesamt</div>
          </div>
        </div>
      </div>

      {/* Filter-Tabs */}
      <div className="flex items-center gap-1 p-1 rounded-lg mb-6" style={{ backgroundColor: '#F3F3F6' }}>
        {[
          { key: 'all' as const, label: 'Alle', count: qrCodes.length },
          { key: 'active' as const, label: 'Aktiv', count: activeCount },
          { key: 'inactive' as const, label: 'Inaktiv', count: qrCodes.length - activeCount },
        ].map(tab => (
          <button
            key={tab.key}
            onClick={() => setFilter(tab.key)}
            className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 rounded-md text-sm font-medium transition-colors"
            style={{
              backgroundColor: filter === tab.key ? '#FFFFFF' : 'transparent',
              color: filter === tab.key ? '#DD3C71' : '#565D6D',
              boxShadow: filter === tab.key ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
            }}
          >
            {tab.label}
            <span
              className="text-[10px] font-bold px-1.5 py-0.5 rounded-full"
              style={{
                backgroundColor: filter === tab.key ? '#FDF2F5' : '#E5E7EB',
                color: filter === tab.key ? '#DD3C71' : '#999',
              }}
            >
              {tab.count}
            </span>
          </button>
        ))}
      </div>

      {/* Loading */}
      {loading && (
        <div className="flex items-center justify-center py-16">
          <div
            className="animate-spin rounded-full h-8 w-8 border-2"
            style={{ borderColor: '#F3F3F6', borderTopColor: '#DD3C71' }}
          />
        </div>
      )}

      {/* QR-Code Grid */}
      {!loading && filtered.length > 0 && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {filtered.map(qr => (
            <QrCard key={qr.id} qr={qr} onToggle={handleToggle} onDelete={handleDelete} />
          ))}
        </div>
      )}

      {/* Empty State */}
      {!loading && filtered.length === 0 && (
        <div className="text-center py-16">
          <span className="material-symbols-outlined mb-4 block" style={{ fontSize: 48, color: '#DEE1E6' }}>qr_code_2</span>
          <h3 className="text-base font-semibold mb-1" style={{ color: '#171A1F' }}>
            {filter === 'all' ? 'Noch keine QR-Codes erstellt' : `Keine ${filter === 'active' ? 'aktiven' : 'inaktiven'} QR-Codes`}
          </h3>
          <p className="text-sm mb-4" style={{ color: '#999' }}>
            {filter === 'all'
              ? 'Erstellen Sie Ihren ersten QR-Code für eine digitale Speisekarte.'
              : 'Ändern Sie den Filter, um alle QR-Codes anzuzeigen.'}
          </p>
          {filter === 'all' && (
            <button
              onClick={() => setShowCreate(true)}
              className="inline-flex items-center gap-2 px-5 py-2.5 rounded-lg text-sm font-semibold text-white transition-colors"
              style={{ backgroundColor: '#22C55E' }}
            >
              <span className="material-symbols-outlined" style={{ fontSize: 18 }}>add</span>
              Ersten QR-Code erstellen
            </button>
          )}
        </div>
      )}

      {/* Create Modal */}
      {showCreate && (
        <CreateModal
          menus={menus}
          onClose={() => setShowCreate(false)}
          onCreate={handleCreate}
        />
      )}
    </div>
  );
}
