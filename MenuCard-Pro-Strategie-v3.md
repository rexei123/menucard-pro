# MenuCard Pro – Strategie v3
## Produktarchitektur, Design-System & Roadmap
### Stand: 17.04.2026 — konsolidiert aus v1-Strategie, v2-Architektur & Design-Strategie 2.0

---

## 1. Produktdefinition

**Produktname:** MenuCard Pro

**Einzeiler:** Eine mandantenfähige Plattform für digitale Speise-, Getränke- und Weinkarten — optimiert für die gehobene Hotellerie und Gastronomie.

**Kernversprechen:** Ein QR-Code, eine URL — die gesamte Karte des Hauses. Immer aktuell, elegant, mehrsprachig, in Echtzeit änderbar. Ohne App-Download, ohne Wartezeit.

**Zielgruppe primär:** Hotel Sonnblick — Restaurant, Bar, Spa, Room Service, Events.

**Zielgruppe sekundär (Skalierung):** Weitere Hotels, Restaurants, Bars im DACH-Raum.

**Abgrenzung:** Kein POS-System, kein Kassensystem, kein Bestellsystem im aktuellen Release. Die v2-Architektur ist so aufgebaut, dass eine spätere Anbindung an Bestell- und Warenwirtschaftssysteme möglich ist.

**Plattformtyp:** Web-Applikation (Next.js), kein nativer App-Download nötig. Admin per Browser, Gästeansicht per Browser.

---

## 2. Projektstatus (Stand 17.04.2026)

### Kennzahlen

| Entität | Anzahl |
|---|---|
| Products | 322 |
| ProductTranslations | 644 (DE + EN) |
| ProductVariants | ~322 (1 Default pro Produkt) |
| VariantPrices | ~298 |
| ProductWineProfiles | 91 |
| ProductBeverageDetails | 137 |
| TaxonomyNodes | ~27 (CATEGORY, REGION, GRAPE, STYLE) |
| Menus | 9 (7 Gourmet EVENT, 1 WINE, 1 BAR) |
| MenuPlacements | 337 (über Varianten) |
| MenuSections | 65 |
| DesignTemplates | 5 (4 SYSTEM, 1 CUSTOM) |
| QRCodes | 10 |
| Locations | 2 |
| Tenants | 1 |
| Users | 1 |

### Release-Status

**v2.0.0 (16.04.2026) — LIVE** unter `https://menu.hotel-sonnblick.at`

Die gesamte Codebasis wurde auf die v2-Architektur migriert. Alle Admin-Seiten, APIs, Gäste-Renderer und Scripts verwenden ausschließlich v2-Modelle. Design-Compliance: 8/8 PASS. SSL, Backups und Monitoring sind aktiv.

### Abgeschlossene Meilensteine

| Version | Datum | Inhalt |
|---|---|---|
| 0.0.x | Apr 2026 | MVP: Admin-Grundgerüst, Gästeansicht, Auth, CRUD |
| 0.1.0 | 04.04. | CSV-Import, Produktbilder in Gästeansicht |
| 0.2.0 | 05.04. | Security-Hardening (Nginx, Rate-Limiting, Header) |
| 0.3.0 | 06.04. | Design-Editor Verfeinerungen |
| 0.4.0 | 08.04. | PDF-Export v2 (react-pdf, Design-Editor, Custom-Templates) |
| 0.5.0 | 10.04. | Bildarchiv (Upload, Galerie, SearXNG-Websuche, Sharp-Pipeline) |
| 0.6.0 | 11.04. | UI-Redesign Phase 1+2 (Design-Tokens, Admin-Sidebar, Dashboard) |
| 0.7.0 | 12.04. | UI-Redesign Phase 3 (4 Gäste-Templates: Elegant, Modern, Classic, Minimal) |
| 0.8.0 | 13.04. | UI-Redesign Phase 4 (Template-Auswahl, Einstellungen, QR-Codes, Bildarchiv) |
| 0.9.0 | 14.04. | SSL/TLS, Domain, HTTPS-Redirect, HSTS |
| 1.0.0 | 14.04. | Stabiler Meilenstein, Dokumentation, Playwright-Tests |
| 2.0.0 | 16.04. | v2-Architektur komplett, Analytics, QR-CRUD, Backup-Strategie |

---

## 3. Architektur (v2)

### Kernprinzip

**Ein Produkt beschreibt, was etwas ist. Eine Variante beschreibt, wie es verkauft wird.**

Das ist der Industriestandard (Square: CatalogItem → CatalogItemVariation, Toast: MenuItem → Variations, Lightspeed: Product → Variation). MenuCard Pro v2 folgt diesem Muster konsequent.

### Datenmodell

```
Tenant (Betrieb)
├── Location (Standort)
│   ├── Menu (Karte)
│   │   ├── MenuSection (Bereich/Kategorie)
│   │   │   ├── MenuPlacement (variantId, sectionId) → Variante einzeln platzierbar
│   │   │   │   ├── sortOrder, isVisible
│   │   │   │   ├── highlightType (RECOMMENDATION, NEW, BESTSELLER, PREMIUM, SIGNATURE, NONE)
│   │   │   │   └── priceOverride (optionaler Preisüberschrieb)
│   │   │   └── MenuSectionTranslation
│   │   ├── MenuTranslation
│   │   └── DesignTemplate (SYSTEM/CUSTOM, config JSON)
│   └── LocationTranslation
│
├── Product (zentrale Datenbank)
│   ├── ProductTranslation (DE + EN, mit Auto-Translate)
│   ├── ProductVariant (isDefault, Füllmenge)
│   │   └── VariantPrice (sellPrice, costPrice, pricingType)
│   ├── ProductWineProfile (Weingut, Jahrgang, Rebsorte, Region, Stil)
│   ├── ProductBeverageDetail (Alkoholgehalt, Serviertemp., Hersteller)
│   ├── ProductAllergen, ProductTag, ProductPairing
│   ├── ProductMedia → Media (Sharp: WebP, thumb/medium/large + 5 Formate)
│   └── ProductTaxonomy → TaxonomyNode (CATEGORY, REGION, GRAPE, STYLE)
│
├── TaxonomyNode (hierarchisch, nach Typ) — ersetzt ProductGroup
├── PriceLevel (4): Restaurant, Bar, Room Service, Einkauf
├── FillQuantity (18): Flasche 0,75l, 1/8 offen, etc.
├── TaxRate (2): Getränke 20%, Speisen 10%
├── Supplier (Lieferanten)
│
├── User (Benutzer) + UserRole (OWNER/ADMIN/MANAGER/EDITOR)
├── Media (Medien mit Formaten: original, 16:9, 4:3, 1:1, 3:4, thumb)
├── QRCode (mit Short-Code-Redirect)
└── AnalyticsEvent (KPIs, Scan-Tracking)
```

### Kern-Änderungen v1 → v2

| v1 | v2 | Begründung |
|---|---|---|
| `ProductPrice` | `ProductVariant` → `VariantPrice` | Varianten mit eigenem sellPrice/costPrice/pricingType — Industriestandard |
| `ProductGroup` | `TaxonomyNode` (type: CATEGORY, REGION, GRAPE, STYLE) | Flexible Hierarchie statt flacher Gruppierung |
| `isHighlight` (boolean) | `highlightType` (enum: RECOMMENDATION, NEW, BESTSELLER, PREMIUM, SIGNATURE, NONE) | Differenzierte Hervorhebung statt Ja/Nein |
| `SOLD_OUT` (Status) | entfernt — nur ACTIVE, DRAFT, ARCHIVED | Sichtbarkeit über `isVisible` auf MenuPlacement |
| `languageCode` | `language` | Konsistenz, DB-Trigger für Rückwärtskompatibilität |
| `product.prices` | `product.variants[].prices[]` | Verschachtelte Struktur für Mehrfachvarianten |
| `MenuPlacement(productId)` | `MenuPlacement(variantId, sectionId)` | Varianten einzeln in verschiedene Sektionen platzierbar |

### Architekturentscheidungen und Begründungen

1. **Monorepo mit Next.js** statt getrennter Frontend/Backend-Repos — schnellere Entwicklung, weniger Deployment-Komplexität, SSR für Gäste-SEO.

2. **Prisma statt Raw SQL** — Typsicherheit, einfache Migrations, automatische TypeScript-Types.

3. **Slug-basiertes Routing** statt ID-basiert für öffentliche URLs — SEO-freundlich, menschenlesbar, stabile QR-Codes.

4. **Übersetzungen als eigene Relationen** statt JSON-Spalten — saubere Abfragen, einfache Erweiterung um neue Sprachen, indexierbar.

5. **Zentrale Produktdatenbank mit Varianten** — Produkte existieren unabhängig von Karten. ProductVariant definiert Verkaufseinheiten. MenuPlacement ordnet Varianten flexibel zu Sektionen zu.

6. **TaxonomyNode statt ProductGroup** — Ein einziges hierarchisches System für Kategorien, Regionen, Rebsorten und Stile. Erweiterbar ohne Schema-Änderung.

7. **Sharp + lokale Speicherung** statt S3/MinIO — WebP-Konvertierung, EXIF-Strip, 6 Formate (original, 16:9, 4:3, 1:1, 3:4, thumb). Einfacher als externe Storage-Anbindung für den aktuellen Umfang.

8. **PM2 + Nginx** statt Docker — direktes Deployment auf Hetzner, weniger Overhead, einfacheres Debugging.

9. **EU-Allergenstandard** als vorkonfigurierte Stammdaten — Rechtssicherheit, sofort einsatzbereit.

---

## 4. Technische Architektur

### Stack

| Schicht | Technologie | Version |
|---|---|---|
| Framework | Next.js (App Router) | 14.2 |
| Sprache | TypeScript | 5.7 |
| Styling | Tailwind CSS | 3.4 |
| Datenbank | PostgreSQL | 15+ |
| ORM | Prisma | 5.22 |
| Auth | NextAuth.js | 4.24 |
| Bilder | Sharp | 0.33 |
| PDF | @react-pdf/renderer | 4.x |
| QR | qrcode (npm) | — |
| Übersetzung | MyMemory API | — |
| Process | PM2 | — |
| Reverse Proxy | Nginx | — |
| Bildersuche | SearXNG (Docker) | — |

### Server

| Parameter | Wert |
|---|---|
| Provider | Hetzner CX22 |
| IP | 178.104.138.177 |
| OS | Ubuntu 24.04 |
| Domain | menu.hotel-sonnblick.at |
| SSL | Let's Encrypt, Auto-Renewal |
| App-Pfad | /var/www/menucard-pro |
| Port | 3000 (intern), 443 (Nginx) |
| GitHub | rexei123/menucard-pro |
| Admin | admin@hotel-sonnblick.at |
| SearXNG | Docker auf 127.0.0.1:8888 |

### Projektstruktur

```
src/
├── app/
│   ├── (public)/                 # Öffentliche Gäste-Seiten
│   │   ├── [tenant]/[location]/[menu]/  # Kartenansicht + /item/[itemId]
│   │   └── q/[code]/             # QR-Short-Code-Redirect
│   ├── auth/login/               # Login-Seite (NextAuth)
│   ├── admin/                    # Admin-Bereich (authentifiziert)
│   │   ├── page.tsx              # Dashboard mit KPI-Kacheln
│   │   ├── items/                # Produkt-Verwaltung
│   │   ├── menus/[id]/           # Karten-Editor
│   │   ├── design/               # Template-Übersicht + Editor
│   │   ├── media/                # Bildarchiv (Upload, Galerie, Websuche)
│   │   ├── qr-codes/             # QR-Code-Verwaltung
│   │   ├── import/               # CSV-Import
│   │   ├── analytics/            # Statistiken & KPIs
│   │   ├── pdf-creator/          # PDF-Layouts
│   │   └── settings/             # Allergene, Sprachen, Theme, Benutzer
│   └── api/v1/                   # REST-API (27+ Endpunkte)
├── components/
│   ├── admin/                    # Admin-Komponenten (19+)
│   ├── templates/                # 4 Gäste-Renderer (elegant, modern, classic, minimal)
│   └── ui/                       # Wiederverwendbare UI-Bausteine
├── lib/                          # Auth, Prisma, PDF, Design-Templates, Utils
├── styles/                       # tokens.css, menu-font.css
└── prisma/schema.prisma          # 40 Modelle/Enums
```

### URL-Struktur

**Gästeansicht (öffentlich):**
```
/q/{shortCode}                                     → QR-Code Redirect
/{tenantSlug}/{locationSlug}/{menuSlug}             → Kartenansicht
/{tenantSlug}/{locationSlug}/{menuSlug}/item/{id}   → Artikeldetail
```

**Admin (geschützt):**
```
/admin                     → Dashboard
/admin/items               → Produktliste (zentrale Datenbank)
/admin/items/{id}          → Produkt-Editor
/admin/menus               → Kartenliste
/admin/menus/{id}          → Karten-Editor mit Variantenpool
/admin/design              → Template-Übersicht (SYSTEM + CUSTOM)
/admin/design/{id}/edit    → Template-Editor (nur CUSTOM editierbar)
/admin/media               → Bildarchiv
/admin/qr-codes            → QR-Verwaltung
/admin/analytics           → Statistiken
/admin/import              → CSV-Import
/admin/pdf-creator         → PDF-Layouts
/admin/settings            → Einstellungen (Allergene, Sprachen, Theme, Benutzer)
```

### Backup-Strategie

| Parameter | Wert |
|---|---|
| Cron-Job | `0 3 * * *` (täglich 03:00 Uhr) |
| Script | `/var/www/menucard-pro/scripts/backup-db.sh` |
| Verzeichnis | `/var/backups/menucard-pro/` |
| Rotation | 7 Tage (ältere automatisch gelöscht) |
| Format | `menucard_pro_YYYY-MM-DD_HHMM.sql.gz` |
| Restore | `bash scripts/restore-db.sh <dateiname>` |
| Log | `/var/backups/menucard-pro/backup.log` |

---

## 5. Design-Strategie 2.0 (verbindlich)

Die Design-Strategie 2.0 ist seit dem 14.04.2026 verbindlich für die gesamte Oberfläche. Compliance-Stand: 8/8 PASS. Jede Änderung an der UI muss diese Regeln einhalten.

### 5.1 Kernprinzipien

1. **Design-Token-System:** Alle Farben, Schriften, Abstände als CSS Custom Properties in `src/styles/tokens.css`. Layout änderbar ohne Komponenten anzufassen.
2. **Material Symbols:** Alle Emojis durch Google Material Symbols (Outlined) ersetzt. Konsistentes, professionelles Icon-System.
3. **4 Gäste-Templates:** Elegant, Modern, Classic, Minimal — jedes mit eigenem Charakter, eigenen Schriften, eigener Farbgebung.
4. **Admin immer Roboto:** Keine Ausnahme.

### 5.2 Farb-System

| Token | Wert | Verwendung |
|---|---|---|
| `--color-primary` | #DD3C71 | Akzentfarbe, aktive Elemente, Links |
| `--color-primary-hover` | #C42D60 | Hover-States |
| `--color-primary-light` | #FDF2F5 | Hintergründe aktiver Sidebar-Elemente |
| `--color-add` | #22C55E (green-500) | Hinzufügen-Buttons |
| `--color-text` | #1A1A1A / #171A1F | Primärtext |
| `--color-text-secondary` | #565D6D | Sekundärtext, Labels |
| `--color-text-muted` | #8E8E8E / #999 | Platzhalter, deaktiviert |
| `--color-border` | #E5E7EB / #DEE1E6 | Rahmen, Trennlinien |
| `--color-success` | #22C55E | Erfolg, aktive Status |
| `--color-error` | #EF4444 | Fehler, Löschen |

### 5.3 Schriftarten-Matrix

| Bereich | Template | Head-Font | Body-Font |
|---|---|---|---|
| Admin-Backend | — | Roboto | Roboto |
| Gäste-Karte | Elegant | Playfair Display | Inter |
| Gäste-Karte | Modern | Montserrat | Montserrat |
| Gäste-Karte | Classic | Playfair Display | Inter |
| Gäste-Karte | Minimal | Space Grotesk | Space Grotesk |

Alle Schriften via `next/font/google` selbst gehostet. Template-Schriften als CSS-Variablen (`--mc-body-font`, `--mc-h1-font`, `--mc-h2-font`, `--mc-price-font`) in den Template-Wrapper injiziert. Wrapper-Klasse `mc-template-root mc-template-{key}` auf jeder öffentlichen Gäste-Seite.

### 5.4 Unverrückbare Design-Regeln

1. **Keine Architektur-/Logik-/Content-Änderungen** beim Design-Arbeiten — nur visuelle Anpassungen (CSS, Schriftarten, Farben).
2. **Material Symbols statt Emojis** — Content-Emojis sind ein Compliance-Verstoß.
3. **Admin-Font immer Roboto** — gilt für alle Admin-Seiten ohne Ausnahme.
4. **`:has()`-Selektoren in `menu-font.css`** nur für Modern und Minimal (Body-Override). Elegant und Classic erben Inter vom Layout.
5. **Classic-Headings: Playfair Display**, nicht Cormorant Garamond (häufiger Fallstrick).
6. **Primärfarbe #DD3C71** — keine amber-, blue- oder andere Akzentfarben im Admin.
7. **Hinzufügen-Buttons: #22C55E** (green-500) — einzige Ausnahme von der Pink-Regel.

### 5.5 Design-Compliance-Workflow

1. Änderung an `src/lib/design-templates/{template}.ts` oder `src/styles/menu-font.css`
2. DB-Reseed: `npx tsx scripts/reseed-system-templates.ts`
3. `npm run build && pm2 restart menucard-pro`
4. Compliance-Lauf: `bash design-compliance-remote.sh <tag>` (Ziel: 8/8 PASS)

Compliance-Pipeline: `design-compliance.mjs` + `design-compliance-remote.sh` auf dem Server, Python-Auswertung zu Excel.

### 5.6 Template-System

**4 SYSTEM-Templates:** Elegant, Modern, Classic, Minimal — nicht editierbar, definiert in `src/lib/design-templates/`.

**CUSTOM-Templates:** Bis zu 6 gleichzeitig aktiv. Werden über Duplicate/Edit aus SYSTEM-Templates erzeugt. Konfiguration als JSON in `DesignTemplate.config` (digital + analog Abschnitte).

**APIs:**
- `GET/POST /api/v1/design-templates` — Liste und Erstellen
- `GET/PATCH/DELETE /api/v1/design-templates/[id]` — Einzelnes Template
- `POST /api/v1/design-templates/[id]/duplicate` — Duplizieren
- `GET/PUT /api/v1/menus/[id]/template` — Template einer Karte zuweisen

**Editor:** `src/components/admin/design-editor.tsx` mit 7 Akkordeons und Live-Vorschau (Digital-Tab + PDF-Tab).

### 5.7 Gäste-Templates im Detail

**Elegant:** Ruhig, hochwertig, Serif-typografisch. Playfair Display + Inter. Kategorie-Karten mit Icon, Thumbnail links (rund), Badges (Klassiker/Vegetarisch/Empfehlung). Artikeldetail mit Header-Bild und Allergene als Icons.

**Modern:** Bildlastig, bold, hoher Kontrast. Montserrat. 2-Spalten Bild-Grid, Card-Layout, Highlight-Badges, vollbreite Produktbilder.

**Classic:** Fine Dining, nummeriert, Storytelling. Playfair Display + Inter. Gangnummern, Versalien-Namen, Kursiv-Beschreibungen, dekorative Sektions-Header.

**Minimal:** Reine Text-Hierarchie, maximale Lesbarkeit. Space Grotesk. Keine Bilder, Tab-Filter, Allergene inline als Codes, Pill-Tags für Eigenschaften.

---

## 6. Admin-Interface

### 6.1 Layout

Drei-Spalten-Layout: Icon-Bar (links, aufklappbar) + List-Panel (resizable) + Workspace.

```
┌──────────┬──────────────────┬─────────────────────────────┐
│ Icon-Bar │   List-Panel     │        Workspace            │
│ (links)  │   (resizable)    │                             │
│          │                  │                             │
│ Dashboard│ Suche + Filter   │  Editor / Detail / Form     │
│ Produkte │                  │                             │
│ Karten   │ Item 1           │  Sticky Save Bar            │
│ QR-Codes │ Item 2           │  Unsaved-Changes Guard      │
│ Bilder   │ Item 3           │                             │
│ Analytics│ ...              │                             │
│ Import   │                  │                             │
│ Design   │                  │                             │
│ PDF      │                  │                             │
│ Settings │                  │                             │
└──────────┴──────────────────┴─────────────────────────────┘
```

### 6.2 Dashboard

KPI-Kacheln (Produkte, Karten, QR-Codes, Bilder), Letzte Änderungen (Timeline), Live-Design Status (aktives Template mit Vorschau/Wechseln), Schnellzugriff (Menü bearbeiten, Design anpassen, Bildarchiv).

### 6.3 Produkt-Editor

Status (ACTIVE/DRAFT/ARCHIVED), Typ (FOOD/WINE/BEVERAGE/COFFEE/BEER/COCKTAIL/SPIRIT), TaxonomyNode-Zuordnung, highlightType-Auswahl, Übersetzungen (DE/EN mit Auto-Translate und Farbstatus), Varianten mit Preiskalkulation (EK → Fix€ → %-Aufschlag → VK, Marge farbcodiert), Weinprofil-Editor, Getränkedetail-Editor, Allergene, Tags, Medien.

### 6.4 Karten-Editor

Drag & Drop Sektionen und Placements. Variantenpool (einzeln platzierbar). isVisible-Toggle (Ausgetrunken). Sortierung per Drag & Drop.

### 6.5 Bildarchiv

4 Tabs: Fotos, Logos, Hochladen, Websuche. Upload mit Drag & Drop (max 4MB, JPEG/PNG/WebP). Sharp-Pipeline erzeugt 6 Formate + 3 Größen. Websuche über SearXNG (Google, Bing, DDG) + Wikimedia Commons + optionale APIs (Pixabay, Pexels). Detailansicht mit Crop-Editor, Metadaten, Produktzuordnung.

### 6.6 Weitere Admin-Seiten

**QR-Codes:** Erstellen mit Karten-Dropdown und automatischem Short-Code. Branding-Farben und Logo. Download als PNG.

**Analytics:** KPI-Karten (Produkte, Karten, QR-Codes, Scans), Typ-/Status-Verteilung, Karten-Statistik-Tabelle, Top-5 QR-Codes.

**CSV-Import:** v2-kompatibel mit TaxonomyNode-Zuordnung, ProductVariant+VariantPrice-Erstellung. Inline-Vorschau und -Bearbeitung vor Import.

**PDF-Creator:** Design-System-konform (Roboto, Material Symbols, Typ-Badges). Karten-PDF-Export über @react-pdf/renderer.

**Einstellungen:** Sub-Navigation (Allergene, Sprachen, Theme, Benutzer). Toggles und System-Status.

---

## 7. Gästeansicht

### 7.1 Kartenansicht

Sektionen mit Produkten und Preisen. Artikeldetail-Seite (alle Produkte klickbar). Volltextsuche inklusive Sektionsname. Filter (Weinstil, Herkunft etc.). Sprachwechsler DE/EN mit Fallback-Logik. QR-Code-Redirect über Short-Codes. Mobile-First, schneller Seitenaufbau.

### 7.2 Preisformatierung

Locale-abhängig: `de-AT` mit Komma (€ 12,50), `en-GB` mit Punkt (€ 12.50). Implementiert in `lib/format-price.ts` via `Intl.NumberFormat`.

### 7.3 Mehrsprachigkeit

Deutsch als Primärsprache, Englisch als Sekundärsprache. Auto-Translate via MyMemory API mit visuellem Farbstatus (grau = nicht übersetzt, orange = automatisch, grün = manuell geprüft). Fallback-Logik: `tr.language || tr.languageCode`.

---

## 8. API-Übersicht

Alle Endpunkte unter `/api/v1/`. Authentifizierung über NextAuth-Session.

| Endpunkt | Methoden | Beschreibung |
|---|---|---|
| `/products` | POST | Produkt erstellen |
| `/products/[id]` | GET, PATCH, DELETE | Einzelnes Produkt |
| `/products/[id]/variants` | GET, POST | Varianten eines Produkts |
| `/products/[id]/media` | GET, POST | Medien eines Produkts |
| `/products/[id]/media/[pmId]` | PATCH, DELETE | Einzelne Produktmedien |
| `/variants/[id]` | PATCH, DELETE | Einzelne Variante |
| `/placements` | GET, POST | Kartenzuordnungen |
| `/placements/[id]` | PATCH, DELETE | Einzelne Zuordnung |
| `/menus` | GET | Kartenliste |
| `/menus/[id]/pdf` | GET | PDF-Export einer Karte |
| `/menus/[id]/template` | GET, PUT | Template einer Karte |
| `/design-templates` | GET, POST | Template-Liste und Erstellen |
| `/design-templates/[id]` | GET, PATCH, DELETE | Einzelnes Template |
| `/design-templates/[id]/duplicate` | POST | Template duplizieren |
| `/media` | GET | Medienliste mit Filtern |
| `/media/[id]` | GET, PATCH, DELETE | Einzelnes Medium |
| `/media/[id]/crop` | PATCH | Format zuschneiden |
| `/media/upload` | POST | Datei-Upload |
| `/media/web-import` | POST | Bild aus dem Web importieren |
| `/media/web-search` | GET, POST | Bildsuche (SearXNG, Wikimedia etc.) |
| `/qr-codes` | GET, POST | QR-Code-Liste und Erstellen |
| `/qr-codes/[id]` | DELETE | QR-Code löschen |
| `/qr-codes/generate` | POST | QR-Bild generieren |
| `/taxonomy` | GET, POST | Taxonomie-Nodes |
| `/translate` | POST | Auto-Translate (MyMemory) |
| `/import` | POST | CSV-Import |
| `/pdf` | POST | PDF-Generierung |

Vollständige Dokumentation mit Payloads und Fehlercodes: `docs/API.md`.

---

## 9. Sicherheit & DSGVO

| Bereich | Maßnahme |
|---|---|
| Passwörter | bcrypt |
| Sessions | HTTP-only, Secure Cookies (NextAuth JWT) |
| Tenant-Isolation | Jede Query filtert nach tenantId |
| Analytics | Keine personenbezogenen Daten, Session-IDs anonymisiert |
| Bilder | Keine EXIF-Daten gespeichert (Sharp `.rotate()` Strip) |
| Nginx | client_max_body_size 10M |
| Nginx Security | Block-Regeln für .git, .env, prisma, .bak, .sh, .sql, .log, node_modules |
| Security-Header | X-Frame-Options, X-Content-Type-Options, X-XSS-Protection, Referrer-Policy, HSTS |
| Rate-Limiting | 10r/s API, 3r/s Login |
| Next.js | poweredByHeader: false |
| SSL | Let's Encrypt, Auto-Renewal |

---

## 10. Qualitätsstandards

- Jede API-Route hat Validierung und Error-Handling
- Alle öffentlichen Seiten sind serverseitig gerendert (SSR)
- Bilder werden per Sharp optimiert (WebP, 6 Formate, 3 Größen)
- Skeleton-Loading für schnelle wahrgenommene Ladezeit
- Unsaved-Changes Guard im Admin verhindert Datenverlust
- Doppelbestätigung bei destruktiven Aktionen (Produkt löschen)
- Auto-Translate mit visuellem Farbstatus
- Design-Compliance-Pipeline (8/8 PASS)
- Tägliches Datenbank-Backup mit 7-Tage-Rotation
- Playwright-Tests (22 Checkpoints)

---

## 11. Deployment & Betrieb

### Workflow

1. Änderungen in Cowork/Claude erstellen
2. PowerShell: `scp` Dateien auf Server
3. SSH: `npm run build && pm2 restart menucard-pro`
4. Bei Schema-Änderungen: `npx prisma db push` vor dem Build
5. Bei Template-Änderungen: `npx tsx scripts/reseed-system-templates.ts` vor dem Build

### Wichtige Befehle

```bash
# SSH
ssh root@178.104.138.177

# Build & Restart
cd /var/www/menucard-pro
npm run build && pm2 restart menucard-pro

# Logs
pm2 logs menucard-pro

# Datenbank
PGPASSWORD=<pw> psql -h 127.0.0.1 -U menucard menucard_pro

# Prisma
npx prisma studio    # DB-Browser
npx prisma db push   # Schema synchronisieren

# Cache leeren
rm -rf .next && npm run build && pm2 restart menucard-pro

# Backup manuell
bash scripts/backup-db.sh

# Restore
bash scripts/restore-db.sh <dateiname>
```

### Arbeitsregeln für Claude

- Immer auf Deutsch, "Sie"-Form, freundlich-professionell
- Autonom arbeiten: Infos selbst beschaffen, Befehle bündeln, Selbstkontrolle vor Rückfragen
- Ein-Shell-Workflow: scp + ssh in einem PowerShell-Befehl
- Backup-Prinzip: Vor Änderungen `cp datei datei.bak`
- TSX-Dateien: Bei größeren Änderungen komplett neu schreiben, keine Regex-Replacements
- Design-Strategie 2.0 ist bei JEDER UI-Änderung einzuhalten

---

## 12. Roadmap: Offene Features

### Priorität Hoch (nächste Schritte)

| Feature | Beschreibung | Komplexität |
|---|---|---|
| Bestellfunktion | Datenmodell vorhanden, UI fehlt. Gäste können direkt über die digitale Karte bestellen. | Hoch |
| Reservierungs-CTA | Link zu Reservierungssystem in der Gästeansicht | Niedrig |
| Embed-Widget / iFrame | `/embed/{tenant}/{menu}` mit schlankem Layout, iFrame-Code-Generator im Admin | Mittel |
| Dark Mode | Dunkles Farbschema für Gästeansicht | Mittel |
| SSH-Key-only Login | Server-Sicherheit härten | Niedrig |

### Priorität Mittel (Funktionserweiterung)

| Feature | Beschreibung | Komplexität |
|---|---|---|
| Bestandsverwaltung | Mindestbestand, automatischer Sold-Out, Lagermengen | Mittel |
| Happy-Hour / Saisonkarten | Zeitsteuerung: Automatische Kartenwechsel nach Tageszeit oder Saison | Mittel |
| Eventkarten | Temporäre Karten für Hochzeiten, Seminare, Feiern | Niedrig |
| Zimmermappe / In-Room-Dining | Room-Service-Ansicht als digitale Zimmermappe | Mittel |
| Massenänderungen | Preise Global/Gruppe/Produkt in einem Schritt ändern | Mittel |
| Pairings-Editor | Speisen-Wein-Zuordnung mit KI-Vorschlägen | Mittel |
| CSV-Export | Karte/Artikel als CSV herunterladen | Niedrig |
| SEO | Meta-Tags, Open Graph, Schema.org Menu | Niedrig |

### Priorität Niedrig (Zukunft)

| Feature | Beschreibung | Komplexität |
|---|---|---|
| Weinlexikon / Glossar | Glossar mit Rebsorten, Regionen, Begriffen | Mittel |
| Analytics v2 | Heatmaps, Conversion-Events, Sprachverteilung, Trends | Hoch |
| POS-Anbindung | Kassenintegration (Datenmodell vorbereitet) | Hoch |
| KI-Empfehlungen | Intelligente Weinvorschläge basierend auf Speisenauswahl | Hoch |
| Multi-Tenant Onboarding | Selbstregistrierung für neue Betriebe | Hoch |
| PDF-Vorlagen v2 | A4, A5, Tischkarte, Barkarte — Template-Auswahl | Mittel |

---

## 13. Dokumentation

Alle fachliche Dokumentation lebt im Repository:

| Datei | Inhalt |
|---|---|
| `CLAUDE.md` | Arbeitsanweisungen, Routen, Architektur, aktueller Datenstand |
| `README.md` | Projektübersicht, Setup-Anleitung, Befehle |
| `CHANGELOG.md` | Versionshistorie ab MVP bis v2.0.0 |
| `docs/API.md` | Alle Endpunkte mit Payloads und Fehlercodes |
| `docs/DATENMODELL.md` | Prisma-Modelle und Enums |
| `docs/DEPLOYMENT.md` | Server-Setup, Backup/Restore, Troubleshooting |

---

## 14. Vision

MenuCard Pro wird die digitale Gastgebermappe des Hotel Sonnblick. Nicht nur eine Karte, sondern ein Informations- und Erlebniskanal zwischen Haus und Gast. Die Plattform soll so selbstverständlich nutzbar sein wie eine gedruckte Karte — aber mit allen Vorteilen digitaler Aktualisierung, Mehrsprachigkeit und Analytik.

**Gästeansicht:** Elegant, ruhig, verkaufsstark. Inspiriert von hochwertigen Printmenüs. Große Typografie, zurückhaltende Farben, hohe Kontraste. Kein visuelles Rauschen. Die Karte muss bei Kerzenlicht auf einem Smartphone genauso gut funktionieren wie am Frühstückstisch auf einem Tablet.

**Admin-Ansicht:** Effizient, übersichtlich, schnell. Der Küchenchef soll in 30 Sekunden ein Gericht als ausverkauft markieren können. Die Rezeptionistin soll die Minibar-Karte ohne Schulung bearbeiten können.

**Architektur:** Zukunftssicher durch v2-Varianten-Modell (Industriestandard), flexibles Taxonomie-System und Design-Token-basiertes Template-System. Die Plattform ist bereit für Bestellfunktion, Warenwirtschaft und Multi-Tenant-Betrieb.
