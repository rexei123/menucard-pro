#!/usr/bin/env python3
"""
Schritt 2b-1: "In neuem Tab oeffnen" Link bei PDF-Vorschau
auf pdf-viewer.html Wrapper umbiegen (Chrome laedt sonst herunter).
"""
import sys, shutil, pathlib, datetime

FILE = pathlib.Path('/var/www/menucard-pro/src/components/admin/design-editor.tsx')

if not FILE.exists():
    print(f"FEHLER: {FILE} nicht gefunden")
    sys.exit(1)

bak = FILE.with_suffix('.tsx.bak-' + datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
shutil.copy(FILE, bak)
print(f"Backup: {bak.name}")

src = FILE.read_text(encoding='utf-8')

OLD = '<a href={(previewMode === \'pdf\' ? previewPdfUrl : previewUrl) || \'#\'} target="_blank" rel="noopener noreferrer"'
NEW = '<a href={previewMode === \'pdf\' && previewPdfUrl ? `/pdf-viewer.html?url=${encodeURIComponent(previewPdfUrl)}` : (previewUrl || \'#\')} target="_blank" rel="noopener noreferrer"'

if OLD not in src:
    print("FEHLER: Pattern nicht gefunden. Rollback.")
    shutil.copy(bak, FILE)
    sys.exit(2)

src = src.replace(OLD, NEW, 1)
FILE.write_text(src, encoding='utf-8')
print("OK: Patch angewendet")
