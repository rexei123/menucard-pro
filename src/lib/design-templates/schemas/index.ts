/**
 * Schema-Registry für Design-Editor v2 (Phase 1)
 *
 * Entry-Point für den SchemaForm-Renderer und den Validator.
 * Siehe docs/DESIGN-EDITOR-SCHEMA-INVENTAR.md für Hintergrund.
 */
import type { ComponentSchema } from './types';

// ─── Einzelne Komponenten-Schemas ─────────────────────────────
import { heroSchema } from './hero';
import { sectionHeaderSchema } from './section-header';
import { itemCardSchema } from './item-card';
import { allergenLegendSchema } from './allergen-legend';
import { footerSchema } from './footer';
import { titlePageSchema } from './title-page';

// ─── Globale Konfigurations-Schemas ───────────────────────────
import { grundstilSchema, farbenSchema, typografieSchema } from './base';
import { navigationSchema } from './navigation';
import { iconsBadgesSchema } from './icons-badges';

export {
  heroSchema,
  sectionHeaderSchema,
  itemCardSchema,
  allergenLegendSchema,
  footerSchema,
  titlePageSchema,
  grundstilSchema,
  farbenSchema,
  typografieSchema,
  navigationSchema,
  iconsBadgesSchema,
};

/**
 * Liste aller 8 Komponenten-Schemas aus dem Phase-1-Scope.
 * Reihenfolge entspricht der Preview-Reihenfolge auf der Karte.
 *
 * Hinweis BeverageBlock: als Unter-Gruppe von ItemCard realisiert,
 * nicht als eigenes Schema — Schema-Inventar §5.
 */
export const COMPONENT_SCHEMAS: ComponentSchema[] = [
  heroSchema,
  sectionHeaderSchema,
  itemCardSchema,
  allergenLegendSchema,
  footerSchema,
  titlePageSchema,
];

/**
 * Liste aller globalen Schemas (Tab-Ebene im Editor).
 * Diese Schemas wirken quer über mehrere Komponenten.
 */
export const GLOBAL_SCHEMAS: ComponentSchema[] = [
  grundstilSchema,
  typografieSchema,
  farbenSchema,
  navigationSchema,
  iconsBadgesSchema,
];

/**
 * Alle Schemas (Komponenten + global) — für Tab-Generierung im Editor.
 */
export const ALL_SCHEMAS: ComponentSchema[] = [
  ...GLOBAL_SCHEMAS,
  ...COMPONENT_SCHEMAS,
];

/**
 * Lookup per ID.
 */
export function getSchemaById(id: string): ComponentSchema | undefined {
  return ALL_SCHEMAS.find((s) => s.id === id);
}

// ─── Re-Exports ───────────────────────────────────────────────
export type {
  FieldDef,
  FieldGroup,
  ComponentSchema,
  ValidationError,
  ValidationResult,
  BooleanField,
  SelectField,
  ColorField,
  NumberField,
  SliderField,
  TextField,
  FontField,
  MultiToggleField,
} from './types';

export { validateSchema, applyDefaults, validateField } from './validator';
export { FONTS, FONT_OPTIONS, isKnownFont } from './shared/fonts';
export { TYPO_LEVELS, typoLevelFields } from './shared/typography';
export {
  extractSchemaConfig,
  mergeSchemaConfig,
  getByPath,
  setByPath,
  splitFieldKey,
} from './config-adapter';
