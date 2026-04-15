#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "[1/3] /api/v1/menus komplett neu schreiben (mit template)..."
cat > src/app/api/v1/menus/route.ts <<'TSEOF'
import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export async function GET() {
  try {
    const menus = await prisma.menu.findMany({
      where: { isArchived: false },
      include: {
        translations: { where: { languageCode: 'de' }, take: 1 },
        template: { select: { id: true, name: true, baseType: true } },
      },
      orderBy: { sortOrder: 'asc' },
    });
    const result = menus.map((m: any) => ({
      id: m.id,
      slug: m.slug,
      name: m.translations[0]?.name || m.slug,
      menuType: m.type,
      designConfig: m.designConfig,
      templateId: m.templateId,
      template: m.template,
      isActive: m.isActive,
    }));
    return NextResponse.json(result);
  } catch (error: any) {
    console.error('GET /api/v1/menus error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
TSEOF
echo "  OK"

echo ""
echo "[2/3] Werkstatt-Seite patchen (falls noch nicht geschehen)..."
# Wurde im vorigen Lauf abgebrochen. Idempotent pruefen.
if grep -q "menu.template?.baseType" src/app/admin/design/page.tsx; then
  echo "  Bereits gepatcht."
else
  cp src/app/admin/design/page.tsx src/app/admin/design/page.tsx.bak
  python3 <<'PYEOF'
path = 'src/app/admin/design/page.tsx'
with open(path, 'r', encoding='utf-8') as f:
    src = f.read()

old_type = """type Menu = {
  id: string;
  name: string;
  slug: string;
  menuType: string;
  designConfig: any;
};"""
new_type = """type Menu = {
  id: string;
  name: string;
  slug: string;
  menuType: string;
  designConfig: any;
  templateId?: string | null;
  template?: { id: string; name: string; baseType: string } | null;
};"""
if old_type not in src:
    raise SystemExit('Patch A fehlgeschlagen')
src = src.replace(old_type, new_type, 1)

old_fn = """function getActiveTemplate(menu: Menu): string {
  try {
    const dc = menu.designConfig;
    return dc?.digital?.template || dc?.template || 'elegant';
  } catch {
    return 'elegant';
  }
}"""
new_fn = """function getActiveTemplate(menu: Menu): string {
  if (menu.template?.baseType) return menu.template.baseType;
  try {
    const dc = menu.designConfig;
    return dc?.digital?.template || dc?.template || 'elegant';
  } catch {
    return 'elegant';
  }
}"""
if old_fn not in src:
    raise SystemExit('Patch B fehlgeschlagen')
src = src.replace(old_fn, new_fn, 1)

with open(path, 'w', encoding='utf-8') as f:
    f.write(src)
print('  OK: Werkstatt gepatcht')
PYEOF
fi

echo ""
echo "[3/3] Build + Restart..."
npm run build 2>&1 | tail -20
pm2 restart menucard-pro
sleep 3

echo ""
echo "================================================"
echo "FERTIG. /admin/design neu laden (Strg+Shift+R)."
echo "Elegant sollte 9 zeigen, andere 0."
echo "================================================"
