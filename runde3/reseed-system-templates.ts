/**
 * Runde 3 – Reseed der SYSTEM Design-Templates in der Datenbank.
 *
 * Aufruf (auf dem Server, /var/www/menucard-pro):
 *   npx tsx runde3/reseed-system-templates.ts
 *
 * Aktualisiert die `config`-Spalte aller SYSTEM-Templates (elegant, modern,
 * classic, minimal) mit den aktuellen Inhalten aus src/lib/design-templates/*.ts.
 * CUSTOM-Templates bleiben unangetastet.
 */
import { PrismaClient } from '@prisma/client';
import { elegantTemplate } from '../src/lib/design-templates/elegant';
import { modernTemplate } from '../src/lib/design-templates/modern';
import { classicTemplate } from '../src/lib/design-templates/classic';
import { minimalTemplate } from '../src/lib/design-templates/minimal';

const prisma = new PrismaClient();

const TEMPLATES: Record<string, any> = {
  elegant: elegantTemplate,
  modern: modernTemplate,
  classic: classicTemplate,
  minimal: minimalTemplate,
};

async function main() {
  console.log('=== Reseed SYSTEM Design-Templates ===\n');
  for (const [baseType, config] of Object.entries(TEMPLATES)) {
    const result = await prisma.designTemplate.updateMany({
      where: { type: 'SYSTEM' as any, baseType },
      data: { config },
    });
    console.log(`  ${baseType.padEnd(10)} -> ${result.count} Datensaetze aktualisiert`);
  }
  console.log('\nFertig.');
}

main()
  .catch((e) => {
    console.error('FEHLER beim Reseed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
