#!/bin/bash
# Fix: Eigener PDF-Viewer mit pdf.js + Vorschau im Editor
cd /var/www/menucard-pro

echo "=== PDF-Viewer mit pdf.js ==="

# 1. PDF-Viewer HTML in public/ erstellen
cat > public/pdf-viewer.html << 'ENDOFHTML'
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>PDF-Vorschau</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { background: #f3f4f6; display: flex; flex-direction: column; align-items: center; padding: 16px; gap: 16px; font-family: system-ui; }
  canvas { background: white; box-shadow: 0 2px 8px rgba(0,0,0,0.15); max-width: 100%; height: auto !important; }
  .loading { color: #6b7280; padding: 40px; text-align: center; }
  .error { color: #dc2626; padding: 40px; text-align: center; }
  .page-label { font-size: 12px; color: #9ca3af; margin-top: 8px; }
</style>
</head>
<body>
<div id="viewer"><div class="loading">PDF wird geladen...</div></div>
<script>
  const params = new URLSearchParams(window.location.search);
  const url = params.get('url');
  const viewer = document.getElementById('viewer');

  if (!url) {
    viewer.innerHTML = '<div class="error">Keine PDF-URL angegeben</div>';
  } else {
    pdfjsLib.GlobalWorkerOptions.workerSrc = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';

    pdfjsLib.getDocument(url).promise.then(async function(pdf) {
      viewer.innerHTML = '';
      for (let i = 1; i <= pdf.numPages; i++) {
        const page = await pdf.getPage(i);
        const scale = 1.5;
        const viewport = page.getViewport({ scale });
        const canvas = document.createElement('canvas');
        canvas.width = viewport.width;
        canvas.height = viewport.height;
        const ctx = canvas.getContext('2d');
        await page.render({ canvasContext: ctx, viewport }).promise;
        viewer.appendChild(canvas);
        const label = document.createElement('div');
        label.className = 'page-label';
        label.textContent = 'Seite ' + i + ' von ' + pdf.numPages;
        viewer.appendChild(label);
      }
    }).catch(function(err) {
      viewer.innerHTML = '<div class="error">Fehler: ' + err.message + '</div>';
    });
  }
</script>
</body>
</html>
ENDOFHTML

echo "  ✓ public/pdf-viewer.html erstellt"

# 2. Analog-Editor: Vorschau auf pdf-viewer.html umstellen
python3 << 'PYEOF'
with open("src/components/admin/analog-design-editor.tsx", "r") as f:
    content = f.read()

# Ersetze loadPdfPreview Funktion
import re
content = re.sub(
    r'const loadPdfPreview = .*?;(\s*\n\s*// Ladezeit.*?\n.*?;)?',
    'const loadPdfPreview = () => {\n    setPdfUrl(`/pdf-viewer.html?url=/api/v1/menus/${menuId}/pdf&t=${Date.now()}`);\n  };',
    content,
    flags=re.DOTALL
)

# Ersetze embed/object/iframe mit einfachem iframe zum Viewer
# Finde den Vorschau-Bereich und ersetze das embed/object
content = re.sub(
    r'<embed src=\{pdfUrl.*?/>',
    '<iframe src={pdfUrl} className="w-full h-full border-0" title="PDF-Vorschau" />',
    content,
    flags=re.DOTALL
)
content = re.sub(
    r'<object data=\{pdfUrl.*?</object>',
    '<iframe src={pdfUrl} className="w-full h-full border-0" title="PDF-Vorschau" />',
    content,
    flags=re.DOTALL
)

# Entferne pdfLoading State falls nicht mehr gebraucht
# (behalten, wird noch für den Button verwendet)

with open("src/components/admin/analog-design-editor.tsx", "w") as f:
    f.write(content)

print("  ✓ Vorschau auf pdf-viewer.html umgestellt")
PYEOF

echo "[3/3] Build..."
npm run build 2>&1 | tail -10

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo ""
  echo "  ✅ PDF-Viewer LIVE!"
  echo "  → PDF wird jetzt mit pdf.js direkt im Browser gerendert"
else
  echo "  ❌ Build fehlgeschlagen"
fi
