/**
 * Runtime-Validator für Schema-basierte Config-Werte.
 *
 * Strategie:
 * - Unbekannte Felder werden DURCHGEREICHT (keine Fehler), damit Migrationen sanft laufen.
 * - Bekannte Felder werden typ-validiert und ggf. normalisiert.
 * - Validierung hat zwei Modi: `strict` (AI-Output) und `lenient` (User-Edits).
 */
import type {
  ComponentSchema,
  FieldDef,
  ValidationError,
  ValidationResult,
} from './types';
import { isKnownFont } from './shared/fonts';

const HEX_6 = /^#[0-9a-fA-F]{6}$/;
const HEX_8 = /^#[0-9a-fA-F]{8}$/;

export interface ValidateOptions {
  /**
   * `strict`: unbekannte Enum-Werte werden als Fehler gemeldet (AI-Output).
   * `lenient`: unbekannte Enum-Werte werden auf den Default zurückgesetzt (User-Edits).
   */
  mode?: 'strict' | 'lenient';
  /** Pfad-Präfix für Fehler-Meldungen (z.B. `digital.products`) */
  pathPrefix?: string;
}

export function validateField(
  value: unknown,
  def: FieldDef,
  field: string,
  pathPrefix: string,
): ValidationError[] {
  const errors: ValidationError[] = [];
  const path = pathPrefix ? `${pathPrefix}.${field}` : field;

  switch (def.type) {
    case 'boolean':
      if (typeof value !== 'boolean') {
        errors.push({ path, field, message: `Erwarte boolean, erhalten ${typeof value}` });
      }
      break;

    case 'select':
      if (typeof value !== 'string') {
        errors.push({ path, field, message: `Erwarte string, erhalten ${typeof value}` });
      } else if (!def.options.some((o) => o.value === value)) {
        errors.push({
          path,
          field,
          message: `Ungültiger Wert "${value}". Erlaubt: ${def.options.map((o) => o.value).join(', ')}`,
        });
      }
      break;

    case 'color':
      if (typeof value !== 'string') {
        errors.push({ path, field, message: `Erwarte HEX-Farbe, erhalten ${typeof value}` });
      } else if (!(HEX_6.test(value) || (def.allowAlpha && HEX_8.test(value)))) {
        errors.push({
          path,
          field,
          message: `Ungültiges HEX-Format "${value}" (erwarte ${def.allowAlpha ? '#RRGGBB oder #RRGGBBAA' : '#RRGGBB'})`,
        });
      }
      break;

    case 'number':
    case 'slider':
      if (typeof value !== 'number' || Number.isNaN(value)) {
        errors.push({ path, field, message: `Erwarte number, erhalten ${typeof value}` });
      } else if (value < def.min || value > def.max) {
        errors.push({
          path,
          field,
          message: `Wert ${value} liegt außerhalb [${def.min}, ${def.max}]`,
        });
      }
      break;

    case 'text':
      if (typeof value !== 'string') {
        errors.push({ path, field, message: `Erwarte string, erhalten ${typeof value}` });
      } else if (def.maxLength !== undefined && value.length > def.maxLength) {
        errors.push({
          path,
          field,
          message: `Text zu lang (${value.length} > ${def.maxLength})`,
        });
      }
      break;

    case 'font':
      if (typeof value !== 'string') {
        errors.push({ path, field, message: `Erwarte Font-Name (string), erhalten ${typeof value}` });
      } else if (!isKnownFont(value)) {
        errors.push({
          path,
          field,
          message: `Unbekannte Schrift "${value}" — nicht in Whitelist`,
        });
      }
      break;

    case 'multitoggle':
      if (!Array.isArray(value)) {
        errors.push({ path, field, message: `Erwarte string[], erhalten ${typeof value}` });
      } else {
        for (const entry of value) {
          if (typeof entry !== 'string') {
            errors.push({ path, field, message: `Array-Eintrag ist nicht string: ${typeof entry}` });
            continue;
          }
          if (!def.options.some((o) => o.value === entry)) {
            errors.push({
              path,
              field,
              message: `Unbekannter Wert "${entry}" in Multi-Toggle. Erlaubt: ${def.options.map((o) => o.value).join(', ')}`,
            });
          }
        }
      }
      break;
  }

  return errors;
}

/**
 * Validiert einen Config-Teilbaum gegen ein ComponentSchema.
 */
export function validateSchema(
  config: Record<string, any>,
  schema: ComponentSchema,
  opts: ValidateOptions = {},
): ValidationResult {
  const errors: ValidationError[] = [];
  const pathPrefix = opts.pathPrefix ?? schema.configPath.join('.');

  for (const group of schema.groups) {
    for (const [fieldKey, def] of Object.entries(group.fields)) {
      if (config[fieldKey] === undefined) continue; // fehlende Werte werden durch Defaults aufgefüllt
      errors.push(...validateField(config[fieldKey], def, fieldKey, pathPrefix));
    }
  }
  return { valid: errors.length === 0, errors };
}

/**
 * Merged Defaults mit einem Config-Objekt. Unbekannte Felder bleiben erhalten.
 */
export function applyDefaults(
  config: Record<string, any>,
  schema: ComponentSchema,
): Record<string, any> {
  const result: Record<string, any> = { ...config };
  for (const group of schema.groups) {
    for (const [fieldKey, def] of Object.entries(group.fields)) {
      if (result[fieldKey] === undefined) {
        result[fieldKey] = def.default as any;
      }
    }
  }
  return result;
}
