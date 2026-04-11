#!/bin/bash
# MenuCard Pro – Bilder in Gästekarte anzeigen
# 1. Menu-Seite: productMedia in Query aufnehmen + an MenuContent übergeben
# 2. MenuContent: Thumbnail anzeigen
# 3. Artikeldetail: Hauptbild anzeigen
# Datum: 10.04.2026

set -e
cd /var/www/menucard-pro

echo "=== Bilder in Gästekarte ==="

# === 1. Menu-Seite: productMedia zur Query + Serialisierung hinzufügen ===
echo "[1/4] Menu-Seite: productMedia hinzufügen..."

python3 -c "
c = open('src/app/(public)/[tenant]/[location]/[menu]/page.tsx').read()

# productMedia zur Prisma-Query hinzufuegen (nach productWineProfile)
old = 'productWineProfile: true,'
new = '''productWineProfile: true,
            productMedia: { where: { isPrimary: true }, take: 1, orderBy: { sortOrder: 'asc' } },'''
c = c.replace(old, new, 1)

# Image-URL in Serialisierung hinzufuegen (nach wineProfile block)
# Finde das Ende des wineProfile-Blocks und fuege image hinzu
old = '''        wineProfile: p.productWineProfile ? {'''
new = '''        image: (() => {
          const pm = (p as any).productMedia?.[0];
          if (!pm) return null;
          const url = pm.url || '';
          return url.replace('/uploads/large/', '/uploads/thumb/');
        })(),
        wineProfile: p.productWineProfile ? {'''
c = c.replace(old, new, 1)

open('src/app/(public)/[tenant]/[location]/[menu]/page.tsx', 'w').write(c)
print('  Menu-Seite aktualisiert')
"

# === 2. MenuContent: Image-Prop + Thumbnail-Anzeige ===
echo "[2/4] MenuContent: Thumbnail hinzufügen..."

python3 -c "
c = open('src/components/menu-content.tsx').read()

# Image zum Item-Type hinzufuegen
old = 'type Item = { id: string; isHighlight: boolean; highlightType?: string | null; isSoldOut: boolean; translations: Translation[]; priceVariants: PriceVariant[];'
new = 'type Item = { id: string; isHighlight: boolean; highlightType?: string | null; isSoldOut: boolean; image?: string | null; translations: Translation[]; priceVariants: PriceVariant[];'
c = c.replace(old, new, 1)

# Thumbnail-Bild in der Item-Card anzeigen (vor dem Chevron-Icon)
old = '''                  {clickable && (
                            <svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" strokeWidth=\"2\" strokeLinecap=\"round\" strokeLinejoin=\"round\" className=\"mt-1 flex-shrink-0 opacity-20\"><path d=\"m9 18 6-6-6-6\"/></svg>
                          )}'''
new = '''                  {item.image && (
                            <img
                              src={item.image}
                              alt=\"\"
                              className=\"h-16 w-16 flex-shrink-0 rounded-lg object-cover\"
                              loading=\"lazy\"
                            />
                          )}
                          {clickable && !item.image && (
                            <svg xmlns=\"http://www.w3.org/2000/svg\" width=\"16\" height=\"16\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" strokeWidth=\"2\" strokeLinecap=\"round\" strokeLinejoin=\"round\" className=\"mt-1 flex-shrink-0 opacity-20\"><path d=\"m9 18 6-6-6-6\"/></svg>
                          )}'''
c = c.replace(old, new, 1)

open('src/components/menu-content.tsx', 'w').write(c)
print('  MenuContent aktualisiert')
"

# === 3. Artikeldetail: Hauptbild anzeigen ===
echo "[3/4] Artikeldetail: Hauptbild hinzufügen..."

python3 -c "
c = open('src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx').read()

# Bild-Block nach dem Title/Badges-Block einfuegen
old = '''        {/* Long Description */}'''
new = '''        {/* Product Image */}
        {product.productMedia && product.productMedia.length > 0 && (
          <div className=\"mb-6 flex justify-center\">
            <img
              src={product.productMedia[0].url?.replace('/uploads/large/', '/uploads/medium/') || product.productMedia[0].url || ''}
              alt={pName}
              className=\"max-h-80 rounded-xl object-contain\"
              loading=\"lazy\"
            />
          </div>
        )}

        {/* Long Description */}'''
c = c.replace(old, new, 1)

open('src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx', 'w').write(c)
print('  Artikeldetail aktualisiert')
"

# === 4. Build + Restart ===
echo ""
echo "=== Build ==="
npm run build

echo ""
echo "=== PM2 Restart ==="
pm2 restart menucard-pro

echo ""
echo "[4/4] Fertig! Bilder werden jetzt in der Gästekarte angezeigt."
echo ""
echo "Test-URLs:"
echo "  Kartenansicht: http://178.104.138.177/hotel-sonnblick/restaurant/barkarte"
echo "  Artikeldetail: (Gin Berry anklicken)"
