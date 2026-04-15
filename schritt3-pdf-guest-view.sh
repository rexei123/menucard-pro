#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "================================================"
echo "SCHRITT 3: PDF + Gaesteansicht auf templateId"
echo "================================================"

# Backups
cp src/app/api/v1/menus/\[id\]/pdf/route.ts src/app/api/v1/menus/\[id\]/pdf/route.ts.bak
cp "src/app/(public)/[tenant]/[location]/[menu]/page.tsx" "src/app/(public)/[tenant]/[location]/[menu]/page.tsx.bak"
echo "  Backups erstellt"

# ==============================================================
# 1) Helper: src/lib/template-resolver.ts
# ==============================================================
echo ""
echo "[1/4] Helper src/lib/template-resolver.ts erstellen..."
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
import { resolveDigitalConfig, configToCssVars, type DigitalConfig } from './design-config-reader';
import { getTemplate, mergeConfig, type AnalogConfig } from './design-templates';

type MenuWithTemplate = {
  templateId?: string | null;
  template?: { baseType: string; config: any } | null;
  designConfig?: any;
};

export function resolveMenuDigitalConfig(menu: MenuWithTemplate): DigitalConfig {
  if (menu.template?.config) {
    const tplDigital = (menu.template.config as any).digital || {};
    return resolveDigitalConfig(tplDigital);
  }
  return resolveDigitalConfig(menu.designConfig);
}

export function resolveMenuAnalogConfig(menu: MenuWithTemplate): AnalogConfig {
  // Neuer Weg: Template direkt aus DB
  if (menu.template?.config) {
    const tplConfig = menu.template.config as any;
    const baseName = menu.template.baseType || 'elegant';
    const base = getTemplate(baseName);
    // Wenn DB-Template eigene analog-Config hat, diese als Overlay nutzen
    return mergeConfig(base.analog, tplConfig.analog);
  }

  // Legacy-Weg: Alte designConfig
  const saved = (menu.designConfig || {}) as any;
  const baseName = saved?.analog?.template || saved?.digital?.template || 'elegant';
  const base = getTemplate(baseName);
  return mergeConfig(base.analog, saved?.analog);
}

export { configToCssVars };
TSEOF
echo "  OK: Helper"

# ==============================================================
# 2) PDF-Route neu
# ==============================================================
echo ""
echo "[2/4] PDF-Route neu schreiben..."
cat > src/app/api/v1/menus/\[id\]/pdf/route.ts <<'TSEOF'
import { NextRequest, NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { renderToBuffer } from '@react-pdf/renderer';
import { MenuPdfDocument } from '@/lib/pdf/menu-pdf';
import { resolveMenuAnalogConfig } from '@/lib/template-resolver';
import React from 'react';

// Dateiname ASCII-sicher machen für Content-Disposition
function sanitizeFilename(name: string): string {
  return name
    .replace(/ä/g, 'ae').replace(/ö/g, 'oe').replace(/ü/g, 'ue')
    .replace(/Ä/g, 'Ae').replace(/Ö/g, 'Oe').replace(/Ü/g, 'Ue')
    .replace(/ß/g, 'ss')
    .replace(/[^a-zA-Z0-9._\- ]/g, '')
    .trim();
}

// GET /api/v1/menus/[id]/pdf – PDF generieren
export async function GET(_req: NextRequest, { params }: { params: { id: string } }) {
  try {
    const menu = await prisma.menu.findUnique({
      where: { id: params.id },
      include: {
        translations: true,
        template: true,
        location: {
          include: { tenant: true },
        },
        sections: {
          where: { isActive: true },
          orderBy: { sortOrder: 'asc' },
          include: {
            translations: true,
            placements: {
              where: { isVisible: true },
              orderBy: { sortOrder: 'asc' },
              include: {
                product: {
                  include: {
                    translations: true,
                    prices: {
                      include: { fillQuantity: true },
                      orderBy: { sortOrder: 'asc' },
                    },
                    productWineProfile: true,
                    productMedia: {
                      where: { isPrimary: true },
                      take: 1,
                    },
                  },
                },
              },
            },
          },
        },
      },
    });
    if (!menu) {
      return NextResponse.json({ error: 'Menu not found' }, { status: 404 });
    }

    // Resolve analog config (neu: templateId bevorzugt, Fallback designConfig)
    const analogConfig = resolveMenuAnalogConfig(menu as any);

    const menuNameDE = menu.translations.find(t => t.languageCode === 'de')?.name || menu.slug;
    const menuNameEN = menu.translations.find(t => t.languageCode === 'en')?.name || undefined;

    // Transform sections
    const sections = menu.sections
      .map(section => {
        const sDE = section.translations.find(t => t.languageCode === 'de');
        const sEN = section.translations.find(t => t.languageCode === 'en');
        const products = section.placements
          .filter(pl => pl.product.status !== 'ARCHIVED')
          .map(pl => {
            const p = pl.product;
            const tDE = p.translations.find(t => t.languageCode === 'de');
            const tEN = p.translations.find(t => t.languageCode === 'en');
            const wp = p.productWineProfile;
            const nameParts: string[] = [tDE?.name || ''];
            if (wp?.grapeVarieties?.length) nameParts.push(wp.grapeVarieties.join(', '));
            if (wp?.appellation) nameParts.push(wp.appellation);
            const prices = p.prices.map(pp => ({
              label: pp.fillQuantity?.label || '',
              price: pl.priceOverride ? Number(pl.priceOverride) : Number(pp.price),
              volume: pp.fillQuantity?.volume || undefined,
            }));
            return {
              id: p.id,
              name: nameParts.filter(Boolean).join('  '),
              nameEN: tEN?.name || undefined,
              shortDescription: tDE?.shortDescription || undefined,
              shortDescriptionEN: tEN?.shortDescription || undefined,
              longDescription: tDE?.longDescription || undefined,
              longDescriptionEN: tEN?.longDescription || undefined,
              prices,
              winery: wp?.winery || undefined,
              wineryLocation: wp?.region || undefined,
              vintage: wp?.vintage || undefined,
              grapeVarieties: wp?.grapeVarieties || undefined,
              region: wp?.region || undefined,
              country: wp?.country || undefined,
              appellation: wp?.appellation || undefined,
              style: wp?.style || undefined,
              isHighlight: p.isHighlight,
              highlightType: pl.highlightType || p.highlightType || undefined,
            };
          });
        return {
          id: section.id,
          name: sDE?.name || section.slug,
          nameEN: sEN?.name || undefined,
          description: sDE?.description || undefined,
          descriptionEN: sEN?.description || undefined,
          icon: section.icon || undefined,
          products,
        };
      })
      .filter(s => s.products.length > 0);

    const element = React.createElement(MenuPdfDocument, {
      menuName: menuNameDE,
      menuNameEN,
      sections,
      config: analogConfig,
      tenantName: menu.location.tenant.name,
      locationName: menu.location.name,
    });
    const buffer = await renderToBuffer(element as any);
    const filename = `${menuNameDE.replace(/[^a-zA-Z0-9äöüÄÖÜß\-_ ]/g, '')}.pdf`;
    return new NextResponse(new Uint8Array(buffer), {
      headers: {
        'Content-Type': 'application/pdf',
        'Content-Disposition': `inline; filename="${sanitizeFilename(filename)}"; filename*=UTF-8''${encodeURIComponent(filename)}`,
        'Cache-Control': 'no-cache',
      },
    });
  } catch (error: any) {
    console.error('PDF generation error:', error);
    return NextResponse.json(
      { error: 'PDF generation failed', details: error.message },
      { status: 500 }
    );
  }
}
TSEOF
echo "  OK: PDF-Route"

# ==============================================================
# 3) Gaesteansicht patchen (chirurgisch, KEIN Regex)
# ==============================================================
echo ""
echo "[3/4] Gaesteansicht patchen..."

python3 <<'PYEOF'
path = 'src/app/(public)/[tenant]/[location]/[menu]/page.tsx'
with open(path, 'r', encoding='utf-8') as f:
    src = f.read()

# Patch A: Import austauschen
old_import = "import { resolveDigitalConfig, configToCssVars } from '@/lib/design-config-reader';"
new_import = "import { resolveMenuDigitalConfig, configToCssVars } from '@/lib/template-resolver';"
if old_import not in src:
    raise SystemExit('Patch A fehlgeschlagen: Import nicht gefunden')
src = src.replace(old_import, new_import, 1)

# Patch B: include: { translations: true, erweitern -> + template: true,
# Wir suchen nach der exakten Stelle im prisma.menu.findUnique call
old_include_head = "    include: {\n      translations: true,\n      sections: { where: { isActive: true }"
new_include_head = "    include: {\n      translations: true,\n      template: true,\n      sections: { where: { isActive: true }"
if old_include_head not in src:
    raise SystemExit('Patch B fehlgeschlagen: include-Block nicht exakt gefunden')
src = src.replace(old_include_head, new_include_head, 1)

# Patch C: resolveDigitalConfig(menu.designConfig) -> resolveMenuDigitalConfig(menu)
old_resolve = "const digitalConfig = resolveDigitalConfig(menu.designConfig);"
new_resolve = "const digitalConfig = resolveMenuDigitalConfig(menu as any);"
if old_resolve not in src:
    raise SystemExit('Patch C fehlgeschlagen: resolveDigitalConfig-Aufruf nicht gefunden')
src = src.replace(old_resolve, new_resolve, 1)

with open(path, 'w', encoding='utf-8') as f:
    f.write(src)

print('  OK: 3 Patches angewendet')
PYEOF

# ==============================================================
# 4) Build + Restart + Test
# ==============================================================
echo ""
echo "[4/4] Build..."
npm run build 2>&1 | tail -30

echo ""
echo "pm2 restart..."
pm2 restart menucard-pro
sleep 2

echo ""
echo "--- Test: Gaesteansicht (Jaegerabend) ---"
curl -s -o /dev/null -w "HTTP %{http_code}\n" "http://localhost:3000/hotel-sonnblick/restaurant/jaegerabend"

echo ""
echo "--- Test: PDF-Route (Jaegerabend) ---"
MENU_ID=$(psql -t -A "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" -c "SELECT id FROM \"Menu\" WHERE slug='jaegerabend' LIMIT 1")
echo "  MENU_ID: $MENU_ID"
curl -s -o /tmp/test.pdf -w "HTTP %{http_code}  Size %{size_download}\n" "http://localhost:3000/api/v1/menus/$MENU_ID/pdf"
file /tmp/test.pdf

echo ""
echo "================================================"
echo "SCHRITT 3 ABGESCHLOSSEN"
echo "================================================"
