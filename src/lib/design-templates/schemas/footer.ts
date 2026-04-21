import type { ComponentSchema } from './types';

export const footerSchema: ComponentSchema = {
  id: 'footer',
  label: 'Fußzeile',
  icon: 'bottom_panel_open',
  desc: 'Informationen am unteren Rand der Kartenansicht',
  configPath: ['digital', 'footer'],
  groups: [
    {
      id: 'visibility',
      label: 'Sichtbarkeit',
      fields: {
        show: {
          type: 'boolean',
          label: 'Fußzeile anzeigen',
          default: true,
        },
      },
    },
    {
      id: 'content',
      label: 'Inhalt',
      fields: {
        text: {
          type: 'text',
          label: 'Fußzeilen-Text',
          default: '',
          placeholder: 'Hotel Sonnblick · Kaprun',
          maxLength: 200,
          visibleIf: (c) => c.show === true,
        },
        showAllergenNote: {
          type: 'boolean',
          label: 'Allergen-Hinweis anzeigen',
          default: true,
          desc: 'Hinweis "Bitte informieren Sie unser Personal über Allergien"',
          visibleIf: (c) => c.show === true,
        },
        showPriceNote: {
          type: 'boolean',
          label: 'Preishinweis anzeigen',
          default: true,
          desc: 'Hinweis "Alle Preise inkl. gesetzlicher MwSt."',
          visibleIf: (c) => c.show === true,
        },
      },
    },
    {
      id: 'layout',
      label: 'Layout',
      fields: {
        align: {
          type: 'select',
          label: 'Ausrichtung',
          default: 'center',
          options: [
            { label: 'Links', value: 'left' },
            { label: 'Zentriert', value: 'center' },
            { label: 'Rechts', value: 'right' },
          ],
          visibleIf: (c) => c.show === true,
        },
      },
    },
    {
      id: 'links',
      label: 'Rechtliche Links',
      fields: {
        linkImprint: {
          type: 'text',
          label: 'Impressum-URL',
          default: '',
          placeholder: 'https://hotel-sonnblick.at/impressum',
          maxLength: 500,
          visibleIf: (c) => c.show === true,
        },
        linkPrivacy: {
          type: 'text',
          label: 'Datenschutz-URL',
          default: '',
          placeholder: 'https://hotel-sonnblick.at/datenschutz',
          maxLength: 500,
          visibleIf: (c) => c.show === true,
        },
      },
    },
  ],
};
