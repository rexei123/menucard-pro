# MenuCard Pro – Produktstrategie 2.0
## Produktarchitektur & Implementierungsanweisung
### Stand: 15.04.2026
### Basiert auf Analyse von Toast, Square, Lightspeed + bisheriger Entwicklung

---

## 1. AUSGANGSLAGE

### Was bisher gebaut wurde (v1)
MenuCard Pro v1 ist funktionsfähig: 9 Karten, 322 Testprodukte, Admin mit Produkt-Editor, Kartenverwaltung mit Drag & Drop, Gästeansicht mit Suche/Filter, QR-Codes, PDF-Export v1. Stack: Next.js 14, TypeScript, Tailwind CSS, Prisma, PostgreSQL, NextAuth, PM2, Nginx.

### Warum v2 nötig ist
Das aktuelle Datenmodell hat strukturelle Grenzen die zukünftige Features (Warenwirtschaft, Bestellsystem, E-Commerce, Multi-Channel) blockieren. Die Testdaten sind Dummies – sie können gelöscht und nach dem Schema-Umbau sauber neu aufgebaut werden. Jetzt ist der billigste Zeitpunkt für den Umbau, weil das UI-Redesign ohnehin ansteht.

### Kernprinzip der neuen Architektur
**Ein Produkt beschreibt, was etwas ist. Eine Variante beschreibt, wie es verkauft wird.**

Das ist der Industriestandard (Square: CatalogItem → CatalogItemVariation, Toast: MenuItem → Variations, Lightspeed: Product → Variation). MenuCard Pro v1 hat das nicht – ein Product ist gleichzeitig abstrakt und verkäuflich.

---

## 2. SERVER & DEPLOYMENT

### Infrastruktur (unverändert)
- **IP:** 178.104.138.177
- **SSH:** `ssh root@178.104.138.177`
- **App:** `/var/www/menucard-pro`
- **DB:** `psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"`
- **Admin:** admin@hotel-sonnblick.at / Sonnblick2026!
- **PM2:** `pm2 restart menucard-pro`
- **Build:** `npm run build && pm2 restart menucard-pro`
- **Nginx:** Reverse proxy → localhost:3000
- **GitHub:** github.com/rexei123/menucard-pro

### Deployment-Workflow (unverändert)
1. Datei in Claude/Cowork erstellen → Download
2. PowerShell 1 (lokal): `scp DATEI root@178.104.138.177:/var/www/menucard-pro/`
3. PowerShell 2 (SSH): `cd /var/www/menucard-pro && bash DATEI.sh`
4. UTF-8 mit echten Umlauten – kein ASCII-Workaround nötig

### Zwei Arbeitsplätze
- **Home PC (erich):** `C:\Users\erich\Desktop`
- **Work PC (User):** `C:\Users\User\OneDrive\Desktop`

Immer fragen welcher Desktop aktiv ist bevor SCP-Befehle generiert werden.

---

## 3. ARCHITEKTURENTSCHEIDUNGEN v2

### 3.1 Product → ProductVariant (NEU)

**Problem v1:** Ein `Product` hat mehrere `ProductPrice`-Einträge (Glas 5,20€ / Flasche 28,00€), aber diese sind keine eigenständigen verkäuflichen Einheiten. Man kann nicht sagen: "Das Glas ist ausverkauft, die Flasche nicht."

**Lösung v2:** Zwischen Product und Preis kommt `ProductVariant`. Jede Variante ist eine eigenständige, verkäufliche Einheit mit eigenem SKU, eigener Verfügbarkeit, eigenem Bestand.

```
Product: "Grüner Veltliner Schlumberger 2023" (abstrakt)
├── ProductVariant: "Glas 0,125l" (verkäuflich)
│   ├── VariantPrice: Restaurant VK 5,20€ / EK 1,80€
│   ├── VariantPrice: Bar VK 5,80€
│   └── StockLevel: Bar → 40 Einheiten
└── ProductVariant: "Flasche 0,75l" (verkäuflich)
    ├── VariantPrice: Restaurant VK 28,00€ / EK 10,80€
    └── StockLevel: Restaurant → 12 Flaschen
```

**Für Speisen ohne Größenvarianten:** Genau eine "Standard"-Variante. Keine Füllmenge nötig.

**Was das für die Zukunft öffnet:**
- Warenwirtschaft: Bestand pro Variante × Location
- Bestellsystem: OrderLine → ProductVariant (nicht Product)
- Umrechnung: 1 Flasche = 6 Gläser (conversionFactor)
- E-Commerce: Jede Variante hat eigene SKU für Shop

### 3.2 MenuPlacement → ProductVariant (ANGEPASST)

**v1:** MenuPlacement referenziert ein Product.
**v2:** MenuPlacement referenziert eine ProductVariant.

Das heißt: In der Weinkarte steht die Flasche, in der Barkarte steht das Glas – mit verschiedenen Preisen, verschiedener Verfügbarkeit. Und auf einer Karte können auch beide Varianten desselben Produkts stehen (Glas UND Flasche).

### 3.3 MenuSection mit Verschachtelung (ERWEITERT)

**v1:** MenuSection ist flach (eine Ebene pro Karte).
**v2:** MenuSection bekommt `parentId` für beliebig tiefe Hierarchie.

```
Weinkarte (Menu)
├── Österreich (MenuSection, depth 0)
│   ├── Weißwein (MenuSection, depth 1)
│   │   ├── Grüner Veltliner (MenuSection, depth 2)
│   │   │   └── Schlumberger Flasche (MenuPlacement → Variant)
│   │   └── Riesling (MenuSection, depth 2)
│   │       └── Domäne Wachau Flasche (MenuPlacement → Variant)
│   └── Rotwein (MenuSection, depth 1)
│       └── ...
├── Frankreich (MenuSection, depth 0)
│   └── ...
```

Die Kartenstruktur ist redaktionell – der Betreiber entscheidet frei, wie tief und wie breit die Gliederung ist. Die Taxonomie ist davon unabhängig.

### 3.4 TaxonomyNode ersetzt ProductGroup (NEU)

**v1:** Ein Product gehört zu genau einer ProductGroup (1:n).
**v2:** Ein Product wird über eine n:m-Tabelle beliebig vielen TaxonomyNodes zugeordnet.

```
TaxonomyNode (type: "category"):  Getränke → Wein → Weißwein
TaxonomyNode (type: "region"):    Österreich → Wachau
TaxonomyNode (type: "grape"):     Grüner Veltliner
TaxonomyNode (type: "style"):     Trocken
TaxonomyNode (type: "diet"):      Vegetarisch
```

Ein Wein kann gleichzeitig "Weißwein" + "Wachau" + "Grüner Veltliner" + "Trocken" sein. Das ermöglicht kartenübergreifende Multi-Filter in der Gästekarte.

**Taxonomie ≠ Kartenstruktur.** Die Taxonomie beschreibt Eigenschaften des Produkts. Die Kartenstruktur (MenuSection-Hierarchie) beschreibt den redaktionellen Aufbau einer bestimmten Karte. Beides ist unabhängig voneinander.

**WineProfile-Felder die in Taxonomie wandern:** country, region, grapeVarieties, wineStyle. Diese werden zu TaxonomyNode-Zuordnungen. Im WineProfile bleiben nur wein-spezifische Detail-Felder: winery, vintage, aging, tastingNotes, servingTemp, foodPairing, certification.

### 3.5 ModifierGroup + Modifier (NEU, Vorbereitung)

Für Beilagen-Auswahl, Zubereitungsoptionen, Extras. Wird als Schema angelegt, Admin-UI kommt erst mit dem Bestellsystem.

```
Product: "Wiener Schnitzel"
└── ModifierGroup: "Beilage" (min: 1, max: 1)
    ├── Modifier: "Kartoffelsalat" (+0,00€)
    ├── Modifier: "Pommes frites" (+0,00€)
    └── Modifier: "Reis" (+0,00€)
```

### 3.6 RecipeComponent (NEU, Vorbereitung)

Cocktail-Rezepte als Zutatenliste von ProductVariants. Ermöglicht automatische Kalkulation und Bestandsreduktion.

```
ProductVariant: "Mojito (Glas)"
└── RecipeComponent[]
    ├── ingredient: "Rum 4cl Variante" → quantity: 4, unit: "cl"
    ├── ingredient: "Limettensaft" → quantity: 3, unit: "cl"
    └── ingredient: "Minze" → quantity: 5, unit: "Blätter"
```

### 3.7 StockLevel (NEU, Vorbereitung)

Bestand pro ProductVariant × Location. Wird als Schema angelegt, Admin-UI kommt mit der Warenwirtschaft.

### 3.8 Order-System (ZUKUNFT, nur Schema)

Order → OrderLine → ProductVariant + OrderLineModifier[]. Tabellen werden angelegt, aber kein Code drumherum. Wenn das Bestellsystem kommt, sind die Tabellen da.

### 3.9 Allergen-Stammdaten (VERBESSERT)

**v1:** Allergen ohne strukturierte Stammdaten.
**v2:** Allergen-Tabelle mit EU-Code, Icon und mehrsprachigen Namen (AllergenTranslation).

### 3.10 Kalkulationskette (UNVERÄNDERT)

EK → +Fix€ → ×Aufschlag% → =VK mit farbcodierter Marge. Verschiebt sich nur von `ProductPrice` auf `VariantPrice`. Logik und UI bleiben identisch.

### 3.11 ChannelType auf MenuPlacement (NEU)

Jedes Placement bekommt ein Array `channels` das steuert, auf welchen Kanälen es sichtbar ist: DIGITAL (QR/Web), PRINT (PDF), POS (Kasse, Zukunft), ONLINE_ORDER (Bestellung, Zukunft). Default: [DIGITAL, PRINT].

---

## DESIGN-PFLICHT: EINKLANG MIT UI-REDESIGN-STRATEGIE

### Verbindliche Design-Grundlage

**Jede UI-Implementierung in diesem Dokument MUSS im Einklang mit der "MenuCard-Pro-UI-Redesign-Anweisung.md" (Stand 13.04.2026) umgesetzt werden.** Diese Anweisung definiert das komplette visuelle System und hat Vorrang bei allen gestalterischen Fragen. Konkret bedeutet das:

### Design-Token-System (Pflicht)

Alle Farben, Schriften, Abstände und Radien kommen ausschließlich aus `src/styles/tokens.css`. Keine hardcodierten Hex-Werte in Komponenten. Die Tokens werden über `tailwind.config.ts` gemappt.

- Akzentfarbe: `--color-primary: #DD3C71`
- Fonts: `--font-heading: Playfair Display` + `--font-body: Inter`
- Marge-Farben: `--color-margin-good/ok/bad` (für Preiskalkulation)
- Übersetzungs-Status: `--color-translate-default/changed/done`
- Badge-Farben: `--color-badge-new/bestseller/signature/vegetarian/vegan`

### Material Symbols (Pflicht)

Alle Icons müssen Google Material Symbols (Outlined) verwenden. Keine Emojis, keine eigenen SVG-Icons. Die `<Icon>` Komponente aus der UI-Redesign-Anweisung ist der einzige Weg, Icons darzustellen.

**Icon-Zuordnung für v2-Konzepte (Ergänzung zum UI-Redesign):**

| v2-Konzept | Material Symbol | Verwendung |
|------------|----------------|------------|
| ProductVariant | `layers` | Varianten-Tab im Editor |
| Variante hinzufügen | `add_circle` | Button im Varianten-Tab |
| Default-Variante | `star` (fill) | Markierung der Standard-Variante |
| Taxonomie | `category` | Taxonomie-Picker |
| Taxonomie-Node | `label` | Einzelner Taxonomie-Chip |
| Region | `location_on` | Region-Taxonomie |
| Rebsorte | `eco` | Rebsorten-Taxonomie |
| Stil | `tune` | Stil-Taxonomie |
| Diät | `restaurant` | Diät-Taxonomie (Vegetarisch etc.) |
| ModifierGroup | `playlist_add` | Beilagen/Extras (Zukunft) |
| StockLevel | `inventory` | Bestand (Zukunft) |
| Bestellsystem | `shopping_cart` | Warenkorb (Zukunft) |
| Verschachtelte Sektion | `subdirectory_arrow_right` | Unter-Sektionen in Kartenverwaltung |

**Bestehende Icon-Zuordnungen aus UI-Redesign bleiben gültig:**

| Bereich | Material Symbol |
|---------|----------------|
| Dashboard | `dashboard` |
| Produkte | `inventory_2` |
| Karten | `menu_book` |
| QR-Codes | `qr_code_2` |
| Bildarchiv | `photo_library` |
| Wein | `wine_bar` |
| Getränk | `local_bar` |
| Speise | `restaurant` |
| Bier | `sports_bar` |
| Kaffee | `coffee` |
| Spirituose | `liquor` |
| Aktiv | `check_circle` (fill) |
| Ausgetrunken | `block` |

### Komponenten-Bibliothek (Pflicht)

Alle neuen UI-Elemente müssen die Basis-Komponenten aus der UI-Redesign-Anweisung verwenden:

- **Buttons:** Primary (`bg-primary`), Secondary, Ghost, Danger – in Größen sm/md/lg
- **Inputs:** `border-border rounded-md`, Focus: `border-primary ring-1`
- **Cards:** `bg-surface rounded-lg shadow-card p-6 border-border-subtle`
- **Badges/Tags:** `px-3 py-1 rounded-full text-xs font-medium` mit Token-Farben
- **Varianten-Card:** Neue Komponente, folgt Card-Pattern mit Marge-Farbcodierung

### Sidebar-Navigation (Pflicht)

Die Sidebar aus dem UI-Redesign (200px, weiß, Material Icons, aktiver Menüpunkt mit rosa Hintergrund) ist verbindlich. Durch v2 ändern sich die Sidebar-Einträge NICHT – die bestehende Navigation (Dashboard, Produkte, Karten, QR-Codes, Bildarchiv, Templates, Einstellungen) deckt alle v2-Konzepte ab. Taxonomie und Varianten werden INNERHALB des Produkt-Bereichs verwaltet, nicht als eigene Sidebar-Einträge.

### Gästeansicht-Templates (Pflicht)

Die 4 Templates aus dem UI-Redesign (Elegant, Modern, Klassisch, Minimal) bleiben die Design-Grundlage. Sie müssen an die v2-Datenstruktur angepasst werden:

- **Varianten-Anzeige:** Glas/Flasche-Preise werden nebeneinander oder untereinander dargestellt (je nach Template-Charakter)
- **Taxonomie-Tags:** Werden als Pill-Badges im Artikeldetail angezeigt (Rebsorte, Region, Stil) – mit Token-Farben
- **Allergene:** Mit Material Symbol Icons + Label (aus UI-Redesign Allergen-Mapping)
- **Verschachtelte Sektionen:** Die Baumtiefe der Kartenstruktur wird je nach Template unterschiedlich visualisiert (Elegant: Einrückung + Linie, Minimal: fette Überschriften, etc.)

**Template "Modern" hat Modifier-Vorbereitung:** Die Visily-Designs zeigen bereits "Extras/Modifikatoren mit Preisen" und "Mengenauswahl + Warenkorb-Button" auf Seite 6. Das passt exakt zum ModifierGroup-Konzept in v2 und wird erst mit dem Bestellsystem aktiviert.

### Dashboard-KPIs (Anpassung)

Die Dashboard-KPIs aus dem UI-Redesign müssen die v2-Struktur widerspiegeln:

| KPI-Kachel | v1 | v2 |
|------------|----|----|
| Produkte | 322 Produkte | "27 Produkte · 42 Varianten" |
| Karten | 9 Karten | Unverändert |
| QR-Scans | 1.247 | Unverändert |
| Sprachen | DE/EN | Unverändert |

### Reihenfolge: Daten zuerst, Design danach

Der Datenbank-Umbau (Phase 1-2) und API-Umbau (Phase 3) erfolgen BEVOR das UI-Redesign umgesetzt wird. Das stellt sicher, dass alle Komponenten von Anfang an auf der v2-Datenstruktur aufbauen. Wenn Admin-UI und Gästeansicht umgebaut werden (Phase 4-5), passiert das bereits mit den Design-Tokens, Material Symbols und Komponenten-Bibliothek aus dem UI-Redesign.

---

## 4. PRISMA-SCHEMA v2 (KOMPLETT)

### 4.1 Enums

```prisma
enum ProductType {
  FOOD
  DRINK
  WINE
  SPIRIT
  BEER
  COFFEE
  OTHER
}

enum ProductStatus {
  ACTIVE
  DRAFT
  ARCHIVED
}

enum HighlightType {
  NONE
  RECOMMENDATION
  NEW
  PREMIUM
  BESTSELLER
  SIGNATURE
}

enum TranslateStatus {
  DEFAULT
  CHANGED
  DONE
}

enum TaxonomyType {
  CATEGORY
  REGION
  GRAPE
  STYLE
  CUISINE
  DIET
  OCCASION
  CUSTOM
}

enum PricingType {
  FIXED
  CALCULATED
  OPEN
}

enum MediaCategory {
  PHOTO
  LOGO
  DOCUMENT
}

enum MediaSource {
  UPLOAD
  PIXABAY
  PEXELS
  WEB
}

enum ProductMediaType {
  LABEL
  BOTTLE
  SERVING
  AMBIANCE
  LOGO
  DOCUMENT
  OTHER
}

enum ChannelType {
  DIGITAL
  PRINT
  POS
  ONLINE_ORDER
  ROOM_SERVICE
}

enum OrderStatus {
  DRAFT
  SUBMITTED
  CONFIRMED
  PREPARING
  READY
  DELIVERED
  CANCELLED
}

enum UserRole {
  OWNER
  ADMIN
  MANAGER
  EDITOR
}
```

### 4.2 Mandant & Standort

```prisma
model Tenant {
  id              String   @id @default(cuid())
  name            String
  slug            String   @unique
  settings        Json?
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt

  locations       Location[]
  products        Product[]
  users           User[]
  media           Media[]
  taxonomyNodes   TaxonomyNode[]
  priceLevels     PriceLevel[]
  fillQuantities  FillQuantity[]
  taxRates        TaxRate[]
  suppliers       Supplier[]
  modifierGroups  ModifierGroup[]
  allergens       Allergen[]
  themes          Theme[]
  languages       TenantLanguage[]
}

model Location {
  id           String   @id @default(cuid())
  tenantId     String
  tenant       Tenant   @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  name         String
  slug         String
  designConfig Json?
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt

  menus        Menu[]
  translations LocationTranslation[]
  stockLevels  StockLevel[]
  orders       Order[]

  @@unique([tenantId, slug])
}

model LocationTranslation {
  id         String   @id @default(cuid())
  locationId String
  location   Location @relation(fields: [locationId], references: [id], onDelete: Cascade)
  language   String   @default("de")
  name       String
  description String?

  @@unique([locationId, language])
}
```

### 4.3 Menü, Sektion, Platzierung

```prisma
model Menu {
  id           String    @id @default(cuid())
  locationId   String
  location     Location  @relation(fields: [locationId], references: [id], onDelete: Cascade)
  slug         String
  type         String
  status       String    @default("ACTIVE")
  sortOrder    Int       @default(0)
  designConfig Json?
  validFrom    DateTime?
  validTo      DateTime?
  createdAt    DateTime  @default(now())
  updatedAt    DateTime  @updatedAt

  sections     MenuSection[]
  translations MenuTranslation[]
  qrCodes      QRCode[]

  @@unique([locationId, slug])
}

model MenuTranslation {
  id          String @id @default(cuid())
  menuId      String
  menu        Menu   @relation(fields: [menuId], references: [id], onDelete: Cascade)
  language    String @default("de")
  name        String
  description String?

  @@unique([menuId, language])
}

model MenuSection {
  id           String        @id @default(cuid())
  menuId       String
  menu         Menu          @relation(fields: [menuId], references: [id], onDelete: Cascade)
  parentId     String?
  parent       MenuSection?  @relation("SectionTree", fields: [parentId], references: [id])
  children     MenuSection[] @relation("SectionTree")
  slug         String
  sortOrder    Int           @default(0)
  depth        Int           @default(0)
  createdAt    DateTime      @default(now())

  placements   MenuPlacement[]
  translations MenuSectionTranslation[]
}

model MenuSectionTranslation {
  id        String      @id @default(cuid())
  sectionId String
  section   MenuSection @relation(fields: [sectionId], references: [id], onDelete: Cascade)
  language  String      @default("de")
  name      String
  description String?

  @@unique([sectionId, language])
}

model MenuPlacement {
  id            String          @id @default(cuid())
  sectionId     String
  section       MenuSection     @relation(fields: [sectionId], references: [id], onDelete: Cascade)
  variantId     String
  variant       ProductVariant  @relation(fields: [variantId], references: [id], onDelete: Cascade)
  sortOrder     Int             @default(0)
  isVisible     Boolean         @default(true)
  highlightType HighlightType   @default(NONE)
  priceOverride Decimal?
  channels      ChannelType[]   @default([DIGITAL, PRINT])
  createdAt     DateTime        @default(now())

  @@unique([sectionId, variantId])
}
```

### 4.4 Produkt (Kern)

```prisma
model Product {
  id            String        @id @default(cuid())
  tenantId      String
  tenant        Tenant        @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  type          ProductType
  status        ProductStatus @default(ACTIVE)
  sku           String?
  highlightType HighlightType @default(NONE)
  supplierId    String?
  supplier      Supplier?     @relation(fields: [supplierId], references: [id])
  createdAt     DateTime      @default(now())
  updatedAt     DateTime      @updatedAt

  variants       ProductVariant[]
  translations   ProductTranslation[]
  wineProfile    ProductWineProfile?
  beverageDetail ProductBeverageDetail?
  productMedia   ProductMedia[]
  taxonomy       ProductTaxonomy[]
  allergens      ProductAllergen[]
  tags           ProductTag[]
  modifierGroups ProductModifierGroup[]
  customFields   ProductCustomFieldValue[]

  @@unique([tenantId, sku])
}

model ProductTranslation {
  id                String          @id @default(cuid())
  productId         String
  product           Product         @relation(fields: [productId], references: [id], onDelete: Cascade)
  language          String          @default("de")
  name              String
  shortDescription  String?
  longDescription   String?
  servingSuggestion String?
  recipe            String?
  notes             String?
  translateStatus   TranslateStatus @default(DEFAULT)

  @@unique([productId, language])
}
```

### 4.5 ProductVariant (HERZSTÜCK v2)

```prisma
model ProductVariant {
  id               String          @id @default(cuid())
  productId        String
  product          Product         @relation(fields: [productId], references: [id], onDelete: Cascade)
  fillQuantityId   String?
  fillQuantity     FillQuantity?   @relation(fields: [fillQuantityId], references: [id])
  label            String?
  sku              String?
  sortOrder        Int             @default(0)
  isDefault        Boolean         @default(false)
  isSellable       Boolean         @default(true)
  isStockable      Boolean         @default(false)
  conversionFactor Decimal?
  conversionBaseId String?
  conversionBase   ProductVariant? @relation("VariantConversion", fields: [conversionBaseId], references: [id])
  derivedVariants  ProductVariant[] @relation("VariantConversion")
  status           ProductStatus   @default(ACTIVE)
  createdAt        DateTime        @default(now())
  updatedAt        DateTime        @updatedAt

  prices             VariantPrice[]
  placements         MenuPlacement[]
  stockLevels        StockLevel[]
  recipeAsResult     RecipeComponent[] @relation("RecipeResult")
  recipeAsIngredient RecipeComponent[] @relation("RecipeIngredient")
  orderLines         OrderLine[]

  @@unique([productId, fillQuantityId])
}

model VariantPrice {
  id             String         @id @default(cuid())
  variantId      String
  variant        ProductVariant @relation(fields: [variantId], references: [id], onDelete: Cascade)
  priceLevelId   String
  priceLevel     PriceLevel     @relation(fields: [priceLevelId], references: [id])
  costPrice      Decimal?
  fixedMarkup    Decimal?
  percentMarkup  Decimal?
  sellPrice      Decimal
  pricingType    PricingType    @default(FIXED)
  taxRateId      String?
  taxRate        TaxRate?       @relation(fields: [taxRateId], references: [id])
  createdAt      DateTime       @default(now())
  updatedAt      DateTime       @updatedAt

  @@unique([variantId, priceLevelId])
}
```

### 4.6 Taxonomie

```prisma
model TaxonomyNode {
  id        String       @id @default(cuid())
  tenantId  String
  tenant    Tenant       @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  name      String
  slug      String
  type      TaxonomyType
  parentId  String?
  parent    TaxonomyNode?  @relation("TaxonomyTree", fields: [parentId], references: [id])
  children  TaxonomyNode[] @relation("TaxonomyTree")
  depth     Int          @default(0)
  sortOrder Int          @default(0)
  icon      String?

  products     ProductTaxonomy[]
  translations TaxonomyNodeTranslation[]

  @@unique([tenantId, type, slug])
}

model TaxonomyNodeTranslation {
  id       String       @id @default(cuid())
  nodeId   String
  node     TaxonomyNode @relation(fields: [nodeId], references: [id], onDelete: Cascade)
  language String       @default("de")
  name     String

  @@unique([nodeId, language])
}

model ProductTaxonomy {
  productId String
  product   Product      @relation(fields: [productId], references: [id], onDelete: Cascade)
  nodeId    String
  node      TaxonomyNode @relation(fields: [nodeId], references: [id], onDelete: Cascade)
  isPrimary Boolean      @default(false)

  @@id([productId, nodeId])
}
```

### 4.7 Weinprofil & Getränkedetail (verschlankt)

```prisma
model ProductWineProfile {
  id            String  @id @default(cuid())
  productId     String  @unique
  product       Product @relation(fields: [productId], references: [id], onDelete: Cascade)
  winery        String?
  vintage       Int?
  aging         String?
  tastingNotes  String?
  servingTemp   String?
  foodPairing   String?
  certification String?
}

model ProductBeverageDetail {
  id             String  @id @default(cuid())
  productId      String  @unique
  product        Product @relation(fields: [productId], references: [id], onDelete: Cascade)
  brand          String?
  alcoholContent Decimal?
  servingStyle   String?
  garnish        String?
  glassType      String?
}
```

### 4.8 Allergene (mit Stammdaten)

```prisma
model Allergen {
  id       String   @id @default(cuid())
  tenantId String
  tenant   Tenant   @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  code     String
  icon     String?

  translations AllergenTranslation[]
  products     ProductAllergen[]

  @@unique([tenantId, code])
}

model AllergenTranslation {
  id         String   @id @default(cuid())
  allergenId String
  allergen   Allergen @relation(fields: [allergenId], references: [id], onDelete: Cascade)
  language   String   @default("de")
  name       String

  @@unique([allergenId, language])
}

model ProductAllergen {
  productId  String
  product    Product  @relation(fields: [productId], references: [id], onDelete: Cascade)
  allergenId String
  allergen   Allergen @relation(fields: [allergenId], references: [id], onDelete: Cascade)
  severity   String?

  @@id([productId, allergenId])
}
```

### 4.9 Modifier (Vorbereitung Bestellsystem)

```prisma
model ModifierGroup {
  id        String @id @default(cuid())
  tenantId  String
  tenant    Tenant @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  name      String
  minSelect Int    @default(0)
  maxSelect Int    @default(1)
  sortOrder Int    @default(0)

  modifiers    Modifier[]
  products     ProductModifierGroup[]
  translations ModifierGroupTranslation[]
}

model ModifierGroupTranslation {
  id       String        @id @default(cuid())
  groupId  String
  group    ModifierGroup @relation(fields: [groupId], references: [id], onDelete: Cascade)
  language String        @default("de")
  name     String

  @@unique([groupId, language])
}

model Modifier {
  id              String        @id @default(cuid())
  groupId         String
  group           ModifierGroup @relation(fields: [groupId], references: [id], onDelete: Cascade)
  name            String
  priceAdjustment Decimal       @default(0)
  sortOrder       Int           @default(0)
  isDefault       Boolean       @default(false)
  isAvailable     Boolean       @default(true)

  translations   ModifierTranslation[]
  orderModifiers OrderLineModifier[]
}

model ModifierTranslation {
  id         String   @id @default(cuid())
  modifierId String
  modifier   Modifier @relation(fields: [modifierId], references: [id], onDelete: Cascade)
  language   String   @default("de")
  name       String

  @@unique([modifierId, language])
}

model ProductModifierGroup {
  productId String
  product   Product       @relation(fields: [productId], references: [id], onDelete: Cascade)
  groupId   String
  group     ModifierGroup @relation(fields: [groupId], references: [id], onDelete: Cascade)
  sortOrder Int           @default(0)

  @@id([productId, groupId])
}
```

### 4.10 Rezeptkomponenten

```prisma
model RecipeComponent {
  id                  String         @id @default(cuid())
  recipeVariantId     String
  recipeVariant       ProductVariant @relation("RecipeResult", fields: [recipeVariantId], references: [id], onDelete: Cascade)
  ingredientVariantId String
  ingredientVariant   ProductVariant @relation("RecipeIngredient", fields: [ingredientVariantId], references: [id], onDelete: Cascade)
  quantity            Decimal
  unit                String
  role                String?
  sortOrder           Int            @default(0)

  @@unique([recipeVariantId, ingredientVariantId])
}
```

### 4.11 Bestand

```prisma
model StockLevel {
  id         String         @id @default(cuid())
  variantId  String
  variant    ProductVariant @relation(fields: [variantId], references: [id], onDelete: Cascade)
  locationId String
  location   Location       @relation(fields: [locationId], references: [id], onDelete: Cascade)
  quantity   Int            @default(0)
  minStock   Int            @default(0)
  autoHide   Boolean        @default(false)
  updatedAt  DateTime       @updatedAt

  @@unique([variantId, locationId])
}
```

### 4.12 Bestellsystem (nur Schema, kein Code)

```prisma
model Order {
  id          String      @id @default(cuid())
  locationId  String
  location    Location    @relation(fields: [locationId], references: [id])
  status      OrderStatus @default(DRAFT)
  tableNumber String?
  guestNote   String?
  totalAmount Decimal?
  currency    String      @default("EUR")
  language    String      @default("de")
  createdAt   DateTime    @default(now())
  updatedAt   DateTime    @updatedAt

  lines       OrderLine[]
}

model OrderLine {
  id         String         @id @default(cuid())
  orderId    String
  order      Order          @relation(fields: [orderId], references: [id], onDelete: Cascade)
  variantId  String
  variant    ProductVariant @relation(fields: [variantId], references: [id])
  quantity   Int            @default(1)
  unitPrice  Decimal
  totalPrice Decimal
  note       String?
  sortOrder  Int            @default(0)

  modifiers  OrderLineModifier[]
}

model OrderLineModifier {
  id           String    @id @default(cuid())
  orderLineId  String
  orderLine    OrderLine @relation(fields: [orderLineId], references: [id], onDelete: Cascade)
  modifierId   String
  modifier     Modifier  @relation(fields: [modifierId], references: [id])
  priceAtOrder Decimal
}
```

### 4.13 Stammdaten

```prisma
model PriceLevel {
  id        String @id @default(cuid())
  tenantId  String
  tenant    Tenant @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  name      String
  slug      String
  sortOrder Int    @default(0)

  prices    VariantPrice[]

  @@unique([tenantId, slug])
}

model FillQuantity {
  id        String @id @default(cuid())
  tenantId  String
  tenant    Tenant @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  label     String
  slug      String
  volumeMl  Int?
  sortOrder Int    @default(0)

  variants  ProductVariant[]

  @@unique([tenantId, slug])
}

model TaxRate {
  id         String  @id @default(cuid())
  tenantId   String
  name       String
  percentage Decimal

  prices     VariantPrice[]
}

model Supplier {
  id       String @id @default(cuid())
  tenantId String
  tenant   Tenant @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  name     String
  contact  String?

  products Product[]
}
```

### 4.14 Medien

```prisma
model Media {
  id           String        @id @default(cuid())
  tenantId     String
  tenant       Tenant        @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  filename     String
  originalName String?
  title        String?
  mimeType     String
  url          String
  thumbnailUrl String?
  width        Int?
  height       Int?
  sizeBytes    Int?
  alt          String?
  formats      Json?
  category     MediaCategory @default(PHOTO)
  source       MediaSource   @default(UPLOAD)
  sourceUrl    String?
  sourceAuthor String?
  createdAt    DateTime      @default(now())
  updatedAt    DateTime      @updatedAt

  productMedia ProductMedia[]
}

model ProductMedia {
  id        String           @id @default(cuid())
  productId String
  product   Product          @relation(fields: [productId], references: [id], onDelete: Cascade)
  mediaId   String?
  media     Media?           @relation(fields: [mediaId], references: [id])
  mediaType ProductMediaType @default(OTHER)
  url       String?
  alt       String?
  sortOrder Int              @default(0)
  isPrimary Boolean          @default(false)
}
```

### 4.15 Tags, Custom Fields, Auth, Sonstiges

```prisma
model ProductTag {
  id        String  @id @default(cuid())
  productId String
  product   Product @relation(fields: [productId], references: [id], onDelete: Cascade)
  tag       String
}

model ProductCustomFieldValue {
  id        String  @id @default(cuid())
  productId String
  product   Product @relation(fields: [productId], references: [id], onDelete: Cascade)
  fieldKey  String
  value     String

  @@unique([productId, fieldKey])
}

model User {
  id        String   @id @default(cuid())
  tenantId  String
  tenant    Tenant   @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  email     String   @unique
  password  String
  name      String?
  role      UserRole @default(EDITOR)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Theme {
  id        String @id @default(cuid())
  tenantId  String
  tenant    Tenant @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  name      String
  config    Json
  isActive  Boolean @default(false)
}

model TenantLanguage {
  id        String  @id @default(cuid())
  tenantId  String
  tenant    Tenant  @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  language  String
  isDefault Boolean @default(false)

  @@unique([tenantId, language])
}

model QRCode {
  id        String   @id @default(cuid())
  menuId    String?
  menu      Menu?    @relation(fields: [menuId], references: [id], onDelete: SetNull)
  shortCode String   @unique
  label     String?
  isActive  Boolean  @default(true)
  config    Json?
  createdAt DateTime @default(now())
}

model TimeRule {
  id        String   @id @default(cuid())
  name      String
  menuId    String?
  startTime String?
  endTime   String?
  daysOfWeek Int[]
  isActive  Boolean  @default(true)
}

model AnalyticsEvent {
  id        String   @id @default(cuid())
  tenantId  String
  type      String
  data      Json?
  sessionId String?
  createdAt DateTime @default(now())
}
```

---

## 5. WAS GELÖSCHT WIRD

### Tabellen die entfallen
| Tabelle | Ersetzt durch |
|---------|--------------|
| ProductPrice | ProductVariant + VariantPrice |
| ProductGroup | TaxonomyNode + ProductTaxonomy |

### Felder die aus ProductWineProfile entfallen
| Feld | Wohin |
|------|-------|
| country | TaxonomyNode (type: REGION) |
| region | TaxonomyNode (type: REGION, Unterkategorie) |
| subRegion | TaxonomyNode (type: REGION, tiefere Ebene) |
| grapeVarieties | TaxonomyNode (type: GRAPE) |
| wineStyle | TaxonomyNode (type: STYLE) |
| wineColor | TaxonomyNode (type: CATEGORY → Weißwein/Rotwein/Rosé) |

### Alte MenuItem-Reste (falls noch vorhanden)
Alle alten Tabellen aus dem MenuItem-Modell müssen endgültig entfernt sein: MenuItem, MenuItemTranslation, PriceVariant, etc. (laut Strategie v1 am 10.04.2026 bereits entfernt – auf Server verifizieren).

---

## 6. SEED-DATEN v2

### 6.1 Stammdaten (immer zuerst)

**14 EU-Allergene** (mit DE + EN Übersetzung):
| Code | DE | EN |
|------|----|----|
| A | Glutenhaltiges Getreide | Cereals containing gluten |
| B | Krebstiere | Crustaceans |
| C | Eier | Eggs |
| D | Fisch | Fish |
| E | Erdnüsse | Peanuts |
| F | Soja | Soybeans |
| G | Milch/Laktose | Milk/Lactose |
| H | Schalenfrüchte | Tree nuts |
| L | Sellerie | Celery |
| M | Senf | Mustard |
| N | Sesam | Sesame |
| O | Sulfite | Sulphites |
| P | Lupinen | Lupin |
| R | Weichtiere | Molluscs |

**4 Preisebenen:** Restaurant, Bar, Room Service, Einkauf

**18 Füllmengen:** Flasche 0,75l (750ml), Flasche 0,375l (375ml), Flasche 1,5l (1500ml), Karaffe 0,5l (500ml), Glas 0,125l (125ml), Glas 0,2l (200ml), 1/8 offen (125ml), 1/4 offen (250ml), Glas 2cl (20ml), Glas 4cl (40ml), Glas 0,3l (300ml), Glas 0,5l (500ml), Dose 0,33l (330ml), Dose 0,5l (500ml), Portion, Espresso (30ml), Tasse (200ml), Standard (null)

**2 Steuersätze:** Getränke 20%, Speisen 10%

### 6.2 Taxonomie-Grundstruktur

```
CATEGORY (Hauptkategorien):
├── Speisen
│   ├── Vorspeisen
│   ├── Suppen
│   ├── Hauptgerichte
│   ├── Desserts
│   └── Käse & Obst
├── Wein
│   ├── Weißwein
│   ├── Rotwein
│   ├── Roséwein
│   └── Schaumwein
├── Cocktails
│   ├── Klassiker
│   └── Signature
├── Spirituosen
│   ├── Gin
│   ├── Whisky
│   ├── Rum
│   └── Edelbrände
├── Bier
│   ├── Fassbier
│   └── Flaschenbier
├── Alkoholfrei
│   ├── Softdrinks
│   └── Säfte
└── Heiße Getränke
    ├── Kaffee
    └── Tee

REGION:
├── Österreich
│   ├── Niederösterreich
│   │   ├── Wachau
│   │   ├── Kamptal
│   │   ├── Kremstal
│   │   └── Traisental
│   ├── Burgenland
│   │   ├── Neusiedlersee
│   │   └── Mittelburgenland
│   ├── Steiermark
│   │   └── Südsteiermark
│   └── Wien
├── Frankreich
│   ├── Champagne
│   ├── Bordeaux
│   └── Provence
├── Italien
│   ├── Venetien
│   ├── Toskana
│   └── Südtirol
└── Spanien
    └── Rías Baixas

GRAPE (Rebsorten):
├── Grüner Veltliner
├── Riesling
├── Sauvignon Blanc
├── Chardonnay
├── Muskateller
├── Pinot Blanc (Weißburgunder)
├── Welschriesling
├── Zweigelt
├── Blaufränkisch
├── St. Laurent
├── Pinot Noir (Spätburgunder)
├── Cabernet Sauvignon
└── Merlot

STYLE:
├── Trocken
├── Halbtrocken
├── Lieblich
├── Brut
└── Extra Brut

DIET:
├── Vegetarisch
├── Vegan
├── Glutenfrei
└── Laktosefrei

CUISINE:
├── Österreichisch
├── Italienisch
├── Französisch
└── International
```

### 6.3 Testprodukte (25-30 Stück)

**Speisen (8):**
1. Rindscarpaccio – 1 Variante (Portion), Allergene: O (Sulfite), Taxonomie: Vorspeise, Österreichisch
2. Kürbiscremesuppe – 1 Variante (Portion), Allergene: G (Milch), Taxonomie: Suppe, Vegetarisch
3. Wiener Schnitzel – 1 Variante (Portion), Allergene: A, C, Taxonomie: Hauptgericht, Österreichisch (+ ModifierGroup "Beilage")
4. Rinderfilet – 1 Variante (Portion), Taxonomie: Hauptgericht, Österreichisch
5. Gebratener Saibling – 1 Variante (Portion), Allergene: D, Taxonomie: Hauptgericht
6. Spinatknödel – 1 Variante (Portion), Allergene: A, C, G, Taxonomie: Hauptgericht, Vegetarisch
7. Topfenstrudel – 1 Variante (Portion), Allergene: A, C, G, Taxonomie: Dessert, Österreichisch
8. Schokoladenkuchen – 1 Variante (Portion), Allergene: A, C, G, H, Taxonomie: Dessert

**Weine (10):**
9. Grüner Veltliner Federspiel Domäne Wachau 2023 – 2 Varianten (Glas 0,125l + Flasche 0,75l), WineProfile: winery=Domäne Wachau, vintage=2023, Taxonomie: Weißwein, Wachau, Grüner Veltliner, Trocken, Österreich
10. Riesling Smaragd Hirtzberger 2022 – 2 Varianten, Taxonomie: Weißwein, Wachau, Riesling, Trocken
11. Sauvignon Blanc Südsteiermark Tement 2023 – 2 Varianten, Taxonomie: Weißwein, Südsteiermark, Sauvignon Blanc
12. Chardonnay Reserve Velich 2021 – 2 Varianten, Taxonomie: Weißwein, Neusiedlersee, Chardonnay
13. Zweigelt Klassik Umathum 2022 – 2 Varianten, Taxonomie: Rotwein, Neusiedlersee, Zweigelt
14. Blaufränkisch Ried Hochberg Moric 2021 – 2 Varianten, Taxonomie: Rotwein, Mittelburgenland, Blaufränkisch
15. Pinot Noir Tatschler Bründlmayer 2021 – 2 Varianten, Taxonomie: Rotwein, Kamptal, Pinot Noir
16. Rosé vom Zweigelt Pittnauer 2023 – 2 Varianten, Taxonomie: Roséwein, Neusiedlersee, Zweigelt
17. Schlumberger Sparkling Brut – 2 Varianten (Glas + Flasche), Taxonomie: Schaumwein, Österreich, Brut
18. Veuve Clicquot Brut – 2 Varianten, Taxonomie: Schaumwein, Champagne, Frankreich

**Cocktails (4):**
19. Aperol Spritz – 1 Variante (Glas), RecipeComponents: Aperol 6cl + Prosecco 9cl + Soda 3cl, Taxonomie: Cocktails, Klassiker
20. Mojito – 1 Variante (Glas), RecipeComponents: Rum 5cl + Limette + Minze + Soda, Taxonomie: Cocktails, Klassiker
21. Negroni – 1 Variante (Glas), RecipeComponents: Gin 3cl + Campari 3cl + Vermouth 3cl, Taxonomie: Cocktails, Klassiker
22. Sonnblick Signature – 1 Variante (Glas), Taxonomie: Cocktails, Signature

**Bier (2):**
23. Stiegl Goldbräu – 2 Varianten (Glas 0,3l + Glas 0,5l), Taxonomie: Bier, Fassbier
24. Edelweiss Hefeweizen – 2 Varianten (Glas 0,3l + Glas 0,5l), Taxonomie: Bier, Fassbier

**Sonstige Getränke (3):**
25. Espresso – 1 Variante (Espresso), Taxonomie: Heiße Getränke, Kaffee (+ ModifierGroup "Extras": Extra Shot +0,50€)
26. Almdudler – 1 Variante (Glas 0,3l), Taxonomie: Alkoholfrei, Softdrinks
27. Apfelsaft naturtrüb – 2 Varianten (Glas 0,2l + Glas 0,5l), Taxonomie: Alkoholfrei, Säfte

**Zusammenfassung:** 27 Produkte, ~42 Varianten, ~60 Preise, 10 Weinprofile, alle Allergene zugeordnet, vollständige Taxonomie.

### 6.4 Testkarten (3)

**Abendkarte** (Location: Restaurant, type: FOOD):
```
├── Vorspeisen
│   ├── Rindscarpaccio (Portion)
│   └── Kürbiscremesuppe (Portion)
├── Hauptgerichte
│   ├── Wiener Schnitzel (Portion)
│   ├── Rinderfilet (Portion)
│   ├── Gebratener Saibling (Portion)
│   └── Spinatknödel (Portion)
└── Desserts
    ├── Topfenstrudel (Portion)
    └── Schokoladenkuchen (Portion)
```

**Weinkarte** (Location: Restaurant, type: WINE):
```
├── Österreich
│   ├── Weißwein
│   │   ├── Grüner Veltliner
│   │   │   └── Domäne Wachau Federspiel (Glas + Flasche)
│   │   ├── Riesling
│   │   │   └── Hirtzberger Smaragd (Glas + Flasche)
│   │   ├── Sauvignon Blanc
│   │   │   └── Tement Südsteiermark (Glas + Flasche)
│   │   └── Chardonnay
│   │       └── Velich Reserve (Glas + Flasche)
│   ├── Rotwein
│   │   ├── Zweigelt
│   │   │   └── Umathum Klassik (Glas + Flasche)
│   │   ├── Blaufränkisch
│   │   │   └── Moric Hochberg (Glas + Flasche)
│   │   └── Pinot Noir
│   │       └── Bründlmayer Tatschler (Glas + Flasche)
│   ├── Rosé
│   │   └── Pittnauer Rosé (Glas + Flasche)
│   └── Schaumwein
│       └── Schlumberger Brut (Glas + Flasche)
├── Frankreich
│   └── Champagne
│       └── Veuve Clicquot Brut (Glas + Flasche)
```

**Barkarte** (Location: Bar & Lounge, type: BAR):
```
├── Cocktails
│   ├── Aperol Spritz (Glas)
│   ├── Mojito (Glas)
│   ├── Negroni (Glas)
│   └── Sonnblick Signature (Glas)
├── Bier
│   ├── Stiegl Goldbräu (0,3l + 0,5l)
│   └── Edelweiss Hefeweizen (0,3l + 0,5l)
├── Wein offen
│   ├── GV Federspiel (Glas) ← gleicher Wein wie in Weinkarte!
│   └── Rosé Pittnauer (Glas)
├── Alkoholfrei
│   ├── Almdudler (0,3l)
│   └── Apfelsaft (0,2l + 0,5l)
└── Kaffee
    └── Espresso
```

---

## 7. API-ÄNDERUNGEN

### Bestehende APIs die angepasst werden müssen

**`GET/PATCH /api/v1/products/[id]`**
- Response enthält jetzt `variants[]` statt `prices[]`
- Jede Variant hat ihre eigenen `prices[]`
- Include: `variants.prices`, `variants.fillQuantity`, `taxonomy.node`

**`POST /api/v1/products`**
- Body enthält `variants[]` Array
- Mindestens eine Variante (isDefault: true)
- Preise werden auf Varianten-Ebene gesetzt

**`GET /api/v1/menus/[id]`**
- Placements referenzieren jetzt `variantId` statt `productId`
- Include: `variant.product.translations`, `variant.prices`, `variant.fillQuantity`

**`PATCH /api/v1/placements/[id]`**
- `variantId` statt `productId` im Body

### Neue APIs

**`GET /api/v1/taxonomy`**
- Query: `?type=CATEGORY&parentId=xxx`
- Response: Hierarchische Baumstruktur

**`POST /api/v1/products/[id]/variants`**
- Neue Variante zu Produkt hinzufügen

**`PATCH /api/v1/variants/[id]`**
- Variante bearbeiten (Preis, Status, Füllmenge)

### Gästeansicht-API
Die öffentlichen Routen müssen auf die neue Struktur umgestellt werden:
- Kartenansicht: `include variant.product.translations, variant.prices`
- Artikeldetail: `include variant.product.wineProfile, variant.product.taxonomy.node`
- Filter: Queries über `ProductTaxonomy` statt über `ProductWineProfile`-Felder
- Suche: Unverändert (sucht in ProductTranslation.name, .shortDescription)

---

## 8. ADMIN-UI-ÄNDERUNGEN

**WICHTIG: Alle UI-Änderungen in diesem Abschnitt MÜSSEN die Design-Tokens, Material Symbols und Komponenten-Bibliothek aus der UI-Redesign-Anweisung verwenden. Siehe Abschnitt "DESIGN-PFLICHT" oben.**

### 8.1 Produkt-Editor

**Neuer Tab: "Varianten"** (Icon: `layers`)
Zwischen "Übersetzungen" und "Bilder". Verwendet `Card`-Komponente mit `shadow-card`, Marge-Farbcodierung aus Tokens (`--color-margin-good/ok/bad`):
```
┌─────────────────────────────────────────────────┐
│ [layers] Varianten                    [+ Neu]   │
│                                                  │
│ ┌──────────────────────────────────────────────┐ │
│ │ [star] Glas 0,125l       SKU: GV-WACH-G     │ │
│ │ Restaurant: VK 5,20€ (EK 1,80€, Marge 65%) │ │  ← --color-margin-good
│ │ Bar: VK 5,80€                               │ │
│ │                   [Bearbeiten] [delete]      │ │  ← Material Symbols
│ └──────────────────────────────────────────────┘ │
│ ┌──────────────────────────────────────────────┐ │
│ │   Flasche 0,75l          SKU: GV-WACH-F     │ │
│ │ Restaurant: VK 28,00€ (EK 10,80€, Marge 61%)│ │  ← --color-margin-ok
│ │ Bar: VK 32,00€                              │ │
│ │                   [Bearbeiten] [delete]      │ │
│ └──────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

Buttons: `[+ Neu]` = Ghost-Button mit `add_circle` Icon. `[Bearbeiten]` = Ghost-Button. `[delete]` = Ghost-Danger mit Doppelbestätigung.

Der "Preise"-Tab wird Teil des Varianten-Editors: Beim Bearbeiten einer Variante öffnet sich die Kalkulationskette (EK → Fix → % → VK) pro Preisebene – identische UX wie bisher, nur auf Varianten-Ebene.

**Statt "Produktgruppe" Dropdown: Taxonomie-Picker** (Icon: `category`)
Multi-Select mit Pill-Badges (`rounded-full`) in Token-Farben. Pro TaxonomyType eine Zeile:
```
[category] Kategorien: [Weißwein ✕] [+ hinzufügen]     ← Pill bg-primary-light text-primary
[location_on] Regionen: [Österreich ✕] [Wachau ✕] [+]  ← Pill bg-info-light text-info
[eco] Rebsorten:  [Grüner Veltliner ✕] [+]             ← Pill bg-success-light text-success
[tune] Stil:      [Trocken ✕] [+]                       ← Pill bg-warning-light text-warning
```

Beim Klick auf `[+]` öffnet sich ein Dropdown/Autocomplete mit bestehenden TaxonomyNodes. Option "Neu anlegen" am Ende der Liste.

### 8.2 Produktliste (List-Panel)

Verwendet das List-Panel-Layout aus der UI-Redesign-Anweisung (resizable, Suche + Filter oben). Zeigt pro Produkt:
- Material Symbol für Typ (`wine_bar`, `restaurant`, `local_bar`, `coffee`, `sports_bar`, `liquor`)
- Produktname (Font: `--font-body`, `--text-sm`, `--font-medium`)
- Varianten-Anzahl als Badge (`--text-xs`, `--color-text-muted`)
- Status-Badge: Active = `check_circle` grün, Draft = `edit_note` grau, Archived = `archive` muted
- Thumbnail 32×32 (Thumb-Format), Fallback: Typ-Icon in farbigem Kreis

### 8.3 Kartenverwaltung

**Produktpool:** Zeigt ProductVariants statt Products. Jede Variante zeigt Produktname + Varianten-Label (z.B. "GV Federspiel · Glas 0,125l"). Filter-Dropdowns basieren auf Taxonomie (Kategorie, Region, etc.) statt auf ProductGroup.

**Drag & Drop:** Varianten werden in Sektionen gezogen, nicht Produkte. Animation und Interaktion bleiben wie in v1 (animierte Gap-Insertion, ✕ oder Zurückziehen zum Entfernen, rote Markierung).

**Verschachtelte Sektionen:** Der Karten-Editor zeigt Sektionen als einrückbare Baumstruktur. Icon `subdirectory_arrow_right` für Unter-Sektionen. "Sektion hinzufügen" Button bei jeder Sektion für Kind-Sektionen. Maximale Tiefe: 4 Ebenen.

### 8.4 Gästeansicht

**WICHTIG: Alle 4 Templates (Elegant, Modern, Klassisch, Minimal) aus der UI-Redesign-Anweisung bleiben die Grundlage. Die v2-Datenstruktur ändert die Datenquelle, nicht das visuelle Design.**

**Kartenansicht:** Variant-Label wird als Zusatzinfo angezeigt (z.B. "Glas 0,125l" / "Flasche 0,75l" unter dem Produktnamen). Preis kommt aus `VariantPrice`. Bei mehreren Varianten desselben Produkts auf einer Karte: nebeneinander anzeigen (Template-abhängig).

**Verschachtelte Sektionen:** Werden je nach Template unterschiedlich visualisiert:
- Elegant: Einrückung mit feiner Linie links, Sektionsname in `--font-heading`
- Modern: Große Bild-Header pro Top-Sektion, Sub-Sektionen als Tabs
- Klassisch: Nummerierte Sektionen (I, II, III...) mit Kursiv-Untertiteln
- Minimal: Fette Überschriften in aufsteigender Größe, kein visueller Container

**Filter:** Taxonomie-basierte Pill-Filter (scrollbar horizontal), ersetzt WineProfile-basierte Filter. Farben aus Tokens.

**Artikeldetail:** Taxonomie-Tags als Pill-Badges (Rebsorte, Region, Stil, Diät). Allergene mit Material Symbol Icons + Label. Alle Varianten mit Preisen aufgelistet.

---

## 9. IMPLEMENTIERUNGS-REIHENFOLGE

**Reihenfolge-Prinzip:** Datenbank und APIs zuerst (Phase 1-3), dann UI mit Design-System (Phase 4-5). Die UI-Phasen werden GEMEINSAM mit dem UI-Redesign umgesetzt – nicht erst v2-Funktionalität bauen und danach restylen, sondern direkt mit Tokens, Material Symbols und Komponenten-Bibliothek.

### Phase 0: Design-Foundation (vor Phase 4)
0a. `src/styles/tokens.css` erstellen → BENUTZER FREIGABE EINHOLEN
0b. `tailwind.config.ts` Token-Mapping
0c. `<Icon>` Komponente erstellen (Material Symbols)
0d. Material Symbols CDN + Google Fonts (Playfair Display, Inter, Montserrat) einbinden
0e. Button, Input, Card, Badge Basis-Komponenten bauen

**Phase 0 kann parallel zu Phase 1-3 laufen, muss aber VOR Phase 4 abgeschlossen sein.**

### Phase 1: Datenbank-Umbau (1 Session)
1. Backup erstellen: `pg_dump ... > /root/menucard-pre-v2-$(date +%Y%m%d).sql`
2. Alle Testdaten löschen (Placements, Prices, WineProfiles, Products, etc.)
3. Alte Tabellen entfernen (ProductPrice, ProductGroup, etc.)
4. Prisma-Schema komplett ersetzen (schema.prisma)
5. `npx prisma db push`
6. Verifizieren: `npx prisma studio`

### Phase 2: Seed v2 (1 Session)
7. Allergen-Stammdaten seeden
8. Stammdaten seeden (PriceLevels, FillQuantities, TaxRates)
9. Taxonomie-Grundstruktur seeden
10. 27 Testprodukte mit Varianten, Preisen, Übersetzungen, Taxonomie seeden
11. 3 Testkarten mit verschachtelten Sektionen und Placements seeden
12. QR-Codes für Testkarten anlegen
13. Verifizieren: Alle Daten in Prisma Studio prüfen

### Phase 3: API-Umbau (2-3 Sessions)
14. Products API auf Varianten-Modell umstellen
15. Placements API: variantId statt productId
16. Taxonomy API (CRUD) bauen
17. Variants API (CRUD) bauen
18. Gästeansicht-Queries auf neue Struktur umstellen
19. Translate API anpassen (unverändert, nur auf Product-Ebene)

### Phase 4: Admin-UI anpassen (3-4 Sessions)
20. Produkt-Editor: Varianten-Tab
21. Produkt-Editor: Taxonomie-Picker (ersetzt Produktgruppen-Dropdown)
22. Produktliste: Varianten-Anzeige
23. Kartenverwaltung: Varianten statt Produkte im Pool
24. Kartenverwaltung: Verschachtelte Sektionen
25. Preiseditor: In Varianten-Editor integrieren (Kalkulationskette)

### Phase 5: Gästeansicht anpassen (1-2 Sessions)
26. Kartenansicht: Varianten-Anzeige mit Preisen
27. Artikeldetail: Alle Varianten, Taxonomie-Tags
28. Filter: Taxonomie-basiert statt WineProfile-basiert
29. Suche: Unverändert (sucht in Translations)

### Phase 6: Build & Deploy
30. `npm run build && pm2 restart menucard-pro`
31. Alle Karten und Funktionen testen
32. Git commit + push

---

## 10. TECHNISCHE HINWEISE

### Prisma-Queries: Typische Includes

**Produkt mit allem:**
```typescript
const product = await prisma.product.findUnique({
  where: { id },
  include: {
    translations: true,
    variants: {
      include: {
        fillQuantity: true,
        prices: { include: { priceLevel: true, taxRate: true } },
      },
      orderBy: { sortOrder: 'asc' },
    },
    wineProfile: true,
    beverageDetail: true,
    taxonomy: { include: { node: true } },
    allergens: { include: { allergen: { include: { translations: true } } } },
    productMedia: { include: { media: true }, orderBy: { sortOrder: 'asc' } },
  },
});
```

**Kartenansicht (öffentlich):**
```typescript
const menu = await prisma.menu.findUnique({
  where: { locationId_slug: { locationId, slug } },
  include: {
    translations: true,
    sections: {
      where: { parentId: null }, // Nur Top-Level
      orderBy: { sortOrder: 'asc' },
      include: {
        translations: true,
        children: {
          orderBy: { sortOrder: 'asc' },
          include: {
            translations: true,
            children: { // Bis zu 3 Ebenen tief
              orderBy: { sortOrder: 'asc' },
              include: {
                translations: true,
                placements: {
                  where: { isVisible: true },
                  orderBy: { sortOrder: 'asc' },
                  include: {
                    variant: {
                      include: {
                        product: { include: { translations: true } },
                        fillQuantity: true,
                        prices: {
                          where: { priceLevel: { slug: 'restaurant' } },
                        },
                      },
                    },
                  },
                },
              },
            },
            placements: { /* same as above */ },
          },
        },
        placements: { /* same as above */ },
      },
    },
  },
});
```

### Bestehende Config (nicht ändern)
- `next.config.mjs` (nicht .ts!)
- Sharp `sharp@0.33.2`
- Nginx: `client_max_body_size 10M`
- PM2 Prozessname: `menucard-pro`
- NextAuth Route: `/api/auth/[...nextauth]/`

### Technische Learnings (aus v1 übernommen)
- TypeScript `Set` iteration: `Array.from(new Set(...))` statt `[...new Set(...)]`
- PowerShell: `&&` funktioniert nicht → Semikolon `;` verwenden
- Bash `!` in Strings: einfache Anführungszeichen oder `\!`
- Sharp: `.rotate()` für Auto-EXIF, `.webp()` für Konvertierung
- Drag & Drop: `useRef` für State im Drop-Handler
- `.next` Cache löschen bei hartnäckigen Problemen: `rm -rf .next`

---

## 11. GLOSSAR (Terminologie)

| Begriff | Bedeutung |
|---------|-----------|
| Product | Abstraktes Produkt ("Grüner Veltliner Schlumberger 2023") |
| ProductVariant | Verkäufliche Einheit ("Glas 0,125l" oder "Flasche 0,75l") |
| VariantPrice | Preis einer Variante auf einer Preisebene |
| TaxonomyNode | Klassifizierungsknoten (Kategorie, Region, Rebsorte, etc.) |
| MenuPlacement | Zuordnung einer Variante zu einer Kartensektion |
| MenuSection | Abschnitt in einer Karte (verschachtelbar) |
| ModifierGroup | Gruppe von Auswahloptionen (Beilagen, Extras) |
| Modifier | Einzelne Option innerhalb einer ModifierGroup |
| RecipeComponent | Zutat eines zusammengesetzten Produkts |
| StockLevel | Bestand einer Variante an einem Standort |
| Digitale Ansicht | Screen/Browser-Ausgabe (Mobile/Desktop/Embed) – NIEMALS "Online-Karte" |
| Analoge Ansicht | PDF/Print-Ausgabe – NIEMALS "Druckversion" |

---

## 12. ZUKUNFTSPFADE (nach v2 Basis)

| Pfad | Was | Voraussetzung |
|------|-----|---------------|
| Warenwirtschaft | StockLevel aktivieren, Auto-Hide, Umrechnung | ProductVariant (Phase 1) |
| Bestellsystem | Order/OrderLine aktivieren, Warenkorb-UI | ProductVariant + Modifier |
| E-Commerce | Shop-Frontend, Checkout, Zahlung | ProductVariant + Order |
| Multi-Channel | Kanal-spezifische Sichtbarkeit/Preise | ChannelType auf Placement |
| Cocktail-Kalkulation | RecipeComponent befüllen, Auto-VK | ProductVariant + RecipeComponent |
| CSV-Import v2 | Import mit Varianten + Taxonomie-Zuordnung | Taxonomie + Varianten |
| KI-Empfehlungen | Pairings über Taxonomie-Ähnlichkeit | Taxonomie |
| PDF-Export v2 | Templates mit Varianten-Preisen | ProductVariant |

---

## 13. STARTBEFEHL FÜR NEUE COWORK-SESSION

```
Weiter mit MenuCard Pro v2 – Hotel Sonnblick.
Server: 178.104.138.177, GitHub: rexei123/menucard-pro

STATUS: Schema-Umbau auf Produktstrategie v2. Neues Datenmodell mit
ProductVariant (verkäufliche Einheiten), TaxonomyNode (mehrdimensionale
Klassifizierung), verschachtelte MenuSections, Modifier, RecipeComponent,
StockLevel, Order-System (Schema only).

WICHTIG: Lies die Projektdateien:
- "MenuCard-Pro-Strategie-v2.md" → Prisma-Schema, APIs, Implementierung
- "MenuCard-Pro-UI-Redesign-Anweisung.md" → Design-Tokens, Material Symbols, Templates
- "MenuCard-Pro-Bildarchiv-Anweisung.md" → Bildarchiv (nach v2-Umbau)

DESIGN-PFLICHT: Alle UI-Arbeit MUSS die Design-Tokens, Material Symbols
und Komponenten aus der UI-Redesign-Anweisung verwenden.

NÄCHSTER SCHRITT: [hier den aktuellen Schritt aus Phase 0-6 eintragen]
```

---

## 14. VERBUNDENE PROJEKTDATEIEN

| Datei | Zweck | Verhältnis zu diesem Dokument |
|-------|-------|-------------------------------|
| **MenuCard-Pro-UI-Redesign-Anweisung.md** | Design-Tokens, Material Symbols, 4 Gäste-Templates, Komponenten-Bibliothek, Sidebar, Visily-Referenz | **Hat Vorrang bei allen Design-Fragen.** Dieses Dokument definiert WAS gebaut wird, die UI-Redesign-Anweisung definiert WIE es aussieht. |
| **MenuCard-Pro-Bildarchiv-Anweisung.md** | Zentrales Bildarchiv, Upload, Websuche, Crop-Editor, Bildformate | Wird NACH dem v2-Datenbank-Umbau umgesetzt. Media/ProductMedia-Tabellen in diesem Dokument sind kompatibel mit dem Bildarchiv-Plan. |
| **MenuCard-Pro-Chat-Zusammenfassung.md** | Historische Projektzusammenfassung v1 | Archiviert. Dieses Dokument ersetzt die strategischen Abschnitte. |
