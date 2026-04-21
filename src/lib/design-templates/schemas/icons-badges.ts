import type { ComponentSchema } from './types';

export const iconsBadgesSchema: ComponentSchema = {
  id: 'icons-badges',
  label: 'Icons & Badges',
  icon: 'sell',
  desc: 'Icon-Stil und sichtbare Produkt-Kennzeichnungen',
  configPath: ['digital'],
  groups: [
    {
      id: 'icons',
      label: 'Icons',
      fields: {
        'icons.style': {
          type: 'select',
          label: 'Icon-Stil',
          default: 'outlined',
          options: [
            { label: 'Emoji-Icons', value: 'emoji' },
            { label: 'Linien-Icons', value: 'outlined' },
            { label: 'Ausgefüllt', value: 'filled' },
            { label: 'Keine', value: 'none' },
          ],
        },
      },
    },
    {
      id: 'badges',
      label: 'Badges',
      fields: {
        'badges.style': {
          type: 'select',
          label: 'Badge-Stil',
          default: 'pill',
          options: [
            { label: 'Pill-Tag', value: 'pill' },
            { label: 'Farbiger Punkt', value: 'dot' },
            { label: 'Icon', value: 'icon' },
            { label: 'Farbiger Rand', value: 'bordered' },
          ],
        },
        'badges.show': {
          type: 'multitoggle',
          label: 'Sichtbare Badges',
          default: ['recommendation', 'new', 'premium'],
          options: [
            { label: 'Empfehlung', value: 'recommendation' },
            { label: 'Neu', value: 'new' },
            { label: 'Premium', value: 'premium' },
            { label: 'Bestseller', value: 'bestseller' },
            { label: 'Signature', value: 'signature' },
            { label: 'Vegetarisch', value: 'vegetarian' },
            { label: 'Vegan', value: 'vegan' },
            { label: 'Bio', value: 'bio' },
          ],
        },
      },
    },
  ],
};
