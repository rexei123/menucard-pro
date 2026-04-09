-- =====================================================
-- MenuCard Pro - Data Migration: MenuItem → Product
-- Run: psql <connstring> -f migrate-to-products.sql
-- =====================================================

DO $$
DECLARE
  v_tid TEXT;
  v_pl_rest TEXT;
  v_pl_bar TEXT;
  v_pl TEXT;
  rec RECORD;
  pv RECORD;
  v_prod_id TEXT;
  v_fq_id TEXT;
  v_pg_id TEXT;
  v_mi_id TEXT;
  v_loc_slug TEXT;
  v_section_name TEXT;
  v_count INT := 0;
  v_sku_counter INT := 0;
BEGIN
  SELECT id INTO v_tid FROM "Tenant" WHERE slug='hotel-sonnblick';
  SELECT id INTO v_pl_rest FROM "PriceLevel" WHERE "tenantId"=v_tid AND slug='restaurant';
  SELECT id INTO v_pl_bar FROM "PriceLevel" WHERE "tenantId"=v_tid AND slug='bar';

  RAISE NOTICE 'Tenant: %, PL Resta: %, PL Bar: %', v_tid, v_pl_rest, v_pl_bar;

  FOR rec IN
    SELECT
      mi.id as mi_id, mi.type as mi_type, mi."sectionId", mi."sortOrder",
      mi."isActive", mi."isSoldOut", mi."isHighlight", mi."highlightType",
      m.type as menu_type, l.slug as loc_slug,
      mst.name as section_name
    FROM "MenuItem" mi
    JOIN "MenuSection" ms ON ms.id = mi."sectionId"
    JOIN "Menu" m ON m.id = ms."menuId"
    JOIN "Location" l ON l.id = m."locationId"
    LEFT JOIN "MenuSectionTranslation" mst ON mst."sectionId"=ms.id AND mst."languageCode"='de'
    ORDER BY m.type, ms."sortOrder", mi."sortOrder"
  LOOP
    v_sku_counter := v_sku_counter + 1;
    v_prod_id := gen_random_uuid()::text;
    v_mi_id := rec.mi_id;
    v_loc_slug := rec.loc_slug;
    v_section_name := COALESCE(rec.section_name, '');
    v_pl := CASE WHEN v_loc_slug = 'bar' THEN v_pl_bar ELSE v_pl_rest END;

    -- === Determine ProductGroup ===
    v_pg_id := NULL;

    IF rec.menu_type = 'WINE' THEN
      IF v_section_name ILIKE '%Schaumwein%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='schaumwein';
      ELSIF v_section_name ILIKE '%Weiß%' OR v_section_name ILIKE '%weiss%' OR v_section_name ILIKE '%Grüner%' OR v_section_name ILIKE '%Sauvignon%' OR v_section_name ILIKE '%Chardonnay%' OR v_section_name ILIKE '%Riesling%' OR v_section_name ILIKE '%Muskateller%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='weisswein';
      ELSIF v_section_name ILIKE '%Rosé%' OR v_section_name = 'Roséwein' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='rose';
      ELSIF v_section_name ILIKE '%Dessert%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='dessertwein';
      ELSIF v_section_name ILIKE '%Likör%' OR v_section_name ILIKE '%Port%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='likoerwein';
      ELSIF v_section_name ILIKE '%Glas%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='wein-im-glas';
      ELSE
        -- Default for wine: rotwein
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='rotwein';
      END IF;

    ELSIF rec.menu_type = 'BAR' THEN
      IF v_section_name ILIKE '%Schaumwein%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='schaumwein';
      ELSIF v_section_name ILIKE '%Aperitif%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='aperitif';
      ELSIF v_section_name ILIKE '%Longdrink%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='longdrinks';
      ELSIF v_section_name ILIKE '%Sour%' OR v_section_name ILIKE '%Mule%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='cocktails';
      ELSIF v_section_name ILIKE '%Cocktail%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='cocktails';
      ELSIF v_section_name ILIKE '%Gin%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='spirituosen';
      ELSIF v_section_name ILIKE '%Whisk%' OR v_section_name ILIKE '%Scotch%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='whiskey-scotch';
      ELSIF v_section_name ILIKE '%Rum%' OR v_section_name ILIKE '%Cognac%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='brandy-rum';
      ELSIF v_section_name ILIKE '%Bitter%' AND v_section_name ILIKE '%Likör%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='bitter-likoer';
      ELSIF v_section_name ILIKE '%Likör%' OR v_section_name ILIKE '%Port%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='bitter-likoer';
      ELSIF v_section_name ILIKE '%Bier%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='bier';
      ELSIF v_section_name ILIKE '%Wein%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='wein-im-glas';
      ELSIF v_section_name ILIKE '%Edel%' OR v_section_name ILIKE '%Destillat%' OR v_section_name ILIKE '%Grappa%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='destillate';
      ELSIF v_section_name ILIKE '%Alkoholfrei%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='alkoholfrei';
      ELSIF v_section_name ILIKE '%Heiß%' OR v_section_name ILIKE '%Heiss%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='heissgetraenke';
      ELSE
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='getraenke';
      END IF;

    ELSIF rec.menu_type = 'EVENT' THEN
      IF v_section_name ILIKE '%Buffet%' OR v_section_name ILIKE '%Salat%' OR v_section_name ILIKE '%Vorspeise%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='vorspeisen';
      ELSIF v_section_name ILIKE '%Suppe%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='suppen';
      ELSIF v_section_name ILIKE '%Zwischen%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='zwischengerichte';
      ELSIF v_section_name ILIKE '%Haupt%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='hauptgerichte';
      ELSIF v_section_name ILIKE '%Dessert%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='desserts';
      ELSIF v_section_name ILIKE '%Käse%' OR v_section_name ILIKE '%Obst%' THEN
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='kaese-obst';
      ELSE
        SELECT id INTO v_pg_id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='speisen';
      END IF;
    END IF;

    -- === Create Product ===
    INSERT INTO "Product" (id, "tenantId", "productGroupId", sku, type,
      status, "isHighlight", "highlightType", "sortOrder", "createdAt", "updatedAt")
    VALUES (
      v_prod_id, v_tid, v_pg_id,
      'SB-' || LPAD(v_sku_counter::text, 4, '0'),
      rec.mi_type::text::"ProductType",
      CASE WHEN rec."isSoldOut" THEN 'SOLD_OUT'::"ProductStatus"
           WHEN NOT rec."isActive" THEN 'ARCHIVED'::"ProductStatus"
           ELSE 'ACTIVE'::"ProductStatus" END,
      rec."isHighlight", rec."highlightType", rec."sortOrder", NOW(), NOW()
    );

    -- === Copy Translations ===
    INSERT INTO "ProductTranslation" (id, "productId", "languageCode", name, "shortDescription", "longDescription", "servingSuggestion")
    SELECT gen_random_uuid()::text, v_prod_id, "languageCode", name, "shortDescription", "longDescription", "servingSuggestion"
    FROM "MenuItemTranslation" WHERE "menuItemId" = v_mi_id;

    -- === Copy PriceVariants → ProductPrice ===
    FOR pv IN SELECT * FROM "PriceVariant" WHERE "menuItemId" = v_mi_id ORDER BY "sortOrder"
    LOOP
      v_fq_id := NULL;

      -- Match volume to FillQuantity
      IF pv.volume = '0.75l' THEN
        SELECT id INTO v_fq_id FROM "FillQuantity" WHERE "tenantId"=v_tid AND label='Flasche 0,75l';
      ELSIF pv.volume = '0.375l' THEN
        SELECT id INTO v_fq_id FROM "FillQuantity" WHERE "tenantId"=v_tid AND label='Halbflasche 0,375l';
      ELSIF pv.volume = '1.5l' THEN
        SELECT id INTO v_fq_id FROM "FillQuantity" WHERE "tenantId"=v_tid AND label='Magnum 1,5l';
      ELSIF pv.volume = '0.125l' THEN
        SELECT id INTO v_fq_id FROM "FillQuantity" WHERE "tenantId"=v_tid AND label='1/8 offen';
      ELSIF pv.volume = '0.1l' THEN
        SELECT id INTO v_fq_id FROM "FillQuantity" WHERE "tenantId"=v_tid AND label='1/10 offen';
      ELSIF pv.volume = '4cl' THEN
        SELECT id INTO v_fq_id FROM "FillQuantity" WHERE "tenantId"=v_tid AND label='Glas 4cl';
      ELSIF pv.volume = '2cl' THEN
        SELECT id INTO v_fq_id FROM "FillQuantity" WHERE "tenantId"=v_tid AND label='Glas 2cl';
      ELSIF pv.volume = '5cl' THEN
        SELECT id INTO v_fq_id FROM "FillQuantity" WHERE "tenantId"=v_tid AND label='Glas 5cl';
      ELSIF pv.volume = '0.5l' THEN
        SELECT id INTO v_fq_id FROM "FillQuantity" WHERE "tenantId"=v_tid AND label='0,50l';
      ELSIF pv.volume = '0.33l' THEN
        SELECT id INTO v_fq_id FROM "FillQuantity" WHERE "tenantId"=v_tid AND label='0,33l';
      ELSIF pv.volume = '0.3l' THEN
        SELECT id INTO v_fq_id FROM "FillQuantity" WHERE "tenantId"=v_tid AND label='0,30l';
      ELSIF pv.volume = '0.25l' THEN
        SELECT id INTO v_fq_id FROM "FillQuantity" WHERE "tenantId"=v_tid AND label='0,25l';
      ELSIF pv.volume = '0.2l' THEN
        SELECT id INTO v_fq_id FROM "FillQuantity" WHERE "tenantId"=v_tid AND label='0,20l';
      ELSIF pv.volume = '0.7l' THEN
        SELECT id INTO v_fq_id FROM "FillQuantity" WHERE "tenantId"=v_tid AND label='Flasche 0,5l';
      ELSE
        -- Default: Portion for items without volume
        SELECT id INTO v_fq_id FROM "FillQuantity" WHERE "tenantId"=v_tid AND label='Portion';
      END IF;

      IF v_fq_id IS NOT NULL THEN
        INSERT INTO "ProductPrice" (id, "productId", "fillQuantityId", "priceLevelId",
          price, currency, "isDefault", "sortOrder")
        VALUES (
          gen_random_uuid()::text, v_prod_id, v_fq_id, v_pl,
          pv.price, COALESCE(pv.currency, 'EUR'), pv."isDefault", pv."sortOrder"
        )
        ON CONFLICT DO NOTHING;
      END IF;
    END LOOP;

    -- === Copy WineProfile ===
    INSERT INTO "ProductWineProfile" (id, "productId", winery, vintage,
      "grapeVarieties", region, country, appellation, style, body, sweetness,
      "bottleSize", "alcoholContent", "servingTemp", "tastingNotes",
      "foodPairing", "stockQuantity", "internalNotes")
    SELECT gen_random_uuid()::text, v_prod_id, winery, vintage,
      "grapeVarieties", region, country, appellation, style, body, sweetness,
      "bottleSize", "alcoholContent", "servingTemp", "tastingNotes",
      "foodPairing", "stockQuantity", "internalNotes"
    FROM "WineProfile" WHERE "menuItemId" = v_mi_id;

    -- === Copy BeverageDetail ===
    INSERT INTO "ProductBeverageDetail" (id, "productId", brand, producer,
      category, "alcoholContent", "servingTemp", carbonated, origin)
    SELECT gen_random_uuid()::text, v_prod_id, brand, producer,
      category, "alcoholContent", "servingTemp", carbonated, origin
    FROM "BeverageDetail" WHERE "menuItemId" = v_mi_id;

    -- === Copy Allergens ===
    INSERT INTO "ProductAllergen" ("productId", "allergenId")
    SELECT v_prod_id, "allergenId"
    FROM "MenuItemAllergen" WHERE "menuItemId" = v_mi_id
    ON CONFLICT DO NOTHING;

    -- === Copy Tags ===
    INSERT INTO "ProductTag" ("productId", "tagId")
    SELECT v_prod_id, "tagId"
    FROM "MenuItemTag" WHERE "menuItemId" = v_mi_id
    ON CONFLICT DO NOTHING;

    -- === Create MenuPlacement ===
    INSERT INTO "MenuPlacement" (id, "menuSectionId", "productId", "priceLevelId",
      "sortOrder", "isVisible", "highlightType", "createdAt", "updatedAt")
    VALUES (
      gen_random_uuid()::text, rec."sectionId", v_prod_id, v_pl,
      rec."sortOrder", rec."isActive", rec."highlightType", NOW(), NOW()
    )
    ON CONFLICT DO NOTHING;

    v_count := v_count + 1;
  END LOOP;

  RAISE NOTICE 'Migration complete: % products created', v_count;
END $$;

-- === Verify ===
SELECT 'Products' as entity, COUNT(*) as count FROM "Product"
UNION ALL SELECT 'Translations', COUNT(*) FROM "ProductTranslation"
UNION ALL SELECT 'Prices', COUNT(*) FROM "ProductPrice"
UNION ALL SELECT 'WineProfiles', COUNT(*) FROM "ProductWineProfile"
UNION ALL SELECT 'BeverageDetails', COUNT(*) FROM "ProductBeverageDetail"
UNION ALL SELECT 'Allergens', COUNT(*) FROM "ProductAllergen"
UNION ALL SELECT 'Tags', COUNT(*) FROM "ProductTag"
UNION ALL SELECT 'Placements', COUNT(*) FROM "MenuPlacement"
ORDER BY entity;
