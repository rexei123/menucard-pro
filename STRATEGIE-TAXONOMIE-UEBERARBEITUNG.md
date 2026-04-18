# Strategie: Taxonomie-Überarbeitung & Produkterstellung

**Stand:** 17.04.2026 | **Referenz:** MenuCard-Pro-Strategie-v3.md

---

## 1. AUSGANGSLAGE

### Was bereits existiert

Das Prisma-Schema (`TaxonomyNode`) unterstützt bereits:

- **Hierarchie:** `parentId`, `children`, `depth` — beliebige Verschachtelungstiefe
- **6 aktive Typen:** CATEGORY, REGION, GRAPE, STYLE, CUISINE, DIET (+ OCCASION, CUSTOM reserviert)
- **Mehrsprachigkeit:** `TaxonomyNodeTranslation` (DE + EN)
- **Produkt-Zuordnung:** `ProductTaxonomy` Junction-Table mit `isPrimary`-Flag
- **Icons:** Material Symbols pro Node
- **API:** Vollständiges CRUD unter `/api/v1/taxonomy`
- **79 Nodes** im Seed (27 live in DB nach Deduplizierung)

### Was fehlt

| Problem | Auswirkung |
|---|---|
| **Keine Taxonomie-Verwaltungs-UI** | Kategorien, Regionen, Rebsorten können nur über Code/DB angelegt werden |
| **Umlaut-Fehler** | 164+ fehlerhafte Einträge in Seed-Dateien, ~20 in der Live-DB |
| **Flache Strukturen** | Regionen, Rebsorten, Kategorien ohne sinnvolle Hierarchie angelegt |
| **Keine Steuer-Zuordnung** | Übergeordnete Gruppen (Lebensmittel/Getränke) fehlen für Steuerlogik |
| **Kein Hinzufügen durch Admin** | Neue Kategorien erfordern Entwickler-Eingriff |

---

## 2. UMLAUT-BEREINIGUNG (Sofort-Maßnahme)

### 2.1 Betroffene Bereiche

**In der Live-Datenbank (TaxonomyNode.name):**

| Falsch | Richtig | Typ |
|---|---|---|
| Niederoesterreich | Niederösterreich | REGION |
| Oesterreich | Österreich | REGION |
| Suedsteiermark | Südsteiermark | REGION |
| Suedtirol | Südtirol | REGION |
| Gruener Veltliner | Grüner Veltliner | GRAPE |
| Blaufraenkisch | Blaufränkisch | GRAPE |
| Oesterreichisch | Österreichisch | CUISINE |
| Franzoesisch | Französisch | CUISINE |
| Kaese & Obst | Käse & Obst | CATEGORY |
| Saefte | Säfte | CATEGORY |

**In Seed-Dateien (für zukünftige Reseeds):**

- `seed-v2.ts` — 27 Stellen
- `seed-wine.sh` — 85 Stellen
- `seed-wine-part2.sql` — 27 Stellen

### 2.2 Umsetzung

1. **SQL-Script** für Live-DB: UPDATE auf `TaxonomyNode.name`, `TaxonomyNode.slug` UND `TaxonomyNodeTranslation.name`
2. **Seed-Dateien** korrigieren: Alle ASCII-Umlaute (oe→ö, ae→ä, ue→ü, ss→ß) in den drei Seed-Files
3. **Slug-Konvention:** Slugs bleiben ASCII-kompatibel (`oesterreich`, `gruener-veltliner`) — nur `name` und Translation werden korrigiert

**Aufwand:** Klein (< 1 Tag)

---

## 3. HIERARCHISCHE TAXONOMIE-STRUKTUR

### 3.1 Kategorien: Steuer-Hauptgruppen einführen

**Aktuelle Struktur (flach):**
```
CATEGORY: Speisen, Wein, Cocktails, Bier, Alkoholfrei, Heisse Getränke, Spirituosen
```

**Neue Struktur (3-stufig):**
```
CATEGORY (depth 0 — Steuer-Hauptgruppe):
├── Lebensmittel (MwSt. 10%)
│   ├── Speisen
│   │   ├── Vorspeisen
│   │   ├── Suppen
│   │   ├── Hauptgerichte
│   │   ├── Desserts
│   │   └── Käse & Obst
│   └── Alkoholfreie Getränke
│       ├── Softdrinks
│       ├── Säfte
│       ├── Heisse Getränke
│       │   ├── Kaffee
│       │   └── Tee
│       └── Wasser
│
├── Alkoholische Getränke (MwSt. 20%)
│   ├── Wein
│   │   ├── Weisswein
│   │   ├── Rotwein
│   │   ├── Roséwein
│   │   └── Schaumwein
│   ├── Bier
│   │   ├── Fassbier
│   │   └── Flaschenbier
│   ├── Cocktails
│   │   ├── Klassiker
│   │   └── Signature
│   └── Spirituosen
│       ├── Gin
│       ├── Whisky
│       ├── Rum
│       └── Edelbrände
│
└── Sonstiges (individuell)
    └── Merchandise, Gutscheine, etc.
```

**Vorteile:**
- Steuer-Zuordnung über depth-0 Node (Lebensmittel = 10%, Alk. Getränke = 20%)
- Bestehende Unterkategorien bleiben erhalten, werden nur umgehängt
- Produkt-Zuordnung auf jeder Ebene möglich (ein Produkt kann z.B. "Hauptgerichte" zugeordnet sein und erbt automatisch "Lebensmittel")

**Schema-Änderung nötig?** Nein — `parentId` und `depth` existieren bereits. Nur Daten-Migration.

### 3.2 Regionen: Land > Region > Lage

**Aktuelle Struktur:**
```
REGION: Österreich > Niederösterreich > Wachau (3 Ebenen, teilweise)
        Frankreich > Champagne (2 Ebenen)
```

**Neue Struktur (konsistent 3-stufig):**
```
REGION:
├── Österreich
│   ├── Niederösterreich
│   │   ├── Wachau
│   │   ├── Kamptal
│   │   ├── Kremstal
│   │   └── Traisental
│   ├── Burgenland
│   │   ├── Neusiedlersee
│   │   ├── Mittelburgenland
│   │   └── Leithaberg
│   ├── Steiermark
│   │   ├── Südsteiermark
│   │   └── Vulkanland
│   └── Wien
│
├── Frankreich
│   ├── Champagne
│   ├── Bordeaux
│   │   ├── Médoc
│   │   └── Saint-Émilion
│   ├── Burgund
│   └── Provence
│
├── Italien
│   ├── Venetien
│   ├── Toskana
│   │   ├── Chianti
│   │   └── Montalcino
│   ├── Südtirol
│   └── Piemont
│
├── Spanien
│   ├── Rias Baixas
│   ├── Rioja
│   └── Ribera del Duero
│
├── Deutschland
│   ├── Mosel
│   ├── Rheingau
│   └── Pfalz
│
└── Portugal
    └── Douro
```

**Prinzip:** Land (depth 0) → Großregion (depth 1) → Lage/Appellation (depth 2)

### 3.3 Rebsorten: Farbgruppen einführen

**Aktuelle Struktur (alle flach):**
```
GRAPE: Grüner Veltliner, Riesling, Zweigelt, Blaufränkisch, ...
```

**Neue Struktur (2-stufig):**
```
GRAPE:
├── Weissweinreben
│   ├── Grüner Veltliner
│   ├── Riesling
│   ├── Sauvignon Blanc
│   ├── Chardonnay
│   ├── Muskateller
│   ├── Pinot Blanc (Weissburgunder)
│   ├── Welschriesling
│   └── Gelber Muskateller
│
├── Rotweinreben
│   ├── Zweigelt
│   ├── Blaufränkisch
│   ├── St. Laurent
│   ├── Pinot Noir (Blauburgunder)
│   ├── Cabernet Sauvignon
│   ├── Merlot
│   └── Syrah
│
├── Cuvée / Verschnitt
│   ├── Rotcuvée
│   └── Weisscuvée
│
└── Sonstige
    ├── Schilcher (Blauer Wildbacher)
    └── Gemischter Satz
```

**Hinweis:** Produkte werden weiterhin der Einzelsorte zugeordnet (z.B. "Grüner Veltliner"). Die Eltern-Ebene ("Weissweinreben") dient der Navigation und Filterung in der Gästeansicht.

### 3.4 Stil: Erweiterung

**Aktuelle Struktur:**
```
STYLE: Trocken, Halbtrocken, Lieblich, Brut, Extra Brut
```

**Erweiterte Struktur (flach, kein Bedarf für Hierarchie):**
```
STYLE:
├── Trocken
├── Halbtrocken
├── Lieblich
├── Süß / Edelsüß
├── Brut
├── Extra Brut
├── Brut Nature
├── Demi-Sec
└── Naturwein
```

---

## 4. ADMIN-UI: TAXONOMIE-VERWALTUNG

### 4.1 Neue Admin-Seite: `/admin/settings/taxonomy`

**Aufbau:**

```
┌─────────────────────────────────────────────────┐
│  Klassifizierung verwalten                      │
├─────────────────────────────────────────────────┤
│  [Kategorien] [Regionen] [Rebsorten] [Stil]    │
│  [Küche] [Ernährung]                    [+ Neu] │
├─────────────────────────────────────────────────┤
│                                                 │
│  ▼ Lebensmittel (10 Produkte)          [⋮]     │
│    ▼ Speisen (45 Produkte)             [⋮]     │
│      ├─ Vorspeisen (12)               [⋮]     │
│      ├─ Suppen (5)                    [⋮]     │
│      ├─ Hauptgerichte (18)            [⋮]     │
│      ├─ Desserts (7)                  [⋮]     │
│      └─ Käse & Obst (3)              [⋮]     │
│    ▼ Alkoholfreie Getränke (15)        [⋮]     │
│      ├─ Softdrinks (6)               [⋮]     │
│      └─ Säfte (4)                    [⋮]     │
│                                                 │
│  ▼ Alkoholische Getränke (120 Produkte) [⋮]    │
│    ▼ Wein (91 Produkte)                [⋮]     │
│      ...                                        │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Funktionen:**

| Funktion | Beschreibung |
|---|---|
| **Baum-Ansicht** | Aufklappbare Hierarchie pro Typ mit Einrückung |
| **Drag & Drop** | Sortierung und Umhängen zwischen Eltern-Nodes |
| **Inline-Edit** | Name direkt in der Liste bearbeiten (Doppelklick) |
| **Neu anlegen** | Node erstellen mit Name, Icon, Eltern-Node, Übersetzungen |
| **Löschen** | Nur wenn 0 Produkte und 0 Kinder (API-Schutz existiert bereits) |
| **Produktanzahl** | Badge mit Anzahl zugeordneter Produkte |
| **Icon-Picker** | Material Symbols Auswahl |
| **Übersetzung** | DE + EN Name direkt editierbar |

### 4.2 Produkt-Editor: Klassifizierung verbessern

**Aktuelle UI:** Flache Pill-Liste pro Typ (Screenshot)

**Verbesserte UI:**

```
┌─────────────────────────────────────────────────┐
│  ◇ Klassifizierung                              │
├─────────────────────────────────────────────────┤
│  KATEGORIEN                                     │
│  Lebensmittel > Speisen > [Hauptgerichte ×]     │
│                            [+ Kategorie]        │
│                                                 │
│  REGIONEN                                       │
│  Österreich > Niederösterreich > [Wachau ×]     │
│                                  [+ Region]     │
│                                                 │
│  REBSORTEN                                      │
│  Weissweinreben > [Grüner Veltliner ×]         │
│                   [+ Rebsorte]                  │
│                                                 │
│  STIL                                           │
│  [Trocken ×]  [+ Stil]                         │
│                                                 │
│  KÜCHE                                          │
│  [Österreichisch ×]  [+ Küche]                 │
│                                                 │
│  ERNÄHRUNG                                      │
│  [Vegetarisch ×] [Glutenfrei ×]  [+ Ernährung] │
└─────────────────────────────────────────────────┘
```

**Änderungen gegenüber heute:**

1. **Breadcrumb-Pfad** statt flacher Pills — zeigt Hierarchie (z.B. "Österreich > Niederösterreich > Wachau")
2. **Cascading-Dropdown** bei "+" — erst Land, dann Region, dann Lage auswählen
3. **Nur Blatt-Nodes zuweisbar** — Produkt wird "Hauptgerichte" zugeordnet, nicht "Lebensmittel" direkt (Steuer-Zuordnung wird automatisch von der Eltern-Node geerbt)
4. **Schnell-Suche** — Tippen filtert die verfügbaren Nodes

### 4.3 Steuer-Zuordnung (Zukunft, vorbereitet)

Das Schema braucht ein neues Feld auf `TaxonomyNode`:

```prisma
model TaxonomyNode {
  // ... bestehende Felder
  taxRate    Float?    // z.B. 0.10, 0.20 — nur auf depth-0 CATEGORY-Nodes
  taxLabel   String?   // z.B. "Ermäßigt 10%", "Normal 20%"
}
```

**Logik:**
- `taxRate` wird nur auf Root-CATEGORY-Nodes gesetzt (Lebensmittel = 0.10, Alk. Getränke = 0.20)
- Produkte erben den Steuersatz über ihre Kategorie-Zuordnung: `Product → ProductTaxonomy → TaxonomyNode → walk up to depth=0 → taxRate`
- Kein Eingriff ins Design nötig — rein Backend-Logik + ein Feld in der Taxonomie-Verwaltung

---

## 5. TECHNISCHE UMSETZUNG

### 5.1 Schema-Änderungen (Prisma)

```prisma
model TaxonomyNode {
  // Bestehend — KEINE Änderung:
  id        String       @id @default(cuid())
  tenantId  String
  name      String
  slug      String
  type      TaxonomyType
  parentId  String?
  depth     Int          @default(0)
  sortOrder Int          @default(0)
  icon      String?

  // NEU — optionale Steuerfelder:
  taxRate   Float?       // Nur für depth-0 CATEGORY-Nodes
  taxLabel  String?      // Anzeigename z.B. "Ermäßigt 10%"

  // Bestehende Relationen — unverändert:
  parent       TaxonomyNode?  @relation("TaxonomyTree", fields: [parentId], references: [id])
  children     TaxonomyNode[] @relation("TaxonomyTree")
  products     ProductTaxonomy[]
  translations TaxonomyNodeTranslation[]
  tenant       Tenant         @relation(fields: [tenantId], references: [id], onDelete: Cascade)

  @@unique([tenantId, type, slug])
}
```

**Einzige Schema-Ergänzung:** `taxRate` und `taxLabel` — zwei optionale Felder. Kein Breaking Change.

### 5.2 API-Erweiterungen

| Endpoint | Änderung |
|---|---|
| `GET /api/v1/taxonomy` | Neuer Query-Param `?tree=true` → gibt verschachtelte Baumstruktur zurück |
| `PATCH /api/v1/taxonomy/[id]` | `parentId` änderbar (Node umhängen) + `taxRate`/`taxLabel` |
| `POST /api/v1/taxonomy` | `parentId` + automatische `depth`-Berechnung (existiert bereits) |
| `GET /api/v1/taxonomy/tree` | Neuer Endpoint: Kompletter Baum pro Typ, optimiert für Admin-UI |

### 5.3 Daten-Migration

**Phase 1 — Umlaute korrigieren:**
```sql
-- TaxonomyNode.name + slug
UPDATE "TaxonomyNode" SET name = 'Österreich' WHERE slug = 'oesterreich';
UPDATE "TaxonomyNode" SET name = 'Niederösterreich' WHERE slug = 'niederoesterreich';
-- ... (alle ~10 Nodes)

-- TaxonomyNodeTranslation.name
UPDATE "TaxonomyNodeTranslation" SET name = 'Österreich'
  WHERE "nodeId" IN (SELECT id FROM "TaxonomyNode" WHERE slug = 'oesterreich');
-- ...
```

**Phase 2 — Hierarchie aufbauen:**
```sql
-- Hauptkategorien anlegen
INSERT INTO "TaxonomyNode" (id, "tenantId", name, slug, type, depth, "sortOrder")
VALUES ('cat-food', '<tenantId>', 'Lebensmittel', 'lebensmittel', 'CATEGORY', 0, 0);
INSERT INTO "TaxonomyNode" (id, "tenantId", name, slug, type, depth, "sortOrder")
VALUES ('cat-bev', '<tenantId>', 'Alkoholische Getränke', 'alkoholische-getraenke', 'CATEGORY', 0, 1);

-- Bestehende Kategorien umhängen
UPDATE "TaxonomyNode" SET "parentId" = 'cat-food', depth = 1 WHERE slug = 'speisen';
UPDATE "TaxonomyNode" SET "parentId" = 'cat-bev', depth = 1 WHERE slug = 'wein';
-- ...

-- Rebsorten-Gruppen
INSERT INTO "TaxonomyNode" (...) VALUES (..., 'Weissweinreben', 'weissweinreben', 'GRAPE', ...);
UPDATE "TaxonomyNode" SET "parentId" = '<weissweinreben-id>', depth = 1
  WHERE slug IN ('gruener-veltliner', 'riesling', 'sauvignon-blanc', ...);
```

**Phase 3 — Seed-Dateien aktualisieren:**
- `seed-v2.ts`: Alle Umlaut-Fehler korrigieren + Hierarchie einbauen
- `seed-wine.sh` und `seed-wine-part2.sql`: Umlaute korrigieren

---

## 6. DESIGN-KONFORMITÄT

Alle UI-Änderungen müssen Design-Strategie 2.0 einhalten:

| Regel | Umsetzung |
|---|---|
| **Font:** Roboto (Admin) | Taxonomie-Verwaltung + verbesserter Produkt-Editor |
| **Primärfarbe:** #DD3C71 | Aktive Tabs, ausgewählte Nodes, Breadcrumb-Highlights |
| **Add-Button:** #22C55E | "[+ Neu]" und "[+ Kategorie]" Buttons |
| **Icons:** Material Symbols | Baum-Chevrons, Typ-Icons, Action-Menü |
| **Keine Emojis** | Nur Material Symbols für Node-Icons |
| **Keine Architektur-Änderung** | Bestehendes Schema wird erweitert, nicht ersetzt |

**Gästeansicht:** Keine Änderung am Rendering. Die hierarchische Taxonomie wirkt sich nur auf Admin-Verwaltung und Filterlogik aus. Die Gäste-Templates (elegant, modern, classic, minimal) bleiben unberührt.

---

## 7. ZUSÄTZLICHE VORSCHLÄGE

### 7.1 Automatische Kategorie-Erkennung beim Import

Beim CSV-Import könnte das System anhand von Keywords automatisch Kategorien vorschlagen:
- "Veltliner", "Riesling" → GRAPE: Grüner Veltliner / Riesling
- "Wachau", "Kamptal" → REGION: entsprechende Node
- Konfidenz-Score anzeigen, Admin bestätigt

### 7.2 Kategorie-basierte Karten-Generierung

Menü-Sektionen automatisch aus Taxonomie-Baum erzeugen:
- "Erstelle Weinkarte" → Sektionen aus REGION depth-1 Nodes (Österreich, Frankreich, Italien)
- "Erstelle Speisekarte" → Sektionen aus CATEGORY depth-2 (Vorspeisen, Suppen, Hauptgerichte)

### 7.3 Filter in der Gästeansicht

Taxonomie-basierte Filterleiste in der Gästeansicht:
- Wein filtern nach: Region, Rebsorte, Stil
- Speisen filtern nach: Küche, Ernährung
- Nutzt die bestehende Hierarchie für Drill-Down

### 7.4 Allergene als Taxonomie-Typ

Allergene (aktuell eigenes Modell `Allergen`) könnten langfristig als DIET-Nodes abgebildet werden — einheitliche Verwaltung aller Produkt-Klassifizierungen.

### 7.5 Saisonale Tags

Neuer `TaxonomyType: SEASON` für saisonale Klassifizierung:
- Frühling, Sommer, Herbst, Winter
- Ermöglicht saisonale Karten-Filterung ohne Zeitsteuerung (C-3)

---

## 8. UMSETZUNGS-REIHENFOLGE

### Sprint T-1: Fundament (< 1 Tag)

1. **Umlaut-Fix** — SQL-Script für Live-DB + Seed-Dateien korrigieren
2. **Seed-Dateien** aktualisieren (seed-v2.ts, seed-wine.sh, seed-wine-part2.sql)

### Sprint T-2: Hierarchie aufbauen (1-2 Tage)

3. **Schema erweitern** — `taxRate`, `taxLabel` Felder hinzufügen (`prisma db push`)
4. **Daten-Migration** — Hauptkategorien anlegen, bestehende Nodes umhängen
5. **Rebsorten-Gruppen** — Weissweinreben, Rotweinreben, Cuvée als Eltern
6. **Regionen vervollständigen** — fehlende Länder/Lagen ergänzen
7. **API erweitern** — `?tree=true` Param, `GET /taxonomy/tree` Endpoint

### Sprint T-3: Admin-UI Taxonomie-Verwaltung (2-3 Tage)

8. **Neue Seite** `/admin/settings/taxonomy` — Baumansicht mit CRUD
9. **Drag & Drop** für Sortierung und Umhängen
10. **Inline-Edit** für Name und Übersetzungen
11. **Icon-Picker** Integration

### Sprint T-4: Produkt-Editor verbessern (1-2 Tage)

12. **Cascading-Dropdown** statt flacher Pills
13. **Breadcrumb-Pfad** für ausgewählte Nodes
14. **Schnell-Suche** über alle Taxonomie-Nodes

### Zukunft

15. Steuer-Zuordnung über Root-Kategorie
16. Automatische Kategorie-Erkennung beim Import
17. Gästeansicht-Filter

---

## 9. ZUSAMMENFASSUNG

| Aspekt | Ist-Zustand | Soll-Zustand |
|---|---|---|
| Umlaute | ~20 fehlerhafte Nodes + 164 in Seeds | Alle korrekt |
| Kategorie-Hierarchie | 2 Ebenen, kein Steuer-Bezug | 3 Ebenen mit Steuer-Hauptgruppen |
| Regionen | Teilweise hierarchisch | Konsistent: Land > Region > Lage |
| Rebsorten | Flach (13 Nodes) | Gruppiert: Weiss/Rot/Cuvée > Einzelsorte |
| Admin-UI | Keine Taxonomie-Verwaltung | Vollständige Baumansicht mit CRUD |
| Produkt-Editor | Flache Pill-Liste | Cascading-Dropdown mit Breadcrumbs |
| Schema-Änderung | — | +2 optionale Felder (taxRate, taxLabel) |
| Design-Bruch | — | Keiner (100% Design 2.0 konform) |

**Kern-Erkenntnis:** Das bestehende Schema ist ausgezeichnet vorbereitet. Die Hauptarbeit liegt in Daten-Migration und UI-Entwicklung, nicht in Architektur-Änderungen.
