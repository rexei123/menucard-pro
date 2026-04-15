#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "Fix: DigitalConfig Type-Import entfernen + ReturnType verwenden"

cat > src/lib/template-resolver.ts <<'TSEOF'
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
    const tplDigital = (menu.template.config as any).digital || {};
    return resolveDigitalConfig(tplDigital);
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
TSEOF

echo "  OK: template-resolver.ts neu geschrieben"
echo ""
echo "Build..."
npm run build 2>&1 | tail -40

echo ""
echo "pm2 restart..."
pm2 restart menucard-pro
sleep 3

echo ""
echo "--- Test Gaesteansicht ---"
curl -s -o /dev/null -w "HTTP %{http_code}\n" "http://localhost:3000/hotel-sonnblick/restaurant/jaegerabend" || echo "curl failed"

echo ""
echo "--- Test PDF ---"
MENU_ID=$(psql -t -A "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -c "SELECT id FROM \"Menu\" WHERE slug='jaegerabend' LIMIT 1")
echo "MENU_ID: $MENU_ID"
curl -s -o /tmp/test.pdf -w "HTTP %{http_code}  Size %{size_download}\n" "http://localhost:3000/api/v1/menus/$MENU_ID/pdf" || echo "curl failed"
file /tmp/test.pdf 2>/dev/null || true

echo ""
echo "FERTIG"
