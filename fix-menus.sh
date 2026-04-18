#!/bin/bash
cd /var/www/menucard-pro
DB="postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

echo "=== 1. Barkarte -> Location 'bar' umhaengen ==="
psql "$DB" -c "
-- Barkarte von bar-lounge auf loc-bar umhaengen
UPDATE \"Menu\" SET \"locationId\" = 'loc-bar'
WHERE slug = 'barkarte' AND \"locationId\" = (SELECT id FROM \"Location\" WHERE slug = 'bar-lounge');
"

echo "=== 2. Doppelte bar-lounge Location bereinigen ==="
psql "$DB" -c "
-- QR-Codes umhaengen falls vorhanden
UPDATE \"QRCode\" SET \"locationId\" = 'loc-bar'
WHERE \"locationId\" = (SELECT id FROM \"Location\" WHERE slug = 'bar-lounge');
-- Doppelte Location loeschen
DELETE FROM \"Location\" WHERE slug = 'bar-lounge';
"

echo "=== 3. Verifikation ==="
psql "$DB" -c "
SELECT m.slug AS menu, l.slug AS location
FROM \"Menu\" m JOIN \"Location\" l ON l.id = m.\"locationId\"
ORDER BY l.slug, m.slug;
"
psql "$DB" -c "SELECT id, slug, name FROM \"Location\";"
