// @ts-nocheck
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions, hasMinRole } from '@/lib/auth';
import prisma from '@/lib/prisma';
import bcrypt from 'bcryptjs';

const VALID_ROLES = ['OWNER', 'ADMIN', 'MANAGER', 'EDITOR'] as const;

// GET /api/v1/users — Alle Benutzer des Mandanten (nur ADMIN+)
export async function GET() {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  if (!hasMinRole(session.user.role, 'ADMIN')) {
    return NextResponse.json({ error: 'Keine Berechtigung' }, { status: 403 });
  }

  const users = await prisma.user.findMany({
    where: { tenantId: session.user.tenantId },
    select: {
      id: true, email: true, firstName: true, lastName: true, name: true,
      role: true, isActive: true, lastLoginAt: true, createdAt: true, updatedAt: true,
    },
    orderBy: [{ role: 'asc' }, { createdAt: 'asc' }],
  });

  return NextResponse.json(users);
}

// POST /api/v1/users — Neuen Benutzer anlegen (nur ADMIN+)
// Body: { email, firstName, lastName, password, role }
export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  if (!hasMinRole(session.user.role, 'ADMIN')) {
    return NextResponse.json({ error: 'Keine Berechtigung' }, { status: 403 });
  }

  const body = await req.json();
  const { email, firstName, lastName, password, role } = body;

  if (!email || !firstName || !lastName || !password) {
    return NextResponse.json({ error: 'email, firstName, lastName und password sind erforderlich' }, { status: 400 });
  }
  if (password.length < 8) {
    return NextResponse.json({ error: 'Passwort muss mindestens 8 Zeichen lang sein' }, { status: 400 });
  }
  if (role && !VALID_ROLES.includes(role)) {
    return NextResponse.json({ error: 'Ungueltige Rolle' }, { status: 400 });
  }
  // Nur OWNER darf OWNER-Rolle vergeben
  if (role === 'OWNER' && session.user.role !== 'OWNER') {
    return NextResponse.json({ error: 'Nur OWNER duerfen OWNER-Rolle vergeben' }, { status: 403 });
  }

  const existing = await prisma.user.findUnique({ where: { email: email.toLowerCase() } });
  if (existing) return NextResponse.json({ error: 'E-Mail existiert bereits' }, { status: 409 });

  const passwordHash = await bcrypt.hash(password, 10);

  const user = await prisma.user.create({
    data: {
      tenantId: session.user.tenantId,
      email: email.toLowerCase(),
      passwordHash,
      firstName,
      lastName,
      name: `${firstName} ${lastName}`.trim(),
      role: role || 'EDITOR',
      isActive: true,
    },
    select: {
      id: true, email: true, firstName: true, lastName: true, name: true,
      role: true, isActive: true, createdAt: true,
    },
  });

  return NextResponse.json(user, { status: 201 });
}
