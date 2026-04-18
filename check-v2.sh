#!/bin/bash
cd /var/www/menucard-pro
node -e "
const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();
(async () => {
  try {
    const v = await p.productVariant.count();
    const vp = await p.variantPrice.count();
    const tn = await p.taxonomyNode.count();
    const pr = await p.product.count();
    const mn = await p.menu.count();
    const mp = await p.menuPlacement.count();
    console.log('ProductVariant:', v);
    console.log('VariantPrice:', vp);
    console.log('TaxonomyNode:', tn);
    console.log('Product:', pr);
    console.log('Menu:', mn);
    console.log('MenuPlacement:', mp);
    console.log('--- v2 Client OK ---');
  } catch(e) { console.error('FEHLER:', e.message); }
  finally { await p.\$disconnect(); }
})();
"
