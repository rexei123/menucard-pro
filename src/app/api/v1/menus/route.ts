// @ts-nocheck
import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

// GET /api/v1/menus — Liste aller Karten des Mandanten
// Query: ?locationId=<id>  ?status=ACTIVE|DRAFT|ARCHIVED  ?type=EVENT|WINE|BAR|...
export async function GET(req: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    const url = new URL(req.url);
    const locationId = url.searchParams.get('locationId');
    const status = url.searchParams.get('status');
    const type = url.searchParams.get('type');

    const where: any = {};

    // Wenn eingeloggt: nur Mandanten-Karten. Ohne Auth: nur oeffentliche (ACTIVE) Karten
    // (z.B. fuer Embed/Widget-Anbindung ueber API-Endpoint).
    if (session?.user?.tenantId) {
      where.location = { tenantId: session.user.tenantId };
    } else {
      where.status = 'ACTIVE';
    }

    if (locationId) where.locationId = locationId;
    if (status) where.status = status;
    else if (session?.user?.tenantId) where.status = { not: 'ARCHIVED' };
    if (type) where.type = type;

    const menus = await prisma.menu.findMany({
      where,
      include: {
        translations: { where: { language: 'de' }, take: 1 },
        template: { select: { id: true, name: true, baseType: true } },
        location: { select: { id: true, name: true, slug: true } },
      },
      orderBy: [{ locationId: 'asc' }, { sortOrder: 'asc' }],
    });

    const result = menus.map((m: any) => ({
      id: m.id,
      slug: m.slug,
      name: m.translations[0]?.name || m.slug,
      menuType: m.type,
      templateId: m.templateId,
      template: m.template,
      location: m.location,
      locationId: m.locationId,
      isActive: m.status === 'ACTIVE',
      status: m.status,
      sortOrder: m.sortOrder,
    }));

    return NextResponse.json(result);
  } catch (error: any) {
    console.error('GET /api/v1/menus error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// POST /api/v1/menus — Neue Karte anlegen
// Body: { locationId, slug, type, name (de), nameEn?, description?, templateId?, status? }
export async function POST(req: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    const tid = session.user.tenantId;

    const body = await req.json();
    const { slug, type, name, nameEn, description, descriptionEn, templateId, status } = body;
    let { locationId } = body;

    if (!type) return NextResponse.json({ error: 'type ist erforderlich' }, { status: 400 });
    if (!name) return NextResponse.json({ error: 'name ist erforderlich' }, { status: 400 });

    // Wenn keine locationId: erste Location des Mandanten nehmen
    if (!locationId) {
      const firstLocation = await prisma.location.findFirst({
        where: { tenantId: tid },
        orderBy: { createdAt: 'asc' },
        select: { id: true },
      });
      if (!firstLocation) {
        return NextResponse.json({ error: 'Kein Standort fuer Mandant gefunden' }, { status: 400 });
      }
      locationId = firstLocation.id;
    } else {
      // Location muss zum Mandanten gehoeren
      const loc = await prisma.location.findFirst({
        where: { id: locationId, tenantId: tid },
      });
      if (!loc) return NextResponse.json({ error: 'Standort nicht gefunden' }, { status: 404 });
    }

    // Slug: vom Body oder aus Namen generieren, bei Kollision mit -2, -3, ... suffixen
    const baseSlug = (slug || name)
      .toLowerCase()
      .replace(/[ä]/g, 'ae').replace(/[ö]/g, 'oe').replace(/[ü]/g, 'ue').replace(/[ß]/g, 'ss')
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '')
      .slice(0, 60) || 'karte';

    let finalSlug = baseSlug;
    let n = 1;
    while (await prisma.menu.findUnique({ where: { locationId_slug: { locationId, slug: finalSlug } } })) {
      n++;
      finalSlug = `${baseSlug}-${n}`;
    }

    // Template-Zuordnung pruefen
    if (templateId) {
      const tpl = await prisma.designTemplate.findUnique({ where: { id: templateId } });
      if (!tpl) return NextResponse.json({ error: 'Template nicht gefunden' }, { status: 404 });
    }

    // Hoechste sortOrder in dieser Location
    const maxSort = await prisma.menu.findFirst({
      where: { locationId },
      orderBy: { sortOrder: 'desc' },
      select: { sortOrder: true },
    });

    const menu = await prisma.menu.create({
      data: {
        locationId,
        slug: finalSlug,
        type,
        status: status || 'DRAFT',
        sortOrder: (maxSort?.sortOrder ?? -1) + 1,
        templateId: templateId || null,
        translations: {
          create: [
            { language: 'de', name, description: description || null },
            { language: 'en', name: nameEn || name, description: descriptionEn || null },
          ],
        },
        // Eine Default-Sektion erstellen, damit die Karte sofort befuellt werden kann
        sections: {
          create: [{
            slug: 'allgemein',
            sortOrder: 0,
            depth: 0,
            translations: {
              create: [
                { language: 'de', name: 'Allgemein' },
                { language: 'en', name: 'General' },
              ],
            },
          }],
        },
      },
      include: {
        translations: true,
        sections: { include: { translations: true } },
        template: { select: { id: true, name: true, baseType: true } },
      },
    });

    return NextResponse.json(menu, { status: 201 });
  } catch (error: any) {
    console.error('POST /api/v1/menus error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
