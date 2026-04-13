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
