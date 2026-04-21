import type { ComponentSchema } from './types';

export const titlePageSchema: ComponentSchema = {
  id: 'title-page',
  label: 'PDF Titelseite',
  icon: 'article',
  desc: 'Vorgeschaltete Titelseite im PDF (Logo, Titel, Zitat)',
  configPath: ['analog', 'titlePage'],
  groups: [
    {
      id: 'logo',
      label: 'Logo',
      fields: {
        logo: {
          type: 'text',
          label: 'Logo-URL',
          default: '',
          placeholder: '/uploads/logo.png',
          maxLength: 500,
        },
        logoPosition: {
          type: 'select',
          label: 'Logo-Position',
          default: 'center',
          options: [
            { label: 'Links', value: 'left' },
            { label: 'Zentriert', value: 'center' },
            { label: 'Rechts', value: 'right' },
          ],
        },
        logoSize: {
          type: 'slider',
          label: 'Logo-Größe',
          min: 40,
          max: 300,
          unit: 'px',
          default: 120,
        },
        logoBgColor: {
          type: 'color',
          label: 'Logo-Hintergrund',
          default: '#FFFFFF',
        },
        logoBgImage: {
          type: 'text',
          label: 'Hintergrundbild-URL',
          default: '',
          placeholder: '/uploads/title-bg.jpg',
          maxLength: 500,
        },
      },
    },
    {
      id: 'quote',
      label: 'Zitat',
      desc: 'Stimmungsvolles Zitat unterhalb des Logos',
      fields: {
        quote: {
          type: 'text',
          label: 'Zitat (Deutsch)',
          default: '',
          multiline: true,
          maxLength: 400,
        },
        quoteEN: {
          type: 'text',
          label: 'Zitat (Englisch)',
          default: '',
          multiline: true,
          maxLength: 400,
        },
        quoteAuthor: {
          type: 'text',
          label: 'Zitat-Autor',
          default: '',
          maxLength: 120,
        },
        quoteFont: {
          type: 'font',
          label: 'Zitat-Schrift',
          default: 'Inter',
        },
      },
    },
  ],
};
