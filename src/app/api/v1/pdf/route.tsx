import { NextRequest, NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import React from 'react';
import { renderToBuffer } from '@react-pdf/renderer';
import { Document, Page, Text, View, StyleSheet, Font } from '@react-pdf/renderer';

Font.register({
  family: 'PlayfairDisplay',
  fonts: [
    { src: 'https://cdn.jsdelivr.net/fontsource/fonts/playfair-display@latest/latin-400-normal.ttf', fontWeight: 400 },
    { src: 'https://cdn.jsdelivr.net/fontsource/fonts/playfair-display@latest/latin-700-normal.ttf', fontWeight: 700 },
  ],
});
Font.register({
  family: 'SourceSans',
  fonts: [
    { src: 'https://cdn.jsdelivr.net/fontsource/fonts/source-sans-3@latest/latin-400-normal.ttf', fontWeight: 400 },
    { src: 'https://cdn.jsdelivr.net/fontsource/fonts/source-sans-3@latest/latin-600-normal.ttf', fontWeight: 600 },
  ],
});

const s = StyleSheet.create({
  page: { paddingTop: 50, paddingBottom: 50, paddingHorizontal: 50, fontFamily: 'SourceSans', fontSize: 10, color: '#1a1a1a' },
  header: { textAlign: 'center', marginBottom: 30 },
  tenantName: { fontSize: 9, letterSpacing: 3, textTransform: 'uppercase', color: '#999', marginBottom: 6 },
  menuTitle: { fontSize: 26, fontFamily: 'PlayfairDisplay', fontWeight: 700 },
  menuDesc: { fontSize: 10, color: '#666', marginTop: 4 },
  divider: { width: 40, height: 1, backgroundColor: '#8B6914', marginVertical: 8, alignSelf: 'center', opacity: 0.4 },
  section: { marginBottom: 20 },
  sectionTitle: { fontSize: 16, fontFamily: 'PlayfairDisplay', fontWeight: 700, textAlign: 'center', marginBottom: 4 },
  sectionDesc: { fontSize: 9, color: '#888', textAlign: 'center', marginBottom: 8 },
  sectionDivider: { width: 30, height: 0.5, backgroundColor: '#8B6914', marginBottom: 12, alignSelf: 'center', opacity: 0.3 },
  item: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 8, paddingBottom: 6, borderBottomWidth: 0.5, borderBottomColor: '#eee' },
  itemLeft: { flex: 1, paddingRight: 10 },
  itemName: { fontSize: 11, fontFamily: 'PlayfairDisplay', fontWeight: 700 },
  itemDesc: { fontSize: 8.5, color: '#666', marginTop: 2 },
  itemWine: { fontSize: 8, color: '#999', marginTop: 2 },
  itemRight: { alignItems: 'flex-end', justifyContent: 'flex-start' },
  price: { fontSize: 11, fontWeight: 600 },
  priceLabel: { fontSize: 7.5, color: '#999' },
  multiPrice: { alignItems: 'flex-end', marginTop: 1 },
  badge: { fontSize: 7, color: '#8B6914', fontWeight: 600, marginLeft: 4 },
  soldOut: { fontSize: 7, color: '#cc0000' },
  footer: { position: 'absolute', bottom: 25, left: 50, right: 50, flexDirection: 'row', justifyContent: 'space-between' },
  footerText: { fontSize: 7, color: '#bbb' },
  pageNum: { fontSize: 7, color: '#bbb' },
});

const hlMap: Record<string, Record<string, string>> = {
  RECOMMENDATION: { de: 'Empfehlung', en: 'Recommended' },
  NEW: { de: 'Neu', en: 'New' },
  POPULAR: { de: 'Beliebt', en: 'Popular' },
  PREMIUM: { de: 'Premium', en: 'Premium' },
  SEASONAL: { de: 'Saison', en: 'Seasonal' },
  CHEFS_CHOICE: { de: "Chef's Choice", en: "Chef's Choice" },
};

function formatEur(price: number, lang: string): string {
  const locale = lang === 'en' ? 'en-GB' : 'de-AT';
  return new Intl.NumberFormat(locale, { style: 'currency', currency: 'EUR', minimumFractionDigits: 2 }).format(price);
}

function MenuPDF({ tenant, menu, lang }: { tenant: any; menu: any; lang: string }) {
  const t = (translations: any[], field: string = 'name') => {
    const found = translations.find((tr: any) => tr.languageCode === lang);
    const fb = translations.find((tr: any) => tr.languageCode === 'de');
    return (found?.[field] || fb?.[field]) ?? '';
  };

  return (
    <Document>
      <Page size="A4" style={s.page}>
        <View style={s.header}>
          <Text style={s.tenantName}>{tenant.name}</Text>
          <Text style={s.menuTitle}>{t(menu.translations)}</Text>
          {t(menu.translations, 'description') ? <Text style={s.menuDesc}>{t(menu.translations, 'description')}</Text> : null}
          <View style={s.divider} />
        </View>

        {menu.sections.map((section: any) => (
          <View key={section.id} style={s.section} wrap={false}>
            <Text style={s.sectionTitle}>{t(section.translations)}</Text>
            {t(section.translations, 'description') ? <Text style={s.sectionDesc}>{t(section.translations, 'description')}</Text> : null}
            <View style={s.sectionDivider} />

            {section.placements.map((placement: any) => {
              const product = placement.product;
              const name = t(product.translations);
              const desc = t(product.translations, 'shortDescription');
              const highlight = placement.highlightType || (product.isHighlight ? product.highlightType : null);
              const isSoldOut = !placement.isVisible;
              const wineProfile = product.productWineProfile;

              // Preise: priceOverride oder Produktpreise
              const prices = product.prices || [];
              const hasOverride = placement.priceOverride !== null;
              const multiPrice = !hasOverride && prices.length > 1;

              return (
                <View key={placement.id} style={s.item} wrap={false}>
                  <View style={s.itemLeft}>
                    <View style={{ flexDirection: 'row', alignItems: 'center' }}>
                      <Text style={s.itemName}>{name}</Text>
                      {highlight && (
                        <Text style={s.badge}>{hlMap[highlight]?.[lang] || ''}</Text>
                      )}
                      {isSoldOut && <Text style={s.soldOut}>{lang === 'en' ? ' (Sold out)' : ' (Ausverkauft)'}</Text>}
                    </View>
                    {desc ? <Text style={s.itemDesc}>{desc}</Text> : null}
                    {wineProfile && (
                      <Text style={s.itemWine}>
                        {[wineProfile.winery, wineProfile.vintage, wineProfile.region, wineProfile.country].filter(Boolean).join(' | ')}
                        {wineProfile.grapeVarieties?.length > 0 ? ` | ${wineProfile.grapeVarieties.join(', ')}` : ''}
                      </Text>
                    )}
                  </View>
                  <View style={s.itemRight}>
                    {hasOverride ? (
                      <Text style={s.price}>{formatEur(Number(placement.priceOverride), lang)}</Text>
                    ) : multiPrice ? (
                      prices.map((pp: any) => (
                        <View key={pp.id} style={s.multiPrice}>
                          <Text style={s.price}>{formatEur(Number(pp.price), lang)}</Text>
                          <Text style={s.priceLabel}>{pp.fillQuantity?.name || ''}</Text>
                        </View>
                      ))
                    ) : prices[0] ? (
                      <Text style={s.price}>{formatEur(Number(prices[0].price), lang)}</Text>
                    ) : null}
                  </View>
                </View>
              );
            })}
          </View>
        ))}

        <View style={s.footer} fixed>
          <Text style={s.footerText}>{lang === 'en' ? 'All prices in EUR incl. taxes' : 'Alle Preise in Euro inkl. MwSt.'}</Text>
          <Text style={s.pageNum} render={({ pageNumber, totalPages }) => `${pageNumber} / ${totalPages}`} />
        </View>
      </Page>
    </Document>
  );
}

export async function GET(req: NextRequest) {
  const menuSlug = req.nextUrl.searchParams.get('menu');
  const locationSlug = req.nextUrl.searchParams.get('location') || 'restaurant';
  const tenantSlug = req.nextUrl.searchParams.get('tenant') || 'hotel-sonnblick';
  const lang = req.nextUrl.searchParams.get('lang') === 'en' ? 'en' : 'de';

  if (!menuSlug) return NextResponse.json({ error: 'menu parameter required' }, { status: 400 });

  const tenant = await prisma.tenant.findUnique({ where: { slug: tenantSlug } });
  if (!tenant) return NextResponse.json({ error: 'Tenant not found' }, { status: 404 });

  const location = await prisma.location.findUnique({ where: { tenantId_slug: { tenantId: tenant.id, slug: locationSlug } } });
  if (!location) return NextResponse.json({ error: 'Location not found' }, { status: 404 });

  const menu = await prisma.menu.findUnique({
    where: { locationId_slug: { locationId: location.id, slug: menuSlug } },
    include: {
      translations: true,
      sections: {
        where: { isActive: true },
        orderBy: { sortOrder: 'asc' },
        include: {
          translations: true,
          placements: {
            orderBy: { sortOrder: 'asc' },
            include: {
              product: {
                include: {
                  translations: true,
                  prices: {
                    orderBy: { sortOrder: 'asc' },
                    include: { fillQuantity: true },
                  },
                  productWineProfile: true,
                },
              },
            },
          },
        },
      },
    },
  });

  if (!menu) return NextResponse.json({ error: 'Menu not found' }, { status: 404 });

  try {
    const buffer = await renderToBuffer(<MenuPDF tenant={tenant} menu={menu} lang={lang} />);
    const filename = `${menu.slug}-${lang}.pdf`;
    return new NextResponse(new Uint8Array(buffer), {
      headers: {
        'Content-Type': 'application/pdf',
        'Content-Disposition': `attachment; filename="${filename}"`,
        'Cache-Control': 'public, max-age=60',
      },
    });
  } catch (e: any) {
    console.error('PDF generation error:', e);
    return NextResponse.json({ error: 'PDF generation failed', details: e.message }, { status: 500 });
  }
}
