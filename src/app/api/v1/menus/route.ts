import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export async function GET() {
  try {
    const menus = await prisma.menu.findMany({
      where: { status: { not: 'ARCHIVED' } },
      include: {
        translations: { where: { languageCode: 'de' }, take: 1 },
        template: { select: { id: true, name: true, baseType: true } },
      },
      orderBy: { sortOrder: 'asc' },
    });
    const result = menus.map((m: any) => ({
      id: m.id,
      slug: m.slug,
      name: m.translations[0]?.name || m.slug,
      menuType: m.type,
      templateId: m.templateId,
      template: m.template,
      isActive: m.isActive,
    }));
    return NextResponse.json(result);
  } catch (error: any) {
    console.error('GET /api/v1/menus error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
