#!/bin/bash
# SCHRITT 1: DesignTemplate-Tabelle + Seed + Migration aller 9 Karten
set -e
cd /var/www/menucard-pro

echo "================================================"
echo "SCHRITT 1: Template-System Datenbank-Migration"
echo "================================================"

# --- 1. DB-Backup ---
echo ""
echo "[1/7] Datenbank-Backup..."
BACKUP_FILE="/root/menucard-pre-templates-$(date +%Y%m%d-%H%M%S).sql"
PGPASSWORD='ccTFFSJtuN7l1dC17PzT8Q' pg_dump -h 127.0.0.1 -U menucard menucard_pro > "$BACKUP_FILE"
echo "  Backup: $BACKUP_FILE ($(du -h $BACKUP_FILE | cut -f1))"

# --- 2. Prisma-Schema patchen ---
echo ""
echo "[2/7] Prisma-Schema patchen..."
cp prisma/schema.prisma prisma/schema.prisma.bak.$(date +%Y%m%d-%H%M%S)

python3 << 'PYEOF'
with open('prisma/schema.prisma', 'r') as f:
    content = f.read()

if 'model DesignTemplate' in content:
    print("  SKIP: DesignTemplate model already exists")
else:
    # Patch Menu: add templateId field + relation above designConfig
    old = '  designConfig Json?'
    new = ('  templateId   String?\n'
           '  template     DesignTemplate? @relation(fields: [templateId], references: [id], onDelete: Restrict)\n'
           '  designConfig Json?')
    if old not in content:
        raise SystemExit("ERROR: designConfig line not found in Menu model")
    content = content.replace(old, new, 1)

    # Append DesignTemplate model + enum
    append = """

model DesignTemplate {
  id         String       @id @default(cuid())
  name       String       @unique
  type       TemplateType
  baseType   String
  config     Json
  isArchived Boolean      @default(false)
  createdBy  String?
  createdAt  DateTime     @default(now())
  updatedAt  DateTime     @updatedAt
  menus      Menu[]
}

enum TemplateType {
  SYSTEM
  CUSTOM
}
"""
    content = content.rstrip() + append + '\n'

    with open('prisma/schema.prisma', 'w') as f:
        f.write(content)
    print("  OK: Schema patched")
PYEOF

# --- 3. Prisma db push ---
echo ""
echo "[3/7] Prisma db push..."
npx prisma db push --skip-generate

# --- 4. Prisma Client regenerieren ---
echo ""
echo "[4/7] Prisma generate..."
npx prisma generate

# --- 5. Seed: 4 System-Templates in DB ---
echo ""
echo "[5/7] System-Templates seeden..."
cat > prisma/seed-design-templates.ts << 'SEEDEOF'
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
    const rec = await prisma.designTemplate.upsert({
      where: { name: t.name },
      update: { type: 'SYSTEM', baseType: t.baseType, config: t.config as any, isArchived: false },
      create: { name: t.name, type: 'SYSTEM', baseType: t.baseType, config: t.config as any },
    });
    console.log('  OK:', rec.name, '->', rec.id);
  }
}

main()
  .then(() => prisma.$disconnect())
  .catch(e => { console.error(e); process.exit(1); });
SEEDEOF

npx tsx prisma/seed-design-templates.ts

# --- 6. Alle 9 Menus auf Elegant ---
echo ""
echo "[6/7] 9 Karten auf Elegant migrieren..."
PGPASSWORD='ccTFFSJtuN7l1dC17PzT8Q' psql -h 127.0.0.1 -U menucard -d menucard_pro << 'SQLEOF'
UPDATE "Menu"
SET "templateId" = (SELECT id FROM "DesignTemplate" WHERE name = 'Elegant' AND type = 'SYSTEM')
WHERE "templateId" IS NULL;
SQLEOF

# --- 7. Verifikation ---
echo ""
echo "[7/7] Verifikation..."
echo ""
echo "=== Alle Karten mit Template ==="
PGPASSWORD='ccTFFSJtuN7l1dC17PzT8Q' psql -h 127.0.0.1 -U menucard -d menucard_pro -c '
SELECT m.slug, m.type as kartentyp, t.name as template
FROM "Menu" m
LEFT JOIN "DesignTemplate" t ON m."templateId" = t.id
ORDER BY m."sortOrder";'

echo ""
echo "=== Template-Nutzung ==="
PGPASSWORD='ccTFFSJtuN7l1dC17PzT8Q' psql -h 127.0.0.1 -U menucard -d menucard_pro -c '
SELECT t.name, t.type, COUNT(m.id) as karten
FROM "DesignTemplate" t
LEFT JOIN "Menu" m ON m."templateId" = t.id
GROUP BY t.name, t.type
ORDER BY t.type, t.name;'

echo ""
echo "================================================"
echo "SCHRITT 1 ABGESCHLOSSEN"
echo "================================================"
echo "Rollback-Backup: $BACKUP_FILE"
echo ""
echo "Das Feld Menu.designConfig bleibt vorerst erhalten"
echo "(wird in Schritt 6 entfernt, damit Gaesteansicht"
echo "und PDF-Route waehrend der Umstellung nicht brechen)."
echo ""
echo "Naechste Schritte:"
echo "  - Schritt 2: API-Endpoints fuer DesignTemplate"
echo "  - Schritt 3: PDF + Gaeste-View auf templateId umstellen"
