import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

// ─── GET: Einzelnes Produkt mit allen Relationen ───
export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const product = await prisma.product.findFirst({
    where: { id: params.id, tenantId: session.user.tenantId },
    include: {
      translations: true,
      variants: {
        orderBy: { sortOrder: 'asc' },
        include: {
          fillQuantity: true,
          prices: { include: { priceLevel: true, taxRate: true }, orderBy: { priceLevelId: 'asc' } },
        },
      },
      taxonomy: { include: { node: { include: { translations: true, parent: true } } } },
      allergens: { include: { allergen: { include: { translations: true } } } },
      tags: true,
      wineProfile: true,
      beverageDetail: true,
      productMedia: { include: { media: true }, orderBy: { sortOrder: 'asc' } },
      modifierGroups: { include: { group: { include: { modifiers: true } } } },
    },
  });
  if (!product) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  return NextResponse.json(product);
}

// ─── PATCH: Produkt aktualisieren (v2 mit Varianten, v1-kompatibel mit prices[]) ───
export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const product = await prisma.product.findFirst({
    where: { id: params.id, tenantId: session.user.tenantId },
    include: { variants: { where: { isDefault: true }, take: 1 } },
  });
  if (!product) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  const body = await req.json();
  const { translations, prices, variants, wineProfile, beverageDetail, taxonomy, allergenIds, tags, ...productData } = body;

  await prisma.$transaction(async (tx) => {
    // ── Produkt-Basisfelder ──
    if (Object.keys(productData).length > 0) {
      const allowed = ['type', 'status', 'sku', 'highlightType', 'supplierId'];
      const data: any = {};
      for (const k of allowed) { if (productData[k] !== undefined) data[k] = productData[k]; }
      if (Object.keys(data).length > 0) {
        await tx.product.update({ where: { id: params.id }, data });
      }
    }

    // ── Translations ──
    if (translations) {
      for (const t of translations) {
        const lang = t.languageCode || t.language || 'de';
        await tx.productTranslation.upsert({
          where: { productId_languageCode: { productId: params.id, languageCode: lang } },
          update: {
            language: lang,
            name: t.name,
            shortDescription: t.shortDescription || null,
            longDescription: t.longDescription || null,
            servingSuggestion: t.servingSuggestion || null,
            recipe: t.recipe || null,
            notes: t.notes || null,
          },
          create: {
            productId: params.id,
            language: lang,
            languageCode: lang,
            name: t.name,
            shortDescription: t.shortDescription || null,
            longDescription: t.longDescription || null,
            servingSuggestion: t.servingSuggestion || null,
            recipe: t.recipe || null,
            notes: t.notes || null,
          },
        });
      }
    }

    // ── Wine Profile ──
    if (wineProfile !== undefined) {
      if (wineProfile === null) {
        await tx.productWineProfile.deleteMany({ where: { productId: params.id } });
      } else {
        await tx.productWineProfile.upsert({
          where: { productId: params.id },
          update: wineProfile,
          create: { productId: params.id, ...wineProfile },
        });
      }
    }

    // ── Beverage Detail ──
    if (beverageDetail !== undefined) {
      if (beverageDetail === null) {
        await tx.productBeverageDetail.deleteMany({ where: { productId: params.id } });
      } else {
        await tx.productBeverageDetail.upsert({
          where: { productId: params.id },
          update: beverageDetail,
          create: { productId: params.id, ...beverageDetail },
        });
      }
    }

    // ── Taxonomie (v2: ersetzt productGroupId) ──
    if (taxonomy) {
      // taxonomy = [{ nodeId: 'xxx', isPrimary: true }, ...]
      await tx.productTaxonomy.deleteMany({ where: { productId: params.id } });
      if (taxonomy.length > 0) {
        await tx.productTaxonomy.createMany({
          data: taxonomy.map((t: any) => ({
            productId: params.id,
            nodeId: t.nodeId,
            isPrimary: t.isPrimary || false,
          })),
        });
      }
    }

    // ── Allergene ──
    if (allergenIds) {
      await tx.productAllergen.deleteMany({ where: { productId: params.id } });
      if (allergenIds.length > 0) {
        await tx.productAllergen.createMany({
          data: allergenIds.map((aid: string) => ({ productId: params.id, allergenId: aid })),
        });
      }
    }

    // ── Tags ──
    if (tags) {
      await tx.productTag.deleteMany({ where: { productId: params.id } });
      if (tags.length > 0) {
        await tx.productTag.createMany({
          data: tags.map((tag: string) => ({ productId: params.id, tag })),
        });
      }
    }

    // ── COMPAT: v1-prices[] → Default-Variante ──
    if (prices && !variants) {
      const defaultVariant = product.variants[0];
      if (defaultVariant) {
        const keepIds = prices.filter((p: any) => p.id).map((p: any) => p.id);
        await tx.variantPrice.deleteMany({
          where: { variantId: defaultVariant.id, id: { notIn: keepIds } },
        });
        for (const p of prices) {
          if (p.id) {
            await tx.variantPrice.update({
              where: { id: p.id },
              data: {
                sellPrice: p.price ?? p.sellPrice,
                costPrice: p.purchasePrice ?? p.costPrice ?? null,
                fixedMarkup: p.fixedMarkup || null,
                percentMarkup: p.percentMarkup || null,
                priceLevelId: p.priceLevelId,
              },
            });
          } else {
            await tx.variantPrice.create({
              data: {
                variantId: defaultVariant.id,
                priceLevelId: p.priceLevelId,
                sellPrice: p.price ?? p.sellPrice,
                costPrice: p.purchasePrice ?? p.costPrice ?? null,
                fixedMarkup: p.fixedMarkup || null,
                percentMarkup: p.percentMarkup || null,
              },
            });
          }
        }
      }
    }

    // ── v2: Varianten direkt bearbeiten ──
    if (variants) {
      for (const v of variants) {
        if (v.id) {
          // Bestehende Variante aktualisieren
          await tx.productVariant.update({
            where: { id: v.id },
            data: {
              fillQuantityId: v.fillQuantityId,
              label: v.label || null,
              sku: v.sku || null,
              sortOrder: v.sortOrder ?? 0,
              isDefault: v.isDefault ?? false,
              isSellable: v.isSellable ?? true,
              status: v.status || 'ACTIVE',
            },
          });

          // Preise dieser Variante
          if (v.prices) {
            const keepPriceIds = v.prices.filter((p: any) => p.id).map((p: any) => p.id);
            await tx.variantPrice.deleteMany({
              where: { variantId: v.id, id: { notIn: keepPriceIds } },
            });
            for (const p of v.prices) {
              if (p.id) {
                await tx.variantPrice.update({
                  where: { id: p.id },
                  data: {
                    sellPrice: p.sellPrice,
                    costPrice: p.costPrice ?? null,
                    fixedMarkup: p.fixedMarkup || null,
                    percentMarkup: p.percentMarkup || null,
                    priceLevelId: p.priceLevelId,
                    taxRateId: p.taxRateId || null,
                    pricingType: p.pricingType || 'FIXED',
                  },
                });
              } else {
                await tx.variantPrice.create({
                  data: {
                    variantId: v.id,
                    priceLevelId: p.priceLevelId,
                    sellPrice: p.sellPrice,
                    costPrice: p.costPrice ?? null,
                    fixedMarkup: p.fixedMarkup || null,
                    percentMarkup: p.percentMarkup || null,
                    taxRateId: p.taxRateId || null,
                    pricingType: p.pricingType || 'FIXED',
                  },
                });
              }
            }
          }
        } else {
          // Neue Variante anlegen
          const newVariant = await tx.productVariant.create({
            data: {
              productId: params.id,
              fillQuantityId: v.fillQuantityId || null,
              label: v.label || null,
              sku: v.sku || null,
              sortOrder: v.sortOrder ?? 0,
              isDefault: v.isDefault ?? false,
              isSellable: v.isSellable ?? true,
            },
          });
          if (v.prices) {
            for (const p of v.prices) {
              await tx.variantPrice.create({
                data: {
                  variantId: newVariant.id,
                  priceLevelId: p.priceLevelId,
                  sellPrice: p.sellPrice,
                  costPrice: p.costPrice ?? null,
                  fixedMarkup: p.fixedMarkup || null,
                  percentMarkup: p.percentMarkup || null,
                  taxRateId: p.taxRateId || null,
                  pricingType: p.pricingType || 'FIXED',
                },
              });
            }
          }
        }
      }
    }
  });

  return NextResponse.json({ success: true });
}

// ─── DELETE: Produkt mit allen Relationen loeschen ───
export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const product = await prisma.product.findFirst({
    where: { id: params.id, tenantId: session.user.tenantId },
  });
  if (!product) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  // Kaskade: Varianten-bezogene Daten zuerst
  await prisma.$transaction(async (tx) => {
    // Placements referenzieren Varianten, nicht Produkte
    const variantIds = (await tx.productVariant.findMany({
      where: { productId: params.id },
      select: { id: true },
    })).map(v => v.id);

    if (variantIds.length > 0) {
      await tx.menuPlacement.deleteMany({ where: { variantId: { in: variantIds } } });
      await tx.variantPrice.deleteMany({ where: { variantId: { in: variantIds } } });
      await tx.stockLevel.deleteMany({ where: { variantId: { in: variantIds } } });
      await tx.productVariant.deleteMany({ where: { productId: params.id } });
    }

    await tx.productTranslation.deleteMany({ where: { productId: params.id } });
    await tx.productWineProfile.deleteMany({ where: { productId: params.id } });
    await tx.productBeverageDetail.deleteMany({ where: { productId: params.id } });
    await tx.productAllergen.deleteMany({ where: { productId: params.id } });
    await tx.productTag.deleteMany({ where: { productId: params.id } });
    await tx.productMedia.deleteMany({ where: { productId: params.id } });
    await tx.productCustomFieldValue.deleteMany({ where: { productId: params.id } });
    await tx.productTaxonomy.deleteMany({ where: { productId: params.id } });
    await tx.product.delete({ where: { id: params.id } });
  });

  return NextResponse.json({ success: true });
}
