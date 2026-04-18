#!/bin/bash
cd /var/www/menucard-pro
DB="postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

echo "=== TaxRate Spalten ==="
psql "$DB" -c "SELECT column_name FROM information_schema.columns WHERE table_name='TaxRate';"

echo ""
echo "=== TaxRate Daten ==="
psql "$DB" -c 'SELECT * FROM "TaxRate";'

echo ""
echo "=== Menus API Fehler ==="
curl -s http://localhost:3000/api/v1/menus

echo ""
echo ""
echo "=== TaxRate.percentage fixen ==="
psql "$DB" -c "
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='TaxRate' AND column_name='percentage') THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='TaxRate' AND column_name='rate') THEN
      ALTER TABLE \"TaxRate\" RENAME COLUMN rate TO percentage;
      RAISE NOTICE 'TaxRate: rate -> percentage umbenannt';
    ELSE
      ALTER TABLE \"TaxRate\" ADD COLUMN percentage DECIMAL NOT NULL DEFAULT 0;
      RAISE NOTICE 'TaxRate: percentage hinzugefuegt';
    END IF;
  ELSE
    RAISE NOTICE 'TaxRate.percentage existiert bereits';
  END IF;
END \$\$;
"

echo ""
echo "=== Prisma db push ==="
npx prisma db push --accept-data-loss 2>&1 | tail -5

echo ""
echo "=== Prisma generate + Build ==="
npx prisma generate 2>&1 | tail -2
npm run build 2>&1 | tail -5
echo "BUILD=$?"

echo ""
echo "=== Restart + Test ==="
pm2 restart menucard-pro
sleep 5
echo -n "  menus="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/api/v1/menus; echo
echo -n "  abendkarte="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/restaurant/abendkarte; echo
echo -n "  weinkarte="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/restaurant/weinkarte; echo
