-- =====================================================
-- MenuCard Pro - Weinkarte Teil 2
-- Direct SQL - run with: psql <connstring> -f seed-wine-part2.sql
-- =====================================================

CREATE OR REPLACE FUNCTION gen_id() RETURNS TEXT AS $$
BEGIN
  RETURN 'cl' || substr(md5(random()::text || clock_timestamp()::text), 1, 23);
END;
$$ LANGUAGE plpgsql;

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
IF v_tenant_id IS NULL THEN RAISE EXCEPTION 'Tenant not found!'; END IF;

SELECT id INTO v_location_id FROM "Location" WHERE "tenantId"=v_tenant_id AND slug='restaurant' LIMIT 1;
IF v_location_id IS NULL THEN RAISE EXCEPTION 'Location not found!'; END IF;

SELECT id INTO v_wine_menu_id FROM "Menu" WHERE "locationId"=v_location_id AND slug='weinkarte' LIMIT 1;
IF v_wine_menu_id IS NULL THEN RAISE EXCEPTION 'Wine menu not found!'; END IF;

SELECT COALESCE(MAX("sortOrder"), 0) INTO v_sort FROM "MenuSection" WHERE "menuId"=v_wine_menu_id;

RAISE NOTICE 'Tenant: %, Menu: %, Starting sort: %', v_tenant_id, v_wine_menu_id, v_sort;

-- =====================================================
-- SECTION: Rotwein International
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
'Intensives, sattes Rubinrot. Filigran-elegante Nase nach reifen Waldbeeren, Schokolade, im Nachhall leicht nach Zigarrenkiste. Am Gaumen ueberragt der suesse Schmelz, baut sich weit und in vielen Schichten auf, elegant, wunderbar harmonisch bis ins lange Finale.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Costasera Amarone della Valpolicella Classico 2012',
'Masi Agricola, Gargagnago di Valpolicella',
'Lots of complexity on the nose: smoky black cherries, dried rose stems, asphalt, tar and licorice. Full, structured body through layers of dark fruit, driven by active acidity to the long but not cloying finish.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 99.90, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Masi Agricola', 2012, ARRAY['Corvina','Rondinella','Molinara'], 'Venetien', 'Italien', 'Amarone della Valpolicella Classico DOCG', 'RED', 'FULL', 'DRY', '0.75l');

-- Chianti Classico 2020
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Chianti Classico 2020', 'Villa Trasqua, Castellina in Chianti',
'Leuchtendes Rubingranat. Feines Spiel zwischen reifer Kirschfrucht und wuerzigen Komponenten, Zimt und Kardamom, dazu Milchschokolade. Griffiges, herzhaftes Tannin.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Chianti Classico 2020', 'Villa Trasqua, Castellina in Chianti',
'Lively ruby red with purple reflections. Floral hints of violet, ripe cherry and raspberry, sweet spices. Fresh with pleasant tannin, vibrant and dynamic.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 41.90, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Villa Trasqua', 2020, ARRAY['Sangiovese','Merlot','Cabernet Sauvignon'], 'Toskana', 'Italien', 'Chianti Classico DOCG', 'RED', 'MEDIUM_FULL', 'DRY', '0.75l');

-- Rosso di Montalcino 2020
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 3, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Rosso di Montalcino 2020', 'Azienda Agricola Altesino, Montalcino',
'Zedernholz, Gewuerze, Kirschen und Mineralien. Am Gaumen rund und kraftvoll, Lavendel-Kirschfrucht mit heller Saeure.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Rosso di Montalcino 2020', 'Azienda Agricola Altesino, Montalcino',
'Cedary spice, dried cherries and crushed rocks. Round and forward, lavender-tinged cherry fruit with bright acidity. Lightly structured yet potent.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 47.10, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Altesino', 2020, ARRAY['Sangiovese'], 'Toskana', 'Italien', 'Rosso di Montalcino DOC', 'RED', 'MEDIUM_FULL', 'DRY', '0.75l');

-- Bastioni 2020
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Bastioni 2020', 'Tenuta I Collazzi, Tavarnelle',
'Intensives Rubinrot mit granatroten Reflexen. Rote Fruechte, Kirsche, Pflaume und Gewuerze. Wuerzig und komplex.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Bastioni 2020', 'Tenuta I Collazzi, Tavarnelle',
'Geraniums, black cherries, mandarin peel and bergamot. Full bodied, rounded tannins and a juicy finale.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 49.20, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Tenuta I Collazzi', 2020, ARRAY['Sangiovese','Merlot','Malvasia Nera'], 'Toskana', 'Italien', 'Chianti Classico DOCG', 'RED', 'FULL', 'DRY', '0.75l');

-- Barolo 2018
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "highlightType", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 5, true, false, true, 'PREMIUM', NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Barolo 2018', 'Fratelli Revello, La Morra',
'Anmutig und einladend. Zerdrueckte Blumen, suesse rote Beeren, Kirsche, Gewuerze und Lakritze. Aetherisch und seidig.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Barolo 2018', 'Fratelli Revello, La Morra',
'Gracious and inviting. Crushed flowers, sweet red berry fruit, kirsch, spice and licorice grace this ethereal, silky Barolo.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 68.10, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Fratelli Revello', 2018, ARRAY['Nebbiolo'], 'Piemont', 'Italien', 'Barolo DOCG', 'RED', 'FULL', 'DRY', '0.75l');

-- Sovrana Barbera d Alba 2020
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 6, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Sovrana Barbera d''Alba 2020', 'Beni di Batasiolo, La Morra',
'Rubinrot mit violetten Nuancen. Beeren, Kirschen und reifes Obst. Wuerzige Noten mit zarten Holz- und Blumenaromen.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Sovrana Barbera d''Alba 2020', 'Beni di Batasiolo, La Morra',
'Ruby red with purple tinges. Berries, cherries and ripe fruit. Pleasant spicy flavours with delicate wood and flower sensations.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 41.90, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Beni di Batasiolo', 2020, ARRAY['Barbera'], 'Piemont', 'Italien', 'Barbera d''Alba DOC', 'RED', 'MEDIUM_FULL', 'DRY', '0.75l');

-- Rioja Reserva 2020
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 7, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Rioja Reserva 2020', 'Marques de Riscal, Elciego',
'Tiefdunkle kirschrote Farbe. Lakritze, Zimt, Vanille, schwarzer Pfeffer und feine Roestnoten. Am Gaumen frisch, geschliffene Tannine, langer balsamischer Abgang.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Rioja Reserva 2020', 'Marques de Riscal, Elciego',
'Deep black cherry red. Liquorice, cinnamon, black pepper, subtle barrel aging. Fresh, polished tannins, long balsamic finish.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 69.20, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Marques de Riscal', 2020, ARRAY['Tempranillo','Graciano'], 'La Rioja', 'Spanien', 'Rioja DOCa', 'RED', 'MEDIUM_FULL', 'DRY', '0.75l');

-- Finniss River Shiraz 2018
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 8, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Finniss River Shiraz Sea Eagle Vineyard 2018', 'Salomon Estate, McLaren Vale',
'Reif, vital und rotfruchtig. Maulbeeren, Granatapfel und Himbeeren, umrahmt von exotischen Gewuerzen und heller Saeure.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Finniss River Shiraz Sea Eagle Vineyard 2018', 'Salomon Estate, McLaren Vale',
'Ripe, vital and red-fruited. Mulberries, pomegranates and raspberries, hemmed in by exotic spice and bright acidity.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 90.20, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Salomon Estate', 2018, ARRAY['Syrah'], 'South Australia', 'Australien', 'RED', 'FULL', 'DRY', '0.75l');

-- =====================================================
-- SECTION: Rotwein Cuvees & Merlot (AT)
-- =====================================================
v_sort := v_sort + 1;
v_section_id := gen_id();
INSERT INTO "MenuSection" (id, "menuId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES (v_section_id, v_wine_menu_id, 'rotwein-cuvees-merlot', v_sort, true, NOW(), NOW());
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name, description)
VALUES (gen_id(), v_section_id, 'de', 'Rotwein Cuvees & Merlot', 'Oesterreich');
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name, description)
VALUES (gen_id(), v_section_id, 'en', 'Red Wine Cuvees & Merlot', 'Austria');

-- Unplugged Merlot 2020
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "highlightType", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 1, true, false, true, 'PREMIUM', NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Unplugged Merlot 2020', 'Weingut Hannes Reeh, Andau | Burgenland QW',
'Dunkles Rubingranat, opaker Kern. Nougat und Lakritze, schwarze Waldbeeren, Kraeuterwuerze und Brombeerkonfit. Kraftvoll, komplex, saftig, dunkle Kirschen, reife Tannine, schokoladig.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Unplugged Merlot 2020', 'Weingut Hannes Reeh, Andau | Burgenland QW',
'Nougat and licorice, black forest berries, herbal spice and blackberry preserves. Powerful, complex, juicy, dark cherries, structured tannins, chocolaty texture.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 104.90, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Hannes Reeh', 2020, ARRAY['Merlot'], 'Burgenland', 'Oesterreich', 'Burgenland QW', 'RED', 'FULL', 'DRY', '0.75l');

-- Merlot Haus und Hof 2021
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Merlot Haus und Hof 2021', 'Weingut Hannes Reeh, Andau | Burgenland QW',
'Dunkles Kirschrot. Himbeeren und dunkle Beeren mit feinen Roestaromen. Zwetschge mit samtigen Tanninen.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Merlot Haus und Hof 2021', 'Weingut Hannes Reeh, Andau | Burgenland QW',
'Dark cherry red. Raspberries and dark berries with fine roasted notes. Plum on the palate with velvety tannins.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 45.00, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Hannes Reeh', 2021, ARRAY['Merlot'], 'Burgenland', 'Oesterreich', 'Burgenland QW', 'RED', 'MEDIUM_FULL', 'DRY', '0.75l');

-- Ried Rosenberg 2016 Magnum
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "highlightType", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 3, true, false, true, 'PREMIUM', NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Ried Rosenberg 2016 (Magnum)', 'Weingut Gerhard Markowitsch, Goettlesbrunn | Carnuntum QW',
'Dunkles Rubingranat. Reifes Waldbeerkonfit mit Nougat, Edelholznuancen. Kraftvoll, stoffig, elegant, praesente Tannine, weisser Pfeffer und Kardamom.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Ried Rosenberg 2016 (Magnum)', 'Weingut Gerhard Markowitsch, Goettlesbrunn | Carnuntum QW',
'Dark ruby-garnet, concentrated dark berries and cassis, very compact with ripe tannin structure and long finish.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Magnum', 136.40, 'EUR', '1.5l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Gerhard Markowitsch', 2016, ARRAY['Zweigelt','Merlot','Cabernet Sauvignon'], 'Carnuntum', 'Oesterreich', 'Carnuntum QW', 'RED', 'FULL', 'DRY', '1.5l');

-- Wiener Trilogie 2019
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Wiener Trilogie 2019', 'Weingut Fritz Wieninger | Wien QW',
'Dunkles Rubingranat. Animalische Wuerze, dunkle Beerenfrucht, suesser Tabak, Bergamotte. Saftig, schwungvolle Kirschfrucht, reife Tannine, mineralisch.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Wiener Trilogie 2019', 'Weingut Fritz Wieninger | Wien QW',
'Dark ruby garnet. Animalistic spice, dark berry fruit, sweet tobacco, bergamot. Juicy cherry fruit, fresh structure, ripe tannins, mineral-driven.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 40.80, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Fritz Wieninger', 2019, ARRAY['Zweigelt','Cabernet Sauvignon','Merlot'], 'Wien', 'Oesterreich', 'Wien QW', 'RED', 'MEDIUM_FULL', 'DRY', '0.75l');

-- Mephisto 2013
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 5, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Mephisto 2013', 'Weingut Robert Goldenits, Tadten | Burgenland QW',
'Dunkles Rubingranat, schwarzer Kern. Edelholzwuerze, dunkles Beerenkonfit, Roestaromen, Nougatnoten. Gute Komplexitaet, praesente Tannine, Tabakwuerze, Lakritze.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Mephisto 2013', 'Weingut Robert Goldenits, Tadten | Burgenland QW',
'Dark ruby garnet, black core. Fine wood spice, dark berry jam, roasted aromas, nougat. Good complexity, prominent tannins, tobacco, licorice, excellent aging potential.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 94.40, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Robert Goldenits', 2013, ARRAY['Syrah','Merlot','Cabernet Sauvignon'], 'Burgenland', 'Oesterreich', 'Burgenland QW', 'RED', 'FULL', 'DRY', '0.75l');

-- Pannobile rot 2020
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 6, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Pannobile rot 2020', 'Weingut Anita & Hans Nittnaus, Gols | Burgenland QW',
'Rote Kirschfrucht, Kraeuter, Lakritze. Saftig, straff, frische Saeurestruktur, gut eingebundene Tannine, rotbeerig, mineralisch.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Pannobile rot 2020', 'Weingut Anita & Hans Nittnaus, Gols | Burgenland QW',
'Red cherry fruit, herbs, licorice. Juicy, taut, fresh acidity, well-integrated tannins, red berry, mineral finish.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 79.70, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Anita & Hans Nittnaus', 2020, ARRAY['Zweigelt','Blaufraenkisch'], 'Burgenland', 'Oesterreich', 'Burgenland QW', 'RED', 'MEDIUM_FULL', 'DRY', '0.75l');

-- Solitaire 2007
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "highlightType", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 7, true, false, true, 'PREMIUM', NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Solitaire 2007', 'Weingut Feiler-Artinger, Rust | Burgenland QW',
'Tiefdunkles Rubingranat. Beerenbouquet, Herzkirschen, balsamisch-tabakig, Bitterschokolade. Saftig, komplex, seidige Tannine, charmant, elegant.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Solitaire 2007', 'Weingut Feiler-Artinger, Rust | Burgenland QW',
'Deep dark ruby garnet. Berries, heart cherries, balsamic-tobacco, dark chocolate. Juicy, complex, silky tannins, charming, elegant, persistent.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 94.40, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Feiler-Artinger', 2007, ARRAY['Blaufraenkisch','Merlot','Cabernet Sauvignon'], 'Burgenland', 'Oesterreich', 'Burgenland QW', 'RED', 'FULL', 'DRY', '0.75l');

-- In Signo Leonis 2013
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 8, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'In Signo Leonis 2013', 'Weingut Heribert Bayer, Neckenmarkt | Burgenland QW',
'Dunkles Rubingranat. Rauchig, Zedernholz, Vanille, dunkles Beerenkonfit, Kirschen, Nougat. Saftig, rotbeerig, praesentes Tannin, zeigt Laenge.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'In Signo Leonis 2013', 'Weingut Heribert Bayer, Neckenmarkt | Burgenland QW',
'Dark ruby. Smoky, cedar, vanilla, dark berry confit, cherries, nougat. Juicy, red berry, well-integrated tannins, shows length.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 104.90, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Heribert Bayer', 2013, ARRAY['Blaufraenkisch','Cabernet Sauvignon','Zweigelt'], 'Burgenland', 'Oesterreich', 'Burgenland QW', 'RED', 'FULL', 'DRY', '0.75l');

-- Bela Rex 2019
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "highlightType", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 9, true, false, true, 'PREMIUM', NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Bela Rex 2019', 'Weingut Gesellmann, Deutschkreutz | Burgenland QW',
'Dunkles Rubingranat. Kraeuterwuerze, Edelholz, Vanille, Nougat, dunkle Beeren, Zwetschken, Feigen. Kraftvoll, saftig, balsamisch, mineralischer Nachhall.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Bela Rex 2019', 'Weingut Gesellmann, Deutschkreutz | Burgenland QW',
'Dark ruby garnet. Herbal spice, dark berries, nougat, orange zest. Juicy, rich extracts, silky tannins, chocolate finish, long on palate.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 123.80, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Gesellmann', 2019, ARRAY['Cabernet Sauvignon','Merlot'], 'Burgenland', 'Oesterreich', 'Burgenland QW', 'RED', 'FULL', 'DRY', '0.75l');

-- Opus Eximium
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 10, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Opus Eximium', 'Weingut Gesellmann, Deutschkreutz | Burgenland QW',
'Dunkles Rubingranat. Kraeuterwuerze, balsamisch, schwarze Beeren, Zwetschke. Saftig, Kirschenfrucht, Holzwuerze, Schokotouch im Abgang.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Opus Eximium', 'Weingut Gesellmann, Deutschkreutz | Burgenland QW',
'Dark ruby garnet. Herbal spice, balsamic, black berries, plum. Juicy, cherry fruit, wood spice, chocolate on the finish.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 153.20, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Gesellmann', ARRAY['Blaufraenkisch','St. Laurent','Zweigelt'], 'Burgenland', 'Oesterreich', 'Burgenland QW', 'RED', 'FULL', 'DRY', '0.75l');

-- Terra O. 2018
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 11, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Terra O. 2018', 'Weingut Silvia Heinrich, Deutschkreutz | Burgenland QW',
'Kraeuterwuerzig, reife Kirschfrucht, Sanddorn, Holzwuerze, Cassis. Elegant, saftig, zarte Tannine, Brombeere, Bourbonvanille.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Terra O. 2018', 'Weingut Silvia Heinrich, Deutschkreutz | Burgenland QW',
'Herbal spice, ripe cherry, sea buckthorn, wood spice, cassis. Elegant, juicy, delicate tannins, blackberry, bourbon vanilla.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 83.90, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Silvia Heinrich', 2018, ARRAY['Blaufraenkisch','Cabernet Sauvignon','Merlot','Syrah'], 'Burgenland', 'Oesterreich', 'Burgenland QW', 'RED', 'MEDIUM_FULL', 'DRY', '0.75l');

-- Vulcano 2020
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 12, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Vulcano 2020', 'Weingut Hans Igler, Deutschkreutz | Burgenland QW',
'Kraeftiges Rubingranat. Edelholzwuerze, Kirschen, Zwetschken, Vanille, Nougat, Orangenzesten. Saftig, rotbeerig, feine Tannine, mineralisch-salzig.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Vulcano 2020', 'Weingut Hans Igler, Deutschkreutz | Burgenland QW',
'Strong ruby. Wood spice, cherries, plums, vanilla, nougat, orange zest. Juicy, red berry, fine tannins, saline minerality.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 52.40, 'EUR', '0.75l', 0, true);
INSERT INTO "WineProfile" (id, "menuItemId", winery, vintage, "grapeVarieties", region, country, appellation, style, body, sweetness, "bottleSize")
VALUES (gen_id(), v_item_id, 'Weingut Hans Igler', 2020, ARRAY['Blaufraenkisch','Merlot','Zweigelt','Cabernet Sauvignon'], 'Burgenland', 'Oesterreich', 'Burgenland QW', 'RED', 'MEDIUM_FULL', 'DRY', '0.75l');

-- =====================================================
-- SECTION: Dessertwein
-- =====================================================
v_sort := v_sort + 1;
v_section_id := gen_id();
INSERT INTO "MenuSection" (id, "menuId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES (v_section_id, v_wine_menu_id, 'dessertwein', v_sort, true, NOW(), NOW());
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name, description)
VALUES (gen_id(), v_section_id, 'de', 'Dessertwein', 'Oesterreich & Ungarn');
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name, description)
VALUES (gen_id(), v_section_id, 'en', 'Dessert Wine', 'Austria & Hungary');

-- Traminer Auslese 2017
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 1, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Traminer Auslese 2017', 'Weingut Feiler-Artinger, Rust | Burgenland QW | suess',
'Helles Goldgelb. Intensives Rosenaroma. Feines Suess-Saeure-Spiel. Lang und fein anhaltend.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Traminer Auslese 2017', 'Weingut Feiler-Artinger, Rust | Burgenland QW | sweet',
'Light golden yellow. Intense rose aroma. Fine sweet-acid interplay. Long and persistent.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 40.80, 'EUR', '0.75l', 0, true);

-- Goldackerl BA 2007
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Goldackerl Beerenauslese 2007', 'Weingut Willi Opitz, Illmitz | Burgenland QW | suess',
'Goldgelb. Honig, Rosinen, Mango, Ananas. Ausbalanciertes Suesse-Saeurespiel, Honig-Zitrus Finish.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Goldackerl Beerenauslese 2007', 'Weingut Willi Opitz, Illmitz | Burgenland QW | sweet',
'Golden yellow. Honey, raisins, mango, pineapple. Balanced sweetness-acidity, honey-citrus finish.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Halbflasche', 36.60, 'EUR', '0.375l', 0, true);

-- Ruster Ausbruch Pinot Cuvee 2007
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 3, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Ruster Ausbruch Pinot Cuvee 2007', 'Weingut Feiler-Artinger, Rust | Burgenland QW | suess',
'Helles Goldgelb. Haselnuss und Vanille der Eiche, exotische Fruchtaromen. Cremige Textur, sehr elegant und lang.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Ruster Ausbruch Pinot Cuvee 2007', 'Weingut Feiler-Artinger, Rust | Burgenland QW | sweet',
'Light golden yellow. Hazelnut and vanilla from oak, exotic fruit. Creamy texture, very elegant and long.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Halbflasche', 40.80, 'EUR', '0.375l', 0, true);

-- Spaetlese Cuvee 2019 Kracher
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Spaetlese Cuvee 2019', 'Weinlaubenhof Kracher, Illmitz | Burgenland QW | suess',
'Reife exotische Fruechte, Wiesenblumenduft. Cremige Textur, gelbe Fruechte, Pfirsich. Gut integrierte Saeure, langer Fruchtnachhall.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Spaetlese Cuvee 2019', 'Weinlaubenhof Kracher, Illmitz | Burgenland QW | sweet',
'Ripe exotic fruits, meadow flowers. Creamy texture, yellow fruits, peach. Well-integrated acidity, long fruit finish.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 40.80, 'EUR', '0.75l', 0, true);

-- Opitz One 2005
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 5, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Opitz One 2005', 'Weingut Willi Opitz, Illmitz | Burgenland QW | suess',
'Doerrobstaromen, Feige, getrocknete Kraeuter, kandierte Orangenschalen. Schokolade, gebrannte Nuesse, Nougat und Marzipan.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Opitz One 2005', 'Weingut Willi Opitz, Illmitz | Burgenland QW | sweet',
'Dried fruit, fig, herbs, candied orange peel. Chocolate, roasted nuts, nougat and marzipan.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Halbflasche', 40.80, 'EUR', '0.375l', 0, true);

-- GV Eiswein 2018
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 6, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Gruener Veltliner Eiswein 2018', 'Weingut Nigl, Senftenberg | Niederoesterreich QW | suess',
'Helles Goldgelb. Bluetenhonig, Tropenfrucht, Litschi, Mango. Saftig, fruchtig-suess, elegant.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Gruener Veltliner Eiswein 2018', 'Weingut Nigl, Senftenberg | Lower Austria QW | sweet',
'Light golden yellow. Blossom honey, tropical fruit, lychee, mango. Juicy, sweet, elegant.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Halbflasche', 40.80, 'EUR', '0.375l', 0, true);

-- Tokaji Aszu 6 Puttonyos 1993
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "highlightType", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 7, true, false, true, 'PREMIUM', NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'de', 'Tokaji Aszu 6 Puttonyos 1993', 'Baron Bornemisza, Tokaji | Ungarn | suess',
'Tief bernsteinfarbig. Honig, Apfel, Aprikosen, Kokos, Vanille. Suess, konzentriert, komplex und ausgewogen.');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription", "longDescription")
VALUES (gen_id(), v_item_id, 'en', 'Tokaji Aszu 6 Puttonyos 1993', 'Baron Bornemisza, Tokaji | Hungary | sweet',
'Deep amber. Honey, apple, dried apricots, coconut, vanilla. Sweet, very concentrated, complex and balanced.');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, 'Flasche', 61.80, 'EUR', '0.5l', 0, true);

-- =====================================================
-- SECTION: Likoerwein / Portwein
-- =====================================================
v_sort := v_sort + 1;
v_section_id := gen_id();
INSERT INTO "MenuSection" (id, "menuId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES (v_section_id, v_wine_menu_id, 'likoerwein-portwein', v_sort, true, NOW(), NOW());
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name, description)
VALUES (gen_id(), v_section_id, 'de', 'Likoerwein / Portwein', 'Portugal');
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name, description)
VALUES (gen_id(), v_section_id, 'en', 'Fortified Wine / Port Wine', 'Portugal');

-- Taylor Select Reserve
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 1, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription")
VALUES (gen_id(), v_item_id, 'de', 'Taylor''s Select Reserve', 'Taylor''s Port, Vila Nova de Gaia | Douro DOC | suess');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription")
VALUES (gen_id(), v_item_id, 'en', 'Taylor''s Select Reserve', 'Taylor''s Port, Vila Nova de Gaia | Douro DOC | sweet');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '5cl', 8.30, 'EUR', '5cl', 0, true);

-- Taylor 10 Years Old Tawny
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription")
VALUES (gen_id(), v_item_id, 'de', 'Taylor''s 10 Years Old Tawny', 'Taylor''s Port | Porto DOC | suess');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription")
VALUES (gen_id(), v_item_id, 'en', 'Taylor''s 10 Years Old Tawny', 'Taylor''s Port | Porto DOC | sweet');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '5cl', 9.30, 'EUR', '5cl', 0, true);

-- Taylor 20 Years Old Tawny
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "highlightType", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 3, true, false, true, 'PREMIUM', NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription")
VALUES (gen_id(), v_item_id, 'de', 'Taylor''s 20 Years Old Tawny', 'Taylor''s Port | Porto DOC | suess');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription")
VALUES (gen_id(), v_item_id, 'en', 'Taylor''s 20 Years Old Tawny', 'Taylor''s Port | Porto DOC | sweet');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '5cl', 10.40, 'EUR', '5cl', 0, true);

-- Taylor Fine White Port
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription")
VALUES (gen_id(), v_item_id, 'de', 'Taylor''s Fine White Port', 'Taylor''s Port | Porto DOC');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription")
VALUES (gen_id(), v_item_id, 'en', 'Taylor''s Fine White Port', 'Taylor''s Port | Porto DOC');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '5cl', 7.20, 'EUR', '5cl', 0, true);

-- Taylor Fine Tawny
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 5, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription")
VALUES (gen_id(), v_item_id, 'de', 'Taylor''s Fine Tawny', 'Taylor''s Port | Porto DOC');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription")
VALUES (gen_id(), v_item_id, 'en', 'Taylor''s Fine Tawny', 'Taylor''s Port | Porto DOC');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault")
VALUES (gen_id(), v_item_id, '5cl', 8.30, 'EUR', '5cl', 0, true);

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
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '1/4', 5.80, 'EUR', '0.25l', 0, true);

-- Canella Prosecco Glas
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Canella Extra Dry Prosecco', 'extra dry');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Canella Extra Dry Prosecco', 'extra dry');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '1/10', 7.20, 'EUR', '0.1l', 0, true);

-- Soehnlein Brillant Glas
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 3, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Soehnlein Brillant trocken', 'Deutscher Sekt | brut');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Soehnlein Brillant Brut', 'German Sparkling Wine');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '1/10', 6.20, 'EUR', '0.1l', 0, true);

-- GV Classic Glas
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Gruener Veltliner Classic', 'Weingut Schmidt');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Gruener Veltliner Classic', 'Weingut Schmidt');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '1/8', 5.10, 'EUR', '0.125l', 0, true);

-- SB Grillberg Glas
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 5, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Ried Grillberg Sauvignon Blanc', 'Weingut Schmidt');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Ried Grillberg Sauvignon Blanc', 'Weingut Schmidt');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '1/8', 6.20, 'EUR', '0.125l', 0, true);

-- Chardonnay Oelberg Glas
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 6, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Ried Oelberg Chardonnay', 'Weingut Schmidt');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Ried Oelberg Chardonnay', 'Weingut Schmidt');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '1/8', 6.20, 'EUR', '0.125l', 0, true);

-- Gelber Muskateller Glas
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 7, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Ried Bergen Gelber Muskateller', 'Weingut Schmidt | halbtrocken');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Ried Bergen Gelber Muskateller', 'Weingut Schmidt | medium dry');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '1/8', 6.20, 'EUR', '0.125l', 0, true);

-- Rose vom Muschelkalk Glas
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 8, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Rose vom Muschelkalk', 'Weingut Schmidt');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Rose vom Muschelkalk', 'Weingut Schmidt');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '1/8', 6.20, 'EUR', '0.125l', 0, true);

-- Zweigelt vom Muschelkalk Glas
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 9, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Zweigelt vom Muschelkalk', 'Weingut Schmidt');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Zweigelt vom Muschelkalk', 'Weingut Schmidt');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '1/8', 5.10, 'EUR', '0.125l', 0, true);

-- CS Classic Glas
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 10, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Cabernet Sauvignon Classic', 'Weingut Schmidt');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Cabernet Sauvignon Classic', 'Weingut Schmidt');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '1/8', 6.20, 'EUR', '0.125l', 0, true);

-- Merlot Oelberg Glas
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 11, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Ried Oelberg Merlot', 'Weingut Schmidt');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Ried Oelberg Merlot', 'Weingut Schmidt');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '1/8', 6.20, 'EUR', '0.125l', 0, true);

-- Refugium Glas
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 12, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Refugium', 'Weingut Leo Aumann | halbtrocken');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Refugium', 'Weingut Leo Aumann | medium dry');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '1/8', 6.20, 'EUR', '0.125l', 0, true);

-- Traminer Spaetlese Glas
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'WINE', 13, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Traminer Spaetlese', 'Weingut Scheiblhofer, Andau | suess');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Traminer Spaetlese', 'Weingut Scheiblhofer, Andau | sweet');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '1/8', 6.20, 'EUR', '0.125l', 0, true);

DROP FUNCTION IF EXISTS gen_id();
RAISE NOTICE 'Weinkarte Teil 2 erfolgreich geseedet! 5 Sektionen, ~45 Artikel.';
END $$;
