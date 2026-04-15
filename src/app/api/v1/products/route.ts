import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import prisma from '@/lib/prisma';

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const tid = session.user.tenantId;

  const body = await req.json();
  const type = body.type || 'OTHER';

  // Auto-generate SKU
  const lastProduct = await prisma.product.findFirst({
    where: { tenantId: tid, sku: { startsWith: 'SB-' } },
    orderBy: { sku: 'desc' },
    select: { sku: true },
  });
  const lastNum = lastProduct?.sku ? parseInt(lastProduct.sku.replace('SB-', '')) : 0;
  const sku = 'SB-' + String(lastNum + 1).padStart(4, '0');

  const product = await prisma.product.create({
    data: {
      tenantId: tid,
      sku,
      type,
      status: 'DRAFT',
      translations: {
        create: [
          { languageCode: 'de', name: body.name || 'Neues Produkt' },
          { languageCode: 'en', name: body.nameEn || 'New Product' },
        ],
      },
    },
  });

  return NextResponse.json({ id: product.id, sku: product.sku }, { status: 201 });
}
