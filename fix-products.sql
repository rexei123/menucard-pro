-- =====================================================
-- MenuCard Pro - DB Cleanup: Rosé-Fix + Deduplizierung
-- Run: psql <connstring> -f fix-products.sql
-- =====================================================

DO $$
DECLARE
  v_tid TEXT;
  v_rose_gid TEXT;
  v_keep_id TEXT;
  v_dup RECORD;
  v_dedup_count INT := 0;
BEGIN
  SELECT id INTO v_tid FROM "Tenant" WHERE slug='hotel-sonnblick';
  SELECT id INTO v_rose_gid FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='rose';

  -- =================================================================
  -- 1. FIX ROSÉ: Move wines with style=ROSE to Rosé group
  -- =================================================================
  UPDATE "Product" p SET "productGroupId" = v_rose_gid
  FROM "ProductWineProfile" wp
  WHERE wp."productId" = p.id AND wp.style = 'ROSE' AND p."productGroupId" != v_rose_gid;
  
  RAISE NOTICE '1. Rosé wines moved to Rosé group: %', (SELECT COUNT(*) FROM "Product" p JOIN "ProductWineProfile" wp ON wp."productId"=p.id WHERE wp.style='ROSE' AND p."productGroupId"=v_rose_gid);

  -- =================================================================
  -- 2. DEDUPLICATE: Produkte mit gleichem DE-Namen zusammenführen
  --    Behalte das Produkt mit dem meisten Daten (Weinprofil, Preise)
  --    Hänge alle Placements auf das behaltene Produkt um
  -- =================================================================
  
  FOR v_dup IN
    SELECT pt.name, array_agg(p.id ORDER BY 
      -- Priorität: Hat Weinprofil > hat mehr Preise > ältere ID (zuerst erstellt)
      CASE WHEN EXISTS(SELECT 1 FROM "ProductWineProfile" wp WHERE wp."productId"=p.id) THEN 0 ELSE 1 END,
      (SELECT COUNT(*) FROM "ProductPrice" pp WHERE pp."productId"=p.id) DESC,
      p.id
    ) as ids
    FROM "Product" p
    JOIN "ProductTranslation" pt ON pt."productId"=p.id AND pt."languageCode"='de'
    WHERE p."tenantId" = v_tid
    GROUP BY pt.name
    HAVING COUNT(*) > 1
  LOOP
    -- Keep the first (best) product
    v_keep_id := v_dup.ids[1];
    
    RAISE NOTICE 'Dedup "%": keep %, remove %', v_dup.name, v_keep_id, array_to_string(v_dup.ids[2:], ',');
    
    -- Move all placements to the kept product
    FOR i IN 2..array_length(v_dup.ids, 1) LOOP
      -- Update placements: change productId to kept product
      -- But only if there's no conflict (same section already has the kept product)
      UPDATE "MenuPlacement" SET "productId" = v_keep_id
      WHERE "productId" = v_dup.ids[i]
      AND "menuSectionId" NOT IN (
        SELECT "menuSectionId" FROM "MenuPlacement" WHERE "productId" = v_keep_id
      );
      
      -- Delete remaining placements that would conflict
      DELETE FROM "MenuPlacement" WHERE "productId" = v_dup.ids[i];
      
      -- Delete duplicate product's related data
      DELETE FROM "ProductTranslation" WHERE "productId" = v_dup.ids[i];
      DELETE FROM "ProductPrice" WHERE "productId" = v_dup.ids[i];
      DELETE FROM "ProductWineProfile" WHERE "productId" = v_dup.ids[i];
      DELETE FROM "ProductBeverageDetail" WHERE "productId" = v_dup.ids[i];
      DELETE FROM "ProductAllergen" WHERE "productId" = v_dup.ids[i];
      DELETE FROM "ProductTag" WHERE "productId" = v_dup.ids[i];
      DELETE FROM "ProductMedia" WHERE "productId" = v_dup.ids[i];
      DELETE FROM "ProductCustomFieldValue" WHERE "productId" = v_dup.ids[i];
      DELETE FROM "ProductPairing" WHERE "sourceId" = v_dup.ids[i] OR "targetId" = v_dup.ids[i];
      
      -- Delete the duplicate product
      DELETE FROM "Product" WHERE id = v_dup.ids[i];
      
      v_dedup_count := v_dedup_count + 1;
    END LOOP;
  END LOOP;
  
  RAISE NOTICE '2. Deduplicated: % duplicate products removed', v_dedup_count;

  -- =================================================================
  -- 3. FIX: Bar "Wein" items that are actually wines on the bar menu
  --    Give them Rosé/Wein-im-Glas group based on name patterns
  -- =================================================================
  
  -- Rosé items in wein-im-glas that should be in rose
  UPDATE "Product" p SET "productGroupId" = v_rose_gid
  FROM "ProductTranslation" pt
  WHERE pt."productId" = p.id AND pt."languageCode" = 'de'
  AND (pt.name ILIKE '%Rosé%' OR pt.name ILIKE '%Rose %')
  AND p."productGroupId" = (SELECT id FROM "ProductGroup" WHERE "tenantId"=v_tid AND slug='wein-im-glas')
  AND pt.name NOT ILIKE '%Roses for%'; -- "Roses for Gladys" is a cocktail, not wine

  RAISE NOTICE '3. Bar rosé items fixed';

END $$;

-- === Verify ===
SELECT '=== After Cleanup ===' as info;

SELECT 'Products' as entity, COUNT(*) as count FROM "Product"
UNION ALL SELECT 'Placements', COUNT(*) FROM "MenuPlacement"
UNION ALL SELECT 'Translations', COUNT(*) FROM "ProductTranslation"
UNION ALL SELECT 'Prices', COUNT(*) FROM "ProductPrice"
ORDER BY entity;

SELECT pg.slug, pgt.name, COUNT(p.id) as products
FROM "ProductGroup" pg
LEFT JOIN "ProductGroupTranslation" pgt ON pgt."productGroupId"=pg.id AND pgt."languageCode"='de'
LEFT JOIN "Product" p ON p."productGroupId"=pg.id
GROUP BY pg.slug, pgt.name
HAVING COUNT(p.id) > 0
ORDER BY products DESC;

-- Check no more duplicates
SELECT 'Remaining duplicates:' as check, COUNT(*) as count FROM (
  SELECT pt.name FROM "Product" p
  JOIN "ProductTranslation" pt ON pt."productId"=p.id AND pt."languageCode"='de'
  GROUP BY pt.name HAVING COUNT(*) > 1
) x;
