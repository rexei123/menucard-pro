/**
 * Globale Basis-Schemas (Grundstil, Typografie, Farben, Preis-Verbindungslinie).
 *
 * Diese Schemas sind NICHT eine der 8 "Komponenten" aus der Roadmap, sondern
 * globale Tab-Gruppen, die Werte für mehrere Komponenten injizieren.
 */
import type { ComponentSchema } from './types';
import { typoLevelFields, TYPO_LEVELS } from './shared/typography';

// ─── Grundstil (Template, Mood, Density) ──────────────────────────

export const grundstilSchema: ComponentSchema = {
  id: 'grundstil',
  label: 'Grundstil',
  icon: 'tune',
  desc: 'Allgemeine Stimmung und Dichte der Darstellung',
  configPath: ['digital'],
  groups: [
    {
      id: 'tone',
      label: 'Stimmung',
      fields: {
        mood: {
          type: 'select',
          label: 'Stimmung',
          default: 'light',
          options: [
            { label: 'Hell', value: 'light' },
            { label: 'Warm', value: 'warm' },
            { label: 'Dunkel', value: 'dark' },
          ],
        },
        density: {
          type: 'select',
          label: 'Dichte',
          default: 'normal',
          options: [
            { label: 'Luftig', value: 'airy' },
            { label: 'Normal', value: 'normal' },
            { label: 'Kompakt', value: 'compact' },
          ],
        },
      },
    },
  ],
};

// ─── Farben ──────────────────────────────────────────────────

export const farbenSchema: ComponentSchema = {
  id: 'farben',
  label: 'Farben',
  icon: 'palette',
  desc: 'Hintergründe, Linien, Preis-Dot-Leader und Akzentfarben',
  configPath: ['digital', 'colors'],
  groups: [
    {
      id: 'surfaces',
      label: 'Grundfarben',
      fields: {
        pageBackground: { type: 'color', label: 'Seiten-Hintergrund', default: '#FFFFFF' },
        headerBackground: { type: 'color', label: 'Kopfbereich-Hintergrund', default: '#FFFFFF' },
        headerText: { type: 'color', label: 'Kopfbereich-Text', default: '#1A1A1A' },
      },
    },
    {
      id: 'products',
      label: 'Produkte',
      fields: {
        productBg: { type: 'color', label: 'Produkt-Hintergrund', default: '#FFFFFF', allowAlpha: true },
        productHover: { type: 'color', label: 'Produkt-Hover', default: '#FAFAFA' },
        productDivider: { type: 'color', label: 'Trennlinie', default: '#EEEEEE' },
      },
    },
    {
      id: 'price-line',
      label: 'Preis-Verbindungslinie',
      fields: {
        priceLine: {
          type: 'select',
          label: 'Stil',
          default: 'none',
          options: [
            { label: 'Gepunktet', value: 'dotted' },
            { label: 'Durchgezogen', value: 'solid' },
            { label: 'Keine', value: 'none' },
          ],
        },
        priceLineColor: {
          type: 'color',
          label: 'Farbe',
          default: '#CCCCCC',
          visibleIf: (c) => c.priceLine !== 'none',
        },
      },
    },
    {
      id: 'accents',
      label: 'Akzentfarben',
      fields: {
        accentPrimary: { type: 'color', label: 'Primär', default: '#1E3A5F' },
        accentRecommend: { type: 'color', label: 'Empfehlung', default: '#C9A34A' },
        accentNew: { type: 'color', label: 'Neu', default: '#1E8E4E' },
        accentPremium: { type: 'color', label: 'Premium', default: '#8B2332' },
      },
    },
  ],
};

// ─── Typografie ──────────────────────────────────────────────

/**
 * Typografie-Schema — baut automatisch 6 Gruppen (h1/h2/h3/body/price/meta)
 * mit den wiederverwendbaren Typo-Level-Feldern.
 */
export const typografieSchema: ComponentSchema = {
  id: 'typografie',
  label: 'Typografie',
  icon: 'text_fields',
  desc: 'Schriftarten und Größen pro Element-Ebene',
  configPath: ['digital', 'typography'],
  groups: TYPO_LEVELS.map((level) => ({
    id: level.key,
    label: level.label,
    desc: level.desc,
    fields: typoLevelFields(
      {
        font: 'Inter',
        size: level.key === 'h1' ? 30 : level.key === 'h2' ? 17 : level.key === 'h3' ? 15 : level.key === 'price' ? 15 : level.key === 'meta' ? 12 : 14,
        weight: level.key === 'h1' ? '700' : level.key === 'h2' || level.key === 'h3' || level.key === 'price' ? '600' : '400',
        color: level.key === 'body' ? '#555555' : level.key === 'meta' ? '#888888' : '#1A1A1A',
        transform: 'none',
        spacing: level.key === 'h1' ? -1 : 0,
        style: 'normal',
      },
      { includeStyle: level.key === 'body' },
    ),
  })),
};
