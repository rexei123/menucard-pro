'use client';
import { useState, useRef, useCallback } from 'react';

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
type AutoCreate = { fillQuantities: string[]; productGroups: string[] };

const statusColors = {
  new: 'bg-green-100 text-green-700',
  update: 'bg-blue-100 text-blue-700',
  error: 'bg-red-100 text-red-700',
};
const statusLabels = { new: 'Neu', update: 'Update', error: 'Fehler' };

const fieldToCsvCol: Record<string, string[]> = {
  type: ['type', 'typ'],
  nameDe: ['name_de', 'name', 'bezeichnung'],
  nameEn: ['name_en', 'name_english'],
  fillQuantity: ['fill_quantity', 'fuellmenge', 'menge'],
  price: ['price', 'preis', 'vk'],
  group: ['group', 'gruppe', 'produktgruppe', 'kategorie'],
};

function applyCsvEdits(rawText: string, edits: Record<string, Record<string, string>>): string {
  const lines = rawText.split(/\r?\n/);
  if (lines.length < 2) return rawText;

  const headerLine = lines[0];
  const headers = headerLine.split(/[;,]/).map(h => h.trim().toLowerCase().replace(/\s+/g, '_'));
  const delimiter = headerLine.includes(';') ? ';' : ',';

  const skuIdx = headers.findIndex(h => ['sku', 'artikelnr', 'artikelnummer'].includes(h));
  if (skuIdx === -1) return rawText;

  for (let i = 1; i < lines.length; i++) {
    if (!lines[i].trim()) continue;
    const cols = lines[i].split(delimiter);
    const sku = cols[skuIdx]?.trim();
    if (!sku || !edits[sku]) continue;

    for (const [field, value] of Object.entries(edits[sku])) {
      const possibleHeaders = fieldToCsvCol[field] || [field];
      const colIdx = headers.findIndex(h => possibleHeaders.includes(h));
      if (colIdx !== -1 && colIdx < cols.length) {
        cols[colIdx] = value;
      }
    }
    lines[i] = cols.join(delimiter);
  }

  return lines.join('\n');
}

// EditableCell as a proper top-level component to prevent focus loss
function EditableCell({ sku, field, value, editedValue, isError, onEdit, className = '' }: {
  sku: string; field: string; value: string; editedValue: string; isError: boolean;
  onEdit: (sku: string, field: string, value: string) => void; className?: string;
}) {
  const wasEdited = editedValue !== value;

  if (!isError && !wasEdited) {
    return <span className={className}>{value}</span>;
  }

  if (field === 'type') {
    return (
      <select
        value={editedValue}
        onChange={e => onEdit(sku, field, e.target.value)}
        className={`rounded border px-1.5 py-0.5 text-sm font-medium ${wasEdited ? 'border-amber-400 bg-amber-50' : 'border-red-300 bg-red-50'}`}
      >
        {!['WINE', 'DRINK', 'FOOD'].includes(value) && <option value={value}>{value} (ungueltig)</option>}
        <option value="WINE">WINE</option>
        <option value="DRINK">DRINK</option>
        <option value="FOOD">FOOD</option>
      </select>
    );
  }

  return (
    <input
      type="text"
      defaultValue={editedValue}
      onBlur={e => {
        if (e.target.value !== editedValue) {
          onEdit(sku, field, e.target.value);
        }
      }}
      onKeyDown={e => {
        if (e.key === 'Enter') {
          (e.target as HTMLInputElement).blur();
        }
      }}
      placeholder={field === 'nameDe' ? 'Name eingeben...' : ''}
      className={`w-full rounded border px-1.5 py-0.5 text-sm ${wasEdited ? 'border-amber-400 bg-amber-50' : 'border-red-300 bg-red-50'} ${className}`}
    />
  );
}

export default function CsvImport() {
  const [step, setStep] = useState<'upload' | 'preview' | 'importing' | 'done'>('upload');
  const [products, setProducts] = useState<ParsedProduct[]>([]);
  const [summary, setSummary] = useState<Summary | null>(null);
  const [autoCreate, setAutoCreate] = useState<AutoCreate | null>(null);
  const [result, setResult] = useState<ImportResult | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [file, setFile] = useState<File | null>(null);
  const [rawText, setRawText] = useState('');
  const [edits, setEdits] = useState<Record<string, Record<string, string>>>({});
  const [hasEdits, setHasEdits] = useState(false);
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

  const sendPreview = useCallback(async (csvText: string, fileName: string) => {
    setLoading(true);
    setError('');
    try {
      const blob = new Blob([csvText], { type: 'text/csv' });
      const formData = new FormData();
      formData.append('file', blob, fileName);
      const res = await fetch('/api/v1/import?action=preview', { method: 'POST', body: formData });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Fehler beim Parsen');
      setProducts(data.products);
      setSummary(data.summary);
      setAutoCreate(data.autoCreate || null);
      setStep('preview');
      setEdits({});
      setHasEdits(false);
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, []);

  const handlePreview = async () => {
    if (!file) return;
    const text = await file.text();
    setRawText(text);
    await sendPreview(text, file.name);
  };

  const handleRevalidate = async () => {
    const correctedText = applyCsvEdits(rawText, edits);
    setRawText(correctedText);
    await sendPreview(correctedText, file?.name || 'import.csv');
  };

  const handleImport = async () => {
    setStep('importing');
    setError('');
    try {
      const blob = new Blob([rawText], { type: 'text/csv' });
      const formData = new FormData();
      formData.append('file', blob, file?.name || 'import.csv');
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

  const handleCellEdit = useCallback((sku: string, field: string, value: string) => {
    setEdits(prev => ({
      ...prev,
      [sku]: { ...(prev[sku] || {}), [field]: value },
    }));
    setHasEdits(true);
  }, []);

  const getEditedValue = (sku: string, field: string, original: string): string => {
    return edits[sku]?.[field] ?? original;
  };

  const reset = () => {
    setStep('upload');
    setProducts([]);
    setSummary(null);
    setAutoCreate(null);
    setResult(null);
    setError('');
    setFile(null);
    setRawText('');
    setEdits({});
    setHasEdits(false);
    if (fileRef.current) fileRef.current.value = '';
  };

  return (
    <div className="mx-auto max-w-5xl">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold" style={{ fontFamily: "'Playfair Display', serif" }}>CSV-Import</h1>
          <p className="mt-1 text-sm text-gray-400">Produkte aus CSV-Datei importieren oder aktualisieren</p>
        </div>
        <a href="/templates/import-vorlage.csv" download
          className="rounded-lg border px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-50 transition-colors">
          Vorlage herunterladen
        </a>
      </div>

      {error && (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div>
      )}

      {step === 'upload' && (
        <div onDrop={handleDrop} onDragOver={e => e.preventDefault()}
          className="rounded-xl border-2 border-dashed bg-white p-12 text-center transition-colors hover:border-amber-400">
          <div className="mb-4"><span className="material-symbols-outlined" style={{fontSize: 48, color: "var(--color-text-muted)"}}>upload_file</span></div>
          <p className="text-lg font-medium text-gray-700">CSV-Datei hier ablegen</p>
          <p className="mt-1 text-sm text-gray-400">oder klicken um eine Datei auszuwählen</p>
          <input ref={fileRef} type="file" accept=".csv,.txt" onChange={handleFileSelect} className="hidden" />
          <button onClick={() => fileRef.current?.click()}
            className="mt-4 rounded-lg border px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-50">
            Datei auswählen
          </button>
          {file && (
            <div className="mt-4">
              <p className="text-sm font-medium text-gray-700">{file.name} ({(file.size / 1024).toFixed(1)} KB)</p>
              <button onClick={handlePreview} disabled={loading}
                className="mt-3 rounded-lg px-6 py-2.5 text-sm font-semibold text-white transition-colors"
                style={{ backgroundColor: loading ? '#999' : '#8B6914' }}>
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

      {step === 'preview' && summary && (
        <div>
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

          {autoCreate && (autoCreate.fillQuantities.length > 0 || autoCreate.productGroups.length > 0) && (
            <div className="mb-4 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
              <span className="font-medium">Wird automatisch angelegt: </span>
              {autoCreate.fillQuantities.length > 0 && (
                <span>Füllmengen: {autoCreate.fillQuantities.join(', ')}</span>
              )}
              {autoCreate.fillQuantities.length > 0 && autoCreate.productGroups.length > 0 && <span> | </span>}
              {autoCreate.productGroups.length > 0 && (
                <span>Produktgruppen: {autoCreate.productGroups.join(', ')}</span>
              )}
            </div>
          )}

          <div className="rounded-xl border bg-white overflow-hidden">
            <div className="max-h-[500px] overflow-y-auto">
              <table className="w-full text-sm">
                <thead className="sticky top-0 bg-gray-50 border-b overflow-x-auto whitespace-nowrap">
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
                  {products.map((p, i) => {
                    const isError = p.status === 'error';
                    return (
                      <tr key={`${p.sku}-${i}`} className={isError ? 'bg-red-50/50' : ''}>
                        <td className="px-3 py-2">
                          <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${statusColors[p.status]}`}>
                            {statusLabels[p.status]}
                          </span>
                        </td>
                        <td className="px-3 py-2 font-mono text-xs">{p.sku}</td>
                        <td className="px-3 py-2">
                          <EditableCell sku={p.sku} field="type" value={p.type}
                            editedValue={getEditedValue(p.sku, 'type', p.type)}
                            isError={isError} onEdit={handleCellEdit} />
                        </td>
                        <td className="px-3 py-2">
                          <EditableCell sku={p.sku} field="nameDe" value={p.nameDe}
                            editedValue={getEditedValue(p.sku, 'nameDe', p.nameDe)}
                            isError={isError} onEdit={handleCellEdit} className="font-medium" />
                        </td>
                        <td className="px-3 py-2 tabular-nums">
                          <EditableCell sku={p.sku} field="price" value={p.price || '-'}
                            editedValue={getEditedValue(p.sku, 'price', p.price || '-')}
                            isError={isError} onEdit={handleCellEdit} />
                        </td>
                        <td className="px-3 py-2 text-xs max-w-[200px]">
                          {isError ? (
                            <span className="text-red-600">{p.statusMsg}</span>
                          ) : (
                            <span className="text-gray-500 truncate block">{p.statusMsg}</span>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>

          <div className="mt-4 flex items-center justify-between">
            <button onClick={reset} className="rounded-lg border px-4 py-2 text-sm font-medium text-gray-600 hover:bg-gray-50">
              Abbrechen
            </button>
            <div className="flex items-center gap-3">
              {hasEdits && (
                <button onClick={handleRevalidate} disabled={loading}
                  className="rounded-lg border-2 border-amber-500 bg-amber-50 px-4 py-2 text-sm font-semibold text-amber-700 hover:bg-amber-100 transition-colors">
                  {loading ? 'Validiere...' : 'Neu validieren'}
                </button>
              )}
              {summary.error > 0 && !hasEdits && (
                <p className="text-sm text-amber-600">{summary.error} Fehler werden übersprungen</p>
              )}
              {summary.error > 0 && hasEdits && (
                <p className="text-sm text-amber-600">Bitte neu validieren</p>
              )}
              <button onClick={handleImport}
                disabled={summary.new + summary.update === 0 || hasEdits}
                className="rounded-lg px-6 py-2.5 text-sm font-semibold text-white transition-colors"
                style={{ backgroundColor: (summary.new + summary.update > 0 && !hasEdits) ? '#8B6914' : '#999' }}>
                {summary.new + summary.update} Produkte importieren
              </button>
            </div>
          </div>
        </div>
      )}

      {step === 'importing' && (
        <div className="rounded-xl border bg-white p-12 text-center">
          <div className="text-4xl mb-4 animate-pulse">⏳</div>
          <p className="text-lg font-medium text-gray-700">Import läuft...</p>
          <p className="mt-1 text-sm text-gray-400">Bitte warten, Produkte werden verarbeitet.</p>
        </div>
      )}

      {step === 'done' && result && (
        <div className="rounded-xl border bg-white p-12 text-center">
          <div className="mb-4"><span className="material-symbols-outlined" style={{fontSize: 48, color: "var(--color-success)"}}>check_circle</span></div>
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
