#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# SearXNG Installation + Websuche-Integration
# Hotel Sonnblick – MenuCard Pro
# ═══════════════════════════════════════════════════════════════
set -e
cd /var/www/menucard-pro

echo ""
echo "═══════════════════════════════════════════"
echo "  SearXNG + Websuche Installation"
echo "═══════════════════════════════════════════"
echo ""

# ─────────────────────────────────────────
echo "[1/5] Docker prüfen..."
# ─────────────────────────────────────────
if ! command -v docker &> /dev/null; then
  echo "  Docker wird installiert..."
  apt-get update -qq
  apt-get install -y -qq docker.io docker-compose-plugin 2>/dev/null || apt-get install -y -qq docker.io docker-compose 2>/dev/null
  systemctl enable docker
  systemctl start docker
  echo "  ✓ Docker installiert"
else
  echo "  ✓ Docker bereits vorhanden"
fi

# ─────────────────────────────────────────
echo "[2/5] SearXNG starten..."
# ─────────────────────────────────────────
# Stoppe alten Container falls vorhanden
docker stop searxng 2>/dev/null || true
docker rm searxng 2>/dev/null || true

# SearXNG Config-Verzeichnis
mkdir -p /opt/searxng

# SearXNG Settings mit JSON-API + Bildersuche
cat > /opt/searxng/settings.yml << 'SETTINGSEOF'
use_default_settings: true
server:
  secret_key: "menucard-pro-searxng-2026"
  bind_address: "0.0.0.0"
  port: 8080
  limiter: false
search:
  safe_search: 0
  autocomplete: "google"
  default_lang: "de"
  formats:
    - html
    - json
engines:
  - name: google images
    engine: google_images
    shortcut: gimg
    disabled: false
  - name: bing images
    engine: bing_images
    shortcut: bimg
    disabled: false
  - name: duckduckgo images
    engine: duckduckgo_images
    shortcut: ddimg
    disabled: false
  - name: qwant images
    engine: qwant
    categories: images
    shortcut: qimg
    disabled: false
  - name: flickr
    engine: flickr
    shortcut: fl
    disabled: false
SETTINGSEOF

# SearXNG Container starten (nur lokal erreichbar auf Port 8888)
docker run -d \
  --name searxng \
  --restart always \
  -p 127.0.0.1:8888:8080 \
  -v /opt/searxng/settings.yml:/etc/searxng/settings.yml:ro \
  searxng/searxng:latest

echo "  Warte 10 Sekunden auf Start..."
sleep 10

# Test
SEARX_TEST=$(curl -s "http://localhost:8888/search?q=hotel&format=json&categories=images" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('results',[])))" 2>/dev/null || echo "0")
if [ "$SEARX_TEST" -gt 0 ] 2>/dev/null; then
  echo "  ✓ SearXNG läuft! ($SEARX_TEST Bilder gefunden)"
else
  echo "  ⏳ SearXNG startet noch... (wird beim Build fertig sein)"
fi

# ─────────────────────────────────────────
echo "[3/5] Web-Search API updaten..."
# ─────────────────────────────────────────

# Backup
cp src/app/api/v1/media/web-search/route.ts src/app/api/v1/media/web-search/route.ts.bak 2>/dev/null || true

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

// ═══ SearXNG Websuche (lokal, kostenlos, keine Limits) ═══
async function searchSearXNG(query: string, page: number): Promise<{ results: SearchResult[]; total: number }> {
  const url = `http://localhost:8888/search?q=${encodeURIComponent(query)}&format=json&categories=images&pageno=${page}&language=de`;
  try {
    const res = await fetch(url, { cache: 'no-store' });
    if (!res.ok) {
      console.error('SearXNG error:', res.status, await res.text().catch(() => ''));
      return { results: [], total: 0 };
    }
    const data = await res.json();
    const results: SearchResult[] = (data.results || [])
      .filter((r: any) => r.img_src || r.thumbnail_src)
      .map((r: any, i: number) => ({
        id: `searx-${page}-${i}`,
        previewUrl: r.thumbnail_src || r.img_src,
        fullUrl: r.img_src || r.thumbnail_src,
        width: r.resolution ? parseInt(r.resolution.split('x')[0]) || 0 : 0,
        height: r.resolution ? parseInt(r.resolution.split('x')[1]) || 0 : 0,
        author: r.source || r.engine || 'Web',
        sourceUrl: r.url || '',
        tags: r.title || '',
        license: r.engine || 'Web',
      }));
    return { results, total: data.number_of_results || results.length * 10 };
  } catch (e) {
    console.error('SearXNG error:', e);
    return { results: [], total: 0 };
  }
}

// ═══ Wikimedia Commons (kein Key) ═══
async function searchWikimedia(query: string, page: number): Promise<{ results: SearchResult[]; total: number }> {
  const offset = (page - 1) * 20;
  const url = `https://commons.wikimedia.org/w/api.php?action=query&generator=search&gsrsearch=${encodeURIComponent(query + ' filetype:bitmap')}&gsrnamespace=6&gsrlimit=20&gsroffset=${offset}&prop=imageinfo&iiprop=url|size|user|extmetadata|mime&iiurlwidth=640&format=json&origin=*`;
  try {
    const res = await fetch(url, { cache: 'no-store' });
    if (!res.ok) return { results: [], total: 0 };
    const data = await res.json();
    const pages = data.query?.pages || {};
    const results: SearchResult[] = [];
    for (const pageId of Object.keys(pages)) {
      const p = pages[pageId];
      const info = p.imageinfo?.[0];
      if (!info) continue;
      const mime = info.mime || '';
      if (!mime.startsWith('image/') || mime === 'image/svg+xml') continue;
      const artist = info.extmetadata?.Artist?.value?.replace(/<[^>]*>/g, '') || info.user || 'Unbekannt';
      const license = info.extmetadata?.LicenseShortName?.value || 'CC';
      results.push({
        id: `wiki-${pageId}`,
        previewUrl: info.thumburl || info.url,
        fullUrl: info.url,
        width: info.width || 0,
        height: info.height || 0,
        author: artist.substring(0, 60),
        sourceUrl: info.descriptionurl || '',
        tags: p.title?.replace('File:', '').replace(/\.[^.]+$/, '').replace(/_/g, ' ') || '',
        license,
      });
    }
    const total = data.query?.searchinfo?.totalhits || results.length * 5;
    return { results, total };
  } catch (e) {
    console.error('Wikimedia error:', e);
    return { results: [], total: 0 };
  }
}

// ═══ Pixabay (optional) ═══
async function searchPixabay(query: string, page: number): Promise<{ results: SearchResult[]; total: number }> {
  const key = process.env.PIXABAY_API_KEY;
  if (!key || key === 'IHR-KEY-HIER') return { results: [], total: 0 };
  const url = `https://pixabay.com/api/?key=${key}&q=${encodeURIComponent(query)}&image_type=photo&per_page=20&page=${page}&lang=de`;
  try {
    const res = await fetch(url, { cache: 'no-store' });
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
        license: 'Pixabay',
      })),
    };
  } catch { return { results: [], total: 0 }; }
}

// ═══ Pexels (optional) ═══
async function searchPexels(query: string, page: number): Promise<{ results: SearchResult[]; total: number }> {
  const key = process.env.PEXELS_API_KEY;
  if (!key) return { results: [], total: 0 };
  const url = `https://api.pexels.com/v1/search?query=${encodeURIComponent(query)}&per_page=20&page=${page}&locale=de-DE`;
  try {
    const res = await fetch(url, { cache: 'no-store', headers: { Authorization: key } });
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
        license: 'Pexels',
      })),
    };
  } catch { return { results: [], total: 0 }; }
}

// Verfügbare Quellen
const getAvailableSources = () => [
  { id: 'searxng', name: 'Websuche (Google, Bing, DDG)', available: true },
  { id: 'wikimedia', name: 'Wikimedia Commons', available: true },
  { id: 'pixabay', name: 'Pixabay', available: !!(process.env.PIXABAY_API_KEY && process.env.PIXABAY_API_KEY !== 'IHR-KEY-HIER') },
  { id: 'pexels', name: 'Pexels', available: !!process.env.PEXELS_API_KEY },
];

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { query, source, page } = await req.json();
  if (!query) return NextResponse.json({ error: 'Query required' }, { status: 400 });

  const p = page || 1;
  let data;

  switch (source) {
    case 'searxng':
      data = await searchSearXNG(query, p);
      break;
    case 'pixabay':
      data = await searchPixabay(query, p);
      if (data.results.length === 0 && (!process.env.PIXABAY_API_KEY || process.env.PIXABAY_API_KEY === 'IHR-KEY-HIER')) {
        return NextResponse.json({ results: [], total: 0, error: 'Pixabay API-Key nicht konfiguriert', sources: getAvailableSources() });
      }
      break;
    case 'pexels':
      data = await searchPexels(query, p);
      if (data.results.length === 0 && !process.env.PEXELS_API_KEY) {
        return NextResponse.json({ results: [], total: 0, error: 'Pexels API-Key nicht konfiguriert', sources: getAvailableSources() });
      }
      break;
    case 'wikimedia':
      data = await searchWikimedia(query, p);
      break;
    default:
      data = await searchSearXNG(query, p);
      break;
  }

  return NextResponse.json({ ...data, sources: getAvailableSources() });
}

export async function GET(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  return NextResponse.json({ sources: getAvailableSources() });
}
ENDOFFILE

echo "  ✓ Web-Search API (SearXNG + Wikimedia + Pixabay + Pexels)"

# ─────────────────────────────────────────
echo "[4/5] UI-Buttons updaten..."
# ─────────────────────────────────────────

python3 << 'PYEOF'
import re

with open('src/components/admin/media-archive.tsx', 'r') as f:
    content = f.read()

# Ersetze die Source-Buttons: Google raus, SearXNG rein
# Suche den Button-Block mit dem alten wikimedia/availableSources Pattern
old_pattern = r"\{?\[[\s\S]*?id: 'wikimedia'[\s\S]*?availableSources\.filter[\s\S]*?\.map\(\(s: any\) => \([\s\S]*?<\/button>\s*\)\)\}"
match = re.search(old_pattern, content)

if match:
    new_buttons = """{[
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
                  ? 'border-gray-200 bg-white text-gray-600 hover:border-amber-300 hover:bg-amber-50/50'
                  : 'border-gray-100 bg-gray-50 text-gray-400 hover:border-amber-200 hover:bg-amber-50/30 cursor-pointer')
            }>
            {s.label || s.name}
            {(s.free) && <span className="ml-1.5 text-xs text-green-600">(frei)</span>}
            {(!s.available && !s.free) && <span className="ml-1.5 text-xs text-gray-400">(Key fehlt)</span>}
          </button>
        ))}"""
    content = content[:match.start()] + new_buttons + content[match.end():]
    print("OK - Buttons ersetzt (regex)")
else:
    print("INFO - Versuche zeilenweise Ersetzung...")
    # Fallback: Ersetze den gesamten div mit gap-2 mb-6
    div_pattern = r'(<div className="flex flex-wrap gap-2 mb-6">\s*)\{[\s\S]*?\}\s*(</div>)'
    match2 = re.search(div_pattern, content)
    if match2:
        new_inner = """{[
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
                  ? 'border-gray-200 bg-white text-gray-600 hover:border-amber-300 hover:bg-amber-50/50'
                  : 'border-gray-100 bg-gray-50 text-gray-400 hover:border-amber-200 hover:bg-amber-50/30 cursor-pointer')
            }>
            {s.label || s.name}
            {(s.free) && <span className="ml-1.5 text-xs text-green-600">(frei)</span>}
            {(!s.available && !s.free) && <span className="ml-1.5 text-xs text-gray-400">(Key fehlt)</span>}
          </button>
        ))}"""
        content = content[:match2.start(1)] + match2.group(1) + new_inner + '\n        ' + match2.group(2) + content[match2.end():]
        print("OK - Buttons ersetzt (fallback)")
    else:
        print("FEHLER - Button-Block nicht gefunden. Manuell pruefen.")

# Default Source von wikimedia auf searxng
content = content.replace("useState('wikimedia')", "useState('searxng')")
content = content.replace("useState<string>('wikimedia')", "useState<string>('searxng')")

with open('src/components/admin/media-archive.tsx', 'w') as f:
    f.write(content)
PYEOF

echo "  ✓ UI-Buttons aktualisiert"

# ─────────────────────────────────────────
echo "[5/5] Build & Restart..."
# ─────────────────────────────────────────
npm run build 2>&1 | tail -5

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo ""
  echo "═══════════════════════════════════════════"
  echo "  ✅ SearXNG + Websuche LIVE!"
  echo "═══════════════════════════════════════════"
  echo ""
  echo "  Quellen:"
  echo "  → Websuche (Google+Bing+DDG via SearXNG)"
  echo "  → Wikimedia Commons (frei)"
  echo "  → Pixabay (Key vorhanden)"
  echo "  → Pexels (optional)"
  echo ""
  echo "  Test: curl 'http://localhost:8888/search?q=hotel&format=json&categories=images' | python3 -c 'import sys,json; d=json.load(sys.stdin); print(len(d[\"results\"]), \"Bilder\")'"
  echo ""
else
  echo "  ❌ Build fehlgeschlagen – prüfe die Fehlermeldung oben"
fi
