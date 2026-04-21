import type { ComponentSchema } from './types';

export const navigationSchema: ComponentSchema = {
  id: 'navigation',
  label: 'Navigation',
  icon: 'menu_open',
  desc: 'Scroll-Verhalten, Inhaltsverzeichnis, Sektions-Tabs',
  configPath: ['digital', 'navigation'],
  groups: [
    {
      id: 'toc',
      label: 'Inhaltsverzeichnis',
      fields: {
        showToc: {
          type: 'boolean',
          label: 'Inhaltsverzeichnis anzeigen',
          default: true,
        },
        tocPosition: {
          type: 'select',
          label: 'Position',
          default: 'sticky',
          options: [
            { label: 'Oben unter Header', value: 'top' },
            { label: 'Sticky', value: 'sticky' },
            { label: 'Dropdown', value: 'dropdown' },
          ],
          visibleIf: (c) => c.showToc === true,
        },
        tocStyle: {
          type: 'select',
          label: 'Stil',
          default: 'list',
          options: [
            { label: 'Pill-Buttons', value: 'pills' },
            { label: 'Tabs', value: 'tabs' },
            { label: 'Einfache Liste', value: 'list' },
          ],
          visibleIf: (c) => c.showToc === true,
        },
      },
    },
    {
      id: 'behavior',
      label: 'Verhalten',
      fields: {
        stickyNav: {
          type: 'boolean',
          label: 'Sticky Navigation',
          default: true,
        },
        smoothScroll: {
          type: 'boolean',
          label: 'Smooth Scroll',
          default: true,
        },
        highlightActive: {
          type: 'boolean',
          label: 'Aktive Sektion hervorheben',
          default: true,
        },
        showBackToTop: {
          type: 'boolean',
          label: '"Nach oben"-Button',
          default: true,
        },
        hideEmptySections: {
          type: 'boolean',
          label: 'Leere Sektionen ausblenden',
          default: true,
        },
      },
    },
  ],
};
