# MenuCard Pro – Bildarchiv
## Detaillierte Implementierungsanweisung
## Version: FINAL v2 · Stand: 12.04.2026
## Abgeglichen mit aktuellem Prisma-Schema vom Server

---

## 1. ÜBERBLICK

### Was gebaut wird
Ein zentrales Bildarchiv für alle Bilder des Hotels – Produktfotos, Logos, Stimmungsbilder, Weinetiketten. Bilder werden einmal hochgeladen und können beliebig vielen Produkten, Karten und Bereichen zugeordnet werden.

### Warum
- Aktuell: Bilder sind direkt an einzelne Produkte gebunden, kein Überblick, keine Wiederverwendung
- Neu: Zentrale Bibliothek mit Suche, Filtern, Zuordnung, Websuche, automatischer Formatgenerierung

### Auswirkungen auf bestehende Bereiche
1. **Produkt-Editor** – Upload-Button wird zu "Aus Bildarchiv wählen"
2. **Karten-Design-System** – Header-Bilder, Hintergrundbilder, Zwischenseiten aus Bildarchiv (designConfig auf Menu und Location existiert bereits)
3. **Gästeansicht** – Produktbilder in verschiedenen Formaten je nach Kontext (add-images-guest.sh wurde bereits implementiert – prüfen was schon da ist)
4. **PDF/Analoge Ansicht** – Flaschenfotos, Logos aus Bildarchiv
5. **Admin Icon-Bar** – Neuer Menüpunkt "Bildarchiv"
6. **QR-Code** – Logo im QR-Code aus Bildarchiv wählbar

---

## 2. DATENBANK

### 2.1 Aktueller Stand (Schema vom Server)

**Media-Tabelle (existiert bereits):**
```prisma
model Media {
  id           String   @id @default(cuid())
  tenantId     String
  tenant       Tenant   @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  filename     String
  mimeType     String
  url          String
  thumbnailUrl String?
  width        Int?
  height       Int?
  sizeBytes    Int?
  alt          String?
  createdAt    DateTime @default(now())
  productMedia ProductMedia[]
}
```

**ProductMedia-Tabelle (existiert bereits, unverändert lassen):**
```prisma
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

enum ProductMediaType {
  LABEL
  BOTTLE
  SERVING
  AMBIANCE
  LOGO
  DOCUMENT
  OTHER
}
```

**Bereits vorhanden und relevant:**
- `Menu.designConfig Json?` – Karten-Design-System ist bereits implementiert
- `Location.designConfig Json?` – Standort-Level-Design ebenfalls vorhanden
- Sharp ist installiert (`sharp@0.33.2`)
- Upload-Verzeichnisse existieren: `public/uploads/original/`, `large/`, `medium/`, `thumb/`
- Upload-API existiert: `src/app/api/v1/media/upload/route.ts`
- Bilder in Gästeansicht: `add-images-guest.sh` wurde bereits deployed

### 2.2 Schema-Erweiterung (NEU hinzufügen)

**Neue Enums:**
```prisma
enum MediaCategory {
  PHOTO       // Produktfotos, Stimmungsbilder
  LOGO        // Weingut-Logos, Hotel-Logo, Hersteller-Logos
  DOCUMENT    // Datenblätter, Zertifikate
}

enum MediaSource {
  UPLOAD      // Vom PC hochgeladen
  PIXABAY     // Aus Pixabay
  PEXELS      // Aus Pexels
  WEB         // Aus allgemeiner Websuche
}
```

**Media-Tabelle erweitern (Felder hinzufügen, bestehende NICHT ändern):**
```prisma
model Media {
  // --- BESTEHENDE FELDER (nicht ändern) ---
  id           String   @id @default(cuid())
  tenantId     String
  tenant       Tenant   @relation(fields: [tenantId], references: [id], onDelete: Cascade)
  filename     String
  mimeType     String
  url          String
  thumbnailUrl String?
  width        Int?
  height       Int?
  sizeBytes    Int?
  alt          String?
  createdAt    DateTime @default(now())
  productMedia ProductMedia[]
  
  // --- NEUE FELDER (hinzufügen) ---
  originalName  String?         // Originaler Dateiname beim Upload
  title         String?         // Editierbarer Titel (z.B. "Schlumberger Sparkling Brut")
  formats       Json?           // Crop-Daten pro Format (siehe 2.3)
  category      MediaCategory   @default(PHOTO)
  source        MediaSource     @default(UPLOAD)
  sourceUrl     String?         // Original-URL bei Websuche (für Attribution)
  sourceAuthor  String?         // Fotograf bei Stock-Fotos
  updatedAt     DateTime        @updatedAt
}
```

**ProductMedia bleibt komplett unverändert** – die n:m-Zuordnung funktioniert bereits korrekt.

### 2.3 Format-Struktur (JSON in Media.formats)

Bei jedem Upload werden automatisch mehrere Formate generiert. Jedes Format hat einen eigenen Crop-Bereich der nachträglich anpassbar ist:

```json
{
  "original": {
    "url": "/uploads/original/a1b2c3.webp",
    "width": 2560,
    "height": 1920
  },
  "16:9": {
    "url": "/uploads/formats/a1b2c3-16x9.webp",
    "width": 1920,
    "height": 1080,
    "cropX": 0,
    "cropY": 210,
    "cropW": 2560,
    "cropH": 1440
  },
  "4:3": {
    "url": "/uploads/formats/a1b2c3-4x3.webp",
    "width": 1200,
    "height": 900,
    "cropX": 0,
    "cropY": 120,
    "cropW": 2560,
    "cropH": 1920
  },
  "1:1": {
    "url": "/uploads/formats/a1b2c3-1x1.webp",
    "width": 800,
    "height": 800,
    "cropX": 320,
    "cropY": 0,
    "cropW": 1920,
    "cropH": 1920
  },
  "3:4": {
    "url": "/uploads/formats/a1b2c3-3x4.webp",
    "width": 600,
    "height": 800,
    "cropX": 560,
    "cropY": 0,
    "cropW": 1440,
    "cropH": 1920
  },
  "thumb": {
    "url": "/uploads/thumb/a1b2c3.webp",
    "width": 200,
    "height": 200
  }
}
```

### 2.4 Neues Verzeichnis auf dem Server

```
/var/www/menucard-pro/public/uploads/
├── original/        ← Existiert bereits
├── formats/         ← NEU: Alle zugeschnittenen Formate
│   ├── a1b2c3-16x9.webp
│   ├── a1b2c3-4x3.webp
│   ├── a1b2c3-1x1.webp
│   └── a1b2c3-3x4.webp
├── large/           ← Existiert bereits (Rückwärtskompatibilität)
├── medium/          ← Existiert bereits
└── thumb/           ← Existiert bereits
```

---

## 3. BILDVERARBEITUNG

### 3.1 Bei Upload (Sharp – bereits installiert)

Die bestehende Upload-API (`src/app/api/v1/media/upload/route.ts`) wird erweitert. Jedes Bild wird verarbeitet:

1. **EXIF entfernen** – `.rotate()` (bereits implementiert)
2. **WebP konvertieren** – `.webp({ quality: 90 })` (bereits implementiert)
3. **6 Formate generieren (NEU – aktuell nur 4):**

| Format | Zweck | Größe | Crop-Logik |
|--------|-------|-------|------------|
| Original | Backup, Download | Wie hochgeladen, max 4096px | Kein Crop |
| 16:9 | Karten-Header, Banner, Desktop (NEU) | 1920×1080 | Zentriert |
| 4:3 | Produktbild in Gästekarte (NEU) | 1200×900 | Zentriert |
| 1:1 | Thumbnail, Admin-Liste, Social Media (NEU) | 800×800 | Zentriert |
| 3:4 | Flaschenfoto hochkant, Mobile (NEU) | 600×800 | Zentriert |
| Thumb | Admin-Übersicht, Grid (existiert) | 200×200 cover | Zentriert |

4. **Crop-Koordinaten** werden in `formats` JSON gespeichert und sind nachträglich anpassbar

### 3.2 Logos: PNG statt WebP

Logos mit Transparenz als PNG speichern:
```javascript
if (category === 'LOGO') {
  await img.clone().png().toFile(path.join(basePath, 'original', `${filename}.png`));
}
```

### 3.3 Crop-Editor (nachträgliche Anpassung)

In der Bild-Detailansicht kann pro Format der Ausschnitt verschoben werden:
- Canvas-basierter Crop-Editor im Browser
- Rahmen im jeweiligen Seitenverhältnis fixiert (z.B. 16:9)
- Benutzer verschiebt den Rahmen
- "Zurücksetzen" setzt auf zentrierten Auto-Crop zurück
- Beim Speichern: neue Crop-Koordinaten an API → Server generiert das Format mit Sharp neu

---

## 4. ADMIN-UI: BILDARCHIV

### 4.1 Icon-Bar (src/components/admin/icon-bar.tsx)

Neuer Menüpunkt zwischen QR-Codes und Analytics hinzufügen:

```javascript
// In navItems Array einfügen:
{ href: '/admin/media', icon: '🖼️', label: 'Bildarchiv', match: /^\/admin\/media/ },
```

Reihenfolge:
```
📊 Dashboard
📦 Produkte
📋 Karten
📱 QR-Codes
🖼️ Bildarchiv    ← NEU
📈 Analytics
⚙️ Einstellungen
```

### 4.2 Seitenstruktur

Neue Dateien erstellen:
```
src/app/admin/media/
├── layout.tsx          # Wrapper (wie andere Admin-Bereiche)
├── page.tsx            # Hauptseite mit Tabs
└── [id]/
    └── page.tsx        # Bild-Detailansicht mit Crop-Editor
```

### 4.3 Layout (Vollbreite, kein List-Panel nötig)

```
┌──────┬──────────────────────────────────────────────────────────┐
│ ICON │  Bildarchiv                                              │
│ BAR  │                                                          │
│      │  ┌────────────────────────────────────────────────────┐  │
│  🖼️  │  │ [📷 Fotos]  [🏷️ Logos]  [📤 Hochladen]  [🌐 Web] │  │
│      │  └────────────────────────────────────────────────────┘  │
│      │                                                          │
│      │  (Tab-Inhalt)                                            │
└──────┴──────────────────────────────────────────────────────────┘
```

### 4.4 Tab: 📷 Fotos

Grid-Ansicht aller Bilder mit Kategorie PHOTO:

```
🔍 Nach Name filtern...
[Alle Typen ▾]  [🖼️ Quer │ 📱 Hoch │ ■ Quadr.]  [Zuordnung ▾]  [Sortierung ▾]
248 Fotos

┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│ 1920×2560│  │  800×600 │  │ 1200×1200│  │ 2560×1916│
│          │  │          │  │          │  │          │
│ Schlum.  │  │ Hurricane│  │  Wachau  │  │  Bar     │
│ Flasche  │  │ Cocktail │  │ Weinberg │  │ Ambiance │
│          │  │          │  │          │  │          │
│ BOTTLE   │  │ SERVING  │  │ AMBIANCE │  │ AMBIANCE │
│ 3 Prod.  │  │ 1 Prod.  │  │ 5 Prod.  │  │ nicht    │
│          │  │          │  │          │  │ zugeordn.│
└──────────┘  └──────────┘  └──────────┘  └──────────┘
```

**Filter:**
- Typ: Alle / BOTTLE / LABEL / SERVING / AMBIANCE / OTHER (aus bestehendem ProductMediaType Enum)
- Orientierung: Alle / Quer / Hoch / Quadratisch
- Zuordnung: Alle / Zugeordnet / Nicht zugeordnet
- Sortierung: Neueste zuerst / Älteste zuerst / Name A-Z / Größe

**Pro Bild-Kachel:**
- Thumbnail (thumb-Format, 200×200)
- Dimensionen oben links
- Titel oder Dateiname
- Typ-Badge
- Zuordnungs-Info ("3 Prod." oder "nicht zugeordnet")
- Klick → Detailansicht

### 4.5 Tab: 🏷️ Logos

Gleiche Grid-Ansicht, gefiltert auf Kategorie LOGO:
- Weingut-Logos, Hotel-Logo, Hersteller-Logos
- Logos mit Transparenz: PNG beibehalten

### 4.6 Tab: 📤 Hochladen

Massen-Upload:
```
┌──────────────────────────────────────────────────────┐
│                                                      │
│     📸 Bilder hierher ziehen                         │
│     oder klicken zum Auswählen                       │
│                                                      │
│     JPEG, PNG, WebP · Max 4MB pro Bild              │
│     Mehrere Dateien gleichzeitig                     │
│                                                      │
└──────────────────────────────────────────────────────┘

Kategorie: [PHOTO ▾]

✅ Schlumberger_Flasche.jpg    → verarbeitet
⏳ Hurricane_Cocktail.png      → wird verarbeitet...

[Alle hochladen]
```

- Drag & Drop für mehrere Dateien
- Upload-Warteschlange mit Fortschritt
- Kategorie vorwählen (PHOTO/LOGO)
- Auto-Titel aus Dateiname
- Sharp verarbeitet alle 6 Formate

### 4.7 Tab: 🌐 Websuche

```
🔍 [Grüner Veltliner Flasche                    ] [Suchen]

Quelle: (● Pixabay) (○ Pexels)

┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│        │ │        │ │        │ │        │ │        │
│  Bild  │ │  Bild  │ │  Bild  │ │  Bild  │ │  Bild  │
│        │ │        │ │        │ │        │ │        │
│  [✓]   │ │  [ ]   │ │  [✓]   │ │  [ ]   │ │  [ ]   │
└────────┘ └────────┘ └────────┘ └────────┘ └────────┘

Foto: John Doe / Pixabay · Frei verwendbar (CC0)

[2 Bilder ins Archiv übernehmen]
```

**Quellen:**

| Quelle | API | Kosten | Lizenz |
|--------|-----|--------|--------|
| **Pixabay** | pixabay.com/api | Gratis, 100/min | CC0, auf eigenem Server speicherbar |
| **Pexels** | api.pexels.com | Gratis, 200/h | Frei, Attribution empfohlen |

API-Keys werden in `.env` gespeichert:
```
PIXABAY_API_KEY=xxx
PEXELS_API_KEY=xxx
```

**Workflow:**
1. Suchbegriff eingeben (oder auto-generiert aus Produkt-Editor)
2. Ergebnisse als Grid
3. Per Checkbox auswählen
4. "Ins Archiv übernehmen" → Server lädt Bilder, verarbeitet mit Sharp, speichert in Media-Tabelle
5. `source` wird auf PIXABAY/PEXELS gesetzt, `sourceUrl` und `sourceAuthor` gespeichert

### 4.8 Bild-Detailansicht (/admin/media/[id])

```
← Zurück zum Archiv

┌──────────────────────┬────────────────────────────────┐
│                      │  Titel: [Schlumberger Brut   ] │
│   Großes Vorschau-   │  Alt:   [Flasche Schlumberg. ] │
│   bild (Original)    │  Typ:   [BOTTLE ▾]            │
│                      │  Kategorie: [PHOTO ▾]         │
│                      │  Quelle: Upload                │
│                      │  Hochgeladen: 10.04.2026       │
│                      │  Größe: 2.4 MB · 2560×1920    │
└──────────────────────┘                                │

Formate:
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ Original │ │   16:9   │ │   4:3    │ │   1:1    │ │   3:4    │
│ 2560×    │ │ 1920×    │ │ 1200×    │ │  800×    │ │  600×    │
│ 1920     │ │ 1080     │ │  900     │ │  800     │ │  800     │
│          │ │   [✂️]    │ │   [✂️]    │ │   [✂️]    │ │   [✂️]    │
└──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘

Klick auf ✂️ → Crop-Editor für das Format

Zugeordnet zu:
• Schlumberger Sparkling Brut (Weinkarte, Barkarte)
• [+ Produkt zuordnen]

[💾 Speichern]                     [🗑️ Bild löschen]
```

---

## 5. AUSWIRKUNGEN AUF BESTEHENDE BEREICHE

### 5.1 Produkt-Editor (src/components/admin/product-editor.tsx + product-images.tsx)

**Vorher (aktueller Stand):**
- `ProductImages` Komponente mit Drag & Drop Zone und "Bild hochladen" Button
- Upload geht direkt an `/api/v1/media/upload`
- Bilder sind nur am aktuellen Produkt sichtbar

**Nachher:**
```
📸 Bilder
  ┌──────┐  ┌──────┐  ┌──────┐
  │ ⭐🖼️ │  │ 🖼️   │  │ 🖼️   │   ← zugeordnete Bilder
  │BOTTLE│  │LABEL │  │AMBIANCE│
  └──────┘  └──────┘  └──────┘

  [🖼️ Aus Bildarchiv wählen]    ← öffnet Bildarchiv-Modal
```

**Funktionsweise "Aus Bildarchiv wählen":**
1. Öffnet ein Modal/Overlay mit dem Bildarchiv
2. Alle 4 Tabs verfügbar: Fotos, Logos, Hochladen, Websuche
3. Bilder die diesem Produkt bereits zugeordnet sind = markiert (✓)
4. Bei Websuche: Suchbegriffe automatisch aus Produktdaten generiert (siehe Abschnitt 6)
5. Benutzer wählt per Checkbox → "Übernehmen"
6. Modal schließt, Bilder erscheinen im Editor
7. Typ (BOTTLE/LABEL/etc.) und Hauptbild direkt am Produkt setzen

**Bestehende Drag & Drop Zone bleibt als Shortcut:**
- Bilder die dort hochgeladen werden, landen automatisch auch im Bildarchiv
- Schnellzugriff für eigene Fotos

### 5.2 Karten-Design-System (designConfig auf Menu + Location)

`Menu.designConfig` und `Location.designConfig` existieren bereits als Json-Felder. Das Bildarchiv integriert sich so:

**Digitale Ansicht (in designConfig.digital):**
- `header.logo` → speichert `mediaId` aus Bildarchiv (Kategorie LOGO)
- `header.backgroundImage` → speichert `mediaId` (Kategorie PHOTO/AMBIANCE)
- Produktbilder in Kartenansicht → automatisch aus ProductMedia (isPrimary), Format je nach Kontext

**Analoge Ansicht (in designConfig.analog):**
- `titlePage.logo` → `mediaId` aus Bildarchiv
- `titlePage.backgroundImage` → `mediaId`
- Flaschenfotos am Seitenende → automatisch aus ProductMedia (Typ BOTTLE), Format 3:4
- Logo in Fußzeile → `mediaId`

**Implementierung:**
- Überall wo im Design-Editor ein Bild gewählt wird → Bildarchiv-Picker (Modal) verwenden
- Config speichert die `mediaId`:
```json
{
  "digital": {
    "header": {
      "logo": "cuid_abc123",
      "backgroundImage": "cuid_def456"
    }
  }
}
```
- Render-Engine löst `mediaId` auf und verwendet das passende Format

**Location-Level:**
- `Location.designConfig` kann Standort-übergreifende Bilder speichern (z.B. Restaurant-Header)
- Karten erben vom Standort wenn kein eigenes Bild gesetzt

### 5.3 Gästeansicht (Public)

**HINWEIS:** `add-images-guest.sh` wurde bereits deployed. Prüfen was schon implementiert ist bevor neue Änderungen gemacht werden.

**Ziel-Zustand:**
- **Kartenansicht:** Produktbild als Thumbnail (Format 1:1 oder 4:3, steuerbar über designConfig)
- **Artikeldetail:** Großes Hauptbild (16:9 oder Original), Galerie bei mehreren Bildern
- **Karten-Header:** Logo + Hintergrundbild aus designConfig → aufgelöst aus Bildarchiv
- **Responsive:** `<picture>` mit srcset, Lazy Loading

### 5.4 Admin-Produktliste (List-Panel)

Thumbnail in der Produktliste anzeigen:
- Kleines Vorschaubild (32×32 oder 40×40) links neben dem Produktnamen
- Verwendet Thumb-Format
- Fallback: Typ-Badge (W/G/S) wenn kein Bild

### 5.5 QR-Code-Generierung

Logo im QR-Code aus Bildarchiv wählbar:
- Im QR-Code-Editor: Button "Logo aus Bildarchiv" → filtert auf Kategorie LOGO

### 5.6 PDF-Export

- Flaschenfotos: Automatisch BOTTLE-Bilder der Produkte, Format 3:4
- Logo in Kopf/Fußzeile: aus Bildarchiv via designConfig
- Titelseite: Logo + Hintergrundbild via designConfig

---

## 6. KI-SUCHBEGRIFF-GENERIERUNG

### 6.1 Automatische Suchbegriffe aus Produktdaten

Wenn der Benutzer vom Produkt-Editor ins Bildarchiv (Websuche) wechselt, werden aus den bestehenden Produktfeldern Suchbegriffe generiert:

**Für Wein (Product.type = WINE, mit ProductWineProfile):**
```
Felder: name, winery, grapeVarieties[], region, country
→ Suchbegriffe:
  1. "{winery} {grapeVarieties[0]} bottle"
  2. "{grapeVarieties[0]} wine bottle"
  3. "{country} wine {region}"
  4. "wine glass vineyard"
```

**Für Getränk (Product.type = DRINK, mit ProductBeverageDetail):**
```
Felder: name, brand, category
→ Suchbegriffe:
  1. "{name} cocktail" oder "{name} drink"
  2. "{category} bar"
  3. "cocktail glass bar ambiance"
```

**Für Speise (Product.type = FOOD):**
```
Felder: name, ProductGroup.name
→ Suchbegriffe:
  1. "{name}"
  2. "{name} restaurant plating"
  3. "{ProductGroup.name} fine dining"
```

**Implementierung:** Regel-basierte Logik (kein LLM nötig). Funktion die aus Produktfeldern Suchstrings zusammenbaut. Angezeigt als klickbare Chips unter dem Suchfeld.

---

## 7. API-ENDPUNKTE

### 7.1 Bestehend (erweitern)

**`POST /api/v1/media/upload`** – Bild hochladen
- Erweitern um: `category`, `source`, `title` in FormData
- Erweitern um: 6 Formate generieren statt aktuell 4
- `formats` JSON in Media speichern

**`DELETE /api/v1/media/[id]`** – Bild löschen
- Erweitern: Warnung wenn Zuordnungen existieren

**`PATCH /api/v1/media/[id]`** – Metadaten aktualisieren
- Erweitern um: `title`, `category`, `source`

### 7.2 Neu erstellen

**`GET /api/v1/media`** – Alle Bilder mit Filter/Suche/Pagination
```
Query-Params: ?category=PHOTO&type=BOTTLE&orientation=landscape&assigned=true&q=schlumberger&page=1&limit=24
```

**`PATCH /api/v1/media/[id]/crop`** – Format-Crop aktualisieren
```json
Body: { "format": "16:9", "cropX": 100, "cropY": 50, "cropW": 1800, "cropH": 1012 }
```
Server generiert das Format mit Sharp neu.

**`POST /api/v1/media/web-search`** – Websuche (Pixabay/Pexels)
```json
Body: { "query": "Grüner Veltliner bottle", "source": "pixabay", "page": 1 }
Response: [{ "previewUrl": "...", "fullUrl": "...", "width": 1920, "height": 1280, "author": "John Doe" }]
```

**`POST /api/v1/media/web-import`** – Bild aus Web importieren
```json
Body: { "url": "https://pixabay.com/...", "source": "PIXABAY", "sourceAuthor": "John Doe", "sourceUrl": "..." }
```
Server lädt Bild, verarbeitet mit Sharp, speichert in Media-Tabelle.

**`POST /api/v1/products/[id]/media`** – Bild einem Produkt zuordnen
```json
Body: { "mediaId": "cuid_abc", "mediaType": "BOTTLE", "isPrimary": true }
```
Erstellt ProductMedia-Eintrag.

**`DELETE /api/v1/products/[id]/media/[productMediaId]`** – Zuordnung entfernen
Bild bleibt im Archiv, nur ProductMedia-Eintrag wird gelöscht.

---

## 8. IMPLEMENTIERUNGS-REIHENFOLGE

### Phase 1: Schema & Grundgerüst
1. Prisma Schema erweitern: `MediaCategory` + `MediaSource` Enums, neue Felder auf Media
2. `npx prisma db push` – Schema synchronisieren
3. Verzeichnis `public/uploads/formats/` erstellen
4. Upload-API erweitern: 6 Formate generieren, `formats` JSON speichern
5. `GET /api/v1/media` mit Filter/Pagination bauen

### Phase 2: Admin-UI Bildarchiv
6. Icon-Bar: "Bildarchiv" Menüpunkt hinzufügen
7. Admin-Seite: `/admin/media/page.tsx` mit Tabs
8. Tab Fotos: Grid-Ansicht mit Filter
9. Tab Logos: Gefiltert auf Kategorie LOGO
10. Tab Hochladen: Massen-Upload mit Warteschlange
11. Bild-Detailansicht: `/admin/media/[id]/page.tsx`

### Phase 3: Websuche
12. `.env`: Pixabay API Key eintragen
13. `POST /api/v1/media/web-search` – Pixabay API Integration
14. `POST /api/v1/media/web-import` – Download + Sharp
15. Tab Websuche im Bildarchiv
16. KI-Suchbegriff-Generierung (Regel-basiert)

### Phase 4: Integration in bestehende Bereiche
17. Produkt-Editor: "Aus Bildarchiv wählen" Modal-Komponente
18. Produkt-Editor: Drag & Drop leitet ans Archiv weiter
19. Admin-Produktliste: Thumbnails anzeigen
20. Design-Editor: Bildarchiv-Picker für Header/Logo/Hintergrund

### Phase 5: Verfeinerung
21. Crop-Editor (Canvas-basiert) pro Format
22. PDF-Export: Flaschenfotos und Logos aus Bildarchiv
23. QR-Code: Logo aus Bildarchiv
24. Migration bestehender Bilder: Fehlende Formate für vorhandene Uploads nachgenerieren

---

## 9. TECHNISCHE HINWEISE

### Sharp-Konfiguration (erweitert)
```javascript
const img = sharp(buffer).rotate();

// Original (existiert)
await img.clone().webp({ quality: 90 }).toFile(`${basePath}/original/${filename}.webp`);

// 16:9 (NEU)
await img.clone().resize(1920, 1080, { fit: 'cover', position: 'center' }).webp({ quality: 85 }).toFile(`${basePath}/formats/${filename}-16x9.webp`);

// 4:3 (NEU)
await img.clone().resize(1200, 900, { fit: 'cover', position: 'center' }).webp({ quality: 85 }).toFile(`${basePath}/formats/${filename}-4x3.webp`);

// 1:1 (NEU)
await img.clone().resize(800, 800, { fit: 'cover', position: 'center' }).webp({ quality: 85 }).toFile(`${basePath}/formats/${filename}-1x1.webp`);

// 3:4 (NEU)
await img.clone().resize(600, 800, { fit: 'cover', position: 'center' }).webp({ quality: 85 }).toFile(`${basePath}/formats/${filename}-3x4.webp`);

// Thumb (existiert)
await img.clone().resize(200, 200, { fit: 'cover', position: 'center' }).webp({ quality: 75 }).toFile(`${basePath}/thumb/${filename}.webp`);

// Large + Medium (existieren, für Rückwärtskompatibilität beibehalten)
await img.clone().resize(1200, null, { withoutEnlargement: true }).webp({ quality: 85 }).toFile(`${basePath}/large/${filename}.webp`);
await img.clone().resize(600, null, { withoutEnlargement: true }).webp({ quality: 80 }).toFile(`${basePath}/medium/${filename}.webp`);
```

### Pixabay API
```javascript
// .env: PIXABAY_API_KEY=dein-key
const res = await fetch(
  `https://pixabay.com/api/?key=${process.env.PIXABAY_API_KEY}&q=${encodeURIComponent(query)}&image_type=photo&per_page=20&page=${page}`
);
const data = await res.json();
// data.hits[].webformatURL → Vorschau (640px)
// data.hits[].largeImageURL → Download (1280px)
// data.hits[].user → Fotograf
```

### Bestehende Konfiguration (nicht ändern)
- `next.config.mjs` (nicht .ts!)
- Nginx: `client_max_body_size 10M` (bereits konfiguriert)
- Sharp: `sharp@0.33.2` (bereits installiert)
- Upload-API: `src/app/api/v1/media/upload/route.ts` (erweitern, nicht neu erstellen)

### Migration bestehender Bilder
Bestehende Bilder in `public/uploads/large/` und `public/uploads/thumb/` bleiben kompatibel. Ein Migrations-Script generiert die fehlenden Formate (16:9, 4:3, 1:1, 3:4) für alle vorhandenen Bilder nach und füllt das `formats` JSON-Feld.

---

## 10. ZUSAMMENFASSUNG

| Bereich | Aktuell | Nach Bildarchiv |
|---------|---------|-----------------|
| Bilder-Speicher | Pro Produkt, isoliert | Zentrales Bildarchiv |
| Upload | Nur vom PC im Produkt-Editor | PC + Websuche (Pixabay) + Bildarchiv-Picker |
| Formate | 4 (original/large/medium/thumb) | 8 (+ 16:9, 4:3, 1:1, 3:4) mit Crop-Editor |
| Wiederverwendung | Nicht möglich | Ein Bild → beliebig viele Produkte |
| Logos | Nicht kategorisiert | Eigene Kategorie, PNG mit Transparenz |
| Suche | Keine | Volltext + Filter (Typ, Orientierung, Zuordnung) |
| Karten-Design | Kein Bild-Picker | Header/Logo/Hintergrund aus Bildarchiv via designConfig |
| PDF | Begrenzt | Flaschenfotos, Logos aus Bildarchiv |
| Admin | Kein Überblick | Eigener Menüpunkt mit Grid, Filter, Massen-Upload |
