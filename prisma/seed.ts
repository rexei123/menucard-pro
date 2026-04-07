import { PrismaClient, MenuType, ItemType, WineStyle, WineBody, WineSweetness, BeverageCategory, UserRole } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding...');

  const tenant = await prisma.tenant.upsert({
    where: { slug: 'hotel-sonnblick' }, update: {},
    create: { name: 'Hotel Sonnblick', slug: 'hotel-sonnblick', website: 'https://www.hotel-sonnblick.at', email: 'info@hotel-sonnblick.at', phone: '+43 6541 6340' },
  });

  await prisma.tenantLanguage.upsert({ where: { tenantId_code: { tenantId: tenant.id, code: 'de' } }, update: {}, create: { tenantId: tenant.id, code: 'de', name: 'Deutsch', isDefault: true } });
  await prisma.tenantLanguage.upsert({ where: { tenantId_code: { tenantId: tenant.id, code: 'en' } }, update: {}, create: { tenantId: tenant.id, code: 'en', name: 'English' } });

  await prisma.theme.deleteMany({ where: { tenantId: tenant.id } });
  await prisma.theme.create({ data: { tenantId: tenant.id, name: 'Sonnblick Elegant', primaryColor: '#1a1a1a', accentColor: '#8B6914', backgroundColor: '#FAFAF8', textColor: '#1a1a1a' } });

  const pwHash = await bcrypt.hash('Sonnblick2024!', 12);
  await prisma.user.upsert({ where: { email: 'admin@hotel-sonnblick.at' }, update: {}, create: { tenantId: tenant.id, email: 'admin@hotel-sonnblick.at', passwordHash: pwHash, firstName: 'Admin', lastName: 'Sonnblick', role: UserRole.OWNER } });

  const restaurant = await prisma.location.upsert({
    where: { tenantId_slug: { tenantId: tenant.id, slug: 'restaurant' } }, update: {},
    create: { tenantId: tenant.id, name: 'Restaurant', slug: 'restaurant', address: 'Dorfstrasse 174, 5753 Saalbach' },
  });
  await prisma.locationTranslation.upsert({ where: { locationId_languageCode: { locationId: restaurant.id, languageCode: 'de' } }, update: {}, create: { locationId: restaurant.id, languageCode: 'de', name: 'Restaurant', description: 'Unser Restaurant mit regionaler Kueche' } });
  await prisma.locationTranslation.upsert({ where: { locationId_languageCode: { locationId: restaurant.id, languageCode: 'en' } }, update: {}, create: { locationId: restaurant.id, languageCode: 'en', name: 'Restaurant', description: 'Our restaurant with regional cuisine' } });

  const speisekarte = await prisma.menu.create({ data: {
    locationId: restaurant.id, type: MenuType.FOOD, slug: 'speisekarte', publishedAt: new Date(),
    translations: { create: [
      { languageCode: 'de', name: 'Speisekarte', description: 'Unsere aktuelle Speisekarte' },
      { languageCode: 'en', name: 'Menu', description: 'Our current menu' },
    ] },
  } });

  const vorspeisen = await prisma.menuSection.create({ data: {
    menuId: speisekarte.id, slug: 'vorspeisen', sortOrder: 0, icon: '🥗',
    translations: { create: [{ languageCode: 'de', name: 'Vorspeisen' }, { languageCode: 'en', name: 'Starters' }] },
  } });

  await prisma.menuItem.create({ data: {
    sectionId: vorspeisen.id, type: ItemType.FOOD, sortOrder: 0, isHighlight: true, highlightType: 'SEASONAL',
    translations: { create: [
      { languageCode: 'de', name: 'Kuerbiscremesuppe', shortDescription: 'mit Kuerbiskernoel und geroesteten Kernen' },
      { languageCode: 'en', name: 'Pumpkin Cream Soup', shortDescription: 'with pumpkin seed oil and roasted seeds' },
    ] },
    priceVariants: { create: [{ price: 12.50, currency: 'EUR', isDefault: true }] },
  } });

  await prisma.menuItem.create({ data: {
    sectionId: vorspeisen.id, type: ItemType.FOOD, sortOrder: 1, isHighlight: true, highlightType: 'RECOMMENDATION',
    translations: { create: [
      { languageCode: 'de', name: 'Beef Tartare', shortDescription: 'vom Pinzgauer Rind, klassisch angemacht' },
      { languageCode: 'en', name: 'Beef Tartare', shortDescription: 'from Pinzgau cattle, classically prepared' },
    ] },
    priceVariants: { create: [{ price: 18.90, currency: 'EUR', isDefault: true }] },
  } });

  const hauptspeisen = await prisma.menuSection.create({ data: {
    menuId: speisekarte.id, slug: 'hauptspeisen', sortOrder: 1, icon: '🍽️',
    translations: { create: [{ languageCode: 'de', name: 'Hauptspeisen' }, { languageCode: 'en', name: 'Main Courses' }] },
  } });

  await prisma.menuItem.create({ data: {
    sectionId: hauptspeisen.id, type: ItemType.FOOD, sortOrder: 0, isHighlight: true, highlightType: 'POPULAR',
    translations: { create: [
      { languageCode: 'de', name: 'Wiener Schnitzel', shortDescription: 'vom Kalb, mit Petersilkartoffeln und Preiselbeeren' },
      { languageCode: 'en', name: 'Wiener Schnitzel', shortDescription: 'veal, with parsley potatoes and lingonberries' },
    ] },
    priceVariants: { create: [{ price: 28.50, currency: 'EUR', isDefault: true }] },
  } });

  await prisma.menuItem.create({ data: {
    sectionId: hauptspeisen.id, type: ItemType.FOOD, sortOrder: 1,
    translations: { create: [
      { languageCode: 'de', name: 'Tafelspitz', shortDescription: 'mit Apfelkren und Schnittlauchsauce' },
      { languageCode: 'en', name: 'Boiled Beef', shortDescription: 'with apple horseradish and chive sauce' },
    ] },
    priceVariants: { create: [{ price: 26.90, currency: 'EUR', isDefault: true }] },
  } });

  await prisma.menuItem.create({ data: {
    sectionId: hauptspeisen.id, type: ItemType.FOOD, sortOrder: 2, isHighlight: true, highlightType: 'CHEFS_CHOICE',
    translations: { create: [
      { languageCode: 'de', name: 'Gebratener Saibling', shortDescription: 'auf Blattspinat mit Mandelbutter' },
      { languageCode: 'en', name: 'Pan-fried Arctic Char', shortDescription: 'on spinach with almond butter' },
    ] },
    priceVariants: { create: [{ price: 29.50, currency: 'EUR', isDefault: true }] },
  } });

  await prisma.menuItem.create({ data: {
    sectionId: hauptspeisen.id, type: ItemType.FOOD, sortOrder: 3,
    translations: { create: [
      { languageCode: 'de', name: 'Pinzgauer Kaesespaetzle', shortDescription: 'mit Bergkaese und Roestzwiebeln' },
      { languageCode: 'en', name: 'Cheese Spaetzle', shortDescription: 'with mountain cheese and fried onions' },
    ] },
    priceVariants: { create: [{ price: 19.50, currency: 'EUR', isDefault: true }] },
  } });

  const desserts = await prisma.menuSection.create({ data: {
    menuId: speisekarte.id, slug: 'desserts', sortOrder: 2, icon: '🍰',
    translations: { create: [{ languageCode: 'de', name: 'Desserts' }, { languageCode: 'en', name: 'Desserts' }] },
  } });

  await prisma.menuItem.create({ data: {
    sectionId: desserts.id, type: ItemType.FOOD, sortOrder: 0, isHighlight: true, highlightType: 'RECOMMENDATION',
    translations: { create: [
      { languageCode: 'de', name: 'Salzburger Nockerl', shortDescription: 'luftig-leicht mit Himbeerroester' },
      { languageCode: 'en', name: 'Salzburg Souffle', shortDescription: 'light and fluffy with raspberry compote' },
    ] },
    priceVariants: { create: [{ price: 14.90, currency: 'EUR', isDefault: true }] },
  } });

  await prisma.menuItem.create({ data: {
    sectionId: desserts.id, type: ItemType.FOOD, sortOrder: 1,
    translations: { create: [
      { languageCode: 'de', name: 'Kaiserschmarrn', shortDescription: 'mit Zwetschkenroester' },
      { languageCode: 'en', name: 'Kaiserschmarrn', shortDescription: 'with plum compote' },
    ] },
    priceVariants: { create: [{ price: 15.50, currency: 'EUR', isDefault: true }] },
  } });

  // Weinkarte
  const weinkarte = await prisma.menu.create({ data: {
    locationId: restaurant.id, type: MenuType.WINE, slug: 'weinkarte', sortOrder: 1, publishedAt: new Date(),
    translations: { create: [{ languageCode: 'de', name: 'Weinkarte' }, { languageCode: 'en', name: 'Wine List' }] },
  } });

  const rotweine = await prisma.menuSection.create({ data: {
    menuId: weinkarte.id, slug: 'rotweine', sortOrder: 0, icon: '🍷',
    translations: { create: [{ languageCode: 'de', name: 'Rotweine' }, { languageCode: 'en', name: 'Red Wines' }] },
  } });

  await prisma.menuItem.create({ data: {
    sectionId: rotweine.id, type: ItemType.WINE, sortOrder: 0, isHighlight: true, highlightType: 'RECOMMENDATION',
    translations: { create: [
      { languageCode: 'de', name: 'Blaufraenkisch Reserve', shortDescription: 'Weingut Moric, Burgenland 2019' },
      { languageCode: 'en', name: 'Blaufraenkisch Reserve', shortDescription: 'Weingut Moric, Burgenland 2019' },
    ] },
    priceVariants: { create: [
      { label: 'Glas', price: 9.50, currency: 'EUR', volume: '0.15l', sortOrder: 0 },
      { label: 'Flasche', price: 48.00, currency: 'EUR', volume: '0.75l', sortOrder: 1, isDefault: true },
    ] },
    wineProfile: { create: { winery: 'Weingut Moric', vintage: 2019, grapeVarieties: ['Blaufraenkisch'], region: 'Burgenland', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.MEDIUM_FULL, sweetness: WineSweetness.DRY, alcoholContent: 13.5, servingTemp: '16-18C', tastingNotes: 'Dunkle Beeren, schwarzer Pfeffer, feine Eiche', foodPairing: 'Rind, Wild, reifer Kaese' } },
  } });

  // QR Code
  await prisma.qRCode.create({ data: { locationId: restaurant.id, menuId: speisekarte.id, label: 'Restaurant Tisch', shortCode: 'SB-REST1', primaryColor: '#1a1a1a', bgColor: '#FAFAF8' } });

  console.log('Seed done! Login: admin@hotel-sonnblick.at / Sonnblick2024!');
}

main().catch(e => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());
