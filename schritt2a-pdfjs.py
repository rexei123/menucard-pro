#!/usr/bin/env python3
"""
PDF-Vorschau auf pdf.js-Viewer umstellen (umgeht Chrome PDF-Setting).
"""
from pathlib import Path
import sys

f = Path("/var/www/menucard-pro/src/components/admin/design-editor.tsx")
text = f.read_text(encoding="utf-8")

old = (
    '              <object data={previewPdfUrl + \'#toolbar=1&navpanes=0&view=FitH\'} type="application/pdf" className="w-full h-full">\n'
    '                <div className="flex flex-col items-center justify-center h-full p-6 text-center text-gray-600">\n'
    '                  <span className="material-symbols-outlined text-gray-300" style={{ fontSize: 64 }}>picture_as_pdf</span>\n'
    '                  <p className="mt-3 text-sm">Die PDF-Vorschau kann nicht eingebettet werden.</p>\n'
    '                  <a href={previewPdfUrl} target="_blank" rel="noopener noreferrer" className="mt-2 text-sm font-medium underline" style={{ color: \'#DD3C71\' }}>PDF in neuem Tab öffnen</a>\n'
    '                </div>\n'
    '              </object>'
)
new = '              <iframe ref={iframeRef} src={`/pdf-viewer.html?url=${encodeURIComponent(previewPdfUrl || \'\')}&t=${savedAt || 0}`} className="w-full h-full border-0" title="PDF-Vorschau" />'

count = text.count(old)
if count != 1:
    print(f"FAIL: Muster {count}x gefunden, erwartet 1")
    sys.exit(1)

f.write_text(text.replace(old, new, 1), encoding="utf-8")
print("OK: Preview -> pdf.js Viewer")
