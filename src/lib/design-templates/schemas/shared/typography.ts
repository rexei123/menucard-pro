/**
 * Typografie-Schema (wiederverwendbar für h1/h2/h3/body/price/meta)
 */
import type { FieldDef } from '../types';
import { FONT_OPTIONS } from './fonts';

export const TYPO_LEVELS = [
  { key: 'h1', label: 'Überschrift 1', desc: 'Titel (Kartenname, Hero)' },
  { key: 'h2', label: 'Überschrift 2', desc: 'Sektions-Titel' },
  { key: 'h3', label: 'Überschrift 3', desc: 'Produkt-Namen' },
  { key: 'body', label: 'Fließtext', desc: 'Beschreibungen' },
  { key: 'price', label: 'Preis', desc: 'Preis-Angaben' },
  { key: 'meta', label: 'Meta-Text', desc: 'Allergene, Tags, Fußnoten' },
] as const;

export type TypoLevelKey = (typeof TYPO_LEVELS)[number]['key'];

const WEIGHT_OPTIONS = [
  { label: 'Light (300)', value: '300' },
  { label: 'Normal (400)', value: '400' },
  { label: 'Medium (500)', value: '500' },
  { label: 'Semi-Bold (600)', value: '600' },
  { label: 'Bold (700)', value: '700' },
  { label: 'Extra-Bold (800)', value: '800' },
];

const TRANSFORM_OPTIONS = [
  { label: 'Keine', value: 'none' },
  { label: 'VERSALIEN', value: 'uppercase' },
  { label: 'kleinbuchstaben', value: 'lowercase' },
  { label: 'Erster Groß', value: 'capitalize' },
];

const STYLE_OPTIONS = [
  { label: 'Normal', value: 'normal' },
  { label: 'Kursiv', value: 'italic' },
];

export interface TypoLevelDefaults {
  font: string;
  size: number;
  weight: string;
  color: string;
  transform: string;
  spacing: number;
  style?: string;
}

/**
 * Liefert die 6 Felder pro Typo-Level als FieldDef-Map.
 * `style` wird nur für `body` ausgespielt (Kursiv-Toggle).
 */
export function typoLevelFields(
  defaults: TypoLevelDefaults,
  options: { includeStyle?: boolean } = {},
): Record<string, FieldDef> {
  const fields: Record<string, FieldDef> = {
    font: {
      type: 'font',
      label: 'Schrift',
      options: FONT_OPTIONS,
      default: defaults.font,
    } as any,
    size: {
      type: 'slider',
      label: 'Größe',
      min: 8,
      max: 64,
      unit: 'px',
      default: defaults.size,
    },
    weight: {
      type: 'select',
      label: 'Gewicht',
      options: WEIGHT_OPTIONS,
      default: defaults.weight,
    },
    color: {
      type: 'color',
      label: 'Farbe',
      default: defaults.color,
    },
    transform: {
      type: 'select',
      label: 'Transform',
      options: TRANSFORM_OPTIONS,
      default: defaults.transform,
    },
    spacing: {
      type: 'slider',
      label: 'Letter-Spacing',
      min: -5,
      max: 20,
      step: 1,
      unit: '%',
      default: defaults.spacing,
    },
  };
  if (options.includeStyle) {
    fields.style = {
      type: 'select',
      label: 'Stil',
      options: STYLE_OPTIONS,
      default: defaults.style ?? 'normal',
    };
  }
  return fields;
}
