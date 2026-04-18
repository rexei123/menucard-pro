'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import CropEditor from './crop-editor';

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
  const [cropFormat, setCropFormat] = useState<string | null>(null);

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

  if (loading) return <div className="p-6 text-center text-[#999]">Laden...</div>;
  if (!media) return <div className="p-6 text-center text-red-500">Bild nicht gefunden</div>;

  const formats = media.formats as Record<string, any> || {};
  const formatKeys = ['original', '16:9', '4:3', '1:1', '3:4', 'thumb'].filter(k => formats[k]);

  return (
    <div className="p-6 max-w-[1200px] mx-auto">
      {/* Header */}
      <button onClick={() => router.push('/admin/media')} className="text-sm text-[#DD3C71] hover:underline mb-4 block">
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
              onError={(e) => {
                const img = e.target as HTMLImageElement;
                if (media.url && !img.src.endsWith(media.url)) {
                  img.src = media.url;
                } else if (media.thumbnailUrl && !img.src.endsWith(media.thumbnailUrl)) {
                  img.src = media.thumbnailUrl;
                } else {
                  img.style.display = 'none';
                  img.parentElement!.innerHTML = '<div class="w-full h-[300px] flex flex-col items-center justify-center text-[#999]"><span class="material-symbols-outlined" style="font-size:48px">broken_image</span><p class="text-sm mt-2">Bild nicht gefunden</p></div>';
                }
              }}
            />
          </div>

          {/* Formate */}
          <h3 className="text-sm font-semibold text-[#171A1F] mt-6 mb-3">Formate</h3>
          <div className="grid grid-cols-3 sm:grid-cols-5 gap-3">
            {formatKeys.map(key => (
              <div key={key} className="group relative">
                <div className="aspect-square bg-gray-100 rounded-lg overflow-hidden border">
                  <img
                    src={formats[key]?.url}
                    alt={key}
                    className="w-full h-full object-cover"
                    loading="lazy"
                    onError={(e) => {
                      const img = e.target as HTMLImageElement;
                      img.style.display = 'none';
                      img.parentElement!.innerHTML = '<div class="w-full h-full flex items-center justify-center text-[#999]"><span class="material-symbols-outlined" style="font-size:20px">broken_image</span></div>';
                    }}
                  />
                </div>
                <p className="text-[10px] text-center text-[#565D6D] mt-1">
                  {key === 'original' ? 'Original' : key}
                </p>
                <p className="text-[10px] text-center text-[#999]">
                  {formats[key]?.width}×{formats[key]?.height}
                </p>
                {key !== 'original' && key !== 'thumb' && (
                  <button
                    onClick={() => setCropFormat(key)}
                    className="mt-1 w-full text-[10px] text-[#DD3C71] hover:text-[#C42D60]"
                  >
                    Zuschneiden
                  </button>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Rechte Seite: Metadaten */}
        <div className="space-y-4">
          <div>
            <label className="text-sm font-medium text-[#171A1F] block mb-1">Titel</label>
            <input
              type="text" value={title} onChange={(e) => setTitle(e.target.value)}
              className="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#DD3C71]"
            />
          </div>
          <div>
            <label className="text-sm font-medium text-[#171A1F] block mb-1">Alt-Text</label>
            <input
              type="text" value={alt} onChange={(e) => setAlt(e.target.value)}
              className="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#DD3C71]"
            />
          </div>
          <div>
            <label className="text-sm font-medium text-[#171A1F] block mb-1">Kategorie</label>
            <select value={category} onChange={(e) => setCategory(e.target.value)}
              className="w-full px-3 py-2 border rounded-lg text-sm bg-white">
              <option value="PHOTO">Foto</option>
              <option value="LOGO">Logo</option>
              <option value="DOCUMENT">Dokument</option>
            </select>
          </div>

          {/* Info */}
          <div className="bg-[#F9FAFB] rounded-lg p-4 space-y-2 text-sm">
            <div className="flex justify-between"><span className="text-[#565D6D]">Quelle</span><span>{media.source}</span></div>
            {media.sourceAuthor && (
              <div className="flex justify-between"><span className="text-[#565D6D]">Fotograf</span><span>{media.sourceAuthor}</span></div>
            )}
            <div className="flex justify-between"><span className="text-[#565D6D]">Hochgeladen</span><span>{formatDate(media.createdAt)}</span></div>
            <div className="flex justify-between"><span className="text-[#565D6D]">Größe</span><span>{formatSize(media.sizeBytes)}</span></div>
            <div className="flex justify-between"><span className="text-[#565D6D]">Dimensionen</span><span>{media.width}×{media.height}</span></div>
            <div className="flex justify-between"><span className="text-[#565D6D]">Datei</span><span className="truncate max-w-[200px]">{media.originalName || media.filename}</span></div>
          </div>

          {/* Zugeordnete Produkte */}
          <div>
            <h3 className="text-sm font-semibold text-[#171A1F] mb-2">
              Zugeordnet zu ({media.productMedia.length})
            </h3>
            {media.productMedia.length === 0 ? (
              <p className="text-sm text-[#999]">Keinem Produkt zugeordnet</p>
            ) : (
              <div className="space-y-1">
                {media.productMedia.map(pm => (
                  <div key={pm.id} className="flex items-center gap-2 text-sm p-2 bg-[#F9FAFB] rounded">
                    <span className="text-[10px] bg-[#DD3C71]/10 text-[#DD3C71] px-1.5 py-0.5 rounded">{pm.mediaType}</span>
                    <span>{pm.product.translations[0]?.name || 'Unbenannt'}</span>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Actions */}
          <div className="flex gap-3 pt-4 border-t">
            <button onClick={save} disabled={saving}
              className="px-5 py-2 bg-[#DD3C71] text-white rounded-lg text-sm font-medium hover:bg-[#C42D60] disabled:opacity-50">
              {saving ? 'Speichere...' : 'Speichern'}
            </button>
            <button onClick={() => deleteMedia(false)}
              className="px-5 py-2 border border-red-300 text-red-600 rounded-lg text-sm hover:bg-red-50">
              Bild löschen
            </button>
          </div>
        </div>
      </div>

      {/* Crop-Editor Modal */}
      {cropFormat && media && formats.original && (
        <CropEditor
          imageUrl={formats.original.url}
          imageWidth={media.width || 800}
          imageHeight={media.height || 600}
          format={cropFormat}
          initialCrop={formats[cropFormat]?.cropX !== undefined ? {
            cropX: formats[cropFormat].cropX,
            cropY: formats[cropFormat].cropY,
            cropW: formats[cropFormat].cropW,
            cropH: formats[cropFormat].cropH,
          } : undefined}
          onSave={async (crop) => {
            try {
              await fetch(`/api/v1/media/${mediaId}/crop`, {
                method: 'PATCH',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ format: cropFormat, ...crop }),
              });
              setCropFormat(null);
              // Refresh
              const res = await fetch(`/api/v1/media/${mediaId}`);
              const data = await res.json();
              setMedia(data);
            } catch (e) { console.error(e); }
          }}
          onCancel={() => setCropFormat(null)}
        />
      )}
    </div>
  );
}
