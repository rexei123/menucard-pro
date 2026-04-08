#!/bin/bash
# Seeds all 7 Hotel Sonnblick Gourmet Menus
cd /var/www/menucard-pro

cat > prisma/seed-real.ts << 'SEEDEOF'
import { PrismaClient, MenuType, ItemType, UserRole } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🗑️  Clearing old data...');
  await prisma.analyticsEvent.deleteMany();
  await prisma.qRCode.deleteMany();
  await prisma.menuItemAllergen.deleteMany();
  await prisma.menuItemAdditive.deleteMany();
  await prisma.menuItemTag.deleteMany();
  await prisma.menuItemMedia.deleteMany();
  await prisma.priceVariantTranslation.deleteMany();
  await prisma.priceVariant.deleteMany();
  await prisma.wineProfile.deleteMany();
  await prisma.beverageDetail.deleteMany();
  await prisma.inventory.deleteMany();
  await prisma.pairing.deleteMany();
  await prisma.menuItemTranslation.deleteMany();
  await prisma.menuItem.deleteMany();
  await prisma.menuSectionTranslation.deleteMany();
  await prisma.menuSection.deleteMany();
  await prisma.menuTranslation.deleteMany();
  await prisma.menu.deleteMany();
  await prisma.locationTranslation.deleteMany();
  await prisma.location.deleteMany();
  await prisma.allergenTranslation.deleteMany();
  await prisma.allergen.deleteMany();
  await prisma.additiveTranslation.deleteMany();
  await prisma.additive.deleteMany();
  await prisma.tagTranslation.deleteMany();
  await prisma.tag.deleteMany();
  await prisma.tenantLanguage.deleteMany();
  await prisma.theme.deleteMany();
  await prisma.media.deleteMany();
  await prisma.user.deleteMany();
  await prisma.timeRule.deleteMany();
  await prisma.tenant.deleteMany();

  console.log('🌱 Seeding Hotel Sonnblick...');

  // ─── TENANT ───
  const tenant = await prisma.tenant.create({ data: {
    name: 'Hotel Sonnblick', slug: 'hotel-sonnblick',
    website: 'https://www.hotel-sonnblick.at', email: 'info@hotel-sonnblick.at', phone: '+43 6541 6340',
  }});

  // ─── LANGUAGES ───
  await prisma.tenantLanguage.createMany({ data: [
    { tenantId: tenant.id, code: 'de', name: 'Deutsch', isDefault: true, sortOrder: 0 },
    { tenantId: tenant.id, code: 'en', name: 'English', isDefault: false, sortOrder: 1 },
  ]});

  // ─── THEME ───
  await prisma.theme.create({ data: {
    tenantId: tenant.id, name: 'Sonnblick Elegant',
    primaryColor: '#1a1a1a', accentColor: '#8B6914', backgroundColor: '#FAFAF8', textColor: '#1a1a1a',
    fontHeading: 'Playfair Display', fontBody: 'Source Sans 3',
  }});

  // ─── USER ───
  const pwHash = await bcrypt.hash('Sonnblick2024!', 12);
  await prisma.user.create({ data: {
    tenantId: tenant.id, email: 'admin@hotel-sonnblick.at', passwordHash: pwHash,
    firstName: 'Admin', lastName: 'Sonnblick', role: UserRole.OWNER,
  }});

  // ─── TAGS ───
  const tagDefs = [
    { slug: 'vegetarisch', color: '#22c55e', icon: '🌿', de: 'Vegetarisch', en: 'Vegetarian' },
    { slug: 'fisch', color: '#3b82f6', icon: '🐟', de: 'Fisch', en: 'Fish' },
    { slug: 'fleisch', color: '#dc2626', icon: '🥩', de: 'Fleisch', en: 'Meat' },
    { slug: 'regional', color: '#a855f7', icon: '🏔️', de: 'Regional', en: 'Regional' },
    { slug: 'hausgemacht', color: '#f97316', icon: '👨‍🍳', de: 'Hausgemacht', en: 'Homemade' },
    { slug: 'premium', color: '#8B6914', icon: '⭐', de: 'Premium', en: 'Premium' },
  ];
  const tags: Record<string, string> = {};
  for (const t of tagDefs) {
    const tag = await prisma.tag.create({ data: { tenantId: tenant.id, slug: t.slug, color: t.color, icon: t.icon } });
    await prisma.tagTranslation.createMany({ data: [
      { tagId: tag.id, languageCode: 'de', name: t.de },
      { tagId: tag.id, languageCode: 'en', name: t.en },
    ]});
    tags[t.slug] = tag.id;
  }

  // ─── LOCATION ───
  const restaurant = await prisma.location.create({ data: {
    tenantId: tenant.id, name: 'Restaurant', slug: 'restaurant',
    address: 'Dorfstraße 174, 5753 Saalbach, Österreich',
    latitude: 47.3917, longitude: 12.6361,
  }});
  await prisma.locationTranslation.createMany({ data: [
    { locationId: restaurant.id, languageCode: 'de', name: 'Restaurant', description: 'Unser Haubenrestaurant mit regionaler und internationaler Küche' },
    { locationId: restaurant.id, languageCode: 'en', name: 'Restaurant', description: 'Our award-winning restaurant with regional and international cuisine' },
  ]});

  // ─── HELPER: Create menu item ───
  async function createItem(sectionId: string, sortOrder: number, de: { name: string; desc: string }, en: { name: string; desc: string }, price?: number, tagSlugs: string[] = []) {
    const item = await prisma.menuItem.create({ data: {
      sectionId, type: ItemType.FOOD, sortOrder, isActive: true,
      translations: { create: [
        { languageCode: 'de', name: de.name, shortDescription: de.desc },
        { languageCode: 'en', name: en.name, shortDescription: en.desc },
      ]},
      priceVariants: price ? { create: [{ price, currency: 'EUR', isDefault: true }] } : undefined,
    }});
    for (const slug of tagSlugs) {
      if (tags[slug]) await prisma.menuItemTag.create({ data: { menuItemId: item.id, tagId: tags[slug] } });
    }
    return item;
  }

  // ─── HELPER: Create a full gourmet menu ───
  async function createGourmetMenu(slug: string, sortOrder: number, titleDe: string, titleEn: string, price: number,
    soup: { de: string; en: string; price: number },
    entre: { de: string; en: string; price: number },
    mains: { de: { name: string; desc: string }; en: { name: string; desc: string }; tags?: string[] }[],
    desserts: { de: { name: string; desc: string }; en: { name: string; desc: string } }[],
  ) {
    const menu = await prisma.menu.create({ data: {
      locationId: restaurant.id, type: MenuType.EVENT, slug, sortOrder, publishedAt: new Date(),
      translations: { create: [
        { languageCode: 'de', name: `Gourmet Menü – ${titleDe}`, description: `3 Gang Gourmet Menü pro Person € ${price.toFixed(2)}` },
        { languageCode: 'en', name: `Gourmet Menu – ${titleEn}`, description: `3 course Gourmet menu per person € ${price.toFixed(2)}` },
      ]},
    }});

    // Buffet section
    const buffet = await prisma.menuSection.create({ data: {
      menuId: menu.id, slug: 'buffet', sortOrder: 0, icon: '🥗',
      translations: { create: [
        { languageCode: 'de', name: 'Salate und Vorspeisen vom Buffet' },
        { languageCode: 'en', name: 'Salads and starters from the buffet' },
      ]},
    }});

    // Soup
    const suppen = await prisma.menuSection.create({ data: {
      menuId: menu.id, slug: 'suppe', sortOrder: 1, icon: '🍵',
      translations: { create: [
        { languageCode: 'de', name: 'Suppe', description: 'Im 5-Gang Menü inkludiert' },
        { languageCode: 'en', name: 'Soup', description: 'Included in the 5-course menu' },
      ]},
    }});
    await createItem(suppen.id, 0, { name: soup.de, desc: '' }, { name: soup.en, desc: '' }, soup.price);

    // Zwischengericht
    const zwischen = await prisma.menuSection.create({ data: {
      menuId: menu.id, slug: 'zwischengericht', sortOrder: 2, icon: '🍽️',
      translations: { create: [
        { languageCode: 'de', name: 'Zwischengericht', description: 'Im 5-Gang Menü inkludiert' },
        { languageCode: 'en', name: 'Entremets', description: 'Included in the 5-course menu' },
      ]},
    }});
    await createItem(zwischen.id, 0, { name: entre.de, desc: '' }, { name: entre.en, desc: '' }, entre.price);

    // Hauptgerichte
    const hauptSection = await prisma.menuSection.create({ data: {
      menuId: menu.id, slug: 'hauptgerichte', sortOrder: 3, icon: '🔥',
      translations: { create: [
        { languageCode: 'de', name: 'Hauptgerichte' },
        { languageCode: 'en', name: 'Main Courses' },
      ]},
    }});
    for (let i = 0; i < mains.length; i++) {
      await createItem(hauptSection.id, i, mains[i].de, mains[i].en, undefined, mains[i].tags || []);
    }

    // Desserts
    const dessertSection = await prisma.menuSection.create({ data: {
      menuId: menu.id, slug: 'desserts', sortOrder: 4, icon: '🍰',
      translations: { create: [
        { languageCode: 'de', name: 'Desserts' },
        { languageCode: 'en', name: 'Desserts' },
      ]},
    }});
    for (let i = 0; i < desserts.length; i++) {
      await createItem(dessertSection.id, i, desserts[i].de, desserts[i].en);
    }

    // Käse & Obst
    const extraSection = await prisma.menuSection.create({ data: {
      menuId: menu.id, slug: 'kaese-obst', sortOrder: 5, icon: '🧀',
      translations: { create: [
        { languageCode: 'de', name: 'Käse & Obst' },
        { languageCode: 'en', name: 'Cheese & Fruit' },
      ]},
    }});
    await createItem(extraSection.id, 0, { name: 'Edle Käsevariation', desc: '' }, { name: 'Noble cheese variation', desc: '' });
    await createItem(extraSection.id, 1, { name: 'Frischer Fruchtsalat', desc: '' }, { name: 'Fresh fruit salad', desc: '' });

    // QR Code
    await prisma.qRCode.create({ data: {
      locationId: restaurant.id, menuId: menu.id,
      label: titleDe, shortCode: `SB-M${sortOrder + 1}`,
    }});

    console.log(`  ✓ ${titleDe}`);
    return menu;
  }

  // ═══════════════════════════════════════════
  // MENÜ 1: Jägerabend
  // ═══════════════════════════════════════════
  await createGourmetMenu('jaegerabend', 0, 'Jägerabend', "Hunter's Evening", 45,
    { de: 'Cremige Kartoffelsuppe mit Bergkräutern', en: 'Creamy potato soup with mountain herbs', price: 5.00 },
    { de: 'Geräucherte Entenbrust mit Schüttelbrot und Feigensenf', en: 'Smoked duck breast with Schüttelbrot and fig mustard', price: 7.50 },
    [
      { de: { name: 'Ragout vom heimischen Hirsch', desc: 'serviert mit Rotkraut, Serviettenknödel und Preiselbeeren' }, en: { name: 'Local deer ragout', desc: 'served with red cabbage, napkin dumpling and cranberry' }, tags: ['fleisch', 'regional'] },
      { de: { name: 'Filet von der Gebirgsforelle', desc: 'an Mandelbutter dazu Petersilienkartoffeln und Pfannengemüse' }, en: { name: 'Mountain trout fillet', desc: 'on almond butter with parsley potatoes and sautéed vegetables' }, tags: ['fisch', 'regional'] },
      { de: { name: 'Cremiges Waldpilzrisotto', desc: 'mit Bierkäsechip' }, en: { name: 'Creamy mushroom risotto', desc: 'with beer cheese chip' }, tags: ['vegetarisch'] },
    ],
    [
      { de: { name: 'Feine Nougatknödel', desc: 'an Butterbrösel' }, en: { name: 'Delicate nougat dumplings', desc: 'on butter crumbs' } },
      { de: { name: 'Almjoghurt', desc: 'mit Waldbeeren und Crumbles' }, en: { name: 'Alp yoghurt', desc: 'with berries and crumbles' } },
    ],
  );

  // ═══════════════════════════════════════════
  // MENÜ 2: Italienischer Abend
  // ═══════════════════════════════════════════
  await createGourmetMenu('italienischer-abend', 1, 'Italienischer Abend', 'Italian Evening', 45,
    { de: 'Tomatencremesuppe mit Mozzarellakugel', en: 'Tomato cream soup with mozzarella dumpling', price: 5.00 },
    { de: 'Vitello Tonnato', en: 'Vitello Tonnato', price: 7.50 },
    [
      { de: { name: 'Piccata Milanese', desc: 'Hühnerbrust in Parmesanpanade mit Spaghetti und Tomatensauce' }, en: { name: 'Piccata Milanese', desc: 'Chicken breast in parmesan breading with spaghetti and tomato sauce' }, tags: ['fleisch'] },
      { de: { name: 'Miesmuscheln', desc: 'in Weißweinsud mit Knoblauchbrot' }, en: { name: 'Mussels', desc: 'in white wine sauce with garlic bread' }, tags: ['fisch'] },
      { de: { name: 'Spinatgnocchi mit Kirschtomaten', desc: 'dazu Schmelzbutter, Parmesan und Pinienkerne' }, en: { name: 'Spinach gnocchi with cherry tomatoes', desc: 'with melted butter, parmesan and pine nuts' }, tags: ['vegetarisch'] },
    ],
    [
      { de: { name: 'Hausgemachtes Tiramisu', desc: 'an pürierten Erdbeeren' }, en: { name: 'Homemade tiramisu', desc: 'on pureed strawberries' } },
      { de: { name: 'Cremiges Stracciatella Eis', desc: 'dazu Schlagsahne' }, en: { name: 'Creamy stracciatella ice cream', desc: 'with whipped cream' } },
    ],
  );

  // ═══════════════════════════════════════════
  // MENÜ 3: Heimatabend
  // ═══════════════════════════════════════════
  await createGourmetMenu('heimatabend', 2, 'Heimatabend', 'Local Evening', 45,
    { de: 'Klare Rinderbouillon mit hausgemachten Frittaten', en: 'Clear beef broth with homemade sliced pancake', price: 5.00 },
    { de: "Oma's Erdäpfelnidei mit Kohlrabi", en: "Grandma's Erdäpfelnidei with kohlrabi", price: 7.50 },
    [
      { de: { name: 'Knuspriger Schweinsbraten', desc: 'serviert im Biersaftl mit Sauerkraut und Serviettenknödel' }, en: { name: 'Crispy roast pork', desc: 'served in beer juice with sauerkraut and napkin dumplings' }, tags: ['fleisch', 'regional'] },
      { de: { name: 'Zander aus heimischer Zucht', desc: 'dazu glacierter Zucchini und cremige Polenta' }, en: { name: 'Pikeperch from local breeding', desc: 'with glazed zucchini and creamy polenta' }, tags: ['fisch', 'regional'] },
      { de: { name: "Pinzgauer Kasnock'n", desc: 'im Pfandl serviert mit Röstzwiebel und frischem Schnittlauch' }, en: { name: 'Local cheese dumplings', desc: 'served in a pan with fried onions and fresh chives' }, tags: ['vegetarisch', 'regional'] },
    ],
    [
      { de: { name: 'Fluffiger Kaiserschmarrn', desc: 'mit Apfelmus' }, en: { name: 'Fluffy Kaiserschmarrn', desc: 'with apple sauce' } },
      { de: { name: 'Eisbecher "Mozart"', desc: 'Vanilleeis mit Mozartlikör und Schlagsahne' }, en: { name: '"Mozart" ice cream sundae', desc: 'Vanilla ice cream with Mozart liqueur and whipped cream' } },
    ],
  );

  // ═══════════════════════════════════════════
  // MENÜ 4: Amerikanischer Abend
  // ═══════════════════════════════════════════
  await createGourmetMenu('amerikanischer-abend', 3, 'Amerikanischer Abend', 'American Evening', 45,
    { de: 'Cremige Maissuppe mit Popcorn', en: 'Creamy corn soup with popcorn', price: 5.00 },
    { de: 'Frittierte Jalapeños gefüllt mit Frischkäse', en: 'Fried jalapeños stuffed with cream cheese', price: 7.50 },
    [
      { de: { name: 'Hausgemachter Beef Burger', desc: 'mit Speck und Cheddarkäse, dazu Pommes frites und Dipvariation' }, en: { name: 'Homemade beef burger', desc: 'with bacon and cheddar cheese, served with French fries and a dip variation' }, tags: ['fleisch'] },
      { de: { name: 'Kanadische Seeforelle', desc: 'dazu Ahornsirup-Sauce, grüne Bohnen und pürierte Süßkartoffeln' }, en: { name: 'Canadian lake trout', desc: 'with maple syrup sauce, green beans, and mashed sweet potatoes' }, tags: ['fisch'] },
      { de: { name: 'Vegetarischer Wrap', desc: 'gefüllt mit Avocado, Mango und Zwiebelbohne' }, en: { name: 'Vegetarian wrap', desc: 'stuffed with avocado, mango and onion bean' }, tags: ['vegetarisch'] },
    ],
    [
      { de: { name: 'New York Cheesecake', desc: 'mit Blaubeeren' }, en: { name: 'New York Cheesecake', desc: 'with blueberries' } },
      { de: { name: 'Frozen Yoghurt', desc: 'mit Schokoladensauce' }, en: { name: 'Frozen Yoghurt', desc: 'with chocolate sauce' } },
    ],
  );

  // ═══════════════════════════════════════════
  // MENÜ 5: Gala Abend
  // ═══════════════════════════════════════════
  const gala = await prisma.menu.create({ data: {
    locationId: restaurant.id, type: MenuType.EVENT, slug: 'gala-abend', sortOrder: 4, publishedAt: new Date(),
    translations: { create: [
      { languageCode: 'de', name: 'Gourmet Menü – Gala Abend', description: '5 Gang Gourmet Menü pro Person € 55,00' },
      { languageCode: 'en', name: 'Gourmet Menu – Gala Evening', description: '5 course Gourmet menu per person € 55,00' },
    ]},
  }});

  const galaBuf = await prisma.menuSection.create({ data: { menuId: gala.id, slug: 'buffet', sortOrder: 0, icon: '🥗', translations: { create: [{ languageCode: 'de', name: 'Salate und Vorspeisen vom Buffet' }, { languageCode: 'en', name: 'Salads and starters from the buffet' }] } }});
  const galaVor = await prisma.menuSection.create({ data: { menuId: gala.id, slug: 'vorspeisen', sortOrder: 1, icon: '🍵', translations: { create: [{ languageCode: 'de', name: 'Vorspeisen' }, { languageCode: 'en', name: 'Starters' }] } }});
  await createItem(galaVor.id, 0, { name: 'Steinpilzcremesuppe', desc: 'mit Prosciutto Chip' }, { name: 'Porcini mushroom cream soup', desc: 'with prosciutto chip' });
  await createItem(galaVor.id, 1, { name: 'Rote Rüben Hummus', desc: 'mit Riesengarnele' }, { name: 'Beetroot Hummus', desc: 'with king prawn' });

  const galaHaupt = await prisma.menuSection.create({ data: { menuId: gala.id, slug: 'hauptgerichte', sortOrder: 2, icon: '🔥', translations: { create: [{ languageCode: 'de', name: 'Hauptgerichte' }, { languageCode: 'en', name: 'Main Courses' }] } }});
  await createItem(galaHaupt.id, 0, { name: 'Gebratene Beiriedschnitte vom Hochlandrind', desc: 'an Pfeffer-Cognacjus mit Pfannengemüse und Estragon-Rosmarin-Kartoffelgratin' }, { name: 'Medium done sirloin slice of highland beef', desc: 'with pepper cognac jus, pan-fried vegetables and tarragon rosemary potato gratin' }, undefined, ['fleisch', 'premium']);
  await createItem(galaHaupt.id, 1, { name: 'Gegrilltes Wildlachssteak', desc: 'dazu Bärlauchrisotto und Safransauce dazu glacierte Babykarotten' }, { name: 'Grilled salmon steak', desc: 'with wild garlic risotto, saffron sauce and glazed baby carrots' }, undefined, ['fisch', 'premium']);
  await createItem(galaHaupt.id, 2, { name: 'Tagliatelle', desc: 'in leichter Trüffel-Rahm-Sauce' }, { name: 'Pasta', desc: 'in a light truffle cream sauce' }, undefined, ['vegetarisch']);

  const galaDes = await prisma.menuSection.create({ data: { menuId: gala.id, slug: 'desserts', sortOrder: 3, icon: '🍰', translations: { create: [{ languageCode: 'de', name: 'Dessert' }, { languageCode: 'en', name: 'Dessert' }] } }});
  await createItem(galaDes.id, 0, { name: 'Schokoladenvariation', desc: 'Brownie, Mousse, Panna Cotta' }, { name: 'Chocolate Variation', desc: 'Brownie, mousse, panna cotta' });

  await prisma.qRCode.create({ data: { locationId: restaurant.id, menuId: gala.id, label: 'Gala Abend', shortCode: 'SB-M5' }});
  console.log('  ✓ Gala Abend');

  // ═══════════════════════════════════════════
  // MENÜ 6: Schnitzel Abend
  // ═══════════════════════════════════════════
  await createGourmetMenu('schnitzel-abend', 5, 'Schnitzel Abend', 'Schnitzel Evening', 45,
    { de: 'Chorizo Kürbiscremesuppe', en: 'Chorizo pumpkin cream soup', price: 5.00 },
    { de: 'Geräucherter Lachs mit Sahnekren', en: 'Smoked salmon with creamed horseradish', price: 7.50 },
    [
      { de: { name: 'Wiener Schnitzel vom Kalb', desc: 'mit Petersilienkartoffeln und Preiselbeeren' }, en: { name: 'Escalope from veal "Viennese Style"', desc: 'with parsley potatoes and cranberries' }, tags: ['fleisch', 'regional'] },
      { de: { name: 'Gebratenes Welsfilet', desc: 'im Speck-Rosmarin-Mantel und Blumenkohlpüree' }, en: { name: 'Roasted catfish fillet', desc: 'in a bacon-rosemary coating and cauliflower puree' }, tags: ['fisch'] },
      { de: { name: 'Eierschwammerlgulasch', desc: 'mit Semmelknödel' }, en: { name: 'Wild mushroom goulash', desc: 'with bread dumplings' }, tags: ['vegetarisch', 'regional'] },
    ],
    [
      { de: { name: 'Warmer Schokokuchen', desc: 'serviert mit Schlagobers und Früchten' }, en: { name: 'Warm chocolate cake', desc: 'served with whipped cream and fruit' } },
      { de: { name: 'Feines Vanilleeis', desc: 'mit Eierlikör und Mandelsplittern' }, en: { name: 'Delicate vanilla ice cream', desc: 'with eggnog and almond splitters' } },
    ],
  );

  // ═══════════════════════════════════════════
  // MENÜ 7: Österreichischer Abend
  // ═══════════════════════════════════════════
  await createGourmetMenu('oesterreichischer-abend', 6, 'Österreichischer Abend', 'Austrian Evening', 45,
    { de: 'Klare Rinderbouillon mit Grießnockerl', en: 'Clear beef bouillon with semolina dumplings', price: 5.00 },
    { de: 'Handgemachter Kaspressknödel auf süßem Kraut', en: 'Handmade cheese dumpling on sweet cabbage', price: 7.50 },
    [
      { de: { name: 'Gedünsteter Zwiebelrostbraten', desc: 'mit Speckbohnen, Bratkartoffeln und gerösteten Zwiebeln' }, en: { name: 'Fried beef in gravy', desc: 'served with bacon beans, roast potatoes and fried onions' }, tags: ['fleisch', 'regional'] },
      { de: { name: 'Gegrilltes Zanderfilet', desc: 'auf Weißweinrisotto mit Gemüsevariation und Kräuterschaum' }, en: { name: 'Grilled pike perch fillet', desc: 'on white wine risotto with vegetable variation and herbal foam' }, tags: ['fisch'] },
      { de: { name: 'Tiroler Schlutzkrapfen', desc: 'gefüllt mit Spinat und Topfen, dazu braune Butter und Parmesan' }, en: { name: 'Tyrolian Ravioli', desc: 'filled with spinach and curd cheese, served with brown butter and parmesan' }, tags: ['vegetarisch', 'regional'] },
    ],
    [
      { de: { name: 'Hausgemachter Apfelstrudel', desc: 'serviert mit Vanillesauce und Schlagsahne' }, en: { name: 'Homemade apple strudel', desc: 'served with vanilla sauce and whipped cream' } },
      { de: { name: 'Wiener Eiskaffee', desc: 'mit Schlagsahne' }, en: { name: 'Viennese iced coffee', desc: 'with whipped cream' } },
    ],
  );

  // ─── SUMMARY ───
  const menuCount = await prisma.menu.count();
  const itemCount = await prisma.menuItem.count();
  const qrCount = await prisma.qRCode.count();
  console.log('');
  console.log('✅ Seed abgeschlossen!');
  console.log(`   ${menuCount} Karten, ${itemCount} Artikel, ${qrCount} QR-Codes`);
  console.log('   Login: admin@hotel-sonnblick.at / Sonnblick2024!');
}

main().catch(e => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());
SEEDEOF

echo "Seed-Script erstellt. Führe aus..."
npx tsx prisma/seed-real.ts

echo ""
echo "Rebuild..."
npx next build 2>&1 | tail -5
pm2 restart menucard-pro

echo ""
echo "✅ Fertig! Alle 7 Menüs sind jetzt live."
