# MenuCard Pro

Digitale Speise-, Getränke- und Weinkarten für Hotel Sonnblick, Saalbach (Österreich).

## Stack
Next.js 14, TypeScript, Tailwind CSS, Prisma, PostgreSQL, NextAuth, PM2, Nginx

## Server
- **App:** `/var/www/menucard-pro`
- **DB:** `psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"`
- **Admin:** admin@hotel-sonnblick.at / Sonnblick2026!
- **Build & Restart:** `npm run build && pm2 restart menucard-pro`
- **Nginx:** Reverse proxy → localhost:3000

## Kommunikation
- Immer auf **Deutsch** kommunizieren, "Sie"-Form, freundlich-professionell
- Aus Sicht des Hotels kommunizieren (neutral, nie persönlich)
- Kurze bis mittellange Antworten, präzise und informativ

## Arbeitsweise
- Dateien direkt editieren, kein Umweg über Scripts
- Nach Änderungen an Komponenten: `npm run build && pm2 restart menucard-pro`
- Bei Prisma-Schema-Änderungen: `npx prisma db push` dann Build
- Immer Backup-Datei erstellen vor größeren Änderungen: `cp datei datei.bak`
- Teste Änderungen nach dem Build (curl, Browser)

## Projektstruktur
```
src/
├── app/
│   ├── admin/              # Admin-Bereich
│   │   ├── design/         # Design-Übersicht
│   │   └── menus/[id]/design/  # Design-Editor pro Karte
│   ├── api/v1/             # REST-API
│   │   ├── menus/[id]/design/  # Design-Config GET/PATCH
│   │   ├── menus/[id]/pdf/     # PDF-Generierung
│   │   ├── products/           # Produkt-CRUD
│   │   ├── placements/         # Kartenzuordnungen
│   │   ├── qr-codes/           # QR-Code-Verwaltung
│   │   ├── import/             # CSV-Import
│   │   ├── translate/          # Auto-Übersetzung
│   │   ├── media/              # Bilder-Upload
│   │   └── design-templates/   # Template-Definitionen
│   ├── api/auth/           # NextAuth
│   └── [tenant]/[location]/[menu]/  # Öffentliche Gästeansicht
├── components/admin/
│   └── design-editor.tsx   # Design-Editor (7 Akkordeons + Live-Vorschau)
├── lib/
│   ├── prisma.ts           # DB-Client
│   ├── auth.ts             # NextAuth Config
│   ├── design-templates/   # Template-Definitionen (elegant/modern/classic/minimal)
│   └── pdf/                # PDF-Engine
└── prisma/
    └── schema.prisma       # Datenbank-Schema
```

## Datenmodell (Kern)
```
Product (322 Produkte)
├── ProductTranslation (DE+EN)
├── ProductPrice (Füllmenge × Preisebene, mit EK/Fix/%)
├── ProductWineProfile
├── ProductBeverageDetail
├── ProductAllergen, ProductTag
├── ProductMedia (Sharp: WebP, thumb/medium/large)
└── MenuPlacement (Zuordnung zu Karten mit isVisible/sortOrder)

Menu → designConfig (JSON: { digital: {...}, analog: {...} })
ProductGroup (27, hierarchisch)
PriceLevel (4): Restaurant, Bar, Room Service, Einkauf
FillQuantity (18): Flasche 0,75l, 1/8 offen, etc.
```

## Design-System
- 4 Templates: elegant, modern, classic, minimal
- Design-Config als JSON in `Menu.designConfig`
- API: GET/PATCH `/api/v1/menus/[id]/design`
- Editor: `src/components/admin/design-editor.tsx`
- Templates: `src/lib/design-templates/`
- "Benutzerdefiniert"-Erkennung wenn Overrides vorhanden
- Reset-to-Default mit Bestätigungsdialog

## Daten (Stand 12.04.2026)
- 322 Produkte, 640 Übersetzungen, 298 Preise, 91 Weinprofile, 139 Getränkedetails
- 9 Karten: 7 Gourmet-Menüs (EVENT), 1 Weinkarte (WINE), 1 Barkarte (BAR)
- 10 QR-Codes, 27 Produktgruppen

## Erledigte Features
- Admin: Icon-Bar + List-Panel + Workspace, Produkt-Editor, Auto-Translate, Preiskalkulation
- Bilder-Upload (Sharp/WebP, 3 Größen), Kartenverwaltung Drag&Drop
- CSV-Import mit Vorschau + Inline-Edit + Neu-Validierung
- Design-Editor: 7 Akkordeons, Live-Vorschau, Template-Wahl, Reset, Custom-Vorlage
- Gästeansicht: Kartenansicht, Volltextsuche, Filter, Sprachwechsler DE/EN, Sold-Out
- Security: Nginx gehärtet, Rate-Limiting, Header, .env geschützt

## Security-Status (12.04.2026)
- Nginx: .git, .env, prisma, .bak, .sh, .sql blockiert
- Security-Header: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
- Rate-Limiting: 10r/s API, 3r/s Login
- poweredByHeader: false
- Test-Scripts: `test-bugs.sh`, `test-security.sh` auf dem Server

## Nächste Schritte
- Domain/SSL (wartet auf IT)
- PDF-Export v2
- Massenänderungen
- Dark Mode
- Embed-Code / iFrame-Widget
- SSH-Key einrichten (dann Root-Login einschränken)

## Technische Learnings
- `next.config.mjs` (nicht .ts)
- NextAuth Route: `/api/auth/[...nextauth]/`
- TypeScript Set: `Array.from(new Set(...))` statt Spread
- Sharp: `.rotate()` für Auto-EXIF, `.webp()` für Konvertierung
- Nginx upload limit: `/etc/nginx/conf.d/upload.conf` → `client_max_body_size 10M`
- Drag & Drop: `useRef` für State in Drop-Handler (useState veraltet in Closures)
- `.next` Cache löschen bei Problemen: `rm -rf .next`
- Design-API: Response-Feld heißt `designConfig` (nicht `mergedConfig`)
- PATCH Design: `{ designConfig: { digital: {...} } }` (nicht `{ digital: {...} }`)

## Backups
- `/root/menucard-pre-cleanup-20260410.sql`
- `/root/menucard-backup-20260410.sql`
- GitHub: rexei123/menucard-pro (main branch)
