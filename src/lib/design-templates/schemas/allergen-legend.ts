import type { ComponentSchema } from './types';

export const allergenLegendSchema: ComponentSchema = {
  id: 'allergen-legend',
  label: 'Allergene',
  icon: 'warning',
  desc: 'Darstellung und Position der Allergenkennzeichnung',
  configPath: ['digital', 'allergens'],
  groups: [
    {
      id: 'display',
      label: 'Darstellung',
      fields: {
        position: {
          type: 'select',
          label: 'Position',
          default: 'product',
          options: [
            { label: 'Am Produkt', value: 'product' },
            { label: 'Am Seitenende', value: 'footer' },
            { label: 'Aus', value: 'hidden' },
          ],
        },
        style: {
          type: 'select',
          label: 'Stil',
          default: 'numbers',
          options: [
            { label: 'Nummern (A, B, C …)', value: 'numbers' },
            { label: 'Abkürzungen', value: 'abbreviations' },
            { label: 'Icons', value: 'icons' },
          ],
          visibleIf: (c) => c.position !== 'hidden',
        },
      },
    },
    {
      id: 'legend',
      label: 'Legende',
      fields: {
        showLegend: {
          type: 'boolean',
          label: 'Legende am Seitenende',
          default: true,
          desc: 'Zeigt eine vollständige Allergen-Legende unterhalb der Karte',
        },
        legendStyle: {
          type: 'select',
          label: 'Legenden-Stil',
          default: 'compact',
          options: [
            { label: 'Kompakt', value: 'compact' },
            { label: 'Vollständig', value: 'full' },
          ],
          visibleIf: (c) => c.showLegend === true,
        },
      },
    },
  ],
};
