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
