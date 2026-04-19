'use client';

import { useState, useEffect, useCallback } from 'react';

interface MediaItem {
  id: string;
  title: string;
  url: string;
  thumbnailUrl: string | null;
  formats: any;
  width: number | null;
  height: number | null;
  category: string;
  source: string;
  productCount: number;
}

interface MediaPickerModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSelect: (media: MediaItem) => void;
  categoryFilter?: 'PHOTO' | 'LOGO';
  title?: string;
}

export default function MediaPickerModal({
  isOpen,
  onClose,
  onSelect,
  categoryFilter,
  title = 'Aus Bildarchiv wählen',
}: MediaPickerModalProps) {
  const [activeTab, setActiveTab] = useState<'browse' | 'upload' | 'web'>('browse');
  const [media, setMedia] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState(categoryFilter || '');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  // Upload State
  const [uploadFiles, setUploadFiles] = useState<File[]>([]);
  const [uploadingIdx, setUploadingIdx] = useState(-1);
  const [uploadDone, setUploadDone] = useState<string[]>([]);

  // Web-Search State
  const [webQuery, setWebQuery] = useState('');
  const [webSource, setWebSource] = useState('searxng');
  const [webResults, setWebResults] = useState<any[]>([]);
  const [webLoading, setWebLoading] = useState(false);
  const [webImporting, setWebImporting] = useState(false);
  const [availableSources, setAvailableSources] = useState<any[]>([]);

  const fetchMedia = useCallback(async () => {
    setLoading(true);
    const params = new URLSearchParams();
    params.set('page', String(page));
    params.set('limit', '24');
    params.set('sort', 'newest');
    if (category) params.set('category', category);
    if (search) params.set('q', search);
    try {
      const res = await fetch('/api/v1/media?' + params);
      const data = await res.json();
      setMedia(data.media || []);
      setTotalPages(data.totalPages || 1);
    } catch (e) { console.error(e); }
    setLoading(false);
  }, [page, search, category]);

  useEffect(() => { if (isOpen) fetchMedia(); }, [isOpen, fetchMedia]);
  useEffect(() => { setPage(1); }, [search, category]);
  useEffect(() => {
    if (isOpen) {
      fetch('/api/v1/media/web-search')
        .then(r => r.json())
        .then(data => { if (data.sources) setAvailableSources(data.sources); })
        .catch(() => {});
    }
  }, [isOpen]);

  // Upload
  async function uploadAll() {
    for (let i = 0; i < uploadFiles.length; i++) {
      setUploadingIdx(i);
      try {
        const fd = new FormData();
        fd.append('file', uploadFiles[i]);
        fd.append('category', categoryFilter || 'PHOTO');
        fd.append('title', uploadFiles[i].name.replace(/\.[^.]+$/, ''));
        const res = await fetch('/api/v1/media/upload', { method: 'POST', body: fd });
        if (res.ok) {
          const data = await res.json();
          setUploadDone(prev => [...prev, data.mediaId]);
        }
      } catch (e) { console.error(e); }
    }
    setUploadingIdx(-1);
    setUploadFiles([]);
    setUploadDone([]);
    fetchMedia();
    setActiveTab('browse');
  }

  // Web Search
  async function webSearch() {
    if (!webQuery.trim()) return;
    setWebLoading(true);
    try {
      const res = await fetch('/api/v1/media/web-search', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query: webQuery, source: webSource, page: 1 }),
      });
      const data = await res.json();
      setWebResults(data.results || []);
    } catch (e) { console.error(e); }
    setWebLoading(false);
  }

  async function webImport(item: any) {
    setWebImporting(true);
    try {
      const res = await fetch('/api/v1/media/web-import', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          url: item.fullUrl,
          source: webSource.toUpperCase(),
          sourceAuthor: item.author,
          sourceUrl: item.sourceUrl,
          category: categoryFilter || 'PHOTO',
        }),
      });
      if (res.ok) {
        fetchMedia();
        setActiveTab('browse');
      }
    } catch (e) { console.error(e); }
    setWebImporting(false);
  }

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onClick={onClose}>
      <div className="bg-white rounded-xl shadow-2xl w-[90vw] max-w-[900px] max-h-[85vh] flex flex-col"
        onClick={(e) => e.stopPropagation()}>

        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b">
          <h2 className="text-lg font-semibold text-[#171A1F]">{title}</h2>
          <button onClick={onClose} className="text-[#999] hover:text-[#565D6D] text-xl">&times;</button>
        </div>

        {/* Tabs */}
        <div className="flex border-b px-4">
          {[
            { id: 'browse' as const, label: 'Durchsuchen' },
            { id: 'upload' as const, label: 'Hochladen' },
            { id: 'web' as const, label: 'Websuche' },
          ].map(tab => (
            <button key={tab.id} onClick={() => setActiveTab(tab.id)}
              className={'px-4 py-2.5 text-sm font-medium border-b-2 ' +
                (activeTab === tab.id ? 'border-amber-600 text-amber-700' : 'border-transparent text-[#565D6D] hover:text-[#171A1F]')
              }>
              {tab.label}
            </button>
          ))}
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-4">

          {/* Browse Tab */}
          {activeTab === 'browse' && (
            <>
              <div className="flex gap-2 mb-4">
                <input type="text" placeholder="Suchen..." value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="flex-1 px-3 py-1.5 border rounded text-sm focus:outline-none focus:ring-2 focus:ring-amber-500" />
                {!categoryFilter && (
                  <select value={category} onChange={(e) => setCategory(e.target.value)}
                    className="px-3 py-1.5 border rounded text-sm bg-white">
                    <option value="">Alle</option>
                    <option value="PHOTO">Fotos</option>
                    <option value="LOGO">Logos</option>
                  </select>
                )}
              </div>
              {loading ? (
                <div className="text-center py-8 text-[#999]">Laden...</div>
              ) : media.length === 0 ? (
                <div className="text-center py-8 text-[#999]">Keine Bilder gefunden</div>
              ) : (
                <>
                  <div className="grid grid-cols-4 sm:grid-cols-5 md:grid-cols-6 gap-3">
                    {media.map(m => (
                      <div key={m.id} onClick={() => { onSelect(m); onClose(); }}
                        className="cursor-pointer border-2 border-transparent rounded-lg overflow-hidden hover:border-amber-400 hover:shadow-md transition-all">
                        <div className="aspect-square bg-gray-100">
                          <img src={m.thumbnailUrl || m.url} alt={m.title}
                            className="w-full h-full object-cover" loading="lazy" />
                        </div>
                        <p className="text-[10px] p-1 truncate text-[#565D6D]">{m.title}</p>
                      </div>
                    ))}
                  </div>
                  {totalPages > 1 && (
                    <div className="flex justify-center gap-2 mt-4">
                      <button onClick={() => setPage(p => Math.max(1, p-1))} disabled={page <= 1}
                        className="px-2 py-1 text-xs border rounded disabled:opacity-30">Zurueck</button>
                      <span className="px-2 py-1 text-xs text-[#565D6D]">{page}/{totalPages}</span>
                      <button onClick={() => setPage(p => Math.min(totalPages, p+1))} disabled={page >= totalPages}
                        className="px-2 py-1 text-xs border rounded disabled:opacity-30">Weiter</button>
                    </div>
                  )}
                </>
              )}
            </>
          )}

          {/* Upload Tab */}
          {activeTab === 'upload' && (
            <div>
              <div
                onDragOver={(e) => e.preventDefault()}
                onDrop={(e) => {
                  e.preventDefault();
                  const newFiles = Array.from(e.dataTransfer.files).filter(f => f.type.startsWith('image/'));
                  setUploadFiles(prev => [...prev, ...newFiles]);
                }}
                onClick={() => {
                  const input = document.createElement('input');
                  input.type = 'file'; input.multiple = true; input.accept = 'image/*';
                  input.onchange = () => {
                    if (input.files) setUploadFiles(prev => [...prev, ...Array.from(input.files!)]);
                  };
                  input.click();
                }}
                className="border-2 border-dashed rounded-xl p-8 text-center cursor-pointer hover:border-amber-400 hover:bg-amber-50/50"
              >
                <p className="text-2xl mb-2">&#x1F4F8;</p>
                <p className="text-sm text-[#565D6D]">Bilder hier ablegen oder klicken</p>
              </div>
              {uploadFiles.length > 0 && (
                <div className="mt-3 space-y-1">
                  {uploadFiles.map((f, i) => (
                    <div key={i} className="flex items-center gap-2 p-1.5 bg-[#F9FAFB] rounded text-sm">
                      <span>{uploadDone.length > i ? '\u2705' : uploadingIdx === i ? '\u23F3' : '\uD83D\uDCC4'}</span>
                      <span className="flex-1 truncate">{f.name}</span>
                      <span className="text-xs text-[#999]">{(f.size / 1024).toFixed(0)} KB</span>
                    </div>
                  ))}
                  <button onClick={uploadAll} disabled={uploadingIdx >= 0}
                    className="mt-2 px-4 py-1.5 bg-amber-600 text-white rounded text-sm hover:bg-amber-700 disabled:opacity-50">
                    {uploadingIdx >= 0 ? 'Wird hochgeladen...' : uploadFiles.length + ' hochladen'}
                  </button>
                </div>
              )}
            </div>
          )}

          {/* Web Tab */}
          {activeTab === 'web' && (
            <div>
              <div className="flex gap-2 mb-3">
                <input type="text" placeholder="z.B. wine bottle, hotel..." value={webQuery}
                  onChange={(e) => setWebQuery(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && webSearch()}
                  className="flex-1 px-3 py-1.5 border rounded text-sm focus:outline-none focus:ring-2 focus:ring-amber-500" />
                <button onClick={webSearch} disabled={webLoading}
                  className="px-4 py-1.5 bg-amber-600 text-white rounded text-sm hover:bg-amber-700 disabled:opacity-50">
                  {webLoading ? '...' : 'Suchen'}
                </button>
              </div>
              <div className="flex flex-wrap gap-2 mb-4">
                {[
                  { id: 'searxng', label: 'Websuche (Google, Bing, DDG)', free: true, available: true },
                  { id: 'wikimedia', label: 'Wikimedia Commons', free: true, available: true },
                  ...availableSources.filter((s: any) => s.id !== 'wikimedia' && s.id !== 'searxng' && s.id !== 'google'),
                ].map((s: any) => (
                  <button key={s.id} type="button" onClick={() => setWebSource(s.id)}
                    className={'px-3 py-1.5 rounded-lg text-xs font-medium border-2 transition-all ' +
                      (webSource === s.id
                        ? 'border-amber-500 bg-amber-50 text-amber-700'
                        : s.available || s.free
                          ? 'border-[#E5E7EB] bg-white text-[#565D6D] hover:border-amber-300'
                          : 'border-gray-100 bg-[#F9FAFB] text-[#999]')
                    }>
                    {s.label || s.name}
                    {s.free && <span className="ml-1 text-green-600">(frei)</span>}
                    {!s.available && !s.free && <span className="ml-1 text-[#999]">(Key fehlt)</span>}
                  </button>
                ))}
              </div>
              {webLoading ? (
                <div className="text-center py-8 text-[#999]">Suche...</div>
              ) : webResults.length > 0 ? (
                <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 gap-3">
                  {webResults.map((r: any) => (
                    <div key={r.id} className="border rounded-lg overflow-hidden">
                      <div className="aspect-square bg-gray-100">
                        <img src={r.previewUrl} alt="" className="w-full h-full object-cover" loading="lazy" />
                      </div>
                      <div className="p-1.5">
                        <p className="text-[10px] text-[#565D6D] truncate">{r.author}</p>
                        <button onClick={() => webImport(r)} disabled={webImporting}
                          className="mt-1 w-full px-2 py-1 bg-amber-100 text-amber-700 rounded text-[10px] hover:bg-amber-200 disabled:opacity-50">
                          Importieren
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              ) : null}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
