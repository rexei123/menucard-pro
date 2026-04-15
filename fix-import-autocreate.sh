#!/bin/bash
# Fix CSV-Import: Fehlende Füllmengen und Produktgruppen automatisch anlegen
# Datum: 10.04.2026

set -e
cd /var/www/menucard-pro

echo "=== CSV-Import: Auto-Create Fix ==="

# Patch mit Python – ersetzt die Validierungs- und Execute-Logik
python3 << 'PYEOF'
import re

with open('src/app/api/v1/import/route.ts', 'r') as f:
    code = f.read()

# === 1. Nach den Lookup-Maps: newFillQuantities und newProductGroups Sets einfügen ===
old_group_block = '''  // Group rows by SKU (multiple prices per product)'''
new_group_block = '''  // Track items that need to be auto-created
  const newFillQuantities = new Set<string>();
  const newProductGroups = new Set<string>();

  // Group rows by SKU (multiple prices per product)'''

code = code.replace(old_group_block, new_group_block)

# === 2. Füllmengen-Validierung: statt Fehler → merken für Auto-Create ===
old_fq_check = '''      if (fq && !fqMap.has(fq.toLowerCase())) errors.push(`Fuellmenge "${fq}" nicht gefunden`);'''
new_fq_check = '''      if (fq && !fqMap.has(fq.toLowerCase())) newFillQuantities.add(fq);'''

code = code.replace(old_fq_check, new_fq_check)

# === 3. Preview-Response: Info über neue Füllmengen/Gruppen mitgeben ===
old_preview = '''    const summary = {
      total: products.length,
      new: products.filter(p => p.status === 'new').length,
      update: products.filter(p => p.status === 'update').length,
      error: products.filter(p => p.status === 'error').length,
    };
    return NextResponse.json({ products, summary });'''

new_preview = '''    const summary = {
      total: products.length,
      new: products.filter(p => p.status === 'new').length,
      update: products.filter(p => p.status === 'update').length,
      error: products.filter(p => p.status === 'error').length,
    };
    const autoCreate = {
      fillQuantities: Array.from(newFillQuantities),
      productGroups: Array.from(newProductGroups),
    };
    return NextResponse.json({ products, summary, autoCreate });'''

code = code.replace(old_preview, new_preview)

# === 4. Execute-Modus: Fehlende Füllmengen und Produktgruppen anlegen ===
old_execute_start = '''    let created = 0;
    let updated = 0;
    let errors = 0;'''

new_execute_start = '''    // Auto-create missing fill quantities
    for (const label of Array.from(newFillQuantities)) {
      const newFq = await prisma.fillQuantity.create({
        data: { tenantId, label, sortOrder: fillQuantities.length + 1 },
      });
      fqMap.set(label.toLowerCase(), newFq.id);
      console.log('Auto-created fill quantity:', label);
    }

    // Auto-create missing product groups
    for (const groupName of Array.from(newProductGroups)) {
      const newPg = await prisma.productGroup.create({
        data: {
          tenantId,
          sortOrder: productGroups.length + 1,
          translations: {
            create: [
              { languageCode: 'de', name: groupName },
              { languageCode: 'en', name: groupName },
            ],
          },
        },
      });
      pgMap.set(groupName.toLowerCase(), newPg.id);
      console.log('Auto-created product group:', groupName);
    }

    let created = 0;
    let updated = 0;
    let errors = 0;'''

code = code.replace(old_execute_start, new_execute_start)

# === 5. Produktgruppe: statt ignorieren → merken für Auto-Create ===
# Suche den Bereich wo group validiert wird und füge Auto-Create-Tracking hinzu
# Der group-Check fehlt aktuell in der Validierung, fügen wir nach dem type-check ein
old_type_check = '''    if (!['WINE', 'DRINK', 'FOOD'].includes(type)) errors.push(`Typ "${type}" ungueltig (WINE/DRINK/FOOD)`);'''
new_type_check = '''    if (!['WINE', 'DRINK', 'FOOD'].includes(type)) errors.push(`Typ "${type}" ungueltig (WINE/DRINK/FOOD)`);
    if (group && !pgMap.has(group.toLowerCase())) newProductGroups.add(group);'''

code = code.replace(old_type_check, new_type_check)

with open('src/app/api/v1/import/route.ts', 'w') as f:
    f.write(code)

print('Import-Route gepatcht: Auto-Create fuer Fuellmengen + Produktgruppen')
PYEOF

echo "[1/2] Route gepatcht"

echo "[2/2] Build + Restart..."
npm run build 2>&1 | tail -5
pm2 restart menucard-pro

echo ""
echo "=== Fix fertig! ==="
echo "Fehlende Fuellmengen und Produktgruppen werden jetzt automatisch angelegt."
echo "Bitte CSV-Import erneut testen."
