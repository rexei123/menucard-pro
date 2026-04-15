#!/bin/bash
cd /var/www/menucard-pro

cat > prisma/seed-wine.ts << 'SEEDEOF'
import { PrismaClient, MenuType, ItemType, WineStyle, WineBody, WineSweetness } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  console.log('🍷 Seeding Weinkarte...');
  const tenant = await prisma.tenant.findUnique({ where: { slug: 'hotel-sonnblick' } });
  if (!tenant) throw new Error('Tenant not found!');
  const restaurant = await prisma.location.findFirst({ where: { tenantId: tenant.id, slug: 'restaurant' } });
  if (!restaurant) throw new Error('Restaurant not found!');

  // Delete existing wine menu if exists
  const existing = await prisma.menu.findFirst({ where: { locationId: restaurant.id, slug: 'weinkarte' } });
  if (existing) await prisma.menu.delete({ where: { id: existing.id } }).catch(() => {});

  const weinkarte = await prisma.menu.create({ data: {
    locationId: restaurant.id, type: MenuType.WINE, slug: 'weinkarte', sortOrder: 8, publishedAt: new Date(),
    translations: { create: [
      { languageCode: 'de', name: 'Weinkarte', description: 'Unsere Weinauswahl' },
      { languageCode: 'en', name: 'Wine List', description: 'Our wine selection' },
    ]},
  }});

  // Helper
  async function addWine(sectionId: string, sortOrder: number, name: string, descDe: string, descEn: string, price: number, volume: string, profile: {
    winery: string; vintage?: number; grapes: string[]; region: string; country: string;
    style: WineStyle; body?: WineBody; sweetness?: WineSweetness;
    tastingDe?: string; tastingEn?: string; appellation?: string;
  }, extraPrices?: { label: string; price: number; volume: string }[]) {
    const prices = extraPrices
      ? extraPrices.map((p, i) => ({ label: p.label, price: p.price, currency: 'EUR', volume: p.volume, sortOrder: i, isDefault: i === extraPrices.length - 1 }))
      : [{ label: 'Flasche', price, currency: 'EUR', volume, sortOrder: 0, isDefault: true }];

    await prisma.menuItem.create({ data: {
      sectionId, type: ItemType.WINE, sortOrder,
      translations: { create: [
        { languageCode: 'de', name, shortDescription: descDe, longDescription: profile.tastingDe || null },
        { languageCode: 'en', name, shortDescription: descEn, longDescription: profile.tastingEn || null },
      ]},
      priceVariants: { create: prices },
      wineProfile: { create: {
        winery: profile.winery, vintage: profile.vintage, grapeVarieties: profile.grapes,
        region: profile.region, country: profile.country, appellation: profile.appellation,
        style: profile.style, body: profile.body, sweetness: profile.sweetness,
      }},
    }});
  }

  // ═══════════════════════════════════════
  // SCHAUMWEIN / SPARKLING
  // ═══════════════════════════════════════
  const sparkling = await prisma.menuSection.create({ data: {
    menuId: weinkarte.id, slug: 'schaumwein', sortOrder: 0, icon: '🥂',
    translations: { create: [{ languageCode: 'de', name: 'Schaumwein' }, { languageCode: 'en', name: 'Sparkling Wine' }] },
  }});
  let s = 0;

  await addWine(sparkling.id, s++, 'Schlumberger Sparkling Brut', 'Kellerei Schlumberger, Wien', 'Kellerei Schlumberger, Vienna', 57.60, '0.75l',
    { winery: 'Kellerei Schlumberger', grapes: ['Chardonnay', 'Pinot Blanc', 'Welschriesling'], region: 'Wien', country: 'Oesterreich', style: WineStyle.SPARKLING, sweetness: WineSweetness.DRY, appellation: 'Oesterreichischer Sekt' });

  await addWine(sparkling.id, s++, 'Secco Rose Pink Ribbon', 'Leo Hillinger, Jois, Burgenland', 'Leo Hillinger, Jois, Burgenland', 42.10, '0.75l',
    { winery: 'Leo Hillinger', grapes: ['Pinot Noir'], region: 'Burgenland', country: 'Oesterreich', style: WineStyle.SPARKLING, sweetness: WineSweetness.DRY,
      tastingDe: 'Der Duft erinnert an Erdbeeren, der Gaumen praesentiert sich erfrischend mit einer ueberaus eleganten Perlage, fruchtig und feingliedrig.',
      tastingEn: 'The scent is reminiscent of strawberries, the palate is refreshing with an extremely elegant perlage, fruity and delicate.' },
    [{ label: '1/8L', price: 5.90, volume: '0.125l' }, { label: 'Flasche', price: 42.10, volume: '0.75l' }]);

  await addWine(sparkling.id, s++, 'Canella Extra Dry', 'Casa Vinicola Canella, Venetien', 'Casa Vinicola Canella, Veneto', 52.40, '0.75l',
    { winery: 'Casa Vinicola Canella', grapes: ['Glera'], region: 'Venetien', country: 'Italien', style: WineStyle.SPARKLING, sweetness: WineSweetness.OFF_DRY, appellation: 'Conegliano Valdobbiadene Prosecco Sup. DOCG',
      tastingDe: 'In der Nase Jasmin, weisse Johannisbeere, Orangebluete. Knackige Textur, lebendige Fruchtsaeure, herrlich frisch.',
      tastingEn: 'On the nose jasmine, white currant, orange blossom. Crisp texture, lively fruit acidity, wonderfully fresh.' },
    [{ label: '1/10L', price: 7.20, volume: '0.1l' }, { label: 'Flasche', price: 52.40, volume: '0.75l' }]);

  await addWine(sparkling.id, s++, 'Perrier-Jouet Grand', 'Champagne Perrier-Jouet, Epernay', 'Champagne Perrier-Jouet, Epernay', 136.40, '0.75l',
    { winery: 'Champagne Perrier-Jouet', grapes: ['Pinot Noir', 'Pinot Meunier', 'Chardonnay'], region: 'Champagne', country: 'Frankreich', style: WineStyle.SPARKLING, sweetness: WineSweetness.DRY, appellation: 'Champagne AOC',
      tastingDe: 'Helles Goldgelb, Silberreflexe. Frische weisse Tropenfrucht, etwas Ananas, Limettenzesten und weisse Blueten. Schoene Komplexitaet, Noten von Pfirsich.',
      tastingEn: 'Bright golden yellow with silver reflections. Fresh white tropical fruit, a touch of pineapple, hints of lime zest, and white flowers. Beautiful complexity, notes of peach.' });

  await addWine(sparkling.id, s++, 'Taittinger Reserve', 'Champagne Taittinger, Reims', 'Champagne Taittinger, Reims', 125.00, '0.75l',
    { winery: 'Champagne Taittinger', grapes: ['Chardonnay', 'Pinot Noir', 'Pinot Meunier'], region: 'Champagne', country: 'Frankreich', style: WineStyle.SPARKLING, sweetness: WineSweetness.DRY, appellation: 'Champagne AOC',
      tastingDe: 'Leuchtendes Goldgelb mit feiner Perlage. Pfirsich, Zitrusfruechte, weisse Blueten, Brioche, Vanille und ein Hauch Honig. Lebendig, frisch und harmonisch.',
      tastingEn: 'Brilliant golden yellow with fine bubbles. Peach, citrus, white flowers, brioche, vanilla, and a hint of honey. Lively, fresh and harmonious.' },
    [{ label: '0.375l', price: 61.30, volume: '0.375l' }, { label: 'Flasche', price: 125.00, volume: '0.75l' }]);

  await addWine(sparkling.id, s++, 'Veuve Clicquot Brut', 'Champagne Veuve Clicquot, Reims', 'Champagne Veuve Clicquot, Reims', 125.00, '0.75l',
    { winery: 'Champagne Veuve Clicquot Ponsardin', grapes: ['Pinot Noir', 'Chardonnay', 'Pinot Meunier'], region: 'Champagne', country: 'Frankreich', style: WineStyle.SPARKLING, sweetness: WineSweetness.DRY, appellation: 'Champagne AOC',
      tastingDe: 'Mittleres Gelbgruen, feine Perlage. Frische Nuancen von Orangenzesten, gelbem Apfel, Biskuit. Saftig, mineralisch, gute Laenge.',
      tastingEn: 'Tightly knit, focused by robust acidity and minerality. Subtle notes of white peach, anise, biscuit and kumquat.' });

  console.log('  ✓ Schaumwein: 6');

  // ═══════════════════════════════════════
  // WEISSWEIN / WHITE WINE
  // ═══════════════════════════════════════
  const weiss = await prisma.menuSection.create({ data: {
    menuId: weinkarte.id, slug: 'weisswein', sortOrder: 1, icon: '🥂',
    translations: { create: [{ languageCode: 'de', name: 'Weisswein' }, { languageCode: 'en', name: 'White Wine' }] },
  }});
  s = 0;

  // Gruener Veltliner
  await addWine(weiss.id, s++, 'Gruener Veltliner Terrassen Smaragd 2023', 'Domaene Wachau, Duernstein', 'Domaene Wachau, Duernstein', 68.10, '0.75l',
    { winery: 'Domaene Wachau', vintage: 2023, grapes: ['Gruener Veltliner'], region: 'Wachau', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Wachau DAC',
      tastingDe: 'Zart nach Zitrus und Quitte, Wiesenkraeuter. Saftig, engmaschig, gelbes Kernobst, lebendiger Saeurebogen, einladendes Finish.',
      tastingEn: 'Delicate notes of citrus and quince, meadow herbs. Juicy, tightly woven, yellow pomaceous fruit, lively acidity, inviting finish.' });

  await addWine(weiss.id, s++, 'Ried Kellerberg Gruener Veltliner Smaragd 2022', 'Domaene Wachau, Duernstein', 'Domaene Wachau, Duernstein', 52.40, '0.75l',
    { winery: 'Domaene Wachau', vintage: 2022, grapes: ['Gruener Veltliner'], region: 'Wachau', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM_FULL, sweetness: WineSweetness.DRY, appellation: 'Wachau DAC',
      tastingDe: 'Feine weisse Tropenfrucht, weisser Apfel, Mandarinenzesten, weisse Blueten. Saftig, weisses Kernobst, mineralisch-salzig im Abgang.',
      tastingEn: 'Open and expressive, dark and smoky spices, delicious stone fruit, white peach. Very distinctive, well structured, precise and powerful.' });

  await addWine(weiss.id, s++, 'Rotes Tor Gruener Veltliner Federspiel 2023', 'Weingut Franz Hirtzberger, Spitz', 'Weingut Franz Hirtzberger, Spitz', 66.00, '0.75l',
    { winery: 'Weingut Franz Hirtzberger', vintage: 2023, grapes: ['Gruener Veltliner'], region: 'Wachau', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Wachau DAC',
      tastingDe: 'Einladendes Bukett nach Honigmelone und dezenter Kraeuterwuerze, floral, Nuancen von Orangenzesten. Elegant, mineralisch.',
      tastingEn: 'Inviting bouquet of honeydew melon and subtle herbal spice, floral notes, with nuances of orange zest. Elegant, mineral-driven.' });

  await addWine(weiss.id, s++, 'Piri Gruener Veltliner 2023', 'Weingut Nigl, Senftenberg', 'Weingut Nigl, Senftenberg', 39.80, '0.75l',
    { winery: 'Weingut Nigl', vintage: 2023, grapes: ['Gruener Veltliner'], region: 'Kremstal', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM_LIGHT, sweetness: WineSweetness.DRY, appellation: 'Kremstal DAC',
      tastingDe: 'Feine gelbe Tropenfrucht, zart nach Pfirsich, ein Hauch von Bluetenhonig. Saftig, elegant, weisser Apfel, frischer Saeurebogen.',
      tastingEn: 'Fine yellow tropical fruits, delicate peach, a hint of blossom honey. Juicy, elegant, white apple, fresh acidity.' });

  await addWine(weiss.id, s++, 'Stein am Rain Gruener Veltliner Federspiel 2024', 'Weingut Josef Jamek, Joching', 'Weingut Josef Jamek, Joching', 44.00, '0.75l',
    { winery: 'Weingut Josef Jamek', vintage: 2024, grapes: ['Gruener Veltliner'], region: 'Wachau', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM_LIGHT, sweetness: WineSweetness.DRY, appellation: 'Wachau DAC',
      tastingDe: 'Herrlich lebendiger, frischer Gruener Veltliner mit Aromen von Apfel und Zitrusfruechten, tropische Frucht und kuehle, mineralische Akzente.',
      tastingEn: 'Wonderfully lively, fresh Gruener Veltliner with aromas of apple and citrus, tropical fruit and cool, mineral accents.' });

  await addWine(weiss.id, s++, 'Terrassen Gruener Veltliner Federspiel 2023', 'Domaene Wachau, Duernstein', 'Domaene Wachau, Duernstein', 50.30, '0.75l',
    { winery: 'Domaene Wachau', vintage: 2023, grapes: ['Gruener Veltliner'], region: 'Wachau', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Wachau DAC',
      tastingDe: 'Zarter Duft nach Wiesenkraeutern, Birne, Ringlotte, mineralischer Touch. Helle Frucht, frischer Saeurebogen, charmanter Stil.',
      tastingEn: 'Delicate aromas of meadow herbs, pear and greengage, with a touch of minerality. Lots of bright fruit, fresh acidity, charming style.' });

  // Riesling
  await addWine(weiss.id, s++, 'Ried Loibenberg Riesling Smaragd 2023', 'Weingut Emmerich Knoll, Unterloiben', 'Weingut Emmerich Knoll, Unterloiben', 136.40, '0.75l',
    { winery: 'Weingut Emmerich Knoll', vintage: 2023, grapes: ['Riesling'], region: 'Wachau', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM_FULL, sweetness: WineSweetness.DRY, appellation: 'Wachau DAC',
      tastingDe: 'Kandierte Orangenzesten, feine Nuancen von Safran, etwas Mango, floraler Touch. Weisses Steinobst, feiner Saeurebogen, mineralisch.',
      tastingEn: 'Rich and powerful with a wonderful creaminess. Mandarin-orange and fresh-papaya aromas cascade over you in the extravagant, yet precise finish.' });

  await addWine(weiss.id, s++, 'Kamptal Riesling Terrassen 2023', 'Weingut Bruendlmayer, Langenlois', 'Weingut Bruendlmayer, Langenlois', 41.90, '0.75l',
    { winery: 'Weingut Bruendlmayer', vintage: 2023, grapes: ['Riesling'], region: 'Kamptal', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Kamptal DAC',
      tastingDe: 'Limettenzesten, feine weisse Pfirsichfrucht, Maracuja. Straff, engmaschig, rassiger Saeurebogen, mineralisch-zitronig.',
      tastingEn: 'Super clear and remarkably intense, white peach and crushed rock. Lush, round and savory, with spicy aromatics and mineral tension.' });

  await addWine(weiss.id, s++, 'Ried Heiligenstein Riesling 2022', 'Weingut Jurtschitsch, Langenlois', 'Weingut Jurtschitsch, Langenlois', 88.10, '0.75l',
    { winery: 'Weingut Jurtschitsch', vintage: 2022, grapes: ['Riesling'], region: 'Kamptal', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM_FULL, sweetness: WineSweetness.DRY, appellation: 'Kamptal DAC',
      tastingDe: 'Dezente Steinobstfrucht, weisser Pfirsich, Bluetenhonig, Ananas. Saftig, komplex, zitroniger Touch, mineralischer Nachhall.',
      tastingEn: 'Subtle aromas of stone fruit, white peach notes, a hint of blossom honey. Juicy, complex, with a lemony touch, mineral aftertaste.' });

  await addWine(weiss.id, s++, 'Ried Klaus Riesling 2023', 'Weingut Josef Jamek, Joching', 'Weingut Josef Jamek, Joching', 68.10, '0.75l',
    { winery: 'Weingut Josef Jamek', vintage: 2023, grapes: ['Riesling'], region: 'Wachau', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Wachau DAC',
      tastingDe: 'Zitrusblaetter und Mandarinenschale ueber reifen Pfirsich- und Quittenaromen. Exquisite Klarheit, zitrische Lebendigkeit und mineralische Eleganz.',
      tastingEn: 'Crushed citrus foliage and tangerine peel, with exquisite clarity. Citric verve and mineral grace, very long finish.' });

  // Cuvee, Sauvignon Blanc, Chardonnay etc.
  await addWine(weiss.id, s++, 'Ried Loiserberg 2024', 'Weingut Fred Loimer, Langenlois', 'Weingut Fred Loimer, Langenlois', 36.60, '0.75l',
    { winery: 'Weingut Fred Loimer', vintage: 2024, grapes: ['Gruener Veltliner', 'Riesling'], region: 'Kamptal', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Kamptal DAC',
      tastingDe: 'Ringlotten, Ananas, Doerrbirnen, Weissdorn. Exzellente Fuelle, balanciert zwischen Saeure und Schmelz. Fein salzig-mineralisch.',
      tastingEn: 'Greengage plums, pineapple, dried pear, hawthorn. Excellent fullness, balanced between fresh acidity and extract-sweet creaminess.' });

  await addWine(weiss.id, s++, 'Ried Spiegel Grau- & Weissburgunder 2022', 'Weingut Bruendlmayer, Langenlois', 'Weingut Bruendlmayer, Langenlois', 83.90, '0.75l',
    { winery: 'Weingut Bruendlmayer', vintage: 2022, grapes: ['Pinot Gris', 'Pinot Blanc'], region: 'Niederoestereich', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY });

  await addWine(weiss.id, s++, 'Gustav Gemischter Satz', 'Weingut Krug, Gumpoldskirchen', 'Weingut Krug, Gumpoldskirchen', 44.00, '0.75l',
    { winery: 'Weingut Krug', grapes: ['Gemischter Satz'], region: 'Thermenregion', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM_LIGHT, sweetness: WineSweetness.DRY, appellation: 'Thermenregion QW' });

  await addWine(weiss.id, s++, 'young & fresh Sauvignon Blanc 2023', 'Weingut Leth, Fels am Wagram', 'Weingut Leth, Fels am Wagram', 45.00, '0.75l',
    { winery: 'Weingut Leth', vintage: 2023, grapes: ['Sauvignon Blanc'], region: 'Niederoestereich', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM_LIGHT, sweetness: WineSweetness.DRY,
      tastingDe: 'Stachelbeere, Johannisbeere, feine exotische Noten. Verspielte Frucht, saftig am Gaumen, animierendes Saeurespiel.',
      tastingEn: 'Gooseberry, blackcurrant, kiwi and yellow apple. Playful fruit, juicy on the palate, sophisticated representative.' });

  await addWine(weiss.id, s++, 'Straden Sauvignon Blanc 2022', 'Weingut Neumeister, Straden', 'Weingut Neumeister, Straden', 39.80, '0.75l',
    { winery: 'Weingut Neumeister', vintage: 2022, grapes: ['Sauvignon Blanc'], region: 'Vulkanland Steiermark', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Vulkanland Steiermark DAC' });

  await addWine(weiss.id, s++, 'Jakobi 2022', 'Weingut Gross, Ratsch', 'Weingut Gross, Ratsch', 34.90, '0.75l',
    { winery: 'Weingut Gross', vintage: 2022, grapes: ['Sauvignon Blanc'], region: 'Suedsteiermark', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Suedsteiermark DAC' });

  await addWine(weiss.id, s++, 'Ried Tagelsteiner Chardonnay 2021', 'Weingut Alphart, Traiskirchen', 'Weingut Alphart, Traiskirchen', 61.80, '0.75l',
    { winery: 'Weingut Alphart', vintage: 2021, grapes: ['Chardonnay'], region: 'Thermenregion', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM_FULL, sweetness: WineSweetness.DRY, appellation: 'Thermenregion QW' });

  await addWine(weiss.id, s++, 'Chardonnay 2024', 'Weingut Gerhard Markowitsch, Goettlesbrunn', 'Weingut Gerhard Markowitsch, Goettlesbrunn', 41.90, '0.75l',
    { winery: 'Weingut Gerhard Markowitsch', vintage: 2024, grapes: ['Chardonnay'], region: 'Carnuntum', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Carnuntum DAC' });

  await addWine(weiss.id, s++, 'Chardonnay 2023', 'Weingut Gesellmann, Deutschkreutz', 'Weingut Gesellmann, Deutschkreutz', 38.70, '0.75l',
    { winery: 'Weingut Gesellmann', vintage: 2023, grapes: ['Chardonnay'], region: 'Burgenland', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY });

  await addWine(weiss.id, s++, 'Ried Poessnitzberg Chardonnay 2021', 'Weingut Erwin Sabathi, Leutschach', 'Weingut Erwin Sabathi, Leutschach', 136.40, '0.75l',
    { winery: 'Weingut Erwin Sabathi', vintage: 2021, grapes: ['Chardonnay'], region: 'Suedsteiermark', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.FULL, sweetness: WineSweetness.DRY, appellation: 'Suedsteiermark DAC' });

  await addWine(weiss.id, s++, 'Leutschach Chardonnay 2023', 'Weingut Erwin Sabathi, Leutschach', 'Weingut Erwin Sabathi, Leutschach', 44.00, '0.75l',
    { winery: 'Weingut Erwin Sabathi', vintage: 2023, grapes: ['Chardonnay'], region: 'Suedsteiermark', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Suedsteiermark DAC' });

  await addWine(weiss.id, s++, 'Muschelkalk Morillon 2019', 'Weingut Tement, Berghausen', 'Weingut Tement, Berghausen', 58.90, '0.75l',
    { winery: 'Weingut Tement', vintage: 2019, grapes: ['Chardonnay'], region: 'Suedsteiermark', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM_FULL, sweetness: WineSweetness.DRY, appellation: 'Suedsteiermark DAC' });

  await addWine(weiss.id, s++, 'Ton & Mergel Weissburgunder 2023', 'Weingut Tement, Berghausen', 'Weingut Tement, Berghausen', 52.40, '0.75l',
    { winery: 'Weingut Tement', vintage: 2023, grapes: ['Pinot Blanc'], region: 'Suedsteiermark', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Suedsteiermark DAC' });

  await addWine(weiss.id, s++, 'Grauburgunder 2024', 'Weingut Krispel, Straden', 'Weingut Krispel, Straden', 52.40, '0.75l',
    { winery: 'Weingut Krispel', vintage: 2024, grapes: ['Pinot Gris'], region: 'Vulkanland Steiermark', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Vulkanland Steiermark DAC' });

  await addWine(weiss.id, s++, 'Welschriesling 2021', 'Weingut Lackner-Tinnacher, Gamlitz', 'Weingut Lackner-Tinnacher, Gamlitz', 46.10, '0.75l',
    { winery: 'Weingut Lackner-Tinnacher', vintage: 2021, grapes: ['Welschriesling'], region: 'Suedsteiermark', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM_LIGHT, sweetness: WineSweetness.DRY, appellation: 'Suedsteiermark DAC' });

  await addWine(weiss.id, s++, 'Welschriesling 2024', 'Weingut Polz, Spielfeld', 'Weingut Polz, Spielfeld', 46.10, '0.75l',
    { winery: 'Weingut Polz', vintage: 2024, grapes: ['Welschriesling'], region: 'Suedsteiermark', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.LIGHT, sweetness: WineSweetness.DRY, appellation: 'Suedsteiermark DAC' });

  await addWine(weiss.id, s++, 'Gelber Muskateller 2024', 'Weingut Nigl, Senftenberg', 'Weingut Nigl, Senftenberg', 36.60, '0.75l',
    { winery: 'Weingut Nigl', vintage: 2024, grapes: ['Muskateller'], region: 'Niederoestereich', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.LIGHT, sweetness: WineSweetness.DRY });

  await addWine(weiss.id, s++, 'Mitzi Muskateller 2022', 'Gross & Gross, Ehrenhausen', 'Gross & Gross, Ehrenhausen', 37.90, '0.75l',
    { winery: 'Gross & Gross', vintage: 2022, grapes: ['Muskateller'], region: 'Suedsteiermark', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM_LIGHT, sweetness: WineSweetness.DRY, appellation: 'Suedsteiermark DAC' });

  await addWine(weiss.id, s++, 'Sand & Schiefer Gelber Muskateller 2023', 'Weingut Tement, Berghausen', 'Weingut Tement, Berghausen', 61.80, '0.75l',
    { winery: 'Weingut Tement', vintage: 2023, grapes: ['Muskateller'], region: 'Suedsteiermark', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Suedsteiermark DAC' });

  await addWine(weiss.id, s++, 'Ried Steinberg Roter Veltliner 2021', 'Heiderer-Mayer, Baumgarten', 'Heiderer-Mayer, Baumgarten', 44.00, '0.75l',
    { winery: 'Heiderer-Mayer', vintage: 2021, grapes: ['Roter Veltliner'], region: 'Wagram', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM_FULL, sweetness: WineSweetness.DRY, appellation: 'Wagram QW' });

  await addWine(weiss.id, s++, 'Nussberg 2023', 'Weingut Rotes Haus am Nussberg, Wien', 'Weingut Rotes Haus am Nussberg, Vienna', 41.90, '0.75l',
    { winery: 'Weingut Rotes Haus am Nussberg', vintage: 2023, grapes: ['Chardonnay', 'Pinot Blanc', 'Pinot Gris', 'Neuburger', 'Gruener Veltliner'], region: 'Wien', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Wiener Gemischter Satz DAC' });

  await addWine(weiss.id, s++, 'Wiener Gemischter Satz 2024', 'Mayer am Pfarrplatz, Wien', 'Mayer am Pfarrplatz, Vienna', 40.80, '0.75l',
    { winery: 'Mayer am Pfarrplatz', vintage: 2024, grapes: ['Gruener Veltliner', 'Riesling', 'Zierfandler'], region: 'Wien', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM_LIGHT, sweetness: WineSweetness.DRY, appellation: 'Wiener Gemischter Satz DAC' });

  await addWine(weiss.id, s++, 'Ried Flamming Rotgipfler 2021', 'Weingut Leo Aumann, Tribuswinkel', 'Weingut Leo Aumann, Tribuswinkel', 41.90, '0.75l',
    { winery: 'Weingut Leo Aumann', vintage: 2021, grapes: ['Rotgipfler'], region: 'Thermenregion', country: 'Oesterreich', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Thermenregion QW' });

  // International whites
  await addWine(weiss.id, s++, 'Brolettino 2022', 'Azienda Agricola Ca dei Frati, Lugana', 'Azienda Agricola Ca dei Frati, Lugana', 71.30, '0.75l',
    { winery: 'Ca dei Frati', vintage: 2022, grapes: ['Turbiana'], region: 'Lombardei', country: 'Italien', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Lugana DOC' });

  await addWine(weiss.id, s++, 'Lugana 2023', 'Olivini, Desenzano', 'Olivini, Desenzano', 35.90, '0.75l',
    { winery: 'Olivini', vintage: 2023, grapes: ['Turbiana'], region: 'Lombardei', country: 'Italien', style: WineStyle.WHITE, body: WineBody.MEDIUM_FULL, sweetness: WineSweetness.DRY, appellation: 'Lugana DOC' });

  await addWine(weiss.id, s++, 'I Ciari Pinot Grigio 2023', 'Borgo Molino, Ormelle', 'Borgo Molino, Ormelle', 51.40, '0.75l',
    { winery: 'Borgo Molino', vintage: 2023, grapes: ['Pinot Grigio'], region: 'Venetien', country: 'Italien', style: WineStyle.WHITE, body: WineBody.MEDIUM_LIGHT, sweetness: WineSweetness.DRY, appellation: 'Veneto DOC' });

  await addWine(weiss.id, s++, 'Just Fiou Sauvignon Blanc 2022', 'Domaine Gerard Fiou, Saint-Satur', 'Domaine Gerard Fiou, Saint-Satur', 50.30, '0.75l',
    { winery: 'Domaine Gerard Fiou', vintage: 2022, grapes: ['Sauvignon Blanc'], region: 'Loire', country: 'Frankreich', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Sancerre AOC' });

  await addWine(weiss.id, s++, 'La Marimorena 2022', 'Casa Rojo, Balsapintada', 'Casa Rojo, Balsapintada', 73.40, '0.75l',
    { winery: 'Casa Rojo', vintage: 2022, grapes: ['Albarin Blanco'], region: 'Galizien', country: 'Spanien', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Rias Baixas DO' });

  await addWine(weiss.id, s++, 'Fosilni Breg Sauvignon Blanc 2020', 'Domaine Ciringa, Zgornja Kungota', 'Domaine Ciringa, Zgornja Kungota', 38.70, '0.75l',
    { winery: 'Domaine Ciringa', vintage: 2020, grapes: ['Sauvignon Blanc'], region: 'Podravje', country: 'Slowenien', style: WineStyle.WHITE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY });

  await addWine(weiss.id, s++, 'Sauvignon Blanc 2022', 'Salomon & Andrew, Marlborough', 'Salomon & Andrew, Marlborough', 44.00, '0.75l',
    { winery: 'Salomon & Andrew', vintage: 2022, grapes: ['Sauvignon Blanc'], region: 'Marlborough', country: 'Neuseeland', style: WineStyle.WHITE, body: WineBody.MEDIUM_LIGHT, sweetness: WineSweetness.DRY });

  console.log('  ✓ Weisswein: ' + s);

  // ═══════════════════════════════════════
  // ROSEWEIN / ROSE
  // ═══════════════════════════════════════
  const rose = await prisma.menuSection.create({ data: {
    menuId: weinkarte.id, slug: 'rosewein', sortOrder: 2, icon: '🌸',
    translations: { create: [{ languageCode: 'de', name: 'Rosewein' }, { languageCode: 'en', name: 'Rose Wine' }] },
  }});
  s = 0;

  await addWine(rose.id, s++, 'Rose Deluxe 2024', 'Weingut Pittnauer, Gols, Burgenland', 'Weingut Pittnauer, Gols, Burgenland', 36.60, '0.75l',
    { winery: 'Weingut Erich & Birgit Pittnauer', vintage: 2024, grapes: ['Zweigelt', 'Blaufraenkisch', 'Merlot', 'Cabernet Sauvignon'], region: 'Burgenland', country: 'Oesterreich', style: WineStyle.ROSE, body: WineBody.MEDIUM_LIGHT, sweetness: WineSweetness.DRY });

  await addWine(rose.id, s++, 'In Bloom Rose 2022', 'Weingut Hannes Reeh, Andau', 'Weingut Hannes Reeh, Andau', 41.90, '0.75l',
    { winery: 'Weingut Hannes Reeh', vintage: 2022, grapes: ['Blaufraenkisch', 'Cabernet Sauvignon'], region: 'Burgenland', country: 'Oesterreich', style: WineStyle.ROSE, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY });

  await addWine(rose.id, s++, 'Rose Zweigelt 2024', 'Weingut Bruendlmayer, Langenlois', 'Weingut Bruendlmayer, Langenlois', 35.60, '0.75l',
    { winery: 'Weingut Bruendlmayer', vintage: 2024, grapes: ['Zweigelt'], region: 'Niederoestereich', country: 'Oesterreich', style: WineStyle.ROSE, body: WineBody.LIGHT, sweetness: WineSweetness.DRY });

  await addWine(rose.id, s++, 'Zweigelt Rose young & fresh 2022', 'Weingut Leth, Fels am Wagram', 'Weingut Leth, Fels am Wagram', 35.60, '0.75l',
    { winery: 'Weingut Leth', vintage: 2022, grapes: ['Zweigelt'], region: 'Niederoestereich', country: 'Oesterreich', style: WineStyle.ROSE, body: WineBody.LIGHT, sweetness: WineSweetness.DRY });

  await addWine(rose.id, s++, 'UP Rose 2023', 'Ultimate Provence, La Garde-Freinet', 'Ultimate Provence, La Garde-Freinet', 47.10, '0.75l',
    { winery: 'Ultimate Provence', vintage: 2023, grapes: ['Grenache', 'Cinsault', 'Syrah', 'Vermentino'], region: 'Provence', country: 'Frankreich', style: WineStyle.ROSE, body: WineBody.MEDIUM_LIGHT, sweetness: WineSweetness.DRY, appellation: 'Cotes de Provence AOC' });

  console.log('  ✓ Rosewein: 5');

  // ═══════════════════════════════════════
  // ROTWEIN / RED WINE (Teil 1)
  // ═══════════════════════════════════════
  const rot = await prisma.menuSection.create({ data: {
    menuId: weinkarte.id, slug: 'rotwein', sortOrder: 3, icon: '🍷',
    translations: { create: [{ languageCode: 'de', name: 'Rotwein' }, { languageCode: 'en', name: 'Red Wine' }] },
  }});
  s = 0;

  // Zweigelt
  await addWine(rot.id, s++, 'Ried Hallebuehl Zweigelt 2018', 'Weingut Josef Umathum, Frauenkirchen', 'Weingut Josef Umathum, Frauenkirchen', 132.20, '0.75l',
    { winery: 'Weingut Josef Umathum', vintage: 2018, grapes: ['Zweigelt'], region: 'Burgenland', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.FULL, sweetness: WineSweetness.DRY });

  await addWine(rot.id, s++, 'Zweigelt 2019', 'Weingut Gernot & Heike Heinrich, Gols', 'Weingut Gernot & Heike Heinrich, Gols', 46.10, '0.75l',
    { winery: 'Weingut Heinrich', vintage: 2019, grapes: ['Zweigelt'], region: 'Burgenland', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.MEDIUM_FULL, sweetness: WineSweetness.DRY });

  await addWine(rot.id, s++, 'Zweigelt 2022', 'Weingut Scheiblhofer, Andau', 'Weingut Scheiblhofer, Andau', 44.00, '0.75l',
    { winery: 'Weingut Scheiblhofer', vintage: 2022, grapes: ['Zweigelt'], region: 'Neusiedlersee', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Neusiedlersee DAC' });

  // Blaufraenkisch
  await addWine(rot.id, s++, 'Kirch Blaufraenkisch 2021', 'Weingut Weninger, Horitschon', 'Weingut Weninger, Horitschon', 69.20, '0.75l',
    { winery: 'Weingut Weninger', vintage: 2021, grapes: ['Blaufraenkisch'], region: 'Burgenland', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.FULL, sweetness: WineSweetness.DRY });

  await addWine(rot.id, s++, 'Ried Fabian Blaufraenkisch 2019', 'Weingut Gager, Deutschkreutz', 'Weingut Gager, Deutschkreutz', 46.10, '0.75l',
    { winery: 'Weingut Gager', vintage: 2019, grapes: ['Blaufraenkisch'], region: 'Mittelburgenland', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.MEDIUM_FULL, sweetness: WineSweetness.DRY, appellation: 'Mittelburgenland DAC' });

  await addWine(rot.id, s++, 'Blaufraenkisch Klassik 2022', 'Weingut Gager, Deutschkreutz', 'Weingut Gager, Deutschkreutz', 41.90, '0.75l',
    { winery: 'Weingut Gager', vintage: 2022, grapes: ['Blaufraenkisch'], region: 'Burgenland', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY });

  await addWine(rot.id, s++, 'Blaufraenkisch 2022', 'Weingut Paul Kerschbaum, Horitschon', 'Weingut Paul Kerschbaum, Horitschon', 40.80, '0.75l',
    { winery: 'Weingut Paul Kerschbaum', vintage: 2022, grapes: ['Blaufraenkisch'], region: 'Burgenland', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY });

  await addWine(rot.id, s++, 'Chevalier Blaufraenkisch Reserve 2022', 'Rotweingut Iby, Horitschon', 'Rotweingut Iby, Horitschon', 49.20, '0.75l',
    { winery: 'Rotweingut Iby', vintage: 2022, grapes: ['Blaufraenkisch'], region: 'Mittelburgenland', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.MEDIUM_FULL, sweetness: WineSweetness.DRY, appellation: 'Mittelburgenland DAC' });

  await addWine(rot.id, s++, 'Ried Hochberg Blaufraenkisch 2020', 'Weingut Hans Igler, Deutschkreutz', 'Weingut Hans Igler, Deutschkreutz', 49.20, '0.75l',
    { winery: 'Weingut Hans Igler', vintage: 2020, grapes: ['Blaufraenkisch'], region: 'Mittelburgenland', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.MEDIUM_FULL, sweetness: WineSweetness.DRY, appellation: 'Mittelburgenland DAC' });

  // St. Laurent
  await addWine(rot.id, s++, 'St. Laurent Reserve 2022', 'Weingut Leth, Fels am Wagram', 'Weingut Leth, Fels am Wagram', 51.40, '0.75l',
    { winery: 'Weingut Leth', vintage: 2022, grapes: ['St. Laurent'], region: 'Wagram', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY });

  await addWine(rot.id, s++, 'St. Laurent 2021', 'Weingut Glatzer, Goettlesbrunn', 'Weingut Glatzer, Goettlesbrunn', 46.10, '0.75l',
    { winery: 'Weingut Glatzer', vintage: 2021, grapes: ['St. Laurent'], region: 'Carnuntum', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.MEDIUM_FULL, sweetness: WineSweetness.DRY });

  await addWine(rot.id, s++, 'Vom Stein St. Laurent 2021', 'Weingut Josef Umathum, Frauenkirchen', 'Weingut Josef Umathum, Frauenkirchen', 47.10, '0.75l',
    { winery: 'Weingut Josef Umathum', vintage: 2021, grapes: ['St. Laurent'], region: 'Burgenland', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.MEDIUM_FULL, sweetness: WineSweetness.DRY });

  // Pinot Noir
  await addWine(rot.id, s++, 'Pinot Noir Vom Dorf 2022', 'Weingut Pittnauer, Gols', 'Weingut Pittnauer, Gols', 52.40, '0.75l',
    { winery: 'Weingut Pittnauer', vintage: 2022, grapes: ['Pinot Noir'], region: 'Burgenland', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY });

  await addWine(rot.id, s++, 'Pinot Noir 2023', 'Weingut Heinrich, Gols', 'Weingut Heinrich, Gols', 52.40, '0.75l',
    { winery: 'Weingut Gernot & Heike Heinrich', vintage: 2023, grapes: ['Pinot Noir'], region: 'Burgenland', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY });

  await addWine(rot.id, s++, 'Ried Holzspur Pinot Noir 2021', 'Johanneshof Reinisch, Tattendorf', 'Johanneshof Reinisch, Tattendorf', 45.00, '0.75l',
    { winery: 'Johanneshof Reinisch', vintage: 2021, grapes: ['Pinot Noir'], region: 'Thermenregion', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Thermenregion QW' });

  // Cabernet Sauvignon
  await addWine(rot.id, s++, 'Unplugged Cabernet Sauvignon 2019', 'Weingut Hannes Reeh, Andau', 'Weingut Hannes Reeh, Andau', 90.20, '0.75l',
    { winery: 'Weingut Hannes Reeh', vintage: 2019, grapes: ['Cabernet Sauvignon'], region: 'Burgenland', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.FULL, sweetness: WineSweetness.DRY });

  await addWine(rot.id, s++, 'Cabernet Sauvignon 2022', 'Weingut Rudolf Salzl, Illmitz', 'Weingut Rudolf Salzl, Illmitz', 47.10, '0.75l',
    { winery: 'Weingut Rudolf Salzl', vintage: 2022, grapes: ['Cabernet Sauvignon'], region: 'Burgenland', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.FULL, sweetness: WineSweetness.DRY });

  await addWine(rot.id, s++, 'Ried Kart Cabernet Sauvignon 2019', 'Weingut Hans Igler, Deutschkreutz', 'Weingut Hans Igler, Deutschkreutz', 59.70, '0.75l',
    { winery: 'Weingut Hans Igler', vintage: 2019, grapes: ['Cabernet Sauvignon'], region: 'Burgenland', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.FULL, sweetness: WineSweetness.DRY });

  // Merlot
  await addWine(rot.id, s++, 'Merlot Reserve 2021', 'Weingut Leo Aumann, Tribuswinkel', 'Weingut Leo Aumann, Tribuswinkel', 46.10, '0.75l',
    { winery: 'Weingut Leo Aumann', vintage: 2021, grapes: ['Merlot'], region: 'Thermenregion', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.MEDIUM, sweetness: WineSweetness.DRY, appellation: 'Thermenregion QW' });

  await addWine(rot.id, s++, 'Quo Vadis Merlot Reserve 2013', 'Weingut Familie Pitnauer, Goettlesbrunn', 'Weingut Familie Pitnauer, Goettlesbrunn', 69.20, '0.75l',
    { winery: 'Weingut Familie Pitnauer', vintage: 2013, grapes: ['Merlot'], region: 'Niederoestereich', country: 'Oesterreich', style: WineStyle.RED, body: WineBody.FULL, sweetness: WineSweetness.DRY });

  console.log('  ✓ Rotwein: ' + s);

  // QR Code
  await prisma.qRCode.create({ data: { locationId: restaurant.id, menuId: weinkarte.id, label: 'Weinkarte', shortCode: 'SB-WINE1' } }).catch(() => {});

  const total = await prisma.menuItem.count({ where: { section: { menu: { id: weinkarte.id } } } });
  console.log('');
  console.log('✅ Weinkarte fertig!');
  console.log('   ' + total + ' Weine in 4 Kategorien');
  console.log('   Teil 2 (restliche Rotweine, Dessertwein, Portwein) kommt spaeter');
}

main().catch(e => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());
SEEDEOF

echo "Wine-Seed erstellt. Fuehre aus..."
npx tsx prisma/seed-wine.ts

echo ""
echo "Rebuild..."
npx next build 2>&1 | tail -5
pm2 restart menucard-pro

echo ""
echo "✅ Weinkarte Teil 1 ist live!"
