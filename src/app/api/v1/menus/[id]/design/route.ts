import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import { getTemplate, mergeConfig } from '@/lib/design-templates';

// Deep merge helper
function deepMerge(target: any, source: any): any {
  if (!source) return target;
  if (!target) return source;
  const result = { ...target };
  for (const key of Object.keys(source)) {
    if (source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])) {
      result[key] = deepMerge(target[key] || {}, source[key]);
    } else {
      result[key] = source[key];
    }
  }
  return result;
}

// GET /api/v1/menus/[id]/design
export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const menu = await prisma.menu.findUnique({
    where: { id: params.id },
    select: { id: true, designConfig: true },
  });
  if (!menu) return NextResponse.json({ error: 'Menu not found' }, { status: 404 });

  const saved = menu.designConfig as any;
  const templateName = saved?.digital?.template || 'elegant';
  const template = getTemplate(templateName);
  const merged = {
    digital: mergeConfig(template.digital, saved?.digital),
    analog: mergeConfig(template.analog, saved?.analog),
  };

  return NextResponse.json({
    designConfig: merged,
    savedOverrides: saved,
    templateName,
    customTemplates: saved?.customTemplates || [],
  });
}

// PATCH /api/v1/menus/[id]/design
export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await req.json();
  const { designConfig } = body;
  if (!designConfig) return NextResponse.json({ error: 'designConfig required' }, { status: 400 });

  // Lade bestehende Config und merge
  const existing = await prisma.menu.findUnique({
    where: { id: params.id },
    select: { designConfig: true },
  });

  const existingConfig = (existing?.designConfig as any) || {};
  const mergedConfig = deepMerge(existingConfig, designConfig);

  const updated = await prisma.menu.update({
    where: { id: params.id },
    data: { designConfig: mergedConfig },
    select: { id: true, designConfig: true },
  });

  return NextResponse.json({ success: true, designConfig: updated.designConfig });
}
