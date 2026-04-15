#!/bin/bash
set -e
echo "============================================"
echo "  UI-Redesign Phase 2c: Emojis → Material Symbols"
echo "============================================"

cd /var/www/menucard-pro

# ============================================
# 1. design-editor.tsx – Template-Icons + Akkordeon-Icons
# ============================================
echo "[1/8] design-editor.tsx..."
cp src/components/admin/design-editor.tsx src/components/admin/design-editor.tsx.bak-emoji

# Template-Icons
sed -i "s/icon: '🍷'/icon: 'wine_bar'/" src/components/admin/design-editor.tsx
sed -i "s/icon: '🍸'/icon: 'local_bar'/" src/components/admin/design-editor.tsx
sed -i "s/icon: '🍽️'/icon: 'restaurant'/" src/components/admin/design-editor.tsx
sed -i "s/icon: '☕'/icon: 'coffee'/" src/components/admin/design-editor.tsx

# Akkordeon-Icons
sed -i 's/icon="🎨"/icon="palette"/' src/components/admin/design-editor.tsx
sed -i 's/icon="🏷️"/icon="sell"/' src/components/admin/design-editor.tsx
sed -i 's/icon="📦"/icon="inventory_2"/' src/components/admin/design-editor.tsx

# Status
sed -i "s/Gespeichert ✓/Gespeichert/" src/components/admin/design-editor.tsx
sed -i "s/>✕</>×</" src/components/admin/design-editor.tsx

# Emoji-Darstellung in Auswahl
sed -i "s/Emoji (🍷🍸)/Emoji-Icons/" src/components/admin/design-editor.tsx

# Handy-Text
sed -i "s/📱 Handy/Handy/" src/components/admin/design-editor.tsx

# ============================================
# 2. product-editor.tsx – Translate-Buttons + Aktionen
# ============================================
echo "[2/8] product-editor.tsx..."
cp src/components/admin/product-editor.tsx src/components/admin/product-editor.tsx.bak-emoji

sed -i "s/⏳ Übersetze.../Übersetze.../" src/components/admin/product-editor.tsx
sed -i "s/✅ Übersetzt/Übersetzt/" src/components/admin/product-editor.tsx
sed -i "s/🔄 DE → EN/DE → EN/" src/components/admin/product-editor.tsx
sed -i "s/⚠️ DE geändert/DE geändert/" src/components/admin/product-editor.tsx
sed -i "s/>✕</>×</" src/components/admin/product-editor.tsx
sed -i "s/📝 Rezeptur/Rezeptur/" src/components/admin/product-editor.tsx
sed -i "s/🗑️ Produkt löschen/Produkt löschen/" src/components/admin/product-editor.tsx
sed -i "s/✓ Gespeichert/Gespeichert/" src/components/admin/product-editor.tsx

# ============================================
# 3. menu-editor.tsx
# ============================================
echo "[3/8] menu-editor.tsx..."
cp src/components/admin/menu-editor.tsx src/components/admin/menu-editor.tsx.bak-emoji

sed -i "s/📱 //" src/components/admin/menu-editor.tsx
sed -i "s/🚫/○/" src/components/admin/menu-editor.tsx
sed -i "s/>✕</>×</" src/components/admin/menu-editor.tsx
sed -i "s/🗑️ Hier ablegen = Entfernen/Hier ablegen = Entfernen/" src/components/admin/menu-editor.tsx

# ============================================
# 4. analog-design-editor.tsx
# ============================================
echo "[4/8] analog-design-editor.tsx..."
cp src/components/admin/analog-design-editor.tsx src/components/admin/analog-design-editor.tsx.bak-emoji

sed -i 's/icon="📄"/icon="description"/' src/components/admin/analog-design-editor.tsx
sed -i 's/icon="🏔️"/icon="landscape"/' src/components/admin/analog-design-editor.tsx
sed -i 's/icon="🎨"/icon="palette"/' src/components/admin/analog-design-editor.tsx
sed -i 's/icon="🍷"/icon="wine_bar"/' src/components/admin/analog-design-editor.tsx
sed -i 's/icon="🖼️"/icon="image"/' src/components/admin/analog-design-editor.tsx
sed -i 's/icon="📏"/icon="straighten"/' src/components/admin/analog-design-editor.tsx
sed -i "s/>✕</>×</" src/components/admin/analog-design-editor.tsx
sed -i "s/🔄 Vorschau aktualisieren/Vorschau aktualisieren/" src/components/admin/analog-design-editor.tsx
sed -i "s/⬇️ PDF herunterladen/PDF herunterladen/" src/components/admin/analog-design-editor.tsx
sed -i 's/<span className="text-5xl mb-4">📄<\/span>/<span className="material-symbols-outlined" style={{fontSize: 48, color: "var(--color-text-muted)"}}>picture_as_pdf<\/span>/' src/components/admin/analog-design-editor.tsx

# ============================================
# 5. media-detail.tsx + csv-import.tsx + design-tabs.tsx
# ============================================
echo "[5/8] media-detail, csv-import, design-tabs..."

# media-detail.tsx
sed -i "s/✂️ Zuschneiden/Zuschneiden/" src/components/admin/media-detail.tsx
sed -i "s/'💾 Speichern'/'Speichern'/" src/components/admin/media-detail.tsx
sed -i "s/🗑️ Bild löschen/Bild löschen/" src/components/admin/media-detail.tsx

# csv-import.tsx
sed -i 's/<div className="text-4xl mb-4">📄<\/div>/<div className="mb-4"><span className="material-symbols-outlined" style={{fontSize: 48, color: "var(--color-text-muted)"}}>upload_file<\/span><\/div>/' src/components/admin/csv-import.tsx
sed -i 's/<div className="text-4xl mb-4">✅<\/div>/<div className="mb-4"><span className="material-symbols-outlined" style={{fontSize: 48, color: "var(--color-success)"}}>check_circle<\/span><\/div>/' src/components/admin/csv-import.tsx

# design-tabs.tsx
sed -i "s/🖥️ Digital/Digital/" src/components/admin/design-tabs.tsx
sed -i "s/📄 PDF/PDF/" src/components/admin/design-tabs.tsx

# ============================================
# 6. menu-list-panel.tsx – Typ-Icons
# ============================================
echo "[6/8] menu-list-panel.tsx..."

cat > /tmp/menu-icons-fix.py << 'PYEOF'
import re
with open('src/components/admin/menu-list-panel.tsx', 'r') as f:
    content = f.read()

# Alte Emoji-Mappings ersetzen
old_icons = """  FOOD: '🍽️', DRINKS: '🍸', WINE: '🍷', BAR: '🍸', EVENT: '🎉',
  BREAKFAST: '☕', SPA: '💆', ROOM_SERVICE: '🛎️', MINIBAR: '🧊',
  DAILY_SPECIAL: '⭐', SEASONAL: '🌿',"""

new_icons = """  FOOD: 'restaurant', DRINKS: 'local_bar', WINE: 'wine_bar', BAR: 'local_bar', EVENT: 'celebration',
  BREAKFAST: 'coffee', SPA: 'spa', ROOM_SERVICE: 'room_service', MINIBAR: 'kitchen',
  DAILY_SPECIAL: 'star', SEASONAL: 'eco',"""

content = content.replace(old_icons, new_icons)

# Icon-Rendering: von <span>{icon}</span> zu Material Symbol
# Alte Zeile: <span className="...">{icon}</span> oder ähnlich - text-2xl/text-lg
content = content.replace(
    "const icon = typeIcons[m.type] || '📄';",
    "const icon = typeIcons[m.type] || 'description';"
)

with open('src/components/admin/menu-list-panel.tsx', 'w') as f:
    f.write(content)
print("menu-list-panel.tsx updated")
PYEOF
python3 /tmp/menu-icons-fix.py

# ============================================
# 7. Admin-Seiten (items, menus, design)
# ============================================
echo "[7/8] Admin-Seiten..."

# items/page.tsx
sed -i 's/<p className="text-5xl mb-4">📦<\/p>/<p className="mb-4"><span className="material-symbols-outlined" style={{fontSize: 48, color: "var(--color-text-muted)"}}>inventory_2<\/span><\/p>/' src/app/admin/items/page.tsx

# menus/page.tsx
sed -i 's/<p className="text-5xl mb-4">📋<\/p>/<p className="mb-4"><span className="material-symbols-outlined" style={{fontSize: 48, color: "var(--color-text-muted)"}}>menu_book<\/span><\/p>/' src/app/admin/menus/page.tsx

# design/page.tsx
sed -i "s/📄 PDF/PDF/" src/app/admin/design/page.tsx

# ============================================
# 8. Öffentliche Gästeansicht – Typ-Icons
# ============================================
echo "[8/8] Gästeansicht Typ-Icons..."

cat > /tmp/public-icons-fix.py << 'PYEOF'
with open('src/app/(public)/[tenant]/[location]/page.tsx', 'r') as f:
    content = f.read()

old = "const icons: Record<string, string> = { FOOD: '🍽️', DRINKS: '🥤', WINE: '🍷', BREAKFAST: '🥐', BAR: '🍸', SPA: '🧖', ROOM_SERVICE: '🛎️', MINIBAR: '🧊', EVENT: '🎉' };"
new = "const icons: Record<string, string> = { FOOD: 'restaurant', DRINKS: 'local_bar', WINE: 'wine_bar', BREAKFAST: 'coffee', BAR: 'local_bar', SPA: 'spa', ROOM_SERVICE: 'room_service', MINIBAR: 'kitchen', EVENT: 'celebration' };"

content = content.replace(old, new)

# Icon-Rendering anpassen
content = content.replace(
    '<span className="text-3xl">{icons[menu.type] || \'📄\'}</span>',
    '<span className="material-symbols-outlined" style={{fontSize: 32, color: "var(--color-primary)"}}>{icons[menu.type] || \'description\'}</span>'
)

with open('src/app/(public)/[tenant]/[location]/page.tsx', 'w') as f:
    f.write(content)
print("public page.tsx updated")
PYEOF
python3 /tmp/public-icons-fix.py

# Cleanup
rm -f /tmp/menu-icons-fix.py /tmp/public-icons-fix.py

# ============================================
# BUILD
# ============================================
echo "[BUILD] Starte Build..."
npm run build && pm2 restart menucard-pro

echo ""
echo "============================================"
echo "  UI-Redesign Phase 2c: FERTIG!"
echo "============================================"
echo "  Emojis ersetzt in:"
echo "  - design-editor.tsx (Templates + Akkordeons)"
echo "  - product-editor.tsx (Translate-Buttons + Aktionen)"
echo "  - menu-editor.tsx (QR, Visibility, Drop)"
echo "  - analog-design-editor.tsx (Akkordeons + PDF)"
echo "  - media-detail.tsx (Crop, Save, Delete)"
echo "  - csv-import.tsx (Upload + Success)"
echo "  - design-tabs.tsx (Digital/PDF)"
echo "  - menu-list-panel.tsx (Kartentyp-Icons)"
echo "  - admin/items, menus, design (Platzhalter)"
echo "  - Gästeansicht (Kartentyp-Icons)"
echo "============================================"
