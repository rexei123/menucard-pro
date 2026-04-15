#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "================================================"
echo "SCHRITT 1 FIX: Schema in richtiges Modell patchen"
echo "================================================"

echo "[1/6] Schema bereinigen (falsche Einfuegung in Location entfernen + korrekt in Menu einfuegen)..."

python3 <<'PYEOF'
import re

with open('prisma/schema.prisma', 'r', encoding='utf-8') as f:
    schema = f.read()

# Schritt A: DesignTemplate-Model und TemplateType-Enum entfernen (werden spaeter neu angehaengt)
schema = re.sub(r'\nmodel DesignTemplate \{.*?\n\}\n', '\n', schema, flags=re.DOTALL)
schema = re.sub(r'\nenum TemplateType \{[^}]*\}\n', '\n', schema)

# Schritt B: Alle versehentlich eingefuegten templateId/template-Zeilen entfernen
schema = re.sub(r'\n  templateId   String\?\n  template     DesignTemplate\? @relation\(fields: \[templateId\], references: \[id\], onDelete: Restrict\)\n', '\n', schema)
schema = re.sub(r'\n  templateId\s+String\?\n  template\s+DesignTemplate\? @relation\(fields: \[templateId\], references: \[id\], onDelete: Restrict\)\n', '\n', schema)

# Schritt C: templateId + template gezielt in das Menu-Modell einfuegen (vor designConfig im Menu)
# Wir finden das Menu-Modell und patchen NUR dort
menu_pattern = re.compile(r'(model Menu \{[^}]*?)(\n  designConfig Json\?)', re.DOTALL)
match = menu_pattern.search(schema)
if not match:
    raise SystemExit('ERROR: Menu model mit designConfig nicht gefunden')

insert = '\n  templateId   String?\n  template     DesignTemplate? @relation(fields: [templateId], references: [id], onDelete: Restrict)'
schema = schema[:match.end(1)] + insert + schema[match.end(1):]

# Schritt D: DesignTemplate-Model und Enum am Ende anhaengen (mit Back-Relation auf Menu)
append = '''

enum TemplateType {
  SYSTEM
  CUSTOM
}

model DesignTemplate {
  id         String       @id @default(cuid())
  name       String       @unique
  type       TemplateType @default(CUSTOM)
  baseType   String
  config     Json
  isArchived Boolean      @default(false)
  createdBy  String?
  createdAt  DateTime     @default(now())
  updatedAt  DateTime     @updatedAt
  menus      Menu[]
}
'''

if 'model DesignTemplate' not in schema:
    schema = schema.rstrip() + append + '\n'

with open('prisma/schema.prisma', 'w', encoding='utf-8') as f:
    f.write(schema)

print('  OK: Schema korrigiert')
PYEOF

echo ""
echo "[2/6] Verifikation der Einfuegestellen..."
echo "--- Menu-Modell (templateId muss hier sein) ---"
grep -A 2 "templateId" prisma/schema.prisma | head -20
echo ""
echo "--- DesignTemplate + Enum ---"
tail -25 prisma/schema.prisma
echo ""

echo "[3/6] Prisma db push..."
npx prisma db push --skip-generate

echo ""
echo "[4/6] Prisma generate..."
npx prisma generate

echo ""
echo "[5/6] Seed-Script erstellen und ausfuehren..."
cat > prisma/seed-design-templates.ts <<'TSEOF'
import { PrismaClient } from '@prisma/client';
import { elegantTemplate } from '../src/lib/design-templates/elegant';
import { modernTemplate } from '../src/lib/design-templates/modern';
import { classicTemplate } from '../src/lib/design-templates/classic';
import { minimalTemplate } from '../src/lib/design-templates/minimal';

const prisma = new PrismaClient();

async function main() {
  const items = [
    { name: 'Elegant',   baseType: 'elegant', config: elegantTemplate },
    { name: 'Modern',    baseType: 'modern',  config: modernTemplate },
    { name: 'Klassisch', baseType: 'classic', config: classicTemplate },
    { name: 'Minimal',   baseType: 'minimal', config: minimalTemplate },
  ];
  for (const t of items) {
    await prisma.designTemplate.upsert({
      where: { name: t.name },
      update: { type: 'SYSTEM', baseType: t.baseType, config: t.config as any, isArchived: false },
      create: { name: t.name, type: 'SYSTEM', baseType: t.baseType, config: t.config as any },
    });
    console.log('  Seeded:', t.name);
  }
}

main().then(() => prisma.$disconnect()).catch(async (e) => {
  console.error(e);
  await prisma.$disconnect();
  process.exit(1);
});
TSEOF

npx tsx prisma/seed-design-templates.ts

echo ""
echo "[6/6] Alle 9 Karten auf Elegant-Template migrieren..."
psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" <<'SQLEOF'
UPDATE "Menu"
SET "templateId" = (SELECT id FROM "DesignTemplate" WHERE name = 'Elegant')
WHERE "templateId" IS NULL;

SELECT
  m.slug,
  m.name,
  dt.name AS template
FROM "Menu" m
LEFT JOIN "DesignTemplate" dt ON m."templateId" = dt.id
ORDER BY m.slug;

SELECT
  dt.name AS template,
  dt.type,
  COUNT(m.id) AS menu_count
FROM "DesignTemplate" dt
LEFT JOIN "Menu" m ON m."templateId" = dt.id
GROUP BY dt.name, dt.type
ORDER BY dt.name;
SQLEOF

echo ""
echo "================================================"
echo "SCHRITT 1 ABGESCHLOSSEN"
echo "================================================"
