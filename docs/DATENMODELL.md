# Datenmodell

Prisma-Schema (PostgreSQL) mit 28 Modellen und 12 Enums. Vollständige Quelle: `prisma/schema.prisma`.

## Überblick

```
Tenant ──┬── Location ── Menu ── MenuSection ── MenuPlacement ── Product
         │                        │                                │
         │                        └── QRCode                       ├── ProductTranslation
         ├── User                                                  ├── ProductPrice ── FillQuantity, PriceLevel
         ├── Theme, TenantLanguage                                 ├── ProductWineProfile
         ├── Allergen, Additive, Tag                               ├── ProductBeverageDetail
         ├── ProductGroup (hierarchisch)                           ├── ProductMedia ── Media
         ├── PriceLevel, FillQuantity, TaxRate                     ├── ProductAllergen, ProductTag
         ├── Supplier                                              └── ProductCustomFieldValue
         ├── CustomFieldDefinition
         ├── Media
         └── DesignTemplate (SYSTEM | CUSTOM) ── Menu.templateId
```

Zentrales Prinzip: **Produkte existieren unabhängig von Karten** und werden über `MenuPlacement` einer oder mehreren Kartensektionen zugeordnet. Preise werden pro Füllmenge × Preisebene geführt; `MenuPlacement.priceOverride` erlaubt kartenspezifische Abweichungen.

## Mandant & Standort

### Tenant
Der oberste Container. Jeder Datensatz ist über `tenantId` isoliert.
- `slug` (unique), `name`, `logo`, `website`, `email`, `phone`
- Kaskadiert auf alle abhängigen Modelle (Location, User, Media, Tags, …)

### Location
Physischer Standort (Restaurant, Bar, Spa). Ein Tenant hat 1..n Locations.
- `tenantId + slug` unique, `timezone` (Default Europe/Vienna)
- `designConfig` (Json) für Standort-Branding
- Relations: `LocationTranslation`, `Menu`, `QRCode`, `TimeRule`

### LocationTranslation
Übersetzte Anzeigename/Beschreibung pro `languageCode`.

## Benutzer & Rollen

### User
- `email` unique, `passwordHash` (bcrypt), `firstName`, `lastName`
- Enum `UserRole`: `OWNER` | `ADMIN` | `MANAGER` | `EDITOR`
- `hasMinRole()`-Helper (lib/auth.ts): OWNER 40, ADMIN 30, MANAGER 20, EDITOR 10
- `lastLoginAt` wird bei Login aktualisiert

## Karten

### Menu
Eine Karte gehört zu einer Location und hat einen `type`.
- `locationId + slug` unique
- Enum `MenuType`: `FOOD` | `DRINKS` | `WINE` | `DAILY_SPECIAL` | `SEASONAL` | `BREAKFAST` | `BAR` | `SPA` | `ROOM_SERVICE` | `MINIBAR` | `EVENT`
- `templateId` → `DesignTemplate` (optional, `onDelete: Restrict`)
- `designConfig` (Json) für kartenspezifische Overrides
- `isArchived` für Soft-Delete
- Relations: `MenuTranslation`, `MenuSection`, `QRCode`

### MenuSection
Hierarchische Sektionen (Vorspeisen → Suppen → …).
- `menuId + slug` unique, `parentId` → Self (SectionTree)
- `sortOrder`, `icon`
- Relations: `MenuSectionTranslation`, `MenuPlacement`

### MenuPlacement (Junction)
Ordnet ein Produkt einer Kartensektion zu.
- `menuSectionId + productId` unique (keine Duplikate)
- `priceLevelId`, `fillQuantityId` (optional, für spezifische Variante)
- `priceOverride`, `highlightType`, `isVisible`, `sortOrder`, `notes`

## Produkte

### Product
Zentrale Produktentität, tenant-gebunden.
- `tenantId + sku` unique (SKU-Schema: `SB-XXXX`, auto-generiert)
- Enum `ProductType`: `WINE` | `DRINK` | `FOOD` | `OTHER`
- Enum `ProductStatus`: `ACTIVE` | `SOLD_OUT` | `ARCHIVED` | `DRAFT`
- Enum `HighlightType`: `RECOMMENDATION` | `NEW` | `POPULAR` | `PREMIUM` | `SEASONAL` | `CHEFS_CHOICE`
- `productGroupId`, `taxRateId`, `supplierId`
- `customFields` (Json, frei), `internalNotes`

### ProductTranslation
Pro `languageCode`: `name`, `shortDescription`, `longDescription`, `servingSuggestion`, `internalNotes`.

### ProductPrice
- `productId + fillQuantityId + priceLevelId` unique
- `price`, `purchasePrice`, `fixedMarkup`, `percentMarkup` (alle Decimal(10,2))
- `currency` (Default EUR), `isDefault`

### ProductWineProfile (1:1)
- `winery`, `vintage`, `grapeVarieties[]`, `region`, `country`, `appellation`
- Enums `WineStyle` (RED, WHITE, ROSE, SPARKLING, DESSERT, FORTIFIED, ORANGE, NATURAL)
- Enums `WineBody` (LIGHT, MEDIUM_LIGHT, MEDIUM, MEDIUM_FULL, FULL)
- Enums `WineSweetness` (DRY, OFF_DRY, MEDIUM_DRY, MEDIUM_SWEET, SWEET)
- `bottleSize` (Default "0.75l"), `alcoholContent`, `tastingNotes`, `foodPairing`, `stockQuantity`

### ProductBeverageDetail (1:1)
- `brand`, `producer`, `origin`
- Enum `BeverageCategory`: `BEER`, `SPIRIT`, `COCKTAIL`, `SOFT_DRINK`, `JUICE`, `WATER`, `HOT_DRINK`, `SMOOTHIE`, `OTHER`
- `alcoholContent`, `servingTemp`, `carbonated`

### ProductAllergen, ProductTag (n:m)
Reine Junction-Tables, `@@id([productId, allergenId|tagId])`.

### ProductMedia
- `mediaId` → `Media` (optional: Legacy-URL)
- Enum `ProductMediaType`: `LABEL`, `BOTTLE`, `SERVING`, `AMBIANCE`, `LOGO`, `DOCUMENT`, `OTHER`
- `isPrimary`, `sortOrder`

### ProductPairing
- `sourceId → Product`, `targetId → Product` (unique Paar)
- Enum `PairingType`: `GOES_WELL`, `RECOMMENDED`, `SOMMELIER_CHOICE`

### ProductCustomFieldValue
Wert pro `customFieldDefinitionId` für ein Produkt.

## Stammdaten

### ProductGroup
Hierarchische Warengruppe. `parentId` → Self.
- `defaultTaxRateId` für Steuergruppe
- Relations: `ProductGroupTranslation`, `Product`

### PriceLevel
Preisebene (Restaurant, Bar, Room Service, Einkauf).
- `isInternal` (z.B. Einkauf)
- `surchargePercent` optional

### FillQuantity
Füllmenge (0,75l Flasche, 1/8 offen, 500g, …).
- `tenantId + label` unique

### TaxRate
Steuersatz (z.B. 10 %, 20 % AT).
- `rate` (Float), `isDefault`

### Supplier
Lieferant.
- `contactName`, `email`, `phone`, `website`, `address`, `notes`

### Allergen, Additive, Tag
Jeweils mit eigener Translation-Tabelle.
- `Allergen`: EU 14 Allergene (A bis N) mit Icon und Sortierung
- `Additive`: Zusatzstoffe (z.B. Farbstoff, Konservierungsstoffe)
- `Tag`: frei definierbar (vegan, regional, Bio, …), mit Farbe und Icon

### CustomFieldDefinition
Frei definierbare Zusatzfelder pro Produkt.
- Enum `CustomFieldType`: `TEXT`, `NUMBER`, `BOOLEAN`, `SELECT`, `DATE`, `URL`
- `selectOptions[]` für SELECT-Felder
- `appliesToType` (ProductType)
- `isPublic`, `isFilterable`, `isRequired`

## Medien

### Media
- `filename`, `mimeType`, `url`, `thumbnailUrl`, `width`, `height`, `sizeBytes`
- `formats` (Json): `{ thumb, medium, large }` — Sharp-Pipeline-Output
- Enum `MediaCategory`: `PHOTO`, `LOGO`, `DOCUMENT`
- Enum `MediaSource`: `UPLOAD`, `PIXABAY`, `PEXELS`, `WEB`
- `sourceUrl`, `sourceAuthor` (für Web-Importe)

## Design

### DesignTemplate
Ein Template kann SYSTEM oder CUSTOM sein.
- Enum `TemplateType`: `SYSTEM` | `CUSTOM`
- `baseType`: `elegant`, `modern`, `classic`, `minimal`
- `config` (Json): `{ digital: {...}, analog: {...} }`
- `isArchived` (Soft-Delete)
- SYSTEM-Templates sind nicht löschbar und nicht editierbar, können aber dupliziert werden.

### Theme (Legacy)
Altes globales Theme-Modell pro Tenant.
- `primaryColor`, `accentColor`, `backgroundColor`, `textColor`
- Enum `CardStyle`: `ELEGANT`, `MINIMAL`, `CLASSIC`, `MODERN`, `RUSTIC`
- Wird im MVP zugunsten von `DesignTemplate` weitgehend nicht mehr genutzt.

## QR-Codes

### QRCode
- `shortCode` unique (8–10 Zeichen, Auto-Generierung mit Kollisionsschutz)
- `locationId`, `menuId` (optional)
- `primaryColor`, `bgColor`, `logoUrl` für Branding
- `scans` (Zähler)

Redirect: `/q/{shortCode}` → öffentliche Kartenansicht + AnalyticsEvent `QR_SCAN`.

## Analyse

### AnalyticsEvent
- Enum `EventType`: `QR_SCAN`, `PAGE_VIEW`, `MENU_VIEW`, `ITEM_VIEW`, `SEARCH`, `FILTER`, `PDF_DOWNLOAD`, `EMBED_VIEW`, `CTA_CLICK`
- Indizes auf `(tenantId, createdAt)` und `(eventType, createdAt)`
- `userAgent`, `referrer`, `sessionId`, `language`

## Zeitregeln

### TimeRule
Automatische Sichtbarkeitssteuerung für Karten.
- `startTime`, `endTime`, `daysOfWeek[]` (0–6)
- Vorbereitet für Frühstück/Lunch/Dinner/Happy Hour — UI im MVP noch nicht aktiv.

## Mehrsprachigkeit

### TenantLanguage
Aktive Sprachen pro Tenant mit Default-Kennzeichnung.
- MVP: `de` (default), `en`
- Fallback-Logik: fehlende Übersetzung → Default-Sprache.

Übersetzungstabellen: `LocationTranslation`, `MenuTranslation`, `MenuSectionTranslation`, `ProductTranslation`, `AllergenTranslation`, `AdditiveTranslation`, `TagTranslation`, `ProductGroupTranslation`, `CustomFieldTranslation`.

## Indexierung & Constraints

- Alle Slugs sind pro Parent-Entity unique (`locationId+slug`, `menuId+slug`, …)
- Alle Translation-Tabellen sind `entityId+languageCode` unique
- `MenuPlacement.menuSectionId+productId` unique (keine Doppelzuordnung)
- `AnalyticsEvent`: zwei zusammengesetzte Indizes für Reporting-Performance

## Aktueller Datenstand (14.04.2026)

| Tabelle | Einträge |
|---|---:|
| Tenants | 1 |
| Locations | 2 |
| Users | 1 |
| Menus | 9 |
| MenuSections | 65 |
| MenuPlacements | 337 |
| Products | 322 |
| ProductTranslations | 644 |
| ProductPrices | 298 |
| ProductWineProfiles | 91 |
| ProductBeverageDetails | 137 |
| ProductGroups | 27 |
| PriceLevels | 4 |
| FillQuantities | 18 |
| DesignTemplates | 5 |
| QRCodes | 10 |
