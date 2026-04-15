import { notFound, redirect } from 'next/navigation';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import TemplateEditor from '@/components/admin/template-editor';

export default async function TemplateEditPage({ params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return null;
  const template = await prisma.designTemplate.findUnique({
    where: { id: params.id },
    include: { _count: { select: { menus: true } } },
  });
  if (!template) return notFound();
  if (template.type === 'SYSTEM') redirect('/admin/design');
  return (
    <TemplateEditor
      template={{
        id: template.id,
        name: template.name,
        baseType: template.baseType,
        type: template.type,
        config: template.config as any,
        menuCount: template._count.menus,
      }}
    />
  );
}
