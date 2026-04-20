import { DesignConfig } from './index';

/**
 * MINIMAL — Der robuste "Never-Fail"-Fallback (Stand 20.04.2026)
 *
 * Dieses Template ist das einzige SYSTEM-Template und dient als sichere Basis:
 * - Wenn ein CUSTOM-Template Fehler hat, wird auf Minimal zurückgefallen
 * - Wenn ein Admin einen neuen Eintrag anlegt, ist Minimal der sichere Start
 * - Jede andere Darstellung wird als CUSTOM-Template aus Minimal abgeleitet
 *
 * Design-Prinzipien:
 *  • Maximale Lesbarkeit (Inter, genügend Kontrast, generöse Line-Height)
 *  • Keine optionalen Spielereien (keine Bilder, keine Uppercase, keine Italic-Body)
 *  • Professionelles Dunkelblau als einziger Akzent
 *  • Funktioniert für Speise-, Wein- und Barkarten ohne Nachjustierung
 */
export const minimalTemplate: DesignConfig = {
  digital: {
    template: 'minimal',
    mood: 'light',
    density: 'normal',
    typography: {
      h1: { font: 'Inter', size: 30, weight: 700, color: '#1A1A1A', transform: 'none', spacing: -0.01 },
      h2: { font: 'Inter', size: 17, weight: 600, color: '#1A1A1A', transform: 'none', spacing: 0 },
      h3: { font: 'Inter', size: 15, weight: 600, color: '#1A1A1A' },
      body: { font: 'Inter', size: 14, weight: 400, color: '#555555', style: 'normal', lineHeight: 1.5 },
      price: { font: 'Inter', size: 15, weight: 600, color: '#1A1A1A', format: '€ {price}' },
      meta: { font: 'Inter', size: 12, weight: 400, color: '#888888' },
    },
    colors: {
      pageBackground: '#FFFFFF',
      headerBackground: '#FFFFFF',
      headerText: '#1A1A1A',
      sectionHeaderBg: 'transparent',
      sectionLine: '#E5E5E5',
      sectionLineWidth: 1,
      sectionLineStyle: 'solid',
      productBg: 'transparent',
      productHover: '#FAFAFA',
      productDivider: '#EEEEEE',
      priceLine: 'none',
      priceLineColor: 'transparent',
      accentPrimary: '#1E3A5F',
      accentRecommend: '#C9A34A',
      accentNew: '#1E8E4E',
      accentPremium: '#8B2332',
    },
    icons: { style: 'outlined', sectionIcons: {} },
    badges: { show: ['recommendation', 'new', 'premium'], style: 'pill' },
    allergens: { position: 'product', style: 'numbers' },
    products: {
      showImages: false,
      imageStyle: 'color',
      imageShape: 'rounded',
      imageSize: 56,
      imagePosition: 'left',
      showShortDesc: true,
      showLongDesc: false,
      descMaxLines: 2,
      pricePosition: 'right',
      currency: '€',
      priceFormat: '€ {price}',
      showAllPrices: true,
      showFillQuantity: true,
      wineDetails: ['winery', 'vintage', 'grape', 'region'],
      wineDetailPosition: 'below',
      drinkDetails: ['alcohol'],
    },
    navigation: {
      showToc: true,
      tocPosition: 'sticky',
      tocStyle: 'list',
      stickyNav: true,
      smoothScroll: true,
      highlightActive: true,
      showBackToTop: true,
      hideEmptySections: true,
    },
    header: {
      logo: null,
      logoPosition: 'center',
      logoSize: 80,
      title: null,
      subtitle: null,
      backgroundImage: null,
      overlayOpacity: 0,
      height: 'normal',
    },
    footer: {
      show: true,
      text: 'Hotel Sonnblick · Kaprun',
      showAllergenNote: true,
      showPriceNote: true,
    },
  },
  analog: {
    template: 'minimal',
    hierarchy: [
      { level: 'KATEGORIE', newPage: false, showText: false, showHeader: true },
      { level: 'PRODUKT', newPage: false, showText: true, showHeader: false },
    ],
    content: {
      groups: ['all'],
      showTitlePage: true,
      showToc: true,
      showLegend: true,
      showQrPage: false,
      freePages: [],
      interPages: false,
    },
    language: { primary: 'de', secondary: 'en', secondaryScope: 'all', descriptionLang: 'both' },
    page: {
      format: 'A4',
      orientation: 'portrait',
      margins: 'normal',
      customMargins: null,
      bleed: false,
      pageNumbers: true,
      pageNumberStart: 1,
      countTitlePage: false,
    },
    titlePage: {
      logo: null,
      logoBgColor: '#FFFFFF',
      logoBgImage: null,
      logoPosition: 'center',
      logoSize: 120,
      quote: null,
      quoteEN: null,
      quoteAuthor: null,
      quoteFont: 'Inter',
      freeBlocks: [],
    },
    toc: { depth: 'category', lineStyle: 'dotted', bilingual: true, indented: false, position: 'afterTitle' },
    typography: {
      sectionTitle: { font: 'Inter', size: 20, weight: 700, color: '#1A1A1A' },
      subCategory: { font: 'Inter', size: 13, weight: 600, color: '#1A1A1A' },
      subGrouping: { font: 'Inter', size: 15, weight: 600, color: '#1A1A1A' },
      productName: { font: 'Inter', size: 11, weight: 600, color: '#000000' },
      winery: { font: 'Inter', size: 9, color: '#666666' },
      description: { font: 'Inter', size: 9, color: '#555555', align: 'left', lineHeight: 1.4 },
      price: { font: 'Inter', size: 11, weight: 700, color: '#000000' },
    },
    colors: { pageBg: '#FFFFFF', textMain: '#1A1A1A', accent: '#1E3A5F', priceColor: '#000000', footerColor: '#999999' },
    productLayout: {
      nameLineShow: [],
      wineryShow: ['winery', 'region'],
      descDE: true,
      descEN: true,
      descLayout: 'stacked',
      descAlign: 'left',
      descMaxChars: 0,
      priceFormat: '{price} €',
      multiplePrices: 'inline',
      spacing: 'normal',
      dividerLine: false,
    },
    images: { show: false, position: 'none', maxPerRow: 0, height: 0, style: 'color', typeFilter: [] },
    headerFooter: {
      header: { repeatSectionName: false, font: 'Inter', dividerLine: false },
      footer: { show: true, textLeft: 'Hotel Sonnblick · Kaprun', textCenter: '', textRight: '{pageNumber}', dividerLine: false },
    },
    pageBreaks: { newPagePerMainCategory: false, noOrphanProducts: true, minProductsAfterHeader: 2, keepImagesWithText: true },
  },
};
