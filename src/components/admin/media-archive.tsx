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
          <option value="oldest">Aelteste zuerst</option>
          <option value="name">Name A-Z</option>
          <option value="size">Groesse</option>
        </select>
      </div>

      <p className="text-sm text-[#565D6D] mb-3">
        {total} {category === 'PHOTO' ? 'Fotos' : 'Logos'}
      </p>

      {loading ? (
        <div className="text-center py-12 text-[#999]">Laden...</div>
      ) : media.length === 0 ? (
        <div className="text-center py-12 text-[#999]">
          {search ? 'Keine Treffer' : ('Noch keine ' + (category === 'PHOTO' ? 'Fotos' : 'Logos') + ' vorhanden')}
        </div>
      ) : (
        <>
          {/* Grid */}
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
            {media.map((m) => (
              <div
                key={m.id}
                onClick={() => router.push('/admin/media/' + m.id)}
                className="group cursor-pointer border rounded-lg overflow-hidden hover:shadow-lg transition-shadow bg-white"
              >
                <div className="relative aspect-square bg-gray-100">
                  <img
                    src={m.thumbnailUrl || m.url}
                    alt={m.title}
                    className="w-full h-full object-cover"
                    loading="lazy"
                  />
                  {m.width && m.height && (
                    <span className="absolute top-1 left-1 bg-black/60 text-white text-[10px] px-1.5 py-0.5 rounded">
                      {m.width}&times;{m.height}
                    </span>
                  )}
                  {m.source !== 'UPLOAD' && (
                    <span className="absolute top-1 right-1 bg-[#DD3C71] text-white text-[10px] px-1.5 py-0.5 rounded">
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
                    <span className="text-[10px] text-[#999]">
                      {m.productCount > 0 ? (m.productCount + ' Prod.') : 'nicht zugeordnet'}
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
                Zurueck
              </button>
              <span className="px-3 py-1 text-sm text-[#565D6D]">
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
        className={'border-2 border-dashed rounded-xl p-12 text-center cursor-pointer transition-colors ' +
          (isDragOver ? 'border-amber-500 bg-amber-50' : 'border-[#DEE1E6] hover:border-amber-400 hover:bg-amber-50/50')
        }
      >
        <div className="text-4xl mb-3">&#x1F4F8;</div>
        <p className="text-[#565D6D] font-medium">Bilder hierher ziehen</p>
        <p className="text-[#999] text-sm mt-1">oder klicken zum Auswaehlen</p>
        <p className="text-[#999] text-xs mt-2">JPEG, PNG, WebP - Max 4MB pro Bild</p>
      </div>

      {/* Kategorie */}
      <div className="mt-4 flex items-center gap-3">
        <span className="text-sm text-[#565D6D]">Kategorie:</span>
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
            <div key={i} className="flex items-center gap-3 p-2 bg-[#F9FAFB] rounded-lg">
              <span className="text-lg">
                {item.status === 'done' ? '\u2705' : item.status === 'error' ? '\u274C' : item.status === 'uploading' ? '\u23F3' : '\uD83D\uDCC4'}
              </span>
              <span className="flex-1 text-sm truncate">{item.file.name}</span>
              <span className="text-xs text-[#999]">{(item.file.size / 1024).toFixed(0)} KB</span>
              {item.error && <span className="text-xs text-red-500">{item.error}</span>}
            </div>
          ))}

          <div className="flex items-center justify-between mt-3">
            <span className="text-sm text-[#565D6D]">
              {doneCount > 0 && (doneCount + ' hochgeladen')}
              {pendingCount > 0 && (' - ' + pendingCount + ' wartend')}
            </span>
            {pendingCount > 0 && (
              <button onClick={uploadAll}
                className="px-4 py-2 bg-amber-600 text-white rounded-lg text-sm font-medium hover:bg-amber-700">
                {pendingCount} {pendingCount === 1 ? 'Bild' : 'Bilder'} hochladen
              </button>
            )}
            {pendingCount === 0 && files.length > 0 && (
              <button onClick={() => setFiles([])}
                className="px-4 py-2 border rounded-lg text-sm hover:bg-[#F9FAFB]">
                Liste leeren
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// ═══ WebSearchTab ═══
function WebSearchTab({ onImported }: { onImported: () => void }) {
  const [query, setQuery] = useState('');
  const [source, setSource] = useState<string>('searxng');
  const [results, setResults] = useState<any[]>([]);
  const [selected, setSelected] = useState<Set<number>>(new Set());
  const [loading, setLoading] = useState(false);
  const [importing, setImporting] = useState(false);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [searched, setSearched] = useState(false);
  const [searchError, setSearchError] = useState('');
  const [availableSources, setAvailableSources] = useState<any[]>([]);

  useEffect(() => {
    fetch('/api/v1/media/web-search')
      .then(r => r.json())
      .then(data => { if (data.sources) setAvailableSources(data.sources); })
      .catch(() => {});
  }, []);

  async function doSearch(p = 1) {
    if (!query.trim()) return;
    setLoading(true);
    setSearchError('');
    setPage(p);
    try {
      const res = await fetch('/api/v1/media/web-search', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query, source, page: p }),
      });
      const data = await res.json();
      setResults(data.results || []);
      setTotal(data.total || 0);
      setSelected(new Set());
      setSearched(true);
      if (data.error) setSearchError(data.error);
    } catch (e) {
      setSearchError('Suche fehlgeschlagen');
    }
    setLoading(false);
  }

  function toggleSelect(idx: number) {
    setSelected(prev => {
      const s = new Set(prev);
      if (s.has(idx)) s.delete(idx); else s.add(idx);
      return s;
    });
  }

  async function importSelected() {
    setImporting(true);
    const items = Array.from(selected).map(i => results[i]).filter(Boolean);
    let ok = 0;
    for (const item of items) {
      try {
        const res = await fetch('/api/v1/media/web-import', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            url: item.fullUrl,
            source: source.toUpperCase(),
            sourceAuthor: item.author,
            sourceUrl: item.sourceUrl,
            category: 'PHOTO',
          }),
        });
        if (res.ok) ok++;
      } catch (e) { console.error(e); }
    }
    setImporting(false);
    setSelected(new Set());
    if (ok > 0) onImported();
    alert(ok + ' Bild' + (ok > 1 ? 'er' : '') + ' importiert!');
  }

  const selectedCount = selected.size;

  return (
    <div>
      <div className="flex gap-3 mb-4">
        <input type="text" placeholder="z.B. wine bottle, hotel restaurant..."
          value={query} onChange={(e) => setQuery(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && doSearch(1)}
          className="flex-1 px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-amber-500" />
        <button onClick={() => doSearch(1)} disabled={loading || !query.trim()}
          className="px-5 py-2 bg-amber-600 text-white rounded-lg text-sm font-medium hover:bg-amber-700 disabled:opacity-50">
          {loading ? '...' : 'Suchen'}
        </button>
      </div>
      <div className="flex flex-wrap gap-2 mb-6">
        {[
          { id: 'searxng', label: 'Websuche (Google, Bing, DDG)', free: true, available: true },
          { id: 'wikimedia', label: 'Wikimedia Commons', free: true, available: true },
          ...availableSources.filter((s: any) => s.id !== 'wikimedia' && s.id !== 'searxng' && s.id !== 'google'),
        ].map((s: any) => (
          <button key={s.id || s.label} type="button"
            onClick={() => setSource(s.id)}
            className={'px-4 py-2.5 rounded-lg text-sm font-medium border-2 transition-all ' +
              (source === s.id
                ? 'border-amber-500 bg-amber-50 text-amber-700'
                : s.available || s.free
                  ? 'border-[#E5E7EB] bg-white text-[#565D6D] hover:border-amber-300 hover:bg-amber-50/50'
                  : 'border-gray-100 bg-[#F9FAFB] text-[#999] hover:border-amber-200 hover:bg-amber-50/30 cursor-pointer')
            }>
            {s.label || s.name}
            {(s.free) && <span className="ml-1.5 text-xs text-green-600">(frei)</span>}
            {(!s.available && !s.free) && <span className="ml-1.5 text-xs text-[#999]">(Key fehlt)</span>}
          </button>
        ))}
      </div>
      {searchError && <div className="mb-4 p-3 bg-yellow-50 border border-yellow-200 rounded-lg text-sm text-yellow-700">{searchError}</div>}
      {loading ? (
        <div className="text-center py-12 text-[#999]">Suche ...</div>
      ) : results.length === 0 && searched ? (
        <div className="text-center py-12 text-[#999]">
          <p>Keine Ergebnisse</p>
          <p className="text-xs mt-1">Tipp: Englische Suchbegriffe liefern mehr Ergebnisse</p>
        </div>
      ) : results.length > 0 ? (
        <>
          <p className="text-sm text-[#565D6D] mb-3">{total} Ergebnisse - Seite {page}</p>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
            {results.map((r, idx) => (
              <div key={r.id} onClick={() => toggleSelect(idx)}
                className={'cursor-pointer border-2 rounded-lg overflow-hidden transition-all ' +
                  (selected.has(idx) ? 'border-amber-500 ring-2 ring-amber-200' : 'border-transparent hover:border-[#DEE1E6]')}>
                <div className="relative aspect-square bg-gray-100">
                  <img src={r.previewUrl} alt={r.tags} className="w-full h-full object-cover" loading="lazy" />
                  {selected.has(idx) && <div className="absolute top-2 right-2 w-6 h-6 bg-amber-500 rounded-full flex items-center justify-center text-white text-xs">+</div>}
                </div>
                <div className="p-1.5">
                  <p className="text-[10px] text-[#565D6D] truncate">{r.author}</p>
                  <p className="text-[10px] text-[#999]">{r.width}x{r.height}</p>
                </div>
              </div>
            ))}
          </div>
          <div className="flex items-center justify-between mt-6">
            <div className="flex gap-2">
              {page > 1 && <button onClick={() => doSearch(page - 1)} className="px-3 py-1 text-sm border rounded">Zurueck</button>}
              <button onClick={() => doSearch(page + 1)} className="px-3 py-1 text-sm border rounded">Weitere</button>
            </div>
            {selectedCount > 0 && (
              <button onClick={importSelected} disabled={importing}
                className="px-5 py-2 bg-amber-600 text-white rounded-lg text-sm font-medium hover:bg-amber-700 disabled:opacity-50">
                {importing ? 'Importiere...' : selectedCount + ' uebernehmen'}
              </button>
            )}
          </div>
        </>
      ) : null}
    </div>
  );
}


// ═══ Hauptkomponente ═══
export default function MediaArchive() {
  const [activeTab, setActiveTab] = useState<'photos' | 'logos' | 'upload' | 'web'>('photos');
  const [refreshKey, setRefreshKey] = useState(0);

  const tabs = [
    { id: 'photos' as const, icon: '\uD83D\uDCF7', label: 'Fotos' },
    { id: 'logos' as const, icon: '\uD83C\uDFF7\uFE0F', label: 'Logos' },
    { id: 'upload' as const, icon: '\uD83D\uDCE4', label: 'Hochladen' },
    { id: 'web' as const, icon: '\uD83C\uDF10', label: 'Websuche' },
  ];

  return (
    <div className="p-6 max-w-[1400px] mx-auto">
      <h1 className="text-2xl font-bold text-[#171A1F] mb-6">Bildarchiv</h1>

      {/* Tabs */}
      <div className="flex border-b mb-6">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={'px-5 py-3 text-sm font-medium border-b-2 transition-colors ' +
              (activeTab === tab.id
                ? 'border-amber-600 text-amber-700'
                : 'border-transparent text-[#565D6D] hover:text-[#171A1F] hover:border-[#DEE1E6]')
            }
          >
            {tab.icon} {tab.label}
          </button>
        ))}
      </div>

      {/* Tab-Inhalt */}
      {activeTab === 'photos' && <MediaGrid key={'photos-' + refreshKey} category="PHOTO" />}
      {activeTab === 'logos' && <MediaGrid key={'logos-' + refreshKey} category="LOGO" />}
      {activeTab === 'upload' && <UploadTab onUploaded={() => setRefreshKey(k => k + 1)} />}
      {activeTab === 'web' && <WebSearchTab onImported={() => setRefreshKey(k => k + 1)} />}
    </div>
  );
}
