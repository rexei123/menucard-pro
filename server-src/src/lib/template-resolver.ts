/**
 * Liefert die effektive Design-Config einer Karte.
 *
 * Priorisierung:
 *   1. menu.template.config   (neue DB-basierte Vorlagen, SYSTEM + CUSTOM)
 *   2. menu.designConfig      (Legacy-Feld, wird in Schritt 6 entfernt)
 *   3. leeres Objekt          (Fallback, der resolveDigitalConfig dann mit Defaults fuellt)
 *
 * Die Struktur der DB-Config entspricht 1:1 den Template-Dateien in
 * src/lib/design-templates/*.ts (seed-design-templates.ts).
 *
 * --- BUGFIX Runde 3 (14.04.2026) ---
 * resolveDigitalConfig() erwartet das WRAPPER-Objekt { digital: {...} } und
 * liest darin selbst designConfig?.digital?.template. Vorher wurde irrtuemlich
 * das innere `digital`-Objekt uebergeben, wodurch template?.template == undefined
 * war und IMMER auf 'elegant' zurueckgefallen wurde. Modern/Minimal/Classic
 * konnten ihre Fonts/Farben deshalb nicht rendern.
 */
import { resolveDigitalConfig, configToCssVars } from './design-config-reader';
import { getTemplate, mergeConfig, type AnalogConfig } from './design-templates';

type MenuWithTemplate = {
  templateId?: string | null;
  template?: { baseType: string; config: any } | null;
  designConfig?: any;
};

export function resolveMenuDigitalConfig(menu: MenuWithTemplate): ReturnType<typeof resolveDigitalConfig> {
  if (menu.template?.config) {
    // FIX: vollstaendige Wrapper-Config uebergeben, nicht das innere digital-Objekt.
    return resolveDigitalConfig(menu.template.config);
  }
  return resolveDigitalConfig(menu.designConfig);
}

export function resolveMenuAnalogConfig(menu: MenuWithTemplate): AnalogConfig {
  if (menu.template?.config) {
    const tplConfig = menu.template.config as any;
    const baseName = menu.template.baseType || 'elegant';
    const base = getTemplate(baseName);
    return mergeConfig(base.analog, tplConfig.analog);
  }

  const saved = (menu.designConfig || {}) as any;
  const baseName = saved?.analog?.template || saved?.digital?.template || 'elegant';
  const base = getTemplate(baseName);
  return mergeConfig(base.analog, saved?.analog);
}

export { configToCssVars };
