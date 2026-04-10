'use client';
import { useState, useRef } from 'react';

type ParsedProduct = {
  row: number;
  sku: string;
  type: string;
  group: string;
  nameDe: string;
  nameEn: string;
  fillQuantity: string;
  priceLevel: string;
  price: string;
  winery: string;
  vintage: string;
  country: string;
  brand: string;
  status: 'new' | 'update' | 'error';
  statusMsg: string;
};

type Summary = { total: number; new: number; update: number; error: number };
type ImportResult = { created: number; updated: number; errors: number; total: number };

const statusColors = {
  new: 'bg-green-100 text-green-700',
  update: 'bg-blue-100 text-blue-700',
  error: 'bg-red-100 text-red-700',
};
const statusLabels = { new: 'Neu', update: 'Update', error: 'Fehler' };

export default function CsvImport() {
  const [step, setStep] = useState<'upload' | 'preview' | 'importing' | 'done'>('upload');
  const [products, setProducts] = useState<ParsedProduct[]>([]);
  const [summary, setSummary] = useState<Summary | null>(null);
  const [result, setResult] = useState<ImportResult | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [file, setFile] = useState<File | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    const f = e.dataTransfer.files[0];
    if (f && (f.name.endsWith('.csv') || f.name.endsWith('.txt'))) {
      setFile(f);
      setError('');
    } else {
      setError('Bitte eine CSV-Datei hochladen');
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0];
    if (f) { setFile(f); setError(''); }
  };

  const handlePreview = async () => {
    if (!file) return;
    setLoading(true);
    setError('');
    try {
      const formData = new FormData();
      formData.append('file', file);
      const res = await fetch('/api/v1/import?action=preview', { method: 'POST', body: formData });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Fehler beim Parsen');
      setProducts(data.products);
      setSummary(data.summary);
      setStep('preview');
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  const handleImport = async () => {
    if (!file) return;
    setStep('importing');
    setError('');
    try {
      const formData = new FormData();
      formData.append('file', file);
      const res = await fetch('/api/v1/import?action=execute', { method: 'POST', body: formData });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Fehler beim Import');
      setResult(data);
      setStep('done');
    } catch (e: any) {
      setError(e.message);
      setStep('preview');
    }
  };

  const reset = () => {
    setStep('upload');
    setProducts([]);
    setSummary(null);
    setResult(null);
    setError('');
    setFile(null);
    if (fileRef.current) fileRef.current.value = '';
  };

  return (
    <div className="mx-auto max-w-5xl">
      {/* Header */}
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold" style={{ fontFamily: "'Playfair Display', serif" }}>CSV-Import</h1>
          <p className="mt-1 text-sm text-gray-400">Produkte aus CSV-Datei importieren oder aktualisieren</p>
        </div>
        <a
          href="/templates/import-vorlage.csv"
          download
          className="rounded-lg border px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-50 transition-colors"
        >
          Vorlage herunterladen
        </a>
      </div>

      {error && (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* Step 1: Upload */}
      {step === 'upload' && (
        <div
          onDrop={handleDrop}
          onDragOver={e => e.preventDefault()}
          className="rounded-xl border-2 border-dashed bg-white p-12 text-center transition-colors hover:border-amber-400"
        >
          <div className="text-4xl mb-4">📄</div>
          <p className="text-lg font-medium text-gray-700">CSV-Datei hier ablegen</p>
          <p className="mt-1 text-sm text-gray-400">oder klicken um eine Datei auszuwählen</p>
          <input
            ref={fileRef}
            type="file"
            accept=".csv,.txt"
            onChange={handleFileSelect}
            className="hidden"
          />
          <button
            onClick={() => fileRef.current?.click()}
            className="mt-4 rounded-lg border px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-50"
          >
            Datei auswählen
          </button>
          {file && (
            <div className="mt-4">
              <p className="text-sm font-medium text-gray-700">{file.name} ({(file.size / 1024).toFixed(1)} KB)</p>
              <button
                onClick={handlePreview}
                disabled={loading}
                className="mt-3 rounded-lg px-6 py-2.5 text-sm font-semibold text-white transition-colors"
                style={{ backgroundColor: loading ? '#999' : '#8B6914' }}
              >
                {loading ? 'Wird analysiert...' : 'Vorschau anzeigen'}
              </button>
            </div>
          )}
          <div className="mt-6 border-t pt-4">
            <p className="text-xs text-gray-400">
              Format: CSV mit Semikolon (;) oder Komma als Trenner. Spaltenköpfe auf Deutsch oder Englisch.
              Ein Produkt kann mehrere Zeilen haben (verschiedene Preise/Füllmengen).
            </p>
          </div>
        </div>
      )}

      {/* Step 2: Preview */}
      {step === 'preview' && summary && (
        <div>
          {/* Summary */}
          <div className="mb-4 grid grid-cols-4 gap-3">
            <div className="rounded-lg border bg-white p-4 text-center">
              <p className="text-2xl font-bold">{summary.total}</p>
              <p className="text-xs text-gray-400">Gesamt</p>
            </div>
            <div className="rounded-lg border bg-green-50 p-4 text-center">
              <p className="text-2xl font-bold text-green-700">{summary.new}</p>
              <p className="text-xs text-green-600">Neue Produkte</p>
            </div>
            <div className="rounded-lg border bg-blue-50 p-4 text-center">
              <p className="text-2xl font-bold text-blue-700">{summary.update}</p>
              <p className="text-xs text-blue-600">Aktualisierungen</p>
            </div>
            <div className="rounded-lg border bg-red-50 p-4 text-center">
              <p className="text-2xl font-bold text-red-700">{summary.error}</p>
              <p className="text-xs text-red-600">Fehler</p>
            </div>
          </div>

          {/* Table */}
          <div className="rounded-xl border bg-white overflow-hidden">
            <div className="max-h-[500px] overflow-y-auto">
              <table className="w-full text-sm">
                <thead className="sticky top-0 bg-gray-50 border-b">
                  <tr>
                    <th className="px-3 py-2 text-left font-medium text-gray-500">Status</th>
                    <th className="px-3 py-2 text-left font-medium text-gray-500">SKU</th>
                    <th className="px-3 py-2 text-left font-medium text-gray-500">Typ</th>
                    <th className="px-3 py-2 text-left font-medium text-gray-500">Name</th>
                    <th className="px-3 py-2 text-left font-medium text-gray-500">Preis</th>
                    <th className="px-3 py-2 text-left font-medium text-gray-500">Details</th>
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {products.map((p, i) => (
                    <tr key={i} className={p.status === 'error' ? 'bg-red-50/50' : ''}>
                      <td className="px-3 py-2">
                        <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${statusColors[p.status]}`}>
                          {statusLabels[p.status]}
                        </span>
                      </td>
                      <td className="px-3 py-2 font-mono text-xs">{p.sku}</td>
                      <td className="px-3 py-2">{p.type}</td>
                      <td className="px-3 py-2 font-medium">{p.nameDe}</td>
                      <td className="px-3 py-2 tabular-nums">{p.price ? `${p.price}` : '-'}</td>
                      <td className="px-3 py-2 text-xs text-gray-500 max-w-[200px] truncate">{p.statusMsg}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Actions */}
          <div className="mt-4 flex items-center justify-between">
            <button onClick={reset} className="rounded-lg border px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-50">
              Abbrechen
            </button>
            <div className="flex items-center gap-3">
              {summary.error > 0 && (
                <p className="text-sm text-amber-600">{summary.error} Fehler werden übersprungen</p>
              )}
              <button
                onClick={handleImport}
                disabled={summary.new + summary.update === 0}
                className="rounded-lg px-6 py-2.5 text-sm font-semibold text-white transition-colors"
                style={{ backgroundColor: summary.new + summary.update > 0 ? '#8B6914' : '#999' }}
              >
                {summary.new + summary.update} Produkte importieren
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Step 3: Importing */}
      {step === 'importing' && (
        <div className="rounded-xl border bg-white p-12 text-center">
          <div className="text-4xl mb-4 animate-pulse">⏳</div>
          <p className="text-lg font-medium text-gray-700">Import läuft...</p>
          <p className="mt-1 text-sm text-gray-400">Bitte warten, Produkte werden verarbeitet.</p>
        </div>
      )}

      {/* Step 4: Done */}
      {step === 'done' && result && (
        <div className="rounded-xl border bg-white p-12 text-center">
          <div className="text-4xl mb-4">✅</div>
          <p className="text-lg font-medium text-gray-700">Import abgeschlossen</p>
          <div className="mt-4 inline-flex gap-6">
            {result.created > 0 && <div><span className="text-2xl font-bold text-green-600">{result.created}</span><p className="text-xs text-gray-400">Neu erstellt</p></div>}
            {result.updated > 0 && <div><span className="text-2xl font-bold text-blue-600">{result.updated}</span><p className="text-xs text-gray-400">Aktualisiert</p></div>}
            {result.errors > 0 && <div><span className="text-2xl font-bold text-red-600">{result.errors}</span><p className="text-xs text-gray-400">Fehler</p></div>}
          </div>
          <div className="mt-6 flex justify-center gap-3">
            <button onClick={reset} className="rounded-lg border px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-50">
              Weiteren Import starten
            </button>
            <a href="/admin/items" className="rounded-lg px-4 py-2 text-sm font-semibold text-white" style={{ backgroundColor: '#8B6914' }}>
              Zu den Produkten
            </a>
          </div>
        </div>
      )}
    </div>
  );
}
