// @ts-nocheck
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions, hasMinRole } from '@/lib/auth';
import prisma from '@/lib/prisma';

// GET /api/v1/tenants/me — aktuellen Tenant inkl. settings auslesen
export async function GET() {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const tenant = await prisma.tenant.findUnique({
    where: { id: session.user.tenantId },
    select: {
      id: true, name: true, slug: true, settings: true,
      createdAt: true, updatedAt: true,
    },
  });
  if (!tenant) return NextResponse.json({ error: 'Nicht gefunden' }, { status: 404 });

  // Standort ist in settings.location (z.B. "Kaprun, Österreich") abgelegt
  const settings = (tenant.settings ?? {}) as Record<string, unknown>;
  return NextResponse.json({
    id: tenant.id,
    name: tenant.name,
    slug: tenant.slug,
    location: typeof settings.location === 'string' ? settings.location : '',
    settings,
    createdAt: tenant.createdAt,
    updatedAt: tenant.updatedAt,
  });
}

// PATCH /api/v1/tenants/me — Name und/oder Standort aendern (nur ADMIN+)
export async function PATCH(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  if (!hasMinRole(session.user.role, 'ADMIN')) {
    return NextResponse.json({ error: 'Keine Berechtigung' }, { status: 403 });
  }

  const body = await req.json().catch(() => ({}));
  const data: any = {};

  if (typeof body.name === 'string') {
    const trimmed = body.name.trim();
    if (trimmed.length === 0) {
      return NextResponse.json({ error: 'Name darf nicht leer sein' }, { status: 400 });
    }
    if (trimmed.length > 120) {
      return NextResponse.json({ error: 'Name ist zu lang (max. 120 Zeichen)' }, { status: 400 });
    }
    data.name = trimmed;
  }

  // Standort in settings.location mergen, alle anderen settings-Keys erhalten bleiben
  if (typeof body.location === 'string') {
    const existing = await prisma.tenant.findUnique({
      where: { id: session.user.tenantId },
      select: { settings: true },
    });
    const current = (existing?.settings ?? {}) as Record<string, unknown>;
    const trimmed = body.location.trim();
    if (trimmed.length > 200) {
      return NextResponse.json({ error: 'Standort ist zu lang (max. 200 Zeichen)' }, { status: 400 });
    }
    data.settings = { ...current, location: trimmed };
  }

  if (Object.keys(data).length === 0) {
    return NextResponse.json({ error: 'Keine Aenderungen uebermittelt' }, { status: 400 });
  }

  const updated = await prisma.tenant.update({
    where: { id: session.user.tenantId },
    data,
    select: {
      id: true, name: true, slug: true, settings: true,
      createdAt: true, updatedAt: true,
    },
  });

  const settings = (updated.settings ?? {}) as Record<string, unknown>;
  return NextResponse.json({
    id: updated.id,
    name: updated.name,
    slug: updated.slug,
    location: typeof settings.location === 'string' ? settings.location : '',
    settings,
    createdAt: updated.createdAt,
    updatedAt: updated.updatedAt,
  });
}
