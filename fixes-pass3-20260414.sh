#!/usr/bin/env bash
# MenuCard Pro — Pass 3 (14.04.2026)
# B-3 (Akzente, sauber), B-4 (Suche), B-5 (Sticky-Nav whitespace)
# + Diagnose für verbleibende Dateien B-8/B-2
set -uo pipefail
cd /var/www/menucard-pro

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="/root/menucard-pass3-${STAMP}"
mkdir -p "$BACKUP"

echo "=========================================="
echo " Pass 3 — Backup: $BACKUP"
echo "=========================================="

###############################################################################
# B-3: Akzente-Cleanup auf ProductTranslation
###############################################################################
echo ""
echo "### B-3: Akzente-Cleanup ###"
export PGPASSWORD='ccTFFSJtuN7l1dC17PzT8Q'
psql -U menucard -h 127.0.0.1 -d menucard_pro <<'SQL'
BEGIN;

-- Nur die zwei eindeutigen Fälle:
UPDATE "ProductTranslation"
SET name = REPLACE(name, 'Secco Rose', 'Secco Rosé')
WHERE name LIKE 'Secco Rose%';

UPDATE "ProductTranslation"
SET name = REPLACE(name, 'Perrier-Jouet', 'Perrier-Jouët')
WHERE name LIKE '%Perrier-Jouet%';

-- Kontrolle
SELECT pt."languageCode", pt.name
FROM "ProductTranslation" pt
WHERE pt.name LIKE '%Rosé%' OR pt.name LIKE '%Jouët%'
ORDER BY pt.name;

COMMIT;
SQL

###############################################################################
# B-4: Suche erweitern um Kategorie-/Sektion-Namen
###############################################################################
echo ""
echo "### B-4: Suche um Kategorie-Namen erweitern ###"
FILE=src/components/menu-content.tsx
cp "$FILE" "$BACKUP/menu-content.tsx.bak"

# Patche den items.filter-Block: wenn sectionName matcht, Item bleibt drin.
# Einfügung direkt nach "const longDesc = ..." Zeile.
# Ersetzung: adde eine Variable sectionName und nimm sie in den OR-Matcher auf.

python3 - <<'PY'
import re, pathlib
p = pathlib.Path("src/components/menu-content.tsx")
src = p.read_text()

# 1. filteredSections-Block finden und erweitern
# Suche nach:  return sections.map(section => { ... const filtered = section.items.filter(...)
# Alternative: direkt den Abschnitt  const q = query.toLowerCase().trim();
old = """const q = query.toLowerCase().trim();"""
if old not in src:
    print("  ✗ Marker 'const q = query.toLowerCase().trim();' nicht gefunden!")
else:
    new = """const q = query.toLowerCase().trim();
    // B-4: Sektion-/Kategorie-Name auch durchsuchen"""
    src = src.replace(old, new, 1)

# 2. Im section.items.filter — Match auf sectionName hinzufügen
# Suche ein Pattern wie: const name = t(item.translations).toLowerCase();
old2 = "const name = t(item.translations).toLowerCase();"
if old2 in src:
    new2 = """const sectionName = t(section.translations).toLowerCase();
          const name = t(item.translations).toLowerCase();"""
    src = src.replace(old2, new2, 1)
else:
    print("  ✗ Marker 'const name = t(item.translations).toLowerCase();' nicht gefunden!")

# 3. Im OR-Matcher: wenn q in sectionName vorkommt, ganzer Abschnitt durch
# Finde den Block der die OR-Kombination baut. Tipisch:
#   if (q && !(name.includes(q) || desc.includes(q) || ...)) return false;
# Ersetze durch Variante, die auch sectionName prüft.
# Da wir die genaue Form nicht kennen, suchen wir nach '.includes(q)' Mehrfachvorkommen
# und packen sectionName.includes(q) mit rein.
m = re.search(r"if\s*\(\s*q\s*&&\s*!\(\s*(.*?)\)\s*\)\s*return\s+false;", src, re.DOTALL)
if m:
    inner = m.group(1)
    if "sectionName" not in inner:
        new_inner = f"sectionName.includes(q) || {inner.strip()}"
        src = src.replace(m.group(0),
                          f"if (q && !({new_inner})) return false;", 1)
else:
    print("  ✗ Matcher-Block 'if (q && !(...))' nicht gefunden!")

p.write_text(src)
print("  ✓ menu-content.tsx gepatcht.")
PY

###############################################################################
# B-5: Sticky-Nav — whitespace-nowrap auf Buttons
###############################################################################
echo ""
echo "### B-5: Sticky-Nav whitespace-nowrap ###"
# Ziel-Zeile 184: className="flex-shrink-0 px-4 py-2.5 text-xs font-semibold uppercase tracking-wider transition-colors"
if grep -q 'flex-shrink-0 px-4 py-2.5 text-xs font-semibold uppercase tracking-wider transition-colors' "$FILE"; then
  sed -i 's/flex-shrink-0 px-4 py-2.5 text-xs font-semibold uppercase tracking-wider transition-colors/flex-shrink-0 whitespace-nowrap px-4 py-2.5 text-xs font-semibold uppercase tracking-wider transition-colors/' "$FILE"
  echo "  ✓ whitespace-nowrap eingefügt."
else
  echo "  ℹ  Ziel-Klasse nicht (mehr) vorhanden — Pass 1 hat sie evtl. schon verändert."
  echo "  Aktuelle Zeile 184:"
  sed -n '184p' "$FILE"
fi

###############################################################################
# Build & Restart
###############################################################################
echo ""
echo "### Build & Restart ###"
npm run build 2>&1 | tail -15
pm2 restart menucard-pro
sleep 2

###############################################################################
# Diagnose für B-8 (Plural) und B-2 (Preisformat Location-Übersicht)
###############################################################################
echo ""
echo "=========================================="
echo " Diagnose für B-8 und B-2"
echo "=========================================="

echo ""
echo "--- Tenant-Seite: src/app/[tenant]/page.tsx ---"
find 'src/app' -path '*/\[tenant\]/page.tsx' -exec cat -n {} \;

echo ""
echo "--- Location-Seite: [tenant]/[location]/page.tsx ---"
find 'src/app' -path '*/\[location\]/page.tsx' -exec cat -n {} \;

echo ""
echo "--- Grep: 'Karten' im gesamten src/ ---"
grep -rn 'Karten' src/app --include="*.tsx" | grep -vE 'Karten:|Karten,|Karten\.|QRCode|Karten"|Karten\*|KartenAnsicht|KartenKey|Kartenverwaltung|Kartenliste' | head -30

echo ""
echo "--- Grep: 'toFixed' im gesamten src/ ---"
grep -rn 'toFixed' src/app src/components --include="*.tsx" | head -20

echo ""
echo "--- Grep: '€' neben '{' (Preis-Rendering ohne Intl) ---"
grep -rnE '€\s*\$?\{[^}]+\}|\{[^}]+\}\s*€' src/app src/components --include="*.tsx" | head -20

echo ""
echo "=========================================="
echo " FERTIG"
echo "=========================================="
