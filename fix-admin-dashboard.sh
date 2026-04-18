#!/bin/bash
cd /var/www/menucard-pro
DB="postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

echo "=== 1. Tenant.settings Spalte hinzufuegen ==="
psql "$DB" -c "
DO \$\$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Tenant' AND column_name='settings') THEN
    ALTER TABLE \"Tenant\" ADD COLUMN settings JSONB;
    RAISE NOTICE 'Tenant.settings hinzugefuegt';
  ELSE
    RAISE NOTICE 'Tenant.settings existiert bereits';
  END IF;
END \$\$;
"

echo "=== 2. Passwort zuruecksetzen ==="
HASH=$(node -e "const bcrypt = require('bcryptjs'); console.log(bcrypt.hashSync('Sonnblick2026%', 10));")
psql "$DB" -c "UPDATE \"User\" SET \"passwordHash\" = '$HASH' WHERE email = 'admin@hotel-sonnblick.at';"
echo "Passwort auf Sonnblick2026% gesetzt."

echo "=== 3. Build + Restart ==="
npm run build 2>&1 | tail -5
echo "BUILD=$?"
pm2 restart menucard-pro
