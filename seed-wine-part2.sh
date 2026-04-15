#!/bin/bash
# =====================================================
# MenuCard Pro - Weinkarte Teil 2 Seed Script
# Hotel Sonnblick, Saalbach
# Inhalt: Restliche Rotweine, Dessertwein, Likoerwein/Portwein, Wein im Glas
# =====================================================

set -e

cd /var/www/menucard-pro

echo "=== Weinkarte Teil 2 - Seed Script ==="
echo ""

# Get IDs
TENANT_ID=$(npx prisma db execute --stdin <<< "SELECT id FROM \"Tenant\" WHERE slug='hotel-sonnblick' LIMIT 1;" 2>/dev/null | grep -E '^\s' | xargs)
if [ -z "$TENANT_ID" ]; then
  echo "ERROR: Tenant not found!"
  exit 1
fi
echo "Tenant ID: $TENANT_ID"

LOCATION_ID=$(npx prisma db execute --stdin <<< "SELECT id FROM \"Location\" WHERE \"tenantId\"='$TENANT_ID' AND slug='restaurant' LIMIT 1;" 2>/dev/null | grep -E '^\s' | xargs)
echo "Location ID: $LOCATION_ID"

WINE_MENU_ID=$(npx prisma db execute --stdin <<< "SELECT id FROM \"Menu\" WHERE \"locationId\"='$LOCATION_ID' AND slug='weinkarte' LIMIT 1;" 2>/dev/null | grep -E '^\s' | xargs)
echo "Wine Menu ID: $WINE_MENU_ID"

if [ -z "$WINE_MENU_ID" ]; then
  echo "ERROR: Wine menu not found! Make sure seed-wine.sh was deployed first."
  exit 1
fi

# Get existing section count for sort order
EXISTING_SECTIONS=$(npx prisma db execute --stdin <<< "SELECT COUNT(*) FROM \"MenuSection\" WHERE \"menuId\"='$WINE_MENU_ID';" 2>/dev/null | grep -E '^\s*[0-9]' | xargs)
echo "Existing sections: $EXISTING_SECTIONS"
SORT_START=$((EXISTING_SECTIONS + 1))

echo ""
echo "Seeding via SQL..."

# Use psql directly for reliable UTF-8
export PGPASSWORD="ccTFFSJtuN7l1dC17PzT8Q"
PSQL="psql postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

$PSQL <<'EOSQL'

-- =====================================================
-- HELPER: Generate cuid-like IDs
-- =====================================================
CREATE OR REPLACE FUNCTION gen_id() RETURNS TEXT AS $$
BEGIN
  RETURN 'cl' || substr(md5(random()::text || clock_timestamp()::text), 1, 23);
END;
$$ LANGUAGE plpgsql;

-- Get reference IDs
DO $$
DECLARE
  v_tenant_id TEXT;
  v_location_id TEXT;
  v_wine_menu_id TEXT;
  v_section_id TEXT;
  v_item_id TEXT;
  v_sort INT;
BEGIN

SELECT id INTO v_tenant_id FROM "Tenant" WHERE slug='hotel-sonnblick' LIMIT 1;
SELECT id INTO v_location_id FROM "Location" WHERE "tenantId"=v_tenant_id AND slug='restaurant' LIMIT 1;
SELECT id INTO v_wine_menu_id FROM "Menu" WHERE "locationId"=v_location_id AND slug='weinkarte' LIMIT 1;

-- Get max sort order of existing sections
SELECT COALESCE(MAX("sortOrder"), 0) INTO v_sort FROM "MenuSection" WHERE "menuId"=v_wine_menu_id;

-- =====================================================
-- SECTION: Rotwein International (Italien)
-- =====================================================
v_sort := v_sort + 1;
v_section_id := gen_id();
INSERT INTO "MenuSection" (id, "menuId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES (v_section_id, v_wine_menu_id, 'rotwein-international', v_sort, true, NOW(), NOW());
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name, description)
VALUES (gen_id(), v_section_id, 'de', 'Rotwein International', 'Italien, Spanien, Australien');
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name, description)
VALUES (gen_id(), v_section_id, 'en', 'Red Wine International', 'Italy, Spain, Australia');

-- Costasera Amarone 2012
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 1, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Costasera Amarone della Valpolicella Classico 2012',
'Masi Agricola, Gargagnago di Valpolicella',
'Intensives, sattes Rubinrot. Filigran-elegante Nase nach reifen Waldbeeren, Schokolade, im Nachhall leicht nach Zigarrenkiste. Am Gaumen überragt der süße Schmelz, baut sich weit und in vielen Schichten auf, elegant, im zweiten Teil stets saftig und ausgewogen, wunderbar harmonisch bis ins lange Finale.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Costasera Amarone della Valpolicella Classico 2012',
'Masi Agricola, Gargagnago di Valpolicella',
'Lots of complexity comes through from the outset on the nose, borne out in terms of smoky black cherries, dried rose stems, asphalt, tar and licorice. Full, structured body that dives through layers of dark fruit, driven along by active acidity all the way to the long but not cloying finish.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 99.90, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize", "tastingNotes")
VALUES (gen_id(), v_item_id, 'Masi Agricola', 2012, ARRAY['Corvina','Rondinella','Molinara'], 'Venetien', 'Italien', 'Amarone della Valpolicella Classico DOCG', 'RED', 'FULL', 'DRY', '0.75l',
'Intensives Rubinrot, Waldbeeren, Schokolade, Zigarrenkiste. Süßer Schmelz, vielschichtig, harmonisch.');

-- Chianti Classico 2020
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Chianti Classico 2020',
'Villa Trasqua, Castellina in Chianti',
'Leuchtendes Rubingranat. Feines Spiel zwischen reifer Kirschfrucht und würzigen Komponenten, Zimt und Kardamom, dazu Milchschokolade. Griffiges, herzhaftes Tannin bestimmt den Gaumen, süßer Fruchtschmelz, dazu etwas erdige Komponenten.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Chianti Classico 2020',
'Villa Trasqua, Castellina in Chianti',
'Lively ruby red colour with purple reflections. Nose begins with floral hints of violet and fruity of ripe cherry and raspberry, followed by notes of sweet spices, such as vanilla and liquorice. In the mouth it is fresh with a pleasant tannin which makes it vibrant and dynamic.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 41.90, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Villa Trasqua', 2020, ARRAY['Sangiovese','Merlot','Cabernet Sauvignon'], 'Toskana', 'Italien', 'Chianti Classico DOCG', 'RED', 'MEDIUM_FULL', 'DRY', '0.75l');

-- Rosso di Montalcino 2020
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 3, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Rosso di Montalcino 2020',
'Azienda Agricola Altesino, Montalcino',
'Aromen von Zedernholz, Gewürzen, Kirschen und Mineralien formen zusammen ein einladendes Bouquet. Am Gaumen rund und kraftvoll, mit nach Lavendel schmeckender Kirschfrucht und einer hellen Säure. Leicht strukturiert und doch kraftvoll.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Rosso di Montalcino 2020',
'Azienda Agricola Altesino, Montalcino',
'Cedary spice, dried cherries and crushed rocks form an inviting display. This is a round and forward effort, with lavender-tinged cherry fruit and bright acidity that adds an energetic feel. Lightly structured yet potent, finishes with admirable length and class.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 47.10, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Altesino', 2020, ARRAY['Sangiovese'], 'Toskana', 'Italien', 'Rosso di Montalcino DOC', 'RED', 'MEDIUM_FULL', 'DRY', '0.75l');

-- Bastioni 2020
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Bastioni 2020',
'Tenuta I Collazzi, Tavarnelle',
'Intensives Rubinrot mit leichten granatroten Reflexen. Die Nase ist intensiv mit Noten von roten Früchten, Kirsche, Pflaume und Gewürzen. Am Gaumen würzig und komplex.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Bastioni 2020',
'Tenuta I Collazzi, Tavarnelle',
'Very open on the nose showing notes of geraniums, black cherries, mandarin peel and bergamot. Full bodied, rounded tannins and a juicy, distended finale.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 49.20, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Tenuta I Collazzi', 2020, ARRAY['Sangiovese','Merlot','Malvasia Nera'], 'Toskana', 'Italien', 'Chianti Classico DOCG', 'RED', 'FULL', 'DRY', '0.75l');

-- Barolo 2018
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "highlightType", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 5, true, false, true, 'PREMIUM', NOW(), NOW());

INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Barolo 2018',
'Fratelli Revello, La Morra',
'Der Jahrgang 2018 zeigt sich gleich von Anfang an anmutig und einladend. Zerdrückte Blumen, süße rote Beeren, Kirsche, Gewürze und Lakritze verleihen diesem ätherischen, seidigen Barolo seine Anmut.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Barolo 2018',
'Fratelli Revello, La Morra',
'The 2018 is gracious and inviting right out of the gate. Crushed flowers, sweet red berry fruit, kirsch, spice and licorice all grace this ethereal, silky Barolo.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 68.10, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Fratelli Revello', 2018, ARRAY['Nebbiolo'], 'Piemont', 'Italien', 'Barolo DOCG', 'RED', 'FULL', 'DRY', '0.75l');

-- Sovrana Barbera d'Alba 2020
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 6, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Sovrana Barbera d''Alba 2020',
'Beni di Batasiolo, La Morra',
'Rubinrot mit violetten Nuancen. Intensiver Duft von Beeren, Kirschen, und reifem Obst. Angenehme würzige Noten mit zarten Holz- und Blumenaromen. Frisch im Mund mit harmonisch hohem Alkoholgehalt.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Sovrana Barbera d''Alba 2020',
'Beni di Batasiolo, La Morra',
'Ruby red with delicate purple tinges. Intense and persistent expression with notes of berries, cherries and ripe fruit. Pleasant spicy flavours and delicate sensations of wood and flowers. Exciting crispness harmonises a high yet pleasant alcohol content.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 41.90, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Beni di Batasiolo', 2020, ARRAY['Barbera'], 'Piemont', 'Italien', 'Barbera d''Alba DOC', 'RED', 'MEDIUM_FULL', 'DRY', '0.75l');

-- Rioja Reserva 2020 (Spanien)
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 7, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Rioja Reserva 2020',
'Marqués de Riscal, Elciego',
'Tiefdunkle, intensiv kirschrote Farbe. Das Bouquet ist ausdrucksstark, mit Anklängen von Lakritze, Zimt, Vanille, schwarzem Pfeffer und feinen Röstnoten über der reifen, dunkelbeerigen Frucht. Am Gaumen frisch und zugänglich, mit geschliffenen Tanninen und langem, balsamischem Abgang.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Rioja Reserva 2020',
'Marqués de Riscal, Elciego',
'Deep black cherry red with intense color. The nose is expressive, with aromas of liquorice, cinnamon, black pepper, and subtle hints of barrel aging, balanced by ripe, concentrated fruit. Fresh and approachable on the palate, with polished tannins and a long, balsamic finish.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 69.20, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Marqués de Riscal', 2020, ARRAY['Tempranillo','Graciano'], 'La Rioja', 'Spanien', 'Rioja DOCa', 'RED', 'MEDIUM_FULL', 'DRY', '0.75l');

-- Finniss River Shiraz 2018 (Australien)
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 8, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Finniss River Shiraz Sea Eagle Vineyard 2018',
'Salomon Estate, McLaren Vale',
'Reif, vital und rotfruchtig. Maulbeeren, Granatäpfel und Himbeeren, umrahmt von exotischen Gewürzen und heller Säure.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Finniss River Shiraz Sea Eagle Vineyard 2018',
'Salomon Estate, McLaren Vale',
'Ripe, vital and red-fruited. Mulberries, pomegranates and raspberries are the order of the day, hemmed in by exotic spice and bright acidity.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 90.20, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Salomon Estate', 2018, ARRAY['Syrah'], 'South Australia', 'Australien', 'RED', 'FULL', 'DRY', '0.75l');

-- =====================================================
-- SECTION: Rotwein Österreich Cuvées & Merlot (erweitert)
-- =====================================================
v_sort := v_sort + 1;
v_section_id := gen_id();
INSERT INTO "MenuSection" (id, "menuId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES (v_section_id, v_wine_menu_id, 'rotwein-cuvees-merlot', v_sort, true, NOW(), NOW());
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name, description)
VALUES (gen_id(), v_section_id, 'de', 'Rotwein Cuvées & Merlot', 'Österreich');
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name, description)
VALUES (gen_id(), v_section_id, 'en', 'Red Wine Cuvées & Merlot', 'Austria');

-- Unplugged Merlot 2020
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "highlightType", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 1, true, false, true, 'PREMIUM', NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Unplugged Merlot 2020',
'Weingut Hannes Reeh, Andau | Burgenland QW',
'Dunkles Rubingranat, opaker Kern, violette Reflexe. Nougat und Lakritze im Duft, schwarze Waldbeeren, mit feiner Kräuterwürze und Brombeerkonfit unterlegt. Am Gaumen kraftvoll, komplex, saftig, dunkle Kirschen, reife, tragende Tannine, schokoladig und anhaftend, zeigt Länge und Potenzial.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Unplugged Merlot 2020',
'Weingut Hannes Reeh, Andau | Burgenland QW',
'On the nose, notes of nougat and licorice, layered with black forest berries, fine herbal spice and blackberry preserves. The palate is powerful, complex and juicy, with dark cherries, ripe and structured tannins, chocolaty texture and persistent grip.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 104.90, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Hannes Reeh', 2020, ARRAY['Merlot'], 'Burgenland', 'Österreich', 'Burgenland QW', 'RED', 'FULL', 'DRY', '0.75l');

-- Merlot Haus und Hof 2021
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Merlot Haus und Hof 2021',
'Weingut Hannes Reeh, Andau | Burgenland QW',
'Dunkles Kirschrot. In der Nase fruchtige Aromen von Himbeeren und dunklen Beeren mit feinen Röstaromen. Am Gaumen Noten von Zwetschge mit samtigen Tanninen.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Merlot Haus und Hof 2021',
'Weingut Hannes Reeh, Andau | Burgenland QW',
'Dark cherry red. Fruity aromas of raspberries and dark berries with fine roasted notes on the nose. Plum notes on the palate with velvety tannins.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 45.00, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Hannes Reeh', 2021, ARRAY['Merlot'], 'Burgenland', 'Österreich', 'Burgenland QW', 'RED', 'MEDIUM_FULL', 'DRY', '0.75l');

-- Ried Rosenberg 2016 (Magnum)
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "highlightType", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 3, true, false, true, 'PREMIUM', NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Ried Rosenberg 2016 (Magnum)',
'Weingut Gerhard Markowitsch, Göttlesbrunn | Carnuntum QW',
'Dunkles Rubingranat, violette Reflexe. Mit einem Hauch von Nougat unterlegtes reifes dunkles Waldbeerkonfit, zarte Edelholznuancen, attraktives Bukett. Kraftvoll, stoffig, elegant, angenehme Extraktsüße, präsente Tannine, weißer Pfeffer und Kardamom im Nachhall.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Ried Rosenberg 2016 (Magnum)',
'Weingut Gerhard Markowitsch, Göttlesbrunn | Carnuntum QW',
'Dark ruby-garnet, concentrated aroma of dark berries and cassis, very concentrated and compact on the palate with a very ripe tannin structure and a long finish.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Magnum', 136.40, 'EUR', '1.5l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Gerhard Markowitsch', 2016, ARRAY['Zweigelt','Merlot','Cabernet Sauvignon'], 'Carnuntum', 'Österreich', 'Carnuntum QW', 'RED', 'FULL', 'DRY', '1.5l');

-- Wiener Trilogie 2019
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Wiener Trilogie 2019',
'Weingut Fritz Wieninger | Wien QW',
'Dunkles Rubingranat, opaker Kern, violette Reflexe. Zart animalische Würze, dunkle Beerenfrucht, süßer Tabak, etwas Bergamotte, würziges Bukett. Saftig, schwungvolle Kirschfrucht, frisch strukturiert, reife Tannine, mineralisch und gut zugänglich.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Wiener Trilogie 2019',
'Weingut Fritz Wieninger | Wien QW',
'Dark ruby garnet, opaque core, violet reflections. Subtle animalistic spice, dark berry fruit, sweet tobacco, hints of bergamot, and a spicy bouquet. Juicy with vibrant cherry fruit, fresh structure, ripe tannins, mineral-driven, and well-accessible.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 40.80, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Fritz Wieninger', 2019, ARRAY['Zweigelt','Cabernet Sauvignon','Merlot'], 'Wien', 'Österreich', 'Wien QW', 'RED', 'MEDIUM_FULL', 'DRY', '0.75l');

-- Mephisto 2013
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 5, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Mephisto 2013',
'Weingut Robert Goldenits, Tadten | Burgenland QW',
'Dunkles Rubingranat, schwarzer Kern. Feine Edelholzwürze, zartes dunkles Beerenkonfit, ein Hauch von Röstaromen, leichte Nougatnoten. Gute Komplexität, präsente Tannine, Tabakwürze im Abgang, etwas Lakritze, gutes Reifepotenzial.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Mephisto 2013',
'Weingut Robert Goldenits, Tadten | Burgenland QW',
'Dark ruby garnet with a black core. Fine wood spice, delicate dark berry jam, a hint of roasted aromas, subtle nougat notes. Good complexity, prominent tannins, tobacco spiciness on the finish, excellent aging potential.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 94.40, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Robert Goldenits', 2013, ARRAY['Syrah','Merlot','Cabernet Sauvignon'], 'Burgenland', 'Österreich', 'Burgenland QW', 'RED', 'FULL', 'DRY', '0.75l');

-- Pannobile rot 2020
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 6, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Pannobile rot 2020',
'Weingut Anita & Hans Nittnaus, Gols | Burgenland QW',
'Rote Kirschfrucht, zart nach Kräutern, ein Hauch von Lakritze. Saftig, straff, frische Säurestruktur, gut eingebundene Tannine, rotbeerige Nuancen, Noten von Cassis, mineralischer Rückgeschmack, tabakiger Nachhall.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Pannobile rot 2020',
'Weingut Anita & Hans Nittnaus, Gols | Burgenland QW',
'Red cherry fruit, delicate herbs, a hint of licorice. Juicy, taut, fresh acidity, well-integrated tannins, red berry nuances, cassis notes, mineral aftertaste, tobacco finish.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 79.70, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Anita & Hans Nittnaus', 2020, ARRAY['Zweigelt','Blaufränkisch'], 'Burgenland', 'Österreich', 'Burgenland QW', 'RED', 'MEDIUM_FULL', 'DRY', '0.75l');

-- Solitaire 2007
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "highlightType", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 7, true, false, true, 'PREMIUM', NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Solitaire 2007',
'Weingut Feiler-Artinger, Rust | Burgenland QW',
'Tiefdunkles Rubingranat, schwarzer Kern. Feines einladendes Beerenbouquet, Herzkirschen, zart balsamisch-tabakig unterlegt, etwas Bitterschokolade. Am Gaumen saftig und komplex, feine, seidige Tannine, mineralisch unterlegte Säurestruktur, sehr charmanter Stil, elegant und anhaltend.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Solitaire 2007',
'Weingut Feiler-Artinger, Rust | Burgenland QW',
'Deep dark ruby garnet. Fine, inviting bouquet of berries, heart cherries, hints of balsamic and tobacco, some dark chocolate. Juicy and complex on the palate, fine, silky tannins, mineral-based acid structure, very charming style, elegant and persistent.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 94.40, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Feiler-Artinger', 2007, ARRAY['Blaufränkisch','Merlot','Cabernet Sauvignon'], 'Burgenland', 'Österreich', 'Burgenland QW', 'RED', 'FULL', 'DRY', '0.75l');

-- In Signo Leonis 2013
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 8, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'In Signo Leonis 2013',
'Weingut Heribert Bayer, Neckenmarkt | Burgenland QW',
'Dunkles Rubingranat. Zart rauchig, ein Hauch von Zedernholz und Vanille, dunkles Beerenkonfit unterlegt, Kirschen und Nougat klingen an. Saftig, zarte rotbeerige Nuancen, präsentes, gut integriertes Tannin, zeigt Länge, ein saftiger Speisenbegleiter.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'In Signo Leonis 2013',
'Weingut Heribert Bayer, Neckenmarkt | Burgenland QW',
'Dark ruby, purple reflections. Delicately smoky, a touch of cedar and vanilla, dark berry confit underneath hints of cherries and nougat. Juicy, subtle red berry nuances, well-integrated tannins, shows length, a juicy food wine.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 104.90, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Heribert Bayer', 2013, ARRAY['Blaufränkisch','Cabernet Sauvignon','Zweigelt'], 'Burgenland', 'Österreich', 'Burgenland QW', 'RED', 'FULL', 'DRY', '0.75l');

-- Bela Rex 2019
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "highlightType", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 9, true, false, true, 'PREMIUM', NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Bela Rex 2019',
'Weingut Gesellmann, Deutschkreutz | Burgenland QW',
'Dunkles Rubingranat. Feine Kräuterwürze, Noten von Edelholz, Vanille, Nougat und dunklen Beeren, reife Zwetschken, ein Hauch von Feigen. Kraftvoll, saftig, reife dunkle Beeren, dunkles Nougat, balsamischer Touch im Abgang, mineralischer Nachhall, sicheres Reifepotenzial.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Bela Rex 2019',
'Weingut Gesellmann, Deutschkreutz | Burgenland QW',
'Dark ruby garnet. Light herbal spiciness, underlying dark berries, nougat and a hint of orange zest. Juicy, rich of extracts, silky tannins. Lingers long on the palate, chocolate in the finish with light roasting flavours.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 123.80, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Gesellmann', 2019, ARRAY['Cabernet Sauvignon','Merlot'], 'Burgenland', 'Österreich', 'Burgenland QW', 'RED', 'FULL', 'DRY', '0.75l');

-- Opus Eximium
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 10, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Opus Eximium',
'Weingut Gesellmann, Deutschkreutz | Burgenland QW',
'Dunkles Rubingranat. Feine Kräuterwürze, feiner balsamischer Touch, schwarze Beeren, zart nach Zwetschke. Saftig, frische Kirschenfrucht, feine Holzwürze, zarter Schokotouch im Abgang, ein vielseitiger Speisenbegleiter.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Opus Eximium',
'Weingut Gesellmann, Deutschkreutz | Burgenland QW',
'Dark ruby garnet. Fine herbal spice, balsamic touch, black berries, hints of plum. Juicy, fresh cherry fruit, fine wood spice, subtle chocolate touch on the finish, a versatile food wine.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 153.20, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Gesellmann', ARRAY['Blaufränkisch','St. Laurent','Zweigelt'], 'Burgenland', 'Österreich', 'Burgenland QW', 'RED', 'FULL', 'DRY', '0.75l');

-- Terra O. 2018
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 11, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Terra O. 2018',
'Weingut Silvia Heinrich, Deutschkreutz | Burgenland QW',
'Kräuterwürzig unterlegte reife Kirschfrucht, Sanddorn, etwas Holzwürze, feine Cassisnoten. Gute Komplexität, elegant, saftig, zarte Tanninstruktur, Brombeernuancen, Bourbonvanille im Nachhall.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Terra O. 2018',
'Weingut Silvia Heinrich, Deutschkreutz | Burgenland QW',
'Ripe cherry fruit with herbal spice underlay, sea buckthorn, some wood spice, fine cassis notes. Good complexity, elegant, juicy, delicate tannin structure, blackberry nuances, bourbon vanilla in the finish.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 83.90, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Silvia Heinrich', 2018, ARRAY['Blaufränkisch','Cabernet Sauvignon','Merlot','Syrah'], 'Burgenland', 'Österreich', 'Burgenland QW', 'RED', 'MEDIUM_FULL', 'DRY', '0.75l');

-- Vulcano 2020
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 12, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Vulcano 2020',
'Weingut Hans Igler, Deutschkreutz | Burgenland QW',
'Kräftiges Rubingranat. Zarte Edelholzwürze, frische Kirschen, ein Hauch von Zwetschken, unterlegt mit Vanille, Nougat und Orangenzesten. Saftig, rotbeerig und frisch strukturiert, feine Tannine, mineralisch-salzig, ein animierender Speisenbegleiter.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Vulcano 2020',
'Weingut Hans Igler, Deutschkreutz | Burgenland QW',
'Strong ruby, purple reflections. Delicate wood spice, fresh cherries, a hint of plums, vanilla, nougat and orange zest. Juicy, red berry notes and freshly structured, fine tannins, saline minerality, an animating food wine with ageing potential.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 52.40, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Hans Igler', 2020, ARRAY['Blaufränkisch','Merlot','Zweigelt','Cabernet Sauvignon'], 'Burgenland', 'Österreich', 'Burgenland QW', 'RED', 'MEDIUM_FULL', 'DRY', '0.75l');

-- =====================================================
-- SECTION: Dessertwein
-- =====================================================
v_sort := v_sort + 1;
v_section_id := gen_id();
INSERT INTO "MenuSection" (id, "menuId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES (v_section_id, v_wine_menu_id, 'dessertwein', v_sort, true, NOW(), NOW());
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name, description)
VALUES (gen_id(), v_section_id, 'de', 'Dessertwein', 'Österreich & Ungarn');
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name, description)
VALUES (gen_id(), v_section_id, 'en', 'Dessert Wine', 'Austria & Hungary');

-- Traminer Auslese 2017
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 1, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Traminer Auslese 2017',
'Weingut Feiler-Artinger, Rust | Burgenland QW',
'Helles Goldgelb im Glas. In der Nase und am Gaumen sehr typisches und intensives Rosenaroma. Sehr feines Süß-Säure-Spiel. Am Gaumen lang und fein anhaltend.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Traminer Auslese 2017',
'Weingut Feiler-Artinger, Rust | Burgenland QW',
'Light golden yellow. Typical and intense rose aroma on nose and palate. Very fine sweet-acid interplay. Long and delicately persistent on the palate.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 40.80, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Feiler-Artinger', 2017, ARRAY['Gewürztraminer'], 'Burgenland', 'Österreich', 'Burgenland QW', 'WHITE', 'SWEET', '0.75l');

-- Goldackerl Beerenauslese 2007
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Goldackerl Beerenauslese 2007',
'Weingut Willi Opitz, Illmitz | Burgenland QW',
'Goldgelb mit leuchtenden Reflexionen. Zarter Honig- und Rosinenduft, Anklänge von Mango und Ananas. Kräftiger Körper mit ausbalanciertem Süße-Säurespiel. Exotischer Geschmack mit Honig und Bisquit in einem lang anhaltenden Finish.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Goldackerl Beerenauslese 2007',
'Weingut Willi Opitz, Illmitz | Burgenland QW',
'Golden yellow with bright reflections. Delicate honey and raisin aromas, hints of mango and pineapple. Full body with balanced sweetness-acidity. Exotic palate with honey and biscuit in a long-lasting finish.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Halbflasche', 36.60, 'EUR', '0.375l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Willi Opitz', 2007, ARRAY['Welschriesling','Scheurebe'], 'Burgenland', 'Österreich', 'Burgenland QW', 'DESSERT', 'SWEET', '0.375l');

-- Ruster Ausbruch Pinot Cuvée 2007
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 3, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Ruster Ausbruch Pinot Cuvée 2007',
'Weingut Feiler-Artinger, Rust | Burgenland QW',
'Helles Goldgelb. Perfekte Harmonie von Haselnuß- und Vanillearomen der Eiche und den exotischen Fruchtaromen des Weines; wunderschöne cremige Textur; sehr elegant und lang.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Ruster Ausbruch Pinot Cuvée 2007',
'Weingut Feiler-Artinger, Rust | Burgenland QW',
'Light golden yellow. Perfect harmony of hazelnut and vanilla aromas from oak and exotic fruit flavours; beautiful creamy texture; very elegant and long.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Halbflasche', 40.80, 'EUR', '0.375l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Feiler-Artinger', 2007, ARRAY['Pinot Blanc','Pinot Gris','Neuburger','Chardonnay'], 'Burgenland', 'Österreich', 'Burgenland QW', 'DESSERT', 'SWEET', '0.375l');

-- Spätlese Cuvée 2019 Kracher
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Spätlese Cuvée 2019',
'Weinlaubenhof Kracher, Illmitz | Burgenland QW',
'Herrlich animierende Aromen von reifen, exotischen Früchten, umschmeichelt von feinem Wiesenblumenduft. Am Gaumen mit cremiger Textur, gelbe Früchte, etwas Pfirsich, sehr erfrischend. Gut integrierte Säure und langer Fruchtnachhall.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Spätlese Cuvée 2019',
'Weinlaubenhof Kracher, Illmitz | Burgenland QW',
'Delightful flavours of ripe, exotic fruits on the nose, caressed by hints of meadow flowers. Creamy texture, yellow fruits, some peach, very refreshing. Well-integrated acidity and long fruit finish.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 40.80, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weinlaubenhof Kracher', 2019, ARRAY['Pinot Blanc','Chardonnay','Welschriesling'], 'Burgenland', 'Österreich', 'Burgenland QW', 'DESSERT', 'SWEET', '0.75l');

-- Opitz One 2005
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 5, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Opitz One 2005',
'Weingut Willi Opitz, Illmitz | Burgenland QW',
'Kräftige Dörrobstaromen, tabakig unterlegte Feigennote, getrocknete Kräuter, kandierte Orangenschalen. Komplexer Gaumen mit Noten von Schokolade und gebrannten Nüssen, saftig und gut strukturiert, Orangefrucht, zart nach Nougat und Marzipan.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Opitz One 2005',
'Weingut Willi Opitz, Illmitz | Burgenland QW',
'Rich dried fruit aromas, tobacco-tinged fig notes, dried herbs, candied orange peel. Complex palate with chocolate and roasted nuts, juicy and well-structured, orange fruit, hints of nougat and marzipan.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Halbflasche', 40.80, 'EUR', '0.375l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Willi Opitz', 2005, ARRAY[]::TEXT[], 'Burgenland', 'Österreich', 'Burgenland QW', 'DESSERT', 'SWEET', '0.375l');

-- GV Eiswein 2018
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 6, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Grüner Veltliner Eiswein 2018',
'Weingut Nigl, Senftenberg | Niederösterreich QW',
'Helles Goldgelb, Silberreflexe. Feiner Blütenhonig, frische weiße Tropenfrucht, zart nach Litschi und reifer Mango, ein Hauch von kandierten Limettenzesten. Saftig und fruchtig-süß, gelbe Nuancen, zarter Honig im Abgang, elegant und bereits gut entwickelt.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Grüner Veltliner Eiswein 2018',
'Weingut Nigl, Senftenberg | Niederösterreich QW',
'Light golden yellow, silver reflections. Delicate blossom honey, fresh white tropical fruit, nuances of lychee and ripe mango, a hint of candied lime zest. Juicy and sweet, yellow fruit nuances, honey notes on the finish. Elegant and already well developed.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Halbflasche', 40.80, 'EUR', '0.375l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Nigl', 2018, ARRAY['Grüner Veltliner'], 'Niederösterreich', 'Österreich', 'Niederösterreich QW', 'DESSERT', 'SWEET', '0.375l');

-- Tokaji Aszu 6 Puttonyos 1993
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "highlightType", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 7, true, false, true, 'PREMIUM', NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Tokaji Aszú 6 Puttonyos 1993',
'Baron Bornemisza, Tokaji | Ungarn',
'Tief bernsteinfarbig, mittlere Intensität. Noten von Honig, Apfel, getrocknete Aprikosen, Kokos, Vanille und rustikale Aromen. Am Gaumen süß, sehr konzentriert, komplex und ausgewogen.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Tokaji Aszú 6 Puttonyos 1993',
'Baron Bornemisza, Tokaji | Hungary',
'Deep amber, medium intensity. Notes of honey, apple, dried apricots, coconut, vanilla and rustic aromas. Sweet, very concentrated, complex and well-balanced on the palate.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 61.80, 'EUR', '0.5l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, style, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Baron Bornemisza', 1993, ARRAY['Furmint'], 'Tokaji', 'Ungarn', 'DESSERT', 'SWEET', '0.5l');

-- =====================================================
-- SECTION: Likörwein / Portwein
-- =====================================================
v_sort := v_sort + 1;
v_section_id := gen_id();
INSERT INTO "MenuSection" (id, "menuId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES (v_section_id, v_wine_menu_id, 'likoerwein-portwein', v_sort, true, NOW(), NOW());
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name, description)
VALUES (gen_id(), v_section_id, 'de', 'Likörwein / Portwein', 'Portugal');
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name, description)
VALUES (gen_id(), v_section_id, 'en', 'Fortified Wine / Port Wine', 'Portugal');

-- Taylor's Select Reserve
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 1, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Taylor''s Select Reserve',
'Taylor''s Port, Vila Nova de Gaia | Douro DOC',
'Tief rubinrot mit granatrotem Rand. Klassisch intensiver Duft nach schwarzen Früchten. Am Gaumen fest, energisch, vollmundig mit kraftvollen Fruchtaromen und langem Finale.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Taylor''s Select Reserve',
'Taylor''s Port, Vila Nova de Gaia | Douro DOC',
'Deep ruby with garnet rim. Classically intense aroma of black fruits. Firm, energetic and full-bodied on the palate with powerful fruit and a long finish.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '5cl', 8.30, 'EUR', '5cl', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, "grapeVarieties", region, country, appellation, style, sweetness)
VALUES (gen_id(), v_item_id, 'Taylor''s Port', ARRAY['Tinta Cão','Tempranillo','Tinta Barroca','Touriga Franca','Touriga Nacional'], 'Douro', 'Portugal', 'Douro DOC', 'FORTIFIED', 'SWEET');

-- Taylor's 10 Years Old Tawny
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Taylor''s 10 Years Old Tawny',
'Taylor''s Port, Vila Nova de Gaia | Porto DOC',
'Tiefe ziegelrote Farbe mit bernsteinfarbenem Rand. Üppig und elegant mit Aromen von reifen Beeren, delikaten nussigen Noten und zarten Anklängen von Schokolade, Karamell und feinem Eichenholz. Sanft und seidig am Gaumen.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Taylor''s 10 Years Old Tawny',
'Taylor''s Port, Vila Nova de Gaia | Porto DOC',
'Deep brick-red colour with amber rim. Rich and elegant with aromas of ripe berries, delicate nutty notes and subtle hints of chocolate, caramel and fine oak. Smooth and silky on the palate.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '5cl', 9.30, 'EUR', '5cl', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, "grapeVarieties", region, country, appellation, style, sweetness)
VALUES (gen_id(), v_item_id, 'Taylor''s Port', ARRAY['Tempranillo','Tinta Amarela','Tinta Barroca','Tinta Cão','Touriga Nacional','Touriga Franca'], 'Douro', 'Portugal', 'Porto DOC', 'FORTIFIED', 'SWEET');

-- Taylor's 20 Years Old Tawny
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "highlightType", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 3, true, false, true, 'PREMIUM', NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Taylor''s 20 Years Old Tawny',
'Taylor''s Port, Vila Nova de Gaia | Porto DOC',
'Glänzende Bernsteinfarbe. Komplexes, vielschichtiges Bouquet nach Bratapfel, gerösteten Mandeln, Zimt und Honig. Ausgewogener, weicher Geschmack mit saftigen, delikaten Aromen und langem Finale.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Taylor''s 20 Years Old Tawny',
'Taylor''s Port, Vila Nova de Gaia | Porto DOC',
'Brilliant amber colour. Complex, layered bouquet of baked apple, roasted almonds, cinnamon and honey. Balanced, smooth taste with juicy, delicate flavours and a long finish.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '5cl', 10.40, 'EUR', '5cl', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, "grapeVarieties", region, country, appellation, style, sweetness)
VALUES (gen_id(), v_item_id, 'Taylor''s Port', ARRAY['Tempranillo','Tinta Amarela','Tinta Barroca','Tinta Cão','Touriga Nacional','Touriga Franca'], 'Douro', 'Portugal', 'Porto DOC', 'FORTIFIED', 'SWEET');

-- Taylor's Fine White Port
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Taylor''s Fine White Port',
'Taylor''s Port, Vila Nova de Gaia | Porto DOC',
'Duftig aromatisches Bouquet von reifen Früchten mit Anklängen von Honig und Eiche. Am Gaumen samtweich und vollmundig mit langem aromatischen Finale.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Taylor''s Fine White Port',
'Taylor''s Port, Vila Nova de Gaia | Porto DOC',
'Fragrant aromatic bouquet of ripe fruits with hints of honey and oak. Velvety smooth and full-bodied on the palate with a long aromatic finish.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '5cl', 7.20, 'EUR', '5cl', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, "grapeVarieties", region, country, appellation, style, sweetness)
VALUES (gen_id(), v_item_id, 'Taylor''s Port', ARRAY['Arinto','Sémillon','Codega','Gouveio','Viosinho','Rabigato'], 'Douro', 'Portugal', 'Porto DOC', 'FORTIFIED', 'MEDIUM_SWEET');

-- Taylor's Fine Tawny
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 5, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Taylor''s Fine Tawny',
'Taylor''s Port, Vila Nova de Gaia | Porto DOC',
'Blasses Ziegelrot mit breitem bernsteinfarbenen Rand. Sanfte Aromen von saftig gereiften Beeren, Karamell, Feigen und Backpflaumen mit köstlichen Anklängen von Nüssen und Gewürzen. Am Gaumen sanft und rund.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Taylor''s Fine Tawny',
'Taylor''s Port, Vila Nova de Gaia | Porto DOC',
'Pale brick-red with broad amber rim. Soft aromas of ripe berries, caramel, figs and baked plums with delightful hints of nuts and spices. Smooth and round on the palate.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '5cl', 8.30, 'EUR', '5cl', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, "grapeVarieties", region, country, appellation, style, sweetness)
VALUES (gen_id(), v_item_id, 'Taylor''s Port', ARRAY['Tempranillo','Tinta Cão','Touriga Franca','Touriga Nacional','Tinta Barroca'], 'Douro', 'Portugal', 'Porto DOC', 'FORTIFIED', 'SWEET');

-- =====================================================
-- SECTION: Wein im Glas
-- =====================================================
v_sort := v_sort + 1;
v_section_id := gen_id();
INSERT INTO "MenuSection" (id, "menuId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES (v_section_id, v_wine_menu_id, 'wein-im-glas', v_sort, true, NOW(), NOW());
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name)
VALUES (gen_id(), v_section_id, 'de', 'Wein im Glas');
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name)
VALUES (gen_id(), v_section_id, 'en', 'Wine by the Glass');

-- Spritzer Sauer
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 1, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Spritzer Sauer');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'White Wine Spritzer');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '1/4', 5.80, 'EUR', '0.25l', 0, true);

-- Canella Prosecco (Glas)
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Canella Extra Dry Prosecco', 'Casa Vinicola Canella, Venetien');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Canella Extra Dry Prosecco', 'Casa Vinicola Canella, Veneto');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '1/10', 7.20, 'EUR', '0.1l', 0, true);

-- Söhnlein Brillant
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 3, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Söhnlein Brillant trocken', 'Deutscher Sekt');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Söhnlein Brillant Brut', 'German Sparkling Wine');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '1/10', 6.20, 'EUR', '0.1l', 0, true);

-- GV Classic (Glas)
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Grüner Veltliner Classic', 'Weingut Schmidt, Niederrußbach');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Grüner Veltliner Classic', 'Weingut Schmidt, Niederrußbach');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '1/8', 5.10, 'EUR', '0.125l', 0, true);

-- Sauvignon Blanc Grillberg (Glas)
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 5, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Ried Grillberg Sauvignon Blanc', 'Weingut Schmidt, Niederrußbach');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Ried Grillberg Sauvignon Blanc', 'Weingut Schmidt, Niederrußbach');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '1/8', 6.20, 'EUR', '0.125l', 0, true);

-- Chardonnay Ölberg (Glas)
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 6, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Ried Ölberg Chardonnay', 'Weingut Schmidt, Niederrußbach');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Ried Ölberg Chardonnay', 'Weingut Schmidt, Niederrußbach');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '1/8', 6.20, 'EUR', '0.125l', 0, true);

-- Gelber Muskateller (Glas)
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 7, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Ried Bergen Gelber Muskateller', 'Weingut Schmidt, Niederrußbach | halbtrocken');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Ried Bergen Gelber Muskateller', 'Weingut Schmidt, Niederrußbach | medium dry');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '1/8', 6.20, 'EUR', '0.125l', 0, true);

-- Rosé vom Muschelkalk (Glas)
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 8, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Rosé vom Muschelkalk', 'Weingut Schmidt, Niederrußbach');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Rosé vom Muschelkalk', 'Weingut Schmidt, Niederrußbach');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '1/8', 6.20, 'EUR', '0.125l', 0, true);

-- Zweigelt vom Muschelkalk (Glas)
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 9, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Zweigelt vom Muschelkalk', 'Weingut Schmidt, Niederrußbach');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Zweigelt vom Muschelkalk', 'Weingut Schmidt, Niederrußbach');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '1/8', 5.10, 'EUR', '0.125l', 0, true);

-- CS Classic (Glas)
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 10, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Cabernet Sauvignon Classic', 'Weingut Schmidt, Niederrußbach');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Cabernet Sauvignon Classic', 'Weingut Schmidt, Niederrußbach');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '1/8', 6.20, 'EUR', '0.125l', 0, true);

-- Merlot Ölberg (Glas)
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 11, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Ried Ölberg Merlot', 'Weingut Schmidt, Niederrußbach');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Ried Ölberg Merlot', 'Weingut Schmidt, Niederrußbach');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '1/8', 6.20, 'EUR', '0.125l', 0, true);

-- Refugium (Glas)
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 12, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Refugium', 'Weingut Leo Aumann, Tribuswinkel | halbtrocken');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Refugium', 'Weingut Leo Aumann, Tribuswinkel | medium dry');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '1/8', 6.20, 'EUR', '0.125l', 0, true);

-- Traminer Spätlese (Glas Dessert)
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 13, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Traminer Spätlese', 'Weingut Scheiblhofer, Andau | süß');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Traminer Spätlese', 'Weingut Scheiblhofer, Andau | sweet');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '1/8', 6.20, 'EUR', '0.125l', 0, true);

-- Cleanup
DROP FUNCTION IF EXISTS gen_id();

RAISE NOTICE 'Weinkarte Teil 2 erfolgreich geseedet!';
END $$;

EOSQL

echo ""
echo "=== Weinkarte Teil 2 Seed abgeschlossen ==="
echo ""
echo "Neue Sektionen:"
echo "  - Rotwein International (8 Weine: IT, ES, AU)"
echo "  - Rotwein Cuvées & Merlot AT (12 Weine)"
echo "  - Dessertwein (7 Weine: AT + Ungarn)"
echo "  - Likörwein / Portwein (5 Taylor's Ports)"
echo "  - Wein im Glas (13 Positionen)"
echo ""
echo "Gesamt: ~45 neue Artikel"
echo ""
echo "Tipp: pm2 restart menucard-pro"
