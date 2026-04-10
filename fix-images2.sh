#!/bin/bash
set -e
cd /var/www/menucard-pro

python3 << 'PYEOF'
# Fix 1: Move ProductImages inside editor
c = open('src/app/admin/items/[id]/page.tsx').read()
c = c.replace(
    "return <>\n    <ProductEditor product={data} options={opts} />\n    <ProductImages productId={product.id} initialImages={data.images || []} />\n  </>;",
    "return <ProductEditor product={data} options={opts} images={data.images || []} />;"
)
c = c.replace("import ProductImages from '@/components/admin/product-images';\n", "")
open('src/app/admin/items/[id]/page.tsx', 'w').write(c)

# Fix 2: Add images prop to ProductEditor
c = open('src/components/admin/product-editor.tsx').read()
if 'ProductImages' not in c:
    c = c.replace("'use client';", "'use client';\nimport ProductImages from '@/components/admin/product-images';")
c = c.replace(
    'export default function ProductEditor({ product, options }:',
    'export default function ProductEditor({ product, options, images }:'
)
c = c.replace(
    '{ product: ProductData; options: Options }',
    '{ product: ProductData; options: Options; images?: any[] }'
)
if '{/* Bilder */}' not in c:
    c = c.replace(
        '{/* Placements',
        '{/* Bilder */}\n      {images && <ProductImages productId={data.id} initialImages={images} />}\n\n      {/* Placements'
    )
open('src/components/admin/product-editor.tsx', 'w').write(c)

# Fix 3: Sort + image scaling
c = open('src/components/admin/product-images.tsx').read()
c = c.replace(
    'const [images, setImages] = useState<ImageData[]>(initialImages);',
    'const [images, setImages] = useState<ImageData[]>([...initialImages].sort((a, b) => a.isPrimary ? -1 : b.isPrimary ? 1 : a.sortOrder - b.sortOrder));'
)
c = c.replace(
    'className="w-full h-32 object-contain bg-gray-100"',
    'className="w-full h-40 object-contain p-1"'
)
open('src/components/admin/product-images.tsx', 'w').write(c)
print('Done!')
PYEOF

npm run build; pm2 restart menucard-pro
echo "=== Done ==="
