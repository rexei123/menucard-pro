// @ts-nocheck
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

/**
 * POST /api/v1/products/[id]/duplicate
 * Dupliziert ein Produkt für einen neuen Jahrgang.
 * Body: { vintage?: number }
 * - Kopiert: Übersetzungen, Taxonomie, Weinprofil, Getränkedetail, Varianten+Preise, Tags
 * - Verknüpft über lineageId (wird automatisch erzeugt/übernommen)
 */
export async function POST(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;

  const body = await req.json().catch(() => ({}));
  const newVintage = body.vintage || null;

  // Original laden mit allen Relationen
  const original = await prisma.product.findUnique({
    where: { id: params.id },
    include: {
      translations: true,
      taxonomy: true,
      wineProfile: true,
      beverageDetail: true,
      variants: { include: { prices: true } },
      tags: true,
    },
  });

  if (!original || original.tenantId !== tid) {
    return NextResponse.json({ error: 'Produkt nicht gefunden' }, { status: 404 });
  }

  // LineageId: Entweder vom Original übernehmen oder neue erstellen
  const lineageId = original.lineageId || original.id;

  // Original bekommt auch die lineageId (falls noch nicht gesetzt)
  if (!original.lineageId) {
    await prisma.product.update({
      where: { id: original.id },
      data: { lineageId },
    });
  }

  // Neuen Namen für Übersetzungen: Jahrgang im Namen ersetzen
  const updateTranslationName = (name: string, oldVintage: number | null, newVint: number | null) => {
    if (!name) return name;
    if (oldVintage && newVint) {
      // Jahrgang im Namen ersetzen (z.B. "Blaufränkisch 2021" → "Blaufränkisch 2022")
      return name.replace(String(oldVintage), String(newVint));
    }
    return name;
  };

  const oldVintage = original.wineProfile?.vintage || null;

  // SKU anpassen (Jahrgang ersetzen oder -copy anhängen)
  let newSku = null;
  if (original.sku) {
    if (oldVintage && newVintage) {
      newSku = original.sku.replace(String(oldVintage), String(newVintage));
      if (newSku === original.sku) newSku = `${original.sku}-${newVintage}`;
    } else {
      newSku = `${original.sku}-copy`;
    }
    // Prüfe ob SKU schon existiert
    const existing = await prisma.product.findFirst({ where: { tenantId: tid, sku: newSku } });
    if (existing) {
      newSku = `${newSku}-${Date.now().toString(36).slice(-4)}`;
    }
  }

  // Neues Produkt erstellen
  const newProduct = await prisma.product.create({
    data: {
      tenantId: tid,
      type: original.type,
      status: 'DRAFT', // Immer als Entwurf starten
      sku: newSku,
      highlightType: original.highlightType,
      lineageId,

      // Übersetzungen kopieren
      translations: {
        create: original.translations.map(t => ({
          language: t.language || t.languageCode || 'de',
          languageCode: t.languageCode || t.language || 'de',
          name: updateTranslationName(t.name, oldVintage, newVintage),
          shortDescription: t.shortDescription,
          longDescription: t.longDescription,
          servingSuggestion: t.servingSuggestion,
          recipe: t.recipe,
          notes: t.notes,
        })),
      },

      // Taxonomie-Zuordnungen kopieren
      taxonomy: {
        create: original.taxonomy.map(pt => ({
          nodeId: pt.nodeId,
          isPrimary: pt.isPrimary,
        })),
      },

      // Tags kopieren
      tags: {
        create: original.tags.map(tg => ({
          tag: tg.tag,
        })),
      },
    },
  });

  // Weinprofil kopieren (mit neuem Jahrgang)
  if (original.wineProfile) {
    await prisma.productWineProfile.create({
      data: {
        productId: newProduct.id,
        winery: original.wineProfile.winery,
        vintage: newVintage || original.wineProfile.vintage,
        aging: original.wineProfile.aging,
        tastingNotes: original.wineProfile.tastingNotes,
        servingTemp: original.wineProfile.servingTemp,
        foodPairing: original.wineProfile.foodPairing,
        certification: original.wineProfile.certification,
      },
    });
  }

  // Getränkedetail kopieren
  if (original.beverageDetail) {
    await prisma.productBeverageDetail.create({
      data: {
        productId: newProduct.id,
        brand: original.beverageDetail.brand,
        alcoholContent: original.beverageDetail.alcoholContent,
        servingStyle: original.beverageDetail.servingStyle,
        garnish: original.beverageDetail.garnish,
        glassType: original.beverageDetail.glassType,
      },
    });
  }

  // Varianten + Preise kopieren
  for (const variant of original.variants) {
    const newVariant = await prisma.productVariant.create({
      data: {
        productId: newProduct.id,
        label: variant.label,
        sku: variant.sku ? `${variant.sku}-${newVintage || 'copy'}` : null,
        fillQuantityId: variant.fillQuantityId,
        isDefault: variant.isDefault,
        sortOrder: variant.sortOrder,
        status: variant.status,
      },
    });

    // Preise kopieren
    for (const price of variant.prices) {
      await prisma.variantPrice.create({
        data: {
          variantId: newVariant.id,
          priceLevelId: price.priceLevelId,
          sellPrice: price.sellPrice,
          costPrice: price.costPrice,
          fixedMarkup: price.fixedMarkup,
          percentMarkup: price.percentMarkup,
        },
      });
    }
  }

  return NextResponse.json({
    id: newProduct.id,
    message: `Produkt dupliziert${newVintage ? ` für Jahrgang ${newVintage}` : ''}`,
  }, { status: 201 });
}
