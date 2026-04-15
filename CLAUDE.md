# MenuCard Pro — Arbeitsanweisungen für Claude

Digitale Speise-, Getränke- und Weinkarten für das Hotel Sonnblick, Saalbach (Österreich).

## Stack

Next.js 14.2 (App Router) · TypeScript 5.7 · Tailwind CSS 3.4 · Prisma 5.22 · PostgreSQL · NextAuth 4.24 · @react-pdf/renderer 4 · Sharp 0.33 · PM2 · Nginx

## Server

- **Domain:** `https://menu.hotel-sonnblick.at`
- **Server-IP:** 178.104.138.177 (Hetzner CX22, Ubuntu 24.04)
- **App-Verzeichnis:** `/var/www/menucard-pro`
- **Datenbank:** `postgresql://menucard:<passwort>@127.0.0.1:5432/menucard_pro` (Passwort in `.env`)
- **Admin-User:** `admin@hotel-sonnblick.at`
- **Build & Restart:** `npm run build && pm2 restart menucard-pro`
- **SSL:** Let's Encrypt, Auto-Renewal aktiv

## Kommunikation

- Immer auf **Deutsch**, "Sie"-Form, freundlich-professionell
- Aus Sicht des Hotels kommunizieren (neutral)
- Kurze bis mittellange Antworten, präzise und informativ

## Arbeitsweise

- **Autonom:** Claude beschafft Infos selbst (Scripts, curl, grep), bündelt Schritte in ausführbaren Scripts, macht Selbstkontrolle vor Rückfragen.
- **Zwei-Shell-Workflow:** Jeder Befehl wird eindeutig markiert als **PowerShell (lokal)** oder **SSH-Terminal (Server)**.
- **Backup-Prinzip:** Vor Änderungen `cp datei datei.bak`, größere Änderungen als ausführbares Shell-Script.
- **Build-Zyklus:** Komponenten-/API-Änderung → `npm run build && pm2 restart menucard-pro` → Test (curl oder Playwright).
- **Prisma-Änderungen:** `npx prisma db push` vor dem Build.
- **TSX-Dateien:** Bei größeren Änderungen komplett neu schreiben, keine Regex-Replacements.

## Projektstruktur

```
src/
├── app/
│   ├── (public)/                 # Öffentliche Gäste-Seiten
│   │   ├── [tenant]/             # z.B. hotel-sonnblick
│   │   │   └── [location]/       # z.B. restaurant
│   │   │       └── [menu]/       # Kartenansicht + /item/[itemId]
│   │   └── q/[code]/             # QR-Short-Code-Redirect
│   ├── auth/login/               # Login-Seite (NextAuth Custom-Page)
│   ├── admin/                    # Admin-Bereich (alle authentifiziert)
│   │   ├── page.tsx              # Dashboard
│   │   ├── items/                # Produkt-Verwaltung (NICHT /products!)
│   │   ├── menus/[id]/           # Karten-Editor
│   │   ├── design/               # Template-Übersicht (SYSTEM + CUSTOM)
│   │   │   └── [id]/edit/        # Template-Editor (nur CUSTOM editierbar)
│   │   ├── media/                # Bildarchiv
│   │   ├── qr-codes/             # QR-Code-Verwaltung
│   │   ├── import/               # CSV-Import
│   │   ├── analytics/            # Statistiken
│   │   ├── pdf-creator/          # PDF-Layouts
│   │   └── settings/             # allergens, languages, theme, users
│   └── api/
│       ├── auth/[...nextauth]/   # NextAuth-Endpoints
│       └── v1/                   # REST-API (siehe docs/API.md)
├── components/
│   ├── admin/                    # admin-spezifisch (19 Komponenten)
│   ├── templates/                # elegant, modern, classic, minimal Renderer
│   ├── ui/                       # badge, button, card, icon, input-field
│   ├── menu-content.tsx          # Öffentliche Kartenansicht
│   └── language-switcher.tsx
├── lib/
│   ├── auth.ts                   # NextAuth-Config
│   ├── prisma.ts                 # DB-Client
│   ├── design-config-reader.ts   # Template-Config-Merging
│   ├── design-templates/         # SYSTEM-Template-Definitionen
│   ├── format-price.ts           # Intl.NumberFormat (de-AT, en-GB)
│   ├── pdf/                      # @react-pdf/renderer Engine
│   ├── s3.ts                     # S3-Storage-Adapter
│   ├── search-suggestions.ts
│   ├── template-resolver.ts      # SYSTEM + CUSTOM Template-Auflösung
│   └── utils.ts                  # generateShortCode, cn, etc.
└── prisma/
    └── schema.prisma             # 40 Modelle/Enums (siehe docs/DATENMODELL.md)
```

## Design-System

- **4 SYSTEM-Templates:** elegant, modern, classic, minimal
- **CUSTOM-Templates:** bis zu 6 gleichzeitig aktiv, via Duplicate/Edit erzeugt
- **Template-Konfiguration:** JSON in `DesignTemplate.config` (digital + analog)
- **Route:** Editor unter `/admin/design/[templateId]/edit` (SYSTEM redirected auf `/admin/design`)
- **API:** `/api/v1/design-templates`, `/api/v1/design-templates/[id]`, `/api/v1/menus/[id]/template`
- **Komponente:** `src/components/admin/design-editor.tsx` (7 Akkordeons + Live-Vorschau)

## Aktueller Datenstand (14.04.2026)

| Entität | Anzahl |
|---|---|
| Products | 322 |
| ProductTranslations | 644 (DE + EN) |
| ProductPrices | 298 |
| ProductWineProfiles | 91 |
| ProductBeverageDetails | 137 |
| Menus | 9 (7 Gourmet EVENT, 1 WINE, 1 BAR) |
| MenuPlacements | 337 |
| MenuSections | 65 |
| DesignTemplates | 5 (4 SYSTEM, 1 CUSTOM "Test 1") |
| QRCodes | 10 |
| ProductGroups | 27 (hierarchisch) |
| PriceLevels | 4 (Restaurant, Bar, Room Service, Einkauf) |
| FillQuantities | 18 |
| Locations | 2 · Tenants | 1 · Users | 1 |

## Action-Button-Farben (verbindlich)

- **Hinzufügen:** `#22C55E` (green-500, CSS-Variable `--color-add`),

## Design-Strategie 2.0 (verbindlich, Stand 14.04.2026)

Die gesamte Oberfläche ist seit Runde 4 (14.04.2026) auf Design-Strategie 2.0 ausgerichtet. Compliance-Stand: **56/58 PASS** (verbleibende 2 Fehler = Content-Emoji 🥩 in einem Produktdatensatz der Karte „Amerikanischer Abend").

### Schriftarten-Matrix

| Bereich | Template | Head-Font | Body-Font |
|---|---|---|---|
| Admin-Backend | — | Roboto | Roboto |
| Gäste-Karte | Elegant | Playfair Display | Inter |
| Gäste-Karte | Modern | Montserrat | Montserrat |
| Gäste-Karte | Classic | Playfair Display | Inter |
| Gäste-Karte | Minimal | Space Grotesk | Space Grotesk |

- Alle Schriften werden via `next/font/google` selbst gehostet (siehe `src/app/layout.tsx`)
- Template-Schriften werden als CSS-Variablen (`--mc-body-font`, `--mc-h1-font`, `--mc-h2-font`, `--mc-price-font`) in den Template-Wrapper injiziert
- Der Wrapper `mc-template-root mc-template-{key}` muss auf **jeder** öffentlichen Gäste-Seite auf dem Root-Container sitzen (Kartenansicht + Item-Detail)

### Unverrückbare Regeln

- **Keine Architektur-/Logik-/Content-Änderungen** beim Design-Arbeiten — nur visuelle (CSS, Schriftarten, Farben)
- **Material Symbols statt Emojis** — Content-Emojis (🥩, 🍷 usw.) sind ein Compliance-Verstoß
- **Admin-Font immer Roboto** — gilt für alle Admin-Seiten ohne Ausnahme
- **`:has()`-Selektoren in `menu-font.css`** nur für Modern und Minimal (Body-Override), Elegant und Classic erben Inter vom Layout
- **Classic-Headings Playfair Display**, nicht Cormorant Garamond (häufiger Fallstrick)

### Pflege-Workflow

1. Änderung an `src/lib/design-templates/{template}.ts` oder `src/styles/menu-font.css`
2. DB-Reseed: `npx tsx scripts/reseed-system-templates.ts` (überträgt TS-Konfig → `DesignTemplate.config`)
3. `npm run build && pm2 restart menucard-pro`
4. Compliance-Lauf: `bash design-compliance-remote.sh <tag>` (Ziel: 56/58 PASS)

### Verifikation

- **Compliance-Pipeline:** `design-compliance.mjs` + `design-compliance-remote.sh` auf dem Server, Python-Auswertung zu Excel (`DESIGN-COMPLIANCE-REPORT-<tag>.xlsx`)
- **Sechs Prüfebenen:** Tokens (CSS-Variablen), Fonts, Colors, Icons, Layout, Snapshots
- **58 Testseiten:** 22 Admin + 18 Gäste-Karten + 18 Item-Detail (je Desktop 1440×900 und Mobile 375×812)
 