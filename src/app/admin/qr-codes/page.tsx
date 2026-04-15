'use client';

import { useEffect, useState } from 'react';

type QrCode = {
  id: string;
  name: string;
  slug: string;
  url: string | null;
  scans: number;
  isActive: boolean;
  menu?: { id: string; name: string; menuType: string } | null;
  location?: { id: string; name: string } | null;
  createdAt: string;
  updatedAt: string;
};

function formatDate(dateStr: string): string {
  try {
    return new Date(dateStr).toLocaleDateString('de-AT', { day: '2-digit', month: '2-digit', year: 'numeric' });
  } catch { return dateStr; }
}

function QrCard({ qr, onToggle }: { qr: QrCode; onToggle: (id: string) => void }) {
  return (
    <div
      className="rounded-xl overflow-hidden transition-all hover:shadow-md"
      style={{
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
          className="w-24 h-24 rounded-xl flex items-center justify-center mb-2"
          style={{ backgroundColor: '#FFF', boxShadow: '0 2px 8px rgba(0,0,0,0.08)' }}
        >
          <span
            className="material-symbols-outlined"
            style={{ fontSize: 48, color: qr.isActive ? '#DD3C71' : '#CCC' }}
          >
            qr_code_2
          </span>
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
      </div>

      {/* Content */}
      <div className="p-4">
        <h3
          className="text-base font-bold mb-1 truncate"
          style={{ fontFamily: "'Inter', sans-serif", color: '#171A1F' }}
        >
          {qr.name}
        </h3>

        {qr.menu && (
          <div className="flex items-center gap-1.5 mb-2">
            <span className="material-symbols-outlined" style={{ fontSize: 14, color: '#DD3C71' }}>menu_book</span>
            <span className="text-xs" style={{ color: '#565D6D' }}>{qr.menu.name}</span>
          </div>
        )}

        {qr.location && (
          <div className="flex items-center gap-1.5 mb-3">
            <span className="material-symbols-outlined" style={{ fontSize: 14, color: '#999' }}>location_on</span>
            <span className="text-xs" style={{ color: '#999' }}>{qr.location.name}</span>
          </div>
        )}

        {/* Stats */}
        <div className="flex items-center gap-4 mb-3 py-2" style={{ borderTop: '1px solid #F3F3F6', borderBottom: '1px solid #F3F3F6' }}>
          <div className="flex items-center gap-1.5">
            <span className="material-symbols-outlined" style={{ fontSize: 16, color: '#DD3C71' }}>visibility</span>
            <span className="text-sm font-bold" style={{ color: '#171A1F' }}>{qr.scans.toLocaleString('de-AT')}</span>
            <span className="text-[11px]" style={{ color: '#999' }}>Scans</span>
          </div>
          <div className="text-[11px]" style={{ color: '#BBB' }}>
            Erstellt: {formatDate(qr.createdAt)}
          </div>
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
            style={{ backgroundColor: '#F3F3F6', color: '#565D6D' }}
            onMouseEnter={e => (e.currentTarget.style.backgroundColor = '#E5E7EB')}
            onMouseLeave={e => (e.currentTarget.style.backgroundColor = '#F3F3F6')}
            onClick={() => {
              if (qr.url) navigator.clipboard.writeText(qr.url);
            }}
          >
            <span className="material-symbols-outlined" style={{ fontSize: 14 }}>content_copy</span>
            URL
          </button>
          <button
            className="flex items-center justify-center w-9 h-9 rounded-lg transition-colors"
            style={{ backgroundColor: '#F3F3F6', color: '#565D6D' }}
            onMouseEnter={e => (e.currentTarget.style.backgroundColor = '#E5E7EB')}
            onMouseLeave={e => (e.currentTarget.style.backgroundColor = '#F3F3F6')}
          >
            <span className="material-symbols-outlined" style={{ fontSize: 16 }}>download</span>
          </button>
        </div>
      </div>
    </div>
  );
}

export default function QrCodesPage() {
  const [qrCodes, setQrCodes] = useState<QrCode[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'active' | 'inactive'>('all');

  useEffect(() => {
    fetch('/api/v1/qr-codes')
      .then(r => r.json())
      .then(data => {
        const items = Array.isArray(data) ? data : data.qrCodes || data.items || [];
        setQrCodes(items);
        setLoading(false);
      })
      .catch(() => setLoading(false));
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

  const filtered = qrCodes.filter(q => {
    if (filter === 'active') return q.isActive;
    if (filter === 'inactive') return !q.isActive;
    return true;
  });

  const activeCount = qrCodes.filter(q => q.isActive).length;
  const totalScans = qrCodes.reduce((sum, q) => sum + (q.scans || 0), 0);

  return (
    <div className="p-6 max-w-6xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1
            className="text-2xl font-bold mb-1"
            style={{ fontFamily: "'Playfair Display', serif", color: '#171A1F' }}
          >
            QR-Codes
          </h1>
          <p className="text-sm" style={{ color: '#565D6D' }}>
            Erstellen und verwalten Sie QR-Codes für Ihre digitalen Speisekarten
          </p>
        </div>
        <button
          className="flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-semibold transition-colors"
          style={{ backgroundColor: '#DD3C71', color: '#FFF' }}
          onMouseEnter={e => (e.currentTarget.style.backgroundColor = '#C42D60')}
          onMouseLeave={e => (e.currentTarget.style.backgroundColor = '#DD3C71')}
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
          <div
            className="w-10 h-10 rounded-lg flex items-center justify-center"
            style={{ backgroundColor: '#FDF2F5' }}
          >
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
          <div
            className="w-10 h-10 rounded-lg flex items-center justify-center"
            style={{ backgroundColor: '#ECFDF5' }}
          >
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
          <div
            className="w-10 h-10 rounded-lg flex items-center justify-center"
            style={{ backgroundColor: '#FFF7ED' }}
          >
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
            <QrCard key={qr.id} qr={qr} onToggle={handleToggle} />
          ))}
        </div>
      )}

      {/* Empty State */}
      {!loading && filtered.length === 0 && (
        <div className="text-center py-16">
          <span
            className="material-symbols-outlined mb-4 block"
            style={{ fontSize: 48, color: '#DEE1E6' }}
          >
            qr_code_2
          </span>
          <h3 className="text-base font-semibold mb-1" style={{ color: '#171A1F' }}>
            {filter === 'all' ? 'Noch keine QR-Codes erstellt' : `Keine ${filter === 'active' ? 'aktiven' : 'inaktiven'} QR-Codes`}
          </h3>
          <p className="text-sm" style={{ color: '#999' }}>
            {filter === 'all'
              ? 'Erstellen Sie Ihren ersten QR-Code für eine digitale Speisekarte.'
              : 'Ändern Sie den Filter, um alle QR-Codes anzuzeigen.'}
          </p>
        </div>
      )}
    </div>
  );
}
