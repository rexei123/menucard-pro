/**
 * Config-Adapter: Bridge zwischen flachen Schema-Feldwerten und der
 * verschachtelten `DesignConfig`-Struktur.
 *
 * Hintergrund:
 *  - Jedes `ComponentSchema` hat `configPath: string[]` (z.B. `['digital','products']`)
 *    und listet Felder direkt unter diesem Pfad (z.B. `showImages`, `imageStyle`).
 *  - Einige Schemas nutzen Dot-Keys wie `icons.style` oder `badges.show` —
 *    diese zeigen auf tiefer verschachtelte Keys ab `configPath`.
 *
 * Dieses Modul macht beide Richtungen:
 *  - `extractSchemaConfig(fullConfig, schema)` → flaches Feld-Objekt für SchemaForm
 *  - `mergeSchemaConfig(fullConfig, schema, flatConfig)` → aktualisierter fullConfig
 *
 * Unbekannte Felder im Ziel-Config bleiben unangetastet.
 */
import type { ComponentSchema } from './types';

/** Gibt Wert bei `path` zurück; `undefined` wenn Pfad nicht existiert. */
export function getByPath(obj: any, path: string[]): any {
  let cur = obj;
  for (const seg of path) {
    if (cur === null || cur === undefined) return undefined;
    cur = cur[seg];
  }
  return cur;
}

/**
 * Setzt immutabel Wert bei `path`. Gibt eine neue Kopie von `obj` zurück.
 * Fehlende Zwischenobjekte werden angelegt.
 */
export function setByPath(obj: any, path: string[], value: any): any {
  if (path.length === 0) return value;
  const [head, ...rest] = path;
  const source = obj && typeof obj === 'object' && !Array.isArray(obj) ? obj : {};
  return {
    ...source,
    [head]: rest.length === 0 ? value : setByPath(source[head], rest, value),
  };
}

/** Zerlegt einen Feld-Key an Punkten: `'icons.style'` → `['icons','style']`. */
export function splitFieldKey(key: string): string[] {
  return key.split('.');
}

/**
 * Extrahiert einen flachen Schema-Config-Slice aus einer vollen DesignConfig.
 *
 * Beispiel:
 *   schema.configPath = ['digital','products']
 *   schema.groups[0].fields = { showImages: {...}, imageStyle: {...} }
 *   → { showImages: config.digital.products.showImages, imageStyle: ... }
 *
 * Dot-Keys (z.B. `icons.style`) werden relativ zu configPath aufgelöst:
 *   → config[configPath...].icons.style
 */
export function extractSchemaConfig(
  fullConfig: any,
  schema: ComponentSchema,
): Record<string, any> {
  const base = getByPath(fullConfig, schema.configPath);
  const flat: Record<string, any> = {};
  for (const group of schema.groups) {
    for (const fieldKey of Object.keys(group.fields)) {
      const path = splitFieldKey(fieldKey);
      flat[fieldKey] = getByPath(base, path);
    }
  }
  return flat;
}

/**
 * Merged einen flachen Schema-Config-Slice zurück in die volle DesignConfig.
 * Unbekannte Config-Felder bleiben erhalten; nur Schema-bekannte Felder werden überschrieben.
 */
export function mergeSchemaConfig(
  fullConfig: any,
  schema: ComponentSchema,
  flatConfig: Record<string, any>,
): any {
  let next = fullConfig ?? {};
  for (const group of schema.groups) {
    for (const fieldKey of Object.keys(group.fields)) {
      if (!(fieldKey in flatConfig)) continue;
      const absPath = [...schema.configPath, ...splitFieldKey(fieldKey)];
      next = setByPath(next, absPath, flatConfig[fieldKey]);
    }
  }
  return next;
}
