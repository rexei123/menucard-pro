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
