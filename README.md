# MenuCard Pro

Digitale Speise-, Getränke- und Weinkarten für das Hotel Sonnblick, Saalbach.

Eine mandantenfähige Plattform, die Speise-, Getränke- und Weinkarten per QR-Code und Direktlink bereitstellt – ohne App-Download, in Echtzeit aktualisierbar, mehrsprachig (DE/EN).

## Live

- **Gästekarte:** `http://178.104.138.177/hotel-sonnblick/restaurant/`
- **Admin:** `http://178.104.138.177/admin`
- **9 Karten** · **322 Produkte** · **640 Übersetzungen** · **91 Weinprofile**

## Stack

Next.js 14 · TypeScript · Tailwind CSS · Prisma · PostgreSQL · NextAuth.js · Sharp · PM2 · Nginx

## Features

### Gästeansicht
- Kartenansicht mit Sektionen, Produkten und Preisen
- Artikeldetail-Seite (alle Produkte klickbar)
- Volltextsuche und Filter (Weinstil, Land)
- Sprachwechsler DE/EN
- QR-Code-Redirect
- Mobile-optimiert (next/font, Skeleton-Loading)
- Ausgetrunken-Anzeige (Sold Out)

### Admin
- Drei-Spalten-Layout: Icon-Bar + List-Panel (resizable) + Workspace
- Dashboard mit Statistiken
- Produkt-Editor mit Auto-Translate (MyMemory API, Farbstatus grau/orange/grün)
- Preiskalkulation (EK → +Fix€ → ×Aufschlag% → =VK, Marge farbcodiert)
- Weinprofil- und Getränkedetail-Editor
- Bilder-Upload: Drag & Drop, Sharp-Optimierung (WebP, 3 Größen), Kategorien
- Kartenverwaltung mit Drag & Drop, Produktpool, Ausgetrunken-Toggle
- QR-Code-Verwaltung
- PDF-Export (A4)

## Architektur

### Zentrale Produktdatenbank

Produkte existieren unabhängig von Karten und werden über **MenuPlacement** flexibel zugeordnet:

```
Product (322)
├── ProductTranslation (DE + EN)
├── ProductPrice (Füllmenge × Preisebene, mit Kalkulation)
├── ProductWineProfile
├── ProductBeverageDetail
├── ProductAllergen, ProductTag
├── ProductMedia (WebP, thumb/medium/large)
└── MenuPlacement → MenuSection → Menu → Location → Tenant
```

Unterstützende Entitäten: ProductGroup (27, hierarchisch), PriceLevel (4), FillQuantity (18), TaxRate (2), Supplier.

### Projektstruktur

```
src/
├── app/
│   ├── (public)/        # Gästeansicht ([tenant]/[location]/[menu])
│   ├── admin/           # Admin-Bereich (products, menus, qr-codes)
│   └── api/v1/          # API-Routes (products, placements, translate, media, pdf, qr-codes)
├── components/
│   ├── admin/           # Admin-Komponenten (product-editor, menu-editor, etc.)
│   └── public/          # Gäste-Komponenten (menu-content, etc.)
├── lib/                 # Prisma-Client, Auth, Utils
└── types/               # TypeScript Types
```

## Setup (Entwicklung)

```bash
# Abhängigkeiten
npm install

# Umgebungsvariablen
cp .env.example .env

# Datenbank
npx prisma generate
npx prisma db push

# Entwicklungsserver
npm run dev
```

## Deployment (Produktion)

Server: Hetzner CX22, Ubuntu 24.04, Nginx Reverse Proxy → localhost:3000

```bash
# Build & Restart
npm run build && pm2 restart menucard-pro

# Prisma Schema synchronisieren
npx prisma db push

# Logs
pm2 logs menucard-pro

# Cache leeren bei Problemen
rm -rf .next && npm run build && pm2 restart menucard-pro
```

## Befehle

| Befehl | Beschreibung |
|--------|-------------|
| `npm run dev` | Entwicklungsserver |
| `npm run build` | Production Build |
| `npm run lint` | ESLint |
| `npx prisma studio` | Datenbank-Browser |
| `npx prisma db push` | Schema synchronisieren |

## URLs

| Bereich | URL |
|---------|-----|
| Gästekarte | `/hotel-sonnblick/restaurant/{menu-slug}` |
| Artikeldetail | `/hotel-sonnblick/restaurant/{menu-slug}/item/{id}` |
| QR-Redirect | `/q/{shortCode}` |
| Admin | `/admin` |
| Login | `/auth/login` |
| PDF-Export | `/api/v1/pdf?tenant=hotel-sonnblick&location=restaurant&menu={slug}&lang=de` |
| API Products | `/api/v1/products` |
| API Placements | `/api/v1/placements` |

## Design-Regel: Action-Button-Farben

**Hinzufuegen-Buttons: Gruen (hell)**
- Farbe: `#22C55E` (green-500, CSS-Variable `--color-add`)
- Hover: `#16A34A` (green-600, CSS-Variable `--color-add-hover`)
- Beispiele: `+ Artikel`, `+ Preis hinzufuegen`, `+ Neu anlegen`
- Referenz: gleicher Farbton wie die kleinen Status-Punkte bei Produkten

**Entfernen-/Loeschen-Buttons: Rosa (UI-Primaerfarbe)**
- Farbe: `var(--color-primary)` (#DD3C71)
- Oder: `var(--color-error)` fuer destruktive Aktionen
- Beispiele: `Loeschen`, `Entfernen`, `X` bei Listenpunkten

**Wichtig:** Diese Farblogik gilt im Admin-Backend durchgaengig. Gruen signalisiert "hinzufuegen/bestaetigen", Rosa/Rot signalisiert "entfernen/abbrechen".

