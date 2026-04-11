import { NextRequest, NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { renderToBuffer } from '@react-pdf/renderer';
import { MenuPdfDocument } from '@/lib/pdf/menu-pdf';
import { getTemplate, mergeConfig } from '@/lib/design-templates';
import type { AnalogConfig } from '@/lib/design-templates';
import React from 'react';

// GET /api/v1/menus/[id]/pdf – PDF generieren
export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  try {
    const menu = await prisma.menu.findUnique({
      where: { id: params.id },
      include: {
        translations: true,
        location: {
          include: { tenant: true },
        },
        sections: {
          where: { isActive: true },
          orderBy: { sortOrder: 'asc' },
          include: {
            translations: true,
            placements: {
              where: { isVisible: true },
              orderBy: { sortOrder: 'asc' },
              include: {
                product: {
                  include: {
                    translations: true,
                    prices: {
                      include: { fillQuantity: true },
                      orderBy: { sortOrder: 'asc' },
                    },
                    productWineProfile: true,
                    productMedia: {
                      where: { isPrimary: true },
                      take: 1,
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

    // Resolve analog config
    const saved = menu.designConfig as any;
    const templateName = saved?.analog?.template || saved?.digital?.template || 'elegant';
    const template = getTemplate(templateName);
    const analogConfig: AnalogConfig = mergeConfig(template.analog, saved?.analog);

    const menuNameDE = menu.translations.find(t => t.languageCode === 'de')?.name || menu.slug;
    const menuNameEN = menu.translations.find(t => t.languageCode === 'en')?.name || undefined;

    // Transform sections
    const sections = menu.sections
      .map(section => {
        const sDE = section.translations.find(t => t.languageCode === 'de');
        const sEN = section.translations.find(t => t.languageCode === 'en');

        const products = section.placements
          .filter(pl => pl.product.status !== 'ARCHIVED')
          .map(pl => {
            const p = pl.product;
            const tDE = p.translations.find(t => t.languageCode === 'de');
            const tEN = p.translations.find(t => t.languageCode === 'en');
            const wp = p.productWineProfile;

            // Build clean product name: "Name Jahrgang Rebsorten Region Appellation"
            const nameParts: string[] = [tDE?.name || ''];
            if (wp?.grapeVarieties?.length) nameParts.push(wp.grapeVarieties.join(', '));
            if (wp?.appellation) nameParts.push(wp.appellation);

            // Prices
            const prices = p.prices.map(pp => ({
              label: pp.fillQuantity?.label || '',
              price: pl.priceOverride ? Number(pl.priceOverride) : Number(pp.price),
              volume: pp.fillQuantity?.volume || undefined,
            }));

            // Single winery line
            const wineryParts: string[] = [];
            if (wp?.winery) wineryParts.push(wp.winery);
            if (wp?.region) wineryParts.push(wp.region);

            return {
              id: p.id,
              name: nameParts.filter(Boolean).join('  '),
              nameEN: tEN?.name || undefined,
              shortDescription: tDE?.shortDescription || undefined,
              shortDescriptionEN: tEN?.shortDescription || undefined,
              longDescription: tDE?.longDescription || undefined,
              longDescriptionEN: tEN?.longDescription || undefined,
              prices,
              winery: wp?.winery || undefined,
              wineryLocation: wp?.region || undefined,
              vintage: wp?.vintage || undefined,
              grapeVarieties: wp?.grapeVarieties || undefined,
              region: wp?.region || undefined,
              country: wp?.country || undefined,
              appellation: wp?.appellation || undefined,
              style: wp?.style || undefined,
              isHighlight: p.isHighlight,
              highlightType: pl.highlightType || p.highlightType || undefined,
            };
          });

        return {
          id: section.id,
          name: sDE?.name || section.slug,
          nameEN: sEN?.name || undefined,
          description: sDE?.description || undefined,
          descriptionEN: sEN?.description || undefined,
          icon: section.icon || undefined,
          products,
        };
      })
      .filter(s => s.products.length > 0); // Skip empty sections

    // Render PDF
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
        'Content-Disposition': `inline; filename="${filename}"`,
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
