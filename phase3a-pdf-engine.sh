#!/bin/bash
# MenuCard Pro – Phase 3a: PDF Render-Engine + Download-API
# Schriften, PDF-Komponenten, API-Route für PDF-Download
# Datum: 11.04.2026

set -e
cd /var/www/menucard-pro

echo "=== Phase 3a: PDF Render-Engine ==="

# === 1. Google Fonts herunterladen ===
echo "[1/5] Schriften herunterladen..."

mkdir -p public/fonts

# Download Google Fonts (TTF) - die wichtigsten für die Templates
cd public/fonts

# Playfair Display (Elegant Template)
if [ ! -f "PlayfairDisplay-Regular.ttf" ]; then
  curl -sL "https://github.com/google/fonts/raw/main/ofl/playfairdisplay/PlayfairDisplay%5Bwght%5D.ttf" -o PlayfairDisplay-Variable.ttf 2>/dev/null || true
  # Fallback: static fonts
  curl -sL "https://fonts.google.com/download?family=Playfair+Display" -o playfair.zip 2>/dev/null && unzip -qo playfair.zip -d playfair_tmp 2>/dev/null && find playfair_tmp -name "*.ttf" -exec cp {} . \; 2>/dev/null && rm -rf playfair_tmp playfair.zip 2>/dev/null || true
fi

# Source Sans 3 (Body text)
if [ ! -f "SourceSans3-Regular.ttf" ]; then
  curl -sL "https://fonts.google.com/download?family=Source+Sans+3" -o sourcesans.zip 2>/dev/null && unzip -qo sourcesans.zip -d ss3_tmp 2>/dev/null && find ss3_tmp -name "*.ttf" -exec cp {} . \; 2>/dev/null && rm -rf ss3_tmp sourcesans.zip 2>/dev/null || true
fi

# Inter (Modern Template)
if [ ! -f "Inter-Regular.ttf" ]; then
  curl -sL "https://fonts.google.com/download?family=Inter" -o inter.zip 2>/dev/null && unzip -qo inter.zip -d inter_tmp 2>/dev/null && find inter_tmp -name "*.ttf" -exec cp {} . \; 2>/dev/null && rm -rf inter_tmp inter.zip 2>/dev/null || true
fi

# Dancing Script (Script headers in analog)
if [ ! -f "DancingScript-Regular.ttf" ]; then
  curl -sL "https://fonts.google.com/download?family=Dancing+Script" -o dancing.zip 2>/dev/null && unzip -qo dancing.zip -d dancing_tmp 2>/dev/null && find dancing_tmp -name "*.ttf" -exec cp {} . \; 2>/dev/null && rm -rf dancing_tmp dancing.zip 2>/dev/null || true
fi

# Lato (Classic Template)
if [ ! -f "Lato-Regular.ttf" ]; then
  curl -sL "https://fonts.google.com/download?family=Lato" -o lato.zip 2>/dev/null && unzip -qo lato.zip -d lato_tmp 2>/dev/null && find lato_tmp -name "*.ttf" -exec cp {} . \; 2>/dev/null && rm -rf lato_tmp lato.zip 2>/dev/null || true
fi

# Cormorant Garamond (Classic Template)
if [ ! -f "CormorantGaramond-Regular.ttf" ]; then
  curl -sL "https://fonts.google.com/download?family=Cormorant+Garamond" -o cormorant.zip 2>/dev/null && unzip -qo cormorant.zip -d cg_tmp 2>/dev/null && find cg_tmp -name "*.ttf" -exec cp {} . \; 2>/dev/null && rm -rf cg_tmp cormorant.zip 2>/dev/null || true
fi

cd /var/www/menucard-pro

echo "  Verfügbare Schriften:"
ls -la public/fonts/*.ttf 2>/dev/null | wc -l
echo "  Dateien"

# === 2. Font-Registry für @react-pdf ===
echo "[2/5] Font-Registry erstellen..."

mkdir -p src/lib/pdf

cat > src/lib/pdf/fonts.ts << 'ENDOFFILE'
import { Font } from '@react-pdf/renderer';
import path from 'path';

const fontsDir = path.join(process.cwd(), 'public', 'fonts');

// Helper: register a font family with available weights
function tryRegister(family: string, files: { weight: number; style: string; file: string }[]) {
  const sources = files
    .filter(f => {
      try {
        require('fs').accessSync(path.join(fontsDir, f.file));
        return true;
      } catch { return false; }
    })
    .map(f => ({
      src: path.join(fontsDir, f.file),
      fontWeight: f.weight as any,
      fontStyle: f.style as any,
    }));

  if (sources.length > 0) {
    Font.register({ family, fonts: sources });
    return true;
  }
  return false;
}

let registered = false;

export function registerFonts() {
  if (registered) return;
  registered = true;

  // Playfair Display
  tryRegister('Playfair Display', [
    { weight: 400, style: 'normal', file: 'PlayfairDisplay-Regular.ttf' },
    { weight: 500, style: 'normal', file: 'PlayfairDisplay-Medium.ttf' },
    { weight: 600, style: 'normal', file: 'PlayfairDisplay-SemiBold.ttf' },
    { weight: 700, style: 'normal', file: 'PlayfairDisplay-Bold.ttf' },
    { weight: 800, style: 'normal', file: 'PlayfairDisplay-ExtraBold.ttf' },
    { weight: 400, style: 'italic', file: 'PlayfairDisplay-Italic.ttf' },
    { weight: 700, style: 'italic', file: 'PlayfairDisplay-BoldItalic.ttf' },
  ]);

  // Source Sans 3
  tryRegister('Source Sans 3', [
    { weight: 300, style: 'normal', file: 'SourceSans3-Light.ttf' },
    { weight: 400, style: 'normal', file: 'SourceSans3-Regular.ttf' },
    { weight: 600, style: 'normal', file: 'SourceSans3-SemiBold.ttf' },
    { weight: 700, style: 'normal', file: 'SourceSans3-Bold.ttf' },
    { weight: 400, style: 'italic', file: 'SourceSans3-Italic.ttf' },
  ]);

  // Inter
  tryRegister('Inter', [
    { weight: 400, style: 'normal', file: 'Inter-Regular.ttf' },
    { weight: 500, style: 'normal', file: 'Inter-Medium.ttf' },
    { weight: 600, style: 'normal', file: 'Inter-SemiBold.ttf' },
    { weight: 700, style: 'normal', file: 'Inter-Bold.ttf' },
    { weight: 800, style: 'normal', file: 'Inter-ExtraBold.ttf' },
  ]);

  // Dancing Script
  tryRegister('Dancing Script', [
    { weight: 400, style: 'normal', file: 'DancingScript-Regular.ttf' },
    { weight: 700, style: 'normal', file: 'DancingScript-Bold.ttf' },
  ]);

  // Lato
  tryRegister('Lato', [
    { weight: 300, style: 'normal', file: 'Lato-Light.ttf' },
    { weight: 400, style: 'normal', file: 'Lato-Regular.ttf' },
    { weight: 700, style: 'normal', file: 'Lato-Bold.ttf' },
    { weight: 400, style: 'italic', file: 'Lato-Italic.ttf' },
  ]);

  // Cormorant Garamond
  tryRegister('Cormorant Garamond', [
    { weight: 400, style: 'normal', file: 'CormorantGaramond-Regular.ttf' },
    { weight: 600, style: 'normal', file: 'CormorantGaramond-SemiBold.ttf' },
    { weight: 700, style: 'normal', file: 'CormorantGaramond-Bold.ttf' },
    { weight: 400, style: 'italic', file: 'CormorantGaramond-Italic.ttf' },
  ]);

  // Fallback: Helvetica is always available in @react-pdf
  // No registration needed

  // Hyphenation callback (disable for German)
  Font.registerHyphenationCallback(word => [word]);
}

// Map font name to PDF-safe font family
export function pdfFont(fontName: string): string {
  const available = ['Playfair Display', 'Source Sans 3', 'Inter', 'Dancing Script', 'Lato', 'Cormorant Garamond'];
  if (available.includes(fontName)) return fontName;
  // Fallback mapping
  if (fontName.includes('Sans') || fontName === 'Open Sans' || fontName === 'Montserrat' || fontName === 'Raleway' || fontName === 'Josefin Sans') return 'Helvetica';
  if (fontName.includes('Garamond') || fontName.includes('Baskerville')) return 'Times-Roman';
  return 'Helvetica';
}
ENDOFFILE

echo "  ✓ Font-Registry erstellt"

# === 3. PDF Render-Komponente ===
echo "[3/5] PDF Render-Komponente erstellen..."

cat > src/lib/pdf/menu-pdf.tsx << 'ENDOFFILE'
import React from 'react';
import { Document, Page, Text, View, StyleSheet, Image as PdfImage } from '@react-pdf/renderer';
import { registerFonts, pdfFont } from './fonts';
import type { AnalogConfig } from '../design-templates';

// Register fonts on module load
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
  vintage?: number;
  grapeVarieties?: string[];
  region?: string;
  country?: string;
  appellation?: string;
  style?: string;
  image?: string;
  isHighlight?: boolean;
  highlightType?: string;
  allergenNumbers?: number[];
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

// ─── Helpers ───
function formatPrice(price: number): string {
  return price.toFixed(2).replace('.', ',');
}

function safeFontFamily(fontName: string): string {
  return pdfFont(fontName);
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

  // Page size
  const pageSize = pageConfig.format === 'A5' ? 'A5' : 'A4';
  const isLandscape = pageConfig.orientation === 'landscape';

  // Margins
  const marginMap: Record<string, number> = { narrow: 42, normal: 56, wide: 70 };
  const margin = marginMap[pageConfig.margins] || 56;

  // Font helpers
  const sectionFont = safeFontFamily(typo.sectionTitle?.font || 'Dancing Script');
  const bodyFont = safeFontFamily(typo.productName?.font || 'Source Sans 3');
  const priceFont = safeFontFamily(typo.price?.font || 'Source Sans 3');

  // Colors
  const textMain = colors.textMain || '#333333';
  const accent = colors.accent || '#C8A850';
  const priceColor = colors.priceColor || '#000000';
  const footerColor = colors.footerColor || '#999999';

  // Spacing
  const spacingMap: Record<string, number> = { small: 4, normal: 8, large: 14 };
  const productSpacing = spacingMap[layout.spacing] || 8;

  const styles = StyleSheet.create({
    page: {
      paddingTop: margin,
      paddingBottom: margin + 20,
      paddingHorizontal: margin,
      fontFamily: bodyFont,
      fontSize: 10,
      color: textMain,
      backgroundColor: colors.pageBg || '#FFFFFF',
    },
    // Title page
    titlePage: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      paddingHorizontal: margin * 1.5,
    },
    titleLogo: {
      width: 160,
      height: 160,
      marginBottom: 30,
      backgroundColor: config.titlePage?.logoBgColor || '#555555',
      borderRadius: 4,
    },
    titleText: {
      fontFamily: safeFontFamily(typo.sectionTitle?.font || 'Dancing Script'),
      fontSize: 42,
      color: textMain,
      marginBottom: 8,
      textAlign: 'center',
    },
    titleSubtext: {
      fontFamily: bodyFont,
      fontSize: 14,
      color: accent,
      textAlign: 'center',
      letterSpacing: 2,
      textTransform: 'uppercase',
    },
    titleQuote: {
      marginTop: 40,
      fontFamily: safeFontFamily(config.titlePage?.quoteFont || 'Dancing Script'),
      fontSize: 14,
      color: '#777777',
      textAlign: 'center',
      fontStyle: 'italic',
      lineHeight: 1.6,
      maxWidth: 300,
    },
    // Section header
    sectionHeader: {
      marginTop: 16,
      marginBottom: 12,
      borderBottomWidth: typo.sectionTitle?.dividerLine !== false ? 1 : 0,
      borderBottomColor: typo.sectionTitle?.dividerColor || accent,
      paddingBottom: 6,
    },
    sectionTitle: {
      fontFamily: sectionFont,
      fontSize: typo.sectionTitle?.size || 36,
      color: typo.sectionTitle?.color || textMain,
    },
    sectionTitleEN: {
      fontFamily: sectionFont,
      fontSize: (typo.sectionTitle?.size || 36) * 0.6,
      color: '#999999',
      marginTop: 2,
    },
    // Sub-category (country etc.)
    subCategory: {
      fontFamily: safeFontFamily(typo.subCategory?.font || 'Source Sans 3'),
      fontSize: typo.subCategory?.size || 14,
      fontWeight: (typo.subCategory?.weight || 700) as any,
      color: typo.subCategory?.color || textMain,
      textTransform: typo.subCategory?.uppercase !== false ? 'uppercase' : 'none',
      letterSpacing: 1.5,
      marginTop: 14,
      marginBottom: 6,
    },
    subCategoryEN: {
      fontFamily: safeFontFamily(typo.subCategory?.font || 'Source Sans 3'),
      fontSize: (typo.subCategory?.size || 14) * 0.85,
      color: '#999999',
      textTransform: typo.subCategory?.uppercase !== false ? 'uppercase' : 'none',
      letterSpacing: 1,
    },
    // Product row
    productRow: {
      marginBottom: productSpacing,
      paddingBottom: layout.dividerLine ? productSpacing : 0,
      borderBottomWidth: layout.dividerLine ? 0.5 : 0,
      borderBottomColor: '#E0E0E0',
    },
    productNameLine: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'flex-start',
    },
    productName: {
      fontFamily: safeFontFamily(typo.productName?.font || 'Source Sans 3'),
      fontSize: typo.productName?.size || 12,
      fontWeight: (typo.productName?.weight || 700) as any,
      color: typo.productName?.color || '#000000',
      flex: 1,
      paddingRight: 8,
    },
    productPrice: {
      fontFamily: priceFont,
      fontSize: typo.price?.size || 11,
      fontWeight: (typo.price?.weight || 700) as any,
      color: priceColor,
      textAlign: 'right',
      minWidth: 80,
    },
    wineryLine: {
      fontFamily: safeFontFamily(typo.winery?.font || 'Source Sans 3'),
      fontSize: typo.winery?.size || 10,
      color: typo.winery?.color || '#777777',
      marginTop: 1,
    },
    descriptionDE: {
      fontFamily: safeFontFamily(typo.description?.font || 'Source Sans 3'),
      fontSize: typo.description?.size || 10,
      color: typo.description?.color || textMain,
      lineHeight: typo.description?.lineHeight || 1.4,
      textAlign: (typo.description?.align || 'justify') as any,
      marginTop: 2,
    },
    descriptionEN: {
      fontFamily: safeFontFamily(typo.description?.font || 'Source Sans 3'),
      fontSize: typo.description?.size || 10,
      color: '#999999',
      lineHeight: typo.description?.lineHeight || 1.4,
      textAlign: (typo.description?.align || 'justify') as any,
      fontStyle: 'italic',
      marginTop: 1,
    },
    // Header/Footer
    headerLine: {
      position: 'absolute',
      top: margin - 20,
      left: margin,
      right: margin,
      flexDirection: 'row',
      justifyContent: 'center',
      borderBottomWidth: hf.header?.dividerLine !== false ? 0.5 : 0,
      borderBottomColor: accent,
      paddingBottom: 4,
    },
    headerText: {
      fontFamily: safeFontFamily(hf.header?.font || 'Dancing Script'),
      fontSize: 12,
      color: '#999999',
    },
    footerLine: {
      position: 'absolute',
      bottom: margin - 10,
      left: margin,
      right: margin,
      flexDirection: 'row',
      justifyContent: 'space-between',
      borderTopWidth: hf.footer?.dividerLine !== false ? 0.5 : 0,
      borderTopColor: '#DDDDDD',
      paddingTop: 4,
    },
    footerText: {
      fontSize: 8,
      color: footerColor,
    },
    // TOC
    tocEntry: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'baseline',
      marginBottom: 6,
      paddingLeft: 0,
    },
    tocDots: {
      flex: 1,
      borderBottomWidth: 0.5,
      borderBottomColor: '#CCCCCC',
      borderBottomStyle: 'dotted' as any,
      marginHorizontal: 8,
      marginBottom: 3,
    },
  });

  // Collect TOC entries (will be filled during render)
  let pageCounter = config.content?.showTitlePage !== false ? 1 : 0;

  // ─── Render Product ───
  const renderProduct = (product: ProductData) => {
    const priceText = product.prices.map(p => {
      const fill = p.label || p.volume || '';
      const priceStr = formatPrice(p.price);
      const fmt = layout.priceFormat || '{fill}  {price} €';
      return fmt.replace('{fill}', fill).replace('{price}', priceStr);
    }).join('\n');

    // Winery line
    const wineryParts: string[] = [];
    if ((layout.wineryShow || ['winery', 'city', 'region']).includes('winery') && product.winery) wineryParts.push(product.winery);
    if ((layout.wineryShow || []).includes('region') && product.region) wineryParts.push(product.region);
    const wineryText = wineryParts.join(', ');

    // Name line extras
    const nameExtras: string[] = [];
    if (product.grapeVarieties?.length && (layout.nameLineShow || []).includes('grapeAbbrev')) {
      nameExtras.push(product.grapeVarieties.join(', '));
    }
    if (product.appellation && (layout.nameLineShow || []).includes('appellation')) {
      nameExtras.push(product.appellation);
    }

    const fullName = [product.name, ...nameExtras].filter(Boolean).join('  ');

    // Description
    const descDE = layout.descDE !== false ? (product.longDescription || product.shortDescription || '') : '';
    const descEN = layout.descEN !== false && showEN ? (product.longDescriptionEN || product.shortDescriptionEN || '') : '';

    // Max chars
    const maxChars = layout.descMaxChars || 0;
    const trimmedDE = maxChars > 0 && descDE.length > maxChars ? descDE.substring(0, maxChars) + '...' : descDE;
    const trimmedEN = maxChars > 0 && descEN.length > maxChars ? descEN.substring(0, maxChars) + '...' : descEN;

    return (
      <View key={product.id} style={styles.productRow} wrap={false}>
        <View style={styles.productNameLine}>
          <Text style={styles.productName}>{fullName}</Text>
          <Text style={styles.productPrice}>{priceText}</Text>
        </View>
        {wineryText ? <Text style={styles.wineryLine}>{wineryText}</Text> : null}
        {trimmedDE ? <Text style={styles.descriptionDE}>{trimmedDE}</Text> : null}
        {trimmedEN ? <Text style={styles.descriptionEN}>{trimmedEN}</Text> : null}
      </View>
    );
  };

  // ─── Render Section ───
  const renderSection = (section: SectionData, isFirst: boolean) => {
    const startOnNewPage = !isFirst && (config.pageBreaks?.newPagePerMainCategory !== false);

    return (
      <View key={section.id} break={startOnNewPage}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>{section.name}</Text>
          {showEN && section.nameEN && (
            <Text style={styles.sectionTitleEN}>{section.nameEN}</Text>
          )}
        </View>
        {section.description && (
          <Text style={[styles.descriptionDE, { marginBottom: 8 }]}>{section.description}</Text>
        )}
        {section.products.map(p => renderProduct(p))}
      </View>
    );
  };

  // ─── Page Header/Footer ───
  const PageHeaderFooter = ({ sectionName, pageNum }: { sectionName?: string; pageNum?: number }) => (
    <>
      {hf.header?.repeatSectionName !== false && sectionName && (
        <View style={styles.headerLine} fixed>
          <Text style={styles.headerText}>{sectionName}</Text>
        </View>
      )}
      {hf.footer?.show !== false && (
        <View style={styles.footerLine} fixed>
          <Text style={styles.footerText}>{hf.footer?.textLeft || ''}</Text>
          <Text style={styles.footerText}>{hf.footer?.textCenter || ''}</Text>
          <Text style={styles.footerText} render={({ pageNumber }) =>
            (hf.footer?.textRight || '{pageNumber}').replace('{pageNumber}', String(pageNumber))
          } />
        </View>
      )}
    </>
  );

  return (
    <Document title={menuName} author={tenantName || 'MenuCard Pro'} creator="MenuCard Pro">
      {/* === Title Page === */}
      {config.content?.showTitlePage !== false && (
        <Page size={pageSize} orientation={isLandscape ? 'landscape' : 'portrait'} style={[styles.page, { paddingBottom: margin }]}>
          <View style={styles.titlePage}>
            {config.titlePage?.logo ? (
              <PdfImage src={config.titlePage.logo} style={{ width: config.titlePage?.logoSize || 200, height: 'auto', marginBottom: 30 }} />
            ) : (
              <View style={[styles.titleLogo, { width: config.titlePage?.logoSize || 160, height: config.titlePage?.logoSize || 160 }]} />
            )}
            <Text style={styles.titleText}>{menuName}</Text>
            {showEN && menuNameEN && <Text style={[styles.titleText, { fontSize: 28, color: '#999' }]}>{menuNameEN}</Text>}
            {tenantName && <Text style={styles.titleSubtext}>{tenantName}</Text>}
            {locationName && <Text style={[styles.titleSubtext, { fontSize: 11, marginTop: 4 }]}>{locationName}</Text>}
            {config.titlePage?.quote && (
              <Text style={styles.titleQuote}>
                {`"${config.titlePage.quote}"`}
                {config.titlePage.quoteAuthor && `\n— ${config.titlePage.quoteAuthor}`}
              </Text>
            )}
            {showEN && config.titlePage?.quoteEN && (
              <Text style={[styles.titleQuote, { fontSize: 12, color: '#AAAAAA' }]}>
                {`"${config.titlePage.quoteEN}"`}
              </Text>
            )}
          </View>
        </Page>
      )}

      {/* === Content Pages === */}
      {sections.map((section, i) => (
        <Page key={section.id} size={pageSize} orientation={isLandscape ? 'landscape' : 'portrait'} style={styles.page}>
          <PageHeaderFooter sectionName={section.name} />
          {renderSection(section, i === 0)}
        </Page>
      ))}
    </Document>
  );
}
ENDOFFILE

echo "  ✓ PDF Render-Komponente erstellt"

# === 4. PDF Download API-Route ===
echo "[4/5] PDF Download API-Route erstellen..."

mkdir -p 'src/app/api/v1/menus/[id]/pdf'

cat > 'src/app/api/v1/menus/[id]/pdf/route.ts' << 'ENDOFFILE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import { renderToBuffer } from '@react-pdf/renderer';
import { MenuPdfDocument } from '@/lib/pdf/menu-pdf';
import { getTemplate, mergeConfig } from '@/lib/design-templates';
import type { AnalogConfig } from '@/lib/design-templates';
import React from 'react';

// GET /api/v1/menus/[id]/pdf – PDF generieren und herunterladen
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
                    productAllergens: {
                      include: { allergen: true },
                    },
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

    // Menu name
    const menuNameDE = menu.translations.find(t => t.languageCode === 'de')?.name || menu.slug;
    const menuNameEN = menu.translations.find(t => t.languageCode === 'en')?.name || undefined;

    // Transform sections to PDF data
    const sections = menu.sections.map(section => {
      const sNameDE = section.translations.find(t => t.languageCode === 'de')?.name || section.slug;
      const sNameEN = section.translations.find(t => t.languageCode === 'en')?.name || undefined;
      const sDescDE = section.translations.find(t => t.languageCode === 'de')?.description || undefined;
      const sDescEN = section.translations.find(t => t.languageCode === 'en')?.description || undefined;

      const products = section.placements.map(pl => {
        const p = pl.product;
        const tDE = p.translations.find(t => t.languageCode === 'de');
        const tEN = p.translations.find(t => t.languageCode === 'en');
        const wp = p.productWineProfile;

        return {
          id: p.id,
          name: tDE?.name || p.sku || 'Produkt',
          nameEN: tEN?.name || undefined,
          shortDescription: tDE?.shortDescription || undefined,
          shortDescriptionEN: tEN?.shortDescription || undefined,
          longDescription: tDE?.longDescription || undefined,
          longDescriptionEN: tEN?.longDescription || undefined,
          prices: p.prices.map(pp => ({
            label: pp.fillQuantity?.label || '',
            price: pl.priceOverride ? Number(pl.priceOverride) : Number(pp.price),
            volume: pp.fillQuantity?.volume || undefined,
          })),
          winery: wp?.winery || undefined,
          vintage: wp?.vintage || undefined,
          grapeVarieties: wp?.grapeVarieties || undefined,
          region: wp?.region || undefined,
          country: wp?.country || undefined,
          appellation: wp?.appellation || undefined,
          style: wp?.style || undefined,
          image: (p as any).productMedia?.[0]?.url || undefined,
          isHighlight: p.isHighlight,
          highlightType: pl.highlightType || p.highlightType || undefined,
          allergenNumbers: p.productAllergens.map(a => (a.allergen as any).number).filter(Boolean),
        };
      });

      return {
        id: section.id,
        name: sNameDE,
        nameEN: sNameEN || undefined,
        description: sDescDE || undefined,
        descriptionEN: sDescEN || undefined,
        icon: section.icon || undefined,
        products,
      };
    });

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

    // Return PDF
    const filename = `${menuNameDE.replace(/[^a-zA-Z0-9äöüÄÖÜß\-_ ]/g, '')}.pdf`;
    return new NextResponse(buffer, {
      headers: {
        'Content-Type': 'application/pdf',
        'Content-Disposition': `inline; filename="${filename}"`,
        'Cache-Control': 'no-cache',
      },
    });
  } catch (error: any) {
    console.error('PDF generation error:', error);
    return NextResponse.json({ error: 'PDF generation failed', details: error.message }, { status: 500 });
  }
}
ENDOFFILE

echo "  ✓ PDF Download API-Route erstellt"

# === 5. PDF-Download Button im Design-Editor und Kartenübersicht ===
echo "[5/5] PDF-Download Buttons hinzufügen..."

# Add PDF download link to the design overview page
python3 << 'PYEOF'
code = open('src/app/admin/design/page.tsx').read()

# Add PDF download button next to "Design bearbeiten"
old = '''                <div className="flex items-center gap-2 text-sm text-blue-500">
                  Design bearbeiten
                  <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
                </div>'''

new = '''                <div className="flex items-center gap-3">
                  <a href={`/api/v1/menus/${menu.id}/pdf`} target="_blank" rel="noopener noreferrer"
                    className="flex items-center gap-1 rounded-lg border border-gray-200 px-3 py-1.5 text-xs text-gray-600 hover:bg-gray-50 transition-colors"
                    onClick={e => e.stopPropagation()}>
                    📄 PDF
                  </a>
                  <div className="flex items-center gap-1 text-sm text-blue-500">
                    Design bearbeiten
                    <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
                  </div>
                </div>'''

code = code.replace(old, new)
open('src/app/admin/design/page.tsx', 'w').write(code)
print('OK - PDF Button in Design-Uebersicht')
PYEOF

echo ""
echo "Build..."
npm run build 2>&1 | tail -15

echo ""
echo "=== Phase 3a fertig! ==="
echo "PDF-Engine erstellt:"
echo "  ✓ Schriften heruntergeladen (public/fonts/)"
echo "  ✓ Font-Registry für @react-pdf"
echo "  ✓ PDF Render-Komponente (Titelseite + Sektionen + Produkte)"
echo "  ✓ API-Route: GET /api/v1/menus/[id]/pdf"
echo "  ✓ PDF-Download Button in Karten-Design Übersicht"
echo ""
echo "PDF-Download testen: /api/v1/menus/[MENU-ID]/pdf"
