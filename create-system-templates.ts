/**
 * Erstellt die 4 SYSTEM Design-Templates in der v2-Datenbank.
 * Verwendet upsert auf `key` (unique in v2-Schema).
 *
 * Aufruf: npx tsx scripts/create-system-templates.ts
 */
import { PrismaClient } from '@prisma/client';
import { elegantTemplate } from '../src/lib/design-templates/elegant';
import { modernTemplate } from '../src/lib/design-templates/modern';
import { classicTemplate } from '../src/lib/design-templates/classic';
import { minimalTemplate } from '../src/lib/design-templates/minimal';

const prisma = new PrismaClient();

const TEMPLATES = [
  { key: 'elegant',  name: 'Elegant',   baseType: 'elegant',  config: elegantTemplate },
  { key: 'modern',   name: 'Modern',    baseType: 'modern',   config: modernTemplate },
  { key: 'classic',  name: 'Klassisch', baseType: 'classic',  config: classicTemplate },
  { key: 'minimal',  name: 'Minimal',   baseType: 'minimal',  config: minimalTemplate },
];

async function main() {
  console.log('=== Create SYSTEM Design-Templates (v2) ===\n');
  for (const t of TEMPLATES) {
    const result = await prisma.designTemplate.upsert({
      where: { key: t.key },
      update: {
        name: t.name,
        type: 'SYSTEM',
        baseType: t.baseType,
        config: t.config as any,
        isArchived: false,
      },
      create: {
        key: t.key,
        name: t.name,
        type: 'SYSTEM',
        baseType: t.baseType,
        config: t.config as any,
        isArchived: false,
      },
    });
    console.log(`  ${t.key.padEnd(10)} -> ${result.id} (${result.name})`);
  }

  const count = await prisma.designTemplate.count();
  console.log(`\nFertig. ${count} Templates in DB.`);
}

main()
  .catch((e) => {
    console.error('FEHLER:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
