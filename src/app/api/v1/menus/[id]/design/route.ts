import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import { getTemplate, mergeConfig } from '@/lib/design-templates';

// GET /api/v1/menus/[id]/design – Design-Config einer Karte laden
export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const menu = await prisma.menu.findUnique({
    where: { id: params.id },
    select: { id: true, designConfig: true },
  });

  if (!menu) return NextResponse.json({ error: 'Menu not found' }, { status: 404 });

  // Merge: Template-Defaults + gespeicherte Overrides
  const saved = menu.designConfig as any;
  const templateName = saved?.digital?.template || saved?.analog?.template || 'elegant';
  const template = getTemplate(templateName);
  const merged = {
    digital: mergeConfig(template.digital, saved?.digital),
    analog: mergeConfig(template.analog, saved?.analog),
  };

  return NextResponse.json({ designConfig: merged, savedOverrides: saved, templateName });
}

// PATCH /api/v1/menus/[id]/design – Design-Config speichern (nur Overrides)
export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await req.json();
  const { designConfig } = body;

  if (!designConfig) return NextResponse.json({ error: 'designConfig required' }, { status: 400 });

  const updated = await prisma.menu.update({
    where: { id: params.id },
    data: { designConfig },
    select: { id: true, designConfig: true },
  });

  return NextResponse.json({ success: true, designConfig: updated.designConfig });
}
