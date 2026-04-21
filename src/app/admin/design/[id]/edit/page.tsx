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
        take: 1,
        where: { status: 'ACTIVE' },
        include: { location: { include: { tenant: true } } },
      },
    },
  });

  if (!template) return notFound();
  if (template.type === 'SYSTEM') redirect('/admin/design');

  // Vorschau: erste aktive Karte, die diese Vorlage nutzt
  let previewUrl: string | null = null;
  let previewPdfUrl: string | null = null;
  const firstMenu = template.menus[0];
  if (firstMenu) {
    previewUrl = `/${firstMenu.location.tenant.slug}/${firstMenu.location.slug}/${firstMenu.slug}`;
    previewPdfUrl = `/api/v1/menus/${firstMenu.id}/pdf`;
  }

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
    />
  );
}
