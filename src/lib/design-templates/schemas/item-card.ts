import type { ComponentSchema } from './types';

export const itemCardSchema: ComponentSchema = {
  id: 'item-card',
  label: 'Produkt-Karte',
  icon: 'restaurant_menu',
  desc: 'Darstellung einzelner Produkte (Speise, Getränk, Wein)',
  configPath: ['digital', 'products'],
  groups: [
    {
      id: 'images',
      label: 'Bilder',
      fields: {
        showImages: {
          type: 'boolean',
          label: 'Bilder anzeigen',
          default: false,
        },
        imageStyle: {
          type: 'select',
          label: 'Stil',
          default: 'color',
          options: [
            { label: 'Farbe', value: 'color' },
            { label: 'Schwarzweiß', value: 'grayscale' },
            { label: 'Sepia', value: 'sepia' },
          ],
          visibleIf: (c) => c.showImages === true,
        },
        imageShape: {
          type: 'select',
          label: 'Form',
          default: 'rounded',
          options: [
            { label: 'Abgerundet', value: 'rounded' },
            { label: 'Rund', value: 'round' },
            { label: 'Rechteck', value: 'rectangle' },
          ],
          visibleIf: (c) => c.showImages === true,
        },
        imageSize: {
          type: 'slider',
          label: 'Größe',
          min: 32,
          max: 128,
          unit: 'px',
          default: 56,
          visibleIf: (c) => c.showImages === true,
        },
        imagePosition: {
          type: 'select',
          label: 'Position',
          default: 'left',
          options: [
            { label: 'Links', value: 'left' },
            { label: 'Rechts', value: 'right' },
          ],
          visibleIf: (c) => c.showImages === true,
        },
      },
    },
    {
      id: 'description',
      label: 'Beschreibung',
      fields: {
        showShortDesc: {
          type: 'boolean',
          label: 'Kurzbeschreibung',
          default: true,
        },
        showLongDesc: {
          type: 'boolean',
          label: 'Langbeschreibung (nur Detail-Seite)',
          default: false,
        },
        descMaxLines: {
          type: 'slider',
          label: 'Max. Zeilen',
          min: 1,
          max: 10,
          default: 2,
          visibleIf: (c) => c.showShortDesc === true,
        },
      },
    },
    {
      id: 'price',
      label: 'Preis',
      fields: {
        pricePosition: {
          type: 'select',
          label: 'Position',
          default: 'right',
          options: [
            { label: 'Rechts', value: 'right' },
            { label: 'Unter Name', value: 'below-name' },
            { label: 'Unter Beschreibung', value: 'below-desc' },
          ],
        },
        showAllPrices: {
          type: 'boolean',
          label: 'Alle Preise zeigen',
          default: true,
        },
        showFillQuantity: {
          type: 'boolean',
          label: 'Füllmenge zeigen',
          default: true,
        },
      },
    },
    {
      id: 'wine-details',
      label: 'Weindetails',
      desc: 'Welche Weinfelder auf der Karte erscheinen',
      fields: {
        wineDetails: {
          type: 'multitoggle',
          label: 'Sichtbare Weinfelder',
          default: ['winery', 'vintage', 'grape', 'region'],
          options: [
            { label: 'Weingut', value: 'winery' },
            { label: 'Jahrgang', value: 'vintage' },
            { label: 'Rebsorte', value: 'grape' },
            { label: 'Region', value: 'region' },
            { label: 'Land', value: 'country' },
            { label: 'Alkoholgehalt', value: 'alcohol' },
            { label: 'Appellation', value: 'appellation' },
          ],
        },
        wineDetailPosition: {
          type: 'select',
          label: 'Position',
          default: 'below',
          options: [
            { label: 'Unter Name', value: 'below' },
            { label: 'Aufklappbar', value: 'collapsible' },
            { label: 'Nur Detailseite', value: 'detail-only' },
          ],
        },
      },
    },
    {
      id: 'beverage-details',
      label: 'Getränkedetails',
      desc: 'Felder für Spirituosen, Bier und Cocktails',
      fields: {
        drinkDetails: {
          type: 'multitoggle',
          label: 'Sichtbare Felder',
          default: ['alcohol'],
          options: [
            { label: 'Alkoholgehalt', value: 'alcohol' },
            { label: 'Füllmenge', value: 'servingSize' },
            { label: 'Jahrgang', value: 'vintage' },
            { label: 'Herkunft', value: 'origin' },
            { label: 'Brennerei', value: 'distillery' },
          ],
        },
      },
    },
  ],
};
