/**
 * MenuCard Pro v2 – Seed-Script
 * Erstellt alle Stammdaten, Taxonomie, 27 Testprodukte mit ~42 Varianten,
 * 3 Testkarten mit verschachtelten Sektionen und Placements.
 *
 * Ausfuehrung: npx tsx seed-v2.ts
 */
import { PrismaClient, ProductType, ProductStatus, HighlightType, TaxonomyType, PricingType, ChannelType } from '@prisma/client';

const prisma = new PrismaClient();

// ─── Hilfsfunktionen ───
function slug(s: string): string {
  return s.toLowerCase()
    .replace(/[äÄ]/g, 'ae').replace(/[öÖ]/g, 'oe').replace(/[üÜ]/g, 'ue').replace(/ß/g, 'ss')
    .replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
}

function generateShortCode(): string {
  const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  return Array.from({ length: 6 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
}

async function main() {
  console.log('=== MenuCard Pro v2 Seed ===\n');

  // ─── Tenant & Locations holen (bestehen bereits) ───
  const tenant = await prisma.tenant.findFirst();
  if (!tenant) throw new Error('Kein Tenant gefunden! Bitte zuerst Tenant anlegen.');
  console.log(`Tenant: ${tenant.name} (${tenant.id})`);

  let restaurant = await prisma.location.findFirst({ where: { tenantId: tenant.id, slug: 'restaurant' } });
  if (!restaurant) {
    restaurant = await prisma.location.create({
      data: { tenantId: tenant.id, name: 'Restaurant', slug: 'restaurant' },
    });
    console.log('  Location "Restaurant" erstellt');
  }

  let bar = await prisma.location.findFirst({ where: { tenantId: tenant.id, slug: 'bar-lounge' } });
  if (!bar) {
    bar = await prisma.location.create({
      data: { tenantId: tenant.id, name: 'Bar & Lounge', slug: 'bar-lounge' },
    });
    console.log('  Location "Bar & Lounge" erstellt');
  }

  // ═════════════════════════════════════════
  // 1. STAMMDATEN
  // ═════════════════════════════════════════
  console.log('\n--- 1. Stammdaten ---');

  // 1a. Allergene (14 EU)
  const allergenData = [
    { code: 'A', de: 'Glutenhaltiges Getreide', en: 'Cereals containing gluten', icon: 'grain' },
    { code: 'B', de: 'Krebstiere', en: 'Crustaceans', icon: 'set_meal' },
    { code: 'C', de: 'Eier', en: 'Eggs', icon: 'egg' },
    { code: 'D', de: 'Fisch', en: 'Fish', icon: 'phishing' },
    { code: 'E', de: 'Erdnuesse', en: 'Peanuts', icon: 'nutrition' },
    { code: 'F', de: 'Soja', en: 'Soybeans', icon: 'spa' },
    { code: 'G', de: 'Milch/Laktose', en: 'Milk/Lactose', icon: 'water_drop' },
    { code: 'H', de: 'Schalenfruechte', en: 'Tree nuts', icon: 'forest' },
    { code: 'L', de: 'Sellerie', en: 'Celery', icon: 'eco' },
    { code: 'M', de: 'Senf', en: 'Mustard', icon: 'local_florist' },
    { code: 'N', de: 'Sesam', en: 'Sesame', icon: 'scatter_plot' },
    { code: 'O', de: 'Sulfite', en: 'Sulphites', icon: 'science' },
    { code: 'P', de: 'Lupinen', en: 'Lupin', icon: 'grass' },
    { code: 'R', de: 'Weichtiere', en: 'Molluscs', icon: 'pool' },
  ];

  const allergenMap: Record<string, string> = {};
  for (const a of allergenData) {
    const allergen = await prisma.allergen.upsert({
      where: { tenantId_code: { tenantId: tenant.id, code: a.code } },
      update: {},
      create: {
        tenantId: tenant.id, code: a.code, icon: a.icon,
        translations: {
          create: [
            { language: 'de', name: a.de },
            { language: 'en', name: a.en },
          ],
        },
      },
    });
    allergenMap[a.code] = allergen.id;
  }
  console.log(`  ${Object.keys(allergenMap).length} Allergene`);

  // 1b. Preisebenen
  const priceLevelData = [
    { name: 'Restaurant', slug: 'restaurant', sortOrder: 0 },
    { name: 'Bar', slug: 'bar', sortOrder: 1 },
    { name: 'Room Service', slug: 'room-service', sortOrder: 2 },
    { name: 'Einkauf', slug: 'einkauf', sortOrder: 3 },
  ];

  const priceLevelMap: Record<string, string> = {};
  for (const pl of priceLevelData) {
    const level = await prisma.priceLevel.upsert({
      where: { tenantId_slug: { tenantId: tenant.id, slug: pl.slug } },
      update: {},
      create: { tenantId: tenant.id, ...pl },
    });
    priceLevelMap[pl.slug] = level.id;
  }
  console.log(`  ${Object.keys(priceLevelMap).length} Preisebenen`);

  // 1c. Steuersaetze
  const taxDrinks = await prisma.taxRate.create({
    data: { tenantId: tenant.id, name: 'Getraenke 20%', percentage: 20 },
  });
  const taxFood = await prisma.taxRate.create({
    data: { tenantId: tenant.id, name: 'Speisen 10%', percentage: 10 },
  });
  console.log('  2 Steuersaetze');

  // 1d. Fuellmengen
  const fillData = [
    { label: 'Flasche 0,75l', slug: 'flasche-075', volumeMl: 750, sortOrder: 0 },
    { label: 'Flasche 0,375l', slug: 'flasche-0375', volumeMl: 375, sortOrder: 1 },
    { label: 'Flasche 1,5l', slug: 'flasche-15', volumeMl: 1500, sortOrder: 2 },
    { label: 'Karaffe 0,5l', slug: 'karaffe-05', volumeMl: 500, sortOrder: 3 },
    { label: 'Glas 0,125l', slug: 'glas-0125', volumeMl: 125, sortOrder: 4 },
    { label: 'Glas 0,2l', slug: 'glas-02', volumeMl: 200, sortOrder: 5 },
    { label: '1/8 offen', slug: 'achtel-offen', volumeMl: 125, sortOrder: 6 },
    { label: '1/4 offen', slug: 'viertel-offen', volumeMl: 250, sortOrder: 7 },
    { label: 'Glas 2cl', slug: 'glas-2cl', volumeMl: 20, sortOrder: 8 },
    { label: 'Glas 4cl', slug: 'glas-4cl', volumeMl: 40, sortOrder: 9 },
    { label: 'Glas 0,3l', slug: 'glas-03', volumeMl: 300, sortOrder: 10 },
    { label: 'Glas 0,5l', slug: 'glas-05', volumeMl: 500, sortOrder: 11 },
    { label: 'Dose 0,33l', slug: 'dose-033', volumeMl: 330, sortOrder: 12 },
    { label: 'Dose 0,5l', slug: 'dose-05', volumeMl: 500, sortOrder: 13 },
    { label: 'Portion', slug: 'portion', volumeMl: null, sortOrder: 14 },
    { label: 'Espresso', slug: 'espresso', volumeMl: 30, sortOrder: 15 },
    { label: 'Tasse', slug: 'tasse', volumeMl: 200, sortOrder: 16 },
    { label: 'Standard', slug: 'standard', volumeMl: null, sortOrder: 17 },
  ];

  const fillMap: Record<string, string> = {};
  for (const f of fillData) {
    const fq = await prisma.fillQuantity.upsert({
      where: { tenantId_slug: { tenantId: tenant.id, slug: f.slug } },
      update: {},
      create: { tenantId: tenant.id, label: f.label, slug: f.slug, volumeMl: f.volumeMl, sortOrder: f.sortOrder },
    });
    fillMap[f.slug] = fq.id;
  }
  console.log(`  ${Object.keys(fillMap).length} Fuellmengen`);

  // ═════════════════════════════════════════
  // 2. TAXONOMIE
  // ═════════════════════════════════════════
  console.log('\n--- 2. Taxonomie ---');

  type TaxTree = { name: string; slug: string; icon?: string; children?: TaxTree[] };

  async function seedTaxonomy(type: TaxonomyType, tree: TaxTree[], parentId?: string, depth = 0) {
    for (let i = 0; i < tree.length; i++) {
      const item = tree[i];
      const node = await prisma.taxonomyNode.upsert({
        where: { tenantId_type_slug: { tenantId: tenant.id, type, slug: item.slug } },
        update: {},
        create: {
          tenantId: tenant.id, type, name: item.name, slug: item.slug,
          parentId, depth, sortOrder: i, icon: item.icon || null,
          translations: {
            create: [{ language: 'de', name: item.name }],
          },
        },
      });
      taxMap[`${type}:${item.slug}`] = node.id;
      if (item.children) {
        await seedTaxonomy(type, item.children, node.id, depth + 1);
      }
    }
  }

  const taxMap: Record<string, string> = {};

  // CATEGORY
  await seedTaxonomy(TaxonomyType.CATEGORY, [
    { name: 'Speisen', slug: 'speisen', icon: 'restaurant', children: [
      { name: 'Vorspeisen', slug: 'vorspeisen' },
      { name: 'Suppen', slug: 'suppen' },
      { name: 'Hauptgerichte', slug: 'hauptgerichte' },
      { name: 'Desserts', slug: 'desserts' },
      { name: 'Kaese & Obst', slug: 'kaese-obst' },
    ]},
    { name: 'Wein', slug: 'wein', icon: 'wine_bar', children: [
      { name: 'Weisswein', slug: 'weisswein' },
      { name: 'Rotwein', slug: 'rotwein' },
      { name: 'Rosewein', slug: 'rosewein' },
      { name: 'Schaumwein', slug: 'schaumwein' },
    ]},
    { name: 'Cocktails', slug: 'cocktails', icon: 'local_bar', children: [
      { name: 'Klassiker', slug: 'klassiker' },
      { name: 'Signature', slug: 'signature' },
    ]},
    { name: 'Spirituosen', slug: 'spirituosen', icon: 'liquor', children: [
      { name: 'Gin', slug: 'gin' },
      { name: 'Whisky', slug: 'whisky' },
      { name: 'Rum', slug: 'rum' },
      { name: 'Edelbraende', slug: 'edelbraende' },
    ]},
    { name: 'Bier', slug: 'bier', icon: 'sports_bar', children: [
      { name: 'Fassbier', slug: 'fassbier' },
      { name: 'Flaschenbier', slug: 'flaschenbier' },
    ]},
    { name: 'Alkoholfrei', slug: 'alkoholfrei', icon: 'water_drop', children: [
      { name: 'Softdrinks', slug: 'softdrinks' },
      { name: 'Saefte', slug: 'saefte' },
    ]},
    { name: 'Heisse Getraenke', slug: 'heisse-getraenke', icon: 'coffee', children: [
      { name: 'Kaffee', slug: 'kaffee' },
      { name: 'Tee', slug: 'tee' },
    ]},
  ]);

  // REGION
  await seedTaxonomy(TaxonomyType.REGION, [
    { name: 'Oesterreich', slug: 'oesterreich', icon: 'flag', children: [
      { name: 'Niederoesterreich', slug: 'niederoesterreich', children: [
        { name: 'Wachau', slug: 'wachau' },
        { name: 'Kamptal', slug: 'kamptal' },
        { name: 'Kremstal', slug: 'kremstal' },
        { name: 'Traisental', slug: 'traisental' },
      ]},
      { name: 'Burgenland', slug: 'burgenland', children: [
        { name: 'Neusiedlersee', slug: 'neusiedlersee' },
        { name: 'Mittelburgenland', slug: 'mittelburgenland' },
      ]},
      { name: 'Steiermark', slug: 'steiermark', children: [
        { name: 'Suedsteiermark', slug: 'suedsteiermark' },
      ]},
      { name: 'Wien', slug: 'wien' },
    ]},
    { name: 'Frankreich', slug: 'frankreich', children: [
      { name: 'Champagne', slug: 'champagne' },
      { name: 'Bordeaux', slug: 'bordeaux' },
      { name: 'Provence', slug: 'provence' },
    ]},
    { name: 'Italien', slug: 'italien', children: [
      { name: 'Venetien', slug: 'venetien' },
      { name: 'Toskana', slug: 'toskana' },
      { name: 'Suedtirol', slug: 'suedtirol' },
    ]},
    { name: 'Spanien', slug: 'spanien', children: [
      { name: 'Rias Baixas', slug: 'rias-baixas' },
    ]},
  ]);

  // GRAPE
  await seedTaxonomy(TaxonomyType.GRAPE, [
    { name: 'Gruener Veltliner', slug: 'gruener-veltliner' },
    { name: 'Riesling', slug: 'riesling' },
    { name: 'Sauvignon Blanc', slug: 'sauvignon-blanc' },
    { name: 'Chardonnay', slug: 'chardonnay' },
    { name: 'Muskateller', slug: 'muskateller' },
    { name: 'Pinot Blanc', slug: 'pinot-blanc' },
    { name: 'Welschriesling', slug: 'welschriesling' },
    { name: 'Zweigelt', slug: 'zweigelt' },
    { name: 'Blaufraenkisch', slug: 'blaufraenkisch' },
    { name: 'St. Laurent', slug: 'st-laurent' },
    { name: 'Pinot Noir', slug: 'pinot-noir' },
    { name: 'Cabernet Sauvignon', slug: 'cabernet-sauvignon' },
    { name: 'Merlot', slug: 'merlot' },
  ]);

  // STYLE
  await seedTaxonomy(TaxonomyType.STYLE, [
    { name: 'Trocken', slug: 'trocken' },
    { name: 'Halbtrocken', slug: 'halbtrocken' },
    { name: 'Lieblich', slug: 'lieblich' },
    { name: 'Brut', slug: 'brut' },
    { name: 'Extra Brut', slug: 'extra-brut' },
  ]);

  // DIET
  await seedTaxonomy(TaxonomyType.DIET, [
    { name: 'Vegetarisch', slug: 'vegetarisch', icon: 'eco' },
    { name: 'Vegan', slug: 'vegan', icon: 'spa' },
    { name: 'Glutenfrei', slug: 'glutenfrei', icon: 'grain' },
    { name: 'Laktosefrei', slug: 'laktosefrei', icon: 'water_drop' },
  ]);

  // CUISINE
  await seedTaxonomy(TaxonomyType.CUISINE, [
    { name: 'Oesterreichisch', slug: 'oesterreichisch' },
    { name: 'Italienisch', slug: 'italienisch' },
    { name: 'Franzoesisch', slug: 'franzoesisch' },
    { name: 'International', slug: 'international' },
  ]);

  console.log(`  ${Object.keys(taxMap).length} Taxonomie-Nodes`);

  // ═════════════════════════════════════════
  // 3. PRODUKTE MIT VARIANTEN
  // ═════════════════════════════════════════
  console.log('\n--- 3. Produkte ---');

  type ProductDef = {
    type: ProductType;
    nameDe: string;
    nameEn: string;
    shortDe?: string;
    shortEn?: string;
    variants: { fill: string; skuSuffix: string; isDefault: boolean; prices: { level: string; sell: number; cost?: number }[] }[];
    taxonomy: string[]; // keys like "CATEGORY:vorspeisen"
    allergens?: string[]; // codes like "A", "C"
    wine?: { winery?: string; vintage?: number; aging?: string; tastingNotes?: string; servingTemp?: string; foodPairing?: string };
    beverage?: { brand?: string; alcoholContent?: number; servingStyle?: string; garnish?: string; glassType?: string };
    highlight?: HighlightType;
  };

  const products: ProductDef[] = [
    // ─── SPEISEN (8) ───
    {
      type: 'FOOD', nameDe: 'Rindscarpaccio', nameEn: 'Beef Carpaccio',
      shortDe: 'Hauchdünn geschnitten mit Parmesan und Rucola', shortEn: 'Thinly sliced with Parmesan and rocket',
      variants: [{ fill: 'portion', skuSuffix: 'P', isDefault: true, prices: [{ level: 'restaurant', sell: 16.90, cost: 5.20 }] }],
      taxonomy: ['CATEGORY:vorspeisen', 'CUISINE:oesterreichisch'], allergens: ['O'],
    },
    {
      type: 'FOOD', nameDe: 'Kuerbiscremesuppe', nameEn: 'Pumpkin Cream Soup',
      shortDe: 'Mit Kuerbiskernoel und gerösteten Kernen', shortEn: 'With pumpkin seed oil and roasted seeds',
      variants: [{ fill: 'portion', skuSuffix: 'P', isDefault: true, prices: [{ level: 'restaurant', sell: 9.50, cost: 2.80 }] }],
      taxonomy: ['CATEGORY:suppen', 'DIET:vegetarisch'], allergens: ['G'],
    },
    {
      type: 'FOOD', nameDe: 'Wiener Schnitzel', nameEn: 'Wiener Schnitzel',
      shortDe: 'Vom Kalb, mit Preiselbeeren und Petersilkartoffeln', shortEn: 'Veal, with lingonberries and parsley potatoes',
      variants: [{ fill: 'portion', skuSuffix: 'P', isDefault: true, prices: [{ level: 'restaurant', sell: 26.90, cost: 9.50 }] }],
      taxonomy: ['CATEGORY:hauptgerichte', 'CUISINE:oesterreichisch'], allergens: ['A', 'C'],
      highlight: 'SIGNATURE',
    },
    {
      type: 'FOOD', nameDe: 'Rinderfilet', nameEn: 'Beef Fillet',
      shortDe: 'Mit Rotwein-Jus und Saisongemuese', shortEn: 'With red wine jus and seasonal vegetables',
      variants: [{ fill: 'portion', skuSuffix: 'P', isDefault: true, prices: [{ level: 'restaurant', sell: 38.90, cost: 16.00 }] }],
      taxonomy: ['CATEGORY:hauptgerichte', 'CUISINE:oesterreichisch'], highlight: 'PREMIUM',
    },
    {
      type: 'FOOD', nameDe: 'Gebratener Saibling', nameEn: 'Pan-Fried Char',
      shortDe: 'Aus dem Pinzgau, auf Blattspinat', shortEn: 'From Pinzgau, on leaf spinach',
      variants: [{ fill: 'portion', skuSuffix: 'P', isDefault: true, prices: [{ level: 'restaurant', sell: 28.50, cost: 10.00 }] }],
      taxonomy: ['CATEGORY:hauptgerichte'], allergens: ['D'],
    },
    {
      type: 'FOOD', nameDe: 'Spinatknoedel', nameEn: 'Spinach Dumplings',
      shortDe: 'Mit brauner Butter und Parmesan', shortEn: 'With brown butter and Parmesan',
      variants: [{ fill: 'portion', skuSuffix: 'P', isDefault: true, prices: [{ level: 'restaurant', sell: 18.90, cost: 4.50 }] }],
      taxonomy: ['CATEGORY:hauptgerichte', 'DIET:vegetarisch'], allergens: ['A', 'C', 'G'],
    },
    {
      type: 'FOOD', nameDe: 'Topfenstrudel', nameEn: 'Curd Cheese Strudel',
      shortDe: 'Mit Vanillesauce', shortEn: 'With vanilla sauce',
      variants: [{ fill: 'portion', skuSuffix: 'P', isDefault: true, prices: [{ level: 'restaurant', sell: 12.50, cost: 3.20 }] }],
      taxonomy: ['CATEGORY:desserts', 'CUISINE:oesterreichisch'], allergens: ['A', 'C', 'G'],
    },
    {
      type: 'FOOD', nameDe: 'Schokoladenkuchen', nameEn: 'Chocolate Cake',
      shortDe: 'Warmer Kern, mit Himbeersorbet', shortEn: 'Warm center, with raspberry sorbet',
      variants: [{ fill: 'portion', skuSuffix: 'P', isDefault: true, prices: [{ level: 'restaurant', sell: 14.50, cost: 4.00 }] }],
      taxonomy: ['CATEGORY:desserts'], allergens: ['A', 'C', 'G', 'H'],
    },

    // ─── WEINE (10) ───
    {
      type: 'WINE', nameDe: 'Gruener Veltliner Federspiel Domaene Wachau 2023', nameEn: 'Gruener Veltliner Federspiel Domaene Wachau 2023',
      shortDe: 'Frisch, mineralisch, Steinobst', shortEn: 'Fresh, mineral, stone fruit',
      variants: [
        { fill: 'glas-0125', skuSuffix: 'G', isDefault: true, prices: [{ level: 'restaurant', sell: 5.20, cost: 1.80 }, { level: 'bar', sell: 5.80 }] },
        { fill: 'flasche-075', skuSuffix: 'F', isDefault: false, prices: [{ level: 'restaurant', sell: 28.00, cost: 10.80 }] },
      ],
      taxonomy: ['CATEGORY:weisswein', 'REGION:wachau', 'REGION:oesterreich', 'GRAPE:gruener-veltliner', 'STYLE:trocken'],
      wine: { winery: 'Domaene Wachau', vintage: 2023, tastingNotes: 'Steinobst, weisser Pfeffer, mineralisch', servingTemp: '10-12°C', foodPairing: 'Fisch, Geflügel, Salate' },
      allergens: ['O'],
    },
    {
      type: 'WINE', nameDe: 'Riesling Smaragd Hirtzberger 2022', nameEn: 'Riesling Smaragd Hirtzberger 2022',
      shortDe: 'Komplex, Pfirsich, Aprikose', shortEn: 'Complex, peach, apricot',
      variants: [
        { fill: 'glas-0125', skuSuffix: 'G', isDefault: true, prices: [{ level: 'restaurant', sell: 7.80, cost: 3.20 }, { level: 'bar', sell: 8.50 }] },
        { fill: 'flasche-075', skuSuffix: 'F', isDefault: false, prices: [{ level: 'restaurant', sell: 48.00, cost: 22.00 }] },
      ],
      taxonomy: ['CATEGORY:weisswein', 'REGION:wachau', 'REGION:oesterreich', 'GRAPE:riesling', 'STYLE:trocken'],
      wine: { winery: 'Hirtzberger', vintage: 2022, tastingNotes: 'Pfirsich, Aprikose, Feuerstein', servingTemp: '10-12°C' },
      allergens: ['O'], highlight: 'RECOMMENDATION',
    },
    {
      type: 'WINE', nameDe: 'Sauvignon Blanc Suedsteiermark Tement 2023', nameEn: 'Sauvignon Blanc Suedsteiermark Tement 2023',
      shortDe: 'Stachelbeere, Holunder, frisch', shortEn: 'Gooseberry, elderflower, fresh',
      variants: [
        { fill: 'glas-0125', skuSuffix: 'G', isDefault: true, prices: [{ level: 'restaurant', sell: 6.50, cost: 2.40 }, { level: 'bar', sell: 7.20 }] },
        { fill: 'flasche-075', skuSuffix: 'F', isDefault: false, prices: [{ level: 'restaurant', sell: 36.00, cost: 15.00 }] },
      ],
      taxonomy: ['CATEGORY:weisswein', 'REGION:suedsteiermark', 'REGION:oesterreich', 'GRAPE:sauvignon-blanc', 'STYLE:trocken'],
      wine: { winery: 'Tement', vintage: 2023, tastingNotes: 'Stachelbeere, Holunder, Zitrus', servingTemp: '8-10°C' },
      allergens: ['O'],
    },
    {
      type: 'WINE', nameDe: 'Chardonnay Reserve Velich 2021', nameEn: 'Chardonnay Reserve Velich 2021',
      shortDe: 'Reif, cremig, dezentes Holz', shortEn: 'Ripe, creamy, subtle oak',
      variants: [
        { fill: 'glas-0125', skuSuffix: 'G', isDefault: true, prices: [{ level: 'restaurant', sell: 8.90, cost: 4.00 }, { level: 'bar', sell: 9.50 }] },
        { fill: 'flasche-075', skuSuffix: 'F', isDefault: false, prices: [{ level: 'restaurant', sell: 56.00, cost: 28.00 }] },
      ],
      taxonomy: ['CATEGORY:weisswein', 'REGION:neusiedlersee', 'REGION:oesterreich', 'GRAPE:chardonnay', 'STYLE:trocken'],
      wine: { winery: 'Velich', vintage: 2021, tastingNotes: 'Butter, Vanille, reife Birne', servingTemp: '12-14°C' },
      allergens: ['O'], highlight: 'PREMIUM',
    },
    {
      type: 'WINE', nameDe: 'Zweigelt Klassik Umathum 2022', nameEn: 'Zweigelt Klassik Umathum 2022',
      shortDe: 'Kirsche, samtig, zugaenglich', shortEn: 'Cherry, velvety, approachable',
      variants: [
        { fill: 'glas-0125', skuSuffix: 'G', isDefault: true, prices: [{ level: 'restaurant', sell: 5.80, cost: 2.00 }, { level: 'bar', sell: 6.50 }] },
        { fill: 'flasche-075', skuSuffix: 'F', isDefault: false, prices: [{ level: 'restaurant', sell: 32.00, cost: 12.50 }] },
      ],
      taxonomy: ['CATEGORY:rotwein', 'REGION:neusiedlersee', 'REGION:oesterreich', 'GRAPE:zweigelt', 'STYLE:trocken'],
      wine: { winery: 'Umathum', vintage: 2022, tastingNotes: 'Kirsche, Brombeere, Gewuerze', servingTemp: '16-18°C' },
      allergens: ['O'],
    },
    {
      type: 'WINE', nameDe: 'Blaufraenkisch Ried Hochberg Moric 2021', nameEn: 'Blaufraenkisch Ried Hochberg Moric 2021',
      shortDe: 'Tiefgruendig, Tannine, dunkle Frucht', shortEn: 'Deep, tannic, dark fruit',
      variants: [
        { fill: 'glas-0125', skuSuffix: 'G', isDefault: true, prices: [{ level: 'restaurant', sell: 8.50, cost: 3.80 }, { level: 'bar', sell: 9.20 }] },
        { fill: 'flasche-075', skuSuffix: 'F', isDefault: false, prices: [{ level: 'restaurant', sell: 52.00, cost: 26.00 }] },
      ],
      taxonomy: ['CATEGORY:rotwein', 'REGION:mittelburgenland', 'REGION:oesterreich', 'GRAPE:blaufraenkisch', 'STYLE:trocken'],
      wine: { winery: 'Moric', vintage: 2021, tastingNotes: 'Brombeere, Leder, mineralisch', servingTemp: '16-18°C' },
      allergens: ['O'], highlight: 'RECOMMENDATION',
    },
    {
      type: 'WINE', nameDe: 'Pinot Noir Tatschler Bruendlmayer 2021', nameEn: 'Pinot Noir Tatschler Bruendlmayer 2021',
      shortDe: 'Elegant, Erdbeere, feine Wuerze', shortEn: 'Elegant, strawberry, fine spice',
      variants: [
        { fill: 'glas-0125', skuSuffix: 'G', isDefault: true, prices: [{ level: 'restaurant', sell: 9.50, cost: 4.50 }, { level: 'bar', sell: 10.20 }] },
        { fill: 'flasche-075', skuSuffix: 'F', isDefault: false, prices: [{ level: 'restaurant', sell: 62.00, cost: 32.00 }] },
      ],
      taxonomy: ['CATEGORY:rotwein', 'REGION:kamptal', 'REGION:oesterreich', 'GRAPE:pinot-noir', 'STYLE:trocken'],
      wine: { winery: 'Bruendlmayer', vintage: 2021, tastingNotes: 'Erdbeere, Veilchen, Nelke', servingTemp: '14-16°C' },
      allergens: ['O'],
    },
    {
      type: 'WINE', nameDe: 'Rose vom Zweigelt Pittnauer 2023', nameEn: 'Rose from Zweigelt Pittnauer 2023',
      shortDe: 'Fruchtig, Erdbeere, erfrischend', shortEn: 'Fruity, strawberry, refreshing',
      variants: [
        { fill: 'glas-0125', skuSuffix: 'G', isDefault: true, prices: [{ level: 'restaurant', sell: 5.00, cost: 1.60 }, { level: 'bar', sell: 5.50 }] },
        { fill: 'flasche-075', skuSuffix: 'F', isDefault: false, prices: [{ level: 'restaurant', sell: 26.00, cost: 9.50 }] },
      ],
      taxonomy: ['CATEGORY:rosewein', 'REGION:neusiedlersee', 'REGION:oesterreich', 'GRAPE:zweigelt'],
      wine: { winery: 'Pittnauer', vintage: 2023, tastingNotes: 'Erdbeere, Wassermelone, Kräuter', servingTemp: '8-10°C' },
      allergens: ['O'],
    },
    {
      type: 'WINE', nameDe: 'Schlumberger Sparkling Brut', nameEn: 'Schlumberger Sparkling Brut',
      shortDe: 'Oesterreichs Traditionshaus, feine Perlage', shortEn: 'Austria\'s traditional house, fine perlage',
      variants: [
        { fill: 'glas-0125', skuSuffix: 'G', isDefault: true, prices: [{ level: 'restaurant', sell: 6.50, cost: 2.20 }, { level: 'bar', sell: 7.00 }] },
        { fill: 'flasche-075', skuSuffix: 'F', isDefault: false, prices: [{ level: 'restaurant', sell: 38.00, cost: 14.00 }] },
      ],
      taxonomy: ['CATEGORY:schaumwein', 'REGION:oesterreich', 'STYLE:brut'],
      wine: { winery: 'Schlumberger', tastingNotes: 'Brioche, gruener Apfel, Zitrus', servingTemp: '6-8°C' },
      allergens: ['O'],
    },
    {
      type: 'WINE', nameDe: 'Veuve Clicquot Brut', nameEn: 'Veuve Clicquot Brut',
      shortDe: 'Champagne Grande Marque', shortEn: 'Champagne Grande Marque',
      variants: [
        { fill: 'glas-0125', skuSuffix: 'G', isDefault: true, prices: [{ level: 'restaurant', sell: 16.00, cost: 8.00 }, { level: 'bar', sell: 18.00 }] },
        { fill: 'flasche-075', skuSuffix: 'F', isDefault: false, prices: [{ level: 'restaurant', sell: 98.00, cost: 52.00 }] },
      ],
      taxonomy: ['CATEGORY:schaumwein', 'REGION:champagne', 'REGION:frankreich', 'STYLE:brut'],
      wine: { winery: 'Veuve Clicquot', tastingNotes: 'Toast, Birne, Honig', servingTemp: '6-8°C' },
      allergens: ['O'], highlight: 'PREMIUM',
    },

    // ─── COCKTAILS (4) ───
    {
      type: 'DRINK', nameDe: 'Aperol Spritz', nameEn: 'Aperol Spritz',
      shortDe: 'Aperol, Prosecco, Soda', shortEn: 'Aperol, Prosecco, Soda',
      variants: [{ fill: 'standard', skuSuffix: 'G', isDefault: true, prices: [{ level: 'bar', sell: 9.50, cost: 2.80 }] }],
      taxonomy: ['CATEGORY:cocktails', 'CATEGORY:klassiker'],
      beverage: { alcoholContent: 8, servingStyle: 'On ice', garnish: 'Orangenscheibe', glassType: 'Weinglas' },
    },
    {
      type: 'DRINK', nameDe: 'Mojito', nameEn: 'Mojito',
      shortDe: 'Rum, Limette, Minze, Soda', shortEn: 'Rum, Lime, Mint, Soda',
      variants: [{ fill: 'standard', skuSuffix: 'G', isDefault: true, prices: [{ level: 'bar', sell: 11.50, cost: 3.20 }] }],
      taxonomy: ['CATEGORY:cocktails', 'CATEGORY:klassiker'],
      beverage: { alcoholContent: 12, servingStyle: 'Muddled', garnish: 'Minze, Limette', glassType: 'Highball' },
    },
    {
      type: 'DRINK', nameDe: 'Negroni', nameEn: 'Negroni',
      shortDe: 'Gin, Campari, Vermouth', shortEn: 'Gin, Campari, Vermouth',
      variants: [{ fill: 'standard', skuSuffix: 'G', isDefault: true, prices: [{ level: 'bar', sell: 12.50, cost: 3.50 }] }],
      taxonomy: ['CATEGORY:cocktails', 'CATEGORY:klassiker'],
      beverage: { alcoholContent: 24, servingStyle: 'Stirred', garnish: 'Orangenzeste', glassType: 'Tumbler' },
    },
    {
      type: 'DRINK', nameDe: 'Sonnblick Signature', nameEn: 'Sonnblick Signature',
      shortDe: 'Unser Hauscocktail mit alpinen Kraeutern', shortEn: 'Our house cocktail with alpine herbs',
      variants: [{ fill: 'standard', skuSuffix: 'G', isDefault: true, prices: [{ level: 'bar', sell: 14.00, cost: 4.00 }] }],
      taxonomy: ['CATEGORY:cocktails', 'CATEGORY:signature'],
      beverage: { alcoholContent: 15, servingStyle: 'Shaken', garnish: 'Alpenkraeuter-Zweig', glassType: 'Coupe' },
      highlight: 'SIGNATURE',
    },

    // ─── BIER (2) ───
    {
      type: 'BEER', nameDe: 'Stiegl Goldbraeu', nameEn: 'Stiegl Goldbraeu',
      shortDe: 'Salzburger Traditionsbier', shortEn: 'Traditional Salzburg beer',
      variants: [
        { fill: 'glas-03', skuSuffix: '03', isDefault: true, prices: [{ level: 'restaurant', sell: 4.20, cost: 1.20 }, { level: 'bar', sell: 4.50 }] },
        { fill: 'glas-05', skuSuffix: '05', isDefault: false, prices: [{ level: 'restaurant', sell: 5.80, cost: 1.80 }, { level: 'bar', sell: 6.20 }] },
      ],
      taxonomy: ['CATEGORY:bier', 'CATEGORY:fassbier'],
      beverage: { brand: 'Stiegl', alcoholContent: 5.0 },
    },
    {
      type: 'BEER', nameDe: 'Edelweiss Hefeweizen', nameEn: 'Edelweiss Hefeweizen',
      shortDe: 'Naturtrueb, erfrischend', shortEn: 'Naturally cloudy, refreshing',
      variants: [
        { fill: 'glas-03', skuSuffix: '03', isDefault: true, prices: [{ level: 'restaurant', sell: 4.50, cost: 1.30 }, { level: 'bar', sell: 4.80 }] },
        { fill: 'glas-05', skuSuffix: '05', isDefault: false, prices: [{ level: 'restaurant', sell: 6.20, cost: 2.00 }, { level: 'bar', sell: 6.50 }] },
      ],
      taxonomy: ['CATEGORY:bier', 'CATEGORY:fassbier'],
      beverage: { brand: 'Edelweiss', alcoholContent: 5.3 },
      allergens: ['A'],
    },

    // ─── SONSTIGE GETRÄNKE (3) ───
    {
      type: 'COFFEE', nameDe: 'Espresso', nameEn: 'Espresso',
      shortDe: 'Italienische Roestung', shortEn: 'Italian roast',
      variants: [{ fill: 'espresso', skuSuffix: 'E', isDefault: true, prices: [{ level: 'restaurant', sell: 3.20, cost: 0.40 }, { level: 'bar', sell: 3.50 }] }],
      taxonomy: ['CATEGORY:heisse-getraenke', 'CATEGORY:kaffee'],
    },
    {
      type: 'DRINK', nameDe: 'Almdudler', nameEn: 'Almdudler',
      shortDe: 'Oesterreichs Kraeuterlimonade', shortEn: 'Austria\'s herbal lemonade',
      variants: [{ fill: 'glas-03', skuSuffix: '03', isDefault: true, prices: [{ level: 'restaurant', sell: 3.80, cost: 1.00 }, { level: 'bar', sell: 4.00 }] }],
      taxonomy: ['CATEGORY:alkoholfrei', 'CATEGORY:softdrinks'],
    },
    {
      type: 'DRINK', nameDe: 'Apfelsaft naturtrueb', nameEn: 'Apple Juice Cloudy',
      shortDe: 'Aus heimischen Aepfeln', shortEn: 'From local apples',
      variants: [
        { fill: 'glas-02', skuSuffix: '02', isDefault: true, prices: [{ level: 'restaurant', sell: 3.50, cost: 0.80 }, { level: 'bar', sell: 3.80 }] },
        { fill: 'glas-05', skuSuffix: '05', isDefault: false, prices: [{ level: 'restaurant', sell: 5.50, cost: 1.50 }, { level: 'bar', sell: 5.80 }] },
      ],
      taxonomy: ['CATEGORY:alkoholfrei', 'CATEGORY:saefte'],
    },
  ];

  // Product + Variant IDs speichern fuer Placements
  const productIds: Record<string, string> = {};
  const variantIds: Record<string, string[]> = {};

  let prodCount = 0;
  let varCount = 0;

  for (const p of products) {
    const skuBase = slug(p.nameDe).substring(0, 20).toUpperCase();
    const product = await prisma.product.create({
      data: {
        tenantId: tenant.id,
        type: p.type as any,
        status: 'ACTIVE',
        sku: skuBase,
        highlightType: p.highlight || 'NONE',
        translations: {
          create: [
            { language: 'de', name: p.nameDe, shortDescription: p.shortDe },
            { language: 'en', name: p.nameEn, shortDescription: p.shortEn },
          ],
        },
      },
    });

    productIds[p.nameDe] = product.id;
    variantIds[p.nameDe] = [];
    prodCount++;

    // Varianten
    for (let vi = 0; vi < p.variants.length; vi++) {
      const v = p.variants[vi];
      const variant = await prisma.productVariant.create({
        data: {
          productId: product.id,
          fillQuantityId: fillMap[v.fill] || null,
          label: null,
          sku: `${skuBase}-${v.skuSuffix}`,
          sortOrder: vi,
          isDefault: v.isDefault,
          prices: {
            create: v.prices.map(pr => ({
              priceLevelId: priceLevelMap[pr.level],
              sellPrice: pr.sell,
              costPrice: pr.cost || null,
              pricingType: 'FIXED' as any,
              taxRateId: ['FOOD'].includes(p.type) ? taxFood.id : taxDrinks.id,
            })),
          },
        },
      });
      variantIds[p.nameDe].push(variant.id);
      varCount++;
    }

    // Taxonomy
    for (const t of p.taxonomy) {
      const key = t;
      if (taxMap[key]) {
        await prisma.productTaxonomy.create({
          data: { productId: product.id, nodeId: taxMap[key], isPrimary: p.taxonomy.indexOf(t) === 0 },
        }).catch(() => {}); // ignore duplicates
      }
    }

    // Allergens
    if (p.allergens) {
      for (const code of p.allergens) {
        if (allergenMap[code]) {
          await prisma.productAllergen.create({
            data: { productId: product.id, allergenId: allergenMap[code] },
          }).catch(() => {});
        }
      }
    }

    // WineProfile
    if (p.wine) {
      await prisma.productWineProfile.create({
        data: { productId: product.id, ...p.wine },
      });
    }

    // BeverageDetail
    if (p.beverage) {
      await prisma.productBeverageDetail.create({
        data: { productId: product.id, ...p.beverage },
      });
    }
  }

  console.log(`  ${prodCount} Produkte, ${varCount} Varianten`);

  // ═════════════════════════════════════════
  // 4. TESTKARTEN
  // ═════════════════════════════════════════
  console.log('\n--- 4. Testkarten ---');

  // Helper: Sektion mit Placements erstellen
  async function createSection(
    menuId: string, slugStr: string, nameDe: string, sortOrder: number,
    parentId: string | null, depth: number,
    placementNames?: { product: string; variantIndex: number }[]
  ): Promise<string> {
    const section = await prisma.menuSection.create({
      data: {
        menuId, slug: slugStr, sortOrder, depth, parentId,
        translations: { create: [{ language: 'de', name: nameDe }] },
      },
    });

    if (placementNames) {
      for (let i = 0; i < placementNames.length; i++) {
        const pn = placementNames[i];
        const vIds = variantIds[pn.product];
        if (vIds && vIds[pn.variantIndex]) {
          await prisma.menuPlacement.create({
            data: {
              sectionId: section.id,
              variantId: vIds[pn.variantIndex],
              sortOrder: i,
              isVisible: true,
            },
          }).catch(() => {}); // ignore unique constraint
        }
      }
    }
    return section.id;
  }

  // ─── Abendkarte ───
  const abendkarte = await prisma.menu.create({
    data: {
      locationId: restaurant.id, slug: 'abendkarte', type: 'FOOD', status: 'ACTIVE', sortOrder: 0,
      translations: { create: [{ language: 'de', name: 'Abendkarte' }, { language: 'en', name: 'Dinner Menu' }] },
    },
  });

  await createSection(abendkarte.id, 'vorspeisen', 'Vorspeisen', 0, null, 0, [
    { product: 'Rindscarpaccio', variantIndex: 0 },
    { product: 'Kuerbiscremesuppe', variantIndex: 0 },
  ]);
  await createSection(abendkarte.id, 'hauptgerichte', 'Hauptgerichte', 1, null, 0, [
    { product: 'Wiener Schnitzel', variantIndex: 0 },
    { product: 'Rinderfilet', variantIndex: 0 },
    { product: 'Gebratener Saibling', variantIndex: 0 },
    { product: 'Spinatknoedel', variantIndex: 0 },
  ]);
  await createSection(abendkarte.id, 'desserts', 'Desserts', 2, null, 0, [
    { product: 'Topfenstrudel', variantIndex: 0 },
    { product: 'Schokoladenkuchen', variantIndex: 0 },
  ]);
  console.log('  Abendkarte: 3 Sektionen, 8 Placements');

  // ─── Weinkarte (verschachtelt!) ───
  const weinkarte = await prisma.menu.create({
    data: {
      locationId: restaurant.id, slug: 'weinkarte', type: 'WINE', status: 'ACTIVE', sortOrder: 1,
      translations: { create: [{ language: 'de', name: 'Weinkarte' }, { language: 'en', name: 'Wine List' }] },
    },
  });

  // Oesterreich (Level 0)
  const atSection = await createSection(weinkarte.id, 'oesterreich', 'Oesterreich', 0, null, 0);

  // Weisswein (Level 1)
  const weissSection = await createSection(weinkarte.id, 'weisswein', 'Weisswein', 0, atSection, 1);
  // GV (Level 2)
  await createSection(weinkarte.id, 'gruener-veltliner', 'Gruener Veltliner', 0, weissSection, 2, [
    { product: 'Gruener Veltliner Federspiel Domaene Wachau 2023', variantIndex: 0 },
    { product: 'Gruener Veltliner Federspiel Domaene Wachau 2023', variantIndex: 1 },
  ]);
  await createSection(weinkarte.id, 'riesling', 'Riesling', 1, weissSection, 2, [
    { product: 'Riesling Smaragd Hirtzberger 2022', variantIndex: 0 },
    { product: 'Riesling Smaragd Hirtzberger 2022', variantIndex: 1 },
  ]);
  await createSection(weinkarte.id, 'sauvignon-blanc', 'Sauvignon Blanc', 2, weissSection, 2, [
    { product: 'Sauvignon Blanc Suedsteiermark Tement 2023', variantIndex: 0 },
    { product: 'Sauvignon Blanc Suedsteiermark Tement 2023', variantIndex: 1 },
  ]);
  await createSection(weinkarte.id, 'chardonnay', 'Chardonnay', 3, weissSection, 2, [
    { product: 'Chardonnay Reserve Velich 2021', variantIndex: 0 },
    { product: 'Chardonnay Reserve Velich 2021', variantIndex: 1 },
  ]);

  // Rotwein (Level 1)
  const rotSection = await createSection(weinkarte.id, 'rotwein', 'Rotwein', 1, atSection, 1);
  await createSection(weinkarte.id, 'zweigelt', 'Zweigelt', 0, rotSection, 2, [
    { product: 'Zweigelt Klassik Umathum 2022', variantIndex: 0 },
    { product: 'Zweigelt Klassik Umathum 2022', variantIndex: 1 },
  ]);
  await createSection(weinkarte.id, 'blaufraenkisch', 'Blaufraenkisch', 1, rotSection, 2, [
    { product: 'Blaufraenkisch Ried Hochberg Moric 2021', variantIndex: 0 },
    { product: 'Blaufraenkisch Ried Hochberg Moric 2021', variantIndex: 1 },
  ]);
  await createSection(weinkarte.id, 'pinot-noir', 'Pinot Noir', 2, rotSection, 2, [
    { product: 'Pinot Noir Tatschler Bruendlmayer 2021', variantIndex: 0 },
    { product: 'Pinot Noir Tatschler Bruendlmayer 2021', variantIndex: 1 },
  ]);

  // Rose (Level 1)
  await createSection(weinkarte.id, 'rose', 'Rose', 2, atSection, 1, [
    { product: 'Rose vom Zweigelt Pittnauer 2023', variantIndex: 0 },
    { product: 'Rose vom Zweigelt Pittnauer 2023', variantIndex: 1 },
  ]);

  // Schaumwein (Level 1)
  await createSection(weinkarte.id, 'schaumwein-at', 'Schaumwein', 3, atSection, 1, [
    { product: 'Schlumberger Sparkling Brut', variantIndex: 0 },
    { product: 'Schlumberger Sparkling Brut', variantIndex: 1 },
  ]);

  // Frankreich (Level 0)
  const frSection = await createSection(weinkarte.id, 'frankreich', 'Frankreich', 1, null, 0);
  await createSection(weinkarte.id, 'champagne', 'Champagne', 0, frSection, 1, [
    { product: 'Veuve Clicquot Brut', variantIndex: 0 },
    { product: 'Veuve Clicquot Brut', variantIndex: 1 },
  ]);

  console.log('  Weinkarte: 14 Sektionen (3 Ebenen), 20 Placements');

  // ─── Barkarte ───
  const barkarte = await prisma.menu.create({
    data: {
      locationId: bar.id, slug: 'barkarte', type: 'BAR', status: 'ACTIVE', sortOrder: 0,
      translations: { create: [{ language: 'de', name: 'Barkarte' }, { language: 'en', name: 'Bar Menu' }] },
    },
  });

  await createSection(barkarte.id, 'cocktails', 'Cocktails', 0, null, 0, [
    { product: 'Aperol Spritz', variantIndex: 0 },
    { product: 'Mojito', variantIndex: 0 },
    { product: 'Negroni', variantIndex: 0 },
    { product: 'Sonnblick Signature', variantIndex: 0 },
  ]);
  await createSection(barkarte.id, 'bier', 'Bier', 1, null, 0, [
    { product: 'Stiegl Goldbraeu', variantIndex: 0 },
    { product: 'Stiegl Goldbraeu', variantIndex: 1 },
    { product: 'Edelweiss Hefeweizen', variantIndex: 0 },
    { product: 'Edelweiss Hefeweizen', variantIndex: 1 },
  ]);
  await createSection(barkarte.id, 'wein-offen', 'Wein offen', 2, null, 0, [
    { product: 'Gruener Veltliner Federspiel Domaene Wachau 2023', variantIndex: 0 }, // gleiche Variante!
    { product: 'Rose vom Zweigelt Pittnauer 2023', variantIndex: 0 },
  ]);
  await createSection(barkarte.id, 'alkoholfrei', 'Alkoholfrei', 3, null, 0, [
    { product: 'Almdudler', variantIndex: 0 },
    { product: 'Apfelsaft naturtrueb', variantIndex: 0 },
    { product: 'Apfelsaft naturtrueb', variantIndex: 1 },
  ]);
  await createSection(barkarte.id, 'kaffee', 'Kaffee', 4, null, 0, [
    { product: 'Espresso', variantIndex: 0 },
  ]);
  console.log('  Barkarte: 5 Sektionen, 14 Placements');

  // ═════════════════════════════════════════
  // 5. QR-CODES
  // ═════════════════════════════════════════
  console.log('\n--- 5. QR-Codes ---');

  for (const menu of [abendkarte, weinkarte, barkarte]) {
    await prisma.qRCode.create({
      data: {
        menuId: menu.id,
        shortCode: generateShortCode(),
        label: `QR ${menu.slug}`,
        isActive: true,
      },
    });
  }
  console.log('  3 QR-Codes');

  // ═════════════════════════════════════════
  // ZUSAMMENFASSUNG
  // ═════════════════════════════════════════
  console.log('\n========================================');
  console.log('  SEED v2 ABGESCHLOSSEN');
  console.log('========================================');
  console.log(`  Produkte:   ${prodCount}`);
  console.log(`  Varianten:  ${varCount}`);
  console.log(`  Allergene:  ${Object.keys(allergenMap).length}`);
  console.log(`  Taxonomie:  ${Object.keys(taxMap).length} Nodes`);
  console.log(`  Karten:     3 (Abendkarte, Weinkarte, Barkarte)`);
  console.log(`  QR-Codes:   3`);
  console.log('========================================\n');
}

main()
  .catch(e => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
