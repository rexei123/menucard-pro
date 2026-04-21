import { notFound, redirect } from 'next/navigation';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import DesignEditor from '@/components/admin/design-editor';
import DesignEditorV2 from '@/components/admin/design-editor-v2';

/**
 * Feature-Flag zwischen Legacy-Akkordeon-Editor und Schema-driven v2-Editor.
 *
 *   /admin/design/<id>/edit           → Design-Editor v2 (Default)
 *   /admin/design/<id>/edit?v=legacy  → alter Akkordeon-Editor
 *
 * Umschalt-Link liegt in der Topbar des jeweils aktiven Editors.
 * Siehe docs/FEATURE-DESIGN-EDITOR-V2-PLAN.md (Sprint 3).
 */
export default async function TemplateEditPage({
  params,
  searchParams,
}: {
  params: { id: string };
  searchParams?: { v?: string };
}) {
  const session = await getServerSession(authOptions);
  if (!session) return null;

  const template = await prisma.designTemplate.findUnique({
    where: { id: params.id },
    include: {
      menus: {
        where: { status: 'ACTIVE' },
        orderBy: { updatedAt: 'desc' },
        include: {
          location: { include: { tenant: true } },
          translations: { where: { language: 'de' }, take: 1 },
        },
      },
    },
  });

  if (!template) return notFound();
  if (template.type === 'SYSTEM') redirect('/admin/design');

  // Vorschau: ALLE aktiven Karten, die diese Vorlage nutzen.
  // Titel kommt aus MenuTranslation (DE bevorzugt, sonst Slug als Fallback).
  const previewMenus = template.menus.map((m) => ({
    id: m.id,
    slug: m.slug,
    title: m.translations[0]?.name || m.slug,
    locationName: m.location.name,
    url: `/${m.location.tenant.slug}/${m.location.slug}/${m.slug}`,
    pdfUrl: `/api/v1/menus/${m.id}/pdf`,
  }));
  const firstMenu = previewMenus[0];
  const previewUrl = firstMenu?.url ?? null;
  const previewPdfUrl = firstMenu?.pdfUrl ?? null;

  const useLegacy = searchParams?.v === 'legacy';

  if (useLegacy) {
    return (
      <DesignEditor
        mode="template"
        templateId={template.id}
        initialName={template.name}
        initialBaseType={template.baseType}
        previewUrl={previewUrl}
        previewPdfUrl={previewPdfUrl}
      />
    );
  }

  return (
    <DesignEditorV2
      mode="template"
      templateId={template.id}
      initialName={template.name}
      initialBaseType={template.baseType}
      previewUrl={previewUrl}
      previewPdfUrl={previewPdfUrl}
      previewMenus={previewMenus}
    />
  );
}
