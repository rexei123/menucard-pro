-- =====================================================
-- MenuCard Pro - Product System Base Data
-- Run: psql <connstring> -f seed-product-base.sql
-- =====================================================

DO $$
DECLARE
  v_tid TEXT;
  v_drinks TEXT;
  v_wine TEXT;
  v_spirits TEXT;
  v_food TEXT;
  v_sub TEXT;
BEGIN
  SELECT id INTO v_tid FROM "Tenant" WHERE slug='hotel-sonnblick';
  IF v_tid IS NULL THEN RAISE EXCEPTION 'Tenant not found!'; END IF;

  -- === TAX RATES ===
  INSERT INTO "TaxRate" (id, "tenantId", name, rate, "isDefault", "isActive")
  VALUES
    (gen_random_uuid()::text, v_tid, 'Getränke 20%', 0.20, true, true),
    (gen_random_uuid()::text, v_tid, 'Speisen 10%', 0.10, false, true)
  ON CONFLICT ("tenantId", name) DO NOTHING;

  -- === PRICE LEVELS ===
  INSERT INTO "PriceLevel" (id, "tenantId", name, slug, "isInternal", "surchargePercent", "sortOrder", "isActive", "createdAt", "updatedAt") VALUES
    (gen_random_uuid()::text, v_tid, 'Restaurant', 'restaurant', false, NULL, 1, true, NOW(), NOW()),
    (gen_random_uuid()::text, v_tid, 'Bar', 'bar', false, NULL, 2, true, NOW(), NOW()),
    (gen_random_uuid()::text, v_tid, 'Room Service', 'room-service', false, 10, 3, true, NOW(), NOW()),
    (gen_random_uuid()::text, v_tid, 'Einkauf', 'einkauf', true, NULL, 10, true, NOW(), NOW())
  ON CONFLICT ("tenantId", slug) DO NOTHING;

  -- === FILL QUANTITIES ===
  INSERT INTO "FillQuantity" (id, "tenantId", label, volume, "sortOrder", "isActive") VALUES
    (gen_random_uuid()::text, v_tid, 'Flasche 0,75l', '0.75l', 1, true),
    (gen_random_uuid()::text, v_tid, 'Halbflasche 0,375l', '0.375l', 2, true),
    (gen_random_uuid()::text, v_tid, 'Magnum 1,5l', '1.5l', 3, true),
    (gen_random_uuid()::text, v_tid, 'Flasche 0,5l', '0.5l', 4, true),
    (gen_random_uuid()::text, v_tid, '1/8 offen', '0.125l', 5, true),
    (gen_random_uuid()::text, v_tid, '1/10 offen', '0.1l', 6, true),
    (gen_random_uuid()::text, v_tid, '1/4 offen', '0.25l', 7, true),
    (gen_random_uuid()::text, v_tid, 'Glas 2cl', '2cl', 8, true),
    (gen_random_uuid()::text, v_tid, 'Glas 4cl', '4cl', 9, true),
    (gen_random_uuid()::text, v_tid, 'Glas 5cl', '5cl', 10, true),
    (gen_random_uuid()::text, v_tid, '0,20l', '0.2l', 11, true),
    (gen_random_uuid()::text, v_tid, '0,25l', '0.25l', 12, true),
    (gen_random_uuid()::text, v_tid, '0,30l', '0.3l', 13, true),
    (gen_random_uuid()::text, v_tid, '0,33l', '0.33l', 14, true),
    (gen_random_uuid()::text, v_tid, '0,50l', '0.5l', 15, true),
    (gen_random_uuid()::text, v_tid, 'Tasse', NULL, 16, true),
    (gen_random_uuid()::text, v_tid, 'Cocktail', NULL, 17, true),
    (gen_random_uuid()::text, v_tid, 'Portion', NULL, 18, true)
  ON CONFLICT ("tenantId", label) DO NOTHING;

  -- === PRODUCT GROUPS ===

  -- Root: Getränke
  v_drinks := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_drinks, v_tid, 'getraenke', 1, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_drinks, 'de', 'Getränke'),
    (gen_random_uuid()::text, v_drinks, 'en', 'Beverages') ON CONFLICT DO NOTHING;

  -- Wein
  v_wine := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_wine, v_tid, v_drinks, 'wein', 1, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_wine, 'de', 'Wein'),
    (gen_random_uuid()::text, v_wine, 'en', 'Wine') ON CONFLICT DO NOTHING;

  -- Wein-Untergruppen
  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_wine, 'weisswein', 1, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Weißwein'), (gen_random_uuid()::text, v_sub, 'en', 'White Wine') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_wine, 'rotwein', 2, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Rotwein'), (gen_random_uuid()::text, v_sub, 'en', 'Red Wine') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_wine, 'rose', 3, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Rosé'), (gen_random_uuid()::text, v_sub, 'en', 'Rosé') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_wine, 'schaumwein', 4, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Schaumwein'), (gen_random_uuid()::text, v_sub, 'en', 'Sparkling Wine') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_wine, 'dessertwein', 5, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Dessertwein'), (gen_random_uuid()::text, v_sub, 'en', 'Dessert Wine') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_wine, 'likoerwein', 6, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Likörwein / Portwein'), (gen_random_uuid()::text, v_sub, 'en', 'Fortified Wine / Port') ON CONFLICT DO NOTHING;

  -- Bier
  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_drinks, 'bier', 2, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Bier'), (gen_random_uuid()::text, v_sub, 'en', 'Beer') ON CONFLICT DO NOTHING;

  -- Spirituosen
  v_spirits := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_spirits, v_tid, v_drinks, 'spirituosen', 3, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_spirits, 'de', 'Spirituosen'), (gen_random_uuid()::text, v_spirits, 'en', 'Spirits') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_spirits, 'whiskey-scotch', 1, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Whiskey & Scotch'), (gen_random_uuid()::text, v_sub, 'en', 'Whiskey & Scotch') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_spirits, 'brandy-rum', 2, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Brandy, Rum & Co'), (gen_random_uuid()::text, v_sub, 'en', 'Brandy, Rum & Co') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_spirits, 'destillate', 3, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Edelbrände & Grappa'), (gen_random_uuid()::text, v_sub, 'en', 'Fine Brandies & Grappa') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_spirits, 'bitter-likoer', 4, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Bitter & Likör'), (gen_random_uuid()::text, v_sub, 'en', 'Bitter & Liqueur') ON CONFLICT DO NOTHING;

  -- Cocktails, Longdrinks, Aperitif
  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_drinks, 'cocktails', 4, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Cocktails'), (gen_random_uuid()::text, v_sub, 'en', 'Cocktails') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_drinks, 'longdrinks', 5, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Longdrinks'), (gen_random_uuid()::text, v_sub, 'en', 'Long Drinks') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_drinks, 'aperitif', 6, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Aperitif'), (gen_random_uuid()::text, v_sub, 'en', 'Aperitif') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_drinks, 'alkoholfrei', 7, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Alkoholfreie Getränke'), (gen_random_uuid()::text, v_sub, 'en', 'Soft Drinks') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_drinks, 'heissgetraenke', 8, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Heißgetränke'), (gen_random_uuid()::text, v_sub, 'en', 'Hot Drinks') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_drinks, 'wein-im-glas', 9, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Wein im Glas'), (gen_random_uuid()::text, v_sub, 'en', 'Wine by the Glass') ON CONFLICT DO NOTHING;

  -- Root: Speisen
  v_food := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_food, v_tid, 'speisen', 2, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_food, 'de', 'Speisen'),
    (gen_random_uuid()::text, v_food, 'en', 'Food') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_food, 'vorspeisen', 1, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Vorspeisen & Buffet'), (gen_random_uuid()::text, v_sub, 'en', 'Starters & Buffet') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_food, 'suppen', 2, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Suppen'), (gen_random_uuid()::text, v_sub, 'en', 'Soups') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_food, 'zwischengerichte', 3, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Zwischengerichte'), (gen_random_uuid()::text, v_sub, 'en', 'Intermediate Courses') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_food, 'hauptgerichte', 4, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Hauptgerichte'), (gen_random_uuid()::text, v_sub, 'en', 'Main Courses') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_food, 'desserts', 5, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Desserts'), (gen_random_uuid()::text, v_sub, 'en', 'Desserts') ON CONFLICT DO NOTHING;

  v_sub := gen_random_uuid()::text;
  INSERT INTO "ProductGroup" (id, "tenantId", "parentId", slug, "sortOrder", "isActive", "createdAt", "updatedAt")
  VALUES (v_sub, v_tid, v_food, 'kaese-obst', 6, true, NOW(), NOW()) ON CONFLICT ("tenantId", slug) DO NOTHING;
  INSERT INTO "ProductGroupTranslation" (id, "productGroupId", "languageCode", name) VALUES
    (gen_random_uuid()::text, v_sub, 'de', 'Käse & Obst'), (gen_random_uuid()::text, v_sub, 'en', 'Cheese & Fruit') ON CONFLICT DO NOTHING;

  RAISE NOTICE 'Base data seeded: 2 tax rates, 4 price levels, 18 fill quantities, 25 product groups';
END $$;
