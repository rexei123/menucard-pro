# MenuCard Pro

Digitale Speise-, Getränke- und Weinkarten für das Hotel Sonnblick, Kaprun (Österreich).

Eine mandantenfähige Plattform, die Speise-, Getränke- und Weinkarten per QR-Code und Direktlink bereitstellt — ohne App-Download, in Echtzeit aktualisierbar, mehrsprachig (Deutsch/Englisch).

## Live-Zugänge

| Zweck | URL |
|---|---|
| Gästekarte | `https://menu.hotel-sonnblick.at/hotel-sonnblick/restaurant/` |
| Admin-Login | `https://menu.hotel-sonnblick.at/auth/login` |
| Admin-Dashboard | `https://menu.hotel-sonnblick.at/admin` |
| QR-Redirect | `https://menu.hotel-sonnblick.at/q/{shortCode}` |

## Kennzahlen

- **322 Produkte** mit 644 Übersetzungen und 298 Preisen
- **9 Karten:** 7 Gourmet-Menüs, 1 Weinkarte, 1 Barkarte
- **337 Kartenzuordnungen** (MenuPlacements)
- **91 Weinprofile**, **137 Getränkedetails**
- **5 Design-Templates** (4 System, 1 Custom) mit Live-Vorschau
- **10 QR-Codes**

## Stack

Next.js 14 · TypeScript · Tailwind CSS · Prisma · PostgreSQL · NextAuth · Sharp · @react-pdf/renderer · PM2 · Nginx

## Features

### Gästeansicht
- Kartenansicht mit Sektionen, Produkten und Preisen
- Artikeldetail-Seite (alle Produkte klickbar)
- Volltextsuche und Filter (Weinstil, Herkunft, etc.)
- Sprachwechsler DE/EN mit Fallback-Logik
- QR-Code-Redirect über Short-Codes
- Mobile-First, schneller Seitenaufbau
- Sold-Out-Anzeige
- 4 Template-Stile: Elegant, Modern, Classic, Minimal

### Admin
- Drei-Spalten-Layout (Icon-Bar · List-Panel · Workspace)
- Dashboard mit KPI-Kacheln und Schnellzugriff
- Produkt-Editor mit Auto-Translate (MyMemory API)
- Preiskalkulation (EK → Fix€ → %-Aufschlag → VK, Marge farbcodiert)
- Weinprofil- und Getränkedetail-Editoren
- Bildarchiv mit Drag & Drop, Sharp-Optimierung (WebP, 3 Größen), Websuche über SearXNG
- Karten-Editor mit Drag & Drop, Zuordnungs-Pool, Sold-Out-Toggle
- Design-Editor mit 7 Akkordeons, Live-Vorschau, PDF-Tab, Template-Duplikation
- QR-Code-Generator mit Branding-Farben und Logo
- CSV-Import mit Inline-Vorschau und -Bearbeitung
- PDF-Export (A4) über @react-pdf/renderer

## Architektur

### Zentrale Produktdatenbank

Produkte existieren unabhängig von Karten und werden über `MenuPlacement` flexibel zugeordnet:

```
Product
├── ProductTranslation (DE + EN)
├── ProductPrice (Füllmenge × Preisebene)
├── ProductWineProfile | ProductBeverageDetail
├── ProductAllergen, ProductTag, ProductPairing
├── ProductMedia → Media
└── MenuPlacement → MenuSection → Menu → Location → Tenant
```

Unterstützende Entitäten: `ProductGroup` (hierarchisch), `PriceLevel`, `FillQuantity`, `TaxRate`, `Supplier`.

### Projektstruktur

```
src/
├── app/
│   ├── (public)/        # Gästeansicht: [tenant]/[location]/[menu] + q/[code]
│   ├── auth/login/      # Login (NextAuth Custom-Page)
│   ├── admin/           # Admin-Bereich
│   └── api/v1/          # REST-API (27 Endpunkte)
├── components/
│   ├── admin/           # Produkt-, Menu-, Design-, QR-Editoren
│   ├── templates/       # elegant, modern, classic, minimal Renderer
│   └── ui/              # Wiederverwendbare UI-Bausteine
├── lib/                 # Auth, Prisma, PDF, Design-Templates, Utils
└── prisma/              # Schema (40 Modelle/Enums)
```

Vollständige Dokumentation: `docs/API.md`, `docs/DATENMODELL.md`, `docs/DEPLOYMENT.md`.

## Setup (Entwicklung)

Voraussetzungen: Node 22, PostgreSQL 15+, npm 10.

```bash
# Repository
git clone https://github.com/rexei123/menucard-pro.git
cd menucard-pro

# Abhängigkeiten
npm install

# Umgebungsvariablen
cp .env.example .env
# DATABASE_URL und NEXTAUTH_SECRET setzen

# Datenbank
npx prisma generate
npx prisma db push
npx prisma db seed   # optional: Demo-Daten

# Entwicklungsserver
npm run dev
```

Der Server läuft unter `http://localhost:3000`.

## Befehle

| Befehl | Zweck |
|---|---|
| `npm run dev` | Entwicklungsserver |
| `npm run build` | Production-Build |
| `npm run start` | Production-Server |
| `npm run lint` | ESLint-Check |
| `npm run db:generate` | Prisma-Client generieren |
| `npm run db:push` | Schema in DB spiegeln |
| `npm run db:studio` | Prisma-Datenbank-Browser |
| `npm run db:seed` | Demo-Daten einspielen |

## Deployment

Siehe `docs/DEPLOYMENT.md` für die vollständige Server-Setup-Anleitung, Backup-/Restore-Prozeduren und Troubleshooting.

Schnell-Deployment auf bestehendem Server:

```bash
# SSH auf Server
cd /var/www/menucard-pro
git pull
npm install              # falls Dependencies sich geändert haben
npx prisma db push       # falls Schema-Änderung
npm run build
pm2 restart menucard-pro
```

## Lizenz & Kontakt

Proprietäre Software für Hotel Sonnblick, Kaprun. Kontakt: `hotelsonnblick@gmail.com`.
