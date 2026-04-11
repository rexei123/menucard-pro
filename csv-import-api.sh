#!/bin/bash
# MenuCard Pro – CSV-Import: API-Route + Template
# Datum: 10.04.2026

set -e
cd /var/www/menucard-pro

echo "=== CSV-Import: API + Template ==="

# === 1. API-Route erstellen ===
mkdir -p src/app/api/v1/import

cat > src/app/api/v1/import/route.ts << 'ENDOFFILE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import Papa from 'papaparse';

type CsvRow = Record<string, string>;

type ParsedProduct = {
  row: number;
  sku: string;
  type: string;
  group: string;
  nameDe: string;
  nameEn: string;
  shortDescDe: string;
  shortDescEn: string;
  longDescDe: string;
  longDescEn: string;
  fillQuantity: string;
  priceLevel: string;
  price: string;
  purchasePrice: string;
  // Wine
  winery: string;
  vintage: string;
  grapes: string;
  region: string;
  country: string;
  wineStyle: string;
  body: string;
  sweetness: string;
  bottleSize: string;
  alcohol: string;
  servingTemp: string;
  tastingNotes: string;
  foodPairing: string;
  // Beverage
  brand: string;
  producer: string;
  bevCategory: string;
  bevAlcohol: string;
  carbonated: string;
  origin: string;
  // Status
  status: 'new' | 'update' | 'error';
  statusMsg: string;
  existingId?: string;
};

function normalize(val: string | undefined): string {
  return (val || '').trim();
}

// POST /api/v1/import?action=preview|execute
export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const action = req.nextUrl.searchParams.get('action') || 'preview';
  const formData = await req.formData();
  const file = formData.get('file') as File | null;

  if (!file) return NextResponse.json({ error: 'No file uploaded' }, { status: 400 });

  const text = await file.text();
  const parsed = Papa.parse<CsvRow>(text, {
    header: true,
    skipEmptyLines: true,
    delimiter: '',
    transformHeader: (h: string) => h.trim().toLowerCase().replace(/\s+/g, '_'),
  });

  if (parsed.errors.length > 0 && parsed.data.length === 0) {
    return NextResponse.json({ error: 'CSV parsing failed', details: parsed.errors }, { status: 400 });
  }

  const tenantId = session.user.tenantId;

  // Load lookup data
  const [fillQuantities, priceLevels, productGroups, existingProducts] = await Promise.all([
    prisma.fillQuantity.findMany({ where: { tenantId } }),
    prisma.priceLevel.findMany({ where: { tenantId } }),
    prisma.productGroup.findMany({ where: { tenantId }, include: { translations: true } }),
    prisma.product.findMany({ where: { tenantId }, select: { id: true, sku: true } }),
  ]);

  const skuMap = new Map(existingProducts.filter(p => p.sku).map(p => [p.sku!, p.id]));
  const fqMap = new Map(fillQuantities.map(f => [f.label.toLowerCase(), f.id]));
  const plMap = new Map(priceLevels.map(p => [p.name.toLowerCase(), p.id]));
  const pgMap = new Map<string, string>();
  productGroups.forEach(pg => {
    pg.translations.forEach(t => pgMap.set(t.name.toLowerCase(), pg.id));
  });

  // Group rows by SKU (multiple prices per product)
  const skuGroups = new Map<string, CsvRow[]>();
  parsed.data.forEach((row, i) => {
    const sku = normalize(row.sku || row.artikelnr || row.artikelnummer || '');
    if (!sku) return;
    if (!skuGroups.has(sku)) skuGroups.set(sku, []);
    skuGroups.get(sku)!.push({ ...row, __row: String(i + 2) } as any);
  });

  const products: ParsedProduct[] = [];
  const validProducts: Array<{ parsed: ParsedProduct; priceRows: CsvRow[] }> = [];

  for (const [sku, rows] of skuGroups) {
    const first = rows[0];
    const rowNum = parseInt((first as any).__row || '0');

    const nameDe = normalize(first.name_de || first.name || first.bezeichnung || '');
    const nameEn = normalize(first.name_en || first.name_english || '');
    const type = normalize(first.type || first.typ || first.produkttyp || 'DRINK').toUpperCase();
    const group = normalize(first.group || first.gruppe || first.produktgruppe || first.kategorie || '');

    const errors: string[] = [];
    if (!nameDe) errors.push('Name (DE) fehlt');
    if (!['WINE', 'DRINK', 'FOOD'].includes(type)) errors.push(`Typ "${type}" ungueltig (WINE/DRINK/FOOD)`);

    // Check prices
    rows.forEach(r => {
      const fq = normalize(r.fill_quantity || r.fuellmenge || r.menge || '');
      const pl = normalize(r.price_level || r.preisebene || r.preislevel || 'Restaurant');
      const price = normalize(r.price || r.preis || r.vk || '');
      if (fq && !fqMap.has(fq.toLowerCase())) errors.push(`Fuellmenge "${fq}" nicht gefunden`);
      if (pl && !plMap.has(pl.toLowerCase())) errors.push(`Preisebene "${pl}" nicht gefunden`);
      if (!price || isNaN(parseFloat(price.replace(',', '.')))) errors.push(`Preis ungueltig: "${price}"`);
    });

    const existingId = skuMap.get(sku);
    const status = errors.length > 0 ? 'error' : existingId ? 'update' : 'new';

    const p: ParsedProduct = {
      row: rowNum,
      sku,
      type,
      group,
      nameDe,
      nameEn,
      shortDescDe: normalize(first.short_description_de || first.kurzbeschreibung || first.beschreibung || ''),
      shortDescEn: normalize(first.short_description_en || first.kurzbeschreibung_en || ''),
      longDescDe: normalize(first.long_description_de || first.langbeschreibung || ''),
      longDescEn: normalize(first.long_description_en || first.langbeschreibung_en || ''),
      fillQuantity: normalize(rows[0].fill_quantity || rows[0].fuellmenge || rows[0].menge || ''),
      priceLevel: normalize(rows[0].price_level || rows[0].preisebene || rows[0].preislevel || 'Restaurant'),
      price: normalize(rows[0].price || rows[0].preis || rows[0].vk || ''),
      purchasePrice: normalize(rows[0].purchase_price || rows[0].ek || rows[0].einkaufspreis || ''),
      winery: normalize(first.winery || first.weingut || ''),
      vintage: normalize(first.vintage || first.jahrgang || ''),
      grapes: normalize(first.grapes || first.grape_varieties || first.rebsorten || ''),
      region: normalize(first.region || ''),
      country: normalize(first.country || first.land || ''),
      wineStyle: normalize(first.wine_style || first.weinstil || first.stil || ''),
      body: normalize(first.body || first.koerper || ''),
      sweetness: normalize(first.sweetness || first.suesse || ''),
      bottleSize: normalize(first.bottle_size || first.flaschengroesse || ''),
      alcohol: normalize(first.alcohol || first.alkohol || first.alkoholgehalt || ''),
      servingTemp: normalize(first.serving_temp || first.trinktemperatur || ''),
      tastingNotes: normalize(first.tasting_notes || first.verkostungsnotizen || ''),
      foodPairing: normalize(first.food_pairing || first.speiseempfehlung || ''),
      brand: normalize(first.brand || first.marke || ''),
      producer: normalize(first.producer || first.produzent || first.hersteller || ''),
      bevCategory: normalize(first.bev_category || first.getraenkekategorie || ''),
      bevAlcohol: normalize(first.bev_alcohol || first.alkoholgehalt || ''),
      carbonated: normalize(first.carbonated || first.kohlensaeure || ''),
      origin: normalize(first.origin || first.herkunft || ''),
      status: status as any,
      statusMsg: errors.length > 0 ? errors.join('; ') : existingId ? 'Wird aktualisiert' : 'Neues Produkt',
      existingId,
    };

    products.push(p);
    if (status !== 'error') validProducts.push({ parsed: p, priceRows: rows });
  }

  // Preview mode: return parsed data
  if (action === 'preview') {
    const summary = {
      total: products.length,
      new: products.filter(p => p.status === 'new').length,
      update: products.filter(p => p.status === 'update').length,
      error: products.filter(p => p.status === 'error').length,
    };
    return NextResponse.json({ products, summary });
  }

  // Execute mode: import products
  if (action === 'execute') {
    let created = 0;
    let updated = 0;
    let errors = 0;

    for (const { parsed: p, priceRows } of validProducts) {
      try {
        const productData = {
          sku: p.sku,
          type: p.type as any,
          status: 'ACTIVE' as any,
          isHighlight: false,
          productGroupId: p.group ? pgMap.get(p.group.toLowerCase()) || null : null,
        };

        // Build translations
        const translations = [
          { languageCode: 'de', name: p.nameDe, shortDescription: p.shortDescDe || null, longDescription: p.longDescDe || null },
        ];
        if (p.nameEn) {
          translations.push({ languageCode: 'en', name: p.nameEn, shortDescription: p.shortDescEn || null, longDescription: p.longDescEn || null });
        }

        // Build prices
        const prices = priceRows.map(r => {
          const fq = normalize(r.fill_quantity || r.fuellmenge || r.menge || '');
          const pl = normalize(r.price_level || r.preisebene || r.preislevel || 'Restaurant');
          const priceVal = parseFloat(normalize(r.price || r.preis || r.vk || '0').replace(',', '.'));
          const ekVal = normalize(r.purchase_price || r.ek || r.einkaufspreis || '');
          return {
            fillQuantityId: fqMap.get(fq.toLowerCase()) || fqMap.values().next().value,
            priceLevelId: plMap.get(pl.toLowerCase()) || plMap.values().next().value,
            price: priceVal,
            purchasePrice: ekVal ? parseFloat(ekVal.replace(',', '.')) : null,
            isDefault: true,
            sortOrder: 0,
          };
        }).filter(pr => pr.fillQuantityId && pr.priceLevelId);

        // Mark first as default
        prices.forEach((pr, i) => { pr.isDefault = i === 0; pr.sortOrder = i; });

        if (p.existingId) {
          // UPDATE existing product
          await prisma.product.update({
            where: { id: p.existingId },
            data: {
              ...productData,
              translations: {
                deleteMany: {},
                create: translations,
              },
              prices: {
                deleteMany: {},
                create: prices,
              },
            },
          });

          // Wine profile
          if (p.type === 'WINE' && p.winery) {
            await prisma.productWineProfile.upsert({
              where: { productId: p.existingId },
              create: {
                productId: p.existingId,
                winery: p.winery || null,
                vintage: p.vintage ? parseInt(p.vintage) : null,
                grapeVarieties: p.grapes ? p.grapes.split(',').map(g => g.trim()) : [],
                region: p.region || null,
                country: p.country || null,
                style: p.wineStyle ? p.wineStyle.toUpperCase() as any : null,
                body: p.body ? p.body.toUpperCase() as any : null,
                sweetness: p.sweetness ? p.sweetness.toUpperCase() as any : null,
                bottleSize: p.bottleSize || '0.75l',
                alcoholContent: p.alcohol ? parseFloat(p.alcohol.replace(',', '.')) : null,
                servingTemp: p.servingTemp || null,
                tastingNotes: p.tastingNotes || null,
                foodPairing: p.foodPairing || null,
              },
              update: {
                winery: p.winery || null,
                vintage: p.vintage ? parseInt(p.vintage) : null,
                grapeVarieties: p.grapes ? p.grapes.split(',').map(g => g.trim()) : [],
                region: p.region || null,
                country: p.country || null,
                style: p.wineStyle ? p.wineStyle.toUpperCase() as any : null,
                body: p.body ? p.body.toUpperCase() as any : null,
                sweetness: p.sweetness ? p.sweetness.toUpperCase() as any : null,
                bottleSize: p.bottleSize || '0.75l',
                alcoholContent: p.alcohol ? parseFloat(p.alcohol.replace(',', '.')) : null,
                servingTemp: p.servingTemp || null,
                tastingNotes: p.tastingNotes || null,
                foodPairing: p.foodPairing || null,
              },
            });
          }

          // Beverage detail
          if (p.type === 'DRINK' && (p.brand || p.producer || p.bevCategory)) {
            await prisma.productBeverageDetail.upsert({
              where: { productId: p.existingId },
              create: {
                productId: p.existingId,
                brand: p.brand || null,
                producer: p.producer || null,
                category: p.bevCategory ? p.bevCategory.toUpperCase() as any : null,
                alcoholContent: p.bevAlcohol ? parseFloat(p.bevAlcohol.replace(',', '.')) : null,
                carbonated: p.carbonated === 'ja' || p.carbonated === 'true' || p.carbonated === '1',
                origin: p.origin || null,
              },
              update: {
                brand: p.brand || null,
                producer: p.producer || null,
                category: p.bevCategory ? p.bevCategory.toUpperCase() as any : null,
                alcoholContent: p.bevAlcohol ? parseFloat(p.bevAlcohol.replace(',', '.')) : null,
                carbonated: p.carbonated === 'ja' || p.carbonated === 'true' || p.carbonated === '1',
                origin: p.origin || null,
              },
            });
          }

          updated++;
        } else {
          // CREATE new product
          const newProduct = await prisma.product.create({
            data: {
              tenantId,
              ...productData,
              translations: { create: translations },
              prices: { create: prices },
            },
          });

          // Wine profile
          if (p.type === 'WINE' && p.winery) {
            await prisma.productWineProfile.create({
              data: {
                productId: newProduct.id,
                winery: p.winery || null,
                vintage: p.vintage ? parseInt(p.vintage) : null,
                grapeVarieties: p.grapes ? p.grapes.split(',').map(g => g.trim()) : [],
                region: p.region || null,
                country: p.country || null,
                style: p.wineStyle ? p.wineStyle.toUpperCase() as any : null,
                body: p.body ? p.body.toUpperCase() as any : null,
                sweetness: p.sweetness ? p.sweetness.toUpperCase() as any : null,
                bottleSize: p.bottleSize || '0.75l',
                alcoholContent: p.alcohol ? parseFloat(p.alcohol.replace(',', '.')) : null,
                servingTemp: p.servingTemp || null,
                tastingNotes: p.tastingNotes || null,
                foodPairing: p.foodPairing || null,
              },
            });
          }

          // Beverage detail
          if (p.type === 'DRINK' && (p.brand || p.producer || p.bevCategory)) {
            await prisma.productBeverageDetail.create({
              data: {
                productId: newProduct.id,
                brand: p.brand || null,
                producer: p.producer || null,
                category: p.bevCategory ? p.bevCategory.toUpperCase() as any : null,
                alcoholContent: p.bevAlcohol ? parseFloat(p.bevAlcohol.replace(',', '.')) : null,
                carbonated: p.carbonated === 'ja' || p.carbonated === 'true' || p.carbonated === '1',
                origin: p.origin || null,
              },
            });
          }

          created++;
        }
      } catch (e: any) {
        console.error(`Import error SKU ${p.sku}:`, e.message);
        errors++;
      }
    }

    return NextResponse.json({ created, updated, errors, total: validProducts.length });
  }

  return NextResponse.json({ error: 'Invalid action' }, { status: 400 });
}
ENDOFFILE

echo "[1/2] API-Route erstellt"

# === 2. CSV-Template erstellen ===
mkdir -p public/templates

cat > public/templates/import-vorlage.csv << 'CSVEOF'
sku;type;name_de;name_en;short_description_de;short_description_en;group;fill_quantity;price_level;price;purchase_price;winery;vintage;grapes;region;country;wine_style;body;sweetness;bottle_size;alcohol;serving_temp;tasting_notes;food_pairing;brand;producer;bev_category;bev_alcohol;carbonated;origin
WEIN-001;WINE;Grüner Veltliner Smaragd;Grüner Veltliner Smaragd;Frisch und mineralisch;Fresh and mineral;Getränke;Flasche 0,75l;Restaurant;38.50;12.00;Weingut Hirtzberger;2022;Grüner Veltliner;Wachau;Österreich;WHITE;MEDIUM;DRY;0.75l;13.5;8-10°C;Aromen von grünem Apfel und weißem Pfeffer;Fisch, Wiener Schnitzel;;;;;;
WEIN-001;WINE;Grüner Veltliner Smaragd;Grüner Veltliner Smaragd;;;Getränke;1/8 offen;Restaurant;6.80;;;;;;;;;;;;;;;;;
DRINK-001;DRINK;Aperol Spritz;Aperol Spritz;Der Klassiker;The classic;Getränke;Cocktail;Bar;8.90;2.50;;;;;;;;;;;;;;;Aperol;Campari Group;COCKTAIL;11;nein;Italien
FOOD-001;FOOD;Wiener Schnitzel;Wiener Schnitzel;Vom Kalb mit Preiselbeeren;Veal with lingonberries;Speisen;Portion;Restaurant;22.50;6.80;;;;;;;;;;;;;;;;;;;
CSVEOF

echo "[2/2] CSV-Template erstellt: public/templates/import-vorlage.csv"

echo ""
echo "=== API + Template fertig ==="
echo "Weiter mit Script 2 (UI-Komponente)"
