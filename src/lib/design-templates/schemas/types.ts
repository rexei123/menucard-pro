/**
 * Schema-System für Design-Editor v2 (Phase 1)
 *
 * Feldtypen und Strukturen für schema-driven UI-Generierung.
 * Siehe docs/DESIGN-EDITOR-SCHEMA-INVENTAR.md für Kontext.
 */

// ─── Field Definitions ────────────────────────────────────────────

export interface FieldDefBase {
  label: string;
  desc?: string;
  /** Feld wird nur angezeigt, wenn Callback true liefert (config → relevant?) */
  visibleIf?: (config: Record<string, any>) => boolean;
}

export interface BooleanField extends FieldDefBase {
  type: 'boolean';
  default: boolean;
}

export interface SelectOption {
  label: string;
  value: string;
}

export interface SelectField extends FieldDefBase {
  type: 'select';
  options: SelectOption[];
  default: string;
}

export interface ColorField extends FieldDefBase {
  type: 'color';
  default: string;
  /** `true` erlaubt 8-stellige Hex-Werte mit Alpha */
  allowAlpha?: boolean;
}

export interface NumberField extends FieldDefBase {
  type: 'number';
  min: number;
  max: number;
  step?: number;
  unit?: string;
  default: number;
}

export interface SliderField extends FieldDefBase {
  type: 'slider';
  min: number;
  max: number;
  step?: number;
  unit?: string;
  default: number;
}

export interface TextField extends FieldDefBase {
  type: 'text';
  default: string;
  maxLength?: number;
  placeholder?: string;
  /** Multiline = Textarea statt Input */
  multiline?: boolean;
}

export interface FontField extends FieldDefBase {
  type: 'font';
  default: string;
}

export interface MultiToggleField extends FieldDefBase {
  type: 'multitoggle';
  options: SelectOption[];
  default: string[];
}

export type FieldDef =
  | BooleanField
  | SelectField
  | ColorField
  | NumberField
  | SliderField
  | TextField
  | FontField
  | MultiToggleField;

// ─── Component Schema ────────────────────────────────────────────

export interface FieldGroup {
  id: string;
  label: string;
  desc?: string;
  fields: Record<string, FieldDef>;
}

export interface ComponentSchema {
  /** Stable ID, nutzt als Key in Config + URL-Param */
  id: string;
  /** UI-Label (DE) */
  label: string;
  /** Icon-Name (Material Symbols Outlined) */
  icon?: string;
  /** Kurzbeschreibung für Editor-Tooltip */
  desc?: string;
  /** Config-Pfad innerhalb von `DesignConfig` (z.B. `['digital','products']`) */
  configPath: string[];
  /** Feldgruppen mit Labels + Feld-Definitionen */
  groups: FieldGroup[];
}

// ─── Validation ────────────────────────────────────────────

export interface ValidationError {
  path: string;
  field: string;
  message: string;
}

export interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
}

// ─── Utility Types ────────────────────────────────────────────

/**
 * Extrahiert den TS-Typ pro Feld-Definition.
 * z.B. `FieldValue<BooleanField> = boolean`
 */
export type FieldValue<T extends FieldDef> =
  T extends BooleanField ? boolean :
  T extends SelectField ? string :
  T extends ColorField ? string :
  T extends NumberField ? number :
  T extends SliderField ? number :
  T extends TextField ? string :
  T extends FontField ? string :
  T extends MultiToggleField ? string[] :
  never;

/**
 * Wandelt eine Feld-Map in eine Config-Map (typed values).
 */
export type ConfigFromFields<F extends Record<string, FieldDef>> = {
  [K in keyof F]: FieldValue<F[K]>;
};
