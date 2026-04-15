# MenuCard Pro – Hotel Sonnblick
## Strategiepapier & Produktarchitektur
### Aktualisiert: 10.04.2026

---

## 1. Produktdefinition

**Produktname:** MenuCard Pro (Arbeitstitel)

**Einzeiler:** Eine mandantenfähige SaaS-Plattform für digitale Speise-, Getränke- und Weinkarten – optimiert für die gehobene Hotellerie und Gastronomie.

**Kernversprechen:** Ein QR-Code, eine URL – die gesamte Karte des Hauses. Immer aktuell, elegant, mehrsprachig, in Echtzeit änderbar. Ohne App-Download, ohne Wartezeit.

**Zielgruppe primär:** Hotel Sonnblick – Restaurant, Bar, Spa, Room Service, Events.

**Zielgruppe sekundär (Skalierung):** Weitere Hotels, Restaurants, Bars im DACH-Raum.

**Abgrenzung:** Kein POS-System, kein Kassensystem, kein Bestellsystem im MVP. Architektur erlaubt spätere Anbindung.

**Plattformtyp:** Web-Applikation (Next.js), kein nativer App-Download nötig. Admin per Browser, Gästeansicht per Browser.

---

## 2. Projektstatus (Stand 10.04.2026)

### Kennzahlen
- 322 Produkte in zentraler Produktdatenbank
- 640 Übersetzungen (DE + EN)
- 298 Preise (mit Füllmengen × Preisebenen, EK/Fix/%)
- 91 Weinprofile, 139 Getränkedetails
- 9 Karten: 7 Gourmet-Menüs (EVENT), 1 Weinkarte (WINE), 1 Barkarte (BAR)
- 337 Kartenzuordnungen (MenuPlacement)
- 27 Produktgruppen (hierarchisch)
- 4 Preisebenen, 18 Füllmengen, 2 Steuersätze, 9 QR-Codes

### Rollout-Phase
**Alpha abgeschlossen** – Admin-CRUD, öffentliche Ansicht, Produktdatenbank, Kartenverwaltung LIVE.
**Aktuell in Beta** – PDF-Export, QR-Management funktionsfähig, CSV-Import und Branding-Editor noch offen.

---

## 3. Priorisierte Featureliste

### Phase 1 – MVP (✅ größtenteils abgeschlossen)

| Prio | Feature | Status |
|------|---------|--------|
| P0 | Mandanten-Struktur (Tenant → Standorte → Karten) | ✅ |
| P0 | Admin-Auth & Rollen (Email/Passwort, Owner/Admin/Editor) | ✅ |
| P0 | Kartenverwaltung (CRUD, Drag & Drop, Produktpool) | ✅ |
| P0 | Artikelverwaltung Speisen (Name, Beschreibung, Preis, Allergene, Bild, Tags) | ✅ |
| P0 | Artikelverwaltung Getränke (+ Volumen, Alkoholgehalt, Produzent) | ✅ |
| P0 | Artikelverwaltung Wein (+ Weingut, Jahrgang, Rebsorte, Region, Glas/Flasche) | ✅ |
| P0 | Mehrsprachigkeit DE/EN mit Auto-Translate (MyMemory API) | ✅ |
| P0 | Öffentliche Kartenansicht (Mobile-first, Suche, Filter, Artikeldetail) | ✅ |
| P0 | QR-Code-Generierung (pro Karte, PNG/SVG/PDF Download) | ✅ |
| P0 | Branding/Theming (Logo, Primärfarbe, Akzentfarbe) | ✅ |
| P0 | Zentrale Produktdatenbank (unabhängig von Karten) | ✅ |
| P0 | Preiskalkulation (EK → +Fix€ → ×Aufschlag% → =VK, Marge farbcodiert) | ✅ |
| P0 | Bilder-Upload (Sharp-Optimierung, WebP, 3 Größen, Kategorien) | ✅ |
| P0 | Ausgetrunken-Toggle (isVisible in Gästekarte) | ✅ |
| P1 | PDF-Export (Basis, eine Vorlage A4) | ✅ |
| P1 | CSV-Import | ⬜ offen |
| P1 | Website-Embed (iFrame/JS-Widget) | ⬜ offen |
| P1 | Basis-Analytics (QR-Scans, Seitenaufrufe, Top-Produkte) | ⬜ offen |

### Phase 2 – Erweitert

| Prio | Feature | Status |
|------|---------|--------|
| P2 | PDF-Vorlagen (A4, A5, Tischkarte, Barkarte) mit Template-Auswahl | ⬜ offen |
| P2 | Zeitsteuerung (Frühstück/Lunch/Dinner/Bar/Happy Hour) | ⬜ offen |
| P2 | Dark Mode für Gästeansicht | ⬜ offen |
| P2 | Empfehlungen & Pairings (manuell) | ⬜ offen |
| P2 | Highlight-Badges ("Empfehlung", "Neu", "Premium") | ✅ (auf Product + Placement) |
| P2 | Bestandsverwaltung (optional aktivierbar) | ⬜ offen |
| P2 | Erweiterte Analytics (Sprachverteilung, Trends) | ⬜ offen |
| P2 | Medien-Manager (Bildgalerie pro Tenant) | ✅ (in Produkt-Editor integriert) |
| P2 | Massenänderungen (Global/Gruppe/Produkt) | ⬜ offen |
| P2 | Bilder in Gästekarte anzeigen | ⬜ offen |
| P2 | Bilder als Thumbnails in Produktliste | ⬜ offen |
| P2 | QR-Codes auf neues Admin-Layout (List-Panel + Workspace) | ⬜ offen |
| P2 | Theme-Editor (Farben, Schriften, Live-Vorschau) | ⬜ offen |
| P2 | Domain menu.hotel-sonnblick.at + SSL | ⬜ offen |

### Phase 3 – Premium (ab Launch)

| Prio | Feature | Status |
|------|---------|--------|
| P3 | Weinlexikon / Glossar | ⬜ offen |
| P3 | Eventkarten (Hochzeit, Seminar) | ⬜ offen |
| P3 | Room-Service / In-Room-Dining | ⬜ offen |
| P3 | Reservierungs-CTA | ⬜ offen |
| P3 | KI-gestützte Empfehlungen | ⬜ offen |
| P3 | Bestellfunktion (Vorbereitung) | ⬜ offen |
| P3 | Multi-Tenant Onboarding Flow | ⬜ offen |

---

## 4. Datenmodell (aktuell)

### Entitäten-Übersicht

Das Datenmodell wurde grundlegend überarbeitet. Die ursprüngliche MenuItem-basierte Struktur (Artikel direkt an Sektionen gebunden) wurde durch eine **zentrale Produktdatenbank** mit **MenuPlacement** als Zuordnungsebene ersetzt. Damit können Produkte in mehreren Karten gleichzeitig erscheinen und zentral verwaltet werden.

```
Tenant (Betrieb)
├── Location (Standort)
│   ├── Menu (Karte)
│   │   ├── MenuSection (Bereich/Kategorie)
│   │   │   ├── MenuPlacement (Zuordnung → Product)
│   │   │   │   ├── sortOrder, isVisible (Ausgetrunken)
│   │   │   │   ├── highlightType (Empfehlung/Neu/Premium)
│   │   │   │   └── priceOverride (optionaler Preisüberschrieb)
│   │   │   └── MenuSectionTranslation
│   │   ├── MenuTranslation
│   │   └── QRCode
│   └── LocationTranslation
│
├── Product (322 Produkte, zentrale Datenbank)
│   ├── ProductTranslation (DE + EN, mit Auto-Translate)
│   ├── ProductPrice (Füllmenge × Preisebene, mit EK/Fix/%)
│   ├── ProductWineProfile (91 Profile)
│   ├── ProductBeverageDetail (139 Details)
│   ├── ProductAllergen, ProductTag
│   ├── ProductMedia (Sharp: WebP, thumb/medium/large)
│   ├── ProductCustomFieldValue
│   └── MenuPlacement[] (Zuordnung zu Karten)
│
├── ProductGroup (27, hierarchisch mit parentId)
├── PriceLevel (4): Restaurant, Bar, Room Service, Einkauf
├── FillQuantity (18): Flasche 0,75l, 1/8 offen, etc.
├── TaxRate (2): Getränke 20%, Speisen 10%
├── Supplier (Lieferanten)
│
├── User (Benutzer) + UserRole (OWNER/ADMIN/MANAGER/EDITOR)
├── Theme (Design/Branding)
├── Media (Medien mit ProductMedia-Zuordnung)
├── TenantLanguage (Sprachen)
├── TimeRule (Zeitsteuerung, vorbereitet)
├── AnalyticsEvent (Analytics, vorbereitet)
└── QRCode (9 Codes)
```

### Entfernte Entitäten (10.04.2026 bereinigt)
Die folgenden Tabellen des alten MenuItem-Modells wurden aus der Datenbank und dem Prisma-Schema entfernt:
MenuItem, MenuItemTranslation, PriceVariant, PriceVariantTranslation, WineProfile, BeverageDetail, Pairing, MenuItemAllergen, MenuItemAdditive, MenuItemTag, MenuItemMedia, Inventory

### Wichtige Architekturänderung: Product vs. MenuItem

| Aspekt | Alt (MenuItem) | Neu (Product + MenuPlacement) |
|--------|---------------|-------------------------------|
| Artikelzuordnung | Fest an eine Sektion gebunden | Produkt in beliebig vielen Karten platzierbar |
| Preise | PriceVariant (label + price) | ProductPrice (Füllmenge × Preisebene, mit Kalkulation) |
| Sichtbarkeit | isSoldOut auf MenuItem | isVisible auf MenuPlacement |
| Highlights | Auf MenuItem | Auf Product ODER MenuPlacement (Placement hat Vorrang) |
| Preisüberschrieb | Nicht möglich | priceOverride auf MenuPlacement |
| Kalkulation | Nicht vorhanden | EK → +Fix€ → ×Aufschlag% → =VK mit farbcodierter Marge |

---

## 5. Technische Architektur

### Stack (produktiv)

| Schicht | Technologie | Anmerkung |
|---------|-------------|-----------|
| Framework | **Next.js 14 (App Router)** | SSR für Gäste-SEO, API-Routes für Backend |
| Sprache | **TypeScript** | Typsicherheit, bessere DX |
| Styling | **Tailwind CSS** | Mobile-first, konsistent |
| Datenbank | **PostgreSQL** | Auf Server, kein Docker |
| ORM | **Prisma** | Schema-first, typsichere Queries |
| Auth | **NextAuth.js** | Credentials-Provider, JWT |
| Bilder | **Sharp** | WebP-Konvertierung, EXIF-Strip, 3 Größen (thumb/medium/large) |
| PDF | **@react-pdf/renderer** | Serverseitige PDF-Generierung |
| QR | **qrcode (npm)** | SVG/PNG-Generierung |
| Übersetzung | **MyMemory API** | Auto-Translate DE→EN mit Farbstatus |
| Process | **PM2** | Process Manager, Auto-Restart |
| Reverse Proxy | **Nginx** | client_max_body_size 10M |
| Fonts | **next/font** | Playfair Display + Source Sans 3 |
| Config | **next.config.mjs** | Nicht .ts! |

### Server

| Parameter | Wert |
|-----------|------|
| Provider | Hetzner CX22 |
| IP | 178.104.138.177 |
| OS | Ubuntu 24.04 |
| App-Pfad | /var/www/menucard-pro |
| Port | 3000 (intern), 80/443 (Nginx) |
| GitHub | rexei123/menucard-pro (public) |
| Admin | admin@hotel-sonnblick.at |

### Architektur-Diagramm

```
┌─────────────────────────────────────────────────┐
│                    CLIENTS                       │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│  │  Gast    │  │  Admin   │  │  Embed/API    │  │
│  │  Mobile  │  │  Desktop │  │  Consumer     │  │
│  └────┬─────┘  └────┬─────┘  └───────┬───────┘  │
└───────┼──────────────┼────────────────┼──────────┘
        │              │                │
┌───────▼──────────────▼────────────────▼──────────┐
│              NGINX (Reverse Proxy)                │
│              178.104.138.177:80/443               │
└──────────────────────┬───────────────────────────┘
                       │
┌──────────────────────▼───────────────────────────┐
│          NEXT.JS APPLICATION (:3000)              │
│                                                   │
│  ┌─────────────────┐  ┌────────────────────────┐  │
│  │  App Router     │  │  API Routes            │  │
│  │                 │  │                        │  │
│  │  /[tenant]/     │  │  /api/v1/products      │  │
│  │    [location]/  │  │  /api/v1/menus         │  │
│  │      [menu]     │  │  /api/v1/placements    │  │
│  │                 │  │  /api/v1/translate      │  │
│  │  /admin/        │  │  /api/v1/media         │  │
│  │    products     │  │  /api/v1/qr-codes      │  │
│  │    menus        │  │  /api/v1/pdf           │  │
│  │    qr-codes     │  │  /api/auth/[...next]   │  │
│  └────────┬────────┘  └───────────┬────────────┘  │
│           │                       │               │
│  ┌────────▼───────────────────────▼────────────┐  │
│  │           DATA LAYER (Prisma)                │  │
│  └────────────────────┬────────────────────────┘  │
└───────────────────────┼──────────────────────────┘
                        │
                ┌───────▼────────┐
                │  PostgreSQL    │
                │  (lokal)       │
                │  /uploads/     │
                │  (Dateisystem) │
                └────────────────┘
```

### Admin-UI-Architektur (neu seit April 2026)

Das Admin-Interface verwendet ein Drei-Spalten-Layout:

```
┌──────────┬──────────────────┬─────────────────────────────┐
│ Icon-Bar │   List-Panel     │        Workspace            │
│ (links)  │   (resizable)    │                             │
│          │                  │                             │
│ 🏠       │ Suche + Filter   │  Editor / Detail / Form     │
│ 📋       │                  │                             │
│ 🍷       │ Produkt 1        │  Sticky Save Bar            │
│ 📊       │ Produkt 2        │  Unsaved-Changes Guard      │
│ ⚙️       │ Produkt 3        │                             │
│ 🔄       │ ...              │                             │
│ 🚪       │                  │                             │
└──────────┴──────────────────┴─────────────────────────────┘
```

- Icon-Bar: aufklappbar, standardmäßig offen
- List-Panel: resizable per Drag, mit Suche und Filter
- Workspace: Produkt-Editor, Karten-Editor, QR-Verwaltung etc.

### URL-Struktur

**Gästeansicht (öffentlich):**
```
/q/{shortCode}                                    → QR-Code Redirect
/{tenantSlug}/{locationSlug}/{menuSlug}            → Kartenansicht
/{tenantSlug}/{locationSlug}/{menuSlug}/item/{id}  → Artikeldetail
```

**Admin (geschützt):**
```
/admin                    → Dashboard
/admin/products           → Produktliste (zentrale Datenbank)
/admin/products/{id}      → Produkt-Editor
/admin/menus              → Kartenliste
/admin/menus/{id}         → Karten-Editor mit Produktpool
/admin/qr-codes           → QR-Verwaltung
```

---

## 6. Strategiepapier: Projektspeicher & Leitlinien

### Vision

MenuCard Pro wird die digitale Gastgebermappe des Hotel Sonnblick. Nicht nur eine Karte, sondern ein Informations- und Erlebniskanal zwischen Haus und Gast. Die Plattform soll so selbstverständlich nutzbar sein wie eine gedruckte Karte – aber mit allen Vorteilen digitaler Aktualisierung, Mehrsprachigkeit und Analytik.

### Designphilosophie

**Gästeansicht:** Elegant, ruhig, verkaufsstark. Inspiriert von hochwertigen Printmenüs. Große Typografie, zurückhaltende Farben, hohe Kontraste. Kein visuelles Rauschen. Die Karte muss bei Kerzenlicht auf einem Smartphone genauso gut funktionieren wie am Frühstückstisch auf einem Tablet.

**Admin-Ansicht:** Effizient, übersichtlich, schnell. Der Küchenchef soll in 30 Sekunden ein Gericht als ausverkauft markieren können. Die Rezeptionistin soll die Minibar-Karte ohne Schulung bearbeiten können.

### Architekturentscheidungen und Begründungen

1. **Monorepo mit Next.js** statt getrennter Frontend/Backend-Repos → Schnellere Entwicklung, weniger Deployment-Komplexität, SSR für Gäste-SEO.

2. **Prisma statt Raw SQL** → Typsicherheit, einfache Migrations, automatische TypeScript-Types.

3. **Slug-basiertes Routing** statt ID-basiert für öffentliche URLs → SEO-freundlich, menschenlesbar, stabile QR-Codes.

4. **Übersetzungen als eigene Relationen** statt JSON-Spalten → Saubere Abfragen, einfache Erweiterung um neue Sprachen, indexierbar.

5. **Zentrale Produktdatenbank statt MenuItem** → Produkte existieren unabhängig von Karten. MenuPlacement ordnet Produkte flexibel zu. Ermöglicht Wiederverwendung, zentrale Preispflege und kartenübergreifende Verwaltung.

6. **Sharp statt S3/MinIO** für Bildverarbeitung → Lokale Speicherung auf dem Server, WebP-Konvertierung, EXIF-Strip, drei Größen (thumb/medium/large). Einfacher als externe Storage-Anbindung für den aktuellen Umfang.

7. **PM2 + Nginx** statt Docker → Direktes Deployment auf Hetzner, weniger Overhead, einfacheres Debugging.

8. **EU-Allergenstandard** als vorkonfigurierte Stammdaten → Rechtssicherheit, sofort einsatzbereit.

### Qualitätsstandards

- Jede API-Route hat Validierung
- Alle öffentlichen Seiten sind serverseitig gerendert
- Bilder werden per Sharp optimiert (WebP, 3 Größen)
- Skeleton-Loading für schnelle wahrgenommene Ladezeit
- Unsaved-Changes Guard im Admin verhindert Datenverlust
- Doppelbestätigung bei destruktiven Aktionen (Produkt löschen)
- Auto-Translate mit visuellem Farbstatus (grau/orange/grün)

### Sicherheit & DSGVO

- Passwörter: bcrypt
- Sessions: HTTP-only, Secure Cookies (NextAuth JWT)
- Tenant-Isolation: Jede Query filtert nach tenantId
- Analytics: Keine personenbezogenen Daten, Session-IDs anonymisiert
- Bilder: Keine EXIF-Daten gespeichert (Sharp .rotate() Strip)
- Nginx: client_max_body_size 10M

---

## 7. Aufgabenliste

### Erledigt ✅

| ID | Feature |
|----|---------|
| T-001 | Projekt-Setup: Next.js 14, TypeScript, Tailwind, Prisma |
| T-003 | Prisma Schema (vollständig, inkl. Product-Modell) |
| T-005 | Seed-Daten: 322 Produkte, 9 Karten, alle Übersetzungen |
| T-006 | Auth: NextAuth mit Credentials-Provider, JWT |
| T-007 | Middleware: Auth-Guard für /admin |
| T-008 | Prisma-Client Singleton, Utility-Funktionen |
| T-009 | Admin-Layout: Icon-Bar + List-Panel + Workspace (Drei-Spalten) |
| T-010 | Dashboard: Stats (Karten, Artikel, QR-Codes) |
| T-011 | Kartenverwaltung: Drag & Drop, Produktpool, Ausgetrunken-Toggle |
| T-012 | Sektions-Verwaltung in Karten-Editor |
| T-013 | Produkt-Editor: Status, Typ, Produktgruppe, Highlight |
| T-014 | Weinprofil-Editor (im Produkt-Editor integriert) |
| T-015 | Getränkedetail-Editor (im Produkt-Editor integriert) |
| T-018 | Preiseditor: Füllmenge × Preisebene, EK/Fix/%/VK-Kalkulation |
| T-019 | Products CRUD API |
| T-020 | Placements CRUD API |
| T-021 | Translate API (MyMemory, Farbstatus) |
| T-025 | Medien-Upload: Sharp-Optimierung, WebP, 3 Größen, Kategorien |
| T-026 | Medien-Picker: Drag & Drop + Datei-Dialog im Produkt-Editor |
| T-029 | Kartenansicht: Sticky-Navigation, Kategorien, Produkt-Cards |
| T-030 | Artikeldetail-Seite (alle Produkte klickbar) |
| T-032 | Volltextsuche in Gästeansicht |
| T-033 | Filter: Weinstil, Land |
| T-034 | Sprachwechsler DE/EN |
| T-035 | Mobile-Optimierung: next/font, Skeleton-Loading, PWA-Meta |
| T-037 | QR-Code-Service: Generierung mit Logo, Farben |
| T-038 | QR-Code-Admin: Erstellen, Label, Download |
| T-039 | QR-Redirect: /q/{shortCode} → richtige Karte |
| T-040 | PDF-Export: Basis-Vorlage A4 (auf Product-Modell umgebaut) |
| T-051 | Seed-Daten: Vollständige Demodaten (322 Produkte, 9 Karten) |
| T-055 | Ausgetrunken: isVisible-Toggle auf MenuPlacement → Sold Out in Gästekarte |
| T-060 | Deployment: Hetzner, PM2, Nginx, LIVE |
| B-002 | Highlight-Badges auf Product + MenuPlacement |
| B-005 | Zentrale Produktdatenbank (vollständig implementiert) |

### Nächste Prioritäten 🔜

| ID | Feature | Priorität |
|----|---------|-----------|
| NEW-001 | Domain menu.hotel-sonnblick.at + SSL (Let's Encrypt) | Hoch |
| T-041 | PDF-Vorlagen: A4, A5, Tischkarte, Barkarte – Template-Auswahl im Admin | Hoch |
| NEW-002 | Bilder in Gästekarte anzeigen (Produktbilder in Kartenansicht) | Hoch |
| NEW-003 | Bilder als Thumbnails in Admin-Produktliste | Mittel |
| T-045 | CSV-Import-Wizard: Spalten-Mapping, Vorschau, Validierung | Mittel |
| T-043 | Website-Embed: /embed/{tenant}/{menu} – schlankes Layout | Mittel |
| T-044 | iFrame-Code-Generator im Admin | Mittel |
| NEW-004 | QR-Codes auf neues Admin-Layout (List-Panel + Workspace) | Mittel |
| NEW-005 | Massenänderungen (Preise Global/Gruppe/Produkt) | Mittel |
| T-047 | Analytics-Service: Events tracken (QR-Scan, Page-View, Item-View) | Mittel |
| T-048 | Analytics-Dashboard: Scans, Views, Top-Items | Mittel |
| T-036 | Dark Mode für Gästeansicht | Niedrig |
| T-049 | Theme-Editor: Farben, Schriften, Logo, Live-Vorschau | Niedrig |

### Backlog (Phase 2+)

| ID | Feature |
|----|---------|
| B-001 | Zeitsteuerung: Automatische Kartenwechsel nach Tageszeit |
| B-003 | Pairings-Editor: Speisen-Wein-Zuordnung |
| B-004 | Weinlexikon: Glossar mit Rebsorten, Regionen, Begriffen |
| B-006 | Eventkarten: Temporäre Karten für Hochzeiten, Feiern |
| B-007 | Room-Service-Ansicht: Zimmermappen-Integration |
| B-008 | Bestandsverwaltung: Lager, Mindestbestand, Auto-Sold-Out |
| B-009 | Erweiterte Druckvorlagen: Barkarte, Weinliste, Cocktailkarte |
| B-010 | Reservierungs-CTA: Link zu Reservierungssystem |
| B-011 | KI-Empfehlungen: Intelligente Weinvorschläge basierend auf Speisenauswahl |
| B-012 | Multi-Tenant Onboarding: Selbstregistrierung für neue Betriebe |
| B-013 | Benutzerverwaltung: User CRUD, Rollenänderung im Admin |
| B-014 | SEO: Meta-Tags, Open Graph, Schema.org Menu |
| B-015 | CSV-Export: Karte/Artikel als CSV herunterladen |

---

## 8. Deployment & Betrieb

### Workflow
1. Script in Claude (Cowork) erstellen → wird in Projektordner geschrieben
2. PowerShell (lokal): `scp "C:\Users\erich\Documents\Claude\Projects\Menucard Pro\DATEI" root@178.104.138.177:/var/www/menucard-pro/`
3. SSH: `cd /var/www/menucard-pro && bash DATEI.sh`
4. UTF-8 mit echten Umlauten – kein ASCII-Workaround nötig

### Wichtige Befehle
```bash
# SSH
ssh root@178.104.138.177

# App
cd /var/www/menucard-pro
npm run build && pm2 restart menucard-pro
pm2 logs menucard-pro

# Datenbank
psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

# Prisma
npx prisma studio    # DB-Browser
npx prisma db push   # Schema synchronisieren

# Cache leeren bei Problemen
rm -rf .next && npm run build && pm2 restart menucard-pro
```

### Backups
- /root/menucard-pre-cleanup-20260410.sql
- /root/menucard-backup-20260410.sql
- /root/menucard-backup-20260409.sql
- /root/menucard-pre-products.sql
- GitHub: main branch

### Technische Learnings
- `next.config.mjs` (nicht .ts!)
- NextAuth Route bei `/api/auth/[...nextauth]/`
- TypeScript `Set` iteration: `Array.from(new Set(...))` statt `[...new Set(...)]`
- PowerShell: `&&` funktioniert nicht → Semikolon `;` verwenden
- Bash `!` in Strings: einfache Anführungszeichen oder `\!`
- Sharp: `.rotate()` für Auto-EXIF, `.webp()` für Konvertierung
- Nginx: `client_max_body_size 10M` in `/etc/nginx/conf.d/upload.conf`
- Drag & Drop: `useRef` für State im Drop-Handler (useState veraltet in Closures)
- `.next` Cache löschen bei hartnäckigen Problemen: `rm -rf .next`
- Heredoc-basierte Schema-Erstellung funktioniert nicht → Python-Inline verwenden
