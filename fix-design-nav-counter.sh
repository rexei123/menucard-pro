#!/bin/bash
set -e
echo "============================================"
echo "  Fix: Design-Nav + Template-Zaehler"
echo "============================================"

cd /var/www/menucard-pro

cp src/components/admin/menu-editor.tsx src/components/admin/menu-editor.tsx.bak-designbtn

# ============================================
# 1. API-Endpoint /api/v1/menus (GET) anlegen
# ============================================
echo "[1/3] API-Endpoint /api/v1/menus GET anlegen..."

cat > src/app/api/v1/menus/route.ts << 'EOF'
import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export async function GET() {
  try {
    const menus = await prisma.menu.findMany({
      where: { isArchived: false },
      include: {
        translations: { where: { languageCode: 'de' }, take: 1 },
      },
      orderBy: { sortOrder: 'asc' },
    });

    const result = menus.map(m => ({
      id: m.id,
      slug: m.slug,
      name: m.translations[0]?.name || m.slug,
      menuType: m.type,
      designConfig: m.designConfig,
      isActive: m.isActive,
    }));

    return NextResponse.json(result);
  } catch (err) {
    console.error('[GET /api/v1/menus]', err);
    return NextResponse.json({ error: 'Fehler beim Laden' }, { status: 500 });
  }
}
EOF

echo "  Endpoint angelegt"

# ============================================
# 2. menu-editor.tsx: Design-Button oben einfuegen
# ============================================
echo "[2/3] Design-Button im Karten-Editor einfuegen..."

# Gezielter Patch: Nur den Button-Block ersetzen (genau 1 Vorkommen)
python3 << 'PY'
path = 'src/components/admin/menu-editor.tsx'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old = '''            <div className="flex gap-2">
              <a href={menu.publicUrl} target="_blank" className="rounded-lg border px-3 py-1.5 text-sm font-medium hover:bg-gray-50">Vorschau &#8599;</a>
              <span className={`rounded-full px-3 py-1.5 text-sm font-medium ${menu.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>{menu.isActive ? 'Aktiv' : 'Inaktiv'}</span>
            </div>'''

new = '''            <div className="flex gap-2">
              <a href={menu.publicUrl} target="_blank" className="rounded-lg border px-3 py-1.5 text-sm font-medium hover:bg-gray-50">Vorschau &#8599;</a>
              <Link
                href={`/admin/menus/${menu.id}/design`}
                className="rounded-lg px-3 py-1.5 text-sm font-medium inline-flex items-center gap-1 transition-colors"
                style={{
                  border: '1px solid var(--color-primary)',
                  color: 'var(--color-primary)',
                  backgroundColor: 'transparent',
                }}
                onMouseEnter={e => { e.currentTarget.style.backgroundColor = 'rgba(221,60,113,0.08)'; }}
                onMouseLeave={e => { e.currentTarget.style.backgroundColor = 'transparent'; }}
              >
                <span className="material-symbols-outlined" style={{ fontSize: 16, fontVariationSettings: "'FILL' 0, 'wght' 500" }}>palette</span>
                Design
              </Link>
              <span className={`rounded-full px-3 py-1.5 text-sm font-medium ${menu.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>{menu.isActive ? 'Aktiv' : 'Inaktiv'}</span>
            </div>'''

if old not in content:
    print('FEHLER: Anker-Block nicht gefunden!')
    exit(1)

content = content.replace(old, new, 1)
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('  Design-Button eingefuegt')
PY

# ============================================
# 3. Build
# ============================================
echo "[3/3] Build..."
rm -rf .next
npm run build 2>&1 | tail -5
pm2 restart menucard-pro

echo ""
echo "============================================"
echo "  Fertig:"
echo "  - GET /api/v1/menus liefert Karten-Liste"
echo "  - Template-Uebersicht zaehlt korrekt"
echo "  - Design-Button im Karten-Editor (rosa)"
echo "============================================"
