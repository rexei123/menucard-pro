#!/bin/bash
cd /var/www/menucard-pro

cat > prisma/seed-bar.ts << 'SEEDEOF'
import { PrismaClient, MenuType, ItemType, BeverageCategory } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  console.log('🍸 Seeding Barkarte...');

  const tenant = await prisma.tenant.findUnique({ where: { slug: 'hotel-sonnblick' } });
  if (!tenant) throw new Error('Tenant not found! Run seed-menus first.');

  // ─── BAR LOCATION ───
  let bar = await prisma.location.findFirst({ where: { tenantId: tenant.id, slug: 'bar' } });
  if (!bar) {
    bar = await prisma.location.create({ data: {
      tenantId: tenant.id, name: 'Bar & Lounge', slug: 'bar',
      address: 'Dorfstraße 174, 5753 Saalbach, Österreich', sortOrder: 1,
    }});
    await prisma.locationTranslation.createMany({ data: [
      { locationId: bar.id, languageCode: 'de', name: 'Bar & Lounge', description: 'Cocktails, Weine und Drinks in gemütlicher Atmosphäre' },
      { locationId: bar.id, languageCode: 'en', name: 'Bar & Lounge', description: 'Cocktails, wines and drinks in a cozy atmosphere' },
    ]});
  }
  console.log('  ✓ Location: Bar & Lounge');

  // Delete existing bar menus
  const existingMenus = await prisma.menu.findMany({ where: { locationId: bar.id } });
  for (const m of existingMenus) {
    await prisma.menu.delete({ where: { id: m.id } }).catch(() => {});
  }

  // ─── BARKARTE ───
  const barkarte = await prisma.menu.create({ data: {
    locationId: bar.id, type: MenuType.BAR, slug: 'barkarte', sortOrder: 0, publishedAt: new Date(),
    translations: { create: [
      { languageCode: 'de', name: 'Barkarte', description: 'Hotelbar Sonnblick' },
      { languageCode: 'en', name: 'Bar Menu', description: 'Hotel bar Sonnblick' },
    ]},
  }});

  // Helper
  async function addDrink(sectionId: string, sortOrder: number, name: string, descDe: string, descEn: string, price: number, volume?: string, category?: BeverageCategory, alcohol?: number) {
    await prisma.menuItem.create({ data: {
      sectionId, type: ItemType.DRINK, sortOrder,
      translations: { create: [
        { languageCode: 'de', name, shortDescription: descDe },
        { languageCode: 'en', name, shortDescription: descEn },
      ]},
      priceVariants: { create: [{ price, currency: 'EUR', isDefault: true, volume: volume || null }] },
      beverageDetail: category ? { create: { category, alcoholContent: alcohol, carbonated: false } } : undefined,
    }});
  }

  async function addDrinkMultiPrice(sectionId: string, sortOrder: number, name: string, descDe: string, descEn: string, prices: { label: string; price: number; volume: string; isDefault?: boolean }[], category?: BeverageCategory) {
    await prisma.menuItem.create({ data: {
      sectionId, type: ItemType.DRINK, sortOrder,
      translations: { create: [
        { languageCode: 'de', name, shortDescription: descDe },
        { languageCode: 'en', name, shortDescription: descEn },
      ]},
      priceVariants: { create: prices.map((p, i) => ({ label: p.label, price: p.price, currency: 'EUR', volume: p.volume, sortOrder: i, isDefault: p.isDefault || false })) },
      beverageDetail: category ? { create: { category, carbonated: false } } : undefined,
    }});
  }

  let s: number;

  // ═══════════════════════════════════════
  // SCHAUMWEIN / SPARKLING WINE
  // ═══════════════════════════════════════
  const schaumwein = await prisma.menuSection.create({ data: {
    menuId: barkarte.id, slug: 'schaumwein', sortOrder: 0, icon: '🥂',
    translations: { create: [{ languageCode: 'de', name: 'Schaumwein' }, { languageCode: 'en', name: 'Sparkling Wine' }] },
  }});
  s = 0;
  await addDrinkMultiPrice(schaumwein.id, s++, 'Canella Extra Dry', 'Casa Vinicola Canella, San Donà di Piave, Italy', 'Casa Vinicola Canella, San Donà di Piave, Italy', [{label:'1/8L',price:7.20,volume:'0.125l'},{label:'Flasche',price:52.40,volume:'0.7l',isDefault:true}]);
  await addDrinkMultiPrice(schaumwein.id, s++, 'Secco Rosé Pink Ribbon', 'Leo Hillinger, Jois, Burgenland', 'Leo Hillinger, Jois, Burgenland', [{label:'1/8L',price:7.20,volume:'0.125l'},{label:'Flasche',price:52.40,volume:'0.7l',isDefault:true}]);
  await addDrink(schaumwein.id, s++, 'Schlumberger', 'Kellerei Schlumberger, Wien', 'Kellerei Schlumberger, Vienna', 57.60, '0.7l');
  await addDrink(schaumwein.id, s++, 'Perrier-Jouët Grand', 'Champagne Perrier-Jouët, Épernay', 'Champagne Perrier-Jouët, Épernay', 136.40, '0.7l');
  await addDrink(schaumwein.id, s++, 'Taittinger Réserve', 'Champagne Taittinger, Reims', 'Champagne Taittinger, Reims', 125.00, '0.7l');
  await addDrink(schaumwein.id, s++, 'Veuve Clicquot Brut', 'Champagne Veuve Clicquot Ponsardin, Reims', 'Champagne Veuve Clicquot Ponsardin, Reims', 125.00, '0.7l');
  await addDrink(schaumwein.id, s++, 'Moët & Chandon Ice Impérial', 'Champagne Moët & Chandon, Épernay', 'Champagne Moët & Chandon, Épernay', 125.00, '0.7l');
  console.log('  ✓ Schaumwein: 7');

  // ═══════════════════════════════════════
  // APERITIF
  // ═══════════════════════════════════════
  const aperitif = await prisma.menuSection.create({ data: {
    menuId: barkarte.id, slug: 'aperitif', sortOrder: 1, icon: '🍹',
    translations: { create: [{ languageCode: 'de', name: 'Aperitif' }, { languageCode: 'en', name: 'Aperitif' }] },
  }});
  s = 0;
  await addDrink(aperitif.id, s++, 'Roses for Gladys', 'Prosecco, Rosensirup & -blüten, Peachtree', 'Prosecco, rose syrup & petals, peachtree', 8.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(aperitif.id, s++, 'Lillet Wildberry', 'Lillet, Prosecco, Wildberry Tonic', 'Lillet, Prosecco, Wildberry Tonic', 8.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(aperitif.id, s++, 'Veneziano Spritz', 'Aperol, Prosecco, Soda', 'Aperol, Prosecco, soda', 9.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(aperitif.id, s++, 'Aperol Spritz', 'Aperol, Weißwein, Soda', 'Aperol, white wine, soda', 9.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(aperitif.id, s++, 'Hugo', 'Prosecco, Soda, Holundersirup, Minze', 'Prosecco, soda, elderberry syrup, mint', 7.20, undefined, BeverageCategory.COCKTAIL);
  await addDrink(aperitif.id, s++, 'Spritzer', 'Weiß, rot, süß', 'White, red, sweet', 5.80, undefined, BeverageCategory.OTHER);
  await addDrink(aperitif.id, s++, 'Vulcano', 'Himbeergeist, Sekt, Blue Curacao', 'Raspberry spirit, sparkling wine, Blue Curacao', 9.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(aperitif.id, s++, 'Gimlet', 'Gin, Limettensaft', 'Gin, lime juice', 9.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(aperitif.id, s++, 'Pablo', 'Tequila, Orangensaft, Limettensaft', 'Tequila, orange juice, lime juice', 9.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(aperitif.id, s++, 'Bellini', 'Prosecco, Pfirsichpüree', 'Prosecco, peach puree', 9.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(aperitif.id, s++, 'Negroni', 'Campari, Gin, Wermut Rosso', 'Campari, Gin, Vermouth Rosso', 9.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(aperitif.id, s++, 'Martini Dry', 'Gin, Wermut', 'Gin, Vermouth', 9.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(aperitif.id, s++, 'Bramble', 'Gin, Chambord, Limette', 'Gin, Chambord, lime', 9.30, undefined, BeverageCategory.COCKTAIL);
  console.log('  ✓ Aperitif: 13');

  // ═══════════════════════════════════════
  // LONGDRINK
  // ═══════════════════════════════════════
  const longdrink = await prisma.menuSection.create({ data: {
    menuId: barkarte.id, slug: 'longdrink', sortOrder: 2, icon: '🥃',
    translations: { create: [{ languageCode: 'de', name: 'Longdrink' }, { languageCode: 'en', name: 'Longdrink' }] },
  }});
  s = 0;
  await addDrink(longdrink.id, s++, 'Gin Berry', 'Gin, Wildberry Tonic, Limette', 'Gin, wildberry tonic, lime', 8.10);
  await addDrink(longdrink.id, s++, 'Cuba Libre', 'Havana 3, Cola, Limette', 'Havana 3, Cola, lime', 11.20);
  await addDrink(longdrink.id, s++, 'Cubata', 'Havana 7, Cola, Limette', 'Havana 7, Cola, lime', 13.30);
  await addDrink(longdrink.id, s++, 'Tequila Sunrise', 'Tequila, Orangensaft, Grenadine', 'Tequila, orange juice, grenadine', 11.20);
  await addDrink(longdrink.id, s++, 'Whiskey Longdrink', 'Cola, Fanta, Sprite', 'Cola, Fanta, Sprite', 9.80);
  await addDrink(longdrink.id, s++, 'Vodka Longdrink', 'Cola, Fanta, Sprite, Orange', 'Cola, Fanta, Sprite, Orange', 9.80);
  await addDrink(longdrink.id, s++, 'Vodka Red Bull', 'Red Bull Energy, Organics', 'Red Bull Energy, Organics', 11.20);
  await addDrink(longdrink.id, s++, 'Bacardi Longdrink', 'Cola, Fanta, Sprite, Orange', 'Cola, Fanta, Sprite, Orange', 9.80);
  console.log('  ✓ Longdrink: 8');

  // ═══════════════════════════════════════
  // SOUR & MULE
  // ═══════════════════════════════════════
  const sour = await prisma.menuSection.create({ data: {
    menuId: barkarte.id, slug: 'sour-mule', sortOrder: 3, icon: '🍋',
    translations: { create: [{ languageCode: 'de', name: 'Sour & Mule' }, { languageCode: 'en', name: 'Sour & Mule' }] },
  }});
  s = 0;
  await addDrink(sour.id, s++, 'Gin Fizz', 'Gin, Zitronensaft, Zuckersirup', 'Gin, lemon juice, sugar syrup', 9.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(sour.id, s++, 'Vodka Fizz', 'Vodka, Zitronensaft, Zuckersirup', 'Vodka, lemon juice, sugar syrup', 9.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(sour.id, s++, 'Gin Sour', 'Gin, Zitronensaft, Zuckersirup, Soda', 'Gin, lemon juice, sugar syrup, soda', 9.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(sour.id, s++, 'Averna Sour', 'Averna, Zitronensaft, Zuckersirup', 'Averna, lemon juice, sugar syrup', 9.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(sour.id, s++, 'Whisky Sour', 'Whisky, Zitronensaft, Zuckersirup', 'Whiskey, lemon juice, sugar syrup', 9.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(sour.id, s++, 'Amaretto Sour', 'Amaretto, Zitronensaft, Orangensaft', 'Amaretto, lemon juice, orange juice', 9.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(sour.id, s++, 'Moscow Mule', 'Vodka, Minze, Limette, Gingerbeer', 'Vodka, mint, lime, ginger beer', 13.50, undefined, BeverageCategory.COCKTAIL);
  await addDrink(sour.id, s++, 'Munich Mule', 'Gin, Limette, Gingerbeer', 'Gin, lime, gingerbeer', 12.50, undefined, BeverageCategory.COCKTAIL);
  console.log('  ✓ Sour & Mule: 8');

  // ═══════════════════════════════════════
  // COCKTAILS
  // ═══════════════════════════════════════
  const cocktail = await prisma.menuSection.create({ data: {
    menuId: barkarte.id, slug: 'cocktails', sortOrder: 4, icon: '🍸',
    translations: { create: [{ languageCode: 'de', name: 'Cocktails' }, { languageCode: 'en', name: 'Cocktails' }] },
  }});
  s = 0;
  await addDrink(cocktail.id, s++, 'Hurricane', 'Rum weiß & dunkel, Orangensaft', 'Rum white & dark, orange juice', 9.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(cocktail.id, s++, 'Margarita', 'Triple Sec, Tequila, Limettensaft', 'Triple sec, tequila, lime juice', 10.00, undefined, BeverageCategory.COCKTAIL);
  await addDrink(cocktail.id, s++, 'Cosmopolitan', 'Vodka, Limettensaft, Cranberrysaft', 'Vodka, lime juice, cranberry juice', 10.00, undefined, BeverageCategory.COCKTAIL);
  await addDrink(cocktail.id, s++, 'Caipirinha', 'Pitu, Limette, brauner Zucker', 'Pitu, lime, brown sugar', 10.40, undefined, BeverageCategory.COCKTAIL);
  await addDrink(cocktail.id, s++, 'Swimming Pool', 'Rum weiß, Kokossirup, Blue Curacao, Ananassaft', 'White rum, coconut syrup, blue curacao, pineapple juice', 11.40, undefined, BeverageCategory.COCKTAIL);
  await addDrink(cocktail.id, s++, 'Basil Smash', 'Bombay Sapphire, Basilikum', 'Bombay Sapphire, basil', 10.40, undefined, BeverageCategory.COCKTAIL);
  await addDrink(cocktail.id, s++, 'Long Island Ice Tea', 'Rum, Tequila, Vodka, Gin, Triple Sec, Cola', 'Rum, tequila, vodka, gin, triple sec, Cola', 14.60, undefined, BeverageCategory.COCKTAIL);
  await addDrink(cocktail.id, s++, 'Mai Tai', 'Weißer Rum, Ananas, Apricot Brandy, Mandelsirup', 'White rum, pineapple, apricot brandy, almond syrup', 11.40, undefined, BeverageCategory.COCKTAIL);
  await addDrink(cocktail.id, s++, 'Bahama Mama', 'Bacardi, Malibu, Ananassaft, Orangensaft', 'Bacardi, Malibu, pineapple juice, orange juice', 11.40, undefined, BeverageCategory.COCKTAIL);
  await addDrink(cocktail.id, s++, 'Mojito', 'Rum weiß, Limette, Pfefferminze, Soda', 'White rum, lime, peppermint, soda', 11.40, undefined, BeverageCategory.COCKTAIL);
  await addDrink(cocktail.id, s++, 'Lynchburg Lemonade', 'Whisky, Limette, Ginger Ale', 'Whiskey, lime, ginger Ale', 11.40, undefined, BeverageCategory.COCKTAIL);
  await addDrink(cocktail.id, s++, 'Rainbow', 'Vodka, Malibu, Blue Curacao, Orangensaft', 'Vodka, Malibu, Blue Curacao, orange juice', 9.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(cocktail.id, s++, 'Pina Colada', 'Rum weiß, Ananassaft, Kokossirup, Sahne', 'White rum, pineapple juice, coconut syrup, cream', 11.40, undefined, BeverageCategory.COCKTAIL);
  await addDrink(cocktail.id, s++, 'Planters Punch', 'Rum braun, Grenadine, Zitronensaft, Angostura, Orangensaft', 'Brown rum, grenadine, lemon juice, Angostura, orange juice', 11.40, undefined, BeverageCategory.COCKTAIL);
  await addDrink(cocktail.id, s++, 'Sex on the Beach', 'Vodka, Pfirsichlikör, Preiselbeersaft, Pfirsichsaft', 'Vodka, peach tree, cranberry juice, peach juice', 14.40, undefined, BeverageCategory.COCKTAIL);
  await addDrink(cocktail.id, s++, 'St. Clement', 'Gin, Bitter Lemon, Orangensaft, Rosmarin', 'Gin, bitter lemon, orange juice, rosemary', 11.40, undefined, BeverageCategory.COCKTAIL);
  await addDrink(cocktail.id, s++, 'Ruby Cooler', 'Gin, Preiselbeersaft, Ginger Ale', 'Gin, cranberry juice, ginger ale', 10.40, undefined, BeverageCategory.COCKTAIL);
  await addDrink(cocktail.id, s++, 'Bloody Mary', 'Wodka, Zitronensaft, Tomatensaft', 'Vodka, lemon juice, tomato juice', 9.30, undefined, BeverageCategory.COCKTAIL);
  console.log('  ✓ Cocktails: 18');

  // ═══════════════════════════════════════
  // DESSERT COCKTAILS
  // ═══════════════════════════════════════
  const dessertCocktail = await prisma.menuSection.create({ data: {
    menuId: barkarte.id, slug: 'dessert-cocktails', sortOrder: 5, icon: '🍫',
    translations: { create: [{ languageCode: 'de', name: 'Dessert Cocktails' }, { languageCode: 'en', name: 'Dessert Cocktails' }] },
  }});
  s = 0;
  await addDrink(dessertCocktail.id, s++, 'Espresso Martini', 'Vodka, Kaffeelikör, Espresso', 'Vodka, coffee liqueur, espresso', 9.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(dessertCocktail.id, s++, 'White Russian', 'Vodka, Kahlua, Sahne', 'Vodka, Kahlua, cream', 8.90, undefined, BeverageCategory.COCKTAIL);
  await addDrink(dessertCocktail.id, s++, 'Black Russian', 'Vodka, Kaffeelikör, Kahlua, Sahne', 'Vodka, Coffee Liqueur, Kahlua, cream', 8.90, undefined, BeverageCategory.COCKTAIL);
  await addDrink(dessertCocktail.id, s++, 'B.Q. Kiss', 'Baileys, Cointreau, Malibu', 'Baileys, Cointreau, Malibu', 9.30, undefined, BeverageCategory.COCKTAIL);
  await addDrink(dessertCocktail.id, s++, 'Irish Coffee', 'Whisky, Espresso, Sahne', 'Whiskey, espresso, cream', 8.10, undefined, BeverageCategory.COCKTAIL);
  await addDrink(dessertCocktail.id, s++, 'Lumumba', 'Heiße Schokolade & Rum', 'Hot chocolate and rum', 7.20, undefined, BeverageCategory.COCKTAIL);
  console.log('  ✓ Dessert Cocktails: 6');

  // ═══════════════════════════════════════
  // VIRGIN COCKTAILS
  // ═══════════════════════════════════════
  const virgin = await prisma.menuSection.create({ data: {
    menuId: barkarte.id, slug: 'virgin-cocktails', sortOrder: 6, icon: '🌿',
    translations: { create: [{ languageCode: 'de', name: 'Alkoholfreie Cocktails' }, { languageCode: 'en', name: 'Virgin Cocktails' }] },
  }});
  s = 0;
  await addDrink(virgin.id, s++, 'Moskito', 'Bitter Lemon, Limette, Zucker, Pfefferminze', 'Bitter lemon, lime, sugar, peppermint', 8.20, undefined, BeverageCategory.SOFT_DRINK, 0);
  await addDrink(virgin.id, s++, 'Sonnblick Kiss', 'Kokossirup, Sahne, Ananassaft, Grenadine', 'Coconut syrup, cream, pineapple juice, grenadine', 8.20, undefined, BeverageCategory.SOFT_DRINK, 0);
  await addDrink(virgin.id, s++, 'Happy Skier', 'Maracujasirup, Ananas, Orange, Zitrone', 'Passion fruit syrup, pineapple, orange, lemon', 8.20, undefined, BeverageCategory.SOFT_DRINK, 0);
  await addDrink(virgin.id, s++, 'Ipanema', 'Ginger Ale, Rohrzucker, Limette', 'Ginger ale, cane sugar, lime', 8.20, undefined, BeverageCategory.SOFT_DRINK, 0);
  await addDrink(virgin.id, s++, 'Virgin Colada', 'Ananassaft, Kokossirup, Sahne', 'Pineapple juice, coconut syrup, cream', 8.20, undefined, BeverageCategory.SOFT_DRINK, 0);
  await addDrink(virgin.id, s++, 'Virgin Mojito', 'Ginger Ale, Rohrzucker, Minze, Limette', 'Ginger ale, cane sugar, mint, lime', 8.20, undefined, BeverageCategory.SOFT_DRINK, 0);
  console.log('  ✓ Virgin Cocktails: 6');

  // ═══════════════════════════════════════
  // GIN
  // ═══════════════════════════════════════
  const gin = await prisma.menuSection.create({ data: {
    menuId: barkarte.id, slug: 'gin', sortOrder: 7, icon: '🫒',
    translations: { create: [{ languageCode: 'de', name: 'Gin' }, { languageCode: 'en', name: 'Gin' }] },
  }});
  s = 0;
  for (const [name, price] of [['Gordons',9.90],['Bombay',9.90],['White Swan Gin',12.30],['Bombay Sapphire',12.30],['Bulldog',12.30],['Deep Purple Herzog',12.30],['Hendricks',15.30],['Gin Mare',15.30],["Monkey's 47",15.30],['Le Tribute',15.30]] as [string,number][]) {
    await addDrink(gin.id, s++, name, '', '', price, '4cl', BeverageCategory.SPIRIT);
  }
  await addDrink(gin.id, s++, 'Fever Tree Tonic', 'Mediterranean Tonic Water', 'Mediterranean Tonic Water', 4.20, '0.2l', BeverageCategory.SOFT_DRINK, 0);
  console.log('  ✓ Gin: 11');

  // ═══════════════════════════════════════
  // WHISKY & SCOTCH
  // ═══════════════════════════════════════
  const whisky = await prisma.menuSection.create({ data: {
    menuId: barkarte.id, slug: 'whisky', sortOrder: 8, icon: '🥃',
    translations: { create: [{ languageCode: 'de', name: 'Whisky & Scotch' }, { languageCode: 'en', name: 'Whisky & Scotch' }] },
  }});
  s = 0;
  await addDrink(whisky.id, s++, 'Peter Affenzeller Single Malt', 'Österreich', 'Austria', 14.60, '4cl', BeverageCategory.SPIRIT);
  for (const [name, price] of [['Johnnie Walker Red Label',8.30],['Chivas Regal 12 Years',9.30],['Dimple 15 Years',14.60],['Glenkinchie 10 Years',14.60],['Dalwhinnie 15 Years',14.60],['Oban 14 Years',14.60],['Cragganmore 12 Years',14.60],['Lagavulin 16 Years',14.60],['Talisker 10 Years',14.60]] as [string,number][]) {
    await addDrink(whisky.id, s++, name, 'Scotch Whisky', 'Scotch Whisky', price, '4cl', BeverageCategory.SPIRIT);
  }
  await addDrink(whisky.id, s++, 'Tullamore D.E.W', 'Irish Blended Whiskey', 'Irish Blended Whiskey', 8.30, '4cl', BeverageCategory.SPIRIT);
  await addDrink(whisky.id, s++, "Jack Daniel's Old No. 7", 'Tennessee Whiskey', 'Tennessee Whiskey', 9.30, '4cl', BeverageCategory.SPIRIT);
  await addDrink(whisky.id, s++, 'Canadian Club', '', '', 8.30, '4cl', BeverageCategory.SPIRIT);
  console.log('  ✓ Whisky: 13');

  // ═══════════════════════════════════════
  // RUM / COGNAC / BITTER
  // ═══════════════════════════════════════
  const rum = await prisma.menuSection.create({ data: {
    menuId: barkarte.id, slug: 'rum-cognac', sortOrder: 9, icon: '🏴‍☠️',
    translations: { create: [{ languageCode: 'de', name: 'Rum / Cognac / Bitter' }, { languageCode: 'en', name: 'Rum / Cognac / Bitter' }] },
  }});
  s = 0;
  await addDrink(rum.id, s++, 'Rumonkey', '', '', 13.50, '4cl', BeverageCategory.SPIRIT);
  await addDrink(rum.id, s++, 'Diplomático Reserva Exclusiva 12', '', '', 15.60, '4cl', BeverageCategory.SPIRIT);
  await addDrink(rum.id, s++, 'Ron Zacapa Centenario 23 Years', '', '', 20.90, '4cl', BeverageCategory.SPIRIT);
  await addDrink(rum.id, s++, 'Ron Zacapa Centenario XO', '', '', 26.10, '4cl', BeverageCategory.SPIRIT);
  await addDrink(rum.id, s++, 'Havana 7 Years', '', '', 9.30, '4cl', BeverageCategory.SPIRIT);
  await addDrink(rum.id, s++, 'Rémy Martin VSOP', 'Cognac Fine Champagne AOC', 'Cognac Fine Champagne AOC', 7.20, '4cl', BeverageCategory.SPIRIT);
  await addDrink(rum.id, s++, 'Hennessy CS', 'Cognac Controlée', 'Cognac Controlée', 7.20, '4cl', BeverageCategory.SPIRIT);
  await addDrink(rum.id, s++, 'Metaxa *****', '', '', 7.20, '4cl', BeverageCategory.SPIRIT);
  await addDrink(rum.id, s++, 'Fernet Branca', '', '', 5.30, '4cl', BeverageCategory.SPIRIT);
  await addDrink(rum.id, s++, 'Ramazzotti Amaro', '', '', 5.30, '4cl', BeverageCategory.SPIRIT);
  await addDrink(rum.id, s++, 'Jägermeister', '', '', 5.30, '2cl', BeverageCategory.SPIRIT);
  console.log('  ✓ Rum/Cognac/Bitter: 11');

  // ═══════════════════════════════════════
  // LIKÖR & PORTWEIN
  // ═══════════════════════════════════════
  const likoer = await prisma.menuSection.create({ data: {
    menuId: barkarte.id, slug: 'likoer-portwein', sortOrder: 10, icon: '🍷',
    translations: { create: [{ languageCode: 'de', name: 'Likör & Portwein' }, { languageCode: 'en', name: 'Liqueur & Port Wine' }] },
  }});
  s = 0;
  for (const [name, price, vol] of [['Amaretti di Saronno',5.30,'4cl'],['Tia Maria',5.30,'4cl'],['Molinari Sambuca',5.30,'4cl'],['Grand Marnier',5.30,'4cl'],['Drambuie',5.70,'4cl'],['Baileys',5.70,'4cl'],['Kahlua',5.70,'4cl'],['Southern Comfort',8.30,'4cl'],['Chambord',8.30,'4cl'],['Kapruner Eierlikör',6.20,'2cl']] as [string,number,string][]) {
    await addDrink(likoer.id, s++, name, '', '', price, vol, BeverageCategory.SPIRIT);
  }
  for (const [name, price] of [["Taylor's Select Reserve",8.30],["Taylor's 10 Years Old Tawny",9.30],["Taylor's 20 Years Old Tawny",10.40],["Taylor's Fine White Port",7.20],["Taylor's Fine Tawny",8.30]] as [string,number][]) {
    await addDrink(likoer.id, s++, name, 'Portwein', 'Port Wine', price, '5cl', BeverageCategory.SPIRIT);
  }
  console.log('  ✓ Likör & Portwein: 15');

  // ═══════════════════════════════════════
  // BIER
  // ═══════════════════════════════════════
  const bier = await prisma.menuSection.create({ data: {
    menuId: barkarte.id, slug: 'bier', sortOrder: 11, icon: '🍺',
    translations: { create: [{ languageCode: 'de', name: 'Bier' }, { languageCode: 'en', name: 'Beer' }] },
  }});
  s = 0;
  await addDrink(bier.id, s++, 'Bier der Woche', '', 'Beer of the Week', 4.90, '0.33l', BeverageCategory.BEER);
  await addDrinkMultiPrice(bier.id, s++, 'Ottakringer Pils', 'vom Fass', 'Drafted', [{label:'Klein',price:4.10,volume:'0.2l'},{label:'Mittel',price:4.70,volume:'0.3l'},{label:'Groß',price:6.20,volume:'0.5l',isDefault:true}], BeverageCategory.BEER);
  await addDrinkMultiPrice(bier.id, s++, 'Radler', '', '', [{label:'0.3l',price:4.70,volume:'0.3l'},{label:'0.5l',price:6.20,volume:'0.5l',isDefault:true}], BeverageCategory.BEER);
  await addDrink(bier.id, s++, 'Ottakringer Null Komma Josef', 'Alkoholfrei', 'Non-alcoholic', 4.70, '0.33l', BeverageCategory.BEER);
  await addDrink(bier.id, s++, 'Paulaner Weissbier Naturtrüb', '', '', 6.20, '0.5l', BeverageCategory.BEER);
  await addDrink(bier.id, s++, 'Paulaner Weissbier Alkoholfrei', '', 'Non-alcoholic', 6.20, '0.5l', BeverageCategory.BEER);
  await addDrink(bier.id, s++, 'Heineken Premium Lager', '', '', 5.10, '0.33l', BeverageCategory.BEER);
  await addDrink(bier.id, s++, 'Stiegl Glutenfrei', '', 'Gluten-free', 4.90, '0.33l', BeverageCategory.BEER);
  console.log('  ✓ Bier: 8');

  // ═══════════════════════════════════════
  // WEIN
  // ═══════════════════════════════════════
  const wein = await prisma.menuSection.create({ data: {
    menuId: barkarte.id, slug: 'wein', sortOrder: 12, icon: '🍷',
    translations: { create: [{ languageCode: 'de', name: 'Wein' }, { languageCode: 'en', name: 'Wine' }] },
  }});
  s = 0;
  for (const [name, p8, p7] of [['Grüner Veltliner',5.10,31.40],['Chardonnay',6.20,34.50],['Sauvignon Blanc',6.20,34.50],['Rosé Cabernet',6.20,34.50],['Zweigelt',5.10,31.40],['Merlot',6.20,34.50],['Cabernet Sauvignon',6.20,34.50]] as [string,number,number][]) {
    await addDrinkMultiPrice(wein.id, s++, name, 'Weingut Schmidt, Niederrußbach, Niederösterreich', 'Weingut Schmidt, Lower Austria', [{label:'1/8L',price:p8,volume:'0.125l'},{label:'Flasche',price:p7,volume:'0.7l',isDefault:true}]);
  }
  console.log('  ✓ Wein: 7');

  // ═══════════════════════════════════════
  // EDELBRÄNDE
  // ═══════════════════════════════════════
  const edelbrand = await prisma.menuSection.create({ data: {
    menuId: barkarte.id, slug: 'edelbraende', sortOrder: 13, icon: '🫐',
    translations: { create: [{ languageCode: 'de', name: 'Edelbrände' }, { languageCode: 'en', name: 'Fine Liquor' }] },
  }});
  s = 0;
  for (const [name, price] of [['Herzog Birne',6.20],['Herzog Marille',6.20],['Herzog Vogelbeere',9.30],['Herzog Salzburger Birne',6.20],['Herzog Zwetschke',6.20],['Herzog Waldhimbeere',11.40],['Herzog Marillenlikör',6.20],['Herzog Schoko-Minze Likör',6.20],['Grappa Piave Cuore',5.30]] as [string,number][]) {
    await addDrink(edelbrand.id, s++, name, 'Edelbrand', 'Fine Liquor', price, '2cl', BeverageCategory.SPIRIT);
  }
  console.log('  ✓ Edelbrände: 9');

  // ═══════════════════════════════════════
  // ALKOHOLFREI
  // ═══════════════════════════════════════
  const alkfrei = await prisma.menuSection.create({ data: {
    menuId: barkarte.id, slug: 'alkoholfrei', sortOrder: 14, icon: '🥤',
    translations: { create: [{ languageCode: 'de', name: 'Alkoholfrei' }, { languageCode: 'en', name: 'Non-Alcoholic' }] },
  }});
  s = 0;
  await addDrinkMultiPrice(alkfrei.id, s++, 'Coca-Cola / Fanta / Sprite / Spezi', '', '', [{label:'0.25l',price:4.20,volume:'0.25l'},{label:'0.5l',price:6.30,volume:'0.5l',isDefault:true}], BeverageCategory.SOFT_DRINK);
  await addDrink(alkfrei.id, s++, 'Coca-Cola Light', '', '', 5.30, '0.33l', BeverageCategory.SOFT_DRINK);
  await addDrink(alkfrei.id, s++, 'Almdudler', '', '', 5.30, '0.33l', BeverageCategory.SOFT_DRINK);
  await addDrink(alkfrei.id, s++, 'Eistee Pfirsich / Zitrone', '', 'Iced Tea Peach / Lemon', 5.30, '0.33l', BeverageCategory.SOFT_DRINK);
  await addDrink(alkfrei.id, s++, 'Soda Zitron', '', 'Soda Lemon', 5.30, '0.5l', BeverageCategory.SOFT_DRINK);
  await addDrink(alkfrei.id, s++, 'Skiwasser', '', '', 4.70, '0.5l', BeverageCategory.SOFT_DRINK);
  await addDrink(alkfrei.id, s++, 'Holunder Gespritzt', '', 'Elderflower Spritzer', 4.70, '0.5l', BeverageCategory.SOFT_DRINK);
  await addDrinkMultiPrice(alkfrei.id, s++, 'Fruchtsäfte / Gespritzt', '', 'Fruit Juices', [{label:'0.25l',price:4.20,volume:'0.25l'},{label:'0.5l',price:6.30,volume:'0.5l',isDefault:true}], BeverageCategory.JUICE);
  await addDrink(alkfrei.id, s++, '"Rauch" Fruchtsäfte', '', '"Rauch" Fruit Juices', 5.30, '0.25l', BeverageCategory.JUICE);
  await addDrink(alkfrei.id, s++, 'Fever Tree Mediterranean Tonic', '', '', 4.20, '0.25l', BeverageCategory.SOFT_DRINK);
  await addDrink(alkfrei.id, s++, 'Red Bull / Organics', '', '', 6.80, '0.25l', BeverageCategory.SOFT_DRINK);
  console.log('  ✓ Alkoholfrei: 11');

  // ═══════════════════════════════════════
  // HEISSE GETRÄNKE
  // ═══════════════════════════════════════
  const heiss = await prisma.menuSection.create({ data: {
    menuId: barkarte.id, slug: 'heissgetraenke', sortOrder: 15, icon: '☕',
    translations: { create: [{ languageCode: 'de', name: 'Heiße Getränke' }, { languageCode: 'en', name: 'Hot Drinks' }] },
  }});
  s = 0;
  await addDrink(heiss.id, s++, 'Espresso', '', '', 4.20, undefined, BeverageCategory.HOT_DRINK, 0);
  await addDrink(heiss.id, s++, 'Espresso Doppelt', '', 'Double Espresso', 6.30, undefined, BeverageCategory.HOT_DRINK, 0);
  await addDrink(heiss.id, s++, 'Cappuccino', '', '', 5.30, undefined, BeverageCategory.HOT_DRINK, 0);
  await addDrink(heiss.id, s++, 'Latte Macchiato', '', '', 6.20, undefined, BeverageCategory.HOT_DRINK, 0);
  await addDrink(heiss.id, s++, 'Verlängerter / Americano', 'Tasse Kaffee', 'Americano', 4.70, undefined, BeverageCategory.HOT_DRINK, 0);
  await addDrink(heiss.id, s++, 'Tee', 'verschiedene Sorten', 'various flavors', 4.20, undefined, BeverageCategory.HOT_DRINK, 0);
  await addDrink(heiss.id, s++, 'Tee mit Rum', '', 'Tea with Rum', 6.20, undefined, BeverageCategory.HOT_DRINK);
  await addDrink(heiss.id, s++, 'Heiße Schokolade', '', 'Hot Chocolate', 4.70, undefined, BeverageCategory.HOT_DRINK, 0);
  await addDrink(heiss.id, s++, 'Glühwein', '', 'Mulled Wine', 7.20, undefined, BeverageCategory.HOT_DRINK);
  await addDrink(heiss.id, s++, 'Jägertee', '', "Hunter's Tea", 8.30, undefined, BeverageCategory.HOT_DRINK);
  console.log('  ✓ Heiße Getränke: 10');

  // ─── QR Code ───
  await prisma.qRCode.create({ data: { locationId: bar.id, menuId: barkarte.id, label: 'Bar & Lounge', shortCode: 'SB-BAR01' } }).catch(() => {});

  const itemCount = await prisma.menuItem.count({ where: { section: { menu: { locationId: bar.id } } } });
  console.log('');
  console.log('✅ Barkarte fertig!');
  console.log(`   ${itemCount} Getränke in 16 Kategorien`);
}

main().catch(e => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());
SEEDEOF

echo "Bar-Seed erstellt. Führe aus..."
npx tsx prisma/seed-bar.ts

echo ""
echo "Rebuild..."
npx next build 2>&1 | tail -5
pm2 restart menucard-pro

echo ""
echo "✅ Barkarte ist live!"
