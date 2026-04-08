-- =====================================================
-- MenuCard Pro - Umlaut Fix
-- Run: psql <connstring> -f fix-umlauts.sql
-- =====================================================

-- Global replace function for all text columns
-- Covers: ue->ü, oe->ö, ae->ä, ss->ß (context-safe patterns)

-- === WineProfile ===
UPDATE "WineProfile" SET country = REPLACE(country, 'Oesterreich', 'Österreich') WHERE country LIKE '%Oesterreich%';
UPDATE "WineProfile" SET region = REPLACE(region, 'Niederoesterreich', 'Niederösterreich') WHERE region LIKE '%Niederoesterreich%';
UPDATE "WineProfile" SET appellation = REPLACE(appellation, 'Oesterreichischer', 'Österreichischer') WHERE appellation LIKE '%Oesterreichischer%';
UPDATE "WineProfile" SET appellation = REPLACE(appellation, 'Niederoesterreich', 'Niederösterreich') WHERE appellation LIKE '%Niederoesterreich%';
UPDATE "WineProfile" SET "grapeVarieties" = array_replace("grapeVarieties", 'Blaufraenkisch', 'Blaufränkisch') WHERE 'Blaufraenkisch' = ANY("grapeVarieties");
UPDATE "WineProfile" SET "grapeVarieties" = array_replace("grapeVarieties", 'Gewuerztraminer', 'Gewürztraminer') WHERE 'Gewuerztraminer' = ANY("grapeVarieties");
UPDATE "WineProfile" SET "grapeVarieties" = array_replace("grapeVarieties", 'Gruener Veltliner', 'Grüner Veltliner') WHERE 'Gruener Veltliner' = ANY("grapeVarieties");

-- === MenuItemTranslation: name ===
UPDATE "MenuItemTranslation" SET name = REPLACE(name, 'Gruener Veltliner', 'Grüner Veltliner') WHERE name LIKE '%Gruener Veltliner%';
UPDATE "MenuItemTranslation" SET name = REPLACE(name, 'Spaetlese', 'Spätlese') WHERE name LIKE '%Spaetlese%';
UPDATE "MenuItemTranslation" SET name = REPLACE(name, 'Soehnlein', 'Söhnlein') WHERE name LIKE '%Soehnlein%';
UPDATE "MenuItemTranslation" SET name = REPLACE(name, 'Marillenlikoer', 'Marillenlikör') WHERE name LIKE '%Marillenlikoer%';
UPDATE "MenuItemTranslation" SET name = REPLACE(name, 'Schoko-Minze Likoer', 'Schoko-Minze Likör') WHERE name LIKE '%Schoko-Minze Likoer%';
UPDATE "MenuItemTranslation" SET name = REPLACE(name, 'Kraeuterlimonade', 'Kräuterlimonade') WHERE name LIKE '%Kraeuterlimonade%';
UPDATE "MenuItemTranslation" SET name = REPLACE(name, 'Naturtrueb', 'Naturtrüb') WHERE name LIKE '%Naturtrueb%';
UPDATE "MenuItemTranslation" SET name = REPLACE(name, 'Verlaengerter', 'Verlängerter') WHERE name LIKE '%Verlaengerter%';
UPDATE "MenuItemTranslation" SET name = REPLACE(name, 'Gluehwein', 'Glühwein') WHERE name LIKE '%Gluehwein%';
UPDATE "MenuItemTranslation" SET name = REPLACE(name, 'Heisse Schokolade', 'Heiße Schokolade') WHERE name LIKE '%Heisse Schokolade%';
UPDATE "MenuItemTranslation" SET name = REPLACE(name, 'Saefte', 'Säfte') WHERE name LIKE '%Saefte%';
UPDATE "MenuItemTranslation" SET name = REPLACE(name, 'Oelberg', 'Ölberg') WHERE name LIKE '%Oelberg%';
UPDATE "MenuItemTranslation" SET name = 'Rosé vom Muschelkalk' WHERE name = 'Rose vom Muschelkalk';
UPDATE "MenuItemTranslation" SET name = REPLACE(name, 'Likoer', 'Likör') WHERE name LIKE '%Likoer%' AND name NOT LIKE '%Likör%';

-- === MenuItemTranslation: shortDescription ===
UPDATE "MenuItemTranslation" SET "shortDescription" = REPLACE("shortDescription", 'Oesterreich', 'Österreich') WHERE "shortDescription" LIKE '%Oesterreich%';
UPDATE "MenuItemTranslation" SET "shortDescription" = REPLACE("shortDescription", 'Goettlesbrunn', 'Göttlesbrunn') WHERE "shortDescription" LIKE '%Goettlesbrunn%';
UPDATE "MenuItemTranslation" SET "shortDescription" = REPLACE("shortDescription", 'suess', 'süß') WHERE "shortDescription" LIKE '%suess%';
UPDATE "MenuItemTranslation" SET "shortDescription" = REPLACE("shortDescription", 'Niederrussbach', 'Niederrußbach') WHERE "shortDescription" LIKE '%Niederrussbach%';
UPDATE "MenuItemTranslation" SET "shortDescription" = REPLACE("shortDescription", 'Heisse', 'Heiße') WHERE "shortDescription" LIKE '%Heisse%';
UPDATE "MenuItemTranslation" SET "shortDescription" = REPLACE("shortDescription", 'Weisser Rum', 'Weißer Rum') WHERE "shortDescription" LIKE '%Weisser Rum%';
UPDATE "MenuItemTranslation" SET "shortDescription" = REPLACE("shortDescription", 'Wuerfelzucker', 'Würfelzucker') WHERE "shortDescription" LIKE '%Wuerfelzucker%';
UPDATE "MenuItemTranslation" SET "shortDescription" = REPLACE("shortDescription", 'Pfirsichlikoer', 'Pfirsichlikör') WHERE "shortDescription" LIKE '%Pfirsichlikoer%';
UPDATE "MenuItemTranslation" SET "shortDescription" = REPLACE("shortDescription", 'Likoer', 'Likör') WHERE "shortDescription" LIKE '%Likoer%' AND "shortDescription" NOT LIKE '%Likör%';

-- === MenuItemTranslation: longDescription (bulk via generic patterns) ===
DO $$
DECLARE
  replacements TEXT[][] := ARRAY[
    ['ueberragt','überragt'],['suesse','süße'],['Suess','Süß'],['suess','süß'],
    ['wuerzigen','würzigen'],['Wuerze','Würze'],['wuerzig','würzig'],
    ['Kraeuterwuerze','Kräuterwürze'],['Kraeuterwuerzig','Kräuterwürzig'],
    ['Gewuerze','Gewürze'],['Gewuerzen','Gewürzen'],
    ['Fruechte','Früchte'],['Fruechten','Früchten'],
    ['Komplexitaet','Komplexität'],['praesente','präsente'],['praesentes','präsentes'],
    ['Saeurestruktur','Säurestruktur'],['Saeure','Säure'],
    ['Laenge','Länge'],['Roestaromen','Röstaromen'],
    ['Kraeftige','Kräftige'],['Kraeftig','Kräftig'],
    ['Doerrobst','Dörrobst'],['Nuesse','Nüsse'],
    ['Bluetenhonig','Blütenhonig'],['fruchtig-suess','fruchtig-süß'],
    ['aetherisch','ätherisch'],['Aetherisch','Ätherisch'],
    ['Zerdrueckte','Zerdrückte'],['zerdrueckte','zerdrückte'],
    ['Holzwuerze','Holzwürze'],['Edelholzwuerze','Edelholzwürze'],
    ['Tabakwuerze','Tabakwürze'],
    ['Haselnuss','Haselnuß'],['wunderschoene','wunderschöne'],
    ['Extraktsuesse','Extraktsüße'],['Rueckgeschmack','Rückgeschmack'],
    ['zugaenglich','zugänglich'],['kraeftig','kräftig'],
    ['Orangenzesten','Orangenzesten'],
    ['Zwetschken','Zwetschken'],['ueberragt','überragt'],
    ['Koerper','Körper'],['Flaschengroesse','Flaschengröße'],
    ['Groesse','Größe']
  ];
  r TEXT[];
BEGIN
  FOREACH r SLICE 1 IN ARRAY replacements LOOP
    EXECUTE format(
      'UPDATE "MenuItemTranslation" SET "longDescription" = REPLACE("longDescription", %L, %L) WHERE "longDescription" LIKE %L',
      r[1], r[2], '%' || r[1] || '%'
    );
  END LOOP;
  RAISE NOTICE 'longDescription umlauts fixed';
END $$;

-- === MenuSectionTranslation ===
UPDATE "MenuSectionTranslation" SET name = 'Heißgetränke' WHERE name = 'Heissgetraenke';
UPDATE "MenuSectionTranslation" SET name = 'Alkoholfreie Getränke' WHERE name = 'Alkoholfreie Getraenke';
UPDATE "MenuSectionTranslation" SET name = 'Rotwein Cuvées & Merlot' WHERE name = 'Rotwein Cuvees & Merlot';
UPDATE "MenuSectionTranslation" SET name = 'Destillate, Grappa & Likör' WHERE name = 'Destillate, Grappa & Likoer';
UPDATE "MenuSectionTranslation" SET name = 'Bitter & Likör' WHERE name = 'Bitter & Likoer';
UPDATE "MenuSectionTranslation" SET name = 'Likörwein / Portwein' WHERE name = 'Likoerwein / Portwein';
UPDATE "MenuSectionTranslation" SET description = REPLACE(description, 'Oesterreich', 'Österreich') WHERE description LIKE '%Oesterreich%';

-- Verify
SELECT 'Done! Checking remaining issues...' AS status;
SELECT COUNT(*) AS remaining_oe FROM "MenuItemTranslation" WHERE name || COALESCE("shortDescription",'') || COALESCE("longDescription",'') ~ '(ue|oe|ae)(rr|ch|ss|nd|ng|ll|tt|ck|nk|rg|rd|rl|rn|rt|rb|lz|nz|tz|st|hl|hr|mm|nn|pf|ld|lb|lf|rm|rk|rp|rv|rz|ft|ht|lt|nt|pt)';
