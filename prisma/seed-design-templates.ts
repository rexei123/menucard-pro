/**
 * Seed der SYSTEM-Templates.
 *
 * Stand 20.04.2026:
 *  • Aktives SYSTEM-Template: minimal (Never-Fail-Fallback, immer sichtbar)
 *  • elegant/modern/classic werden nicht mehr aktiv geseeded. Sie bleiben
 *    in der DB erhalten (fuer Legacy-Zugriffe), werden aber ueber das
 *    Script `scripts/archive-legacy-system-templates.ts` einmalig auf
 *    `isArchived=true` gesetzt. Der Seed fasst sie nicht an — damit kann
 *    jemand sie bei Bedarf auch wieder reaktivieren (isArchived=false)
 *    ohne dass der naechste Deploy das ueberschreibt.
 *
 * Das Script ist idempotent und kann beliebig oft ausgefuehrt werden.
 */
import { PrismaClient } from '@prisma/client';
import { minimalTemplate } from '../src/lib/design-templates/minimal';

const prisma = new PrismaClient();

async function main() {
  await prisma.designTemplate.upsert({
    where: { key: 'minimal' },
    update: {
      name: 'Minimal',
      type: 'SYSTEM',
      baseType: 'minimal',
      config: minimalTemplate as any,
      isArchived: false,
    },
    create: {
      key: 'minimal',
      name: 'Minimal',
      type: 'SYSTEM',
      baseType: 'minimal',
      config: minimalTemplate as any,
      isArchived: false,
    },
  });
  console.log('  Seeded: Minimal (aktiv, Never-Fail-Fallback)');
}

main()
  .then(() => prisma.$disconnect())
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });
