#!/bin/bash
# design-compliance-preflight.sh
# Wird auf dem Server ausgeführt. Robust gegen Schema-Abweichungen:
# Erkennt Menu-Template-FK und MenuPlacement-Menu-Pfad dynamisch.

set -euo pipefail
cd /var/www/menucard-pro
mkdir -p tests/design-compliance/snapshots

DB_URL=$(grep -E '^DATABASE_URL=' .env | sed 's/^DATABASE_URL=//; s/^"//; s/"$//')
export PGPASSWORD=$(echo "$DB_URL" | sed -E 's|.*://menucard:([^@]+)@.*|\1|')
PSQL='psql -U menucard -h 127.0.0.1 -d menucard_pro -tAF|'

echo "=== Schema-Probing ==="
MENU_COLS=$($PSQL -c "SELECT column_name FROM information_schema.columns WHERE table_name='Menu';")
PLACE_COLS=$($PSQL -c "SELECT column_name FROM information_schema.columns WHERE table_name='MenuPlacement';")
SECTION_COLS=$($PSQL -c "SELECT column_name FROM information_schema.columns WHERE table_name='MenuSection';")
DT_COLS=$($PSQL -c "SELECT column_name FROM information_schema.columns WHERE table_name='DesignTemplate';")
echo "Menu:           $(echo "$MENU_COLS"   | tr '\n' ' ')"
echo "MenuPlacement:  $(echo "$PLACE_COLS"  | tr '\n' ' ')"
echo "MenuSection:    $(echo "$SECTION_COLS"| tr '\n' ' ')"
echo "DesignTemplate: $(echo "$DT_COLS"     | tr '\n' ' ')"

# DesignTemplate-Spalten-Fallbacks (baseType vor type bevorzugen, das unterscheidet die 4 Varianten)
DT_KEY=""; DT_NAME=""; DT_SRC=""
for c in key slug code identifier templateKey baseType base_type; do echo "$DT_COLS" | grep -qx "$c" && DT_KEY="$c" && break; done
for c in name title label; do echo "$DT_COLS" | grep -qx "$c" && DT_NAME="$c" && break; done
for c in source origin type kind; do echo "$DT_COLS" | grep -qx "$c" && DT_SRC="$c" && break; done
echo "DT-Cols: key=$DT_KEY name=$DT_NAME source=$DT_SRC"

# Menu-Template-FK bestimmen
TPL_COL=""
for c in templateId designTemplateId design_template_id template_id activeTemplateId; do
  if echo "$MENU_COLS" | grep -qx "$c"; then TPL_COL="$c"; break; fi
done
echo "Template-FK: $TPL_COL"

# Menu → Product Pfad bestimmen
MP_MENU=""  # direkte FK auf Menu?
MP_SECTION=""   # FK auf MenuSection?
MP_PRODUCT=""
MP_SORT=""
for c in menuId; do echo "$PLACE_COLS" | grep -qx "$c" && MP_MENU="$c" && break; done
for c in menuSectionId sectionId; do echo "$PLACE_COLS" | grep -qx "$c" && MP_SECTION="$c" && break; done
for c in productId product_id; do echo "$PLACE_COLS" | grep -qx "$c" && MP_PRODUCT="$c" && break; done
for c in sortOrder order position sort_order; do echo "$PLACE_COLS" | grep -qx "$c" && MP_SORT="$c" && break; done
echo "Placement: menu=$MP_MENU section=$MP_SECTION product=$MP_PRODUCT sort=$MP_SORT"

SECTION_MENU=""
for c in menuId menu_id; do echo "$SECTION_COLS" | grep -qx "$c" && SECTION_MENU="$c" && break; done
echo "Section-Menu-FK: $SECTION_MENU"

# Item-Pfad-Subquery zusammenbauen
if [ -n "$MP_MENU" ] && [ -n "$MP_PRODUCT" ]; then
  ITEM_SQ="(SELECT mp.\"$MP_PRODUCT\" FROM \"MenuPlacement\" mp WHERE mp.\"$MP_MENU\" = m.id ORDER BY ${MP_SORT:+mp.\"$MP_SORT\" NULLS LAST,} mp.\"id\" LIMIT 1)"
elif [ -n "$MP_SECTION" ] && [ -n "$MP_PRODUCT" ] && [ -n "$SECTION_MENU" ]; then
  ITEM_SQ="(SELECT mp.\"$MP_PRODUCT\" FROM \"MenuPlacement\" mp JOIN \"MenuSection\" ms ON ms.id = mp.\"$MP_SECTION\" WHERE ms.\"$SECTION_MENU\" = m.id ORDER BY ${MP_SORT:+mp.\"$MP_SORT\" NULLS LAST,} mp.\"id\" LIMIT 1)"
else
  ITEM_SQ="NULL"
fi
echo "Item-Subquery: $ITEM_SQ"

echo ""
echo "=== Menus abfragen ==="
BASE_SQL="
SELECT json_agg(json_build_object(
  'tenant', t.slug, 'location', l.slug, 'menu', m.slug,
  'menuId', m.id, 'menuType', m.type,
  'publicPath', '/' || t.slug || '/' || l.slug || '/' || m.slug,
  'itemProductId', $ITEM_SQ
))
FROM \"Menu\" m
JOIN \"Location\" l ON l.id = m.\"locationId\"
JOIN \"Tenant\"   t ON t.id = l.\"tenantId\"
WHERE m.\"isActive\" = true;"
MENUS_BASE=$($PSQL -c "$BASE_SQL")

dtKeyExpr()  { [ -n "$DT_KEY" ]  && echo "COALESCE(dt.\"$DT_KEY\", '')"  || echo "''"; }
dtNameExpr() { [ -n "$DT_NAME" ] && echo "COALESCE(dt.\"$DT_NAME\", '')" || echo "''"; }
dtSrcExpr()  { [ -n "$DT_SRC" ]  && echo "COALESCE(dt.\"$DT_SRC\"::text, '')" || echo "''"; }

if [ -n "$TPL_COL" ]; then
  TPL_MAP=$($PSQL -c "
    SELECT json_agg(json_build_object('menuId', m.id,
           'templateId', m.\"$TPL_COL\",
           'templateKey', $(dtKeyExpr),
           'templateName', $(dtNameExpr),
           'templateSource', $(dtSrcExpr)))
    FROM \"Menu\" m
    LEFT JOIN \"DesignTemplate\" dt ON dt.id = m.\"$TPL_COL\"
    WHERE m.\"isActive\" = true;")
else
  TPL_MAP='[]'
fi

# Template-Liste (alle SYSTEM-Templates) mit dynamischen Spalten
KEY_SEL="''";   [ -n "$DT_KEY" ]  && KEY_SEL="COALESCE(\"$DT_KEY\", '')"
NAME_SEL="''";  [ -n "$DT_NAME" ] && NAME_SEL="COALESCE(\"$DT_NAME\", '')"
SRC_SEL="''";   [ -n "$DT_SRC" ]  && SRC_SEL="COALESCE(\"$DT_SRC\"::text, '')"
WHERE_SRC="";   [ -n "$DT_SRC" ]  && WHERE_SRC="WHERE \"$DT_SRC\"::text = 'SYSTEM'"

TEMPLATES_JSON=$($PSQL -c "
  SELECT json_agg(json_build_object(
    'id', id,
    'key',    $KEY_SEL,
    'name',   $NAME_SEL,
    'source', $SRC_SEL
  ))
  FROM \"DesignTemplate\" $WHERE_SRC;")
[ -z "$TEMPLATES_JSON" ] && TEMPLATES_JSON='[]'

ADMIN_JSON='[
  {"path":"/auth/login",          "label":"Login",         "needsAuth":false},
  {"path":"/admin",               "label":"Dashboard",     "needsAuth":true},
  {"path":"/admin/items",         "label":"Produkte",      "needsAuth":true},
  {"path":"/admin/menus",         "label":"Karten",        "needsAuth":true},
  {"path":"/admin/design",        "label":"Design",        "needsAuth":true},
  {"path":"/admin/media",         "label":"Bildarchiv",    "needsAuth":true},
  {"path":"/admin/qr-codes",      "label":"QR-Codes",      "needsAuth":true},
  {"path":"/admin/import",        "label":"Import",        "needsAuth":true},
  {"path":"/admin/analytics",     "label":"Analytics",     "needsAuth":true},
  {"path":"/admin/pdf-creator",   "label":"PDF-Creator",   "needsAuth":true},
  {"path":"/admin/settings",      "label":"Einstellungen", "needsAuth":true}
]'

BASE="$MENUS_BASE" TPL="$TPL_MAP" ADMIN="$ADMIN_JSON" TEMPLATES="${TEMPLATES_JSON:-[]}" node -e "
const fs=require('fs');
const base  = JSON.parse(process.env.BASE      || '[]') || [];
const tpl   = JSON.parse(process.env.TPL       || '[]') || [];
const admin = JSON.parse(process.env.ADMIN     || '[]') || [];
const tpls  = JSON.parse(process.env.TEMPLATES || '[]') || [];
const byMenu = Object.fromEntries(tpl.map(t => [t.menuId, t]));
const menus  = base.map(m => ({ ...m, ...(byMenu[m.menuId] || {}) }));
const out = {
  generatedAt: new Date().toISOString(),
  adminRoutes: admin,
  menus,
  templates: tpls
};
fs.writeFileSync('tests/design-compliance/routes.json', JSON.stringify(out, null, 2));
console.log('Vorflug OK:');
console.log('  admin:',     admin.length);
console.log('  menus:',     menus.length);
console.log('  templates:', tpls.length);
if (menus[0]) console.log('  Beispiel-Menu:', JSON.stringify(menus[0], null, 2));
"
