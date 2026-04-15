#!/usr/bin/env bash
# MenuCard Pro — Pass 4 (14.04.2026)
# Fixt B-8 (Plural) + zeigt exakten Filter-Block für B-4
# und setzt B-4 vollständig um
set -uo pipefail
cd /var/www/menucard-pro

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="/root/menucard-pass4-${STAMP}"
mkdir -p "$BACKUP"

echo "=========================================="
echo " Pass 4 — Backup: $BACKUP"
echo "=========================================="

###############################################################################
# Kontext: Filter-Block in menu-content.tsx sichtbar machen
###############################################################################
echo ""
echo "### Kontext: Filter-Logik (Zeilen 83-110) ###"
sed -n '83,110p' src/components/menu-content.tsx

###############################################################################
# B-8: Plural in src/app/[tenant]/page.tsx
###############################################################################
echo ""
echo "### B-8: Plural-Fix Tenant-Seite ###"
FILE1=$(find src/app -path '*/\[tenant\]/page.tsx' | head -1)
echo "Datei: $FILE1"
cp "$FILE1" "$BACKUP/tenant-page.tsx.bak"

# Zeile 31: const menuLabel = lang === 'en' ? 'menus' : 'Karten';
# Ersetze diese Zeile so, dass sie eine Funktion wird
python3 - <<PY
import pathlib, re
p = pathlib.Path("$FILE1")
src = p.read_text()
old = "const menuLabel = lang === 'en' ? 'menus' : 'Karten';"
new = """const menuLabel = (n: number) =>
    lang === 'en'
      ? (n === 1 ? 'menu' : 'menus')
      : (n === 1 ? 'Karte' : 'Karten');"""
if old in src:
    src = src.replace(old, new, 1)
else:
    print("  ✗ Original-Zeile nicht gefunden!")

# Verwendung: {loc.menus.length} {menuLabel}  ->  {loc.menus.length} {menuLabel(loc.menus.length)}
src = src.replace("{loc.menus.length} {menuLabel}",
                  "{loc.menus.length} {menuLabel(loc.menus.length)}")
p.write_text(src)
print("  ✓ Plural-Logik aktiv.")
PY

###############################################################################
# B-4: Suche in menu-content.tsx um Kategorie erweitern (robust)
###############################################################################
echo ""
echo "### B-4: Suche um Kategorie-Namen erweitern ###"
FILE2=src/components/menu-content.tsx
cp "$FILE2" "$BACKUP/menu-content.tsx.bak"

python3 - <<'PY'
import pathlib, re
p = pathlib.Path("src/components/menu-content.tsx")
src = p.read_text()

# sectionName-Definition ist schon drin (durch Pass 3) — verifizieren
if "const sectionName = t(section.translations).toLowerCase();" not in src:
    # Falls nicht drin, einfügen direkt vor "const name = t(item.translations)..."
    src = src.replace(
        "const name = t(item.translations).toLowerCase();",
        "const sectionName = t(section.translations).toLowerCase();\n          const name = t(item.translations).toLowerCase();",
        1
    )

# Finde die return-Zeile des Filter-Blocks mit .includes(q)
# Typische Patterns:
#   return name.includes(q) || desc.includes(q) || ...
#   if (!(name.includes(q) || desc.includes(q))) return false;

# Pattern 1: return expr.includes(q) || ... ;
m = re.search(r"(return\s+)([A-Za-z_][A-Za-z0-9_.]*\.includes\(q\)(?:\s*\|\|\s*[A-Za-z_][A-Za-z0-9_.()\s'|]+\.includes\(q\))+)(\s*;)", src)
if m:
    original = m.group(0)
    expr = m.group(2)
    if "sectionName.includes(q)" not in expr:
        patched = f"{m.group(1)}sectionName.includes(q) || {expr}{m.group(3)}"
        src = src.replace(original, patched, 1)
        print("  ✓ return-Matcher gepatcht.")
    else:
        print("  ℹ  sectionName bereits im return-Matcher.")
else:
    # Pattern 2: if (!(...)) return false
    m2 = re.search(r"if\s*\(\s*!\(\s*([^)]+\.includes\(q\)(?:\s*\|\|\s*[^)]+\.includes\(q\))+)\s*\)\s*\)\s*return\s+false\s*;", src)
    if m2:
        inner = m2.group(1)
        if "sectionName" not in inner:
            new_inner = f"sectionName.includes(q) || {inner}"
            src = src.replace(m2.group(0), f"if (!({new_inner})) return false;", 1)
            print("  ✓ if-not-Matcher gepatcht.")
    else:
        print("  ✗ Matcher-Muster nicht gefunden — Kontext oben prüfen.")

p.write_text(src)
PY

###############################################################################
# Build & Restart
###############################################################################
echo ""
echo "### Build & Restart ###"
npm run build 2>&1 | tail -10
pm2 restart menucard-pro
sleep 2

###############################################################################
# Verifikation
###############################################################################
echo ""
echo "### Verifikation ###"
echo "B-1 Startseite:"
curl -s https://menu.hotel-sonnblick.at/ | grep -oE "Getr[aä]nke|f[uü]r die" | sort -u
echo ""
echo "B-3 DB (Rosé/Jouët):"
export PGPASSWORD='ccTFFSJtuN7l1dC17PzT8Q'
psql -U menucard -h 127.0.0.1 -d menucard_pro -c "SELECT count(*) FROM \"ProductTranslation\" WHERE name LIKE '%Jouët%' OR name LIKE '%Secco Rosé%';"
echo ""
echo "B-8 Tenant:"
curl -s https://menu.hotel-sonnblick.at/hotel-sonnblick | grep -oE "[0-9]+ (Karte|Karten)" | sort -u
echo ""
echo "B-4 Suche aktiv im Code:"
grep -c "sectionName.includes(q)" src/components/menu-content.tsx

echo ""
echo "=========================================="
echo " FERTIG — Pass 4"
echo "=========================================="
