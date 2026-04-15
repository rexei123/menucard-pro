#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "================================================"
echo "SCHRITT 2: API-Endpoints fuer Template-System"
echo "================================================"

# Verzeichnisse anlegen
mkdir -p src/app/api/v1/design-templates/\[id\]/restore
mkdir -p src/app/api/v1/design-templates/\[id\]/duplicate
mkdir -p src/app/api/v1/menus/\[id\]/template

# ==============================================================
# GET + POST: /api/v1/design-templates
# ==============================================================
cat > src/app/api/v1/design-templates/route.ts <<'TSEOF'
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

const MAX_CUSTOM_ACTIVE = 6;

export async function GET(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { searchParams } = new URL(req.url);
  const includeArchived = searchParams.get('includeArchived') === 'true';

  const templates = await prisma.designTemplate.findMany({
    where: includeArchived ? {} : { isArchived: false },
    orderBy: [{ type: 'asc' }, { name: 'asc' }],
    include: {
      _count: { select: { menus: true } },
    },
  });

  return NextResponse.json({ templates });
}

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await req.json();
  const { name, baseType, config } = body;

  if (!name || !baseType || !config) {
    return NextResponse.json({ error: 'name, baseType und config erforderlich' }, { status: 400 });
  }

  // Cap pruefen
  const activeCustomCount = await prisma.designTemplate.count({
    where: { type: 'CUSTOM', isArchived: false },
  });
  if (activeCustomCount >= MAX_CUSTOM_ACTIVE) {
    return NextResponse.json(
      { error: `Maximal ${MAX_CUSTOM_ACTIVE} eigene Vorlagen aktiv. Bitte archivieren Sie zuerst eine bestehende Vorlage.` },
      { status: 409 }
    );
  }

  // Namens-Kollision
  const existing = await prisma.designTemplate.findUnique({ where: { name } });
  if (existing) {
    return NextResponse.json({ error: 'Eine Vorlage mit diesem Namen existiert bereits.' }, { status: 409 });
  }

  const template = await prisma.designTemplate.create({
    data: {
      name,
      type: 'CUSTOM',
      baseType,
      config,
      createdBy: session.user?.email ?? null,
    },
  });

  return NextResponse.json({ template }, { status: 201 });
}
TSEOF
echo "  OK: /api/v1/design-templates/route.ts"

# ==============================================================
# GET + PATCH + DELETE: /api/v1/design-templates/[id]
# ==============================================================
cat > src/app/api/v1/design-templates/\[id\]/route.ts <<'TSEOF'
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

export async function GET(_req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const template = await prisma.designTemplate.findUnique({
    where: { id: params.id },
    include: { _count: { select: { menus: true } }, menus: { select: { id: true, slug: true } } },
  });
  if (!template) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  return NextResponse.json({ template });
}

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const template = await prisma.designTemplate.findUnique({ where: { id: params.id } });
  if (!template) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  if (template.type === 'SYSTEM') {
    return NextResponse.json({ error: 'System-Vorlagen koennen nicht bearbeitet werden. Bitte duplizieren.' }, { status: 403 });
  }

  const body = await req.json();
  const data: any = {};
  if (typeof body.name === 'string') data.name = body.name;
  if (typeof body.baseType === 'string') data.baseType = body.baseType;
  if (body.config !== undefined) data.config = body.config;

  // Namenskollision
  if (data.name && data.name !== template.name) {
    const conflict = await prisma.designTemplate.findUnique({ where: { name: data.name } });
    if (conflict) return NextResponse.json({ error: 'Name bereits vergeben.' }, { status: 409 });
  }

  const updated = await prisma.designTemplate.update({
    where: { id: params.id },
    data,
  });

  return NextResponse.json({ template: updated });
}

export async function DELETE(_req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const template = await prisma.designTemplate.findUnique({
    where: { id: params.id },
    include: { _count: { select: { menus: true } } },
  });
  if (!template) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  if (template.type === 'SYSTEM') {
    return NextResponse.json({ error: 'System-Vorlagen koennen nicht geloescht werden.' }, { status: 403 });
  }
  if (template._count.menus > 0) {
    return NextResponse.json(
      { error: `Diese Vorlage wird von ${template._count.menus} Karte(n) genutzt. Bitte weisen Sie die Karten zuerst einer anderen Vorlage zu.` },
      { status: 409 }
    );
  }

  // Soft-Delete: archivieren
  const archived = await prisma.designTemplate.update({
    where: { id: params.id },
    data: { isArchived: true },
  });

  return NextResponse.json({ template: archived, archived: true });
}
TSEOF
echo "  OK: /api/v1/design-templates/[id]/route.ts"

# ==============================================================
# POST: /api/v1/design-templates/[id]/restore
# ==============================================================
cat > src/app/api/v1/design-templates/\[id\]/restore/route.ts <<'TSEOF'
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

const MAX_CUSTOM_ACTIVE = 6;

export async function POST(_req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const template = await prisma.designTemplate.findUnique({ where: { id: params.id } });
  if (!template) return NextResponse.json({ error: 'Not found' }, { status: 404 });
  if (!template.isArchived) return NextResponse.json({ error: 'Nicht archiviert.' }, { status: 400 });

  if (template.type === 'CUSTOM') {
    const activeCount = await prisma.designTemplate.count({
      where: { type: 'CUSTOM', isArchived: false },
    });
    if (activeCount >= MAX_CUSTOM_ACTIVE) {
      return NextResponse.json(
        { error: `Maximal ${MAX_CUSTOM_ACTIVE} aktive eigene Vorlagen. Bitte archivieren Sie zuerst eine andere Vorlage.` },
        { status: 409 }
      );
    }
  }

  const restored = await prisma.designTemplate.update({
    where: { id: params.id },
    data: { isArchived: false },
  });

  return NextResponse.json({ template: restored });
}
TSEOF
echo "  OK: /api/v1/design-templates/[id]/restore/route.ts"

# ==============================================================
# POST: /api/v1/design-templates/[id]/duplicate
# ==============================================================
cat > src/app/api/v1/design-templates/\[id\]/duplicate/route.ts <<'TSEOF'
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

const MAX_CUSTOM_ACTIVE = 6;

export async function POST(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const source = await prisma.designTemplate.findUnique({ where: { id: params.id } });
  if (!source) return NextResponse.json({ error: 'Quell-Vorlage nicht gefunden' }, { status: 404 });

  const activeCount = await prisma.designTemplate.count({
    where: { type: 'CUSTOM', isArchived: false },
  });
  if (activeCount >= MAX_CUSTOM_ACTIVE) {
    return NextResponse.json(
      { error: `Maximal ${MAX_CUSTOM_ACTIVE} aktive eigene Vorlagen. Bitte archivieren Sie zuerst eine bestehende Vorlage.` },
      { status: 409 }
    );
  }

  const body = await req.json().catch(() => ({}));
  let baseName = typeof body.name === 'string' && body.name ? body.name : `${source.name} (Kopie)`;

  // eindeutigen Namen finden
  let name = baseName;
  let counter = 2;
  while (await prisma.designTemplate.findUnique({ where: { name } })) {
    name = `${baseName} ${counter}`;
    counter++;
    if (counter > 20) break;
  }

  const copy = await prisma.designTemplate.create({
    data: {
      name,
      type: 'CUSTOM',
      baseType: source.baseType,
      config: source.config as any,
      createdBy: session.user?.email ?? null,
    },
  });

  return NextResponse.json({ template: copy }, { status: 201 });
}
TSEOF
echo "  OK: /api/v1/design-templates/[id]/duplicate/route.ts"

# ==============================================================
# PATCH: /api/v1/menus/[id]/template  (Karte einem Template zuordnen)
# ==============================================================
cat > src/app/api/v1/menus/\[id\]/template/route.ts <<'TSEOF'
import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

export async function GET(_req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const menu = await prisma.menu.findUnique({
    where: { id: params.id },
    include: { template: true },
  });
  if (!menu) return NextResponse.json({ error: 'Karte nicht gefunden' }, { status: 404 });

  return NextResponse.json({ template: menu.template, templateId: menu.templateId });
}

export async function PATCH(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await req.json();
  const { templateId } = body;
  if (!templateId) return NextResponse.json({ error: 'templateId erforderlich' }, { status: 400 });

  const template = await prisma.designTemplate.findUnique({ where: { id: templateId } });
  if (!template) return NextResponse.json({ error: 'Vorlage nicht gefunden' }, { status: 404 });
  if (template.isArchived) {
    return NextResponse.json({ error: 'Archivierte Vorlagen koennen Karten nicht zugewiesen werden.' }, { status: 400 });
  }

  const updated = await prisma.menu.update({
    where: { id: params.id },
    data: { templateId },
    include: { template: true },
  });

  return NextResponse.json({ menu: updated });
}
TSEOF
echo "  OK: /api/v1/menus/[id]/template/route.ts"

# ==============================================================
# Build + Restart
# ==============================================================
echo ""
echo "[Build] npm run build..."
npm run build 2>&1 | tail -30

echo ""
echo "[Restart] pm2 restart menucard-pro..."
pm2 restart menucard-pro

echo ""
echo "[Test] API-Calls..."
sleep 2
echo "--- GET /api/v1/design-templates (unauth, sollte 401) ---"
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/api/v1/design-templates

echo ""
echo "================================================"
echo "SCHRITT 2 ABGESCHLOSSEN"
echo "================================================"
