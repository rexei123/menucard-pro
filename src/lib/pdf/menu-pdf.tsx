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
// Normalisiere fuer Dedup-Vergleich: Trim, Klein, Whitespace kollabieren
function norm(s: string | undefined | null): string {
  return (s || '').trim().toLowerCase().replace(/\s+/g, ' ');
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
    titleMain: {
      fontFamily: sectionFont,
      fontSize: 52,
      color: textMain,
      textAlign: 'center',
    },
    titleEN: {
      fontFamily: sectionFont,
      fontSize: 32,
      color: '#AAAAAA',
      textAlign: 'center',
      marginTop: 6,
    },
    titleDivider: {
      height: 0.8,
      backgroundColor: accent,
      width: 80,
      marginVertical: 24,
    },
    titleTenant: {
      fontFamily: bodyFont,
      fontSize: 13,
      color: accent,
      textAlign: 'center',
      letterSpacing: 3,
      textTransform: 'uppercase',
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
      marginBottom: 20,
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
    // Preise rechts: Container
    priceBlock: {
      minWidth: 120,
      alignItems: 'flex-end',
    },
    // Preiszeile: Label + Betrag zweispaltig
    priceLine: {
      flexDirection: 'row',
      justifyContent: 'flex-end',
      alignItems: 'baseline',
    },
    priceLabel: {
      fontFamily: priceFont,
      fontSize: ((typo.price as any)?.size || 10) - 1,
      color: '#888888',
      marginRight: 8,
    },
    priceValue: {
      fontFamily: priceFont,
      fontSize: (typo.price as any)?.size || 10,
      fontWeight: ((typo.price as any)?.weight || 400) as any,
      color: priceColor,
      minWidth: 52,
      textAlign: 'right',
    },
    wineryLine: {
      fontFamily: pdfFont((typo.winery as any)?.font || 'Source Sans 3'),
      fontSize: (typo.winery as any)?.size || 9,
      color: (typo.winery as any)?.color || '#999999',
      marginTop: 2,
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
      color: '#B5B5B5',
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
  // Legacy-Text aus alten Template-Configs automatisch mit Trennzeichen versehen
  const rawFooterLeft = hf.footer?.textLeft || 'Inklusivpreise in Euro · All prices incl. Taxes';
  const footerLeft = rawFooterLeft === 'Inklusivpreise in Euro All prices incl. Taxes'
    ? 'Inklusivpreise in Euro · All prices incl. Taxes'
    : rawFooterLeft;
  const Footer = () => (
    <View style={styles.footer} fixed>
      <Text style={styles.footerText}>{footerLeft}</Text>
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
    // Preise: Label + Betrag getrennt
    const priceItems = product.prices.map(p => ({
      label: p.label || '',
      value: formatPrice(p.price) + ' €',
    }));
    // Winery-Zeile
    const wineryParts: string[] = [];
    if (product.winery) wineryParts.push(product.winery);
    if (product.wineryLocation) wineryParts.push(product.wineryLocation);
    else if (product.region) wineryParts.push(product.region);
    const wineryText = wineryParts.join(', ');
    const wineryNorm = norm(wineryText);
    // Beschreibungen mit Dedup
    let descDE = layout.descDE !== false ? (product.longDescription || product.shortDescription || '') : '';
    let descEN = layout.descEN !== false && showEN ? (product.longDescriptionEN || product.shortDescriptionEN || '') : '';
    // Dedup: descDE unterdruecken, wenn identisch zu Winery-Zeile
    if (norm(descDE) && norm(descDE) === wineryNorm) descDE = '';
    // Dedup: descEN unterdruecken, wenn identisch zu descDE oder Winery-Zeile oder Produktname
    const descDENorm = norm(descDE);
    const nameNorm = norm(product.name);
    const descENnorm = norm(descEN);
    if (descENnorm && (descENnorm === descDENorm || descENnorm === wineryNorm || descENnorm === nameNorm)) {
      descEN = '';
    }
    // Produktname EN nur zeigen, wenn verschieden
    const nameEN = product.nameEN && norm(product.nameEN) !== nameNorm ? product.nameEN : '';
    return (
      <View key={product.id} style={styles.productRow} wrap={false}>
        <View style={styles.productNameLine}>
          <Text style={styles.productName}>{product.name}</Text>
          <View style={styles.priceBlock}>
            {priceItems.map((it, i) => (
              <View key={i} style={styles.priceLine}>
                {it.label ? <Text style={styles.priceLabel}>{it.label}</Text> : null}
                <Text style={styles.priceValue}>{it.value}</Text>
              </View>
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
  let contentStartPage = 1;
  if (config.content?.showTitlePage !== false) contentStartPage++;
  if (config.content?.showToc !== false) contentStartPage++;
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
              <PdfImage src={tp.logo as string} style={{ width: tp.logoSize || 180, marginBottom: 28 }} />
            ) : null}
            <Text style={styles.titleMain}>{menuName}</Text>
            {showEN && menuNameEN && norm(menuNameEN) !== norm(menuName) && (
              <Text style={styles.titleEN}>{menuNameEN}</Text>
            )}
            <View style={styles.titleDivider} />
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
                {showEN && entry.nameEN && tocConfig.bilingual !== false && norm(entry.nameEN) !== norm(entry.name) && (
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
            {showEN && section.nameEN && norm(section.nameEN) !== norm(section.name) && (
              <Text style={styles.sectionTitleEN}>{section.nameEN}</Text>
            )}
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
