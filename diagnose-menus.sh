#!/bin/bash
cd /var/www/menucard-pro
DB="postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

echo "=== 1. Menus mit Location ==="
psql "$DB" -c "
SELECT m.id, m.slug, m.type, l.slug AS location_slug
FROM \"Menu\" m
JOIN \"Location\" l ON l.id = m.\"locationId\"
ORDER BY l.slug, m.slug;
"

echo "=== 2. Sections pro Menu (mit parentId und Tiefe) ==="
psql "$DB" -c "
SELECT ms.\"menuId\", m.slug AS menu, ms.id, ms.slug, ms.depth, ms.\"parentId\",
  (SELECT count(*) FROM \"MenuPlacement\" mp WHERE mp.\"sectionId\" = ms.id) AS placements
FROM \"MenuSection\" ms
JOIN \"Menu\" m ON m.id = ms.\"menuId\"
ORDER BY m.slug, ms.depth, ms.\"sortOrder\";
"

echo "=== 3. Placements mit Variant + Product ==="
psql "$DB" -c "
SELECT mp.id, ms.slug AS section, m.slug AS menu, pv.label AS variant_label,
  pt.name AS product_name, vp.\"sellPrice\"
FROM \"MenuPlacement\" mp
JOIN \"MenuSection\" ms ON ms.id = mp.\"sectionId\"
JOIN \"Menu\" m ON m.id = ms.\"menuId\"
JOIN \"ProductVariant\" pv ON pv.id = mp.\"variantId\"
JOIN \"Product\" p ON p.id = pv.\"productId\"
LEFT JOIN \"ProductTranslation\" pt ON pt.\"productId\" = p.id AND pt.language = 'de'
LEFT JOIN \"VariantPrice\" vp ON vp.\"variantId\" = pv.id
ORDER BY m.slug, ms.\"sortOrder\", mp.\"sortOrder\"
LIMIT 50;
"

echo "=== 4. Location-Slugs ==="
psql "$DB" -c "SELECT id, slug, name FROM \"Location\";"
