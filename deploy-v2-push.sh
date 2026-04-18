#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Prisma Generate ==="
npx prisma generate 2>&1 | tail -3

echo ""
echo "=== Prisma DB Push (Preview) ==="
npx prisma db push 2>&1 | tail -20

echo ""
echo "=== Prisma Studio Test: Zähle v2-Tabellen ==="
node -e "
const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();
(async () => {
  try {
    const variants = await p.productVariant.count();
    const prices = await p.variantPrice.count();
    const taxonomy = await p.taxonomyNode.count();
    const products = await p.product.count();
    const menus = await p.menu.count();
    console.log('ProductVariant:', variants);
    console.log('VariantPrice:', prices);
    console.log('TaxonomyNode:', taxonomy);
    console.log('Product:', products);
    console.log('Menu:', menus);
    console.log('=== Prisma Client v2 funktioniert! ===');
  } catch(e) {
    console.error('FEHLER:', e.message);
  } finally {
    await p.\$disconnect();
  }
})();
"

echo ""
echo "=== Build ==="
npm run build 2>&1 | tail -5

echo ""
echo "=== PM2 Restart ==="
pm2 restart menucard-pro 2>&1 | tail -3

echo ""
echo "=== FERTIG ==="
