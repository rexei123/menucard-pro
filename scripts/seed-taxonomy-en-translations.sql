-- Seed fehlende EN-Uebersetzungen fuer TaxonomyNode
-- Deckt die gaengigen deutschen Kategorien/Regionen/Rebsorten ab.
-- Fuer Knoten ohne bekannte Zuordnung wird der DE-Name uebernommen.

BEGIN;

-- Temporaere Mapping-Tabelle DE -> EN
CREATE TEMP TABLE tx_map (de TEXT, en TEXT);
INSERT INTO tx_map VALUES
-- Kategorien Speisen
  ('Lebensmittel', 'Food'),
  ('Speisen', 'Dishes'),
  ('Vorspeisen', 'Starters'),
  ('Suppen', 'Soups'),
  ('Hauptgerichte', 'Main Courses'),
  ('Hauptspeisen', 'Main Courses'),
  ('Desserts', 'Desserts'),
  ('Nachspeisen', 'Desserts'),
  ('Beilagen', 'Side Dishes'),
  ('Salate', 'Salads'),
  ('Kaese & Obst', 'Cheese & Fruit'),
  ('Käse & Obst', 'Cheese & Fruit'),
  ('Kinder', 'Children'),
  ('Frühstück', 'Breakfast'),
  ('Fruehstueck', 'Breakfast'),
  ('Mittagskarte', 'Lunch'),
  ('Abendkarte', 'Dinner'),
  ('Tageskarte', 'Daily Menu'),
-- Getränkekategorien
  ('Alkoholische Getränke', 'Alcoholic Beverages'),
  ('Alkoholische Getraenke', 'Alcoholic Beverages'),
  ('Wein', 'Wine'),
  ('Weisswein', 'White Wine'),
  ('Weißwein', 'White Wine'),
  ('Rotwein', 'Red Wine'),
  ('Rosewein', 'Rose Wine'),
  ('Roséwein', 'Rose Wine'),
  ('Schaumwein', 'Sparkling Wine'),
  ('Sekt', 'Sparkling Wine'),
  ('Champagner', 'Champagne'),
  ('Dessertwein', 'Dessert Wine'),
  ('Suesswein', 'Sweet Wine'),
  ('Cocktails', 'Cocktails'),
  ('Klassiker', 'Classics'),
  ('Signature', 'Signature'),
  ('Spirituosen', 'Spirits'),
  ('Gin', 'Gin'),
  ('Whisky', 'Whisky'),
  ('Rum', 'Rum'),
  ('Wodka', 'Vodka'),
  ('Tequila', 'Tequila'),
  ('Edelbrände', 'Schnapps'),
  ('Edelbraende', 'Schnapps'),
  ('Likoer', 'Liqueur'),
  ('Likör', 'Liqueur'),
  ('Bier', 'Beer'),
  ('Fassbier', 'Draft Beer'),
  ('Flaschenbier', 'Bottled Beer'),
  ('Alkoholfrei', 'Non-Alcoholic'),
  ('Softdrinks', 'Soft Drinks'),
  ('Limonaden', 'Lemonades'),
  ('Säfte', 'Juices'),
  ('Saefte', 'Juices'),
  ('Wasser', 'Water'),
  ('Heiße Getränke', 'Hot Beverages'),
  ('Heisse Getraenke', 'Hot Beverages'),
  ('Kaffee', 'Coffee'),
  ('Tee', 'Tea'),
  ('Sonstiges', 'Other'),
-- Weinregionen / Länder
  ('Österreich', 'Austria'),
  ('Oesterreich', 'Austria'),
  ('Deutschland', 'Germany'),
  ('Frankreich', 'France'),
  ('Italien', 'Italy'),
  ('Spanien', 'Spain'),
  ('Portugal', 'Portugal'),
  ('Schweiz', 'Switzerland'),
  ('Ungarn', 'Hungary'),
  ('USA', 'USA'),
  ('Argentinien', 'Argentina'),
  ('Chile', 'Chile'),
  ('Australien', 'Australia'),
  ('Neuseeland', 'New Zealand'),
  ('Südafrika', 'South Africa'),
  ('Suedafrika', 'South Africa'),
  ('Niederösterreich', 'Lower Austria'),
  ('Niederoesterreich', 'Lower Austria'),
  ('Burgenland', 'Burgenland'),
  ('Steiermark', 'Styria'),
  ('Südtirol', 'South Tyrol'),
  ('Suedtirol', 'South Tyrol'),
  ('Wachau', 'Wachau'),
  ('Kamptal', 'Kamptal'),
  ('Kremstal', 'Kremstal'),
  ('Traisental', 'Traisental'),
  ('Mittelburgenland', 'Central Burgenland'),
  ('Neusiedlersee', 'Neusiedlersee'),
  ('Leithaberg', 'Leithaberg'),
  ('Südsteiermark', 'Southern Styria'),
  ('Suedsteiermark', 'Southern Styria'),
  ('Vulkanland', 'Volcanic Region'),
  ('Mosel', 'Mosel'),
  ('Rheingau', 'Rheingau'),
  ('Pfalz', 'Palatinate'),
  ('Douro', 'Douro'),
-- Rebsorten
  ('Weissweinreben', 'White Grape Varieties'),
  ('Weißweinreben', 'White Grape Varieties'),
  ('Rotweinreben', 'Red Grape Varieties'),
  ('Grüner Veltliner', 'Gruner Veltliner'),
  ('Gruener Veltliner', 'Gruner Veltliner'),
  ('Riesling', 'Riesling'),
  ('Sauvignon Blanc', 'Sauvignon Blanc'),
  ('Chardonnay', 'Chardonnay'),
  ('Muskateller', 'Muscat'),
  ('Welschriesling', 'Welschriesling'),
  ('Weißburgunder', 'Pinot Blanc'),
  ('Grauburgunder', 'Pinot Gris'),
  ('Blaufränkisch', 'Blaufrankisch'),
  ('Blaufraenkisch', 'Blaufrankisch'),
  ('Zweigelt', 'Zweigelt'),
  ('Pinot Noir', 'Pinot Noir'),
  ('Blauburgunder', 'Pinot Noir'),
  ('St. Laurent', 'St. Laurent'),
  ('Merlot', 'Merlot'),
  ('Cabernet Sauvignon', 'Cabernet Sauvignon'),
  ('Syrah', 'Syrah'),
  ('Shiraz', 'Shiraz'),
  ('Cuvée', 'Cuvee'),
  ('Cuvee', 'Cuvee'),
  ('Verschnitt', 'Blend'),
-- Stile / Diät / Herkunft kulinarisch
  ('Österreichisch', 'Austrian'),
  ('Oesterreichisch', 'Austrian'),
  ('Italienisch', 'Italian'),
  ('Französisch', 'French'),
  ('Franzoesisch', 'French'),
  ('Mediterran', 'Mediterranean'),
  ('Asiatisch', 'Asian'),
  ('International', 'International'),
  ('Vegetarisch', 'Vegetarian'),
  ('Vegan', 'Vegan'),
  ('Glutenfrei', 'Gluten-free'),
  ('Laktosefrei', 'Lactose-free'),
  ('Bio', 'Organic')
;

-- 1. Fehlende EN-Uebersetzungen einfuegen, wenn DE-Mapping gefunden wurde
INSERT INTO "TaxonomyNodeTranslation" (id, "nodeId", language, name)
SELECT
  'tt_' || substr(md5(random()::text || n.id || 'en'), 1, 20),
  n.id,
  'en',
  COALESCE(m.en, de_tr.name)
FROM "TaxonomyNode" n
LEFT JOIN "TaxonomyNodeTranslation" de_tr ON de_tr."nodeId" = n.id AND de_tr.language = 'de'
LEFT JOIN tx_map m ON m.de = de_tr.name
WHERE NOT EXISTS (
  SELECT 1 FROM "TaxonomyNodeTranslation" t WHERE t."nodeId" = n.id AND t.language = 'en'
);

-- 2. Knoten ohne DE-Uebersetzung ueberhaupt anlegen (name = nodeId als Notfall)
INSERT INTO "TaxonomyNodeTranslation" (id, "nodeId", language, name)
SELECT
  'tt_' || substr(md5(random()::text || n.id || 'de'), 1, 20),
  n.id,
  'de',
  COALESCE(n.slug, n.id)
FROM "TaxonomyNode" n
WHERE NOT EXISTS (
  SELECT 1 FROM "TaxonomyNodeTranslation" t WHERE t."nodeId" = n.id AND t.language = 'de'
);

-- Verifikation
SELECT
  n.type,
  n.slug,
  MAX(CASE WHEN t.language = 'de' THEN t.name END) AS de,
  MAX(CASE WHEN t.language = 'en' THEN t.name END) AS en
FROM "TaxonomyNode" n
LEFT JOIN "TaxonomyNodeTranslation" t ON t."nodeId" = n.id
GROUP BY n.id, n.type, n.slug
ORDER BY n.type, n.slug;

COMMIT;
