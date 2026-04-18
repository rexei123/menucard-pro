'use client';

import { useState } from 'react';

type QRData = {
  id: string;
  label: string | null;
  shortCode: string;
  locationName: string;
  locationId: string;
  menuName: string | null;
  menuId: string | null;
  primaryColor: string;
  bgColor: string;
  scans: number;
  isActive: boolean;
  url: string;
};

type Props = {
  initialData: QRData[];
  locations: { id: string; name: string }[];
  menus: { id: string; name: string; locationId: string }[];
  baseUrl: string;
};

export default function QRCodeAdmin({ initialData, locations, menus, baseUrl }: Props) {
  const [qrCodes, setQrCodes] = useState<QRData[]>(initialData);
  const [showCreate, setShowCreate] = useState(false);
  const [creating, setCreating] = useState(false);
  const [preview, setPreview] = useState<string | null>(null);

  // Create form state
  const [newLabel, setNewLabel] = useState('');
  const [newLocationId, setNewLocationId] = useState(locations[0]?.id || '');
  const [newMenuId, setNewMenuId] = useState('');
  const [newFg, setNewFg] = useState('#000000');
  const [newBg, setNewBg] = useState('#FFFFFF');

  const filteredMenus = menus.filter(m => m.locationId === newLocationId);

  const handleCreate = async () => {
    if (!newLocationId) return;
    setCreating(true);
    try {
      const res = await fetch('/api/v1/qr-codes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          locationId: newLocationId,
          menuId: newMenuId || null,
          label: newLabel || null,
          primaryColor: newFg,
          bgColor: newBg,
        }),
      });
      if (res.ok) {
        const qr = await res.json();
        const menuObj = menus.find(m => m.id === qr.menuId);
        setQrCodes(prev => [{
          id: qr.id,
          label: qr.label,
          shortCode: qr.shortCode,
          locationName: locations.find(l => l.id === qr.locationId)?.name || '',
          locationId: qr.locationId,
          menuName: menuObj?.name || null,
          menuId: qr.menuId,
          primaryColor: qr.primaryColor,
          bgColor: qr.bgColor,
          scans: 0,
          isActive: true,
          url: `${baseUrl}/q/${qr.shortCode}`,
        }, ...prev]);
        setShowCreate(false);
        setNewLabel('');
        setNewMenuId('');
      }
    } finally { setCreating(false); }
  };

  const toggleActive = async (id: string, current: boolean) => {
    const res = await fetch(`/api/v1/qr-codes/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ isActive: !current }),
    });
    if (res.ok) {
      setQrCodes(prev => prev.map(q => q.id === id ? { ...q, isActive: !current } : q));
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('QR-Code wirklich löschen?')) return;
    const res = await fetch(`/api/v1/qr-codes/${id}`, { method: 'DELETE' });
    if (res.ok) setQrCodes(prev => prev.filter(q => q.id !== id));
  };

  const downloadQR = (url: string, code: string, format: 'png' | 'svg') => {
    const qrUrl = `/api/v1/qr-codes/generate?url=${encodeURIComponent(url)}&format=${format}&size=1024`;
    const a = document.createElement('a');
    a.href = qrUrl;
    a.download = `qr-${code}.${format}`;
    a.click();
  };

  return (
    <div>
      {/* Actions */}
      <div className="mb-6 flex items-center justify-between">
        <p className="text-base text-gray-500">{qrCodes.length} QR-Codes</p>
        <button
          onClick={() => setShowCreate(!showCreate)}
          className="rounded-lg px-4 py-2 text-base font-medium text-white transition-colors"
          style={{ backgroundColor: '#8B6914' }}
        >
          + Neuer QR-Code
        </button>
      </div>

      {/* Create Form */}
      {showCreate && (
        <div className="mb-6 rounded-xl border bg-white p-6 shadow-sm">
          <h2 className="mb-4 text-xl font-semibold">Neuer QR-Code</h2>
          <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-500">Label</label>
              <input
                type="text"
                value={newLabel}
                onChange={e => setNewLabel(e.target.value)}
                placeholder="z.B. Tisch 5, Lobby, Bar..."
                className="w-full rounded-lg border px-3 py-2 text-base outline-none focus:border-gray-400"
              />
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-500">Standort</label>
              <select
                value={newLocationId}
                onChange={e => { setNewLocationId(e.target.value); setNewMenuId(''); }}
                className="w-full rounded-lg border px-3 py-2 text-base outline-none"
              >
                {locations.map(l => <option key={l.id} value={l.id}>{l.name}</option>)}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-500">Karte (optional)</label>
              <select
                value={newMenuId}
                onChange={e => setNewMenuId(e.target.value)}
                className="w-full rounded-lg border px-3 py-2 text-base outline-none"
              >
                <option value="">Alle Karten zeigen</option>
                {filteredMenus.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}
              </select>
            </div>
            <div className="flex gap-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-500">QR-Farbe</label>
                <input type="color" value={newFg} onChange={e => setNewFg(e.target.value)} className="h-10 w-14 cursor-pointer rounded border" />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-500">Hintergrund</label>
                <input type="color" value={newBg} onChange={e => setNewBg(e.target.value)} className="h-10 w-14 cursor-pointer rounded border" />
              </div>
            </div>
          </div>
          <div className="mt-4 flex gap-2">
            <button
              onClick={handleCreate}
              disabled={creating}
              className="rounded-lg px-4 py-2 text-base font-medium text-white disabled:opacity-50"
              style={{ backgroundColor: '#8B6914' }}
            >
              {creating ? 'Erstelle...' : 'Erstellen'}
            </button>
            <button onClick={() => setShowCreate(false)} className="rounded-lg border px-4 py-2 text-base font-medium">
              Abbrechen
            </button>
          </div>
        </div>
      )}

      {/* QR Code List */}
      <div className="space-y-3">
        {qrCodes.map(qr => (
          <div key={qr.id} className={`rounded-xl border bg-white p-4 shadow-sm transition-opacity ${qr.isActive ? '' : 'opacity-50'}`}>
            <div className="flex items-start gap-4">
              {/* QR Preview */}
              <div className="flex-shrink-0">
                <img
                  src={`/api/v1/qr-codes/generate?url=${encodeURIComponent(qr.url)}&format=png&size=120&fg=${encodeURIComponent(qr.primaryColor)}&bg=${encodeURIComponent(qr.bgColor)}`}
                  alt={`QR ${qr.shortCode}`}
                  width={80}
                  height={80}
                  className="rounded-lg border"
                />
              </div>

              {/* Info */}
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <h3 className="text-base font-semibold">{qr.label || qr.shortCode}</h3>
                  <span className={`rounded-full px-2 py-0.5 text-sm font-medium ${qr.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                    {qr.isActive ? 'Aktiv' : 'Inaktiv'}
                  </span>
                </div>
                <p className="mt-1 text-sm text-gray-400">
                  {qr.locationName}{qr.menuName ? ` → ${qr.menuName}` : ' → Alle Karten'}
                </p>
                <p className="mt-0.5 text-sm font-mono text-gray-300">/q/{qr.shortCode}</p>
                <div className="mt-2 flex items-center gap-1">
                  <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="opacity-40"><path d="M15.5 2H8.6c-.4 0-.8.2-1.1.5-.3.3-.5.7-.5 1.1v16.8c0 .4.2.8.5 1.1.3.3.7.5 1.1.5h12.8c.4 0 .8-.2 1.1-.5.3-.3.5-.7.5-1.1V7.5L15.5 2z"/><polyline points="14,2 14,8 20,8"/></svg>
                  <span className="text-sm text-gray-400">{qr.scans} Scans</span>
                </div>
              </div>

              {/* Actions */}
              <div className="flex flex-col gap-1">
                <button
                  onClick={() => downloadQR(qr.url, qr.shortCode, 'png')}
                  className="rounded-lg border px-3 py-1.5 text-sm font-medium hover:bg-gray-50"
                >
                  PNG
                </button>
                <button
                  onClick={() => downloadQR(qr.url, qr.shortCode, 'svg')}
                  className="rounded-lg border px-3 py-1.5 text-sm font-medium hover:bg-gray-50"
                >
                  SVG
                </button>
                <button
                  onClick={() => toggleActive(qr.id, qr.isActive)}
                  className="rounded-lg border px-3 py-1.5 text-sm font-medium hover:bg-gray-50"
                >
                  {qr.isActive ? 'Deaktivieren' : 'Aktivieren'}
                </button>
                <button
                  onClick={() => handleDelete(qr.id)}
                  className="rounded-lg border border-red-200 px-3 py-1.5 text-sm font-medium text-red-600 hover:bg-red-50"
                >
                  Löschen
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {qrCodes.length === 0 && (
        <div className="rounded-xl border border-dashed bg-gray-50 px-6 py-12 text-center">
          <p className="text-base text-gray-400">Noch keine QR-Codes erstellt</p>
        </div>
      )}
    </div>
  );
}
