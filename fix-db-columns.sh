#!/bin/bash
cd /var/www/menucard-pro
DB="postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

echo "=== 1. Fehlende Spalten manuell nachtragen ==="

# TenantLanguage.language - existiert evtl. unter anderem Namen
psql "$DB" -c "
DO \$\$
BEGIN
  -- Pruefen ob 'language' existiert
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='TenantLanguage' AND column_name='language') THEN
    -- Pruefen ob 'code' oder 'languageCode' existiert (v1-Name)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='TenantLanguage' AND column_name='code') THEN
      ALTER TABLE \"TenantLanguage\" RENAME COLUMN code TO language;
      RAISE NOTICE 'TenantLanguage: code -> language umbenannt';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='TenantLanguage' AND column_name='languageCode') THEN
      ALTER TABLE \"TenantLanguage\" RENAME COLUMN \"languageCode\" TO language;
      RAISE NOTICE 'TenantLanguage: languageCode -> language umbenannt';
    ELSE
      ALTER TABLE \"TenantLanguage\" ADD COLUMN language TEXT NOT NULL DEFAULT 'de';
      RAISE NOTICE 'TenantLanguage: language hinzugefuegt';
    END IF;
  ELSE
    RAISE NOTICE 'TenantLanguage.language existiert bereits';
  END IF;
END \$\$;
"

# Menu.status
psql "$DB" -c "
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Menu' AND column_name='status') THEN
    ALTER TABLE \"Menu\" ADD COLUMN status TEXT NOT NULL DEFAULT 'ACTIVE';
    RAISE NOTICE 'Menu.status hinzugefuegt';
  ELSE
    RAISE NOTICE 'Menu.status existiert bereits';
  END IF;
END \$\$;
"

# Location.isActive + sortOrder
psql "$DB" -c "
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Location' AND column_name='isActive') THEN
    ALTER TABLE \"Location\" ADD COLUMN \"isActive\" BOOLEAN NOT NULL DEFAULT true;
    RAISE NOTICE 'Location.isActive hinzugefuegt';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='Location' AND column_name='sortOrder') THEN
    ALTER TABLE \"Location\" ADD COLUMN \"sortOrder\" INT NOT NULL DEFAULT 0;
    RAISE NOTICE 'Location.sortOrder hinzugefuegt';
  END IF;
END \$\$;
"

# QRCode.locationId + scans
psql "$DB" -c "
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='QRCode' AND column_name='locationId') THEN
    ALTER TABLE \"QRCode\" ADD COLUMN \"locationId\" TEXT;
    RAISE NOTICE 'QRCode.locationId hinzugefuegt';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='QRCode' AND column_name='scans') THEN
    ALTER TABLE \"QRCode\" ADD COLUMN scans INT NOT NULL DEFAULT 0;
    RAISE NOTICE 'QRCode.scans hinzugefuegt';
  END IF;
END \$\$;
"

# DesignTemplate.isArchived
psql "$DB" -c "
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='DesignTemplate' AND column_name='isArchived') THEN
    ALTER TABLE \"DesignTemplate\" ADD COLUMN \"isArchived\" BOOLEAN NOT NULL DEFAULT false;
    RAISE NOTICE 'DesignTemplate.isArchived hinzugefuegt';
  END IF;
END \$\$;
"

echo ""
echo "=== 2. Prisma db push ==="
npx prisma db push --accept-data-loss 2>&1 | tail -5

echo ""
echo "=== 3. Prisma generate ==="
npx prisma generate 2>&1 | tail -2

echo ""
echo "=== 4. Build ==="
npm run build 2>&1 | tail -5
echo "BUILD=$?"

echo ""
echo "=== 5. Restart + Test ==="
pm2 restart menucard-pro
sleep 5
echo -n "  menus="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/api/v1/menus; echo
echo -n "  abendkarte="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/restaurant/abendkarte; echo
echo -n "  weinkarte="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/restaurant/weinkarte; echo
echo -n "  barkarte="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/bar/barkarte; echo
echo -n "  admin="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/admin; echo
echo -n "  taxonomy="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/api/v1/taxonomy; echo
