import type { ComponentSchema } from './types';
import { typoLevelFields } from './shared/typography';

export const sectionHeaderSchema: ComponentSchema = {
  id: 'section-header',
  label: 'Sektions-Header',
  icon: 'view_headline',
  desc: 'Titel und Trennlinien einzelner Kategorie-Blöcke',
  configPath: ['digital'],
  groups: [
    {
      id: 'layout',
      label: 'Layout',
      fields: {
        'sectionAlign': {
          type: 'select',
          label: 'Ausrichtung',
          default: 'left',
          options: [
            { label: 'Links', value: 'left' },
            { label: 'Zentriert', value: 'center' },
            { label: 'Rechts', value: 'right' },
          ],
        },
        'sectionShowIcon': {
          type: 'boolean',
          label: 'Icon anzeigen',
          default: false,
          desc: 'Kleines Symbol links vom Titel (aus Sektions-Icon-Feld)',
        },
      },
    },
    {
      id: 'line',
      label: 'Trennlinie',
      fields: {
        'colors.sectionLineStyle': {
          type: 'select',
          label: 'Linienstil',
          default: 'solid',
          options: [
            { label: 'Durchgezogen', value: 'solid' },
            { label: 'Gestrichelt', value: 'dashed' },
            { label: 'Doppelt', value: 'double' },
            { label: 'Keine', value: 'none' },
          ],
        },
        'colors.sectionLineWidth': {
          type: 'slider',
          label: 'Linienstärke',
          min: 0,
          max: 5,
          unit: 'px',
          default: 1,
          visibleIf: (c) => c['colors.sectionLineStyle'] !== 'none',
        },
        'colors.sectionLine': {
          type: 'color',
          label: 'Linien-Farbe',
          default: '#E5E5E5',
          visibleIf: (c) => c['colors.sectionLineStyle'] !== 'none',
        },
      },
    },
    {
      id: 'colors',
      label: 'Farben',
      fields: {
        'colors.sectionHeaderBg': {
          type: 'color',
          label: 'Header-Hintergrund',
          default: '#FFFFFF',
          allowAlpha: true,
        },
      },
    },
    {
      id: 'typography',
      label: 'Typografie (H2)',
      desc: 'Typografie-Einstellungen aus dem Typografie-Tab für h2 werden hier gespiegelt.',
      fields: typoLevelFields({
        font: 'Inter',
        size: 17,
        weight: '600',
        color: '#1A1A1A',
        transform: 'none',
        spacing: 0,
      }),
    },
  ],
};
