# Design-Editor v2 — Sprint 0: Schema-Inventar

**Branch:** `feature/design-editor-v2` · **Stand:** 20.04.2026 · **Verantwortlich:** Claude (autonom bis Gate 1)
**Scope:** Inventar der 8 Komponenten aus Roadmap §Phase 1, Vergleich Config ↔ tatsächliches Rendering.

---

## Quellen (Ist-Stand)

| Schicht | Datei | Bemerkung |
|---|---|---|
| Config-Typen | `src/lib/design-templates/index.ts` | `DesignConfig = { digital, analog }`, Feldstruktur |
| SYSTEM-Defaults | `src/lib/design-templates/{minimal,elegant,modern,classic}.ts` | minimal = einziges aktives SYSTEM (seit 20.04.2026) |
| Admin-Editor | `src/components/admin/design-editor.tsx` | 1091 Z., 7 Digital-Tabs + PDF-Tab |
| Gäste-Orchestrator | `src/components/menu-content.tsx` | Template-Routing + Elegant/Default-Renderer inline |
| Gäste-Komponenten | `src/components/templates/{minimal,modern,classic}-renderer.tsx` | jeweils eigenständige Komponenten |
| Gäste-Page | `src/app/(public)/[tenant]/[location]/[menu]/page.tsx` | Header-Render mit Logo/Titel/Subtitle |

---

## Drift-Befund (entscheidend für Schema-Approach)

Die Templates zeigen drei Rendering-Pfade, von "schema-driven" bis "hartverdrahtet":

| Renderer | CSS-Variablen | Inline-Hardcode | Konsequenz |
|---|---|---|---|
| **menu-content: `renderDefaultItem/Section`** | ja (`var(--mc-h2-font)`, `var(--mc-price-color)` …) | keine Farben | vollständig config-driven, Ziel-Pattern |
| **menu-content: `renderElegantItem/Section`** | ja (`var(--mc-h3-color)`, `var(--mc-price-font)` …) | nur `letterSpacing: '0.03em'` | weitgehend config-driven |
| **minimal-renderer.tsx** | nein | `fontFamily: "'Montserrat', sans-serif"`, `#171A1F`, `#DD3C71` | **ignoriert Config komplett** |
| **modern-renderer.tsx** | teilweise (`--mc-h2-color`, `--mc-section-line`) | `fontFamily: "'Montserrat'"`, `#171A1F`, `#DD3C71`, `#565D6D` | zum Teil ignoriert |
| **classic-renderer.tsx** | nein | `fontFamily: "'Playfair Display'"`, `#171A1F`, `#DD3C71`, `#DEE1E6`, `#FDFBF7` | **ignoriert Config komplett** |

**Implikation für Phase 1:** Neue Schemas greifen erst, wenn die Renderer durchgehend über CSS-Variablen laufen. `renderDefaultItem/Section` ist das Referenz-Pattern. Ab Phase 1 wird jeder neue Renderer (insbesondere der schema-basierte Minimal-Renderer) nur noch über CSS-Variablen angebunden. Altlasten-Renderer werden nicht refaktoriert (Elegant/Modern/Classic sind archiviert).

**Begleitregel:** Die neu aufgebauten Components konsumieren CSS-Variablen mit Namespace `--mc-*`. Der Template-Wrapper `mc-template-root mc-template-{key}` muss diese injizieren (bereits heute durch `menu-font.css` und das Template-Wrapper-Layout).

---

## Schema-Feldtypen (Phase-1-Katalog)

| Typ | Beispiel | Validation |
|---|---|---|
| `boolean` | `products.showImages` | true/false |
| `select` | `navigation.tocStyle` | aus fester Options-Liste |
| `color` | `colors.accentPrimary` | HEX `#RRGGBB` oder `#RRGGBBAA` |
| `number` | `header.logoSize` | min/max, unit optional |
| `text` | `header.subtitle` | maxLength |
| `font` | `typography.h1.font` | aus `FONTS`-Whitelist (10 Schriften) |
| `slider` | `colors.sectionLineWidth` | number mit explizitem min/max/step |

Feldtyp-Konvention für Schema-Definitionen:
```ts
type FieldDef =
  | { type: 'boolean'; label: string; default: boolean; desc?: string }
  | { type: 'select'; label: string; options: { label: string; value: string }[]; default: string; desc?: string }
  | { type: 'color'; label: string; default: string; desc?: string }
  | { type: 'number'; label: string; min: number; max: number; unit?: string; default: number; desc?: string }
  | { type: 'slider'; label: string; min: number; max: number; step?: number; unit?: string; default: number; desc?: string }
  | { type: 'text'; label: string; default: string; maxLength?: number; placeholder?: string; desc?: string }
  | { type: 'font'; label: string; default: string; desc?: string };
```

Gruppierung: `ComponentSchema = { name: string; label: string; groups: { id: string; label: string; fields: Record<string, FieldDef> }[] }`

---

## Komponenten-Inventar

### 1 · Hero (Menu-Header)

**Render-Ort:** `src/app/(public)/[tenant]/[location]/[menu]/page.tsx` (Z. 128, 129, 217, 227–253)

**Config-Pfad:** `digital.header.*`

| Feld | Typ | Default (global) | Bisheriger Editor-Pfad | Drift? |
|---|---|---|---|---|
| `logo` | `text` (URL, optional) | `null` | nur via Seitenaufruf | nicht im Editor |
| `logoPosition` | `select` left/center/right | `'center'` | TabRahmen | ok |
| `logoSize` | `slider` 40–240 px | `120` | TabRahmen | ok |
| `title` | `text` (nullable) | `null` → Kartenname | TabRahmen | ok |
| `subtitle` | `text` | `''` | TabRahmen | ok |
| `height` | `select` small/normal/large | `'normal'` | TabRahmen | ok |
| `backgroundImage` | `text` (URL) | `null` | **fehlt im Editor** | noch nicht editierbar |
| `overlayOpacity` | `slider` 0–100 % | `0.6` | TabRahmen | ok |
| `layout` *(neu)* | `select` centered/left/split | n/a | entsteht in Phase 1 | neu |

**Minimum-Slots für Inline-Edit (Phase 2):** `title`, `subtitle`, `logo` (Upload-Aktion), `backgroundImage`.

---

### 2 · SectionHeader

**Render-Orte:**
- `menu-content.renderDefaultSection` (Z. 412–428)
- `menu-content.renderElegantSection` (Z. 324–341)
- `modern-renderer.ModernSection` (Z. 153–185, teilweise hartverdrahtet)
- `classic-renderer.ClassicSection` (Z. 206–272, komplett hartverdrahtet — dekorative Linien, Icon, untere Akzentlinie)

**Config-Pfad:** `digital.colors.sectionHeaderBg`, `digital.colors.sectionLine`, `digital.colors.sectionLineWidth`, `digital.colors.sectionLineStyle`, `digital.typography.h2.*`

| Feld | Typ | Default (minimal) | Drift? |
|---|---|---|---|
| `headerBg` | `color` | `transparent` | ok |
| `lineColor` | `color` | `#EBEBEB` | ok |
| `lineWidth` | `slider` 0–5 px | `1` | ok |
| `lineStyle` | `select` solid/dashed/double/none | `'solid'` | ok |
| `align` *(neu)* | `select` left/center/right | `'left'` für minimal | fehlt aktuell |
| `showIcon` *(neu)* | `boolean` | `false` | fehlt — classic renderbar |
| `typography.h2.*` | (Composite, siehe Abschnitt Typography) | — | h2.font/size/weight/color/transform/spacing |

**Konsolidierung für Phase 1:** `align` und `showIcon` neu ins Schema — damit classic/modern-Look (zentrierter Header mit Icon) auch für minimal-abgeleitete CUSTOM-Templates steuerbar ist. Bestehende Renderer werden NICHT angefasst — nur der neue, schema-driven Renderer in Phase 1-Sprint 3.

---

### 3 · ItemCard

**Render-Orte:**
- `menu-content.renderDefaultItem` (Z. 346–410, schema-driven via CSS-Vars)
- `menu-content.renderElegantItem` (Z. 206–319, schema-driven via CSS-Vars)
- `minimal-renderer.MinimalItem` (hartverdrahtet)
- `modern-renderer.ModernItem` (hartverdrahtet)
- `classic-renderer.ClassicItem` (hartverdrahtet)

**Config-Pfad:** `digital.products.*`, `digital.colors.{productBg, productHover, productDivider, priceLine, priceLineColor, accent*}`, `digital.typography.{h3, body, price, meta}.*`

| Feld | Typ | Default (minimal) | Editor | Drift? |
|---|---|---|---|---|
| `showImages` | `boolean` | `false` | TabProdukte | ok |
| `imageStyle` | `select` color/grayscale/sepia | `'color'` | TabProdukte | ok |
| `imageShape` | `select` rounded/round/rectangle | `'rounded'` | TabProdukte | ok |
| `imageSize` | `slider` 32–128 px | `64` | TabProdukte | ok |
| `imagePosition` | `select` left/right | `'left'` | TabProdukte | **nicht in renderDefaultItem umgesetzt** (fix Phase 1) |
| `showShortDesc` | `boolean` | `true` | TabProdukte | ok |
| `showLongDesc` | `boolean` | `false` | TabProdukte | nicht genutzt in Gäste-Ansicht, nur Item-Detail |
| `descMaxLines` | `slider` 1–10 | `2` | TabProdukte | **nicht in renderDefaultItem umgesetzt** (fix Phase 1) |
| `pricePosition` | `select` right/below-name/below-desc | `'right'` | TabProdukte | **nicht in renderDefaultItem umgesetzt** (fix Phase 1) |
| `showAllPrices` | `boolean` | `true` | TabProdukte | ok |
| `showFillQuantity` | `boolean` | `true` | TabProdukte | ok |
| `productBg` | `color` | `#FFFFFF` | TabFarben | ok |
| `productHover` | `color` | `#F9F9F9` | TabFarben | **nicht im CSS aktiviert** (Render-Pfad hat hover nur in Elegant) |
| `productDivider` | `color` | `#EBEBEB` | TabFarben | ok |
| `priceLine` | `select` dotted/solid/none | `'none'` | TabFarben | **in keinem Renderer implementiert** (Dot-Leader-Linie zwischen Name+Preis) |
| `priceLineColor` | `color` | `#CCCCCC` | TabFarben | s.o. |
| `highlightBadgeStyle` *(neu)* | `select` pill/dot/icon/bordered | → aus `digital.badges.style` | TabElemente | ok (aber aktuell nur in ElegantRenderer korrekt konsumiert) |
| `accentPrimary` | `color` | `#1E3A5F` | TabFarben | ok |
| `accentRecommend` | `color` | `#D97706` | TabFarben | ok |
| `accentNew` | `color` | `#E05252` | TabFarben | ok |
| `accentPremium` | `color` | `#7C3AED` | TabFarben | ok |

**Wine-Details (Teil der ItemCard):** siehe §4 WineBlock.

---

### 4 · WineBlock (Flag-Gruppe auf ItemCard)

**Render-Ort:** Inline in allen ItemCard-Varianten, wenn `item.wineProfile != null`.
- `menu-content.renderElegantItem` Z. 288–296 (respektiert `wineDetails`-Array)
- `menu-content.renderDefaultItem` Z. 373–381 (respektiert `wineDetails`-Array)
- `minimal-renderer` / `modern-renderer` / `classic-renderer` **ignorieren `wineDetails`-Array** und rendern feste Felder

**Config-Pfad:** `digital.products.wineDetails: string[]`, `digital.products.wineDetailPosition: 'below' | 'collapsible' | 'detail-only'`

| Feld-Flag | Typ | Default (minimal) | Sichtbar in Default-Render? | Drift? |
|---|---|---|---|---|
| `wineDetails[winery]` | toggle | `true` | ja | legacy Renderer ignorieren |
| `wineDetails[vintage]` | toggle | `true` | ja | s.o. |
| `wineDetails[grape]` | toggle | `true` | ja | s.o. |
| `wineDetails[region]` | toggle | `true` | ja | s.o. |
| `wineDetails[country]` | toggle | `false` | ja | s.o. |
| `wineDetails[alcohol]` | toggle | `false` | **nicht in Gäste-Render** | fix Phase 1 |
| `wineDetails[appellation]` | toggle | `false` | **nicht in Gäste-Render** | fix Phase 1 |
| `wineDetailPosition` | `select` | `'below'` | nur `'below'` implementiert | fix Phase 1 (collapsible + detail-only) |

---

### 5 · BeverageBlock (neu, noch nicht in Codebase)

**Status:** Heute existiert `ProductBeverageDetails`-Prisma-Modell, aber kein dedizierter Render-Block. Felder (ABV, Glasgröße, Jahrgang, Brennerei, Herkunft) werden im Item-Detail gelistet, aber nicht auf der Kartenansicht.

**Phase-1-Entscheidung:** BeverageBlock bekommt **dasselbe Pattern wie WineBlock** — `digital.products.beverageDetails: string[]` mit Flags `['abv','servingSize','vintage','origin','distillery']` und Position `below`/`collapsible`/`detail-only`.

**Konsequenz:** Schema wird vorbereitet, Renderer-Umsetzung folgt in Phase 1 Sprint 3 (analog WineBlock).

---

### 6 · AllergenLegend

**Render-Orte:**
- ItemCard-Fuß: Allergen-Nummern/Kürzel neben Tags in allen Item-Render-Pfaden
- Footer-Hinweis: Text-Hinweis "Bitte informieren Sie unser Personal …" in `menu-content` Z. 518–526 (nur für Elegant hartverdrahtet)

**Config-Pfad:** `digital.allergens.{position, style}`

| Feld | Typ | Default | Editor | Drift? |
|---|---|---|---|---|
| `position` | `select` product/footer/hidden | `'product'` | TabElemente | ok für `product`, `hidden` — `footer`-Position nicht implementiert |
| `style` | `select` numbers/abbreviations/icons | `'numbers'` | TabElemente | **nur `abbreviations` implementiert** (erster Buchstabe), `numbers`/`icons` fehlen |

**Legende-Block (neu in Phase 1):** zusätzliches Feld `showLegend: boolean` + `legendStyle: compact/full` für einen eigenständigen Allergen-Legenden-Block am Seitenende (aktuell nur als Textzeile im Footer der Elegant-Variante).

---

### 7 · Footer

**Render-Orte:**
- `menu-content` Z. 518–526 (nur Elegant, hartverdrahtet)
- `src/app/(public)/[tenant]/[location]/[menu]/page.tsx` rendert keinen eigenen Footer (nur Footer aus `digitalConfig.footer` wird NICHT konsumiert — weiterer Drift)

**Config-Pfad:** `digital.footer.{show, text, showAllergenNote, showPriceNote}`

| Feld | Typ | Default | Editor | Drift? |
|---|---|---|---|---|
| `show` | `boolean` | `true` | TabRahmen | **komplett ignoriert im Render** — Phase 1 muss Footer-Block erzeugen |
| `text` | `text` | `''` | TabRahmen | s.o. |
| `showAllergenNote` | `boolean` | `true` | TabRahmen | s.o., nur Elegant zeigt Hinweis |
| `showPriceNote` | `boolean` | `true` | TabRahmen | s.o. |
| `align` *(neu)* | `select` left/center/right | `'center'` | fehlt | neu |
| `linkImprint` *(neu)* | `text` (URL) | `null` | fehlt | neu |
| `linkPrivacy` *(neu)* | `text` (URL) | `null` | fehlt | neu |

**Phase-1-Entscheidung:** Footer wird als echter schema-driven Block ausgerollt (MwSt-Hinweis, Allergen-Hinweis, Impressum/Datenschutz-Links). Fix Elegant-Hartverdrahtung.

---

### 8 · TitlePage (nur PDF)

**Render-Ort:** `src/lib/pdf/*` (PDF-Engine, @react-pdf/renderer)

**Config-Pfad:** `analog.titlePage.*` sowie `analog.toc.*`

| Feld | Typ | Default | Hinweis |
|---|---|---|---|
| `showTitlePage` | `boolean` | `true` | aktiviert vorgeschaltete Titelseite |
| `title` | `text` | Kartenname | Großtitel |
| `subtitle` | `text` | `''` | Untertitel |
| `logoUrl` | `text` (URL) | `null` | zentral oben |
| `backgroundImage` | `text` (URL) | `null` | Vollbild-Hintergrund |
| `typography.title.*` | Composite (font/size/color) | — | eigene Typo |
| `showToc` | `boolean` (aus `analog.toc.show`) | `true` | aktiviert TOC-Seite |
| `tocStyle` | `select` elegant/minimal/numbered | `'numbered'` | Darstellung |

**Phase-1-Scope:** TitlePage-Schema wird in Sprint 1 definiert, PDF-Renderer in Sprint 3 angebunden (`TabPdfLayout` wird durch SchemaForm ersetzt).

---

## Globale Sektionen (nicht "Komponenten" im Puck-Sinn, aber teil-schemarelevant)

### Typography (wirkt auf alle Komponenten)

**Config-Pfad:** `digital.typography.{h1,h2,h3,body,price,meta}.*`

Pro Level folgende Felder (siehe `TabTypografie` Z. 800–853):

| Feld | Typ | Default (body, minimal) |
|---|---|---|
| `font` | `font` (aus 10-Font-Whitelist) | `'Inter'` |
| `size` | `slider` 8–64 px | `16` |
| `weight` | `select` 300/400/500/600/700/800 | `400` |
| `color` | `color` | `#1A1A1A` |
| `transform` | `select` none/uppercase/lowercase/capitalize | `'none'` |
| `spacing` | `slider` -5…20 % (wird /100 gespeichert) | `0` |
| `style` (nur body) | `select` normal/italic | `'normal'` |

**Font-Whitelist** (aus `FONTS` in design-editor.tsx):
Playfair Display, Cormorant Garamond, Libre Baskerville (serif);
Source Sans 3, Inter, Lato, Open Sans (sans);
Josefin Sans, Raleway, Montserrat (display).

### Grundstil (wirkt auf alle Komponenten)

| Feld | Typ | Default (minimal) |
|---|---|---|
| `mood` | `select` light/warm/dark | `'light'` |
| `density` | `select` airy/normal/compact | `'normal'` |

### Navigation (wirkt auf Seite, nicht Komponente)

| Feld | Typ | Default | Editor | Drift? |
|---|---|---|---|---|
| `showToc` | `boolean` | `true` | TabNavigation | aktuell nicht in Gäste-Render (nur PDF) |
| `tocPosition` | `select` top/sticky/dropdown | `'sticky'` | TabNavigation | s.o. |
| `tocStyle` | `select` pills/tabs/list | `'pills'` | TabNavigation | s.o. |
| `stickyNav` | `boolean` | `true` | TabNavigation | ok |
| `smoothScroll` | `boolean` | `true` | TabNavigation | **nicht explizit aktiviert** — Browser-Default nutzt es |
| `highlightActive` | `boolean` | `true` | TabNavigation | teilweise (activeSection-State gibt's, Observer fehlt) |
| `showBackToTop` | `boolean` | `true` | TabNavigation | ok |
| `hideEmptySections` | `boolean` | `true` | TabNavigation | **nicht implementiert** (leere Sections werden heute gefiltert durch `filteredSections.length > 0` nur während Suche) |

### Icons / Badges (Cross-Komponenten)

| Feld | Typ | Default (minimal) | Editor | Drift? |
|---|---|---|---|---|
| `icons.style` | `select` emoji/outlined/filled/none | `'outlined'` | TabElemente | **in keinem Renderer konsumiert** — Icons sind hartverdrahtet |
| `badges.style` | `select` pill/dot/icon/bordered | `'pill'` | TabElemente | nur in Elegant korrekt |
| `badges.show` | `string[]` aus recommendation/new/premium/vegetarian/vegan/bio | `['new','recommendation']` | TabElemente | aktuell nicht honoriert — alle Highlight-Types werden immer gezeigt |

---

## Phase-1-Abgrenzung (aus dem Inventar abgeleitet)

### Was in Schema kommt

Alle Felder oben, gruppiert nach 8 Komponenten + 3 globalen Bereichen (Typography, Grundstil, Navigation, Icons/Badges). Der PDF-Teil bekommt ein eigenes Schema-Set (TitlePage + TOC + analog-spezifische Typo).

### Was NICHT in Schema kommt (Phase 1)

- **Suchleiste / Filter** — Gäste-Interaktion, bleibt UI-Pattern, keine Konfiguration.
- **Section-Tab-Navigation** (oben in `renderSearchBar`) — bleibt unverändert.
- **Item-Detail-Seite** — bekommt eigenes Schema erst in einer späteren Phase, wenn die Karten-Seite steht.

### Pflicht-Fixes neben Schema-Aufbau

Die Schema-Einführung bringt Felder sichtbar, die aktuell im UI verfügbar sind, aber im Renderer tot liegen (s.o. Drift-Spalten). Um Gate 1 zu erreichen, muss der **neue schema-driven Renderer** folgende heute inaktive Felder aktivieren:

1. `products.imagePosition` (Wechsel links/rechts)
2. `products.descMaxLines` (line-clamp)
3. `products.pricePosition` (right/below-name/below-desc)
4. `products.priceLine` + `priceLineColor` (Dot-Leader-Linie)
5. `products.productHover` (Hover-State)
6. `products.wineDetails[alcohol]` + `[appellation]` (fehlt komplett im Render)
7. `products.wineDetailPosition` Varianten `collapsible` + `detail-only`
8. `allergens.position='footer'` und `allergens.style='numbers'|'icons'`
9. `footer.*` komplett (heute nicht gerendert, außer Elegant-MwSt-Hinweis)
10. `header.layout` (neu) + `header.backgroundImage`-Editor (bisher nur via API)
11. `icons.style` (heute nie konsumiert)
12. `badges.show[]` (heute ignoriert)

Diese Fixes werden in Sprint 3 ausgeführt (neuer schema-driven Renderer ersetzt die hartverdrahteten Template-Renderer für Minimal). Elegant/Modern/Classic sind archiviert, daher kein Re-Fit nötig.

---

## Sprint-1-Ergebnis-Skizze (Vorschau)

Pro Komponente eine TS-Datei unter `src/lib/design-templates/schemas/`:

```
schemas/
├── index.ts               // exportiert ComponentSchema[], Validator, Defaults-Merger
├── types.ts               // FieldDef, ComponentSchema, Validator-Typen
├── validator.ts           // validate(config, schema) → { valid, errors }
├── hero.ts                // ComponentSchema für Hero
├── section-header.ts
├── item-card.ts           // inkl. WineBlock + BeverageBlock als "Sub-Gruppen"
├── allergen-legend.ts
├── footer.ts
├── title-page.ts          // PDF-spezifisch
└── shared/
    ├── typography.ts      // h1/h2/h3/body/price/meta-Schema (wiederverwendbar)
    ├── colors.ts          // Color-Palette-Schema
    └── fonts.ts           // FONTS-Whitelist (aus design-editor.tsx extrahiert)
```

Validator-Aufgabe: (a) Unbekannte Felder durchreichen, (b) Wert-Validierung pro FieldDef (Regex-HEX, min/max, Enum), (c) Merge mit Defaults. Aufruf-Orte: API-PATCH (bevor Daten in `DesignTemplate.config` landen), Build-Time-Check im Seed-Script.

---

## Nächste Schritte

1. **Commit dieses Dokuments** auf `feature/design-editor-v2` (Sprint 0 Ende).
2. **Sprint 1 starten:** `schemas/`-Struktur anlegen, mit `shared/fonts.ts` + `shared/typography.ts` + `item-card.ts` beginnen (größter Scope, Blueprint für Rest).
3. Nach jedem Sprint: PLAN.md-Checkliste abhaken, commit, kurze Status-Note ins Auto-Memory (feature-freeze-Pattern).
4. Gate 1 aktivieren, sobald der neue `<SchemaForm>` die `ItemCard`-Felder rendert und Preview-Update <300 ms liefert.

---

_Dokument-Version 1 · 20.04.2026 · Claude · abgeleitet aus Read der o.g. Quellen, kein Hotelier-Eingriff._
