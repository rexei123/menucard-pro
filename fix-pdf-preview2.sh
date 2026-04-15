#!/bin/bash
# Fix: PDF-Vorschau mit <object> statt <iframe>
cd /var/www/menucard-pro

echo "=== Fix PDF-Vorschau v2 ==="

python3 << 'PYEOF'
with open("src/components/admin/analog-design-editor.tsx", "r") as f:
    content = f.read()

# Ersetze iframe mit object-Tag
old_iframe = '''pdfUrl !== "" ? (
            <iframe src={pdfUrl} className="w-full h-full" title="PDF-Vorschau" />'''

new_object = '''pdfUrl !== "" ? (
            <object data={pdfUrl} type="application/pdf" className="w-full h-full">
              <p className="p-8 text-center text-gray-500">PDF kann nicht im Browser angezeigt werden. <a href={pdfUrl} target="_blank" rel="noopener noreferrer" className="text-blue-600 underline">PDF öffnen</a></p>
            </object>'''

if old_iframe in content:
    content = content.replace(old_iframe, new_object)
    print("  ✓ iframe → object ersetzt")
else:
    # Fallback: auch originale Version prüfen
    old2 = '''pdfUrl ? (
            <iframe src={pdfUrl} className="w-full h-full" title="PDF-Vorschau" />'''
    new2 = '''pdfUrl ? (
            <object data={pdfUrl} type="application/pdf" className="w-full h-full">
              <p className="p-8 text-center text-gray-500">PDF kann nicht im Browser angezeigt werden. <a href={pdfUrl} target="_blank" rel="noopener noreferrer" className="text-blue-600 underline">PDF öffnen</a></p>
            </object>'''
    if old2 in content:
        content = content.replace(old2, new2)
        print("  ✓ iframe → object ersetzt (v2)")
    else:
        print("  ⚠ iframe nicht gefunden, manueller Fix nötig")

with open("src/components/admin/analog-design-editor.tsx", "w") as f:
    f.write(content)
PYEOF

echo "[2/2] Build..."
npm run build 2>&1 | tail -10

if [ $? -eq 0 ]; then
  pm2 restart menucard-pro
  echo "  ✅ PDF-Vorschau v2 Fix LIVE!"
else
  echo "  ❌ Build fehlgeschlagen"
fi
