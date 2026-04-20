/**
 * Archiviert die Alt-SYSTEM-Templates (elegant/modern/classic).
 *
 * Hintergrund:
 *  Ab 20.04.2026 ist MINIMAL das einzige sichtbare SYSTEM-Template. Es fungiert
 *  als "Never-Fail"-Fallback und Basis für alle CUSTOM-Templates. Die drei
 *  alten SYSTEM-Templates bleiben für Rollback-Sicherheit in der DB, werden
 *  aber aus der UI ausgeblendet (isArchived=true).
 *
 * Bedingung: Keine Karte darf noch auf ein zu archivierendes Template zeigen,
 *            sonst würde der Picker das Template nicht mehr auflösen können.
 *            Das Script bricht in diesem Fall mit einer Warnung ab.
 *
 * Ausführung:
 *   npx tsx scripts/archive-legacy-system-templates.ts            # Dry-Run
 *   npx tsx scripts/archive-legacy-system-templates.ts --apply    # Live
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const LEGACY_KEYS = ['elegant', 'modern', 'classic'];

async function main() {
  const apply = process.argv.includes('--apply');
  const mode = apply ? 'APPLY' : 'DRY-RUN';

  console.log(`[archive-legacy] Modus: ${mode}`);
  console.log(`[archive-legacy] Kandidaten: ${LEGACY_KEYS.join(', ')}`);
  console.log('');

  const legacy = await prisma.designTemplate.findMany({
    where: { key: { in: LEGACY_KEYS } },
    select: {
      id: true,
      key: true,
      name: true,
      type: true,
      isArchived: true,
      _count: { select: { menus: true } },
    },
  });

  if (legacy.length === 0) {
    console.log('[archive-legacy] Keine Legacy-Templates gefunden – nichts zu tun.');
    await prisma.$disconnect();
    return;
  }

  let blocked = false;
  for (const t of legacy) {
    const marker = t.isArchived ? '✓ bereits archiviert' : t._count.menus > 0 ? '⚠ BLOCKIERT' : 'bereit';
    console.log(`  • ${t.key.padEnd(10)} ${t.name.padEnd(12)} menus=${t._count.menus} archived=${t.isArchived} → ${marker}`);
    if (!t.isArchived && t._count.menus > 0) blocked = true;
  }

  if (blocked) {
    console.log('');
    console.log('[archive-legacy] ABBRUCH: Es existieren Karten, die noch auf ein Legacy-Template zeigen.');
    console.log('[archive-legacy] Bitte zuerst alle Karten auf "minimal" oder ein CUSTOM-Template umstellen.');
    await prisma.$disconnect();
    process.exit(1);
  }

  const toArchive = legacy.filter((t) => !t.isArchived);
  if (toArchive.length === 0) {
    console.log('');
    console.log('[archive-legacy] Alle Legacy-Templates sind bereits archiviert – nichts zu tun.');
    await prisma.$disconnect();
    return;
  }

  console.log('');
  if (!apply) {
    console.log(`[archive-legacy] Würde ${toArchive.length} Template(s) archivieren.`);
    console.log('[archive-legacy] Mit --apply ausführen, um die Änderung zu schreiben.');
    await prisma.$disconnect();
    return;
  }

  const { count } = await prisma.designTemplate.updateMany({
    where: { key: { in: toArchive.map((t) => t.key) } },
    data: { isArchived: true },
  });
  console.log(`[archive-legacy] ${count} Template(s) archiviert.`);

  await prisma.$disconnect();
}

main().catch(async (e) => {
  console.error('[archive-legacy] Fehler:', e);
  await prisma.$disconnect();
  process.exit(1);
});
