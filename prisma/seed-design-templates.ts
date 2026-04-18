import { PrismaClient } from '@prisma/client';
import { elegantTemplate } from '../src/lib/design-templates/elegant';
import { modernTemplate } from '../src/lib/design-templates/modern';
import { classicTemplate } from '../src/lib/design-templates/classic';
import { minimalTemplate } from '../src/lib/design-templates/minimal';

const prisma = new PrismaClient();

async function main() {
  const items = [
    { key: 'elegant', name: 'Elegant',   baseType: 'elegant', config: elegantTemplate },
    { key: 'modern',  name: 'Modern',    baseType: 'modern',  config: modernTemplate },
    { key: 'classic', name: 'Klassisch', baseType: 'classic', config: classicTemplate },
    { key: 'minimal', name: 'Minimal',   baseType: 'minimal', config: minimalTemplate },
  ];
  for (const t of items) {
    await prisma.designTemplate.upsert({
      where: { key: t.key },
      update: { name: t.name, type: 'SYSTEM', baseType: t.baseType, config: t.config as any, isArchived: false },
      create: { key: t.key, name: t.name, type: 'SYSTEM', baseType: t.baseType, config: t.config as any },
    });
    console.log('  Seeded:', t.name, '(' + t.key + ')');
  }
}

main().then(() => prisma.$disconnect()).catch(async (e) => {
  console.error(e);
  await prisma.$disconnect();
  process.exit(1);
});
