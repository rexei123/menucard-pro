#!/bin/bash
cd /var/www/menucard-pro

echo "=== 1. Emojis in menu-editor.tsx ==="
# Sektionen-Icons / Emoji-Mapping suchen
grep -n "Schaumwein\|Aperitif\|sectionIcon\|sectionEmoji" src/components/admin/menu-editor.tsx | head -20

echo ""
echo "=== 2. Alle Emoji-Pattern in menu-editor ==="
python3 << 'PY'
with open('src/components/admin/menu-editor.tsx','r',encoding='utf-8') as f:
    for i, line in enumerate(f, 1):
        for ch in line:
            if ord(ch) > 0x1F000:
                print(f"{i}: {line.rstrip()}")
                break
PY

echo ""
echo "=== 3. Wo wird die Sektions-Ueberschrift gerendert? ==="
grep -nE "section\.name|section\.icon|section\.emoji" src/components/admin/menu-editor.tsx | head -20

echo ""
echo "=== 4. Backup-Dateien check ==="
ls -la src/components/admin/menu-editor.tsx*
