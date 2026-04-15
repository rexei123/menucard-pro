#!/bin/bash
# Fix: PDF-Vorschau mit <embed> + Fallback auf Popup
cd /var/www/menucard-pro

echo "=== Fix PDF-Vorschau v3 ==="

python3 << 'PYEOF'
with open("src/components/admin/analog-design-editor.tsx", "r") as f:
    content = f.read()

# Ersetze den kompletten Vorschau-Bereich (rechte Spalte)
old_preview = '''      {/* ─── Rechte Spalte: PDF-Vorschau ─── */}
      <div className="flex-1 flex flex-col min-w-0">
        <div className="flex items-center justify-between mb-3">
          <h3 className="font-medium text-gray-700">PDF-Vorschau</h3>
          <div className="flex gap-2">
            <button onClick={loadPdfPreview} disabled={pdfLoading}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 text-sm font-medium transition-colors flex items-center gap-2">
              {pdfLoading ? (
                <><span className="animate-spin">⟳</span> Generiere...</>
              ) : (
                <><span>🔄</span> Vorschau aktualisieren</>
              )}
            </button>
            <a href={`/api/v1/menus/${menuId}/pdf`} target="_blank" rel="noopener noreferrer"
              className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 text-sm font-medium transition-colors flex items-center gap-2">
              <span>⬇️</span> PDF herunterladen
            </a>
          </div>
        </div>
        <div className="flex-1 bg-gray-100 rounded-lg border border-gray-200 overflow-hidden min-h-[600px]">
          {pdfUrl !== "" ? (
            <object data={pdfUrl} type="application/pdf" className="w-full h-full">
              <p className="p-8 text-center text-gray-500">PDF kann nicht im Browser angezeigt werden. <a href={pdfUrl} target="_blank" rel="noopener noreferrer" className="text-blue-600 underline">PDF öffnen</a></p>
            </object>
          ) : (
            <div className="flex flex-col items-center justify-center h-full text-gray-400">
              <span className="text-5xl mb-4">📄</span>
              <p className="text-lg">Klicken Sie auf &quot;Vorschau aktualisieren&quot;</p>
              <p className="text-sm mt-1">um eine PDF-Vorschau zu sehen</p>
            </div>
          )}
        </div>
      </div>'''

new_preview = '''      {/* ─── Rechte Spalte: PDF-Vorschau ─── */}
      <div className="flex-1 flex flex-col min-w-0">
        <div className="flex items-center justify-between mb-3">
          <h3 className="font-medium text-gray-700">PDF-Vorschau</h3>
          <div className="flex gap-2">
            <button onClick={loadPdfPreview} disabled={pdfLoading}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 text-sm font-medium transition-colors flex items-center gap-2">
              {pdfLoading ? (
                <><span className="animate-spin">⟳</span> Generiere...</>
              ) : (
                <><span>🔄</span> Vorschau aktualisieren</>
              )}
            </button>
            <button onClick={() => window.open(`/api/v1/menus/${menuId}/pdf`, '_blank')}
              className="px-4 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 text-sm font-medium transition-colors flex items-center gap-2">
              <span>↗️</span> In neuem Tab öffnen
            </button>
            <a href={`/api/v1/menus/${menuId}/pdf`} download
              className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 text-sm font-medium transition-colors flex items-center gap-2">
              <span>⬇️</span> Download
            </a>
          </div>
        </div>
        <div className="flex-1 bg-gray-100 rounded-lg border border-gray-200 overflow-hidden" style={{ minHeight: '700px' }}>
          {pdfUrl !== "" ? (
            <embed src={pdfUrl + '#toolbar=1&navpanes=0&scrollbar=1&view=FitH'} type="application/pdf" style={{ width: '100%', height: '100%' }} />
          ) : (
            <div className="flex flex-col items-center justify-center h-full text-gray-400">
              <span className="text-5xl mb-4">📄</span>
              <p className="text-lg font-medium">PDF-Vorschau</p>
              <p className="text-sm mt-1 mb-4">Klicken Sie auf &quot;Vorschau aktualisieren&quot; um das PDF zu sehen</p>
              <p className="text-xs text-gray-300">Tipp: &quot;In neuem Tab öffnen&quot; für die beste Ansicht</p>
            </div>
          )}
        </div>
      </div>'''

if old_preview in content:
    content = content.replace(old_preview, new_preview)
    print("  ✓ Vorschau-Bereich komplett ersetzt")
else:
    print("  ⚠ Vorschau-Bereich nicht gefunden - versuche Zeile für Zeile")
    # Einzelne Ersetzungen als Fallback
    content = content.replace(
        '<object data={pdfUrl} type="application/pdf" className="w-full h-full">',
        "<embed src={pdfUrl + '#toolbar=1&navpanes=0&scrollbar=1&view=FitH'} type=\"application/pdf\" style={{ width: '100%', height: '100%' }} />"
    )
    content = content.replace(
        '              <p className="p-8 text-center text-gray-500">PDF kann nicht im Browser angezeigt werden. <a href={pdfUrl} target="_blank" rel="noopener noreferrer" className="text-blue-600 underline">PDF öffnen</a></p>\n            </object>',
        ''
    )
    print("  ✓ Fallback-Ersetzung durchgeführt")

with open("src/components/admin/analog-design-editor.tsx", "w") as f:
    f.write(content)
PYEOF

echo "[2/2] Build..."
npm run build 2>&1 | tail -10

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo "  ✅ PDF-Vorschau v3 LIVE!"
else
  echo "  ❌ Build fehlgeschlagen"
fi
