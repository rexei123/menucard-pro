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
    // DesignTemplate.config hat Struktur `{ digital: {...}, analog: {...} }`.
    // resolveDigitalConfig erwartet genau diese Root-Struktur — nicht `.digital` auspacken!
    // baseType entscheidet, welches Hardcoded-Template als Defaults-Fallback dient.
    const tplConfig = menu.template.config as any;
    const baseName = menu.template.baseType || tplConfig?.digital?.template || 'minimal';
    const base = getTemplate(baseName);
    return mergeConfig(base.digital, tplConfig?.digital || {});
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
