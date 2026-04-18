// @ts-nocheck
import { NextRequest, NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { renderToBuffer } from '@react-pdf/renderer';
import { MenuPdfDocument } from '@/lib/pdf/menu-pdf';
import { resolveMenuAnalogConfig } from '@/lib/template-resolver';
import React from 'react';

// Dateiname ASCII-sicher machen für Content-Disposition
function sanitizeFilename(name: string): string {
  return name
    .replace(/ä/g, 'ae').replace(/ö/g, 'oe').replace(/ü/g, 'ue')
    .replace(/Ä/g, 'Ae').replace(/Ö/g, 'Oe').replace(/Ü/g, 'Ue')
    .replace(/ß/g, 'ss')
    .replace(/[^a-zA-Z0-9._\- ]/g, '')
    .trim();
}

// v2: Translation-Helper (language bevorzugt, languageCode als Fallback)
function tr(translations: any[], lang: string, field = 'name') {
  const found = translations?.find((t: any) => t.language === lang || t.languageCode === lang);
  return found?.[field] || undefined;
}

// GET /api/v1/menus/[id]/pdf – PDF generieren (v2)
export async function GET(_req: NextRequest, { params }: { params: { id: string } }) {
  try {
    const menu = await prisma.menu.findUnique({
      where: { id: params.id },
      include: {
        translations: true,
        template: true,
        location: {
          include: { tenant: true },
        },
        sections: {
          orderBy: { sortOrder: 'asc' },
          include: {
            translations: true,
            placements: {
              where: { isVisible: true },
              orderBy: { sortOrder: 'asc' },
              include: {
                // v2: placement → variant → product
                variant: {
                  include: {
                    product: {
                      include: {
                        translations: true,
                        wineProfile: true,
                        productMedia: {
                          where: { isPrimary: true },
                          take: 1,
                        },
                      },
                    },
                    fillQuantity: true,
                    prices: {
                      include: { priceLevel: true },
                    },
                  },
                },
              },
            },
          },
        },
      },
    });
    if (!menu) {
      return NextResponse.json({ error: 'Menu not found' }, { status: 404 });
    }

    // Resolve analog config (templateId bevorzugt, Fallback designConfig)
    const analogConfig = resolveMenuAnalogConfig(menu as any);

    const menuNameDE = tr(menu.translations, 'de') || menu.slug;
    const menuNameEN = tr(menu.translations, 'en') || undefined;

    // v2: Transform sections mit variant-basierter Preisstruktur
    const sections = menu.sections
      .map(section => {
        const sNameDE = tr(section.translations, 'de') || section.slug;
        const sNameEN = tr(section.translations, 'en') || undefined;
        const sDescDE = tr(section.translations, 'de', 'description') || undefined;
        const sDescEN = tr(section.translations, 'en', 'description') || undefined;

        const products = section.placements
          .filter(pl => pl.variant?.product?.status !== 'ARCHIVED')
          .map(pl => {
            const v = pl.variant;
            const p = v?.product;
            if (!p) return null;

            const tDE = p.translations?.find((t: any) => t.language === 'de' || t.languageCode === 'de');
            const tEN = p.translations?.find((t: any) => t.language === 'en' || t.languageCode === 'en');
            const wp = p.wineProfile;

            // v2: Preise aus Variante (mit FillQuantity als Label)
            const prices = (v.prices || []).map((vp: any) => ({
              label: v.fillQuantity?.label || vp.priceLevel?.name || '',
              price: pl.priceOverride ? Number(pl.priceOverride) : Number(vp.sellPrice),
              volume: v.fillQuantity?.volumeMl ? `${v.fillQuantity.volumeMl} ml` : undefined,
            }));

            return {
              id: p.id,
              name: tDE?.name || '',
              nameEN: tEN?.name || undefined,
              shortDescription: tDE?.shortDescription || undefined,
              shortDescriptionEN: tEN?.shortDescription || undefined,
              longDescription: tDE?.longDescription || undefined,
              longDescriptionEN: tEN?.longDescription || undefined,
              prices,
              winery: wp?.winery || undefined,
              wineryLocation: undefined,
              vintage: wp?.vintage || undefined,
              grapeVarieties: undefined,
              region: undefined,
              country: undefined,
              appellation: undefined,
              style: undefined,
              isHighlight: false,
              highlightType: p.highlightType !== 'NONE' ? p.highlightType : undefined,
            };
          })
          .filter(Boolean);

        return {
          id: section.id,
          name: sNameDE,
          nameEN: sNameEN,
          description: sDescDE,
          descriptionEN: sDescEN,
          icon: section.icon || undefined,
          products,
        };
      })
      .filter(s => s.products.length > 0);

    const element = React.createElement(MenuPdfDocument, {
      menuName: menuNameDE,
      menuNameEN,
      sections,
      config: analogConfig,
      tenantName: menu.location.tenant.name,
      locationName: menu.location.name,
    });
    const buffer = await renderToBuffer(element as any);
    const filename = `${menuNameDE.replace(/[^a-zA-Z0-9äöüÄÖÜß\-_ ]/g, '')}.pdf`;
    return new NextResponse(new Uint8Array(buffer), {
      headers: {
        'Content-Type': 'application/pdf',
        'Content-Disposition': `inline; filename="${sanitizeFilename(filename)}"; filename*=UTF-8''${encodeURIComponent(filename)}`,
        'Cache-Control': 'no-cache',
      },
    });
  } catch (error: any) {
    console.error('PDF generation error:', error);
    return NextResponse.json(
      { error: 'PDF generation failed', details: error.message },
      { status: 500 }
    );
  }
}
