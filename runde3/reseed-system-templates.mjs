#!/usr/bin/env node
/**
 * Runde 3 – Reseed der SYSTEM Design-Templates in der Datenbank.
 *
 * Hintergrund:
 *   Die Datei src/lib/design-templates/modern.ts (und minimal.ts) wurde
 *   geaendert (Inter -> Montserrat / Space Grotesk).
 *   Die SYSTEM-Eintraege in DesignTemplate.config wurden beim allerersten
 *   Seed mit den alten Inter-Werten befuellt. Da die App zur Laufzeit die
 *   DB-Config liest (nicht die TS-Datei), muss die DB aktualisiert werden.
 *
 * Was passiert:
 *   - Liest die 4 SYSTEM-Templates (elegant, modern, classic, minimal)
 *     aus den TS-Files.
 *   - UPDATEt deren `config`-Feld in der Postgres-Tabelle "DesignTemplate"
 *     fuer alle Eintraege mit type='SYSTEM' und passendem baseType.
 *   - CUSTOM-Templates bleiben unberuehrt.
 *
 * Aufruf (auf dem Server, im App-Verzeichnis /var/www/menucard-pro):
 *   node runde3/reseed-system-templates.mjs
 */
import { PrismaClient } from '@prisma/client';

// require() funktioniert in .mjs nur via createRequire
import { createRequire } from 'module';
const require = createRequire(import.meta.url);

const { elegantTemplate } = require('./src/lib/design-templates/elegant.ts');
const { modernTemplate } = require('./src/lib/design-templates/modern.ts');
const { classicTemplate } = require('./src/lib/design-templates/classic.ts');
const { minimalTemplate } = require('./src/lib/design-templates/minimal.ts');

const prisma = new PrismaClient();

const TEMPLATES = {
  elegant: elegantTemplate,
  modern: modernTemplate,
  classic: classicTemplate,
  minimal: minimalTemplate,
};

async function main() {
  console.log('=== Reseed SYSTEM Design-Templates ===\n');
  for (const [baseType, config] of Object.entries(TEMPLATES)) {
    const result = await prisma.designTemplate.updateMany({
      where: { type: 'SYSTEM', baseType },
      data: { config },
    });
    console.log(`  ${baseType.padEnd(10)} -> ${result.count} Datensaetze aktualisiert`);
  }
  console.log('\nFertig.');
}

main()
  .catch(e => {
    console.error('FEHLER beim Reseed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
