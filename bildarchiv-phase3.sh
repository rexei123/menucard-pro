#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Bildarchiv Phase 3: Websuche (Pixabay/Pexels API)
# ═══════════════════════════════════════════════════════════════
cd /var/www/menucard-pro

echo "=== Bildarchiv Phase 3 ==="
echo ""

# ───────────────────────────────────────
echo "[1/4] API: Web-Search Endpoint..."
# ───────────────────────────────────────

mkdir -p src/app/api/v1/media/web-search
mkdir -p src/app/api/v1/media/web-import

cat > src/app/api/v1/media/web-search/route.ts << 'ENDOFFILE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

interface SearchResult {
  id: string;
  previewUrl: string;
  fullUrl: string;
  width: number;
  height: number;
  author: string;
  sourceUrl: string;
  tags: string;
}

async function searchPixabay(query: string, page: number): Promise<{ results: SearchResult[]; total: number }> {
  const key = process.env.PIXABAY_API_KEY;
  if (!key) return { results: [], total: 0 };

  const url = `https://pixabay.com/api/?key=${key}&q=${encodeURIComponent(query)}&image_type=photo&per_page=20&page=${page}&lang=de`;
  const res = await fetch(url);
  if (!res.ok) return { results: [], total: 0 };
  const data = await res.json();

  return {
    total: data.totalHits || 0,
    results: (data.hits || []).map((h: any) => ({
      id: `pixabay-${h.id}`,
      previewUrl: h.webformatURL,
      fullUrl: h.largeImageURL,
      width: h.imageWidth,
      height: h.imageHeight,
      author: h.user,
      sourceUrl: h.pageURL,
      tags: h.tags,
    })),
  };
}

async function searchPexels(query: string, page: number): Promise<{ results: SearchResult[]; total: number }> {
  const key = process.env.PEXELS_API_KEY;
  if (!key) return { results: [], total: 0 };

  const url = `https://api.pexels.com/v1/search?query=${encodeURIComponent(query)}&per_page=20&page=${page}&locale=de-DE`;
  const res = await fetch(url, { headers: { Authorization: key } });
  if (!res.ok) return { results: [], total: 0 };
  const data = await res.json();

  return {
    total: data.total_results || 0,
    results: (data.photos || []).map((p: any) => ({
      id: `pexels-${p.id}`,
      previewUrl: p.src.medium,
      fullUrl: p.src.large2x,
      width: p.width,
      height: p.height,
      author: p.photographer,
      sourceUrl: p.url,
      tags: p.alt || '',
    })),
  };
}

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { query, source, page } = await req.json();
  if (!query) return NextResponse.json({ error: 'Query required' }, { status: 400 });

  const p = page || 1;
  let data;

  if (source === 'pexels') {
    data = await searchPexels(query, p);
  } else {
    data = await searchPixabay(query, p);
  }

  return NextResponse.json(data);
}
ENDOFFILE

echo "  ✓ Web-Search API erstellt"

# ───────────────────────────────────────
echo "[2/4] API: Web-Import Endpoint..."
# ───────────────────────────────────────

cat > src/app/api/v1/media/web-import/route.ts << 'ENDOFFILE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import sharp from 'sharp';
import { mkdir } from 'fs/promises';
import path from 'path';
import crypto from 'crypto';

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { url, source, sourceAuthor, sourceUrl, category } = await req.json();
  if (!url) return NextResponse.json({ error: 'URL required' }, { status: 400 });

  try {
    // Bild herunterladen
    const imgRes = await fetch(url);
    if (!imgRes.ok) throw new Error('Download failed');
    const buffer = Buffer.from(await imgRes.arrayBuffer());

    if (buffer.length > 10 * 1024 * 1024) {
      return NextResponse.json({ error: 'Bild zu groß (max 10MB)' }, { status: 400 });
    }

    const hash = crypto.createHash('md5').update(buffer).digest('hex').slice(0, 12);
    const filename = `${hash}-${Date.now()}`;
    const basePath = path.join(process.cwd(), 'public', 'uploads');
    const cat = category || 'PHOTO';
    const isLogo = cat === 'LOGO';

    await mkdir(path.join(basePath, 'original'), { recursive: true });
    await mkdir(path.join(basePath, 'formats'), { recursive: true });
    await mkdir(path.join(basePath, 'large'), { recursive: true });
    await mkdir(path.join(basePath, 'medium'), { recursive: true });
    await mkdir(path.join(basePath, 'thumb'), { recursive: true });

    const img = sharp(buffer).rotate();
    const meta = await img.metadata();
    const w = meta.width || 800;
    const h = meta.height || 600;
    const ext = isLogo ? 'png' : 'webp';

    // Original
    if (isLogo) {
      await img.clone().png().toFile(path.join(basePath, 'original', `${filename}.png`));
    } else {
      await img.clone().webp({ quality: 90 }).toFile(path.join(basePath, 'original', `${filename}.webp`));
    }

    const fmt = isLogo
      ? (clone: sharp.Sharp) => clone.png()
      : (clone: sharp.Sharp) => clone.webp({ quality: 85 });

    // 6 Formate generieren
    await fmt(img.clone().resize(1920, 1080, { fit: 'cover', position: 'center' }))
      .toFile(path.join(basePath, 'formats', `${filename}-16x9.${ext}`));
    await fmt(img.clone().resize(1200, 900, { fit: 'cover', position: 'center' }))
      .toFile(path.join(basePath, 'formats', `${filename}-4x3.${ext}`));
    await fmt(img.clone().resize(800, 800, { fit: 'cover', position: 'center' }))
      .toFile(path.join(basePath, 'formats', `${filename}-1x1.${ext}`));
    await fmt(img.clone().resize(600, 800, { fit: 'cover', position: 'center' }))
      .toFile(path.join(basePath, 'formats', `${filename}-3x4.${ext}`));
    await img.clone().resize(200, 200, { fit: 'cover', position: 'center' })
      .webp({ quality: 75 }).toFile(path.join(basePath, 'thumb', `${filename}.webp`));
    await img.clone().resize(1200, null, { withoutEnlargement: true })
      .webp({ quality: 85 }).toFile(path.join(basePath, 'large', `${filename}.webp`));
    await img.clone().resize(600, null, { withoutEnlargement: true })
      .webp({ quality: 80 }).toFile(path.join(basePath, 'medium', `${filename}.webp`));

    // Crop-Koordinaten
    function centerCrop(srcW: number, srcH: number, tgtRatio: number) {
      const srcRatio = srcW / srcH;
      let cropW, cropH, cropX, cropY;
      if (srcRatio > tgtRatio) {
        cropH = srcH; cropW = Math.round(srcH * tgtRatio);
        cropX = Math.round((srcW - cropW) / 2); cropY = 0;
      } else {
        cropW = srcW; cropH = Math.round(srcW / tgtRatio);
        cropX = 0; cropY = Math.round((srcH - cropH) / 2);
      }
      return { cropX, cropY, cropW, cropH };
    }

    const formats = {
      original: { url: `/uploads/original/${filename}.${ext}`, width: w, height: h },
      '16:9': { url: `/uploads/formats/${filename}-16x9.${ext}`, width: 1920, height: 1080, ...centerCrop(w, h, 16/9) },
      '4:3': { url: `/uploads/formats/${filename}-4x3.${ext}`, width: 1200, height: 900, ...centerCrop(w, h, 4/3) },
      '1:1': { url: `/uploads/formats/${filename}-1x1.${ext}`, width: 800, height: 800, ...centerCrop(w, h, 1) },
      '3:4': { url: `/uploads/formats/${filename}-3x4.${ext}`, width: 600, height: 800, ...centerCrop(w, h, 3/4) },
      thumb: { url: `/uploads/thumb/${filename}.webp`, width: 200, height: 200 },
    };

    // Titel aus URL extrahieren
    const urlParts = url.split('/');
    const autoTitle = sourceAuthor ? `${sourceAuthor} (${source || 'Web'})` : urlParts[urlParts.length - 1]?.split('?')[0] || 'Web-Bild';

    const media = await prisma.media.create({
      data: {
        tenantId: (session.user as any).tenantId,
        filename: `${filename}.${ext}`,
        originalName: autoTitle,
        title: autoTitle,
        mimeType: isLogo ? 'image/png' : 'image/webp',
        url: `/uploads/large/${filename}.webp`,
        thumbnailUrl: `/uploads/thumb/${filename}.webp`,
        width: w,
        height: h,
        sizeBytes: buffer.length,
        alt: autoTitle,
        formats: formats as any,
        category: cat as any,
        source: (source || 'WEB') as any,
        sourceUrl: sourceUrl || url,
        sourceAuthor: sourceAuthor || null,
      },
    });

    return NextResponse.json({
      id: media.id,
      url: media.url,
      thumbnailUrl: media.thumbnailUrl,
      formats,
    }, { status: 201 });

  } catch (e: any) {
    console.error('Web import error:', e);
    return NextResponse.json({ error: 'Import failed', details: e.message }, { status: 500 });
  }
}
ENDOFFILE

echo "  ✓ Web-Import API erstellt"

# ───────────────────────────────────────
echo "[3/4] Suchbegriff-Generierung (Utility)..."
# ───────────────────────────────────────

mkdir -p src/lib

cat > src/lib/search-suggestions.ts << 'ENDOFFILE'
// Regelbasierte Suchbegriff-Generierung aus Produktdaten

interface ProductData {
  name: string;
  type?: string;
  wineProfile?: {
    winery?: string | null;
    grapeVarieties?: string[];
    region?: string | null;
    country?: string | null;
  } | null;
  beverageDetail?: {
    brand?: string | null;
    category?: string | null;
  } | null;
  groupName?: string | null;
}

export function generateSearchSuggestions(product: ProductData): string[] {
  const suggestions: string[] = [];

  if (product.type === 'WINE' && product.wineProfile) {
    const { winery, grapeVarieties, region, country } = product.wineProfile;
    const grape = grapeVarieties?.[0] || '';

    if (winery && grape) suggestions.push(`${winery} ${grape} bottle`);
    if (grape) suggestions.push(`${grape} wine bottle`);
    if (country && region) suggestions.push(`${country} wine ${region}`);
    suggestions.push('wine glass vineyard');
  } else if (product.type === 'DRINK' && product.beverageDetail) {
    const { brand, category } = product.beverageDetail;
    const name = product.name;

    if (name) suggestions.push(`${name} cocktail`);
    if (brand) suggestions.push(`${brand} drink`);
    if (category) suggestions.push(`${category} bar`);
    suggestions.push('cocktail glass bar ambiance');
  } else {
    // FOOD oder andere
    const name = product.name;
    const group = product.groupName;

    if (name) suggestions.push(name);
    if (name) suggestions.push(`${name} restaurant plating`);
    if (group) suggestions.push(`${group} fine dining`);
  }

  return suggestions.filter(s => s.trim().length > 0).slice(0, 4);
}
ENDOFFILE

echo "  ✓ Suchbegriff-Generierung erstellt"

# ───────────────────────────────────────
echo "[4/4] Websuche-Tab in MediaArchive aktivieren..."
# ───────────────────────────────────────

# WebSearchTab Platzhalter durch funktionale Komponente ersetzen
cat > /tmp/web-search-tab.tsx << 'ENDOFFILE'
function WebSearchTab({ onImported }: { onImported: () => void }) {
  const [query, setQuery] = useState('');
  const [source, setSource] = useState<'pixabay' | 'pexels'>('pixabay');
  const [results, setResults] = useState<any[]>([]);
  const [selected, setSelected] = useState<Set<number>>(new Set());
  const [loading, setLoading] = useState(false);
  const [importing, setImporting] = useState(false);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [searched, setSearched] = useState(false);

  async function doSearch(p = 1) {
    if (!query.trim()) return;
    setLoading(true);
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
    } catch (e) {
      console.error(e);
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
    for (const item of items) {
      try {
        await fetch('/api/v1/media/web-import', {
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
      } catch (e) {
        console.error('Import error:', e);
      }
    }
    setImporting(false);
    setSelected(new Set());
    onImported();
    alert(`${items.length} Bild(er) importiert!`);
  }

  const hasPixabayKey = true; // Wird runtime über die API validiert
  const selectedCount = selected.size;

  return (
    <div>
      {/* Suchfeld */}
      <div className="flex gap-3 mb-4">
        <input
          type="text"
          placeholder="z.B. Grüner Veltliner Flasche..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && doSearch(1)}
          className="flex-1 px-3 py-2 border rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-amber-500"
        />
        <button onClick={() => doSearch(1)} disabled={loading || !query.trim()}
          className="px-5 py-2 bg-amber-600 text-white rounded-lg text-sm font-medium hover:bg-amber-700 disabled:opacity-50">
          {loading ? '...' : 'Suchen'}
        </button>
      </div>

      {/* Quelle */}
      <div className="flex gap-4 mb-6">
        <label className="flex items-center gap-2 text-sm cursor-pointer">
          <input type="radio" name="source" checked={source === 'pixabay'}
            onChange={() => setSource('pixabay')} className="accent-amber-600" />
          Pixabay
        </label>
        <label className="flex items-center gap-2 text-sm cursor-pointer">
          <input type="radio" name="source" checked={source === 'pexels'}
            onChange={() => setSource('pexels')} className="accent-amber-600" />
          Pexels
        </label>
      </div>

      {/* Ergebnisse */}
      {loading ? (
        <div className="text-center py-12 text-gray-400">Suche läuft...</div>
      ) : results.length === 0 && searched ? (
        <div className="text-center py-12 text-gray-400">
          <p>Keine Ergebnisse</p>
          <p className="text-xs mt-1">Prüfen Sie ob die API-Keys in .env eingetragen sind</p>
        </div>
      ) : results.length > 0 ? (
        <>
          <p className="text-sm text-gray-500 mb-3">
            {total} Ergebnisse · Seite {page}
          </p>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
            {results.map((r, idx) => (
              <div
                key={r.id}
                onClick={() => toggleSelect(idx)}
                className={`cursor-pointer border-2 rounded-lg overflow-hidden transition-all ${
                  selected.has(idx) ? 'border-amber-500 ring-2 ring-amber-200' : 'border-transparent hover:border-gray-300'
                }`}
              >
                <div className="relative aspect-square bg-gray-100">
                  <img src={r.previewUrl} alt={r.tags} className="w-full h-full object-cover" loading="lazy" />
                  {selected.has(idx) && (
                    <div className="absolute top-2 right-2 w-6 h-6 bg-amber-500 rounded-full flex items-center justify-center text-white text-xs">✓</div>
                  )}
                </div>
                <div className="p-1.5">
                  <p className="text-[10px] text-gray-500 truncate">📷 {r.author} / {source === 'pixabay' ? 'Pixabay' : 'Pexels'}</p>
                  <p className="text-[10px] text-gray-400">{r.width}×{r.height}</p>
                </div>
              </div>
            ))}
          </div>

          {/* Pagination + Import */}
          <div className="flex items-center justify-between mt-6">
            <div className="flex gap-2">
              {page > 1 && (
                <button onClick={() => doSearch(page - 1)} className="px-3 py-1 text-sm border rounded">Zurück</button>
              )}
              <button onClick={() => doSearch(page + 1)} className="px-3 py-1 text-sm border rounded">Weitere</button>
            </div>
            {selectedCount > 0 && (
              <button onClick={importSelected} disabled={importing}
                className="px-5 py-2 bg-amber-600 text-white rounded-lg text-sm font-medium hover:bg-amber-700 disabled:opacity-50">
                {importing ? 'Importiere...' : `${selectedCount} Bild${selectedCount > 1 ? 'er' : ''} ins Archiv übernehmen`}
              </button>
            )}
          </div>

          {/* Lizenz-Info */}
          <p className="text-xs text-gray-400 mt-4 text-center">
            {source === 'pixabay' ? 'Pixabay-Lizenz: Frei für kommerzielle Nutzung, keine Quellenangabe nötig' :
              'Pexels-Lizenz: Frei verwendbar, Quellenangabe empfohlen'}
          </p>
        </>
      ) : null}
    </div>
  );
}
ENDOFFILE

# Ersetze den WebSearchTab Platzhalter in media-archive.tsx
# Erst die alte WebSearchTab-Funktion entfernen, dann die neue einfügen
python3 << 'PYEOF'
import re

with open('src/components/admin/media-archive.tsx', 'r') as f:
    content = f.read()

# Alten WebSearchTab ersetzen
old_pattern = r"// ═══ WebSearchTab \(Platzhalter für Phase 3\) ═══\nfunction WebSearchTab\(\) \{[\s\S]*?^}"
new_tab = open('/tmp/web-search-tab.tsx', 'r').read()

content = re.sub(old_pattern, new_tab.strip(), content, flags=re.MULTILINE)

# onUploaded prop auch für Websuche nutzen - refreshKey update
content = content.replace(
    "{activeTab === 'web' && <WebSearchTab />}",
    "{activeTab === 'web' && <WebSearchTab onImported={() => setRefreshKey(k => k + 1)} />}"
)

with open('src/components/admin/media-archive.tsx', 'w') as f:
    f.write(content)

print("  ✓ WebSearchTab aktualisiert")
PYEOF

echo "  ✓ Websuche-Tab aktiviert"

# ───────────────────────────────────────
echo ""
echo "[BUILD] Kompiliere..."
# ───────────────────────────────────────

npm run build 2>&1 | tail -15

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo ""
  echo "═══════════════════════════════════"
  echo "  ✅ Bildarchiv Phase 3 LIVE!"
  echo "═══════════════════════════════════"
  echo ""
  echo "  Neue Features:"
  echo "  → Websuche (Pixabay + Pexels)"
  echo "  → Web-Import mit Sharp-Verarbeitung"
  echo "  → Suchbegriff-Generierung"
  echo ""
  echo "  ⚠️  API-Keys in .env eintragen:"
  echo "  PIXABAY_API_KEY=xxx"
  echo "  PEXELS_API_KEY=xxx"
  echo ""
else
  echo ""
  echo "  ❌ Build fehlgeschlagen – siehe Fehler oben"
fi
