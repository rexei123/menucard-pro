#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Bildarchiv Phase 4: Editor-Integration (sicher, keine Regex)
# ═══════════════════════════════════════════════════════════════
cd /var/www/menucard-pro

echo ""
echo "═══════════════════════════════════════════"
echo "  Bildarchiv Phase 4: Editor-Integration"
echo "═══════════════════════════════════════════"
echo ""

# Backups
cp src/components/admin/product-images.tsx src/components/admin/product-images.tsx.bak-phase4 2>/dev/null || true

# ───────────────────────────────────────
echo "[1/5] MediaPicker Modal..."
# ───────────────────────────────────────

cat > src/components/admin/media-picker-modal.tsx << 'ENDOFFILE'
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
  title = 'Aus Bildarchiv waehlen',
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
          <h2 className="text-lg font-semibold text-gray-800">{title}</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 text-xl">&times;</button>
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
                (activeTab === tab.id ? 'border-amber-600 text-amber-700' : 'border-transparent text-gray-500 hover:text-gray-700')
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
                <div className="text-center py-8 text-gray-400">Laden...</div>
              ) : media.length === 0 ? (
                <div className="text-center py-8 text-gray-400">Keine Bilder gefunden</div>
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
                        <p className="text-[10px] p-1 truncate text-gray-600">{m.title}</p>
                      </div>
                    ))}
                  </div>
                  {totalPages > 1 && (
                    <div className="flex justify-center gap-2 mt-4">
                      <button onClick={() => setPage(p => Math.max(1, p-1))} disabled={page <= 1}
                        className="px-2 py-1 text-xs border rounded disabled:opacity-30">Zurueck</button>
                      <span className="px-2 py-1 text-xs text-gray-500">{page}/{totalPages}</span>
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
                <p className="text-sm text-gray-600">Bilder hier ablegen oder klicken</p>
              </div>
              {uploadFiles.length > 0 && (
                <div className="mt-3 space-y-1">
                  {uploadFiles.map((f, i) => (
                    <div key={i} className="flex items-center gap-2 p-1.5 bg-gray-50 rounded text-sm">
                      <span>{uploadDone.length > i ? '\u2705' : uploadingIdx === i ? '\u23F3' : '\uD83D\uDCC4'}</span>
                      <span className="flex-1 truncate">{f.name}</span>
                      <span className="text-xs text-gray-400">{(f.size / 1024).toFixed(0)} KB</span>
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
                          ? 'border-gray-200 bg-white text-gray-600 hover:border-amber-300'
                          : 'border-gray-100 bg-gray-50 text-gray-400')
                    }>
                    {s.label || s.name}
                    {s.free && <span className="ml-1 text-green-600">(frei)</span>}
                    {!s.available && !s.free && <span className="ml-1 text-gray-400">(Key fehlt)</span>}
                  </button>
                ))}
              </div>
              {webLoading ? (
                <div className="text-center py-8 text-gray-400">Suche...</div>
              ) : webResults.length > 0 ? (
                <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 gap-3">
                  {webResults.map((r: any) => (
                    <div key={r.id} className="border rounded-lg overflow-hidden">
                      <div className="aspect-square bg-gray-100">
                        <img src={r.previewUrl} alt="" className="w-full h-full object-cover" loading="lazy" />
                      </div>
                      <div className="p-1.5">
                        <p className="text-[10px] text-gray-500 truncate">{r.author}</p>
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
ENDOFFILE

echo "  OK MediaPicker Modal (mit SearXNG)"

# ───────────────────────────────────────
echo "[2/5] ImagePickerButton..."
# ───────────────────────────────────────

cat > src/components/admin/image-picker-button.tsx << 'ENDOFFILE'
'use client';

import { useState } from 'react';
import MediaPickerModal from './media-picker-modal';

interface ImagePickerButtonProps {
  label: string;
  currentUrl?: string | null;
  onSelect: (mediaId: string, url: string) => void;
  onRemove?: () => void;
  categoryFilter?: 'PHOTO' | 'LOGO';
}

export default function ImagePickerButton({
  label,
  currentUrl,
  onSelect,
  onRemove,
  categoryFilter,
}: ImagePickerButtonProps) {
  const [showPicker, setShowPicker] = useState(false);

  return (
    <div>
      <label className="text-xs font-medium text-gray-600 block mb-1">{label}</label>
      <div className="flex items-center gap-2">
        {currentUrl ? (
          <div className="relative w-16 h-16 rounded border overflow-hidden bg-gray-100">
            <img src={currentUrl} alt="" className="w-full h-full object-cover" />
            {onRemove && (
              <button onClick={onRemove}
                className="absolute top-0 right-0 w-4 h-4 bg-red-500 text-white text-[10px] rounded-bl flex items-center justify-center">
                &times;
              </button>
            )}
          </div>
        ) : null}
        <button type="button" onClick={() => setShowPicker(true)}
          className="px-3 py-1.5 border border-dashed border-amber-300 rounded text-xs text-amber-700 hover:bg-amber-50">
          {currentUrl ? 'Aendern' : label + ' waehlen'}
        </button>
      </div>
      {showPicker && (
        <MediaPickerModal
          isOpen={showPicker}
          onClose={() => setShowPicker(false)}
          onSelect={(media) => {
            const formats = media.formats as any;
            const url = formats?.['1:1']?.url || media.thumbnailUrl || media.url;
            onSelect(media.id, url);
            setShowPicker(false);
          }}
          categoryFilter={categoryFilter}
          title={label + ' aus Bildarchiv waehlen'}
        />
      )}
    </div>
  );
}
ENDOFFILE

echo "  OK ImagePickerButton"

# ───────────────────────────────────────
echo "[3/5] product-images.tsx (komplett neu)..."
# ───────────────────────────────────────

cat > src/components/admin/product-images.tsx << 'ENDOFFILE'
'use client';

import { useState, useRef } from 'react';
import MediaPickerModal from './media-picker-modal';

type ImageData = {
  id: string;
  mediaId: string | null;
  url: string;
  thumbUrl: string;
  mediaType: string;
  isPrimary: boolean;
  sortOrder: number;
};

const typeLabels: Record<string, string> = {
  LABEL: 'Etikett',
  BOTTLE: 'Flasche',
  SERVING: 'Serviervorschlag',
  AMBIANCE: 'Ambiente',
  LOGO: 'Logo',
  DOCUMENT: 'Dokument',
  OTHER: 'Sonstige',
};

const typeOptions = Object.entries(typeLabels).map(([value, label]) => ({ value, label }));

export default function ProductImages({ productId, initialImages }: { productId: string; initialImages: ImageData[] }) {
  const [showMediaPicker, setShowMediaPicker] = useState(false);
  const [images, setImages] = useState<ImageData[]>([...initialImages].sort((a, b) => a.isPrimary ? -1 : b.isPrimary ? 1 : a.sortOrder - b.sortOrder));
  const [uploading, setUploading] = useState(false);
  const [dragOver, setDragOver] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  const upload = async (files: FileList | File[]) => {
    setUploading(true);
    for (const file of Array.from(files)) {
      if (file.size > 4 * 1024 * 1024) { alert(file.name + ': Max 4MB'); continue; }
      const form = new FormData();
      form.append('file', file);
      form.append('productId', productId);
      form.append('mediaType', 'OTHER');

      try {
        const res = await fetch('/api/v1/media/upload', { method: 'POST', credentials: 'include', body: form });
        if (res.ok) {
          const data = await res.json();
          setImages(prev => [...prev, data]);
        } else {
          const err = await res.json();
          alert(err.error || 'Upload fehlgeschlagen');
        }
      } catch { alert('Upload fehlgeschlagen'); }
    }
    setUploading(false);
  };

  const assignFromArchive = async (media: any) => {
    try {
      const res = await fetch('/api/v1/products/' + productId + '/media', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          mediaId: media.id,
          mediaType: 'OTHER',
          isPrimary: images.length === 0,
        }),
      });
      if (res.ok) {
        const pm = await res.json();
        const formats = media.formats as any;
        setImages(prev => [...prev, {
          id: pm.id,
          mediaId: media.id,
          url: formats?.original?.url || media.url,
          thumbUrl: media.thumbnailUrl || media.url,
          mediaType: pm.mediaType || 'OTHER',
          isPrimary: pm.isPrimary || false,
          sortOrder: prev.length,
        }]);
      } else {
        const err = await res.json();
        alert(err.error || 'Zuordnung fehlgeschlagen');
      }
    } catch { alert('Zuordnung fehlgeschlagen'); }
  };

  const remove = async (id: string) => {
    const res = await fetch('/api/v1/media/' + id, { method: 'DELETE', credentials: 'include' });
    if (res.ok) setImages(prev => prev.filter(img => img.id !== id));
  };

  const setPrimary = async (id: string) => {
    const res = await fetch('/api/v1/media/' + id, {
      method: 'PATCH', credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ isPrimary: true }),
    });
    if (res.ok) setImages(prev => {
      const updated = prev.map(img => ({ ...img, isPrimary: img.id === id }));
      const primary = updated.find(i => i.id === id);
      if (primary) { const rest = updated.filter(i => i.id !== id); return [primary, ...rest]; }
      return updated;
    });
  };

  const setType = async (id: string, mediaType: string) => {
    const res = await fetch('/api/v1/media/' + id, {
      method: 'PATCH', credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ mediaType }),
    });
    if (res.ok) setImages(prev => prev.map(img => img.id === id ? { ...img, mediaType } : img));
  };

  const onDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
    if (e.dataTransfer.files?.length) upload(e.dataTransfer.files);
  };

  return (
    <section className="rounded-xl border bg-white p-5 shadow-sm">
      <div className="flex items-center justify-between mb-3">
        <h2 className="text-base font-semibold text-gray-500">&#x1F4F8; Bilder</h2>
        <div className="flex gap-2">
          <button onClick={() => setShowMediaPicker(true)}
            className="rounded-lg px-3 py-1.5 text-sm font-medium border-2 border-dashed border-amber-300 text-amber-700 hover:bg-amber-50 hover:border-amber-400 transition-colors">
            Aus Bildarchiv
          </button>
          <button onClick={() => fileRef.current?.click()} disabled={uploading}
            className="rounded-lg px-3 py-1.5 text-sm font-medium text-white disabled:opacity-50" style={{backgroundColor:'#8B6914'}}>
            {uploading ? 'Laedt...' : '+ Hochladen'}
          </button>
        </div>
        <input ref={fileRef} type="file" accept="image/*" multiple className="hidden" onChange={e => e.target.files && upload(e.target.files)} />
      </div>

      {/* Image Grid */}
      {images.length > 0 && (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3 mb-3">
          {images.map(img => (
            <div key={img.id} className={'relative group rounded-lg border overflow-hidden ' + (img.isPrimary ? 'ring-2 ring-amber-400' : '')}>
              <img src={img.url} alt="" className="w-full h-40 object-contain bg-gray-50 p-2" />
              {img.isPrimary && (
                <span className="absolute top-1 left-1 bg-amber-400 text-white text-[10px] font-bold px-1.5 py-0.5 rounded">Hauptbild</span>
              )}
              {/* Hover Overlay */}
              <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center justify-center gap-1.5">
                {!img.isPrimary && (
                  <button onClick={() => setPrimary(img.id)} className="text-sm text-white bg-amber-500 rounded px-2 py-1 hover:bg-amber-600">Hauptbild</button>
                )}
                <select value={img.mediaType} onChange={e => setType(img.id, e.target.value)}
                  className="text-sm rounded px-2 py-1 bg-white/90 text-gray-800 outline-none">
                  {typeOptions.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
                </select>
                <button onClick={() => remove(img.id)} className="text-sm text-white bg-red-500 rounded px-2 py-1 hover:bg-red-600">Loeschen</button>
              </div>
              <div className="px-2 py-1 bg-gray-50 text-[10px] text-gray-500 text-center">
                {typeLabels[img.mediaType] || img.mediaType}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Drop Zone */}
      <div
        onDragOver={e => { e.preventDefault(); setDragOver(true); }}
        onDragLeave={() => setDragOver(false)}
        onDrop={onDrop}
        onClick={() => fileRef.current?.click()}
        className={'rounded-lg border-2 border-dashed p-6 text-center cursor-pointer transition-colors ' +
          (dragOver ? 'border-blue-400 bg-blue-50' : 'border-gray-200 hover:border-gray-400 hover:bg-gray-50')}
      >
        <p className="text-base text-gray-400">{uploading ? 'Wird hochgeladen...' : dragOver ? 'Hier ablegen' : 'Bilder hierher ziehen oder klicken'}</p>
        <p className="text-sm text-gray-300 mt-1">JPEG, PNG, WebP - Max 4MB - Automatisch optimiert</p>
      </div>

      {/* MediaPicker Modal */}
      {showMediaPicker && (
        <MediaPickerModal
          isOpen={showMediaPicker}
          onClose={() => setShowMediaPicker(false)}
          onSelect={(media) => {
            assignFromArchive(media);
            setShowMediaPicker(false);
          }}
          categoryFilter="PHOTO"
          title="Bild aus Bildarchiv waehlen"
        />
      )}
    </section>
  );
}
ENDOFFILE

echo "  OK product-images.tsx (mit Bildarchiv-Button)"

# ───────────────────────────────────────
echo "[4/5] API: Produkt-Media Zuordnung..."
# ───────────────────────────────────────

mkdir -p "src/app/api/v1/products/[id]/media/[productMediaId]"

cat > "src/app/api/v1/products/[id]/media/route.ts" << 'ENDOFFILE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function POST(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { mediaId, mediaType, isPrimary } = await req.json();
  if (!mediaId) return NextResponse.json({ error: 'mediaId required' }, { status: 400 });

  const media = await prisma.media.findUnique({ where: { id: mediaId } });
  if (!media) return NextResponse.json({ error: 'Media not found' }, { status: 404 });

  const existing = await prisma.productMedia.findFirst({
    where: { productId: params.id, mediaId },
  });
  if (existing) return NextResponse.json({ error: 'Bereits zugeordnet' }, { status: 409 });

  const count = await prisma.productMedia.count({ where: { productId: params.id } });

  if (isPrimary) {
    await prisma.productMedia.updateMany({
      where: { productId: params.id, isPrimary: true },
      data: { isPrimary: false },
    });
  }

  const pm = await prisma.productMedia.create({
    data: {
      productId: params.id,
      mediaId,
      mediaType: (mediaType || 'OTHER') as any,
      url: media.url,
      alt: media.alt,
      sortOrder: count,
      isPrimary: isPrimary || count === 0,
    },
  });

  return NextResponse.json(pm, { status: 201 });
}

export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const productMedia = await prisma.productMedia.findMany({
    where: { productId: params.id },
    include: { media: true },
    orderBy: [{ isPrimary: 'desc' }, { sortOrder: 'asc' }],
  });

  return NextResponse.json(productMedia);
}
ENDOFFILE

cat > "src/app/api/v1/products/[id]/media/[productMediaId]/route.ts" << 'ENDOFFILE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function DELETE(
  req: NextRequest,
  { params }: { params: { id: string; productMediaId: string } }
) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  await prisma.productMedia.delete({ where: { id: params.productMediaId } });
  return NextResponse.json({ success: true });
}

export async function PATCH(
  req: NextRequest,
  { params }: { params: { id: string; productMediaId: string } }
) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { mediaType, isPrimary } = await req.json();
  const data: any = {};
  if (mediaType !== undefined) data.mediaType = mediaType;

  if (isPrimary) {
    await prisma.productMedia.updateMany({
      where: { productId: params.id, isPrimary: true },
      data: { isPrimary: false },
    });
    data.isPrimary = true;
  }

  const updated = await prisma.productMedia.update({
    where: { id: params.productMediaId },
    data,
  });

  return NextResponse.json(updated);
}
ENDOFFILE

echo "  OK Produkt-Media API"

# ───────────────────────────────────────
echo "[5/5] Build & Restart..."
# ───────────────────────────────────────

npm run build 2>&1 | tail -15

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo ""
  echo "============================================"
  echo "  Bildarchiv Phase 4 LIVE!"
  echo "============================================"
  echo ""
  echo "  Neue Features:"
  echo "  - Produkt-Editor: 'Aus Bildarchiv' Button"
  echo "  - MediaPicker Modal (Browse + Upload + Web)"
  echo "  - Produkt-Media Zuordnungs-API"
  echo "  - ImagePickerButton Komponente"
  echo ""
else
  echo ""
  echo "  FEHLER - Build fehlgeschlagen"
  echo "  Ausgabe oben pruefen!"
fi
