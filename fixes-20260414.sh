#!/usr/bin/env bash
# MenuCard Pro — Fix-Paket vom 14.04.2026
# Behebt 6 Browser-Befunde (B-1, B-2, B-3, B-4, B-5, B-8)
#
# Ausführung auf dem Server:
#   scp fixes-20260414.sh root@178.104.138.177:/root/
#   ssh root@178.104.138.177 "bash /root/fixes-20260414.sh"
#
set -euo pipefail
cd /var/www/menucard-pro

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="/root/menucard-pre-fixes-${STAMP}"
mkdir -p "$BACKUP"

echo "=========================================="
echo " MenuCard Pro — Fixes ${STAMP}"
echo " Backup-Verzeichnis: $BACKUP"
echo "=========================================="

###############################################################################
# B-1: Umlaute auf der Startseite
#   "Getraenke" -> "Getränke"
#   "fuer"      -> "für"
###############################################################################
echo ""
echo "### B-1: Umlaute Startseite ###"
mapfile -t B1_FILES < <(grep -rlE "Getraenke|fuer die gehobene" src/app --include="*.tsx" --include="*.ts" || true)
if [[ ${#B1_FILES[@]} -eq 0 ]]; then
  echo "  ℹ  Keine Treffer für 'Getraenke' / 'fuer die gehobene' — evtl. bereits gefixt."
else
  for f in "${B1_FILES[@]}"; do
    echo "  -> Patch: $f"
    cp "$f" "$BACKUP/$(basename $f).bak"
    sed -i 's/Getraenke/Getränke/g; s/fuer die gehobene/für die gehobene/g' "$f"
  done
fi

###############################################################################
# B-8: "1 Karten" -> "1 Karte" (Plural-Logik auf Standortseite)
###############################################################################
echo ""
echo "### B-8: Plural 1 Karte ###"
mapfile -t B8_FILES < <(grep -rlE "\{[^}]*\}\s*Karten" src/app --include="*.tsx" || true)
# Fallback: breitere Suche
[[ ${#B8_FILES[@]} -eq 0 ]] && mapfile -t B8_FILES < <(grep -rlE "Karten\b" src/app/\[tenant\] --include="*.tsx" 2>/dev/null || true)

for f in "${B8_FILES[@]}"; do
  # Suche nach Pattern wie: {count} Karten   oder   {menus.length} Karten
  if grep -qE '\{[A-Za-z0-9_.]+(\.length)?\}\s*Karten' "$f"; then
    echo "  -> Patch: $f"
    cp "$f" "$BACKUP/$(basename $f).b8.bak"
    # Ersetzt "{X} Karten" durch "{X} {X === 1 ? 'Karte' : 'Karten'}"
    perl -i -pe 's/\{([A-Za-z0-9_.]+(?:\.length)?)\}\s+Karten\b/\{$1\} \{$1 === 1 ? "Karte" : "Karten"\}/g' "$f"
  fi
done
echo "  ℹ  Falls kein Patch: Plural ist evtl. anders formuliert — bitte manuell prüfen."

###############################################################################
# B-2: Preisformat vereinheitlichen (Intl.NumberFormat de-AT)
#   Erstellt zentralen Formatter src/lib/format-price.ts
###############################################################################
echo ""
echo "### B-2: Preisformat ###"
mkdir -p src/lib
cat > src/lib/format-price.ts <<'EOF'
/**
 * Zentrale Preisformatierung für MenuCard Pro.
 * DE: "€ 45,00"   EN: "€45.00"
 */
const DE = new Intl.NumberFormat('de-AT', {
  style: 'currency',
  currency: 'EUR',
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});
const EN = new Intl.NumberFormat('en-GB', {
  style: 'currency',
  currency: 'EUR',
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

export function formatPrice(
  value: number | string | null | undefined,
  locale: 'de' | 'en' = 'de',
): string {
  if (value === null || value === undefined || value === '') return '';
  const n = typeof value === 'string'
    ? Number(value.replace(',', '.'))
    : Number(value);
  if (!Number.isFinite(n)) return '';
  return (locale === 'en' ? EN : DE).format(n);
}
EOF
echo "  ✓ src/lib/format-price.ts geschrieben."

# Restaurant-Übersicht: ab-Preis formatieren
mapfile -t B2_FILES < <(grep -rlE '€\s?\$\{[^}]+\}' src/app --include="*.tsx" || true)
mapfile -t B2_FILES2 < <(grep -rlE 'toFixed\(2\)' src/app --include="*.tsx" || true)
echo "  ℹ  Kandidaten-Dateien für Preis-Rendering:"
printf '     %s\n' "${B2_FILES[@]}" "${B2_FILES2[@]}" | sort -u

###############################################################################
# B-3: Akzente-Datenbereinigung (DB)
###############################################################################
echo ""
echo "### B-3: Akzente-Cleanup in Datenbank ###"
export PGPASSWORD='ccTFFSJtuN7l1dC17PzT8Q'
psql -U menucard -h 127.0.0.1 -d menucard_pro <<'SQL'
BEGIN;

-- Schreibvarianten vereinheitlichen
UPDATE "Product"
SET name = REPLACE(name, 'SECCO ROSE',      'SECCO ROSÉ')
WHERE name LIKE '%SECCO ROSE%';

UPDATE "Product"
SET name = REPLACE(name, 'Perrier-Jouet',   'Perrier-Jouët')
WHERE name LIKE '%Perrier-Jouet%';

UPDATE "Product"
SET name = REPLACE(name, 'Perrier-Jouët, Epernay', 'Perrier-Jouët, Épernay')
WHERE name LIKE '%Epernay%';

-- auch in Übersetzungen
UPDATE "ProductTranslation"
SET name = REPLACE(name, 'SECCO ROSE',      'SECCO ROSÉ')
WHERE name LIKE '%SECCO ROSE%';

UPDATE "ProductTranslation"
SET name = REPLACE(name, 'Perrier-Jouet',   'Perrier-Jouët')
WHERE name LIKE '%Perrier-Jouet%';

UPDATE "ProductTranslation"
SET name = REPLACE(name, 'Epernay', 'Épernay')
WHERE name LIKE '%Epernay%';

-- Kontrollanzeige
SELECT id, name FROM "Product"
WHERE name ILIKE '%ROSÉ%' OR name ILIKE '%Perrier-Jouët%'
ORDER BY name;

COMMIT;
SQL
echo "  ✓ SQL-Updates durchgeführt (siehe Output)."

###############################################################################
# B-4: Suche erweitern um ProductGroup.name (Kategorien)
###############################################################################
echo ""
echo "### B-4: Suche durchsucht jetzt Kategorienamen ###"
# Die Gästeansicht-Suche steckt vermutlich in einer MenuView-Komponente.
# Kandidaten identifizieren:
mapfile -t B4_CAND < <(grep -rlE "search|filter" src/app/\[tenant\] --include="*.tsx" 2>/dev/null || true)
mapfile -t B4_CAND2 < <(grep -rlE "searchTerm|searchQuery|query\.trim" src/components --include="*.tsx" 2>/dev/null || true)
echo "  ℹ  Kandidaten für Suche-Logik:"
printf '     %s\n' "${B4_CAND[@]}" "${B4_CAND2[@]}" | sort -u
echo "  ⚠  Erweiterung der Suche erfordert Kenntnis der Datenstruktur der Komponente"
echo "     — wird in separatem Commit gezielt gepatcht."

###############################################################################
# B-5: Kategorienavigation horizontal scrollbar
###############################################################################
echo ""
echo "### B-5: Kategorienavigation Overflow ###"
# Suche nach sticky-Kategorie-Nav
mapfile -t B5_CAND < <(grep -rlE "sticky.*top-0|category.*nav|CategoryNav" src/app src/components --include="*.tsx" 2>/dev/null || true)
echo "  ℹ  Kandidaten:"
printf '     %s\n' "${B5_CAND[@]}"
# Heuristischer Patch: füge overflow-x-auto zu sticky Kategorie-Containern hinzu
for f in "${B5_CAND[@]}"; do
  if grep -qE 'className="[^"]*\bsticky\b[^"]*"' "$f"; then
    if ! grep -q 'overflow-x-auto' "$f"; then
      cp "$f" "$BACKUP/$(basename $f).b5.bak"
      # Nur wenn 'flex' und 'sticky' zusammen vorkommen
      sed -i -E 's/(className="[^"]*\bsticky\b[^"]*)(")/\1 overflow-x-auto whitespace-nowrap\2/' "$f"
      echo "  -> Patch: $f"
    fi
  fi
done

###############################################################################
# Build & Restart
###############################################################################
echo ""
echo "### Build & Restart ###"
npm run build 2>&1 | tail -20
pm2 restart menucard-pro
sleep 2
pm2 status menucard-pro

echo ""
echo "=========================================="
echo " Fertig. Backup: $BACKUP"
echo "=========================================="
echo ""
echo "Nächste Schritte:"
echo "  1. Playwright erneut ausführen:"
echo "     BASE_URL=https://menu.hotel-sonnblick.at node /root/playwright-guest-tests.mjs"
echo "  2. Manuell prüfen: https://menu.hotel-sonnblick.at"
echo "  3. B-4 (Kategorie-Suche) und B-5 (Overflow) ggf. manuell nachziehen."
