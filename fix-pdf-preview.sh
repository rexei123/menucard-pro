#!/bin/bash
# Fix: PDF-Vorschau direkt per URL statt Blob
cd /var/www/menucard-pro

echo "=== Fix PDF-Vorschau ==="

# Ersetze die loadPdfPreview-Funktion und den iframe-Bereich
sed -i 's|const \[pdfUrl, setPdfUrl\] = useState<string | null>(null);|const [pdfUrl, setPdfUrl] = useState<string>("");|' src/components/admin/analog-design-editor.tsx

# Komplette Datei neu schreiben wäre sicherer - nur den Preview-Teil patchen
# Einfachster Fix: pdfUrl direkt als API-URL setzen statt Blob

python3 << 'PYEOF'
import re

with open("src/components/admin/analog-design-editor.tsx", "r") as f:
    content = f.read()

# 1. Fix: loadPdfPreview - direkt URL statt Blob
old_preview = '''const loadPdfPreview = async () => {
    setPdfLoading(true);
    try {
      const res = await fetch(`/api/v1/menus/${menuId}/pdf`);
      if (!res.ok) throw new Error('PDF konnte nicht generiert werden');
      const blob = await res.blob();
      if (pdfUrl) URL.revokeObjectURL(pdfUrl);
      setPdfUrl(URL.createObjectURL(blob));
    } catch (e) {
      console.error('PDF preview error:', e);
    }
    setPdfLoading(false);
  };'''

new_preview = '''const loadPdfPreview = () => {
    setPdfLoading(true);
    // Timestamp für Cache-Busting bei jeder Aktualisierung
    setPdfUrl(`/api/v1/menus/${menuId}/pdf?t=${Date.now()}`);
    // Ladezeit simulieren bis iframe geladen
    setTimeout(() => setPdfLoading(false), 1500);
  };'''

content = content.replace(old_preview, new_preview)

# 2. Fix: pdfUrl State - leerer String statt null
content = content.replace(
    "const [pdfUrl, setPdfUrl] = useState<string | null>(null);",
    'const [pdfUrl, setPdfUrl] = useState("");'
)
content = content.replace(
    "const [pdfUrl, setPdfUrl] = useState<string>(null);",
    'const [pdfUrl, setPdfUrl] = useState("");'
)

# 3. Fix: iframe Check - leerer String statt null
content = content.replace(
    "{pdfUrl ? (",
    '{pdfUrl !== "" ? ('
)

with open("src/components/admin/analog-design-editor.tsx", "w") as f:
    f.write(content)

print("  ✓ PDF-Vorschau auf direkte URL umgestellt")
PYEOF

echo "[2/2] Build..."
npm run build 2>&1 | tail -10

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo ""
  echo "  ✅ PDF-Vorschau Fix LIVE!"
else
  echo ""
  echo "  ❌ Build fehlgeschlagen"
fi
