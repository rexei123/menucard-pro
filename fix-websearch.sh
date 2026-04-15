#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Fix: Freie Websuche (Wikimedia Commons – kein API-Key nötig)
# + Pixabay/Pexels bleiben als optionale Quellen
# ═══════════════════════════════════════════════════════════════
cd /var/www/menucard-pro

echo "=== Websuche Fix ==="
echo ""

# ───────────────────────────────────────
echo "[1/3] Web-Search API erweitern (Wikimedia Commons)..."
# ───────────────────────────────────────

cp src/app/api/v1/media/web-search/route.ts src/app/api/v1/media/web-search/route.ts.bak 2>/dev/null

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
  license: string;
}

// ═══ Wikimedia Commons (KEINE API-Key nötig!) ═══
async function searchWikimedia(query: string, page: number): Promise<{ results: SearchResult[]; total: number }> {
  const offset = (page - 1) * 20;
  const url = `https://commons.wikimedia.org/w/api.php?action=query&generator=search&gsrsearch=${encodeURIComponent(query + ' filetype:bitmap')}&gsrnamespace=6&gsrlimit=20&gsroffset=${offset}&prop=imageinfo&iiprop=url|size|user|extmetadata&iiurlwidth=640&format=json&origin=*`;

  try {
    const res = await fetch(url);
    if (!res.ok) return { results: [], total: 0 };
    const data = await res.json();

    const pages = data.query?.pages || {};
    const results: SearchResult[] = [];

    for (const pageId of Object.keys(pages)) {
      const p = pages[pageId];
      const info = p.imageinfo?.[0];
      if (!info) continue;

      // Nur echte Bilder (keine SVGs, PDFs etc.)
      const mime = info.mime || '';
      if (!mime.startsWith('image/') || mime === 'image/svg+xml') continue;

      const ext = info.descriptionurl || '';
      const artist = info.extmetadata?.Artist?.value?.replace(/<[^>]*>/g, '') || info.user || 'Unbekannt';
      const license = info.extmetadata?.LicenseShortName?.value || 'CC';

      results.push({
        id: `wiki-${pageId}`,
        previewUrl: info.thumburl || info.url,
        fullUrl: info.url,
        width: info.width || 0,
        height: info.height || 0,
        author: artist.substring(0, 60),
        sourceUrl: info.descriptionurl || `https://commons.wikimedia.org/wiki/File:${p.title?.replace('File:', '')}`,
        tags: p.title?.replace('File:', '').replace(/\.[^.]+$/, '').replace(/_/g, ' ') || '',
        license,
      });
    }

    // Total ist geschätzt (Wikimedia gibt keine genaue Gesamtzahl)
    const searchInfo = data.query?.searchinfo;
    const total = searchInfo?.totalhits || results.length * 5;

    return { results, total };
  } catch (e) {
    console.error('Wikimedia search error:', e);
    return { results: [], total: 0 };
  }
}

// ═══ Pixabay (API-Key erforderlich) ═══
async function searchPixabay(query: string, page: number): Promise<{ results: SearchResult[]; total: number }> {
  const key = process.env.PIXABAY_API_KEY;
  if (!key) return { results: [], total: 0 };

  const url = `https://pixabay.com/api/?key=${key}&q=${encodeURIComponent(query)}&image_type=photo&per_page=20&page=${page}&lang=de`;
  try {
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
        license: 'Pixabay License',
      })),
    };
  } catch { return { results: [], total: 0 }; }
}

// ═══ Pexels (API-Key erforderlich) ═══
async function searchPexels(query: string, page: number): Promise<{ results: SearchResult[]; total: number }> {
  const key = process.env.PEXELS_API_KEY;
  if (!key) return { results: [], total: 0 };

  const url = `https://api.pexels.com/v1/search?query=${encodeURIComponent(query)}&per_page=20&page=${page}&locale=de-DE`;
  try {
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
        license: 'Pexels License',
      })),
    };
  } catch { return { results: [], total: 0 }; }
}

// ═══ Verfügbare Quellen prüfen ═══
function getAvailableSources(): { id: string; name: string; available: boolean }[] {
  return [
    { id: 'wikimedia', name: 'Wikimedia Commons (frei)', available: true },
    { id: 'pixabay', name: 'Pixabay', available: !!process.env.PIXABAY_API_KEY },
    { id: 'pexels', name: 'Pexels', available: !!process.env.PEXELS_API_KEY },
  ];
}

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { query, source, page } = await req.json();
  if (!query) return NextResponse.json({ error: 'Query required' }, { status: 400 });

  const p = page || 1;
  let data;

  switch (source) {
    case 'pixabay':
      data = await searchPixabay(query, p);
      if (data.results.length === 0 && !process.env.PIXABAY_API_KEY) {
        return NextResponse.json({ results: [], total: 0, error: 'Pixabay API-Key nicht konfiguriert' });
      }
      break;
    case 'pexels':
      data = await searchPexels(query, p);
      if (data.results.length === 0 && !process.env.PEXELS_API_KEY) {
        return NextResponse.json({ results: [], total: 0, error: 'Pexels API-Key nicht konfiguriert' });
      }
      break;
    case 'wikimedia':
    default:
      data = await searchWikimedia(query, p);
      break;
  }

  return NextResponse.json({ ...data, sources: getAvailableSources() });
}

// GET: Verfügbare Quellen abfragen
export async function GET(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  return NextResponse.json({ sources: getAvailableSources() });
}
ENDOFFILE

echo "  ✓ Web-Search API mit Wikimedia Commons"

# ───────────────────────────────────────
echo "[2/3] Websuche-Tab im UI aktualisieren..."
# ───────────────────────────────────────

# Ersetze den WebSearchTab in media-archive.tsx
python3 << 'PYEOF'
import re

with open('src/components/admin/media-archive.tsx', 'r') as f:
    content = f.read()

# Finde und ersetze die komplette WebSearchTab Funktion
# Suche nach dem Funktionsbeginn und Ende
pattern = r'function WebSearchTab\([^)]*\)\s*\{[\s\S]*?^}'
match = re.search(pattern, content, re.MULTILINE)

if match:
    new_web_tab = '''function WebSearchTab({ onImported }: { onImported: () => void }) {
  const [query, setQuery] = useState('');
  const [source, setSource] = useState<string>('wikimedia');
  const [results, setResults] = useState<any[]>([]);
  const [selected, setSelected] = useState<Set<number>>(new Set());
  const [loading, setLoading] = useState(false);
  const [importing, setImporting] = useState(false);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [searched, setSearched] = useState(false);
  const [searchError, setSearchError] = useState('');
  const [availableSources, setAvailableSources] = useState<any[]>([]);

  // Verfügbare Quellen laden
  useEffect(() => {
    fetch('/api/v1/media/web-search')
      .then(r => r.json())
      .then(data => {
        if (data.sources) setAvailableSources(data.sources);
      })
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
      console.error(e);
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
      } catch (e) {
        console.error('Import error:', e);
      }
    }
    setImporting(false);
    setSelected(new Set());
    if (ok > 0) onImported();
    alert(ok + ' Bild' + (ok > 1 ? 'er' : '') + ' importiert!');
  }

  const selectedCount = selected.size;
  const sourceLabels: Record<string, string> = {
    wikimedia: 'Wikimedia Commons',
    pixabay: 'Pixabay',
    pexels: 'Pexels',
  };

  return (
    <div>
      {/* Suchfeld */}
      <div className="flex gap-3 mb-4">
        <input
          type="text"
          placeholder="z.B. Grüner Veltliner Flasche, Hotel Restaurant..."
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

      {/* Quellen */}
      <div className="flex flex-wrap gap-4 mb-6">
        <label className="flex items-center gap-2 text-sm cursor-pointer">
          <input type="radio" name="wsource" checked={source === 'wikimedia'}
            onChange={() => setSource('wikimedia')} className="accent-amber-600" />
          <span>🌐 Wikimedia Commons <span className="text-xs text-green-600">(frei)</span></span>
        </label>
        <label className={'flex items-center gap-2 text-sm cursor-pointer ' + (availableSources.find((s: any) => s.id === 'pixabay')?.available ? '' : 'opacity-40')}>
          <input type="radio" name="wsource" checked={source === 'pixabay'}
            onChange={() => setSource('pixabay')} className="accent-amber-600"
            disabled={!availableSources.find((s: any) => s.id === 'pixabay')?.available} />
          <span>Pixabay {!availableSources.find((s: any) => s.id === 'pixabay')?.available && <span className="text-xs text-gray-400">(Key fehlt)</span>}</span>
        </label>
        <label className={'flex items-center gap-2 text-sm cursor-pointer ' + (availableSources.find((s: any) => s.id === 'pexels')?.available ? '' : 'opacity-40')}>
          <input type="radio" name="wsource" checked={source === 'pexels'}
            onChange={() => setSource('pexels')} className="accent-amber-600"
            disabled={!availableSources.find((s: any) => s.id === 'pexels')?.available} />
          <span>Pexels {!availableSources.find((s: any) => s.id === 'pexels')?.available && <span className="text-xs text-gray-400">(Key fehlt)</span>}</span>
        </label>
      </div>

      {searchError && (
        <div className="mb-4 p-3 bg-yellow-50 border border-yellow-200 rounded-lg text-sm text-yellow-700">
          {searchError}
        </div>
      )}

      {/* Ergebnisse */}
      {loading ? (
        <div className="text-center py-12 text-gray-400">Suche läuft...</div>
      ) : results.length === 0 && searched ? (
        <div className="text-center py-12 text-gray-400">
          <p>Keine Ergebnisse für diese Suche</p>
          <p className="text-xs mt-1">Versuchen Sie andere Suchbegriffe (am besten auf Englisch)</p>
        </div>
      ) : results.length > 0 ? (
        <>
          <p className="text-sm text-gray-500 mb-3">
            {total > 0 ? total + ' Ergebnisse' : results.length + ' Treffer'} · Seite {page} · {sourceLabels[source] || source}
          </p>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
            {results.map((r, idx) => (
              <div
                key={r.id}
                onClick={() => toggleSelect(idx)}
                className={'cursor-pointer border-2 rounded-lg overflow-hidden transition-all ' +
                  (selected.has(idx) ? 'border-amber-500 ring-2 ring-amber-200' : 'border-transparent hover:border-gray-300')}
              >
                <div className="relative aspect-square bg-gray-100">
                  <img src={r.previewUrl} alt={r.tags} className="w-full h-full object-cover" loading="lazy" />
                  {selected.has(idx) && (
                    <div className="absolute top-2 right-2 w-6 h-6 bg-amber-500 rounded-full flex items-center justify-center text-white text-xs font-bold">✓</div>
                  )}
                </div>
                <div className="p-1.5">
                  <p className="text-[10px] text-gray-500 truncate" title={r.author}>📷 {r.author}</p>
                  <p className="text-[10px] text-gray-400">{r.width}×{r.height} · {r.license}</p>
                </div>
              </div>
            ))}
          </div>

          {/* Pagination + Import */}
          <div className="flex items-center justify-between mt-6">
            <div className="flex gap-2">
              {page > 1 && (
                <button onClick={() => doSearch(page - 1)} className="px-3 py-1 text-sm border rounded hover:bg-gray-50">Zurück</button>
              )}
              <button onClick={() => doSearch(page + 1)} className="px-3 py-1 text-sm border rounded hover:bg-gray-50">Weitere</button>
            </div>
            {selectedCount > 0 && (
              <button onClick={importSelected} disabled={importing}
                className="px-5 py-2 bg-amber-600 text-white rounded-lg text-sm font-medium hover:bg-amber-700 disabled:opacity-50">
                {importing ? 'Importiere...' : selectedCount + ' Bild' + (selectedCount > 1 ? 'er' : '') + ' ins Archiv übernehmen'}
              </button>
            )}
          </div>

          {/* Lizenz-Info */}
          <p className="text-xs text-gray-400 mt-4 text-center">
            {source === 'wikimedia' ? 'Wikimedia Commons – Lizenz je Bild beachten (meist CC BY-SA oder gemeinfrei)' :
             source === 'pixabay' ? 'Pixabay-Lizenz: Frei für kommerzielle Nutzung' :
             'Pexels-Lizenz: Frei verwendbar, Quellenangabe empfohlen'}
          </p>
        </>
      ) : null}
    </div>
  );
}'''

    content = content[:match.start()] + new_web_tab + content[match.end():]

    # Sicherstellen dass der WebSearchTab mit onImported aufgerufen wird
    content = content.replace(
        "<WebSearchTab />",
        "<WebSearchTab onImported={() => setRefreshKey(k => k + 1)} />"
    )

    with open('src/components/admin/media-archive.tsx', 'w') as f:
        f.write(content)
    print("  ✓ WebSearchTab aktualisiert (Wikimedia als Default)")
else:
    print("  ⚠️ WebSearchTab nicht gefunden – manuelles Update nötig")
PYEOF

echo "  ✓ UI aktualisiert"

# ───────────────────────────────────────
echo "[3/3] Build & Deploy..."
# ───────────────────────────────────────

npm run build 2>&1 | tail -5

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo ""
  echo "═══════════════════════════════════"
  echo "  ✅ Websuche Fix LIVE!"
  echo "═══════════════════════════════════"
  echo ""
  echo "  Quellen:"
  echo "  → 🌐 Wikimedia Commons (frei, kein Key)"
  echo "  → Pixabay (optional, Key in .env)"
  echo "  → Pexels (optional, Key in .env)"
  echo ""
else
  echo ""
  echo "  ❌ Build fehlgeschlagen – siehe Fehler oben"
fi
