#!/bin/bash
set -e
cd /var/www/menucard-pro

echo "=== Adding Product Delete ==="

# 1. Add DELETE handler to API
python3 << 'PYEOF'
content = open('src/app/api/v1/products/[id]/route.ts').read()

# Add DELETE method
content += """

export async function DELETE(req: NextRequest, { params }: { params: { id: string } }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const product = await prisma.product.findFirst({
    where: { id: params.id, tenantId: session.user.tenantId },
  });
  if (!product) return NextResponse.json({ error: 'Not found' }, { status: 404 });

  // Delete all related data
  await prisma.menuPlacement.deleteMany({ where: { productId: params.id } });
  await prisma.productTranslation.deleteMany({ where: { productId: params.id } });
  await prisma.productPrice.deleteMany({ where: { productId: params.id } });
  await prisma.productWineProfile.deleteMany({ where: { productId: params.id } });
  await prisma.productBeverageDetail.deleteMany({ where: { productId: params.id } });
  await prisma.productAllergen.deleteMany({ where: { productId: params.id } });
  await prisma.productTag.deleteMany({ where: { productId: params.id } });
  await prisma.productMedia.deleteMany({ where: { productId: params.id } });
  await prisma.productCustomFieldValue.deleteMany({ where: { productId: params.id } });
  await prisma.productPairing.deleteMany({ where: { OR: [{ sourceId: params.id }, { targetId: params.id }] } });
  await prisma.product.delete({ where: { id: params.id } });

  return NextResponse.json({ success: true });
}
"""

open('src/app/api/v1/products/[id]/route.ts', 'w').write(content)
print('API updated')
PYEOF

# 2. Add delete button to product editor
python3 << 'PYEOF'
content = open('src/components/admin/product-editor.tsx').read()

# Add delete function after save function
content = content.replace(
    "finally { setSaving(false); }",
    """finally { setSaving(false); }
  };

  const deleteProduct = async () => {
    const name = (data.translations.find(t => t.languageCode === 'de') as any)?.name || 'Produkt';
    if (!confirm(`Produkt "${name}" wirklich dauerhaft löschen?\\n\\nAlle Daten (Preise, Übersetzungen, Kartenplatzierungen) werden unwiderruflich gelöscht.`)) return;
    if (!confirm('ENDGÜLTIG LÖSCHEN?\\n\\nDiese Aktion kann NICHT rückgängig gemacht werden!')) return;
    try {
      const res = await fetch(`/api/v1/products/${data.id}`, { method: 'DELETE', credentials: 'include' });
      if (res.ok) window.location.href = '/admin/items';
      else { const d = await res.json(); setError(d.error || 'Löschen fehlgeschlagen'); }
    } catch { setError('Netzwerkfehler'); }"""
)

# Add delete button next to ID at the bottom
content = content.replace(
    """<div className="text-xs text-gray-300">ID: {data.id} · Erstellt: {new Date(data.createdAt).toLocaleDateString('de-AT')}</div>""",
    """<div className="flex items-center justify-between">
        <span className="text-xs text-gray-300">ID: {data.id} · Erstellt: {new Date(data.createdAt).toLocaleDateString('de-AT')}</span>
        <button onClick={deleteProduct} className="rounded-lg border border-red-200 px-3 py-1.5 text-xs font-medium text-red-500 hover:bg-red-50 hover:text-red-700 transition-colors">🗑️ Produkt löschen</button>
      </div>"""
)

open('src/components/admin/product-editor.tsx', 'w').write(content)
print('Editor updated')
PYEOF

npm run build && pm2 restart menucard-pro
echo "=== Done ==="
