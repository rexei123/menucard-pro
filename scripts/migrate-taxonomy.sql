-- ============================================
-- TAXONOMIE-MIGRATION: Umlaute + Hierarchie
-- Stand: 17.04.2026
-- ============================================

-- SCHRITT 1: Umlaute in TaxonomyNode.name korrigieren
-- (Slugs bleiben ASCII-kompatibel)
-- ============================================

UPDATE "TaxonomyNode" SET name = 'Österreich' WHERE slug = 'oesterreich' AND type = 'REGION';
UPDATE "TaxonomyNode" SET name = 'Niederösterreich' WHERE slug = 'niederoesterreich' AND type = 'REGION';
UPDATE "TaxonomyNode" SET name = 'Südsteiermark' WHERE slug = 'suedsteiermark' AND type = 'REGION';
UPDATE "TaxonomyNode" SET name = 'Südtirol' WHERE slug = 'suedtirol' AND type = 'REGION';
UPDATE "TaxonomyNode" SET name = 'Grüner Veltliner' WHERE slug = 'gruener-veltliner' AND type = 'GRAPE';
UPDATE "TaxonomyNode" SET name = 'Blaufränkisch' WHERE slug = 'blaufraenkisch' AND type = 'GRAPE';
UPDATE "TaxonomyNode" SET name = 'Österreichisch' WHERE slug = 'oesterreichisch' AND type = 'CUISINE';
UPDATE "TaxonomyNode" SET name = 'Französisch' WHERE slug = 'franzoesisch' AND type = 'CUISINE';
UPDATE "TaxonomyNode" SET name = 'Käse & Obst' WHERE slug = 'kaese-obst' AND type = 'CATEGORY';
UPDATE "TaxonomyNode" SET name = 'Säfte' WHERE slug = 'saefte' AND type = 'CATEGORY';
UPDATE "TaxonomyNode" SET name = 'Heiße Getränke' WHERE slug LIKE 'heisse-getraenke%' AND type = 'CATEGORY';
UPDATE "TaxonomyNode" SET name = 'Edelbrände' WHERE slug = 'edelbraende' AND type = 'CATEGORY';

-- Übersetzungen (DE) korrigieren
UPDATE "TaxonomyNodeTranslation" SET name = 'Österreich'
  WHERE language = 'de' AND "nodeId" IN (SELECT id FROM "TaxonomyNode" WHERE slug = 'oesterreich' AND type = 'REGION');
UPDATE "TaxonomyNodeTranslation" SET name = 'Niederösterreich'
  WHERE language = 'de' AND "nodeId" IN (SELECT id FROM "TaxonomyNode" WHERE slug = 'niederoesterreich' AND type = 'REGION');
UPDATE "TaxonomyNodeTranslation" SET name = 'Südsteiermark'
  WHERE language = 'de' AND "nodeId" IN (SELECT id FROM "TaxonomyNode" WHERE slug = 'suedsteiermark' AND type = 'REGION');
UPDATE "TaxonomyNodeTranslation" SET name = 'Südtirol'
  WHERE language = 'de' AND "nodeId" IN (SELECT id FROM "TaxonomyNode" WHERE slug = 'suedtirol' AND type = 'REGION');
UPDATE "TaxonomyNodeTranslation" SET name = 'Grüner Veltliner'
  WHERE language = 'de' AND "nodeId" IN (SELECT id FROM "TaxonomyNode" WHERE slug = 'gruener-veltliner' AND type = 'GRAPE');
UPDATE "TaxonomyNodeTranslation" SET name = 'Blaufränkisch'
  WHERE language = 'de' AND "nodeId" IN (SELECT id FROM "TaxonomyNode" WHERE slug = 'blaufraenkisch' AND type = 'GRAPE');
UPDATE "TaxonomyNodeTranslation" SET name = 'Österreichisch'
  WHERE language = 'de' AND "nodeId" IN (SELECT id FROM "TaxonomyNode" WHERE slug = 'oesterreichisch' AND type = 'CUISINE');
UPDATE "TaxonomyNodeTranslation" SET name = 'Französisch'
  WHERE language = 'de' AND "nodeId" IN (SELECT id FROM "TaxonomyNode" WHERE slug = 'franzoesisch' AND type = 'CUISINE');
UPDATE "TaxonomyNodeTranslation" SET name = 'Käse & Obst'
  WHERE language = 'de' AND "nodeId" IN (SELECT id FROM "TaxonomyNode" WHERE slug = 'kaese-obst' AND type = 'CATEGORY');
UPDATE "TaxonomyNodeTranslation" SET name = 'Säfte'
  WHERE language = 'de' AND "nodeId" IN (SELECT id FROM "TaxonomyNode" WHERE slug = 'saefte' AND type = 'CATEGORY');
UPDATE "TaxonomyNodeTranslation" SET name = 'Heiße Getränke'
  WHERE language = 'de' AND "nodeId" IN (SELECT id FROM "TaxonomyNode" WHERE slug LIKE 'heisse-getraenke%' AND type = 'CATEGORY');
UPDATE "TaxonomyNodeTranslation" SET name = 'Edelbrände'
  WHERE language = 'de' AND "nodeId" IN (SELECT id FROM "TaxonomyNode" WHERE slug = 'edelbraende' AND type = 'CATEGORY');

-- ============================================
-- SCHRITT 2: CATEGORY Steuer-Hauptgruppen
-- ============================================

-- Tenant-ID dynamisch holen
DO $$
DECLARE
  tid TEXT;
  cat_food_id TEXT;
  cat_bev_id TEXT;
  cat_other_id TEXT;
BEGIN
  SELECT id INTO tid FROM "Tenant" LIMIT 1;

  -- Prüfen ob Hauptkategorien schon existieren
  IF NOT EXISTS (SELECT 1 FROM "TaxonomyNode" WHERE slug = 'lebensmittel' AND type = 'CATEGORY' AND "tenantId" = tid) THEN

    -- Hauptkategorie: Lebensmittel
    cat_food_id := 'tax-cat-lebensmittel';
    INSERT INTO "TaxonomyNode" (id, "tenantId", name, slug, type, "parentId", depth, "sortOrder", icon, "taxRate", "taxLabel")
    VALUES (cat_food_id, tid, 'Lebensmittel', 'lebensmittel', 'CATEGORY', NULL, 0, 0, 'lunch_dining', 0.10, 'Ermäßigt 10%');
    INSERT INTO "TaxonomyNodeTranslation" (id, "nodeId", language, name)
    VALUES ('tnt-food-de', cat_food_id, 'de', 'Lebensmittel'), ('tnt-food-en', cat_food_id, 'en', 'Food');

    -- Hauptkategorie: Alkoholische Getränke
    cat_bev_id := 'tax-cat-alk-getraenke';
    INSERT INTO "TaxonomyNode" (id, "tenantId", name, slug, type, "parentId", depth, "sortOrder", icon, "taxRate", "taxLabel")
    VALUES (cat_bev_id, tid, 'Alkoholische Getränke', 'alkoholische-getraenke', 'CATEGORY', NULL, 0, 1, 'liquor', 0.20, 'Normal 20%');
    INSERT INTO "TaxonomyNodeTranslation" (id, "nodeId", language, name)
    VALUES ('tnt-bev-de', cat_bev_id, 'de', 'Alkoholische Getränke'), ('tnt-bev-en', cat_bev_id, 'en', 'Alcoholic Beverages');

    -- Hauptkategorie: Sonstiges
    cat_other_id := 'tax-cat-sonstiges';
    INSERT INTO "TaxonomyNode" (id, "tenantId", name, slug, type, "parentId", depth, "sortOrder", icon)
    VALUES (cat_other_id, tid, 'Sonstiges', 'sonstiges', 'CATEGORY', NULL, 0, 2, 'more_horiz');
    INSERT INTO "TaxonomyNodeTranslation" (id, "nodeId", language, name)
    VALUES ('tnt-other-de', cat_other_id, 'de', 'Sonstiges'), ('tnt-other-en', cat_other_id, 'en', 'Other');

    -- Bestehende Kategorien umhängen unter Lebensmittel
    UPDATE "TaxonomyNode" SET "parentId" = cat_food_id, depth = 1
      WHERE slug = 'speisen' AND type = 'CATEGORY' AND "tenantId" = tid;
    UPDATE "TaxonomyNode" SET "parentId" = cat_food_id, depth = 1
      WHERE slug = 'alkoholfrei' AND type = 'CATEGORY' AND "tenantId" = tid;
    -- "Heisse Getränke" -> Lebensmittel (Kaffee/Tee = ermäßigt)
    UPDATE "TaxonomyNode" SET "parentId" = cat_food_id, depth = 1
      WHERE slug LIKE 'heisse-getraenke%' AND type = 'CATEGORY' AND "tenantId" = tid;

    -- Bestehende Kategorien umhängen unter Alkoholische Getränke
    UPDATE "TaxonomyNode" SET "parentId" = cat_bev_id, depth = 1
      WHERE slug = 'wein' AND type = 'CATEGORY' AND "tenantId" = tid;
    UPDATE "TaxonomyNode" SET "parentId" = cat_bev_id, depth = 1
      WHERE slug = 'cocktails' AND type = 'CATEGORY' AND "tenantId" = tid;
    UPDATE "TaxonomyNode" SET "parentId" = cat_bev_id, depth = 1
      WHERE slug = 'spirituosen' AND type = 'CATEGORY' AND "tenantId" = tid;
    UPDATE "TaxonomyNode" SET "parentId" = cat_bev_id, depth = 1
      WHERE slug = 'bier' AND type = 'CATEGORY' AND "tenantId" = tid;

    -- Unterkategorien depth auf 2 setzen (Kinder der umgehängten Nodes)
    UPDATE "TaxonomyNode" SET depth = 2
      WHERE "parentId" IN (
        SELECT id FROM "TaxonomyNode"
        WHERE type = 'CATEGORY' AND depth = 1 AND "tenantId" = tid
      ) AND "tenantId" = tid;

  END IF;
END $$;

-- ============================================
-- SCHRITT 3: GRAPE Rebsorten-Gruppen
-- ============================================

DO $$
DECLARE
  tid TEXT;
  grp_weiss_id TEXT;
  grp_rot_id TEXT;
  grp_cuvee_id TEXT;
BEGIN
  SELECT id INTO tid FROM "Tenant" LIMIT 1;

  IF NOT EXISTS (SELECT 1 FROM "TaxonomyNode" WHERE slug = 'weissweinreben' AND type = 'GRAPE' AND "tenantId" = tid) THEN

    -- Gruppe: Weissweinreben
    grp_weiss_id := 'tax-grape-weiss';
    INSERT INTO "TaxonomyNode" (id, "tenantId", name, slug, type, "parentId", depth, "sortOrder", icon)
    VALUES (grp_weiss_id, tid, 'Weissweinreben', 'weissweinreben', 'GRAPE', NULL, 0, 0, 'brightness_high');
    INSERT INTO "TaxonomyNodeTranslation" (id, "nodeId", language, name)
    VALUES ('tnt-gw-de', grp_weiss_id, 'de', 'Weissweinreben'), ('tnt-gw-en', grp_weiss_id, 'en', 'White Grape Varieties');

    -- Gruppe: Rotweinreben
    grp_rot_id := 'tax-grape-rot';
    INSERT INTO "TaxonomyNode" (id, "tenantId", name, slug, type, "parentId", depth, "sortOrder", icon)
    VALUES (grp_rot_id, tid, 'Rotweinreben', 'rotweinreben', 'GRAPE', NULL, 0, 1, 'brightness_low');
    INSERT INTO "TaxonomyNodeTranslation" (id, "nodeId", language, name)
    VALUES ('tnt-gr-de', grp_rot_id, 'de', 'Rotweinreben'), ('tnt-gr-en', grp_rot_id, 'en', 'Red Grape Varieties');

    -- Gruppe: Cuvée / Verschnitt
    grp_cuvee_id := 'tax-grape-cuvee';
    INSERT INTO "TaxonomyNode" (id, "tenantId", name, slug, type, "parentId", depth, "sortOrder", icon)
    VALUES (grp_cuvee_id, tid, 'Cuvée / Verschnitt', 'cuvee-verschnitt', 'GRAPE', NULL, 0, 2, 'join');
    INSERT INTO "TaxonomyNodeTranslation" (id, "nodeId", language, name)
    VALUES ('tnt-gc-de', grp_cuvee_id, 'de', 'Cuvée / Verschnitt'), ('tnt-gc-en', grp_cuvee_id, 'en', 'Blends / Cuvée');

    -- Weisse Rebsorten umhängen
    UPDATE "TaxonomyNode" SET "parentId" = grp_weiss_id, depth = 1
      WHERE slug IN ('gruener-veltliner', 'riesling', 'sauvignon-blanc', 'chardonnay', 'muskateller', 'pinot-blanc', 'welschriesling')
      AND type = 'GRAPE' AND "tenantId" = tid;

    -- Rote Rebsorten umhängen
    UPDATE "TaxonomyNode" SET "parentId" = grp_rot_id, depth = 1
      WHERE slug IN ('zweigelt', 'blaufraenkisch', 'st-laurent', 'pinot-noir', 'cabernet-sauvignon', 'merlot')
      AND type = 'GRAPE' AND "tenantId" = tid;

  END IF;
END $$;

-- ============================================
-- SCHRITT 4: REGION vervollständigen
-- ============================================

DO $$
DECLARE
  tid TEXT;
  id_de TEXT;
  id_pt TEXT;
BEGIN
  SELECT id INTO tid FROM "Tenant" LIMIT 1;

  -- Deutschland hinzufügen (falls nicht vorhanden)
  IF NOT EXISTS (SELECT 1 FROM "TaxonomyNode" WHERE slug = 'deutschland' AND type = 'REGION' AND "tenantId" = tid) THEN
    id_de := 'tax-reg-deutschland';
    INSERT INTO "TaxonomyNode" (id, "tenantId", name, slug, type, "parentId", depth, "sortOrder", icon)
    VALUES (id_de, tid, 'Deutschland', 'deutschland', 'REGION', NULL, 0, 4, 'flag');
    INSERT INTO "TaxonomyNodeTranslation" (id, "nodeId", language, name)
    VALUES ('tnt-rde-de', id_de, 'de', 'Deutschland'), ('tnt-rde-en', id_de, 'en', 'Germany');

    -- Deutsche Weinregionen
    INSERT INTO "TaxonomyNode" (id, "tenantId", name, slug, type, "parentId", depth, "sortOrder")
    VALUES ('tax-reg-mosel', tid, 'Mosel', 'mosel', 'REGION', id_de, 1, 0);
    INSERT INTO "TaxonomyNodeTranslation" (id, "nodeId", language, name)
    VALUES ('tnt-mosel-de', 'tax-reg-mosel', 'de', 'Mosel'), ('tnt-mosel-en', 'tax-reg-mosel', 'en', 'Moselle');

    INSERT INTO "TaxonomyNode" (id, "tenantId", name, slug, type, "parentId", depth, "sortOrder")
    VALUES ('tax-reg-rheingau', tid, 'Rheingau', 'rheingau', 'REGION', id_de, 1, 1);
    INSERT INTO "TaxonomyNodeTranslation" (id, "nodeId", language, name)
    VALUES ('tnt-rheingau-de', 'tax-reg-rheingau', 'de', 'Rheingau'), ('tnt-rheingau-en', 'tax-reg-rheingau', 'en', 'Rheingau');

    INSERT INTO "TaxonomyNode" (id, "tenantId", name, slug, type, "parentId", depth, "sortOrder")
    VALUES ('tax-reg-pfalz', tid, 'Pfalz', 'pfalz', 'REGION', id_de, 1, 2);
    INSERT INTO "TaxonomyNodeTranslation" (id, "nodeId", language, name)
    VALUES ('tnt-pfalz-de', 'tax-reg-pfalz', 'de', 'Pfalz'), ('tnt-pfalz-en', 'tax-reg-pfalz', 'en', 'Palatinate');
  END IF;

  -- Portugal hinzufügen
  IF NOT EXISTS (SELECT 1 FROM "TaxonomyNode" WHERE slug = 'portugal' AND type = 'REGION' AND "tenantId" = tid) THEN
    id_pt := 'tax-reg-portugal';
    INSERT INTO "TaxonomyNode" (id, "tenantId", name, slug, type, "parentId", depth, "sortOrder", icon)
    VALUES (id_pt, tid, 'Portugal', 'portugal', 'REGION', NULL, 0, 5, 'flag');
    INSERT INTO "TaxonomyNodeTranslation" (id, "nodeId", language, name)
    VALUES ('tnt-rpt-de', id_pt, 'de', 'Portugal'), ('tnt-rpt-en', id_pt, 'en', 'Portugal');

    INSERT INTO "TaxonomyNode" (id, "tenantId", name, slug, type, "parentId", depth, "sortOrder")
    VALUES ('tax-reg-douro', tid, 'Douro', 'douro', 'REGION', id_pt, 1, 0);
    INSERT INTO "TaxonomyNodeTranslation" (id, "nodeId", language, name)
    VALUES ('tnt-douro-de', 'tax-reg-douro', 'de', 'Douro'), ('tnt-douro-en', 'tax-reg-douro', 'en', 'Douro');
  END IF;

  -- Fehlende österreichische Subregionen
  IF NOT EXISTS (SELECT 1 FROM "TaxonomyNode" WHERE slug = 'leithaberg' AND type = 'REGION' AND "tenantId" = tid) THEN
    INSERT INTO "TaxonomyNode" (id, "tenantId", name, slug, type, "parentId", depth, "sortOrder")
    VALUES ('tax-reg-leithaberg', tid, 'Leithaberg', 'leithaberg', 'REGION',
      (SELECT id FROM "TaxonomyNode" WHERE slug = 'burgenland' AND type = 'REGION' AND "tenantId" = tid), 2, 2);
    INSERT INTO "TaxonomyNodeTranslation" (id, "nodeId", language, name)
    VALUES ('tnt-leitha-de', 'tax-reg-leithaberg', 'de', 'Leithaberg'), ('tnt-leitha-en', 'tax-reg-leithaberg', 'en', 'Leithaberg');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM "TaxonomyNode" WHERE slug = 'vulkanland' AND type = 'REGION' AND "tenantId" = tid) THEN
    INSERT INTO "TaxonomyNode" (id, "tenantId", name, slug, type, "parentId", depth, "sortOrder")
    VALUES ('tax-reg-vulkanland', tid, 'Vulkanland', 'vulkanland', 'REGION',
      (SELECT id FROM "TaxonomyNode" WHERE slug = 'steiermark' AND type = 'REGION' AND "tenantId" = tid), 2, 1);
    INSERT INTO "TaxonomyNodeTranslation" (id, "nodeId", language, name)
    VALUES ('tnt-vulkan-de', 'tax-reg-vulkanland', 'de', 'Vulkanland'), ('tnt-vulkan-en', 'tax-reg-vulkanland', 'en', 'Vulkanland');
  END IF;

END $$;

-- ============================================
-- SCHRITT 5: Zusätzliche STYLE-Einträge
-- ============================================

DO $$
DECLARE
  tid TEXT;
BEGIN
  SELECT id INTO tid FROM "Tenant" LIMIT 1;

  IF NOT EXISTS (SELECT 1 FROM "TaxonomyNode" WHERE slug = 'edelsüß' AND type = 'STYLE' AND "tenantId" = tid)
     AND NOT EXISTS (SELECT 1 FROM "TaxonomyNode" WHERE slug = 'edelsues' AND type = 'STYLE' AND "tenantId" = tid) THEN
    INSERT INTO "TaxonomyNode" (id, "tenantId", name, slug, type, depth, "sortOrder")
    VALUES ('tax-style-edel', tid, 'Edelsüß', 'edelsues', 'STYLE', 0, 5);
    INSERT INTO "TaxonomyNodeTranslation" (id, "nodeId", language, name)
    VALUES ('tnt-edel-de', 'tax-style-edel', 'de', 'Edelsüß'), ('tnt-edel-en', 'tax-style-edel', 'en', 'Noble Sweet');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM "TaxonomyNode" WHERE slug = 'naturwein' AND type = 'STYLE' AND "tenantId" = tid) THEN
    INSERT INTO "TaxonomyNode" (id, "tenantId", name, slug, type, depth, "sortOrder")
    VALUES ('tax-style-natur', tid, 'Naturwein', 'naturwein', 'STYLE', 0, 6);
    INSERT INTO "TaxonomyNodeTranslation" (id, "nodeId", language, name)
    VALUES ('tnt-natur-de', 'tax-style-natur', 'de', 'Naturwein'), ('tnt-natur-en', 'tax-style-natur', 'en', 'Natural Wine');
  END IF;
END $$;

-- ============================================
-- VERIFIKATION
-- ============================================
SELECT type, depth, name, slug, "parentId" IS NOT NULL AS has_parent
FROM "TaxonomyNode"
ORDER BY type, depth, "sortOrder"
LIMIT 80;
