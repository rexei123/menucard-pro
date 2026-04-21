import type { ComponentSchema } from './types';

export const heroSchema: ComponentSchema = {
  id: 'hero',
  label: 'Kopfbereich',
  icon: 'panorama',
  desc: 'Logo, Titel, Untertitel und Hintergrund der Kartenansicht',
  configPath: ['digital', 'header'],
  groups: [
    {
      id: 'layout',
      label: 'Layout',
      fields: {
        height: {
          type: 'select',
          label: 'Höhe',
          default: 'normal',
          options: [
            { label: 'Klein (nur Logo+Titel)', value: 'small' },
            { label: 'Normal (Logo+Titel+Untertitel)', value: 'normal' },
            { label: 'Groß (Vollbild mit Hintergrundbild)', value: 'large' },
          ],
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
          max: 240,
          unit: 'px',
          default: 80,
        },
      },
    },
    {
      id: 'content',
      label: 'Inhalt',
      fields: {
        title: {
          type: 'text',
          label: 'Titel (leer = Kartenname)',
          default: '',
          placeholder: 'Kartenname wird verwendet',
          maxLength: 120,
        },
        subtitle: {
          type: 'text',
          label: 'Untertitel',
          default: '',
          placeholder: 'z.B. Saison 2025/26',
          maxLength: 120,
        },
        logo: {
          type: 'text',
          label: 'Logo-URL',
          default: '',
          placeholder: '/uploads/logo.png',
          maxLength: 500,
        },
      },
    },
    {
      id: 'background',
      label: 'Hintergrund',
      fields: {
        backgroundImage: {
          type: 'text',
          label: 'Hintergrundbild-URL',
          default: '',
          placeholder: '/uploads/hero.jpg',
          maxLength: 500,
          visibleIf: (c) => c.height === 'large',
        },
        overlayOpacity: {
          type: 'slider',
          label: 'Overlay-Deckkraft',
          min: 0,
          max: 100,
          step: 5,
          unit: '%',
          default: 60,
          visibleIf: (c) => c.height === 'large',
        },
      },
    },
  ],
};
