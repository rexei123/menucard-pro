#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Fix: Websuche v2 – Wikimedia (frei) + Google Bilder (frei)
# ═══════════════════════════════════════════════════════════════
cd /var/www/menucard-pro

echo "=== Websuche v2 ==="

# Komplett neue web-search Route
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

// ═══ Google Custom Search (100 Suchen/Tag kostenlos) ═══
async function searchGoogle(query: string, page: number): Promise<{ results: SearchResult[]; total: number }> {
  const key = process.env.GOOGLE_SEARCH_KEY;
  const cx = process.env.GOOGLE_SEARCH_CX;
  if (!key || !cx) return { results: [], total: 0 };
  const start = (page - 1) * 10 + 1;
  const url = `https://www.googleapis.com/customsearch/v1?key=${key}&cx=${cx}&q=${encodeURIComponent(query)}&searchType=image&num=10&start=${start}`;
  try {
    const res = await fetch(url, { cache: 'no-store' });
    if (!res.ok) return { results: [], total: 0 };
    const data = await res.json();
    return {
      total: data.searchInformation?.totalResults ? parseInt(data.searchInformation.totalResults) : 0,
      results: (data.items || []).map((item: any, i: number) => ({
        id: `google-${start + i}`,
        previewUrl: item.image?.thumbnailLink || item.link,
        fullUrl: item.link,
        width: item.image?.width || 0,
        height: item.image?.height || 0,
        author: item.displayLink || 'Web',
        sourceUrl: item.image?.contextLink || item.link,
        tags: item.title || item.snippet || '',
        license: 'Web',
      })),
    };
  } catch (e) {
    console.error('Google search error:', e);
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
  { id: 'wikimedia', name: 'Wikimedia Commons (frei)', available: true },
  { id: 'google', name: 'Google Bilder', available: !!(process.env.GOOGLE_SEARCH_KEY && process.env.GOOGLE_SEARCH_CX) },
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
    case 'google':
      data = await searchGoogle(query, p);
      if (data.results.length === 0 && !process.env.GOOGLE_SEARCH_KEY) {
        return NextResponse.json({ results: [], total: 0, error: 'Google API-Key nicht konfiguriert', sources: getAvailableSources() });
      }
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
    default:
      data = await searchWikimedia(query, p);
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

echo "  ✓ Web-Search API (Wikimedia + Google + Pixabay + Pexels)"

# ───────────────────────────────────────
echo "[2/2] Build..."
# ───────────────────────────────────────

npm run build 2>&1 | tail -5

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo ""
  echo "═══════════════════════════════════"
  echo "  ✅ Websuche v2 LIVE!"
  echo "═══════════════════════════════════"
  echo ""
  echo "  Quellen:"
  echo "  → Wikimedia Commons (sofort, kein Key)"
  echo "  → Google Bilder (GOOGLE_SEARCH_KEY + GOOGLE_SEARCH_CX in .env)"
  echo "  → Pixabay (optional)"
  echo "  → Pexels (optional)"
  echo ""
else
  echo "  ❌ Build fehlgeschlagen"
fi
