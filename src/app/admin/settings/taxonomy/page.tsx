// @ts-nocheck
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';
import TaxonomyManager from '@/components/admin/taxonomy-manager';

export default async function TaxonomyPage() {
  const session = await getServerSession(authOptions);
  if (!session) return null;
  const tid = session.user.tenantId;

  // Alle Root-Nodes mit bis zu 3 Ebenen Kindern laden
  const buildInclude = (d) => {
    if (d <= 0) return { translations: true, _count: { select: { products: true, children: true } } };
    return {
      translations: true,
      _count: { select: { products: true, children: true } },
      children: { include: buildInclude(d - 1), orderBy: { sortOrder: 'asc' } },
    };
  };

  const nodes = await prisma.taxonomyNode.findMany({
    where: { tenantId: tid },
    include: {
      translations: true,
      _count: { select: { products: true, children: true } },
      children: { include: buildInclude(3), orderBy: { sortOrder: 'asc' } },
      parent: true,
    },
    orderBy: [{ type: 'asc' }, { sortOrder: 'asc' }],
  });

  return <TaxonomyManager initialNodes={JSON.parse(JSON.stringify(nodes))} />;
}
