#!/bin/bash
cd /var/www/menucard-pro
DB="postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

echo "=== 1. Tenant + Locations + Admin-User anlegen ==="
psql "$DB" << 'SQLEOF'
-- Tenant
INSERT INTO "Tenant" (id, name, slug, "isActive", "createdAt", "updatedAt")
VALUES ('cmnooy9xw0000u8rijzrmf40u', 'Hotel Sonnblick', 'hotel-sonnblick', true, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Locations
INSERT INTO "Location" (id, "tenantId", name, slug, "isActive", "sortOrder", "createdAt", "updatedAt")
VALUES
  ('loc-restaurant', 'cmnooy9xw0000u8rijzrmf40u', 'Restaurant', 'restaurant', true, 0, NOW(), NOW()),
  ('loc-bar', 'cmnooy9xw0000u8rijzrmf40u', 'Bar', 'bar', true, 1, NOW(), NOW())
ON CONFLICT DO NOTHING;

-- Admin-User (Passwort: Sonnblick2026!)
INSERT INTO "User" (id, "tenantId", email, "passwordHash", "firstName", "lastName", name, role, "isActive", "createdAt", "updatedAt")
VALUES (
  'cluser001admin',
  'cmnooy9xw0000u8rijzrmf40u',
  'admin@hotel-sonnblick.at',
  '$2a$10$8K1p/kEIxVCRq8xU2QKGOO5xYDFx0mG6cM5jV8HZXSaYl7MjpgCa',
  'Admin', 'Sonnblick', 'Admin Sonnblick',
  'ADMIN', true, NOW(), NOW()
) ON CONFLICT DO NOTHING;

-- Theme
INSERT INTO "Theme" (id, "tenantId", name, "isActive", "accentColor", "backgroundColor", "textColor")
VALUES ('theme-default', 'cmnooy9xw0000u8rijzrmf40u', 'Default', true, '#8B6914', '#FAFAF8', '#1a1a1a')
ON CONFLICT DO NOTHING;

-- Sprachen
INSERT INTO "TenantLanguage" (id, "tenantId", language, "isDefault")
VALUES
  ('tl-de', 'cmnooy9xw0000u8rijzrmf40u', 'de', true),
  ('tl-en', 'cmnooy9xw0000u8rijzrmf40u', 'en', false)
ON CONFLICT DO NOTHING;

SELECT 'Basis-Daten erstellt' AS result;
SQLEOF

echo ""
echo "=== 2. Seed v2 ausfuehren ==="
npx tsx scripts/seed-v2.ts 2>&1
echo "SEED=$?"

echo ""
echo "=== 3. DesignTemplates baseType + languageCode sync ==="
psql "$DB" -c "UPDATE \"DesignTemplate\" SET \"baseType\" = key WHERE \"baseType\" IS NULL;"
psql "$DB" -c "UPDATE \"ProductTranslation\" SET \"languageCode\" = language WHERE \"languageCode\" != language OR \"languageCode\" IS NULL;"
psql "$DB" -c "UPDATE \"MenuTranslation\" SET \"languageCode\" = language WHERE \"languageCode\" != language OR \"languageCode\" IS NULL;"
psql "$DB" -c "UPDATE \"MenuSectionTranslation\" SET \"languageCode\" = language WHERE \"languageCode\" != language OR \"languageCode\" IS NULL;"

echo ""
echo "=== 4. Prisma generate + Build ==="
npx prisma generate 2>&1 | tail -2
npm run build 2>&1 | tail -5
echo "BUILD=$?"

echo ""
echo "=== 5. Restart + Test ==="
pm2 restart menucard-pro
sleep 5
for url in "api/v1/menus" "hotel-sonnblick/restaurant/abendkarte" "hotel-sonnblick/restaurant/weinkarte" "hotel-sonnblick/bar/barkarte" "admin"; do
  echo -n "  $url = "; curl -s -o /dev/null -w '%{http_code}' "http://localhost:3000/$url"; echo
done

echo ""
echo "=== 6. Datenstand ==="
psql "$DB" -c "
SELECT 'Products' as entity, count(*) FROM \"Product\"
UNION ALL SELECT 'Variants', count(*) FROM \"ProductVariant\"
UNION ALL SELECT 'VariantPrices', count(*) FROM \"VariantPrice\"
UNION ALL SELECT 'Menus', count(*) FROM \"Menu\"
UNION ALL SELECT 'Sections', count(*) FROM \"MenuSection\"
UNION ALL SELECT 'Placements', count(*) FROM \"MenuPlacement\"
UNION ALL SELECT 'Taxonomy', count(*) FROM \"TaxonomyNode\"
UNION ALL SELECT 'Allergens', count(*) FROM \"Allergen\"
ORDER BY 1;
"
