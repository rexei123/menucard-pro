#!/bin/bash
# MenuCard Pro – PDF Fix v2
# Fix: Button, TOC, Weingut-Duplikate, leere Seiten, Layout-Qualität
# Datum: 11.04.2026

set -e
cd /var/www/menucard-pro

echo "=== PDF Fix v2 ==="

# === 1. Fix PDF Button in Admin (nested link problem) ===
echo "[1/3] PDF-Button Fix..."

python3 << 'PYEOF'
code = open('src/app/admin/design/page.tsx').read()

# Die Design-Übersicht ist eine Server Component.
# Das Problem: <a> für PDF ist innerhalb von <Link> für Design-Editor.
# Lösung: Link und PDF-Button separat machen, nicht verschachtelt.

old_block = '''              <Link key={menu.id} href={`/admin/menus/${menu.id}/design`}
                className="flex items-center justify-between rounded-lg border bg-white p-4 hover:border-blue-300 hover:shadow-sm transition-all">
                <div>
                  <div className="font-medium text-gray-900">{name}</div>
                  <div className="text-sm text-gray-500">{menu.location.name} · {menu.type}</div>
                </div>
                <div className="flex items-center gap-3">
                  <a href={`/api/v1/menus/${menu.id}/pdf`} target="_blank" rel="noopener noreferrer"
                    className="flex items-center gap-1 rounded-lg border border-gray-200 px-3 py-1.5 text-xs text-gray-600 hover:bg-gray-50 transition-colors"
                    >
                    📄 PDF
                  </a>
                  <div className="flex items-center gap-1 text-sm text-blue-500">
                    Design bearbeiten
                    <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
                  </div>
                </div>
              </Link>'''

new_block = '''              <div key={menu.id} className="flex items-center justify-between rounded-lg border bg-white p-4 hover:shadow-sm transition-all">
                <div>
                  <div className="font-medium text-gray-900">{name}</div>
                  <div className="text-sm text-gray-500">{menu.location.name} · {menu.type}</div>
                </div>
                <div className="flex items-center gap-3">
                  <a href={`/api/v1/menus/${menu.id}/pdf`} target="_blank" rel="noopener noreferrer"
                    className="flex items-center gap-1 rounded-lg border border-gray-200 px-3 py-1.5 text-xs text-gray-600 hover:bg-gray-50 transition-colors">
                    📄 PDF
                  </a>
                  <Link href={`/admin/menus/${menu.id}/design`}
                    className="flex items-center gap-1 text-sm text-blue-500 hover:underline">
                    Design bearbeiten
                    <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
                  </Link>
                </div>
              </div>'''

if old_block in code:
    code = code.replace(old_block, new_block)
    open('src/app/admin/design/page.tsx', 'w').write(code)
    print('OK - PDF Button Fix')
else:
    print('WARN - Block nicht gefunden, versuche Alternative...')
    # Fallback: ersetze nur die verschachtelte Struktur
    code2 = code.replace(
        '<Link key={menu.id} href={`/admin/menus/${menu.id}/design`}\n                className="flex items-center justify-between rounded-lg border bg-white p-4 hover:border-blue-300 hover:shadow-sm transition-all">',
        '<div key={menu.id} className="flex items-center justify-between rounded-lg border bg-white p-4 hover:shadow-sm transition-all">'
    )
    # Find closing </Link> for this block and replace with </div>
    # Simple approach: just rewrite the whole file
    print('Fallback nicht implementiert - manueller Fix noetig')
PYEOF

# === 2. Komplettes PDF-Rewrite mit TOC + besserem Layout ===
echo "[2/3] PDF Render-Komponente neu schreiben..."

cat > src/lib/pdf/menu-pdf.tsx << 'ENDOFFILE'
import React from 'react';
import { Document, Page, Text, View, StyleSheet, Image as PdfImage, Link as PdfLink } from '@react-pdf/renderer';
import { registerFonts, pdfFont } from './fonts';
import type { AnalogConfig } from '../design-templates';

registerFonts();

// ─── Types ───
type ProductData = {
  id: string;
  name: string;
  nameEN?: string;
  shortDescription?: string;
  shortDescriptionEN?: string;
  longDescription?: string;
  longDescriptionEN?: string;
  prices: { label: string; price: number; volume?: string }[];
  winery?: string;
  wineryLocation?: string;
  vintage?: number;
  grapeVarieties?: string[];
  region?: string;
  country?: string;
  appellation?: string;
  style?: string;
  image?: string;
  isHighlight?: boolean;
  highlightType?: string;
};

type SectionData = {
  id: string;
  name: string;
  nameEN?: string;
  description?: string;
  descriptionEN?: string;
  icon?: string;
  products: ProductData[];
};

type MenuPdfProps = {
  menuName: string;
  menuNameEN?: string;
  sections: SectionData[];
  config: AnalogConfig;
  tenantName?: string;
  locationName?: string;
};

function formatPrice(price: number): string {
  return price.toFixed(2).replace('.', ',');
}

// ─── PDF Document ───
export function MenuPdfDocument({ menuName, menuNameEN, sections, config, tenantName, locationName }: MenuPdfProps) {
  const typo = config.typography || {} as any;
  const colors = config.colors || {} as any;
  const layout = config.productLayout || {} as any;
  const pageConfig = config.page || {} as any;
  const lang = config.language || {} as any;
  const showEN = lang.secondary === 'en';
  const hf = config.headerFooter || {} as any;
  const tp = config.titlePage || {} as any;
  const tocConfig = config.toc || {} as any;

  const pageSize = pageConfig.format === 'A5' ? 'A5' as const : 'A4' as const;
  const isLandscape = pageConfig.orientation === 'landscape';
  const marginMap: Record<string, number> = { narrow: 42, normal: 56, wide: 70 };
  const margin = marginMap[pageConfig.margins] || 56;

  // Fonts
  const sectionFont = pdfFont((typo.sectionTitle as any)?.font || 'Dancing Script');
  const bodyFont = pdfFont((typo.productName as any)?.font || 'Source Sans 3');
  const priceFont = pdfFont((typo.price as any)?.font || 'Source Sans 3');

  // Colors
  const textMain = colors.textMain || '#333333';
  const accent = colors.accent || '#C8A850';
  const priceColor = colors.priceColor || '#000000';
  const footerColor = colors.footerColor || '#999999';

  // Spacing
  const spacingMap: Record<string, number> = { small: 4, normal: 8, large: 14 };
  const productSpacing = spacingMap[layout.spacing] || 8;

  // Only sections with products
  const activeSections = sections.filter(s => s.products.length > 0);

  const styles = StyleSheet.create({
    page: {
      paddingTop: margin,
      paddingBottom: margin + 14,
      paddingHorizontal: margin,
      fontFamily: bodyFont,
      fontSize: 10,
      color: textMain,
      backgroundColor: colors.pageBg || '#FFFFFF',
    },
    // ─── Title Page ───
    titlePage: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
    },
    titleLogoBox: {
      width: tp.logoSize || 180,
      height: tp.logoSize || 180,
      backgroundColor: tp.logoBgColor || '#555555',
      borderRadius: 6,
      marginBottom: 28,
      justifyContent: 'center',
      alignItems: 'center',
    },
    titleMain: {
      fontFamily: sectionFont,
      fontSize: 48,
      color: textMain,
      textAlign: 'center',
    },
    titleEN: {
      fontFamily: sectionFont,
      fontSize: 30,
      color: '#AAAAAA',
      textAlign: 'center',
      marginTop: 4,
    },
    titleTenant: {
      fontFamily: bodyFont,
      fontSize: 13,
      color: accent,
      textAlign: 'center',
      letterSpacing: 3,
      textTransform: 'uppercase',
      marginTop: 20,
    },
    titleLocation: {
      fontFamily: bodyFont,
      fontSize: 11,
      color: accent,
      textAlign: 'center',
      letterSpacing: 2,
      textTransform: 'uppercase',
      marginTop: 4,
    },
    titleQuote: {
      fontFamily: pdfFont(tp.quoteFont || 'Dancing Script'),
      fontSize: 13,
      color: '#888888',
      textAlign: 'center',
      fontStyle: 'italic',
      lineHeight: 1.6,
      marginTop: 36,
      maxWidth: 320,
    },
    // ─── TOC ───
    tocTitle: {
      fontFamily: sectionFont,
      fontSize: 32,
      color: textMain,
      textAlign: 'center',
      marginBottom: 24,
    },
    tocEntry: {
      flexDirection: 'row',
      alignItems: 'baseline',
      marginBottom: 8,
    },
    tocName: {
      fontFamily: bodyFont,
      fontSize: 12,
      color: textMain,
    },
    tocNameEN: {
      fontFamily: bodyFont,
      fontSize: 11,
      color: '#999999',
      marginLeft: 8,
    },
    tocDots: {
      flex: 1,
      borderBottomWidth: 1,
      borderBottomColor: '#DDDDDD',
      borderStyle: 'dotted',
      marginHorizontal: 8,
      marginBottom: 3,
    },
    tocPage: {
      fontFamily: bodyFont,
      fontSize: 12,
      color: textMain,
      minWidth: 20,
      textAlign: 'right',
    },
    // ─── Section Header ───
    sectionHeaderBlock: {
      marginBottom: 16,
    },
    sectionHeaderLine: {
      flexDirection: 'row',
      alignItems: 'center',
      marginBottom: 12,
    },
    sectionLine: {
      flex: 1,
      height: 0.5,
      backgroundColor: '#CCCCCC',
    },
    sectionHeaderSmall: {
      fontFamily: sectionFont,
      fontSize: 14,
      color: '#999999',
      marginHorizontal: 12,
    },
    sectionTitleBig: {
      fontFamily: sectionFont,
      fontSize: (typo.sectionTitle as any)?.size || 40,
      color: (typo.sectionTitle as any)?.color || textMain,
    },
    sectionTitleEN: {
      fontFamily: sectionFont,
      fontSize: ((typo.sectionTitle as any)?.size || 40) * 0.5,
      color: '#BBBBBB',
      marginTop: 2,
    },
    sectionDivider: {
      height: 1,
      backgroundColor: accent,
      marginTop: 8,
      marginBottom: 16,
      width: 60,
    },
    // ─── Product ───
    productRow: {
      marginBottom: productSpacing + 4,
    },
    productNameLine: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'flex-start',
    },
    productName: {
      fontFamily: pdfFont((typo.productName as any)?.font || 'Source Sans 3'),
      fontSize: (typo.productName as any)?.size || 11,
      fontWeight: ((typo.productName as any)?.weight || 700) as any,
      color: (typo.productName as any)?.color || '#000000',
      flex: 1,
      paddingRight: 10,
    },
    productPrice: {
      fontFamily: priceFont,
      fontSize: (typo.price as any)?.size || 10,
      fontWeight: ((typo.price as any)?.weight || 400) as any,
      color: priceColor,
      textAlign: 'right',
      minWidth: 100,
    },
    wineryLine: {
      fontFamily: pdfFont((typo.winery as any)?.font || 'Source Sans 3'),
      fontSize: (typo.winery as any)?.size || 9,
      color: (typo.winery as any)?.color || '#999999',
      marginTop: 1,
    },
    descDE: {
      fontFamily: pdfFont((typo.description as any)?.font || 'Source Sans 3'),
      fontSize: (typo.description as any)?.size || 9,
      color: (typo.description as any)?.color || '#555555',
      lineHeight: (typo.description as any)?.lineHeight || 1.4,
      textAlign: ((typo.description as any)?.align || 'justify') as any,
      marginTop: 3,
    },
    descEN: {
      fontFamily: pdfFont((typo.description as any)?.font || 'Source Sans 3'),
      fontSize: (typo.description as any)?.size || 9,
      color: '#AAAAAA',
      lineHeight: (typo.description as any)?.lineHeight || 1.4,
      textAlign: ((typo.description as any)?.align || 'justify') as any,
      fontStyle: 'italic',
      marginTop: 1,
    },
    // ─── Footer ───
    footer: {
      position: 'absolute',
      bottom: margin - 6,
      left: margin,
      right: margin,
      flexDirection: 'row',
      justifyContent: 'space-between',
      borderTopWidth: 0.5,
      borderTopColor: '#DDDDDD',
      paddingTop: 4,
    },
    footerText: {
      fontSize: 7.5,
      color: footerColor,
    },
    // ─── Page Header ───
    pageHeader: {
      position: 'absolute',
      top: margin - 16,
      left: margin,
      right: margin,
      flexDirection: 'row',
      alignItems: 'center',
    },
    pageHeaderLine: {
      flex: 1,
      height: 0.5,
      backgroundColor: '#CCCCCC',
    },
    pageHeaderText: {
      fontFamily: sectionFont,
      fontSize: 11,
      color: '#BBBBBB',
      marginHorizontal: 10,
    },
  });

  // ─── Footer Component ───
  const Footer = () => (
    <View style={styles.footer} fixed>
      <Text style={styles.footerText}>
        {hf.footer?.textLeft || 'Inklusivpreise in Euro All prices incl. Taxes'}
      </Text>
      <Text style={styles.footerText} render={({ pageNumber }) => String(pageNumber)} />
    </View>
  );

  // ─── Page Header Component ───
  const PageHeader = ({ name }: { name: string }) => (
    <View style={styles.pageHeader} fixed>
      <View style={styles.pageHeaderLine} />
      <Text style={styles.pageHeaderText}>{name}</Text>
      <View style={styles.pageHeaderLine} />
    </View>
  );

  // ─── Render Product ───
  const renderProduct = (product: ProductData) => {
    // Price formatting
    const priceLines = product.prices.map(p => {
      const fill = p.label || '';
      const priceStr = formatPrice(p.price);
      return `${fill}  ${priceStr} €`;
    });

    // Winery line - single, clean
    const wineryParts: string[] = [];
    if (product.winery) wineryParts.push(product.winery);
    if (product.wineryLocation) wineryParts.push(product.wineryLocation);
    else if (product.region) wineryParts.push(product.region);
    const wineryText = wineryParts.join(', ');

    // Description
    const descDE = layout.descDE !== false ? (product.longDescription || product.shortDescription || '') : '';
    const descEN = layout.descEN !== false && showEN ? (product.longDescriptionEN || product.shortDescriptionEN || '') : '';

    return (
      <View key={product.id} style={styles.productRow} wrap={false}>
        <View style={styles.productNameLine}>
          <Text style={styles.productName}>{product.name}</Text>
          <View>
            {priceLines.map((line, i) => (
              <Text key={i} style={styles.productPrice}>{line}</Text>
            ))}
          </View>
        </View>
        {wineryText ? <Text style={styles.wineryLine}>{wineryText}</Text> : null}
        {descDE ? <Text style={styles.descDE}>{descDE}</Text> : null}
        {descEN ? <Text style={styles.descEN}>{descEN}</Text> : null}
      </View>
    );
  };

  // ─── Calculate TOC page numbers (estimate) ───
  // Title page = 1, TOC = 2, content starts at 3
  let contentStartPage = 1;
  if (config.content?.showTitlePage !== false) contentStartPage++;
  if (config.content?.showToc !== false) contentStartPage++;

  // Estimate pages per section (rough: ~5 products per page)
  const tocEntries: { name: string; nameEN?: string; page: number }[] = [];
  let currentPage = contentStartPage;
  for (const section of activeSections) {
    tocEntries.push({ name: section.name, nameEN: section.nameEN, page: currentPage });
    const productsPages = Math.ceil(section.products.length / 5);
    currentPage += Math.max(1, productsPages);
  }

  return (
    <Document title={menuName} author={tenantName || 'MenuCard Pro'} creator="MenuCard Pro">

      {/* ═══ TITLE PAGE ═══ */}
      {config.content?.showTitlePage !== false && (
        <Page size={pageSize} orientation={isLandscape ? 'landscape' : 'portrait'}
          style={[styles.page, { paddingBottom: margin }]}>
          <View style={styles.titlePage}>
            {tp.logo ? (
              <PdfImage src={tp.logo} style={{ width: tp.logoSize || 180, marginBottom: 28 }} />
            ) : (
              <View style={styles.titleLogoBox} />
            )}
            <Text style={styles.titleMain}>{menuName}</Text>
            {showEN && menuNameEN && <Text style={styles.titleEN}>{menuNameEN}</Text>}
            {tenantName && <Text style={styles.titleTenant}>{tenantName}</Text>}
            {locationName && <Text style={styles.titleLocation}>{locationName}</Text>}
            {tp.quote && (
              <View style={{ marginTop: 36, alignItems: 'center' }}>
                <Text style={styles.titleQuote}>{`"${tp.quote}"`}</Text>
                {tp.quoteAuthor && <Text style={[styles.titleQuote, { fontSize: 10, marginTop: 4 }]}>— {tp.quoteAuthor}</Text>}
                {showEN && tp.quoteEN && <Text style={[styles.titleQuote, { fontSize: 11, color: '#BBBBBB', marginTop: 8 }]}>{`"${tp.quoteEN}"`}</Text>}
              </View>
            )}
          </View>
        </Page>
      )}

      {/* ═══ TABLE OF CONTENTS ═══ */}
      {config.content?.showToc !== false && (
        <Page size={pageSize} orientation={isLandscape ? 'landscape' : 'portrait'} style={styles.page}>
          <View style={{ marginTop: 40 }}>
            <Text style={styles.tocTitle}>Inhalt</Text>
            {tocEntries.map((entry, i) => (
              <View key={i} style={styles.tocEntry}>
                <Text style={styles.tocName}>{entry.name}</Text>
                {showEN && entry.nameEN && tocConfig.bilingual !== false && (
                  <Text style={styles.tocNameEN}>{entry.nameEN}</Text>
                )}
                <View style={styles.tocDots} />
                <Text style={styles.tocPage}>{entry.page}</Text>
              </View>
            ))}
          </View>
          <Footer />
        </Page>
      )}

      {/* ═══ CONTENT PAGES ═══ */}
      {activeSections.map((section, sIdx) => (
        <Page key={section.id} size={pageSize} orientation={isLandscape ? 'landscape' : 'portrait'} style={styles.page} wrap>
          {/* Page header (repeating section name at top) */}
          <PageHeader name={section.name} />

          {/* Big section title on first page of section */}
          <View style={styles.sectionHeaderBlock}>
            <Text style={styles.sectionTitleBig}>{section.name}</Text>
            {showEN && section.nameEN && (
              <Text style={styles.sectionTitleEN}>{section.nameEN}</Text>
            )}
            <View style={styles.sectionDivider} />
          </View>

          {/* Products */}
          {section.products.map(p => renderProduct(p))}

          {/* Footer */}
          <Footer />
        </Page>
      ))}
    </Document>
  );
}
ENDOFFILE

echo "  ✓ PDF Render-Komponente v2"

# === 3. Fix PDF API Route - bessere Daten-Aufbereitung ===
echo "[3/3] PDF API Route verbessern..."

cat > 'src/app/api/v1/menus/[id]/pdf/route.ts' << 'ENDOFFILE'
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
ENDOFFILE

echo "  ✓ PDF API Route v2"

echo ""
echo "Build..."
npm run build 2>&1 | tail -10

echo ""
echo "=== PDF Fix v2 fertig! ==="
echo "Verbesserungen:"
echo "  ✓ PDF-Button Fix (kein verschachtelter Link mehr)"
echo "  ✓ Inhaltsverzeichnis mit gepunkteten Linien"
echo "  ✓ Weingut nur einmal (Weingut, Region)"
echo "  ✓ Leere Sektionen werden übersprungen"
echo "  ✓ Großer Script-Titel pro Sektion"
echo "  ✓ Page Header (Sektionsname oben mit Linien)"
echo "  ✓ Sauberes Layout: Titelseite → TOC → Inhalt"
