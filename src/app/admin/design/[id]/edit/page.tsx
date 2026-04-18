import { notFound, redirect } from 'next/navigation';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import DesignEditor from '@/components/admin/design-editor';

export default async function TemplateEditPage({ params }: { params: { id: string } }) {
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
