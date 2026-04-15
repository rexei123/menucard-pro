#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Bildarchiv Phase 2: Admin-UI (Icon-Bar, /admin/media, 4 Tabs)
# ═══════════════════════════════════════════════════════════════
cd /var/www/menucard-pro

echo "=== Bildarchiv Phase 2 ==="
echo ""

# Backup
cp src/components/admin/icon-bar.tsx src/components/admin/icon-bar.tsx.bak-bildarchiv

# ───────────────────────────────────────
echo "[1/5] Icon-Bar: Bildarchiv-Menüpunkt..."
# ───────────────────────────────────────

# Bildarchiv nach QR-Codes einfügen
sed -i "/label: 'QR-Codes'/a\\
  { href: '/admin/media', icon: '\xF0\x9F\x96\xBC\xEF\xB8\x8F', label: 'Bildarchiv', match: /^\\\\\\/admin\\\\\\/media/ }," src/components/admin/icon-bar.tsx

echo "  ✓ Icon-Bar erweitert"

# ───────────────────────────────────────
echo "[2/5] Admin Media-Seite mit Tabs..."
# ───────────────────────────────────────

mkdir -p src/app/admin/media/\[id\]

# Hauptseite: /admin/media
cat > src/app/admin/media/page.tsx << 'ENDOFFILE'
import { Metadata } from 'next';
import MediaArchive from '@/components/admin/media-archive';

export const metadata: Metadata = { title: 'Bildarchiv – Admin' };

export default function MediaPage() {
  return <MediaArchive />;
}
ENDOFFILE

echo "  ✓ Admin-Seite erstellt"

# ───────────────────────────────────────
echo "[3/5] MediaArchive-Komponente (4 Tabs)..."
# ───────────────────────────────────────

cat > src/components/admin/media-archive.tsx << 'ENDOFFILE'
'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';

// ═══ Types ═══
interface MediaItem {
  id: string;
  filename: string;
  originalName: string | null;
  title: string;
  url: string;
  thumbnailUrl: string | null;
  formats: any;
  width: number | null;
  height: number | null;
  sizeBytes: number | null;
  category: string;
  source: string;
  createdAt: string;
  productCount: number;
  products: Array<{ id: string; name: string; mediaType: string }>;
}

interface UploadItem {
  file: File;
  status: 'pending' | 'uploading' | 'done' | 'error';
  progress: number;
  error?: string;
  mediaId?: string;
}

// ═══ MediaGrid ═══
function MediaGrid({ category }: { category: 'PHOTO' | 'LOGO' }) {
  const router = useRouter();
  const [media, setMedia] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [orientFilter, setOrientFilter] = useState('');
  const [assignFilter, setAssignFilter] = useState('');
  const [sortBy, setSortBy] = useState('newest');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);

  const fetchMedia = useCallback(async () => {
    setLoading(true);
    const params = new URLSearchParams();
    params.set('category', category);
    params.set('page', String(page));
    params.set('limit', '24');
    params.set('sort', sortBy);
    if (search) params.set('q', search);
    if (typeFilter) params.set('type', typeFilter);
    if (orientFilter) params.set('orientation', orientFilter);
    if (assignFilter) params.set('assigned', assignFilter);

    try {
      const res = await fetch(`/api/v1/media?${params}`);
      const data = await res.json();
      setMedia(data.media || []);
      setTotalPages(data.totalPages || 1);
      setTotal(data.total || 0);
    } catch (e) {
      console.error('Fetch media error:', e);
    }
    setLoading(false);
  }, [category, page, sortBy, search, typeFilter, orientFilter, assignFilter]);

  useEffect(() => { fetchMedia(); }, [fetchMedia]);
  useEffect(() => { setPage(1); }, [search, typeFilter, orientFilter, assignFilter, sortBy]);

  const typeOptions = category === 'PHOTO'
    ? [
        { value: '', label: 'Alle Typen' },
        { value: 'BOTTLE', label: 'Flasche' },
        { value: 'LABEL', label: 'Etikett' },
        { value: 'SERVING', label: 'Servierung' },
        { value: 'AMBIANCE', label: 'Stimmung' },
        { value: 'OTHER', label: 'Sonstige' },
      ]
    : [
        { value: '', label: 'Alle Logos' },
        { value: 'LOGO', label: 'Logo' },
      ];

  function formatSize(bytes: number | null) {
    if (!bytes) return '';
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(0) + ' KB';
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
  }

  return (
    <div>
      {/* Filter-Leiste */}
      <div className="mb-4 flex flex-wrap gap-3 items-center">
        <div className="flex-1 min-w-[200px]">
          <input
            type="text"
            placeholder="Nach Name filtern..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-amber-500"
          />
        </div>
        <select value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)}
          className="px-3 py-2 border rounded-lg text-sm bg-white">
          {typeOptions.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
        </select>
        <select value={orientFilter} onChange={(e) => setOrientFilter(e.target.value)}
          className="px-3 py-2 border rounded-lg text-sm bg-white">
          <option value="">Alle Formate</option>
          <option value="landscape">Quer</option>
          <option value="portrait">Hoch</option>
          <option value="square">Quadratisch</option>
        </select>
        <select value={assignFilter} onChange={(e) => setAssignFilter(e.target.value)}
          className="px-3 py-2 border rounded-lg text-sm bg-white">
          <option value="">Alle</option>
          <option value="true">Zugeordnet</option>
          <option value="false">Nicht zugeordnet</option>
        </select>
        <select value={sortBy} onChange={(e) => setSortBy(e.target.value)}
          className="px-3 py-2 border rounded-lg text-sm bg-white">
          <option value="newest">Neueste zuerst</option>
          <option value="oldest">Älteste zuerst</option>
          <option value="name">Name A-Z</option>
          <option value="size">Größe</option>
        </select>
      </div>

      <p className="text-sm text-gray-500 mb-3">
        {total} {category === 'PHOTO' ? 'Fotos' : 'Logos'}
      </p>

      {loading ? (
        <div className="text-center py-12 text-gray-400">Laden...</div>
      ) : media.length === 0 ? (
        <div className="text-center py-12 text-gray-400">
          {search ? 'Keine Treffer' : `Noch keine ${category === 'PHOTO' ? 'Fotos' : 'Logos'} vorhanden`}
        </div>
      ) : (
        <>
          {/* Grid */}
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
            {media.map((m) => (
              <div
                key={m.id}
                onClick={() => router.push(`/admin/media/${m.id}`)}
                className="group cursor-pointer border rounded-lg overflow-hidden hover:shadow-lg transition-shadow bg-white"
              >
                <div className="relative aspect-square bg-gray-100">
                  <img
                    src={m.thumbnailUrl || m.url}
                    alt={m.title}
                    className="w-full h-full object-cover"
                    loading="lazy"
                  />
                  {/* Dimensionen */}
                  {m.width && m.height && (
                    <span className="absolute top-1 left-1 bg-black/60 text-white text-[10px] px-1.5 py-0.5 rounded">
                      {m.width}×{m.height}
                    </span>
                  )}
                  {/* Quelle */}
                  {m.source !== 'UPLOAD' && (
                    <span className="absolute top-1 right-1 bg-blue-500 text-white text-[10px] px-1.5 py-0.5 rounded">
                      {m.source}
                    </span>
                  )}
                </div>
                <div className="p-2">
                  <p className="text-xs font-medium truncate" title={m.title}>{m.title}</p>
                  <div className="flex items-center justify-between mt-1">
                    {m.products.length > 0 && m.products[0]?.mediaType && (
                      <span className="text-[10px] bg-amber-100 text-amber-700 px-1.5 py-0.5 rounded">
                        {m.products[0].mediaType}
                      </span>
                    )}
                    <span className="text-[10px] text-gray-400">
                      {m.productCount > 0 ? `${m.productCount} Prod.` : 'nicht zugeordnet'}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex justify-center gap-2 mt-6">
              <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page <= 1}
                className="px-3 py-1 text-sm border rounded disabled:opacity-30">
                Zurück
              </button>
              <span className="px-3 py-1 text-sm text-gray-600">
                Seite {page} / {totalPages}
              </span>
              <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page >= totalPages}
                className="px-3 py-1 text-sm border rounded disabled:opacity-30">
                Weiter
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}

// ═══ UploadTab ═══
function UploadTab({ onUploaded }: { onUploaded: () => void }) {
  const [files, setFiles] = useState<UploadItem[]>([]);
  const [category, setCategory] = useState<'PHOTO' | 'LOGO'>('PHOTO');
  const [isDragOver, setIsDragOver] = useState(false);

  function addFiles(newFiles: FileList | File[]) {
    const items: UploadItem[] = Array.from(newFiles)
      .filter(f => f.type.startsWith('image/') && f.size <= 4 * 1024 * 1024)
      .map(f => ({ file: f, status: 'pending' as const, progress: 0 }));
    setFiles(prev => [...prev, ...items]);
  }

  async function uploadAll() {
    const pending = files.filter(f => f.status === 'pending');
    for (let i = 0; i < pending.length; i++) {
      const item = pending[i];
      setFiles(prev => prev.map(f =>
        f.file === item.file ? { ...f, status: 'uploading' } : f
      ));

      try {
        const formData = new FormData();
        formData.append('file', item.file);
        formData.append('category', category);
        formData.append('title', item.file.name.replace(/\.[^.]+$/, ''));

        const res = await fetch('/api/v1/media/upload', { method: 'POST', body: formData });
        if (!res.ok) throw new Error(await res.text());
        const data = await res.json();

        setFiles(prev => prev.map(f =>
          f.file === item.file ? { ...f, status: 'done', progress: 100, mediaId: data.mediaId } : f
        ));
      } catch (e: any) {
        setFiles(prev => prev.map(f =>
          f.file === item.file ? { ...f, status: 'error', error: e.message } : f
        ));
      }
    }
    onUploaded();
  }

  const pendingCount = files.filter(f => f.status === 'pending').length;
  const doneCount = files.filter(f => f.status === 'done').length;

  return (
    <div>
      {/* Drop-Zone */}
      <div
        onDragOver={(e) => { e.preventDefault(); setIsDragOver(true); }}
        onDragLeave={() => setIsDragOver(false)}
        onDrop={(e) => { e.preventDefault(); setIsDragOver(false); addFiles(e.dataTransfer.files); }}
        onClick={() => {
          const input = document.createElement('input');
          input.type = 'file';
          input.multiple = true;
          input.accept = 'image/jpeg,image/png,image/webp';
          input.onchange = () => { if (input.files) addFiles(input.files); };
          input.click();
        }}
        className={`border-2 border-dashed rounded-xl p-12 text-center cursor-pointer transition-colors ${
          isDragOver ? 'border-amber-500 bg-amber-50' : 'border-gray-300 hover:border-amber-400 hover:bg-amber-50/50'
        }`}
      >
        <div className="text-4xl mb-3">📸</div>
        <p className="text-gray-600 font-medium">Bilder hierher ziehen</p>
        <p className="text-gray-400 text-sm mt-1">oder klicken zum Auswählen</p>
        <p className="text-gray-400 text-xs mt-2">JPEG, PNG, WebP · Max 4MB pro Bild · Mehrere Dateien</p>
      </div>

      {/* Kategorie */}
      <div className="mt-4 flex items-center gap-3">
        <span className="text-sm text-gray-600">Kategorie:</span>
        <select value={category} onChange={(e) => setCategory(e.target.value as any)}
          className="px-3 py-1.5 border rounded text-sm bg-white">
          <option value="PHOTO">Foto</option>
          <option value="LOGO">Logo</option>
        </select>
      </div>

      {/* Dateiliste */}
      {files.length > 0 && (
        <div className="mt-4 space-y-2">
          {files.map((item, i) => (
            <div key={i} className="flex items-center gap-3 p-2 bg-gray-50 rounded-lg">
              <span className="text-lg">
                {item.status === 'done' ? '✅' : item.status === 'error' ? '❌' : item.status === 'uploading' ? '⏳' : '📄'}
              </span>
              <span className="flex-1 text-sm truncate">{item.file.name}</span>
              <span className="text-xs text-gray-400">{(item.file.size / 1024).toFixed(0)} KB</span>
              {item.error && <span className="text-xs text-red-500">{item.error}</span>}
            </div>
          ))}

          <div className="flex items-center justify-between mt-3">
            <span className="text-sm text-gray-500">
              {doneCount > 0 && `${doneCount} hochgeladen`}
              {pendingCount > 0 && ` · ${pendingCount} wartend`}
            </span>
            {pendingCount > 0 && (
              <button onClick={uploadAll}
                className="px-4 py-2 bg-amber-600 text-white rounded-lg text-sm font-medium hover:bg-amber-700">
                {pendingCount} {pendingCount === 1 ? 'Bild' : 'Bilder'} hochladen
              </button>
            )}
            {pendingCount === 0 && files.length > 0 && (
              <button onClick={() => setFiles([])}
                className="px-4 py-2 border rounded-lg text-sm hover:bg-gray-50">
                Liste leeren
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// ═══ WebSearchTab (Platzhalter für Phase 3) ═══
function WebSearchTab() {
  return (
    <div className="text-center py-12 text-gray-400">
      <div className="text-4xl mb-3">🌐</div>
      <p className="font-medium text-gray-500">Websuche (Pixabay / Pexels)</p>
      <p className="text-sm mt-2">Wird in Phase 3 aktiviert.</p>
      <p className="text-xs mt-1 text-gray-400">Bitte API-Keys in .env eintragen:</p>
      <code className="text-xs text-gray-400 block mt-1">PIXABAY_API_KEY=xxx</code>
      <code className="text-xs text-gray-400 block">PEXELS_API_KEY=xxx</code>
    </div>
  );
}

// ═══ Hauptkomponente ═══
export default function MediaArchive() {
  const [activeTab, setActiveTab] = useState<'photos' | 'logos' | 'upload' | 'web'>('photos');
  const [refreshKey, setRefreshKey] = useState(0);

  const tabs = [
    { id: 'photos' as const, icon: '📷', label: 'Fotos' },
    { id: 'logos' as const, icon: '🏷️', label: 'Logos' },
    { id: 'upload' as const, icon: '📤', label: 'Hochladen' },
    { id: 'web' as const, icon: '🌐', label: 'Websuche' },
  ];

  return (
    <div className="p-6 max-w-[1400px] mx-auto">
      <h1 className="text-2xl font-bold text-gray-800 mb-6">Bildarchiv</h1>

      {/* Tabs */}
      <div className="flex border-b mb-6">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`px-5 py-3 text-sm font-medium border-b-2 transition-colors ${
              activeTab === tab.id
                ? 'border-amber-600 text-amber-700'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            {tab.icon} {tab.label}
          </button>
        ))}
      </div>

      {/* Tab-Inhalt */}
      {activeTab === 'photos' && <MediaGrid key={`photos-${refreshKey}`} category="PHOTO" />}
      {activeTab === 'logos' && <MediaGrid key={`logos-${refreshKey}`} category="LOGO" />}
      {activeTab === 'upload' && <UploadTab onUploaded={() => setRefreshKey(k => k + 1)} />}
      {activeTab === 'web' && <WebSearchTab />}
    </div>
  );
}
ENDOFFILE

echo "  ✓ MediaArchive-Komponente erstellt (4 Tabs)"

# ───────────────────────────────────────
echo "[4/5] Bild-Detailansicht..."
# ───────────────────────────────────────

cat > src/app/admin/media/\[id\]/page.tsx << 'ENDOFFILE'
import MediaDetail from '@/components/admin/media-detail';

export default function MediaDetailPage({ params }: { params: { id: string } }) {
  return <MediaDetail mediaId={params.id} />;
}
ENDOFFILE

cat > src/components/admin/media-detail.tsx << 'ENDOFFILE'
'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

interface MediaData {
  id: string;
  filename: string;
  originalName: string | null;
  title: string | null;
  alt: string | null;
  url: string;
  thumbnailUrl: string | null;
  formats: any;
  width: number | null;
  height: number | null;
  sizeBytes: number | null;
  category: string;
  source: string;
  sourceUrl: string | null;
  sourceAuthor: string | null;
  createdAt: string;
  productMedia: Array<{
    id: string;
    mediaType: string;
    product: { id: string; translations: Array<{ name: string }> };
  }>;
}

export default function MediaDetail({ mediaId }: { mediaId: string }) {
  const router = useRouter();
  const [media, setMedia] = useState<MediaData | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [title, setTitle] = useState('');
  const [alt, setAlt] = useState('');
  const [category, setCategory] = useState('PHOTO');
  const [showDelete, setShowDelete] = useState(false);

  useEffect(() => {
    fetch(`/api/v1/media/${mediaId}`)
      .then(r => r.json())
      .then(data => {
        setMedia(data);
        setTitle(data.title || '');
        setAlt(data.alt || '');
        setCategory(data.category || 'PHOTO');
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, [mediaId]);

  async function save() {
    setSaving(true);
    try {
      await fetch(`/api/v1/media/${mediaId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title, alt, category }),
      });
    } catch (e) {
      console.error(e);
    }
    setSaving(false);
  }

  async function deleteMedia(force: boolean) {
    const url = `/api/v1/media/${mediaId}${force ? '?force=true' : ''}`;
    const res = await fetch(url, { method: 'DELETE' });
    if (res.ok) {
      router.push('/admin/media');
    } else {
      const data = await res.json();
      if (data.productCount) {
        if (confirm(`Bild ist ${data.productCount} Produkten zugeordnet. Trotzdem löschen?`)) {
          deleteMedia(true);
        }
      }
    }
  }

  function formatSize(bytes: number | null) {
    if (!bytes) return '-';
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(0) + ' KB';
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
  }

  function formatDate(d: string) {
    return new Date(d).toLocaleDateString('de-AT', { day: '2-digit', month: '2-digit', year: 'numeric' });
  }

  if (loading) return <div className="p-6 text-center text-gray-400">Laden...</div>;
  if (!media) return <div className="p-6 text-center text-red-500">Bild nicht gefunden</div>;

  const formats = media.formats as Record<string, any> || {};
  const formatKeys = ['original', '16:9', '4:3', '1:1', '3:4', 'thumb'].filter(k => formats[k]);

  return (
    <div className="p-6 max-w-[1200px] mx-auto">
      {/* Header */}
      <button onClick={() => router.push('/admin/media')} className="text-sm text-amber-600 hover:underline mb-4 block">
        ← Zurück zum Archiv
      </button>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Linke Seite: Vorschau */}
        <div>
          <div className="bg-gray-100 rounded-xl overflow-hidden">
            <img
              src={formats.original?.url || media.url}
              alt={media.alt || media.title || ''}
              className="w-full h-auto max-h-[500px] object-contain"
            />
          </div>

          {/* Formate */}
          <h3 className="text-sm font-semibold text-gray-700 mt-6 mb-3">Formate</h3>
          <div className="grid grid-cols-3 sm:grid-cols-5 gap-3">
            {formatKeys.map(key => (
              <div key={key} className="group relative">
                <div className="aspect-square bg-gray-100 rounded-lg overflow-hidden border">
                  <img
                    src={formats[key]?.url}
                    alt={key}
                    className="w-full h-full object-cover"
                    loading="lazy"
                  />
                </div>
                <p className="text-[10px] text-center text-gray-500 mt-1">
                  {key === 'original' ? 'Original' : key}
                </p>
                <p className="text-[10px] text-center text-gray-400">
                  {formats[key]?.width}×{formats[key]?.height}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Rechte Seite: Metadaten */}
        <div className="space-y-4">
          <div>
            <label className="text-sm font-medium text-gray-700 block mb-1">Titel</label>
            <input
              type="text" value={title} onChange={(e) => setTitle(e.target.value)}
              className="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-amber-500"
            />
          </div>
          <div>
            <label className="text-sm font-medium text-gray-700 block mb-1">Alt-Text</label>
            <input
              type="text" value={alt} onChange={(e) => setAlt(e.target.value)}
              className="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-amber-500"
            />
          </div>
          <div>
            <label className="text-sm font-medium text-gray-700 block mb-1">Kategorie</label>
            <select value={category} onChange={(e) => setCategory(e.target.value)}
              className="w-full px-3 py-2 border rounded-lg text-sm bg-white">
              <option value="PHOTO">Foto</option>
              <option value="LOGO">Logo</option>
              <option value="DOCUMENT">Dokument</option>
            </select>
          </div>

          {/* Info */}
          <div className="bg-gray-50 rounded-lg p-4 space-y-2 text-sm">
            <div className="flex justify-between"><span className="text-gray-500">Quelle</span><span>{media.source}</span></div>
            {media.sourceAuthor && (
              <div className="flex justify-between"><span className="text-gray-500">Fotograf</span><span>{media.sourceAuthor}</span></div>
            )}
            <div className="flex justify-between"><span className="text-gray-500">Hochgeladen</span><span>{formatDate(media.createdAt)}</span></div>
            <div className="flex justify-between"><span className="text-gray-500">Größe</span><span>{formatSize(media.sizeBytes)}</span></div>
            <div className="flex justify-between"><span className="text-gray-500">Dimensionen</span><span>{media.width}×{media.height}</span></div>
            <div className="flex justify-between"><span className="text-gray-500">Datei</span><span className="truncate max-w-[200px]">{media.originalName || media.filename}</span></div>
          </div>

          {/* Zugeordnete Produkte */}
          <div>
            <h3 className="text-sm font-semibold text-gray-700 mb-2">
              Zugeordnet zu ({media.productMedia.length})
            </h3>
            {media.productMedia.length === 0 ? (
              <p className="text-sm text-gray-400">Keinem Produkt zugeordnet</p>
            ) : (
              <div className="space-y-1">
                {media.productMedia.map(pm => (
                  <div key={pm.id} className="flex items-center gap-2 text-sm p-2 bg-gray-50 rounded">
                    <span className="text-[10px] bg-amber-100 text-amber-700 px-1.5 py-0.5 rounded">{pm.mediaType}</span>
                    <span>{pm.product.translations[0]?.name || 'Unbenannt'}</span>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Actions */}
          <div className="flex gap-3 pt-4 border-t">
            <button onClick={save} disabled={saving}
              className="px-5 py-2 bg-amber-600 text-white rounded-lg text-sm font-medium hover:bg-amber-700 disabled:opacity-50">
              {saving ? 'Speichere...' : '💾 Speichern'}
            </button>
            <button onClick={() => deleteMedia(false)}
              className="px-5 py-2 border border-red-300 text-red-600 rounded-lg text-sm hover:bg-red-50">
              🗑️ Bild löschen
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
ENDOFFILE

echo "  ✓ Bild-Detailansicht erstellt"

# ───────────────────────────────────────
echo ""
echo "[BUILD] Kompiliere..."
# ───────────────────────────────────────

npm run build 2>&1 | tail -15

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo ""
  echo "═══════════════════════════════════"
  echo "  ✅ Bildarchiv Phase 2 LIVE!"
  echo "═══════════════════════════════════"
  echo ""
  echo "  Neuer Menüpunkt: 🖼️ Bildarchiv"
  echo "  → /admin/media (4 Tabs)"
  echo "  → /admin/media/[id] (Detailansicht)"
  echo ""
else
  echo ""
  echo "  ❌ Build fehlgeschlagen – siehe Fehler oben"
fi
