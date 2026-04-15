#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Removing old MenuItem tables ==="

echo "1/4 Backup..."
pg_dump "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" > /root/menucard-pre-cleanup-$(date +%Y%m%d).sql
echo "Backup saved"

echo "2/4 Removing old models from schema..."
python3 << 'PYEOF'
c = open('prisma/schema.prisma').read()

# Remove old model blocks (each model + its fields until next model or enum)
import re

models_to_remove = [
    'MenuItem', 'MenuItemTranslation', 'PriceVariant', 'PriceVariantTranslation',
    'MenuItemAllergen', 'MenuItemAdditive', 'MenuItemTag',
    'WineProfile', 'BeverageDetail', 'MenuItemMedia'
]

for model in models_to_remove:
    # Match model block: from "model X {" to closing "}"
    pattern = r'\nmodel ' + model + r' \{[^}]+\}\n'
    c = re.sub(pattern, '\n', c)

# Remove old relation lines from other models
lines_to_remove = [
    '  items        MenuItem[]',
    '  priceVariants  PriceVariant[]',
    '  allergens      MenuItemAllergen[]',
    '  additives      MenuItemAdditive[]',
    '  tags           MenuItemTag[]',
    '  media          MenuItemMedia[]',
    '  wineProfile    WineProfile?',
    '  beverageDetail BeverageDetail?',
    '  menuItems    MenuItemAllergen[]',
    '  menuItems    MenuItemAdditive[]',
    '  menuItems    MenuItemTag[]',
    '  menuItems    MenuItemMedia[]',
    '  menuItems   MenuItemMedia[]',
]

for line in lines_to_remove:
    c = c.replace(line + '\n', '')

# Also remove Pairing model if it references old MenuItem
# Keep ProductPairing, remove old Pairing if exists
pattern_old_pairing = r'\nmodel Pairing \{[^}]+\}\n'
c = re.sub(pattern_old_pairing, '\n', c)

# Remove old PairingType if duplicated
# Keep only if referenced by ProductPairing

# Clean up multiple blank lines
c = re.sub(r'\n{3,}', '\n\n', c)

open('prisma/schema.prisma', 'w').write(c)
print('Schema cleaned')
PYEOF

echo "3/4 Dropping old tables from DB..."
psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" << 'SQL'
DROP TABLE IF EXISTS "MenuItemMedia" CASCADE;
DROP TABLE IF EXISTS "MenuItemAllergen" CASCADE;
DROP TABLE IF EXISTS "MenuItemAdditive" CASCADE;
DROP TABLE IF EXISTS "MenuItemTag" CASCADE;
DROP TABLE IF EXISTS "PriceVariantTranslation" CASCADE;
DROP TABLE IF EXISTS "PriceVariant" CASCADE;
DROP TABLE IF EXISTS "WineProfile" CASCADE;
DROP TABLE IF EXISTS "BeverageDetail" CASCADE;
DROP TABLE IF EXISTS "MenuItemTranslation" CASCADE;
DROP TABLE IF EXISTS "Pairing" CASCADE;
DROP TABLE IF EXISTS "MenuItem" CASCADE;
SELECT 'Old tables dropped' as status;
SQL

echo "4/4 Syncing schema and building..."
npx prisma db push --accept-data-loss
npm run build; pm2 restart menucard-pro

echo ""
echo "=== Old MenuItem tables removed! ==="
echo "Backup: /root/menucard-pre-cleanup-$(date +%Y%m%d).sql"
