#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Bildarchiv Phase 4: Integration in Produkt-Editor, Design-Editor, Admin-Liste
# ═══════════════════════════════════════════════════════════════
cd /var/www/menucard-pro

echo "=== Bildarchiv Phase 4 ==="
echo ""

# Backup
cp src/components/admin/product-images.tsx src/components/admin/product-images.tsx.bak-bildarchiv 2>/dev/null
cp src/components/admin/design-editor.tsx src/components/admin/design-editor.tsx.bak-bildarchiv 2>/dev/null

# ───────────────────────────────────────
echo "[1/5] Bildarchiv-Picker Modal-Komponente..."
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

interface UploadItem {
  file: File;
  status: 'pending' | 'uploading' | 'done' | 'error';
  mediaId?: string;
}

interface MediaPickerModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSelect: (media: MediaItem) => void;
  onMultiSelect?: (media: MediaItem[]) => void;
  categoryFilter?: 'PHOTO' | 'LOGO';
  multiSelect?: boolean;
  searchSuggestions?: string[];
  title?: string;
}

export default function MediaPickerModal({
  isOpen,
  onClose,
  onSelect,
  onMultiSelect,
  categoryFilter,
  multiSelect = false,
  searchSuggestions = [],
  title = 'Aus Bildarchiv wählen',
}: MediaPickerModalProps) {
  const [activeTab, setActiveTab] = useState<'browse' | 'upload' | 'web'>('browse');
  const [media, setMedia] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState(categoryFilter || '');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [selected, setSelected] = useState<Set<string>>(new Set());

  // Web-Search State
  const [webQuery, setWebQuery] = useState('');
  const [webSource, setWebSource] = useState<'pixabay' | 'pexels'>('pixabay');
  const [webResults, setWebResults] = useState<any[]>([]);
  const [webLoading, setWebLoading] = useState(false);
  const [webImporting, setWebImporting] = useState(false);

  // Upload State
  const [uploadFiles, setUploadFiles] = useState<UploadItem[]>([]);
  const [uploadCategory, setUploadCategory] = useState(categoryFilter || 'PHOTO');

  const fetchMedia = useCallback(async () => {
    setLoading(true);
    const params = new URLSearchParams();
    params.set('page', String(page));
    params.set('limit', '20');
    params.set('sort', 'newest');
    if (category) params.set('category', category);
    if (search) params.set('q', search);

    try {
      const res = await fetch(`/api/v1/media?${params}`);
      const data = await res.json();
      setMedia(data.media || []);
      setTotalPages(data.totalPages || 1);
    } catch (e) { console.error(e); }
    setLoading(false);
  }, [page, search, category]);

  useEffect(() => { if (isOpen) fetchMedia(); }, [isOpen, fetchMedia]);
  useEffect(() => { setPage(1); }, [search, category]);

  function toggleSelect(id: string) {
    if (multiSelect) {
      setSelected(prev => {
        const s = new Set(prev);
        if (s.has(id)) s.delete(id); else s.add(id);
        return s;
      });
    } else {
      const item = media.find(m => m.id === id);
      if (item) { onSelect(item); onClose(); }
    }
  }

  function confirmMultiSelect() {
    const items = media.filter(m => selected.has(m.id));
    if (onMultiSelect) onMultiSelect(items);
    onClose();
  }

  // Upload
  async function uploadAll() {
    const pending = uploadFiles.filter(f => f.status === 'pending');
    for (const item of pending) {
      setUploadFiles(prev => prev.map(f =>
        f.file === item.file ? { ...f, status: 'uploading' } : f
      ));
      try {
        const fd = new FormData();
        fd.append('file', item.file);
        fd.append('category', uploadCategory);
        fd.append('title', item.file.name.replace(/\.[^.]+$/, ''));
        const res = await fetch('/api/v1/media/upload', { method: 'POST', body: fd });
        if (!res.ok) throw new Error('Upload failed');
        const data = await res.json();
        setUploadFiles(prev => prev.map(f =>
          f.file === item.file ? { ...f, status: 'done', mediaId: data.mediaId } : f
        ));
      } catch {
        setUploadFiles(prev => prev.map(f =>
          f.file === item.file ? { ...f, status: 'error' } : f
        ));
      }
    }
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
        const data = await res.json();
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
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 text-xl">✕</button>
        </div>

        {/* Tabs */}
        <div className="flex border-b px-4">
          {[
            { id: 'browse' as const, label: '📷 Durchsuchen' },
            { id: 'upload' as const, label: '📤 Hochladen' },
            { id: 'web' as const, label: '🌐 Websuche' },
          ].map(tab => (
            <button key={tab.id} onClick={() => setActiveTab(tab.id)}
              className={`px-4 py-2.5 text-sm font-medium border-b-2 ${
                activeTab === tab.id ? 'border-amber-600 text-amber-700' : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}>
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
                      <div key={m.id} onClick={() => toggleSelect(m.id)}
                        className={`cursor-pointer border-2 rounded-lg overflow-hidden transition-all ${
                          selected.has(m.id) ? 'border-amber-500 ring-2 ring-amber-200' : 'border-transparent hover:border-gray-300'
                        }`}>
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
                        className="px-2 py-1 text-xs border rounded disabled:opacity-30">←</button>
                      <span className="px-2 py-1 text-xs text-gray-500">{page}/{totalPages}</span>
                      <button onClick={() => setPage(p => Math.min(totalPages, p+1))} disabled={page >= totalPages}
                        className="px-2 py-1 text-xs border rounded disabled:opacity-30">→</button>
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
                  const items: UploadItem[] = Array.from(e.dataTransfer.files)
                    .filter(f => f.type.startsWith('image/'))
                    .map(f => ({ file: f, status: 'pending' as const }));
                  setUploadFiles(prev => [...prev, ...items]);
                }}
                onClick={() => {
                  const input = document.createElement('input');
                  input.type = 'file'; input.multiple = true; input.accept = 'image/*';
                  input.onchange = () => {
                    if (input.files) {
                      const items: UploadItem[] = Array.from(input.files).map(f => ({ file: f, status: 'pending' as const }));
                      setUploadFiles(prev => [...prev, ...items]);
                    }
                  };
                  input.click();
                }}
                className="border-2 border-dashed rounded-xl p-8 text-center cursor-pointer hover:border-amber-400 hover:bg-amber-50/50"
              >
                <p className="text-2xl mb-2">📸</p>
                <p className="text-sm text-gray-600">Bilder hier ablegen oder klicken</p>
              </div>
              {uploadFiles.length > 0 && (
                <div className="mt-3 space-y-1">
                  {uploadFiles.map((item, i) => (
                    <div key={i} className="flex items-center gap-2 p-1.5 bg-gray-50 rounded text-sm">
                      <span>{item.status === 'done' ? '✅' : item.status === 'error' ? '❌' : '📄'}</span>
                      <span className="flex-1 truncate">{item.file.name}</span>
                    </div>
                  ))}
                  <button onClick={uploadAll}
                    className="mt-2 px-4 py-1.5 bg-amber-600 text-white rounded text-sm hover:bg-amber-700">
                    Hochladen
                  </button>
                </div>
              )}
            </div>
          )}

          {/* Web Tab */}
          {activeTab === 'web' && (
            <div>
              {/* Suchvorschläge */}
              {searchSuggestions.length > 0 && (
                <div className="flex flex-wrap gap-2 mb-3">
                  {searchSuggestions.map((s, i) => (
                    <button key={i} onClick={() => { setWebQuery(s); }}
                      className="px-2.5 py-1 bg-amber-50 border border-amber-200 rounded-full text-xs text-amber-700 hover:bg-amber-100">
                      {s}
                    </button>
                  ))}
                </div>
              )}
              <div className="flex gap-2 mb-3">
                <input type="text" placeholder="Suchbegriff..." value={webQuery}
                  onChange={(e) => setWebQuery(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && webSearch()}
                  className="flex-1 px-3 py-1.5 border rounded text-sm focus:outline-none focus:ring-2 focus:ring-amber-500" />
                <select value={webSource} onChange={(e) => setWebSource(e.target.value as any)}
                  className="px-2 py-1.5 border rounded text-sm bg-white">
                  <option value="pixabay">Pixabay</option>
                  <option value="pexels">Pexels</option>
                </select>
                <button onClick={webSearch} disabled={webLoading}
                  className="px-4 py-1.5 bg-amber-600 text-white rounded text-sm hover:bg-amber-700 disabled:opacity-50">
                  Suchen
                </button>
              </div>
              {webLoading ? (
                <div className="text-center py-8 text-gray-400">Suche...</div>
              ) : (
                <div className="grid grid-cols-4 sm:grid-cols-5 gap-3">
                  {webResults.map((r, i) => (
                    <div key={r.id} className="border rounded-lg overflow-hidden">
                      <div className="aspect-square bg-gray-100">
                        <img src={r.previewUrl} alt="" className="w-full h-full object-cover" loading="lazy" />
                      </div>
                      <div className="p-1.5">
                        <p className="text-[10px] text-gray-500 truncate">📷 {r.author}</p>
                        <button onClick={() => webImport(r)} disabled={webImporting}
                          className="mt-1 w-full px-2 py-1 bg-amber-100 text-amber-700 rounded text-[10px] hover:bg-amber-200 disabled:opacity-50">
                          Importieren
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>

        {/* Footer */}
        {multiSelect && selected.size > 0 && (
          <div className="p-4 border-t flex justify-end">
            <button onClick={confirmMultiSelect}
              className="px-5 py-2 bg-amber-600 text-white rounded-lg text-sm font-medium hover:bg-amber-700">
              {selected.size} Bild{selected.size > 1 ? 'er' : ''} übernehmen
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
ENDOFFILE

echo "  ✓ MediaPickerModal erstellt"

# ───────────────────────────────────────
echo "[2/5] Produkt-Editor: 'Aus Bildarchiv wählen'..."
# ───────────────────────────────────────

# Wir fügen den Bildarchiv-Button in product-images.tsx ein
# Da die Datei komplex ist, patchen wir sie vorsichtig

# Prüfen ob Datei existiert
if [ -f src/components/admin/product-images.tsx ]; then

python3 << 'PYEOF'
with open('src/components/admin/product-images.tsx', 'r') as f:
    content = f.read()

# Import für MediaPickerModal hinzufügen (nach letztem import)
if 'MediaPickerModal' not in content:
    # Finde die letzte import-Zeile
    import_insert = "import MediaPickerModal from './media-picker-modal';\n"

    # Nach 'use client' oder nach den imports einfügen
    if "'use client'" in content:
        content = content.replace("'use client';", "'use client';\n" + import_insert, 1)
    else:
        content = import_insert + content

    # State für Modal hinzufügen - nach dem ersten useState finden
    if 'const [showMediaPicker' not in content:
        # Finde ein bestehendes useState und füge danach ein
        idx = content.find('useState')
        if idx > -1:
            # Finde das Ende der Zeile
            line_end = content.find('\n', idx)
            if line_end > -1:
                content = content[:line_end+1] + "  const [showMediaPicker, setShowMediaPicker] = useState(false);\n" + content[line_end+1:]

    # Button "Aus Bildarchiv wählen" einfügen
    # Suche nach dem Upload-Bereich / Drop-Zone und füge Button davor oder danach ein
    # Wir suchen nach einem typischen Pattern in der Datei

    # Variante 1: Suche nach "Bild hochladen" oder ähnlichem Button-Text
    button_html = """
      {/* Bildarchiv-Button */}
      <button
        type="button"
        onClick={() => setShowMediaPicker(true)}
        className="w-full px-4 py-2 border-2 border-dashed border-amber-300 rounded-lg text-sm text-amber-700 hover:bg-amber-50 hover:border-amber-400 transition-colors"
      >
        🖼️ Aus Bildarchiv wählen
      </button>
      {showMediaPicker && (
        <MediaPickerModal
          isOpen={showMediaPicker}
          onClose={() => setShowMediaPicker(false)}
          onSelect={async (media) => {
            try {
              const res = await fetch(`/api/v1/products/${productId}/media`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  mediaId: media.id,
                  mediaType: 'OTHER',
                  isPrimary: false,
                }),
              });
              if (res.ok) {
                window.location.reload();
              }
            } catch (e) { console.error(e); }
          }}
          categoryFilter="PHOTO"
          title="Bild für Produkt wählen"
        />
      )}
"""

    # Suche nach </div> vor dem return-Ende und füge vor dem letzten schließenden div ein
    # Einfacherer Ansatz: Vor dem drop-zone div einfügen
    if 'dropzone' in content.lower() or 'drag' in content.lower():
        # Suche nach dem Drag & Drop Bereich
        for marker in ['className="dropzone', 'onDrop', 'drag & drop', 'Drag & Drop', 'hierher ziehen', 'zum Hochladen']:
            idx = content.find(marker)
            if idx > -1:
                # Gehe zurück zur vorherigen Zeile mit <div
                search_area = content[max(0,idx-500):idx]
                div_pos = search_area.rfind('<div')
                if div_pos > -1:
                    insert_pos = max(0,idx-500) + div_pos
                    content = content[:insert_pos] + button_html + '\n' + content[insert_pos:]
                    break
    else:
        # Fallback: Vor dem return-Ende einfügen
        last_return = content.rfind('</div>')
        if last_return > -1:
            content = content[:last_return] + button_html + '\n' + content[last_return:]

with open('src/components/admin/product-images.tsx', 'w') as f:
    f.write(content)

print("  ✓ product-images.tsx gepatcht")
PYEOF

else
  echo "  ⚠️  product-images.tsx nicht gefunden – überspringe"
fi

echo "  ✓ Produkt-Editor: Bildarchiv-Button"

# ───────────────────────────────────────
echo "[3/5] API: Produkt-Media Zuordnung..."
# ───────────────────────────────────────

# POST /api/v1/products/[id]/media – Bild zuordnen
# DELETE /api/v1/products/[id]/media/[pmId] – Zuordnung entfernen

mkdir -p src/app/api/v1/products/\[id\]/media/\[productMediaId\]

cat > src/app/api/v1/products/\[id\]/media/route.ts << 'ENDOFFILE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function POST(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { mediaId, mediaType, isPrimary } = await req.json();
  if (!mediaId) return NextResponse.json({ error: 'mediaId required' }, { status: 400 });

  // Prüfe ob Media existiert
  const media = await prisma.media.findUnique({ where: { id: mediaId } });
  if (!media) return NextResponse.json({ error: 'Media not found' }, { status: 404 });

  // Prüfe ob Zuordnung schon existiert
  const existing = await prisma.productMedia.findFirst({
    where: { productId: params.id, mediaId },
  });
  if (existing) return NextResponse.json({ error: 'Bereits zugeordnet' }, { status: 409 });

  const count = await prisma.productMedia.count({ where: { productId: params.id } });

  // Wenn isPrimary, alte Primary entfernen
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

// GET: Alle Bilder eines Produkts
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

cat > src/app/api/v1/products/\[id\]/media/\[productMediaId\]/route.ts << 'ENDOFFILE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

// DELETE: Zuordnung entfernen (Bild bleibt im Archiv)
export async function DELETE(
  req: NextRequest,
  { params }: { params: { id: string; productMediaId: string } }
) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  await prisma.productMedia.delete({ where: { id: params.productMediaId } });

  return NextResponse.json({ success: true });
}

// PATCH: Typ oder Primary ändern
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
    // Alte Primary entfernen
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

echo "  ✓ Produkt-Media Zuordnungs-API erstellt"

# ───────────────────────────────────────
echo "[4/5] Admin-Produktliste: Thumbnails..."
# ───────────────────────────────────────

# Wir patchen die Produktliste, um Thumbnails anzuzeigen
# Die Produktliste ist typischerweise in src/components/admin/product-list.tsx oder ähnlich

PRODUCT_LIST=""
for f in src/components/admin/product-list.tsx src/components/admin/list-panel.tsx; do
  if [ -f "$f" ]; then
    PRODUCT_LIST="$f"
    break
  fi
done

if [ -n "$PRODUCT_LIST" ]; then
  cp "$PRODUCT_LIST" "${PRODUCT_LIST}.bak-bildarchiv"

python3 << PYEOF
import re

filename = "$PRODUCT_LIST"
with open(filename, 'r') as f:
    content = f.read()

# Prüfe ob Thumbnail schon vorhanden
if 'thumbnailUrl' not in content and 'productMedia' not in content:
    # Suche nach dem Produktnamen-Bereich in der Liste
    # Typisches Pattern: <span oder <p mit product name
    # Wir fügen ein kleines Bild vor dem Produktnamen ein

    # Suche nach Pattern wo der Produktname angezeigt wird
    # z.B. translations[0]?.name oder ähnlich
    name_patterns = [
        r'(translations\[0\]\?\.name)',
        r'(\.name)',
    ]

    for pattern in name_patterns:
        match = re.search(pattern, content)
        if match:
            # Finde das öffnende Tag davor
            pos = match.start()
            before = content[max(0,pos-200):pos]
            # Prüfe ob wir einen guten Einfügepunkt haben
            tag_start = before.rfind('<')
            if tag_start > -1:
                insert_pos = max(0,pos-200) + tag_start
                thumb_code = """<div className="w-8 h-8 rounded bg-gray-100 overflow-hidden flex-shrink-0 mr-2">
                  {(p as any).productMedia?.[0]?.media?.thumbnailUrl ? (
                    <img src={(p as any).productMedia[0].media.thumbnailUrl} alt="" className="w-full h-full object-cover" />
                  ) : (
                    <span className="w-full h-full flex items-center justify-center text-xs text-gray-400">📷</span>
                  )}
                </div>
                """
                content = content[:insert_pos] + thumb_code + content[insert_pos:]
                break

    with open(filename, 'w') as f:
        f.write(content)
    print(f"  ✓ {filename} gepatcht (Thumbnails)")
else:
    print(f"  ⓘ {filename} hat bereits Thumbnails")
PYEOF

else
  echo "  ⚠️  Produktliste nicht gefunden – überspringe Thumbnails"
fi

echo "  ✓ Admin-Produktliste: Thumbnails"

# ───────────────────────────────────────
echo "[5/5] Design-Editor: Bildarchiv-Picker für Logo/Header..."
# ───────────────────────────────────────

# Im Design-Editor fügen wir einen Image-Picker für Header-Bild und Logo ein
# Wir erstellen eine kleine Hilfskomponente

cat > src/components/admin/image-picker-button.tsx << 'ENDOFFILE'
'use client';

import { useState } from 'react';
import MediaPickerModal from './media-picker-modal';

interface ImagePickerButtonProps {
  label: string;
  currentMediaId?: string | null;
  currentUrl?: string | null;
  onSelect: (mediaId: string, url: string) => void;
  onRemove?: () => void;
  categoryFilter?: 'PHOTO' | 'LOGO';
}

export default function ImagePickerButton({
  label,
  currentMediaId,
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
                ✕
              </button>
            )}
          </div>
        ) : null}
        <button type="button" onClick={() => setShowPicker(true)}
          className="px-3 py-1.5 border border-dashed border-amber-300 rounded text-xs text-amber-700 hover:bg-amber-50">
          {currentUrl ? 'Ändern' : `🖼️ ${label} wählen`}
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
          title={`${label} aus Bildarchiv wählen`}
        />
      )}
    </div>
  );
}
ENDOFFILE

echo "  ✓ ImagePickerButton erstellt"

# ───────────────────────────────────────
echo ""
echo "[BUILD] Kompiliere..."
# ───────────────────────────────────────

npm run build 2>&1 | tail -15

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo ""
  echo "═══════════════════════════════════"
  echo "  ✅ Bildarchiv Phase 4 LIVE!"
  echo "═══════════════════════════════════"
  echo ""
  echo "  Neue Features:"
  echo "  → MediaPicker Modal (Browse + Upload + Web)"
  echo "  → Produkt-Editor: 'Aus Bildarchiv wählen'"
  echo "  → Produkt-Media Zuordnungs-API"
  echo "  → ImagePickerButton für Design-Editor"
  echo ""
else
  echo ""
  echo "  ❌ Build fehlgeschlagen – siehe Fehler oben"
fi
