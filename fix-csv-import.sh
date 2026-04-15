#!/bin/bash
# Fix CSV-Import: BeverageCategory Enum-Validierung + NaN-Schutz + Template-Fix
# Datum: 10.04.2026

set -e
cd /var/www/menucard-pro

echo "=== CSV-Import Fix ==="

# === 1. BeverageCategory Enum-Werte aus Prisma Schema lesen ===
echo "[1/4] Lese BeverageCategory Enum..."
grep -A 20 'enum BeverageCategory' prisma/schema.prisma || echo "Enum nicht gefunden - verwende Standardwerte"

# === 2. Import-Route patchen: Enum-Validierung + NaN-Schutz ===
echo "[2/4] Patche Import-Route..."

# Erstelle die verbesserte beverage-detail Erstellung als Funktion
# Wir ersetzen den gesamten Beverage-Detail-Block im CREATE-Abschnitt
python3 -c "
import re

with open('src/app/api/v1/import/route.ts', 'r') as f:
    code = f.read()

# Enum-Validierungs-Helper einfügen (nach den Type-Definitionen)
enum_helper = '''
const VALID_BEVERAGE_CATEGORIES = ['BEER', 'WINE', 'SPIRIT', 'COCKTAIL', 'SOFT_DRINK', 'HOT_DRINK', 'JUICE', 'WATER', 'OTHER'];
const VALID_WINE_STYLES = ['RED', 'WHITE', 'ROSE', 'SPARKLING', 'DESSERT', 'FORTIFIED', 'ORANGE', 'NATURAL'];
const VALID_BODY = ['LIGHT', 'MEDIUM_LIGHT', 'MEDIUM', 'MEDIUM_FULL', 'FULL'];
const VALID_SWEETNESS = ['BONE_DRY', 'DRY', 'OFF_DRY', 'MEDIUM_DRY', 'MEDIUM_SWEET', 'SWEET', 'VERY_SWEET'];

function safeEnum<T>(val: string | undefined | null, validValues: string[]): T | null {
  if (!val) return null;
  const upper = val.toUpperCase().trim();
  return validValues.includes(upper) ? upper as T : null;
}

function safeFloat(val: string | undefined | null): number | null {
  if (!val) return null;
  const num = parseFloat(val.replace(',', '.'));
  return isNaN(num) ? null : num;
}
'''

# Einfügen nach 'type ParsedProduct' Block
insert_pos = code.find('function normalize(')
if insert_pos > 0:
    code = code[:insert_pos] + enum_helper + '\n' + code[insert_pos:]

# Ersetze alle p.bevCategory.toUpperCase() as any mit safeEnum
code = code.replace(
    \"p.bevCategory ? p.bevCategory.toUpperCase() as any : null\",
    \"safeEnum(p.bevCategory, VALID_BEVERAGE_CATEGORIES)\",
)

# Ersetze alle Wein-Enum-Felder
code = code.replace(
    \"p.wineStyle ? p.wineStyle.toUpperCase() as any : null\",
    \"safeEnum(p.wineStyle, VALID_WINE_STYLES)\",
)
code = code.replace(
    \"p.body ? p.body.toUpperCase() as any : null\",
    \"safeEnum(p.body, VALID_BODY)\",
)
code = code.replace(
    \"p.sweetness ? p.sweetness.toUpperCase() as any : null\",
    \"safeEnum(p.sweetness, VALID_SWEETNESS)\",
)

# Ersetze alle parseFloat fuer alcoholContent mit safeFloat
code = code.replace(
    \"p.bevAlcohol ? parseFloat(p.bevAlcohol.replace(',', '.')) : null\",
    \"safeFloat(p.bevAlcohol)\",
)
code = code.replace(
    \"p.alcohol ? parseFloat(p.alcohol.replace(',', '.')) : null\",
    \"safeFloat(p.alcohol)\",
)

# Fix auch vintage
code = code.replace(
    \"p.vintage ? parseInt(p.vintage) : null\",
    \"p.vintage ? (isNaN(parseInt(p.vintage)) ? null : parseInt(p.vintage)) : null\",
)

with open('src/app/api/v1/import/route.ts', 'w') as f:
    f.write(code)

print('Route gepatcht!')
"

echo "[3/4] Aktualisiere CSV-Template..."
cat > public/templates/import-vorlage.csv << 'CSVEOF'
sku;type;name_de;name_en;short_description_de;short_description_en;group;fill_quantity;price_level;price;purchase_price;winery;vintage;grapes;region;country;wine_style;body;sweetness;bottle_size;alcohol;serving_temp;tasting_notes;food_pairing;brand;producer;bev_category;bev_alcohol;carbonated;origin
WEIN-001;WINE;Grüner Veltliner Smaragd;Grüner Veltliner Smaragd;Frisch und mineralisch;Fresh and mineral;Getränke;Flasche 0,75l;Restaurant;38.50;12.00;Weingut Hirtzberger;2022;Grüner Veltliner;Wachau;Österreich;WHITE;MEDIUM;DRY;0.75l;13.5;8-10°C;Aromen von grünem Apfel und weißem Pfeffer;Fisch, Wiener Schnitzel;;;;;;
WEIN-001;WINE;Grüner Veltliner Smaragd;Grüner Veltliner Smaragd;;;Getränke;1/8 offen;Restaurant;6.80;;;;;;;;;;;;;;;;;;;;
DRINK-001;DRINK;Aperol Spritz;Aperol Spritz;Der Klassiker;The classic;Getränke;Cocktail;Bar;8.90;2.50;;;;;;;;;;;;;;Aperol;Campari Group;COCKTAIL;11;nein;Italien
FOOD-001;FOOD;Wiener Schnitzel;Wiener Schnitzel;Vom Kalb mit Preiselbeeren;Veal with lingonberries;Speisen;Portion;Restaurant;22.50;6.80;;;;;;;;;;;;;;;;;;;
CSVEOF

echo "[4/4] Build + Restart..."
npm run build 2>&1 | tail -5
pm2 restart menucard-pro

echo ""
echo "=== Fix fertig! ==="
echo "Bitte Test-Produkte loeschen und CSV-Import erneut testen."
