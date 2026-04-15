#!/bin/bash
# MenuCard Pro – Phase 1: Design-System Grundgerüst
# designConfig JSON-Feld + 4 Template-Defaults + API
# Datum: 11.04.2026

set -e
cd /var/www/menucard-pro

echo "=== Phase 1: Design-System Grundgerüst ==="

# === 1. Prisma Schema: designConfig Feld auf Menu ===
echo "[1/5] Prisma Schema erweitern..."

python3 -c "
code = open('prisma/schema.prisma').read()
# Füge designConfig vor dem ersten @@ in Menu ein
old = '  qrCodes      QRCode[]'
new = '''  qrCodes      QRCode[]
  designConfig Json?'''
if 'designConfig' not in code:
    code = code.replace(old, new)
    open('prisma/schema.prisma', 'w').write(code)
    print('designConfig Feld hinzugefuegt')
else:
    print('designConfig existiert bereits')
"

npx prisma db push 2>&1 | tail -5

# === 2. Template-Defaults als JSON ===
echo "[2/5] Template-Defaults erstellen..."

mkdir -p src/lib/design-templates

cat > src/lib/design-templates/index.ts << 'ENDOFFILE'
export type DesignConfig = {
  digital: DigitalConfig;
  analog: AnalogConfig;
};

export type TypographyLevel = {
  font: string;
  size: number;
  weight?: number;
  color: string;
  transform?: string;
  spacing?: number;
  style?: string;
  align?: string;
  lineHeight?: number;
};

export type DigitalConfig = {
  template: 'elegant' | 'modern' | 'classic' | 'minimal';
  mood: 'light' | 'warm' | 'dark';
  density: 'airy' | 'normal' | 'compact';
  typography: {
    h1: TypographyLevel;
    h2: TypographyLevel;
    h3: TypographyLevel;
    body: TypographyLevel;
    price: TypographyLevel & { format: string };
    meta: TypographyLevel;
  };
  colors: {
    pageBackground: string;
    headerBackground: string;
    headerText: string;
    sectionHeaderBg: string;
    sectionLine: string;
    sectionLineWidth: number;
    sectionLineStyle: string;
    productBg: string;
    productHover: string;
    productDivider: string;
    priceLine: string;
    priceLineColor: string;
    accentPrimary: string;
    accentRecommend: string;
    accentNew: string;
    accentPremium: string;
  };
  icons: { style: string; sectionIcons: Record<string, string> };
  badges: { show: string[]; style: string };
  allergens: { position: string; style: string };
  products: {
    showImages: boolean;
    imageStyle: string;
    imageShape: string;
    imageSize: number;
    imagePosition: string;
    showShortDesc: boolean;
    showLongDesc: boolean;
    descMaxLines: number;
    pricePosition: string;
    currency: string;
    priceFormat: string;
    showAllPrices: boolean;
    showFillQuantity: boolean;
    wineDetails: string[];
    wineDetailPosition: string;
    drinkDetails: string[];
  };
  navigation: {
    showToc: boolean;
    tocPosition: string;
    tocStyle: string;
    stickyNav: boolean;
    smoothScroll: boolean;
    highlightActive: boolean;
    showBackToTop: boolean;
    hideEmptySections: boolean;
  };
  header: {
    logo: string | null;
    logoPosition: string;
    logoSize: number;
    title: string | null;
    subtitle: string | null;
    backgroundImage: string | null;
    overlayOpacity: number;
    height: string;
  };
  footer: {
    show: boolean;
    text: string;
    showAllergenNote: boolean;
    showPriceNote: boolean;
  };
};

export type HierarchyLevel = {
  level: string;
  newPage: boolean;
  showText: boolean;
  showHeader: boolean;
};

export type AnalogConfig = {
  template: string;
  hierarchy: HierarchyLevel[];
  content: {
    groups: string[];
    showTitlePage: boolean;
    showToc: boolean;
    showLegend: boolean;
    showQrPage: boolean;
    freePages: any[];
    interPages: boolean;
  };
  language: {
    primary: string;
    secondary: string;
    secondaryScope: string;
    descriptionLang: string;
  };
  page: {
    format: string;
    orientation: string;
    margins: string;
    customMargins: any;
    bleed: boolean;
    pageNumbers: boolean;
    pageNumberStart: number;
    countTitlePage: boolean;
  };
  titlePage: {
    logo: string | null;
    logoBgColor: string;
    logoBgImage: string | null;
    logoPosition: string;
    logoSize: number;
    quote: string | null;
    quoteEN: string | null;
    quoteAuthor: string | null;
    quoteFont: string;
    freeBlocks: any[];
  };
  toc: {
    depth: string;
    lineStyle: string;
    bilingual: boolean;
    indented: boolean;
    position: string;
  };
  typography: Record<string, TypographyLevel>;
  colors: Record<string, string>;
  productLayout: Record<string, any>;
  images: Record<string, any>;
  headerFooter: Record<string, any>;
  pageBreaks: Record<string, boolean | number>;
};

// Helper: deep merge two objects (template defaults + user overrides)
export function mergeConfig<T extends Record<string, any>>(defaults: T, overrides: Partial<T> | null | undefined): T {
  if (!overrides) return defaults;
  const result = { ...defaults };
  for (const key of Object.keys(overrides) as Array<keyof T>) {
    const val = overrides[key];
    if (val !== null && typeof val === 'object' && !Array.isArray(val) && typeof defaults[key] === 'object' && !Array.isArray(defaults[key])) {
      result[key] = mergeConfig(defaults[key] as any, val as any);
    } else if (val !== undefined) {
      result[key] = val as any;
    }
  }
  return result;
}

export { elegantTemplate } from './elegant';
export { modernTemplate } from './modern';
export { classicTemplate } from './classic';
export { minimalTemplate } from './minimal';

export function getTemplate(name: string): DesignConfig {
  switch (name) {
    case 'modern': return require('./modern').modernTemplate;
    case 'classic': return require('./classic').classicTemplate;
    case 'minimal': return require('./minimal').minimalTemplate;
    default: return require('./elegant').elegantTemplate;
  }
}
ENDOFFILE

# --- Elegant Template ---
cat > src/lib/design-templates/elegant.ts << 'ENDOFFILE'
import { DesignConfig } from './index';

export const elegantTemplate: DesignConfig = {
  digital: {
    template: 'elegant',
    mood: 'warm',
    density: 'normal',
    typography: {
      h1: { font: 'Playfair Display', size: 32, weight: 700, color: '#2C1810', transform: 'none', spacing: 0.02 },
      h2: { font: 'Playfair Display', size: 22, weight: 600, color: '#8B6914', transform: 'uppercase', spacing: 0.05 },
      h3: { font: 'Source Sans 3', size: 16, weight: 600, color: '#333333' },
      body: { font: 'Source Sans 3', size: 14, weight: 400, color: '#777777', style: 'italic' },
      price: { font: 'Source Sans 3', size: 16, weight: 700, color: '#6B4C1E', format: '€ {price}' },
      meta: { font: 'Source Sans 3', size: 11, color: '#AAAAAA' },
    },
    colors: {
      pageBackground: '#FFF8F0',
      headerBackground: '#8B6914',
      headerText: '#FFFFFF',
      sectionHeaderBg: 'transparent',
      sectionLine: '#D4A853',
      sectionLineWidth: 1,
      sectionLineStyle: 'solid',
      productBg: 'transparent',
      productHover: '#FFF5E6',
      productDivider: '#F0E6D4',
      priceLine: 'dotted',
      priceLineColor: '#D4C4A8',
      accentPrimary: '#8B6914',
      accentRecommend: '#D4A853',
      accentNew: '#4A7C59',
      accentPremium: '#7B2D3F',
    },
    icons: { style: 'outlined', sectionIcons: {} },
    badges: { show: ['recommendation', 'new', 'premium', 'vegetarian', 'bio'], style: 'pill' },
    allergens: { position: 'product', style: 'numbers' },
    products: {
      showImages: true, imageStyle: 'color', imageShape: 'rounded', imageSize: 64, imagePosition: 'left',
      showShortDesc: true, showLongDesc: false, descMaxLines: 2,
      pricePosition: 'right', currency: '€', priceFormat: '€ {price}', showAllPrices: true, showFillQuantity: true,
      wineDetails: ['winery', 'vintage', 'grape', 'region'], wineDetailPosition: 'below',
      drinkDetails: ['alcohol', 'ingredients'],
    },
    navigation: { showToc: true, tocPosition: 'sticky', tocStyle: 'pills', stickyNav: true, smoothScroll: true, highlightActive: true, showBackToTop: true, hideEmptySections: true },
    header: { logo: null, logoPosition: 'center', logoSize: 120, title: null, subtitle: null, backgroundImage: null, overlayOpacity: 0.6, height: 'normal' },
    footer: { show: true, text: 'Hotel Sonnblick · Saalbach', showAllergenNote: true, showPriceNote: true },
  },
  analog: {
    template: 'elegant',
    hierarchy: [
      { level: 'KATEGORIE', newPage: true, showText: true, showHeader: true },
      { level: 'HERKUNFTSLAND', newPage: false, showText: true, showHeader: true },
      { level: 'REBSORTE', newPage: false, showText: false, showHeader: true },
      { level: 'PRODUKT', newPage: false, showText: true, showHeader: false },
    ],
    content: { groups: ['all'], showTitlePage: true, showToc: true, showLegend: true, showQrPage: true, freePages: [], interPages: false },
    language: { primary: 'de', secondary: 'en', secondaryScope: 'all', descriptionLang: 'both' },
    page: { format: 'A4', orientation: 'portrait', margins: 'normal', customMargins: null, bleed: false, pageNumbers: true, pageNumberStart: 1, countTitlePage: false },
    titlePage: { logo: null, logoBgColor: '#555555', logoBgImage: null, logoPosition: 'upperThird', logoSize: 200, quote: null, quoteEN: null, quoteAuthor: null, quoteFont: 'Dancing Script', freeBlocks: [] },
    toc: { depth: 'categoryAndCountry', lineStyle: 'dotted', bilingual: true, indented: true, position: 'afterTitle' },
    typography: {
      sectionTitle: { font: 'Dancing Script', size: 36, color: '#333333' },
      subCategory: { font: 'Source Sans 3', size: 14, weight: 700, color: '#333333' },
      subGrouping: { font: 'Playfair Display', size: 18, color: '#333333' },
      productName: { font: 'Source Sans 3', size: 12, weight: 700, color: '#000000' },
      winery: { font: 'Source Sans 3', size: 10, color: '#777777' },
      description: { font: 'Source Sans 3', size: 10, color: '#333333', align: 'justify', lineHeight: 1.4 },
      price: { font: 'Source Sans 3', size: 11, weight: 700, color: '#000000' },
    },
    colors: { pageBg: '#FFFFFF', textMain: '#333333', accent: '#C8A850', priceColor: '#000000', footerColor: '#999999' },
    productLayout: {
      nameLineShow: ['grapeAbbrev', 'appellation', 'style', 'icons'],
      wineryShow: ['winery', 'city', 'region'],
      descDE: true, descEN: true, descLayout: 'stacked', descAlign: 'justify', descMaxChars: 0,
      priceFormat: '{fill}  {price} €', multiplePrices: 'stacked',
      spacing: 'normal', dividerLine: false,
    },
    images: { show: true, position: 'pageBottom', maxPerRow: 4, height: 120, style: 'color', typeFilter: ['BOTTLE', 'LABEL'] },
    headerFooter: {
      header: { repeatSectionName: true, font: 'Dancing Script', dividerLine: true },
      footer: { show: true, textLeft: 'Inklusivpreise in Euro All prices incl. Taxes', textCenter: '', textRight: '{pageNumber}', dividerLine: true },
    },
    pageBreaks: { newPagePerMainCategory: true, noOrphanProducts: true, minProductsAfterHeader: 2, keepImagesWithText: true },
  },
};
ENDOFFILE

# --- Modern Template ---
cat > src/lib/design-templates/modern.ts << 'ENDOFFILE'
import { DesignConfig } from './index';

export const modernTemplate: DesignConfig = {
  digital: {
    template: 'modern',
    mood: 'dark',
    density: 'normal',
    typography: {
      h1: { font: 'Inter', size: 36, weight: 800, color: '#FFFFFF', transform: 'none', spacing: -0.02 },
      h2: { font: 'Inter', size: 20, weight: 700, color: '#E8C547', transform: 'uppercase', spacing: 0.08 },
      h3: { font: 'Inter', size: 16, weight: 600, color: '#F0F0F0' },
      body: { font: 'Inter', size: 14, weight: 400, color: '#AAAAAA', style: 'normal' },
      price: { font: 'Inter', size: 18, weight: 800, color: '#E8C547', format: '{price} €' },
      meta: { font: 'Inter', size: 11, color: '#888888' },
    },
    colors: {
      pageBackground: '#1A1A2E',
      headerBackground: '#16213E',
      headerText: '#E8C547',
      sectionHeaderBg: '#16213E',
      sectionLine: '#E8C547',
      sectionLineWidth: 2,
      sectionLineStyle: 'solid',
      productBg: 'transparent',
      productHover: '#16213E',
      productDivider: '#2A2A4A',
      priceLine: 'none',
      priceLineColor: 'transparent',
      accentPrimary: '#E8C547',
      accentRecommend: '#E8C547',
      accentNew: '#4ECDC4',
      accentPremium: '#FF6B6B',
    },
    icons: { style: 'emoji', sectionIcons: {} },
    badges: { show: ['recommendation', 'new', 'premium'], style: 'pill' },
    allergens: { position: 'footer', style: 'numbers' },
    products: {
      showImages: true, imageStyle: 'color', imageShape: 'rounded', imageSize: 80, imagePosition: 'left',
      showShortDesc: true, showLongDesc: false, descMaxLines: 2,
      pricePosition: 'right', currency: '€', priceFormat: '{price} €', showAllPrices: true, showFillQuantity: true,
      wineDetails: ['winery', 'vintage', 'grape'], wineDetailPosition: 'below',
      drinkDetails: ['alcohol'],
    },
    navigation: { showToc: true, tocPosition: 'top', tocStyle: 'tabs', stickyNav: true, smoothScroll: true, highlightActive: true, showBackToTop: true, hideEmptySections: true },
    header: { logo: null, logoPosition: 'left', logoSize: 80, title: null, subtitle: null, backgroundImage: null, overlayOpacity: 0.8, height: 'small' },
    footer: { show: true, text: 'Hotel Sonnblick · Saalbach', showAllergenNote: true, showPriceNote: true },
  },
  analog: {
    template: 'modern',
    hierarchy: [
      { level: 'KATEGORIE', newPage: true, showText: false, showHeader: true },
      { level: 'PRODUKT', newPage: false, showText: true, showHeader: false },
    ],
    content: { groups: ['all'], showTitlePage: true, showToc: false, showLegend: false, showQrPage: true, freePages: [], interPages: false },
    language: { primary: 'de', secondary: 'en', secondaryScope: 'productNames', descriptionLang: 'primary' },
    page: { format: 'A4', orientation: 'portrait', margins: 'normal', customMargins: null, bleed: false, pageNumbers: true, pageNumberStart: 1, countTitlePage: false },
    titlePage: { logo: null, logoBgColor: '#1A1A2E', logoBgImage: null, logoPosition: 'center', logoSize: 180, quote: null, quoteEN: null, quoteAuthor: null, quoteFont: 'Inter', freeBlocks: [] },
    toc: { depth: 'category', lineStyle: 'solid', bilingual: false, indented: false, position: 'afterTitle' },
    typography: {
      sectionTitle: { font: 'Inter', size: 28, weight: 800, color: '#1A1A2E' },
      subCategory: { font: 'Inter', size: 13, weight: 700, color: '#555555' },
      subGrouping: { font: 'Inter', size: 16, weight: 600, color: '#333333' },
      productName: { font: 'Inter', size: 12, weight: 600, color: '#000000' },
      winery: { font: 'Inter', size: 10, color: '#777777' },
      description: { font: 'Inter', size: 10, color: '#555555', align: 'left', lineHeight: 1.3 },
      price: { font: 'Inter', size: 12, weight: 800, color: '#000000' },
    },
    colors: { pageBg: '#FFFFFF', textMain: '#333333', accent: '#1A1A2E', priceColor: '#000000', footerColor: '#999999' },
    productLayout: {
      nameLineShow: ['style', 'icons'],
      wineryShow: ['winery'],
      descDE: true, descEN: false, descLayout: 'stacked', descAlign: 'left', descMaxChars: 150,
      priceFormat: '{fill}  {price} €', multiplePrices: 'stacked',
      spacing: 'compact', dividerLine: true,
    },
    images: { show: true, position: 'inline', maxPerRow: 1, height: 80, style: 'color', typeFilter: ['BOTTLE'] },
    headerFooter: {
      header: { repeatSectionName: true, font: 'Inter', dividerLine: false },
      footer: { show: true, textLeft: 'Alle Preise inkl. Steuern', textCenter: '', textRight: '{pageNumber}', dividerLine: false },
    },
    pageBreaks: { newPagePerMainCategory: true, noOrphanProducts: true, minProductsAfterHeader: 2, keepImagesWithText: true },
  },
};
ENDOFFILE

# --- Classic Template ---
cat > src/lib/design-templates/classic.ts << 'ENDOFFILE'
import { DesignConfig } from './index';

export const classicTemplate: DesignConfig = {
  digital: {
    template: 'classic',
    mood: 'light',
    density: 'normal',
    typography: {
      h1: { font: 'Cormorant Garamond', size: 36, weight: 700, color: '#2C2C2C', transform: 'none', spacing: 0 },
      h2: { font: 'Cormorant Garamond', size: 24, weight: 600, color: '#6B4C1E', transform: 'none', spacing: 0.02 },
      h3: { font: 'Lato', size: 16, weight: 600, color: '#333333' },
      body: { font: 'Lato', size: 14, weight: 400, color: '#666666', style: 'normal' },
      price: { font: 'Lato', size: 16, weight: 700, color: '#333333', format: '€ {price}' },
      meta: { font: 'Lato', size: 11, color: '#999999' },
    },
    colors: {
      pageBackground: '#FAFAF5',
      headerBackground: '#F5F0E8',
      headerText: '#2C2C2C',
      sectionHeaderBg: '#F5F0E8',
      sectionLine: '#D4C4A8',
      sectionLineWidth: 1,
      sectionLineStyle: 'double',
      productBg: 'transparent',
      productHover: '#F5F0E8',
      productDivider: '#E8E0D0',
      priceLine: 'dotted',
      priceLineColor: '#D4C4A8',
      accentPrimary: '#6B4C1E',
      accentRecommend: '#8B6914',
      accentNew: '#2E7D4F',
      accentPremium: '#8B2252',
    },
    icons: { style: 'outlined', sectionIcons: {} },
    badges: { show: ['recommendation', 'vegetarian', 'vegan'], style: 'dot' },
    allergens: { position: 'footer', style: 'numbers' },
    products: {
      showImages: false, imageStyle: 'color', imageShape: 'rectangle', imageSize: 48, imagePosition: 'left',
      showShortDesc: true, showLongDesc: false, descMaxLines: 2,
      pricePosition: 'right', currency: '€', priceFormat: '€ {price}', showAllPrices: true, showFillQuantity: true,
      wineDetails: ['winery', 'vintage', 'region', 'country'], wineDetailPosition: 'below',
      drinkDetails: ['alcohol'],
    },
    navigation: { showToc: true, tocPosition: 'top', tocStyle: 'list', stickyNav: false, smoothScroll: true, highlightActive: false, showBackToTop: true, hideEmptySections: true },
    header: { logo: null, logoPosition: 'center', logoSize: 100, title: null, subtitle: null, backgroundImage: null, overlayOpacity: 0.5, height: 'normal' },
    footer: { show: true, text: 'Hotel Sonnblick · Saalbach', showAllergenNote: true, showPriceNote: true },
  },
  analog: {
    template: 'classic',
    hierarchy: [
      { level: 'KATEGORIE', newPage: true, showText: true, showHeader: true },
      { level: 'PRODUKT', newPage: false, showText: true, showHeader: false },
    ],
    content: { groups: ['all'], showTitlePage: true, showToc: true, showLegend: false, showQrPage: false, freePages: [], interPages: false },
    language: { primary: 'de', secondary: 'en', secondaryScope: 'all', descriptionLang: 'both' },
    page: { format: 'A4', orientation: 'portrait', margins: 'wide', customMargins: null, bleed: false, pageNumbers: true, pageNumberStart: 1, countTitlePage: false },
    titlePage: { logo: null, logoBgColor: '#6B4C1E', logoBgImage: null, logoPosition: 'center', logoSize: 160, quote: null, quoteEN: null, quoteAuthor: null, quoteFont: 'Cormorant Garamond', freeBlocks: [] },
    toc: { depth: 'category', lineStyle: 'dotted', bilingual: true, indented: false, position: 'afterTitle' },
    typography: {
      sectionTitle: { font: 'Cormorant Garamond', size: 32, color: '#2C2C2C' },
      subCategory: { font: 'Lato', size: 13, weight: 700, color: '#555555' },
      subGrouping: { font: 'Cormorant Garamond', size: 16, color: '#333333' },
      productName: { font: 'Lato', size: 12, weight: 700, color: '#000000' },
      winery: { font: 'Lato', size: 10, color: '#777777' },
      description: { font: 'Lato', size: 10, color: '#333333', align: 'justify', lineHeight: 1.4 },
      price: { font: 'Lato', size: 11, weight: 700, color: '#000000' },
    },
    colors: { pageBg: '#FFFFFF', textMain: '#333333', accent: '#6B4C1E', priceColor: '#000000', footerColor: '#999999' },
    productLayout: {
      nameLineShow: ['icons'],
      wineryShow: ['winery', 'region'],
      descDE: true, descEN: true, descLayout: 'stacked', descAlign: 'justify', descMaxChars: 0,
      priceFormat: '{fill}  {price} €', multiplePrices: 'stacked',
      spacing: 'normal', dividerLine: true,
    },
    images: { show: false, position: 'pageBottom', maxPerRow: 4, height: 100, style: 'color', typeFilter: ['BOTTLE'] },
    headerFooter: {
      header: { repeatSectionName: false, font: 'Cormorant Garamond', dividerLine: true },
      footer: { show: true, textLeft: 'Inklusivpreise in Euro', textCenter: '', textRight: '{pageNumber}', dividerLine: true },
    },
    pageBreaks: { newPagePerMainCategory: true, noOrphanProducts: true, minProductsAfterHeader: 2, keepImagesWithText: true },
  },
};
ENDOFFILE

# --- Minimal Template ---
cat > src/lib/design-templates/minimal.ts << 'ENDOFFILE'
import { DesignConfig } from './index';

export const minimalTemplate: DesignConfig = {
  digital: {
    template: 'minimal',
    mood: 'light',
    density: 'compact',
    typography: {
      h1: { font: 'Inter', size: 28, weight: 700, color: '#111111', transform: 'none', spacing: -0.01 },
      h2: { font: 'Inter', size: 18, weight: 600, color: '#333333', transform: 'uppercase', spacing: 0.06 },
      h3: { font: 'Inter', size: 15, weight: 600, color: '#222222' },
      body: { font: 'Inter', size: 13, weight: 400, color: '#888888', style: 'normal' },
      price: { font: 'Inter', size: 15, weight: 700, color: '#111111', format: '{price} €' },
      meta: { font: 'Inter', size: 11, color: '#BBBBBB' },
    },
    colors: {
      pageBackground: '#FFFFFF',
      headerBackground: '#FFFFFF',
      headerText: '#111111',
      sectionHeaderBg: 'transparent',
      sectionLine: '#EEEEEE',
      sectionLineWidth: 1,
      sectionLineStyle: 'solid',
      productBg: 'transparent',
      productHover: '#F8F8F8',
      productDivider: '#F0F0F0',
      priceLine: 'none',
      priceLineColor: 'transparent',
      accentPrimary: '#111111',
      accentRecommend: '#E8C547',
      accentNew: '#22C55E',
      accentPremium: '#EF4444',
    },
    icons: { style: 'none', sectionIcons: {} },
    badges: { show: ['recommendation'], style: 'dot' },
    allergens: { position: 'footer', style: 'abbreviations' },
    products: {
      showImages: false, imageStyle: 'color', imageShape: 'rectangle', imageSize: 48, imagePosition: 'left',
      showShortDesc: false, showLongDesc: false, descMaxLines: 1,
      pricePosition: 'right', currency: '€', priceFormat: '{price} €', showAllPrices: true, showFillQuantity: true,
      wineDetails: ['vintage', 'grape'], wineDetailPosition: 'inline',
      drinkDetails: [],
    },
    navigation: { showToc: false, tocPosition: 'top', tocStyle: 'list', stickyNav: false, smoothScroll: true, highlightActive: false, showBackToTop: false, hideEmptySections: true },
    header: { logo: null, logoPosition: 'left', logoSize: 60, title: null, subtitle: null, backgroundImage: null, overlayOpacity: 0, height: 'small' },
    footer: { show: false, text: '', showAllergenNote: true, showPriceNote: false },
  },
  analog: {
    template: 'minimal',
    hierarchy: [
      { level: 'KATEGORIE', newPage: false, showText: false, showHeader: true },
      { level: 'PRODUKT', newPage: false, showText: false, showHeader: false },
    ],
    content: { groups: ['all'], showTitlePage: false, showToc: false, showLegend: false, showQrPage: false, freePages: [], interPages: false },
    language: { primary: 'de', secondary: '', secondaryScope: 'none', descriptionLang: 'primary' },
    page: { format: 'A5', orientation: 'portrait', margins: 'narrow', customMargins: null, bleed: false, pageNumbers: false, pageNumberStart: 1, countTitlePage: false },
    titlePage: { logo: null, logoBgColor: '#FFFFFF', logoBgImage: null, logoPosition: 'center', logoSize: 100, quote: null, quoteEN: null, quoteAuthor: null, quoteFont: 'Inter', freeBlocks: [] },
    toc: { depth: 'category', lineStyle: 'none', bilingual: false, indented: false, position: 'afterTitle' },
    typography: {
      sectionTitle: { font: 'Inter', size: 20, weight: 700, color: '#111111' },
      subCategory: { font: 'Inter', size: 12, weight: 600, color: '#555555' },
      subGrouping: { font: 'Inter', size: 14, weight: 600, color: '#333333' },
      productName: { font: 'Inter', size: 11, weight: 600, color: '#000000' },
      winery: { font: 'Inter', size: 9, color: '#999999' },
      description: { font: 'Inter', size: 9, color: '#777777', align: 'left', lineHeight: 1.3 },
      price: { font: 'Inter', size: 11, weight: 700, color: '#000000' },
    },
    colors: { pageBg: '#FFFFFF', textMain: '#111111', accent: '#111111', priceColor: '#000000', footerColor: '#BBBBBB' },
    productLayout: {
      nameLineShow: [],
      wineryShow: [],
      descDE: false, descEN: false, descLayout: 'stacked', descAlign: 'left', descMaxChars: 0,
      priceFormat: '{price} €', multiplePrices: 'inline',
      spacing: 'compact', dividerLine: false,
    },
    images: { show: false, position: 'none', maxPerRow: 0, height: 0, style: 'color', typeFilter: [] },
    headerFooter: {
      header: { repeatSectionName: false, font: 'Inter', dividerLine: false },
      footer: { show: false, textLeft: '', textCenter: '', textRight: '', dividerLine: false },
    },
    pageBreaks: { newPagePerMainCategory: false, noOrphanProducts: true, minProductsAfterHeader: 1, keepImagesWithText: true },
  },
};
ENDOFFILE

echo "4 Templates erstellt"

# === 3. API: GET/PATCH designConfig ===
echo "[3/5] API-Endpoints erstellen..."

mkdir -p src/app/api/v1/menus/\[id\]/design

cat > 'src/app/api/v1/menus/[id]/design/route.ts' << 'ENDOFFILE'
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import { getTemplate, mergeConfig } from '@/lib/design-templates';

// GET /api/v1/menus/[id]/design – Design-Config einer Karte laden
export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const menu = await prisma.menu.findUnique({
    where: { id: params.id },
    select: { id: true, designConfig: true },
  });

  if (!menu) return NextResponse.json({ error: 'Menu not found' }, { status: 404 });

  // Merge: Template-Defaults + gespeicherte Overrides
  const saved = menu.designConfig as any;
  const templateName = saved?.digital?.template || saved?.analog?.template || 'elegant';
  const template = getTemplate(templateName);
  const merged = {
    digital: mergeConfig(template.digital, saved?.digital),
    analog: mergeConfig(template.analog, saved?.analog),
  };

  return NextResponse.json({ designConfig: merged, savedOverrides: saved, templateName });
}

// PATCH /api/v1/menus/[id]/design – Design-Config speichern (nur Overrides)
export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await req.json();
  const { designConfig } = body;

  if (!designConfig) return NextResponse.json({ error: 'designConfig required' }, { status: 400 });

  const updated = await prisma.menu.update({
    where: { id: params.id },
    data: { designConfig },
    select: { id: true, designConfig: true },
  });

  return NextResponse.json({ success: true, designConfig: updated.designConfig });
}
ENDOFFILE

echo "API-Endpoints erstellt"

# === 4. API: Template-Liste ===
echo "[4/5] Template-Liste API..."

mkdir -p src/app/api/v1/design-templates

cat > 'src/app/api/v1/design-templates/route.ts' << 'ENDOFFILE'
import { NextResponse } from 'next/server';

const templates = [
  { id: 'elegant', name: 'Elegant', description: 'Weinkarten, Gala-Menüs – Playfair Display, warme Töne, viel Weißraum', mood: 'warm' },
  { id: 'modern', name: 'Modern', description: 'Barkarte, Cocktails – Inter, dunkler Hintergrund, große Bilder', mood: 'dark' },
  { id: 'classic', name: 'Klassisch', description: 'Restaurant-Menüs, Themenabende – Garamond, Bordüren, zentriert', mood: 'light' },
  { id: 'minimal', name: 'Minimal', description: 'Frühstück, Room Service – Max. Lesbarkeit, wenig Dekoration', mood: 'light' },
];

export async function GET() {
  return NextResponse.json({ templates });
}
ENDOFFILE

# === 5. Build + Restart ===
echo "[5/5] Build + Restart..."
npm run build 2>&1 | tail -10
pm2 restart menucard-pro

echo ""
echo "=== Phase 1 fertig! ==="
echo "- designConfig JSON-Feld auf Menu-Tabelle"
echo "- 4 Template-Defaults (elegant, modern, classic, minimal)"
echo "- TypeScript Types fuer DesignConfig"
echo "- API: GET/PATCH /api/v1/menus/[id]/design"
echo "- API: GET /api/v1/design-templates"
