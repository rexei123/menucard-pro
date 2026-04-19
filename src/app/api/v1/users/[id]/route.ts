// @ts-nocheck
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions, hasMinRole } from '@/lib/auth';
import prisma from '@/lib/prisma';
import bcrypt from 'bcryptjs';

const VALID_ROLES = ['OWNER', 'ADMIN', 'MANAGER', 'EDITOR'] as const;

async function getScopedUser(id: string, tenantId: string) {
  return prisma.user.findFirst({ where: { id, tenantId } });
}

// GET /api/v1/users/[id]
export async function GET(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  if (!hasMinRole(session.user.role, 'ADMIN') && session.user.id !== params.id) {
    return NextResponse.json({ error: 'Keine Berechtigung' }, { status: 403 });
  }

  const user = await prisma.user.findFirst({
    where: { id: params.id, tenantId: session.user.tenantId },
    select: {
      id: true, email: true, firstName: true, lastName: true, name: true,
      role: true, isActive: true, lastLoginAt: true, createdAt: true, updatedAt: true,
    },
  });
  if (!user) return NextResponse.json({ error: 'Nicht gefunden' }, { status: 404 });
  return NextResponse.json(user);
}

// PATCH /api/v1/users/[id] — Rolle/Status/Name/Passwort aendern (nur ADMIN+)
export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  if (!hasMinRole(session.user.role, 'ADMIN')) {
    return NextResponse.json({ error: 'Keine Berechtigung' }, { status: 403 });
  }

  const target = await getScopedUser(params.id, session.user.tenantId);
  if (!target) return NextResponse.json({ error: 'Nicht gefunden' }, { status: 404 });

  const body = await req.json();
  const data: any = {};

  if (typeof body.firstName === 'string') data.firstName = body.firstName;
  if (typeof body.lastName === 'string') data.lastName = body.lastName;
  if (data.firstName || data.lastName) {
    data.name = `${data.firstName ?? target.firstName} ${data.lastName ?? target.lastName}`.trim();
  }
  if (typeof body.isActive === 'boolean') {
    // Niemand darf sich selbst deaktivieren
    if (target.id === session.user.id && body.isActive === false) {
      return NextResponse.json({ error: 'Sie koennen sich nicht selbst deaktivieren' }, { status: 400 });
    }
    data.isActive = body.isActive;
  }
  if (typeof body.role === 'string') {
    if (!VALID_ROLES.includes(body.role)) {
      return NextResponse.json({ error: 'Ungueltige Rolle' }, { status: 400 });
    }
    if (body.role === 'OWNER' && session.user.role !== 'OWNER') {
      return NextResponse.json({ error: 'Nur OWNER duerfen OWNER-Rolle vergeben' }, { status: 403 });
    }
    // Letzten OWNER nicht degradieren
    if (target.role === 'OWNER' && body.role !== 'OWNER') {
      const ownerCount = await prisma.user.count({
        where: { tenantId: session.user.tenantId, role: 'OWNER', isActive: true },
      });
      if (ownerCount <= 1) {
        return NextResponse.json({ error: 'Letzter OWNER kann nicht degradiert werden' }, { status: 400 });
      }
    }
    data.role = body.role;
  }
  if (typeof body.password === 'string' && body.password.length > 0) {
    if (body.password.length < 8) {
      return NextResponse.json({ error: 'Passwort muss mindestens 8 Zeichen lang sein' }, { status: 400 });
    }
    // Self-Update: aktuelles Passwort muss verifiziert werden
    if (target.id === session.user.id) {
      if (typeof body.currentPassword !== 'string' || body.currentPassword.length === 0) {
        return NextResponse.json({ error: 'Aktuelles Passwort erforderlich' }, { status: 400 });
      }
      const full = await prisma.user.findUnique({
        where: { id: target.id },
        select: { passwordHash: true },
      });
      const isValid = full?.passwordHash
        ? await bcrypt.compare(body.currentPassword, full.passwordHash)
        : false;
      if (!isValid) {
        return NextResponse.json({ error: 'Aktuelles Passwort ist falsch' }, { status: 400 });
      }
    }
    data.passwordHash = await bcrypt.hash(body.password, 10);
  }

  const updated = await prisma.user.update({
    where: { id: params.id },
    data,
    select: {
      id: true, email: true, firstName: true, lastName: true, name: true,
      role: true, isActive: true, lastLoginAt: true, createdAt: true, updatedAt: true,
    },
  });
  return NextResponse.json(updated);
}

// DELETE /api/v1/users/[id] — Benutzer loeschen (nur ADMIN+)
export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  if (!hasMinRole(session.user.role, 'ADMIN')) {
    return NextResponse.json({ error: 'Keine Berechtigung' }, { status: 403 });
  }

  const target = await getScopedUser(params.id, session.user.tenantId);
  if (!target) return NextResponse.json({ error: 'Nicht gefunden' }, { status: 404 });
  if (target.id === session.user.id) {
    return NextResponse.json({ error: 'Sie koennen sich nicht selbst loeschen' }, { status: 400 });
  }
  if (target.role === 'OWNER') {
    const ownerCount = await prisma.user.count({
      where: { tenantId: session.user.tenantId, role: 'OWNER' },
    });
    if (ownerCount <= 1) {
      return NextResponse.json({ error: 'Letzter OWNER kann nicht geloescht werden' }, { status: 400 });
    }
  }

  await prisma.user.delete({ where: { id: params.id } });
  return NextResponse.json({ success: true });
}
