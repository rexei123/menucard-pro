/**
 * Zentrale Preisformatierung für MenuCard Pro.
 * DE: "€ 45,00"   EN: "€45.00"
 */
const DE = new Intl.NumberFormat('de-AT', {
  style: 'currency',
  currency: 'EUR',
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});
const EN = new Intl.NumberFormat('en-GB', {
  style: 'currency',
  currency: 'EUR',
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

export function formatPrice(
  value: number | string | null | undefined,
  locale: 'de' | 'en' = 'de',
): string {
  if (value === null || value === undefined || value === '') return '';
  const n = typeof value === 'string'
    ? Number(value.replace(',', '.'))
    : Number(value);
  if (!Number.isFinite(n)) return '';
  return (locale === 'en' ? EN : DE).format(n);
}
