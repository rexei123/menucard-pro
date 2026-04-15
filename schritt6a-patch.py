#!/usr/bin/env python3
"""Phase A Cleanup: Legacy designConfig-Lesepfade auf Template-System umstellen.
- Dashboard liest templateName aus Menu.template.baseType
- Menu-Liste-API gibt designConfig nicht mehr im Response aus
- PDF-Creator verlinkt nicht mehr auf tote /admin/menus/[id]/design Route
"""
import sys
from pathlib import Path

patches = []

# ── 1) Dashboard: designConfig → template.baseType ──────────────────────
P1 = Path("src/app/admin/page.tsx")
t1 = P1.read_text(encoding="utf-8")
old1a = "    select: { designConfig: true, slug: true, translations: { select: { name: true, languageCode: true } } },"
new1a = "    select: { template: { select: { baseType: true } }, slug: true, translations: { select: { name: true, languageCode: true } } },"
old1b = "  const designConfig = firstMenu?.designConfig as any;\n  const templateName = designConfig?.digital?.template || 'elegant';"
new1b = "  const templateName = (firstMenu?.template?.baseType as string) || 'elegant';"

if old1a in t1 and old1b in t1:
    t1 = t1.replace(old1a, new1a).replace(old1b, new1b)
    patches.append((P1, t1))
    print(f"[ok] {P1}")
elif "template: { select: { baseType: true } }" in t1:
    print(f"[skip] {P1} bereits gepatcht")
else:
    print(f"[FEHLER] {P1}: Anker nicht gefunden")
    sys.exit(1)

# ── 2) Menu-Liste-API: designConfig aus Response raus ───────────────────
P2 = Path("src/app/api/v1/menus/route.ts")
t2 = P2.read_text(encoding="utf-8")
old2 = "      designConfig: m.designConfig,\n      templateId: m.templateId,"
new2 = "      templateId: m.templateId,"
if old2 in t2:
    t2 = t2.replace(old2, new2)
    # Ausserdem das designConfig: true aus dem Prisma-Select entfernen, falls vorhanden
    t2 = t2.replace("      designConfig: true,\n", "")
    patches.append((P2, t2))
    print(f"[ok] {P2}")
elif "designConfig: m.designConfig" not in t2:
    print(f"[skip] {P2} bereits gepatcht")
else:
    print(f"[FEHLER] {P2}: Anker nicht gefunden")
    sys.exit(1)

# ── 3) PDF-Creator: Link auf /admin/menus/[id]/design entfernen ─────────
P3 = Path("src/app/admin/pdf-creator/page.tsx")
t3 = P3.read_text(encoding="utf-8")
old3 = "                <Link href={`/admin/menus/${menu.id}/design`}"
new3 = "                <Link href={`/admin/menus/${menu.id}`}"
if old3 in t3:
    t3 = t3.replace(old3, new3)
    # Label "Design bearbeiten" → "Karte öffnen" um Verwirrung zu vermeiden
    t3 = t3.replace("                  Design bearbeiten\n", "                  Karte öffnen\n")
    patches.append((P3, t3))
    print(f"[ok] {P3}")
elif "/admin/menus/${menu.id}/design" not in t3:
    print(f"[skip] {P3} bereits gepatcht")
else:
    print(f"[FEHLER] {P3}: Anker nicht gefunden")
    sys.exit(1)

# ── Schreiben ───────────────────────────────────────────────────────────
for path, content in patches:
    bak = path.with_suffix(path.suffix + ".bak-s6a")
    bak.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")
    path.write_text(content, encoding="utf-8")

print(f"\n{len(patches)} Datei(en) gepatcht, Backups mit .bak-s6a angelegt.")
