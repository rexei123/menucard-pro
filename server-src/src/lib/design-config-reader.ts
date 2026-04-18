import { DesignConfig, DigitalConfig, mergeConfig, getTemplate } from './design-templates';

/**
 * Resolves a menu's designConfig: loads template defaults, merges with overrides.
 * Returns the complete DigitalConfig ready for rendering.
 */
export function resolveDigitalConfig(designConfig: any): DigitalConfig {
  const templateName = designConfig?.digital?.template || 'elegant';
  const template = getTemplate(templateName);
  return mergeConfig(template.digital, designConfig?.digital || {});
}

/**
 * Bekannte Sans-Serif-Fonts → korrekter CSS-Fallback.
 * Alles andere fällt auf 'serif' zurück.
 */
const SANS_SERIF_FONTS = new Set<string>([
  'Inter',
  'Lato',
  'Roboto',
  'Montserrat',
  'Space Grotesk',
  'Source Sans 3',
  'Source Sans Pro',
  'Open Sans',
  'Nunito',
  'Poppins',
  'Work Sans',
  'IBM Plex Sans',
  'Manrope',
]);

function fontStack(fontName: string): string {
  const isSans = SANS_SERIF_FONTS.has(fontName) || /sans/i.test(fontName);
  return `'${fontName}', ${isSans ? 'system-ui, -apple-system, sans-serif' : 'Georgia, serif'}`;
}

/**
 * Converts a DigitalConfig into CSS custom properties.
 * These are set on the page wrapper so all children can reference them.
 */
export function configToCssVars(config: DigitalConfig): Record<string, string> {
  const vars: Record<string, string> = {};

  // Typography
  const typoLevels = ['h1', 'h2', 'h3', 'body', 'price', 'meta'] as const;
  for (const level of typoLevels) {
    const t = config.typography[level];
    vars[`--mc-${level}-font`] = fontStack(t.font);
    vars[`--mc-${level}-size`] = `${t.size}px`;
    vars[`--mc-${level}-weight`] = String(t.weight || 400);
    vars[`--mc-${level}-color`] = t.color;
    if (t.transform) vars[`--mc-${level}-transform`] = t.transform;
    if (t.spacing) vars[`--mc-${level}-spacing`] = `${t.spacing}em`;
    if (t.style) vars[`--mc-${level}-style`] = t.style;
  }

  // Colors
  vars['--mc-bg'] = config.colors.pageBackground;
  vars['--mc-header-bg'] = config.colors.headerBackground;
  vars['--mc-header-text'] = config.colors.headerText;
  vars['--mc-section-header-bg'] = config.colors.sectionHeaderBg;
  vars['--mc-section-line'] = config.colors.sectionLine;
  vars['--mc-section-line-w'] = `${config.colors.sectionLineWidth}px`;
  vars['--mc-product-bg'] = config.colors.productBg;
  vars['--mc-product-hover'] = config.colors.productHover;
  vars['--mc-product-divider'] = config.colors.productDivider;
  vars['--mc-price-line'] = config.colors.priceLine;
  vars['--mc-price-line-color'] = config.colors.priceLineColor;
  vars['--mc-accent'] = config.colors.accentPrimary;
  vars['--mc-accent-recommend'] = config.colors.accentRecommend;
  vars['--mc-accent-new'] = config.colors.accentNew;
  vars['--mc-accent-premium'] = config.colors.accentPremium;

  // Density
  const densityMap = { airy: '1.25', normal: '1', compact: '0.8' };
  vars['--mc-density'] = densityMap[config.density] || '1';

  return vars;
}

/**
 * Returns density-based spacing classes
 */
export function getDensityClasses(density: string): { section: string; item: string; padding: string } {
  switch (density) {
    case 'airy': return { section: 'py-10', item: 'space-y-3', padding: 'p-5' };
    case 'compact': return { section: 'py-5', item: 'space-y-1', padding: 'p-3' };
    default: return { section: 'py-8', item: 'space-y-2', padding: 'p-4' };
  }
}
