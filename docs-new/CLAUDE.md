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

- **Hinzufügen:** `#22C55E` (green-500, CSS-Variable `--color-add`), Hover `#16A34A`
- **Entfernen/Löschen:** `var(--color-primary)` (`#DD3C71`), bzw. `var(--color-error)` für destruktive Aktionen
- Gilt durchgängig im Admin-Backend.

## Security-Status

- Nginx: `.git`, `.env`, `prisma`, `.bak`, `.sh`, `.sql`, `.log`, `node_modules` blockiert
- Security-Header: `X-Frame-Options: SAMEORIGIN`, `X-Content-Type-Options: nosniff`, `X-XSS-Protection`, `Referrer-Policy`
- Rate-Limiting: 10r/s API, 3r/s Login (Burst 20/5)
- `poweredByHeader: false`
- SSL/TLS: Let's Encrypt (menu.hotel-sonnblick.at)

## Test-Infrastruktur

- **Playwright-Script:** `playwright-admin-tests-v4.mjs` im Projektordner
- **Login-Pfad:** `/auth/login` (Custom-Page, nicht NextAuth-Default)
- **Selektoren:** `input[name="email"]`, `input[name="password"]`, `button[type="submit"]`
- **Test-IDs:** In `INVENTAR-*.md` je Stichtag; vor jedem Lauf prüfen, ob Test-IDs noch existieren

## Technische Learnings

- `next.config.mjs` (nicht `.ts`)
- NextAuth-Route: `/api/auth/[...nextauth]/route.ts`
- TypeScript-Set: `Array.from(new Set(...))` statt Spread
- Sharp: `.rotate()` für Auto-EXIF, `.webp()` für Konvertierung
- Nginx-Upload-Limit: `/etc/nginx/conf.d/upload.conf` → `client_max_body_size 10M`
- Drag & Drop: `useRef` für State in Drop-Handler (useState veraltet in Closures)
- `.next` Cache löschen: `rm -rf .next`
- PATCH Template: `{ templateId: "..." }` an `/api/v1/menus/[id]/template`

## Backups

- DB-Dumps: `/root/backups-YYYYMMDD/menucard-db-*.sql`
- Letzter Stand: `/root/backups-20260414/`
- Git-Tags: `v1.0-stabil` (14.04.2026)
- GitHub: `rexei123/menucard-pro` (main branch, Token nicht in Remote-URL)

## Weiterführende Dokumentation

- `docs/API.md` — alle 27 API-Routen mit Methoden und Payloads
- `docs/DATENMODELL.md` — Prisma-Schema vollständig dokumentiert
- `docs/DEPLOYMENT.md` — Server-Setup, Backup/Restore, Troubleshooting
- `CHANGELOG.md` — Versionshistorie
- `README.md` — öffentliche Projektbeschreibung

## Nächste Schritte (offen)

- Phase 5: UI/UX-Original-Strategie gegen Original-Briefing fertigstellen
- Bestellfunktion (vorbereitet, nicht aktiv)
- Bestandsverwaltung (Mindestbestand, Ausverkauf-Automatik)
- Happy-Hour / Saisonkarten / Eventkarten
- Embed-Widget / iFrame
- Dark Mode
- SSH-Key-only Login
