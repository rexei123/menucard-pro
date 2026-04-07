# MenuCard Pro

Digitale Speise-, Getränke- und Weinkarten für das Hotel Sonnblick.

## Quick Start

### Voraussetzungen

- Node.js 20+
- Docker & Docker Compose (für PostgreSQL & MinIO)

### Setup

```bash
# 1. Abhängigkeiten installieren
npm install

# 2. Umgebungsvariablen
cp .env.example .env

# 3. Datenbank & Storage starten
cd docker && docker-compose up -d && cd ..

# 4. Prisma Schema pushen & Seed
npx prisma generate
npx prisma db push
npm run db:seed

# 5. Entwicklungsserver starten
npm run dev
```

### Zugänge nach Seed

| Rolle | E-Mail | Passwort |
|-------|--------|----------|
| Owner | admin@hotel-sonnblick.at | Sonnblick2024! |
| Editor | kueche@hotel-sonnblick.at | Sonnblick2024! |

### URLs

| Bereich | URL |
|---------|-----|
| Landing | http://localhost:3000 |
| Demo-Karte | http://localhost:3000/hotel-sonnblick |
| Admin | http://localhost:3000/admin |
| Login | http://localhost:3000/auth/login |
| API | http://localhost:3000/api/v1/... |
| MinIO Console | http://localhost:9001 |

## Stack

Next.js 14 · TypeScript · Tailwind CSS · shadcn/ui · Prisma · PostgreSQL · Zod · NextAuth.js

## Projektstruktur

```
src/
├── app/           # Next.js App Router (Pages & API)
├── components/    # UI-Komponenten (ui/, public/, admin/, shared/)
├── services/      # Business Logic Layer
├── schemas/       # Zod-Validierung
├── lib/           # Prisma, Auth, S3, Utils
├── types/         # TypeScript Types
├── config/        # Allergen-/Zusatzstoff-Stammdaten, Konstanten
├── hooks/         # React Hooks
├── stores/        # Zustand Stores
└── i18n/          # UI-Übersetzungen
```

## Befehle

| Befehl | Beschreibung |
|--------|-------------|
| `npm run dev` | Entwicklungsserver |
| `npm run build` | Production Build |
| `npm run db:seed` | Datenbank seeden |
| `npm run db:migrate` | Migration erstellen |
| `npm run db:studio` | Prisma Studio öffnen |
| `npm run test` | Tests ausführen |
| `npm run lint` | ESLint |
| `npm run type-check` | TypeScript prüfen |
