// Regelbasierte Suchbegriff-Generierung aus Produktdaten

interface ProductData {
  name: string;
  type?: string;
  wineProfile?: {
    winery?: string | null;
    grapeVarieties?: string[];
    region?: string | null;
    country?: string | null;
  } | null;
  beverageDetail?: {
    brand?: string | null;
    category?: string | null;
  } | null;
  groupName?: string | null;
}

export function generateSearchSuggestions(product: ProductData): string[] {
  const suggestions: string[] = [];

  if (product.type === 'WINE' && product.wineProfile) {
    const { winery, grapeVarieties, region, country } = product.wineProfile;
    const grape = grapeVarieties?.[0] || '';

    if (winery && grape) suggestions.push(`${winery} ${grape} bottle`);
    if (grape) suggestions.push(`${grape} wine bottle`);
    if (country && region) suggestions.push(`${country} wine ${region}`);
    suggestions.push('wine glass vineyard');
  } else if (product.type === 'DRINK' && product.beverageDetail) {
    const { brand, category } = product.beverageDetail;
    const name = product.name;

    if (name) suggestions.push(`${name} cocktail`);
    if (brand) suggestions.push(`${brand} drink`);
    if (category) suggestions.push(`${category} bar`);
    suggestions.push('cocktail glass bar ambiance');
  } else {
    // FOOD oder andere
    const name = product.name;
    const group = product.groupName;

    if (name) suggestions.push(name);
    if (name) suggestions.push(`${name} restaurant plating`);
    if (group) suggestions.push(`${group} fine dining`);
  }

  return suggestions.filter(s => s.trim().length > 0).slice(0, 4);
}
