-- =====================================================
-- MenuCard Pro - Barkarte Seed Script
-- Hotel Sonnblick - Aperitif, Bier, Spirits, Cocktails, etc.
-- Run: psql <connstring> -f seed-bar.sql
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
  v_bar_menu_id TEXT;
  v_section_id TEXT;
  v_item_id TEXT;
  v_sort INT := 0;
BEGIN

SELECT id INTO v_tenant_id FROM "Tenant" WHERE slug='hotel-sonnblick' LIMIT 1;
IF v_tenant_id IS NULL THEN RAISE EXCEPTION 'Tenant not found!'; END IF;

SELECT id INTO v_location_id FROM "Location" WHERE "tenantId"=v_tenant_id AND slug='restaurant' LIMIT 1;
IF v_location_id IS NULL THEN RAISE EXCEPTION 'Location not found!'; END IF;

-- Create Bar Menu
v_bar_menu_id := gen_id();
INSERT INTO "Menu" (id, "locationId", slug, "isActive", "sortOrder", "createdAt", "updatedAt")
VALUES (v_bar_menu_id, v_location_id, 'barkarte', true, 3, NOW(), NOW());
INSERT INTO "MenuTranslation" (id, "menuId", "languageCode", name, description)
VALUES (gen_id(), v_bar_menu_id, 'de', 'Barkarte', 'Aperitif, Bier, Spirits, Cocktails & mehr');
INSERT INTO "MenuTranslation" (id, "menuId", "languageCode", name, description)
VALUES (gen_id(), v_bar_menu_id, 'en', 'Bar Menu', 'Aperitifs, Beer, Spirits, Cocktails & more');

RAISE NOTICE 'Bar Menu created: %', v_bar_menu_id;

-- =====================================================
-- SECTION: Aperitif
-- =====================================================
v_sort := v_sort + 1;
v_section_id := gen_id();
INSERT INTO "MenuSection" (id, "menuId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES (v_section_id, v_bar_menu_id, 'aperitif', v_sort, true, NOW(), NOW());
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'de', 'Aperitif');
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'en', 'Aperitif');

-- Sandeman Fino
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 1, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Sandeman Fino');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Sandeman Fino');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 6.80, 'EUR', 0, true);

-- Martini Bianco
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Martini Bianco');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Martini Bianco');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 6.80, 'EUR', 0, true);

-- Martini Rosso
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 3, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Martini Rosso');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Martini Rosso');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 6.80, 'EUR', 0, true);

-- Aperol Spritzer
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Aperol Spritzer');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Aperol Spritz');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 9.30, 'EUR', 0, true);

-- Hugo
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 5, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Hugo');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Hugo');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 7.20, 'EUR', 0, true);

-- Kir Royal
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 6, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Kir Royal');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Kir Royal');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 7.90, 'EUR', 0, true);

-- Campari Orange
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 7, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Campari Orange');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Campari Orange');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 8.90, 'EUR', 0, true);

-- Campari Soda
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 8, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Campari Soda');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Campari Soda');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 8.30, 'EUR', 0, true);

-- =====================================================
-- SECTION: Bier / Beer
-- =====================================================
v_sort := v_sort + 1;
v_section_id := gen_id();
INSERT INTO "MenuSection" (id, "menuId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES (v_section_id, v_bar_menu_id, 'bier', v_sort, true, NOW(), NOW());
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'de', 'Bier');
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'en', 'Beer');

-- Ottakringer Helles vom Fass
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 1, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Ottakringer Helles vom Fass', 'Fassbier');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Ottakringer Lager on Draught', 'Draught beer');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,20', 4.10, 'EUR', '0.2l', 0, false);
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,30', 4.70, 'EUR', '0.3l', 1, true);
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,50', 6.20, 'EUR', '0.5l', 2, false);

-- Ottakringer Null Komma Josef
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Ottakringer Null Komma Josef', 'Alkoholfrei');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Ottakringer Null Komma Josef', 'Non-alcoholic');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,33', 4.70, 'EUR', '0.33l', 0, true);

-- Paulaner Hefe-Weissbier
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 3, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Paulaner Hefe-Weissbier Naturtrueb', 'Weizenbier');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Paulaner Wheat Beer', 'Unfiltered wheat beer');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,50', 6.20, 'EUR', '0.5l', 0, true);

-- Paulaner Hefe-Weissbier Alkoholfrei
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Paulaner Hefe-Weissbier Alkoholfrei', 'Alkoholfreies Weizenbier');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Paulaner Wheat Beer Alcohol-Free', 'Non-alcoholic wheat beer');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,50', 6.20, 'EUR', '0.5l', 0, true);

-- Heineken Premium Lager
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 5, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Heineken Premium Lager');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Heineken Premium Lager');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,33', 5.10, 'EUR', '0.33l', 0, true);

-- Radler
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 6, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Radler');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Radler (Shandy)');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,30', 4.70, 'EUR', '0.3l', 0, true);
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,50', 6.20, 'EUR', '0.5l', 1, false);

-- =====================================================
-- SECTION: Heimische Destillate & Grappa
-- =====================================================
v_sort := v_sort + 1;
v_section_id := gen_id();
INSERT INTO "MenuSection" (id, "menuId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES (v_section_id, v_bar_menu_id, 'destillate-grappa', v_sort, true, NOW(), NOW());
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'de', 'Destillate, Grappa & Likoer');
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'en', 'Spirits, Grappa & Liqueur');

-- Herzog Marille
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 1, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Herzog Marille', 'Edelbrand');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Herzog Apricot', 'Fine brandy');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 6.20, 'EUR', '2cl', 0, true);

-- Herzog Salzburger Birne
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Herzog Salzburger Birne', 'Edelbrand');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Herzog Salzburg Pear', 'Fine brandy');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 6.20, 'EUR', '2cl', 0, true);

-- Herzog Zwetschke
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 3, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Herzog Zwetschke', 'Edelbrand');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Herzog Plum', 'Fine brandy');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 6.20, 'EUR', '2cl', 0, true);

-- Herzog Waldhimbeere
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Herzog Waldhimbeere', 'Edelbrand');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Herzog Wild Raspberry', 'Fine brandy');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 11.40, 'EUR', '2cl', 0, true);

-- Piave Grappa Cuore
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 5, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Piave Grappa Cuore', 'Grappa');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Piave Grappa Cuore', 'Grappa');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 5.20, 'EUR', '2cl', 0, true);

-- Herzog Marillenlikoer
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 6, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Herzog Marillenlikoer', 'Likoer');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Herzog Apricot Liqueur', 'Liqueur');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 6.20, 'EUR', '2cl', 0, true);

-- Herzog Schoko-Minze Likoer
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 7, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Herzog Schoko-Minze Likoer', 'Likoer');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Herzog Chocolate Mint Liqueur', 'Liqueur');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 6.20, 'EUR', '2cl', 0, true);

-- =====================================================
-- SECTION: Brandy, Rum & Co
-- =====================================================
v_sort := v_sort + 1;
v_section_id := gen_id();
INSERT INTO "MenuSection" (id, "menuId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES (v_section_id, v_bar_menu_id, 'brandy-rum', v_sort, true, NOW(), NOW());
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'de', 'Brandy, Rum & Co');
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'en', 'Brandy, Rum & Co');

-- Remy Martin VSOP
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 1, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Remy Martin VSOP', 'Cognac Fine Champagne AOC');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Remy Martin VSOP', 'Cognac Fine Champagne AOC');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 6.20, 'EUR', '2cl', 0, true);

-- Hennessy VS
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Hennessy VS', 'Cognac');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Hennessy VS', 'Cognac');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 6.20, 'EUR', '2cl', 0, true);

-- Metaxa 5 Sterne
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 3, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Metaxa *****', 'Griechenland');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Metaxa *****', 'Greece');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 5.80, 'EUR', '2cl', 0, true);

-- Diplomatico Reserva Exclusiva
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Diplomatico Reserva Exclusiva Rum', 'Venezuela');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Diplomatico Reserva Exclusiva Rum', 'Venezuela');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '4cl', 15.30, 'EUR', '4cl', 0, true);

-- Ron Zacapa 23
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 5, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Ron Zacapa Centenario Rum 23 years', 'Guatemala');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Ron Zacapa Centenario Rum 23 years', 'Guatemala');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '4cl', 20.50, 'EUR', '4cl', 0, true);

-- Ron Zacapa XO
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "highlightType", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 6, true, false, true, 'PREMIUM', NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Ron Zacapa Centenario XO Solera Gran Reserva Especial', 'Guatemala');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Ron Zacapa Centenario XO Solera Gran Reserva Especial', 'Guatemala');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '4cl', 25.60, 'EUR', '4cl', 0, true);

-- =====================================================
-- SECTION: Whiskey & Scotch
-- =====================================================
v_sort := v_sort + 1;
v_section_id := gen_id();
INSERT INTO "MenuSection" (id, "menuId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES (v_section_id, v_bar_menu_id, 'whiskey-scotch', v_sort, true, NOW(), NOW());
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'de', 'Whiskey & Scotch');
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'en', 'Whiskey & Scotch');

-- Chivas Regal 12
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 1, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Chivas Regal 12 years', 'Blended Scotch Whisky');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Chivas Regal 12 years', 'Blended Scotch Whisky');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '4cl', 9.30, 'EUR', '4cl', 0, true);

-- Dimple 15
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Dimple 15 years', 'Blended Scotch Whisky');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Dimple 15 years', 'Blended Scotch Whisky');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '4cl', 9.30, 'EUR', '4cl', 0, true);

-- Johnnie Walker Red Label
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 3, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Johnnie Walker Red Label', 'Blended Scotch Whisky');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Johnnie Walker Red Label', 'Blended Scotch Whisky');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '4cl', 8.30, 'EUR', '4cl', 0, true);

-- Glenkinchie 10
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Glenkinchie 10 years', 'Single Malt Scotch Whisky');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Glenkinchie 10 years', 'Single Malt Scotch Whisky');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '4cl', 14.60, 'EUR', '4cl', 0, true);

-- Dalwhinnie 15
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 5, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Dalwhinnie 15 years', 'Single Malt Scotch Whisky');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Dalwhinnie 15 years', 'Single Malt Scotch Whisky');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '4cl', 14.60, 'EUR', '4cl', 0, true);

-- Oban 14
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 6, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Oban 14 years', 'Single Malt Scotch Whisky');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Oban 14 years', 'Single Malt Scotch Whisky');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '4cl', 14.60, 'EUR', '4cl', 0, true);

-- Cragganmore 12
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 7, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Cragganmore 12 years', 'Single Malt Scotch Whisky');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Cragganmore 12 years', 'Single Malt Scotch Whisky');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '4cl', 14.60, 'EUR', '4cl', 0, true);

-- Ballantine's Finest
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 8, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Ballantine''s Finest', 'Blended Scotch Whisky');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Ballantine''s Finest', 'Blended Scotch Whisky');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '4cl', 8.30, 'EUR', '4cl', 0, true);

-- Lagavulin 16
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "highlightType", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 9, true, false, true, 'PREMIUM', NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Lagavulin 16 years', 'Single Malt Scotch Whisky');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Lagavulin 16 years', 'Single Malt Scotch Whisky');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '4cl', 14.60, 'EUR', '4cl', 0, true);

-- Talisker 10
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 10, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Talisker 10 years', 'Single Malt Scotch Whisky');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Talisker 10 years', 'Single Malt Scotch Whisky');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '4cl', 14.60, 'EUR', '4cl', 0, true);

-- Tullamore DEW
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 11, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Tullamore D.E.W.', 'Irish Blended Whiskey');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Tullamore D.E.W.', 'Irish Blended Whiskey');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '4cl', 8.30, 'EUR', '4cl', 0, true);

-- Jack Daniel's
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt")
VALUES (v_item_id, v_section_id, 'DRINK', 12, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Jack Daniel''s Old No. 7', 'Tennessee Whiskey');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Jack Daniel''s Old No. 7', 'Tennessee Whiskey');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '4cl', 9.30, 'EUR', '4cl', 0, true);

-- =====================================================
-- SECTION: Bitter & Likoer
-- =====================================================
v_sort := v_sort + 1;
v_section_id := gen_id();
INSERT INTO "MenuSection" (id, "menuId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES (v_section_id, v_bar_menu_id, 'bitter-likoer', v_sort, true, NOW(), NOW());
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'de', 'Bitter & Likoer');
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'en', 'Bitter & Liqueur');

-- Fernet Branca
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 1, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Fernet Branca');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Fernet Branca');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 5.20, 'EUR', '2cl', 0, true);

-- Ramazzotti Amaro
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Ramazzotti Amaro');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Ramazzotti Amaro');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 5.20, 'EUR', '2cl', 0, true);

-- Disaronno Amaretto
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 3, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Disaronno Amaretto Originale');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Disaronno Amaretto Originale');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 5.20, 'EUR', '2cl', 0, true);

-- Tia Maria
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Tia Maria');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Tia Maria');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 5.20, 'EUR', '2cl', 0, true);

-- Luxardo Sambuca
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 5, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Luxardo Sambuca');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Luxardo Sambuca');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 5.20, 'EUR', '2cl', 0, true);

-- Grand Marnier
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 6, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Grand Marnier');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Grand Marnier');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 5.20, 'EUR', '2cl', 0, true);

-- Drambuie
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 7, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Drambuie Liqueur');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Drambuie Liqueur');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 5.70, 'EUR', '2cl', 0, true);

-- Baileys
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 8, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Baileys Irish Cream');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Baileys Irish Cream');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 5.70, 'EUR', '2cl', 0, true);

-- Southern Comfort
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 9, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Southern Comfort Original');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Southern Comfort Original');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '4cl', 9.30, 'EUR', '4cl', 0, true);

-- Kahlua
v_item_id := gen_id();
INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 10, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Kahlua 20%');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Kahlua 20%');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '2cl', 5.20, 'EUR', '2cl', 0, true);

-- =====================================================
-- SECTION: Cocktails
-- =====================================================
v_sort := v_sort + 1;
v_section_id := gen_id();
INSERT INTO "MenuSection" (id, "menuId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES (v_section_id, v_bar_menu_id, 'cocktails', v_sort, true, NOW(), NOW());
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'de', 'Cocktails');
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'en', 'Cocktails');

-- All cocktails in compact form
v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 1, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Martini Cocktail', 'Martini dry, Gin');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Martini Cocktail', 'Martini dry, Gin');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 9.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Manhattan', 'Canadian, Martini Rosso, Angostura');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Manhattan', 'Canadian, Martini Rosso, Angostura');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 9.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 3, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Negroni');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Negroni');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 9.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Old Fashioned', 'Bourbon, Angostura, Soda, Wuerfelzucker, Orange');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Old Fashioned', 'Bourbon, Angostura, Soda, Sugar, Orange');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 9.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 5, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Cosmopolitan', 'Cointreau, Vodka, Limettensaft, Cranberrysaft');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Cosmopolitan', 'Cointreau, Vodka, Lime juice, Cranberry juice');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 9.80, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 6, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Sour''s', 'Whiskey, Vodka, Averna, Aperol oder Amaretto | Zitronensaft, Zuckersirup');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Sour''s', 'Whiskey, Vodka, Averna, Aperol or Amaretto | Lemon juice, Sugar syrup');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 9.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 7, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Basil Smash', 'Bombay Sapphire, Basilikum, Zitronensaft, Zuckersirup, Soda');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Basil Smash', 'Bombay Sapphire, Basil, Lemon juice, Sugar syrup, Soda');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 10.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 8, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Gin Fizz', 'Gin, Zitronensaft, Soda');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Gin Fizz', 'Gin, Lemon juice, Soda');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 9.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 9, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Margarita', 'Cointreau, Tequila, Limettensaft, Salzrand');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Margarita', 'Cointreau, Tequila, Lime juice, Salt rim');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 9.80, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 10, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Black Russian', 'Vodka, Kahlua');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Black Russian', 'Vodka, Kahlua');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 8.80, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 11, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'White Russian', 'Vodka, Kahlua, Sahne');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'White Russian', 'Vodka, Kahlua, Cream');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 8.80, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 12, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Pina Colada', 'Weisser Rum, Kokossirup, Sahne, Ananassaft');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Pina Colada', 'White Rum, Coconut syrup, Cream, Pineapple juice');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 11.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 13, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Swimming Pool', 'Weisser Rum, Vodka, Kokossirup, Sahne, Blue Curacao, Ananassaft');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Swimming Pool', 'White Rum, Vodka, Coconut syrup, Cream, Blue Curacao, Pineapple juice');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 11.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 14, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Long Island Ice Tea', 'Weisser Rum, brauner Rum, Vodka, Gin, Triple sec, Zitronensaft, Pepsi Cola');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Long Island Iced Tea', 'White Rum, Dark Rum, Vodka, Gin, Triple sec, Lemon juice, Cola');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 14.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 15, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Caipirinha', 'Pitu, Limetten, brauner Zucker');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Caipirinha', 'Cachaca, Lime, Brown sugar');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 10.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 16, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Caipiroska', 'Vodka, Limette, brauner Zucker');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Caipiroska', 'Vodka, Lime, Brown sugar');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 10.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 17, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Mai Tai', 'Brauner Rum, weisser Rum, Lime Juice, Apricot Brandy, Mandelsirup');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Mai Tai', 'Dark Rum, White Rum, Lime juice, Apricot Brandy, Almond syrup');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 11.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 18, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Mojito', 'Rum, Limette, Pfefferminze, Angostura, Soda');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Mojito', 'Rum, Lime, Mint, Angostura, Soda');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 11.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 19, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Planter''s Punch', 'Brauner Rum, Weisser Rum, Grenadine, Zitronen- Orangen- und Ananassaft');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Planter''s Punch', 'Dark Rum, White Rum, Grenadine, Lemon, Orange & Pineapple juice');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 11.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 20, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Sex on the Beach', 'Vodka, Pfirsichlikoer, Orangensaft, Cranberrynektar');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Sex on the Beach', 'Vodka, Peach liqueur, Orange juice, Cranberry nectar');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 11.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 21, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Tequila Sunrise', 'Tequila, Zitronensaft, Orangensaft, Grenadine');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Tequila Sunrise', 'Tequila, Lemon juice, Orange juice, Grenadine');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 11.20, 'EUR', 0, true);

-- Alkoholfrei / Non-alcoholic cocktails
v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 22, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Coconut Kiss (alkoholfrei)', 'Kokossirup, Sahne, Ananassaft, Grenadine');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Coconut Kiss (non-alcoholic)', 'Coconut syrup, Cream, Pineapple juice, Grenadine');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 8.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 23, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Florida (alkoholfrei)', 'Orangensaft, Ananassaft, Grenadine, Zitronensaft');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Florida (non-alcoholic)', 'Orange juice, Pineapple juice, Grenadine, Lemon juice');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 8.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 24, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Ipanema (alkoholfrei)', '');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Ipanema (non-alcoholic)', '');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 8.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 25, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Virgin Mojito (alkoholfrei)', 'Limette, Zucker, Minze, Lemon Soda');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Virgin Mojito (non-alcoholic)', 'Lime, Sugar, Mint, Lemon Soda');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Cocktail', 8.20, 'EUR', 0, true);

-- =====================================================
-- SECTION: Longdrinks
-- =====================================================
v_sort := v_sort + 1;
v_section_id := gen_id();
INSERT INTO "MenuSection" (id, "menuId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES (v_section_id, v_bar_menu_id, 'longdrinks', v_sort, true, NOW(), NOW());
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'de', 'Longdrinks');
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'en', 'Long Drinks');

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 1, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Cuba Libre');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Cuba Libre');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 11.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Bacardi Cola');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Bacardi Cola');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 9.80, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 3, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Southern Comfort Ginger Ale');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Southern Comfort Ginger Ale');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 9.80, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Vodka Lemon');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Vodka Lemon');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 9.80, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 5, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Vodka Orange');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Vodka Orange');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 9.80, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 6, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Vodka Red Bull');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Vodka Red Bull');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 11.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 7, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Whiskey Cola');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Whiskey Cola');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 9.80, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 8, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Gin & Tonic');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Gin & Tonic');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 9.80, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 9, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Bombay Sapphire & Tonic');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Bombay Sapphire & Tonic');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 12.30, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "highlightType", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 10, true, false, true, 'PREMIUM', NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Hendrick''s & Tonic');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Hendrick''s & Tonic');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 15.30, 'EUR', 0, true);

-- =====================================================
-- SECTION: Alkoholfreie Getraenke
-- =====================================================
v_sort := v_sort + 1;
v_section_id := gen_id();
INSERT INTO "MenuSection" (id, "menuId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES (v_section_id, v_bar_menu_id, 'alkoholfreie-getraenke', v_sort, true, NOW(), NOW());
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'de', 'Alkoholfreie Getraenke');
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'en', 'Soft Drinks');

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 1, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Holunder Gespritzt');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Elderflower Spritzer');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,50', 4.70, 'EUR', '0.5l', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Soda');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Soda');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,25', 3.20, 'EUR', '0.25l', 0, true);
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,50', 5.20, 'EUR', '0.5l', 1, false);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 3, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Skiwasser');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Ski Water (Raspberry Lemonade)');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,25', 3.20, 'EUR', '0.25l', 0, true);
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,50', 4.70, 'EUR', '0.5l', 1, false);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Almdudler Kraeuterlimonade');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Almdudler Herbal Lemonade');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,33', 5.20, 'EUR', '0.33l', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 5, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Red Bull Energy Drink');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Red Bull Energy Drink');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,25', 6.70, 'EUR', '0.25l', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 6, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Coca Cola');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Coca Cola');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,25', 4.20, 'EUR', '0.25l', 0, true);
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,50', 6.20, 'EUR', '0.5l', 1, false);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 7, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Coca Cola Zero');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Coca Cola Zero');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,33', 5.20, 'EUR', '0.33l', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 8, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Fanta');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Fanta');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,25', 4.20, 'EUR', '0.25l', 0, true);
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,50', 6.20, 'EUR', '0.5l', 1, false);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 9, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Sprite');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Sprite');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,25', 4.20, 'EUR', '0.25l', 0, true);
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,50', 6.20, 'EUR', '0.5l', 1, false);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 10, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Spezi');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Spezi (Cola-Orange Mix)');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,25', 4.20, 'EUR', '0.25l', 0, true);
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,50', 6.20, 'EUR', '0.5l', 1, false);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 11, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Eistee');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Iced Tea');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,33', 5.20, 'EUR', '0.33l', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 12, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Thomas Henry Bitter Lemon');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Thomas Henry Bitter Lemon');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,20', 4.20, 'EUR', '0.2l', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 13, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Thomas Henry Ginger Ale');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Thomas Henry Ginger Ale');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,20', 4.20, 'EUR', '0.2l', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 14, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Thomas Henry Tonic Water');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Thomas Henry Tonic Water');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,20', 4.20, 'EUR', '0.2l', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 15, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Diverse Saefte gespritzt');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Assorted Juice Spritzers');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,50', 6.20, 'EUR', '0.5l', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 16, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Rauch Orangensaft');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Rauch Orange Juice');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, volume, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, '0,25', 4.20, 'EUR', '0.25l', 0, true);

-- =====================================================
-- SECTION: Heissgetraenke / Hot Drinks
-- =====================================================
v_sort := v_sort + 1;
v_section_id := gen_id();
INSERT INTO "MenuSection" (id, "menuId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
VALUES (v_section_id, v_bar_menu_id, 'heissgetraenke', v_sort, true, NOW(), NOW());
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'de', 'Heissgetraenke');
INSERT INTO "MenuSectionTranslation" (id, "sectionId", "languageCode", name) VALUES (gen_id(), v_section_id, 'en', 'Hot Drinks');

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 1, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Cappuccino');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Cappuccino');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Tasse', 5.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 2, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Doppelter Espresso');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Double Espresso');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Tasse', 6.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 3, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Espresso');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Espresso');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Tasse', 4.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 4, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Irish Coffee');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Irish Coffee');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 9.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 5, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Latte Macchiato');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Latte Macchiato');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Glas', 6.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 6, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Tasse Kaffee / Verlaengerter');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Coffee / Americano');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Tasse', 4.70, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 7, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Tee - verschiedene Sorten');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Tea - various flavours');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Tasse', 4.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 8, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Tee mit Rum');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Tea with Rum');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Tasse', 6.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 9, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Heisse Schokolade');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Hot Chocolate');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Tasse', 5.70, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 10, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'de', 'Lumumba', 'Heisse Schokolade & Rum');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name, "shortDescription") VALUES (gen_id(), v_item_id, 'en', 'Lumumba', 'Hot Chocolate & Rum');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Tasse', 7.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 11, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Gluehwein');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Mulled Wine');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Tasse', 7.20, 'EUR', 0, true);

v_item_id := gen_id(); INSERT INTO "MenuItem" (id, "sectionId", type, "sortOrder", "isActive", "isSoldOut", "isHighlight", "createdAt", "updatedAt") VALUES (v_item_id, v_section_id, 'DRINK', 12, true, false, false, NOW(), NOW());
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'de', 'Jagertee');
INSERT INTO "MenuItemTranslation" (id, "menuItemId", "languageCode", name) VALUES (gen_id(), v_item_id, 'en', 'Jagertee (Austrian Hot Tea & Rum)');
INSERT INTO "PriceVariant" (id, "menuItemId", label, price, currency, "sortOrder", "isDefault") VALUES (gen_id(), v_item_id, 'Tasse', 8.20, 'EUR', 0, true);

DROP FUNCTION IF EXISTS gen_id();
RAISE NOTICE 'Barkarte erfolgreich geseedet! 10 Sektionen, ~100 Artikel.';
END $$;
