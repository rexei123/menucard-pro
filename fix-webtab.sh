#!/bin/bash
cd /var/www/menucard-pro

echo "=== WebSearchTab Fix ==="

python3 << 'PYEOF'
with open('src/components/admin/media-archive.tsx', 'r') as f:
    lines = f.readlines()

new_func = r'''function WebSearchTab({ onImported }: { onImported: () => void }) {
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
      <div className="flex flex-wrap gap-4 mb-6">
        <label className="flex items-center gap-2 text-sm cursor-pointer">
          <input type="radio" name="wsource" checked={source === 'wikimedia'}
            onChange={() => setSource('wikimedia')} className="accent-amber-600" />
          <span>Wikimedia Commons <span className="text-xs text-green-600">(frei)</span></span>
        </label>
        {availableSources.filter((s: any) => s.id !== 'wikimedia').map((s: any) => (
          <label key={s.id} className={'flex items-center gap-2 text-sm cursor-pointer ' + (!s.available ? 'opacity-40' : '')}>
            <input type="radio" name="wsource" checked={source === s.id}
              onChange={() => setSource(s.id)} className="accent-amber-600" disabled={!s.available} />
            <span>{s.name} {!s.available && <span className="text-xs text-gray-400">(Key fehlt)</span>}</span>
          </label>
        ))}
      </div>
      {searchError && <div className="mb-4 p-3 bg-yellow-50 border border-yellow-200 rounded-lg text-sm text-yellow-700">{searchError}</div>}
      {loading ? (
        <div className="text-center py-12 text-gray-400">Suche ...</div>
      ) : results.length === 0 && searched ? (
        <div className="text-center py-12 text-gray-400">
          <p>Keine Ergebnisse</p>
          <p className="text-xs mt-1">Tipp: Englische Suchbegriffe liefern mehr Ergebnisse</p>
        </div>
      ) : results.length > 0 ? (
        <>
          <p className="text-sm text-gray-500 mb-3">{total} Ergebnisse - Seite {page}</p>
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
            {results.map((r, idx) => (
              <div key={r.id} onClick={() => toggleSelect(idx)}
                className={'cursor-pointer border-2 rounded-lg overflow-hidden transition-all ' +
                  (selected.has(idx) ? 'border-amber-500 ring-2 ring-amber-200' : 'border-transparent hover:border-gray-300')}>
                <div className="relative aspect-square bg-gray-100">
                  <img src={r.previewUrl} alt={r.tags} className="w-full h-full object-cover" loading="lazy" />
                  {selected.has(idx) && <div className="absolute top-2 right-2 w-6 h-6 bg-amber-500 rounded-full flex items-center justify-center text-white text-xs">+</div>}
                </div>
                <div className="p-1.5">
                  <p className="text-[10px] text-gray-500 truncate">{r.author}</p>
                  <p className="text-[10px] text-gray-400">{r.width}x{r.height}</p>
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
'''

before = lines[:331]
after = lines[494:]
result = before + [new_func + '\n'] + after

with open('src/components/admin/media-archive.tsx', 'w') as f:
    f.writelines(result)

print("Done")
PYEOF

npm run build 2>&1 | tail -5

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo "✅ Websuche mit Wikimedia Commons LIVE!"
else
  echo "❌ Build fehlgeschlagen"
fi
