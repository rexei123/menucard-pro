// @ts-nocheck
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


const VALID_BEVERAGE_CATEGORIES = ['BEER', 'WINE', 'SPIRIT', 'COCKTAIL', 'SOFT_DRINK', 'HOT_DRINK', 'JUICE', 'WATER', 'OTHER'];
const VALID_WINE_STYLES = ['RED', 'WHITE', 'ROSE', 'SPARKLING', 'DESSERT', 'FORTIFIED', 'ORANGE', 'NATURAL'];
const VALID_BODY = ['LIGHT', 'MEDIUM_LIGHT', 'MEDIUM', 'MEDIUM_FULL', 'FULL'];
const VALID_SWEETNESS = ['BONE_DRY', 'DRY', 'OFF_DRY', 'MEDIUM_DRY', 'MEDIUM_SWEET', 'SWEET', 'VERY_SWEET'];

function safeEnum<T>(val: string | undefined | null, validValues: string[]): T | null {
  if (!val) return null;
  const upper = val.toUpperCase().trim();
  return validValues.includes(upper) ? upper as T : null;
}

function safeFloat(val: string | undefined | null): number | null {
  if (!val) return null;
  const num = parseFloat(val.replace(',', '.'));
  return isNaN(num) ? null : num;
}

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

  // Load lookup data — v2: TaxonomyNode statt ProductGroup
  const [fillQuantities, priceLevels, taxonomyNodes, existingProducts] = await Promise.all([
    prisma.fillQuantity.findMany({ where: { tenantId } }),
    prisma.priceLevel.findMany({ where: { tenantId } }),
    prisma.taxonomyNode.findMany({ where: { tenantId, type: 'CATEGORY' }, include: { translations: true } }),
    prisma.product.findMany({ where: { tenantId }, select: { id: true, sku: true } }),
  ]);

  const skuMap = new Map(existingProducts.filter(p => p.sku).map(p => [p.sku!, p.id]));
  const fqMap = new Map(fillQuantities.map(f => [f.label.toLowerCase(), f.id]));
  const plMap = new Map(priceLevels.map(p => [p.name.toLowerCase(), p.id]));
  // v2: Taxonomy-Lookup statt ProductGroup
  const taxMap = new Map<string, string>();
  taxonomyNodes.forEach(tn => {
    tn.translations.forEach(t => taxMap.set(t.name.toLowerCase(), tn.id));
  });

  // Track items that need to be auto-created
  const newFillQuantities = new Set<string>();
  const newTaxonomyNodes = new Set<string>();

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

  for (const [sku, rows] of Array.from(skuGroups.entries())) {
    const first = rows[0];
    const rowNum = parseInt((first as any).__row || '0');

    const nameDe = normalize(first.name_de || first.name || first.bezeichnung || '');
    const nameEn = normalize(first.name_en || first.name_english || '');
    const type = normalize(first.type || first.typ || first.produkttyp || 'DRINK').toUpperCase();
    const group = normalize(first.group || first.gruppe || first.produktgruppe || first.kategorie || '');

    const errors: string[] = [];
    if (!nameDe) errors.push('Name (DE) fehlt');
    if (!['WINE', 'DRINK', 'FOOD'].includes(type)) errors.push(`Typ "${type}" ungueltig (WINE/DRINK/FOOD)`);
    if (group && !taxMap.has(group.toLowerCase())) newTaxonomyNodes.add(group);

    // Check prices
    rows.forEach(r => {
      const fq = normalize(r.fill_quantity || r.fuellmenge || r.menge || '');
      const pl = normalize(r.price_level || r.preisebene || r.preislevel || 'Restaurant');
      const price = normalize(r.price || r.preis || r.vk || '');
      if (fq && !fqMap.has(fq.toLowerCase())) newFillQuantities.add(fq);
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
    const autoCreate = {
      fillQuantities: Array.from(newFillQuantities),
      taxonomyNodes: Array.from(newTaxonomyNodes),
    };
    return NextResponse.json({ products, summary, autoCreate });
  }

  // Execute mode: import products
  if (action === 'execute') {
    // Auto-create missing fill quantities
    for (const label of Array.from(newFillQuantities)) {
      const newFq = await prisma.fillQuantity.create({
        data: { tenantId, label, sortOrder: fillQuantities.length + 1 },
      });
      fqMap.set(label.toLowerCase(), newFq.id);
      console.log('Auto-created fill quantity:', label);
    }

    // v2: Auto-create missing TaxonomyNodes (statt ProductGroup)
    for (const groupName of Array.from(newTaxonomyNodes)) {
      const slug = groupName.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
      const newTn = await prisma.taxonomyNode.create({
        data: {
          tenantId,
          type: 'CATEGORY',
          slug,
          sortOrder: taxonomyNodes.length + 1,
          translations: {
            create: [
              { language: 'de', name: groupName },
              { language: 'en', name: groupName },
            ],
          },
        },
      });
      taxMap.set(groupName.toLowerCase(), newTn.id);
      console.log('Auto-created taxonomy node:', groupName);
    }

    let created = 0;
    let updated = 0;
    let errors = 0;

    for (const { parsed: p, priceRows } of validProducts) {
      try {
        // v2: Product ohne prices, ohne isHighlight, ohne productGroupId
        const productData: any = {
          sku: p.sku,
          type: p.type as any,
          status: 'ACTIVE' as any,
        };

        // v2: Translations mit language statt languageCode
        const translations = [
          { language: 'de', name: p.nameDe, shortDescription: p.shortDescDe || null, longDescription: p.longDescDe || null },
        ];
        if (p.nameEn) {
          translations.push({ language: 'en', name: p.nameEn, shortDescription: p.shortDescEn || null, longDescription: p.longDescEn || null });
        }

        // v2: Taxonomy-Verknüpfung
        const taxonomyNodeId = p.group ? taxMap.get(p.group.toLowerCase()) || null : null;

        // v2: Varianten + VariantPrice statt product.prices
        const variantPrices = priceRows.map((r, i) => {
          const fq = normalize(r.fill_quantity || r.fuellmenge || r.menge || '');
          const pl = normalize(r.price_level || r.preisebene || r.preislevel || 'Restaurant');
          const priceVal = parseFloat(normalize(r.price || r.preis || r.vk || '0').replace(',', '.'));
          const ekVal = normalize(r.purchase_price || r.ek || r.einkaufspreis || '');
          return {
            fqId: fqMap.get(fq.toLowerCase()) || Array.from(fqMap.values())[0],
            plId: plMap.get(pl.toLowerCase()) || Array.from(plMap.values())[0],
            sellPrice: priceVal,
            costPrice: ekVal ? parseFloat(ekVal.replace(',', '.')) : null,
            isDefault: i === 0,
            fqLabel: fq,
          };
        });

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
            },
          });

          // v2: Taxonomy-Verknüpfung aktualisieren
          if (taxonomyNodeId) {
            await prisma.productTaxonomy.deleteMany({ where: { productId: p.existingId } });
            await prisma.productTaxonomy.create({
              data: { productId: p.existingId, taxonomyNodeId },
            });
          }

          // v2: Default-Variante + Preise aktualisieren
          const existingVariants = await prisma.productVariant.findMany({
            where: { productId: p.existingId },
            include: { prices: true },
          });

          if (existingVariants.length > 0) {
            // Bestehende Default-Variante aktualisieren
            const defaultVariant = existingVariants.find(v => v.isDefault) || existingVariants[0];
            // Alte Preise löschen und neue erstellen
            await prisma.variantPrice.deleteMany({ where: { variantId: defaultVariant.id } });
            for (const vp of variantPrices) {
              await prisma.variantPrice.create({
                data: {
                  variantId: defaultVariant.id,
                  priceLevelId: vp.plId,
                  sellPrice: vp.sellPrice,
                  costPrice: vp.costPrice,
                  pricingType: 'FIXED',
                },
              });
            }
          } else {
            // Keine Variante vorhanden — neue Default-Variante erstellen
            const fqId = variantPrices[0]?.fqId;
            const newVariant = await prisma.productVariant.create({
              data: {
                productId: p.existingId,
                fillQuantityId: fqId || null,
                label: null,
                isDefault: true,
                isSellable: true,
                sortOrder: 0,
              },
            });
            for (const vp of variantPrices) {
              await prisma.variantPrice.create({
                data: {
                  variantId: newVariant.id,
                  priceLevelId: vp.plId,
                  sellPrice: vp.sellPrice,
                  costPrice: vp.costPrice,
                  pricingType: 'FIXED',
                },
              });
            }
          }

          // Wine profile (Prisma-Modell heißt weiterhin ProductWineProfile)
          if (p.type === 'WINE' && p.winery) {
            await prisma.productWineProfile.upsert({
              where: { productId: p.existingId },
              create: {
                productId: p.existingId,
                winery: p.winery || null,
                vintage: p.vintage ? (isNaN(parseInt(p.vintage)) ? null : parseInt(p.vintage)) : null,
                aging: null,
                tastingNotes: p.tastingNotes || null,
                servingTemp: p.servingTemp || null,
                foodPairing: p.foodPairing || null,
                certification: null,
              },
              update: {
                winery: p.winery || null,
                vintage: p.vintage ? (isNaN(parseInt(p.vintage)) ? null : parseInt(p.vintage)) : null,
                tastingNotes: p.tastingNotes || null,
                servingTemp: p.servingTemp || null,
                foodPairing: p.foodPairing || null,
              },
            });
          }

          // Beverage detail (Prisma-Modell heißt weiterhin ProductBeverageDetail)
          if (p.type === 'DRINK' && (p.brand || p.producer || p.bevCategory)) {
            await prisma.productBeverageDetail.upsert({
              where: { productId: p.existingId },
              create: {
                productId: p.existingId,
                brand: p.brand || null,
                alcoholContent: safeFloat(p.bevAlcohol),
              },
              update: {
                brand: p.brand || null,
                alcoholContent: safeFloat(p.bevAlcohol),
              },
            });
          }

          updated++;
        } else {
          // CREATE new product — v2: ohne productGroupId, ohne isHighlight
          const newProduct = await prisma.product.create({
            data: {
              tenantId,
              ...productData,
              translations: { create: translations },
            },
          });

          // v2: Taxonomy-Verknüpfung
          if (taxonomyNodeId) {
            await prisma.productTaxonomy.create({
              data: { productId: newProduct.id, taxonomyNodeId },
            });
          }

          // v2: Default-Variante + VariantPrice
          const fqId = variantPrices[0]?.fqId;
          const newVariant = await prisma.productVariant.create({
            data: {
              productId: newProduct.id,
              fillQuantityId: fqId || null,
              label: null,
              isDefault: true,
              isSellable: true,
              sortOrder: 0,
            },
          });

          for (const vp of variantPrices) {
            await prisma.variantPrice.create({
              data: {
                variantId: newVariant.id,
                priceLevelId: vp.plId,
                sellPrice: vp.sellPrice,
                costPrice: vp.costPrice,
                pricingType: 'FIXED',
              },
            });
          }

          // Wine profile
          if (p.type === 'WINE' && p.winery) {
            await prisma.productWineProfile.create({
              data: {
                productId: newProduct.id,
                winery: p.winery || null,
                vintage: p.vintage ? (isNaN(parseInt(p.vintage)) ? null : parseInt(p.vintage)) : null,
                aging: null,
                tastingNotes: p.tastingNotes || null,
                servingTemp: p.servingTemp || null,
                foodPairing: p.foodPairing || null,
                certification: null,
              },
            });
          }

          // Beverage detail
          if (p.type === 'DRINK' && (p.brand || p.producer || p.bevCategory)) {
            await prisma.productBeverageDetail.create({
              data: {
                productId: newProduct.id,
                brand: p.brand || null,
                alcoholContent: safeFloat(p.bevAlcohol),
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
