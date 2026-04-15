# MenuCard Pro – UI-Redesign
## Detaillierte Implementierungsanweisung
## Version: FINAL · Stand: 13.04.2026
## Basiert auf Visily-Designs (17 Screens) + aktuellem Prisma-Schema

---

## 1. ÜBERBLICK

### Was gemacht wird
Komplettes visuelles Redesign der gesamten Software – Gästeansicht UND Admin-Backend. Die Funktionalität bleibt identisch, nur das Erscheinungsbild wird modernisiert.

### Kernprinzipien
1. **Design-Token-System:** Alle Farben, Schriften, Abstände, Radien als CSS Custom Properties. Layout änderbar ohne Komponenten anzufassen.
2. **Material Symbols:** Alle Emojis (🍷📦📋 etc.) werden durch Google Material Symbols (Outlined) ersetzt. Konsistentes, professionelles Icon-System.
3. **Font-Entscheidung vor Programmierung:** Token-Datei wird zuerst erstellt, vom Benutzer freigegeben, dann erst programmiert.
4. **4 Gäste-Templates:** Elegant, Modern, Klassisch, Minimal – jedes mit eigenem Charakter.

### Betroffene Bereiche
- **Admin:** Dashboard, Produktliste, Produkt-Editor, Kartenverwaltung, Weinkarte, Bildarchiv, Template-Auswahl, Einstellungen, Icon-Bar
- **Gästeansicht:** Menü-Übersicht, Artikelliste, Artikeldetail (je 4 Templates)
- **Komponenten:** Buttons, Inputs, Cards, Badges, Navigation, Modals

---

## 2. DESIGN-TOKEN-SYSTEM

### 2.1 Token-Datei (src/styles/tokens.css)

Diese Datei ist die EINZIGE Stelle an der Farben/Schriften/Abstände definiert werden. Alles andere referenziert nur Tokens. Datei wird VOR der Programmierung dem Benutzer zur Freigabe vorgelegt.

```css
:root {
  /* ============================================ */
  /* FARBEN – hier ändern = überall geändert      */
  /* ============================================ */
  
  /* Primärfarbe (Akzent) */
  --color-primary: #DD3C71;
  --color-primary-hover: #C42D60;
  --color-primary-light: #FDF2F5;
  --color-primary-subtle: rgba(221, 60, 113, 0.08);
  
  /* Neutrale Farben */
  --color-bg: #FFFFFF;
  --color-bg-subtle: #FAFAFB;
  --color-bg-muted: #F3F3F6;
  --color-surface: #FFFFFF;
  --color-surface-hover: #F9F9FB;
  
  /* Text */
  --color-text: #1A1A1A;
  --color-text-secondary: #565D6D;
  --color-text-muted: #8E8E8E;
  --color-text-inverse: #FFFFFF;
  
  /* Borders */
  --color-border: #E5E7EB;
  --color-border-subtle: rgba(0, 0, 0, 0.04);
  --color-border-focus: var(--color-primary);
  
  /* Status */
  --color-success: #16A34A;
  --color-success-light: #F0FDF4;
  --color-warning: #F59E0B;
  --color-warning-light: #FFFBEB;
  --color-error: #E05252;
  --color-error-light: #FEF2F2;
  --color-info: #3B82F6;
  --color-info-light: #EFF6FF;
  
  /* Admin Sidebar */
  --color-sidebar-bg: #FFFFFF;
  --color-sidebar-text: #565D6D;
  --color-sidebar-active-bg: var(--color-primary-light);
  --color-sidebar-active-text: var(--color-primary);
  --color-sidebar-hover-bg: #F3F3F6;
  --color-sidebar-border: #F3F3F6;
  
  /* Badges */
  --color-badge-new: #DD3C71;
  --color-badge-top: #F59E0B;
  --color-badge-bestseller: #16A34A;
  --color-badge-hot: #E05252;
  --color-badge-vegetarian: #16A34A;
  --color-badge-vegan: #059669;
  --color-badge-signature: #7C3AED;
  
  /* Marge-Farben (Admin Preiskalkulation) */
  --color-margin-good: #16A34A;
  --color-margin-ok: #F59E0B;
  --color-margin-bad: #E05252;
  
  /* Übersetzungs-Status */
  --color-translate-default: #9CA3AF;
  --color-translate-changed: #F59E0B;
  --color-translate-done: #16A34A;

  /* ============================================ */
  /* TYPOGRAFIE                                    */
  /* ============================================ */
  
  /* Schriftfamilien */
  --font-heading: 'Playfair Display', ui-serif, Georgia, serif;
  --font-body: 'Inter', ui-sans-serif, system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', ui-monospace, monospace;
  --font-eyebrow: 'Inter', sans-serif;
  
  /* Schriftgrößen */
  --text-xs: 0.75rem;     /* 12px */
  --text-sm: 0.875rem;    /* 14px */
  --text-base: 1rem;      /* 16px */
  --text-lg: 1.125rem;    /* 18px */
  --text-xl: 1.25rem;     /* 20px */
  --text-2xl: 1.5rem;     /* 24px */
  --text-3xl: 1.875rem;   /* 30px */
  --text-4xl: 2.25rem;    /* 36px */
  
  /* Schriftgewichte */
  --font-normal: 400;
  --font-medium: 500;
  --font-semibold: 600;
  --font-bold: 700;
  
  /* Zeilenhöhen */
  --leading-tight: 1.25;
  --leading-normal: 1.5;
  --leading-relaxed: 1.625;

  /* ============================================ */
  /* ABSTÄNDE & LAYOUT                             */
  /* ============================================ */
  
  --spacing-unit: 4px;    /* Basis: 4px Grid */
  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
  --spacing-xl: 32px;
  --spacing-2xl: 48px;
  --spacing-3xl: 64px;
  
  /* Border Radius */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-full: 9999px;
  
  /* Schatten */
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.05), 0 2px 4px rgba(0, 0, 0, 0.03);
  --shadow-lg: 0 10px 25px rgba(0, 0, 0, 0.05), 0 8px 10px rgba(0, 0, 0, 0.03);
  --shadow-card: 0 1px 3px rgba(0, 0, 0, 0.08);

  /* ============================================ */
  /* ADMIN LAYOUT                                  */
  /* ============================================ */
  
  --sidebar-width: 200px;
  --sidebar-collapsed-width: 56px;
  --header-height: 56px;
  --list-panel-width: 400px;
  --list-panel-min-width: 280px;
  --list-panel-max-width: 600px;
  
  /* ============================================ */
  /* ÜBERGÄNGE                                     */
  /* ============================================ */
  
  --transition-fast: 150ms ease;
  --transition-normal: 250ms ease;
  --transition-slow: 350ms ease;
}
```

### 2.2 Wie Tokens verwendet werden

**In Tailwind (tailwind.config.ts):**
```typescript
theme: {
  extend: {
    colors: {
      primary: {
        DEFAULT: 'var(--color-primary)',
        hover: 'var(--color-primary-hover)',
        light: 'var(--color-primary-light)',
        subtle: 'var(--color-primary-subtle)',
      },
      surface: {
        DEFAULT: 'var(--color-surface)',
        hover: 'var(--color-surface-hover)',
      },
      // ... alle Token-Farben mappen
    },
    fontFamily: {
      heading: 'var(--font-heading)',
      body: 'var(--font-body)',
    },
    borderRadius: {
      DEFAULT: 'var(--radius-md)',
    },
  }
}
```

**In Komponenten:**
```tsx
// VORHER (hardcoded):
<button className="bg-blue-600 text-white rounded-lg">

// NACHHER (Token-basiert):
<button className="bg-primary text-text-inverse rounded-md">
```

**Ergebnis:** Farbe ändern = nur `tokens.css` anpassen. Kein einziger Komponenten-Change nötig.

---

## 3. ICON-SYSTEM: GOOGLE MATERIAL SYMBOLS

### 3.1 Setup

Material Symbols via CDN in `src/app/layout.tsx` einbinden:

```html
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" />
```

### 3.2 Icon-Komponente

```tsx
// src/components/ui/icon.tsx
interface IconProps {
  name: string;           // Material Symbol Name, z.B. "restaurant_menu"
  size?: number;          // 20, 24, 32, 40, 48
  weight?: number;        // 100-700
  fill?: boolean;         // Ausgefüllt oder Outlined
  className?: string;
}

export function Icon({ name, size = 24, weight = 400, fill = false, className = '' }: IconProps) {
  return (
    <span
      className={`material-symbols-outlined ${className}`}
      style={{
        fontSize: size,
        fontVariationSettings: `'FILL' ${fill ? 1 : 0}, 'wght' ${weight}, 'GRAD' 0, 'opsz' ${size}`
      }}
    >
      {name}
    </span>
  );
}
```

### 3.3 Icon-Mapping (Emojis → Material Symbols)

**Admin Icon-Bar:**

| Aktuell (Emoji) | Neu (Material Symbol) | Name |
|-----------------|----------------------|------|
| 📊 Dashboard | `dashboard` | dashboard |
| 📦 Produkte | `inventory_2` | inventory_2 |
| 📋 Karten | `menu_book` | menu_book |
| 📱 QR-Codes | `qr_code_2` | qr_code_2 |
| 🖼️ Bildarchiv | `photo_library` | photo_library |
| 📈 Analytics | `analytics` | analytics |
| ⚙️ Einstellungen | `settings` | settings |
| 🔄 Neu laden | `refresh` | refresh |
| 🚪 Logout | `logout` | logout |

**Produkttypen:**

| Aktuell | Neu | Name |
|---------|-----|------|
| 🍷 Wein | `wine_bar` | wine_bar |
| 🍸 Getränk | `local_bar` | local_bar |
| 🍽️ Speise | `restaurant` | restaurant |
| ☕ Heißgetränk | `coffee` | coffee |
| 🍺 Bier | `sports_bar` | sports_bar |

**Status & Aktionen:**

| Aktuell | Neu | Name |
|---------|-----|------|
| ✅ Aktiv | `check_circle` (fill) | check_circle |
| 🚫 Ausgetrunken | `block` | block |
| ⭐ Hauptbild | `star` (fill) | star |
| ✂️ Crop | `crop` | crop |
| 🗑️ Löschen | `delete` | delete |
| 💾 Speichern | `save` | save |
| ➕ Hinzufügen | `add` | add |
| ✕ Schließen | `close` | close |
| 🔍 Suche | `search` | search |
| 📤 Upload | `upload` | upload |
| 🌐 Web | `language` | language |

**Gästeansicht – Kategorie-Icons:**

| Kategorie | Material Symbol |
|-----------|----------------|
| Vorspeisen | `tapas` |
| Hauptgerichte | `restaurant` |
| Pasta | `ramen_dining` |
| Desserts | `cake` |
| Weinkarte | `wine_bar` |
| Kaffee & Digestif | `coffee` |
| Salate | `eco` |
| Burger | `lunch_dining` |
| Pizza | `local_pizza` |

**Allergene:**

| Allergen | Material Symbol |
|----------|----------------|
| Gluten | `grain` |
| Laktose | `water_drop` |
| Nüsse | `psychiatry` |
| Fisch | `set_meal` |
| Eier | `egg` |

---

## 4. ADMIN-BACKEND REDESIGN

### 4.1 Sidebar (ersetzt Icon-Bar)

Basierend auf Visily-Design Seite 13-17: Helle Sidebar mit Text-Labels, aktiver Menüpunkt mit rosa Hintergrund.

```
┌────────────────────┬─────────────────────────────────────────────┐
│                    │                                             │
│  🍴 MenuCard Pro   │  Workspace                                  │
│     ADMIN PANEL    │                                             │
│                    │                                             │
│  ┈┈┈┈┈┈┈┈┈┈┈┈┈┈  │                                             │
│                    │                                             │
│  ⬡ Dashboard       │                                             │
│  🍴 Menüverwaltung │  ← aktiv: rosa Hintergrund, rosa Text      │
│  🍷 Weinkarte      │                                             │
│  🖼 Bildarchiv     │                                             │
│  📱 QR-Codes       │                                             │
│  🎨 Templates      │                                             │
│  ⚙ Einstellungen  │                                             │
│                    │                                             │
│                    │                                             │
│                    │                                             │
│  ┈┈┈┈┈┈┈┈┈┈┈┈┈┈  │                                             │
│  👤 Erich R.       │                                             │
│     Administrator  │                                             │
└────────────────────┴─────────────────────────────────────────────┘
```

**Styling (aus Tokens):**
- Breite: `var(--sidebar-width)` = 200px
- Hintergrund: `var(--color-sidebar-bg)` = weiß
- Rechter Border: 1px `var(--color-sidebar-border)`
- Aktiver Menüpunkt: `var(--color-sidebar-active-bg)` + `var(--color-sidebar-active-text)`
- Icons: Material Symbols Outlined, 24px, weight 400
- Text: `var(--font-body)`, `var(--text-sm)`, `var(--color-sidebar-text)`
- User-Info unten: Avatar (Kreis) + Name + Rolle

### 4.2 Dashboard (Seite 13 Referenz)

```
┌──────────┬──────────────────────────────────────────────────────┐
│ SIDEBAR  │  Übersicht (Dashboard)                                │
│          │                                                       │
│          │  Guten Morgen, Erich! 👋                              │
│          │  Hier ist die Zusammenfassung für Ihr Restaurant.     │
│          │                                                       │
│          │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐│
│          │  │ € icon   │ │ 📋 icon  │ │ 📈 icon  │ │ 👥 icon  ││
│          │  │ Produkte │ │ Karten   │ │ QR-Scans │ │ Sprachen ││
│          │  │ 322      │ │ 9        │ │ 1.247    │ │ DE/EN    ││
│          │  └──────────┘ └──────────┘ └──────────┘ └──────────┘│
│          │                                                       │
│          │  ┌─────────────────────────┐ ┌────────────────────┐  │
│          │  │ Letzte Änderungen       │ │ Top Produkte       │  │
│          │  │ (Timeline)              │ │ (mit Thumbnails)   │  │
│          │  └─────────────────────────┘ └────────────────────┘  │
│          │                                                       │
│          │  ┌─────────────────────────┐ ┌────────────────────┐  │
│          │  │ Live-Design Status      │ │ Schnellzugriff     │  │
│          │  │ Template: Elegant       │ │ [Menü bearbeiten]  │  │
│          │  │ [Vorschau] [Wechseln]   │ │ [Design anpassen]  │  │
│          │  └─────────────────────────┘ └────────────────────┘  │
└──────────┴──────────────────────────────────────────────────────┘
```

**KPI-Kacheln:** Weiße Card mit `var(--shadow-card)`, Icon oben links (Material Symbol, in farbigem Kreis), Wert groß, Label klein.

### 4.3 Menüverwaltung (Seite 14 Referenz)

```
┌──────────┬──────────────────────┬──────────────────────────────┐
│ SIDEBAR  │  Menüstruktur        │  Gericht bearbeiten          │
│          │  + Kategorie         │  [Verwerfen] [💾 Speichern]  │
│          │                      │                              │
│          │  ▸ Vorspeisen (4)    │  GERICHT-BILD                │
│          │    Bruschetta  8,50€ │  [🖼 Bild ändern]            │
│          │    Carpaccio  14,90€ │                              │
│          │    Burrata    12,50€ │  Name: [                   ] │
│          │    + Gericht hinzuf. │  Preis: [                  ] │
│          │                      │                              │
│          │  ▸ Hauptspeisen (8)  │  Kurzbeschreibung:           │
│          │  ▸ Desserts (3)      │  [                          ]│
│          │                      │                              │
│          │  ┌────────────────┐  │  Detaillierte Beschreibung:  │
│          │  │ DESIGN-TIPP    │  │  [                          ]│
│          │  │ Bilder mit     │  │                              │
│          │  │ hohem Kontrast │  │  EIGENSCHAFTEN  ALLERGENE    │
│          │  │ funktionieren  │  │  [Vegan] [+]   ☑ Sesam      │
│          │  │ am besten...   │  │                ☑ Nüsse       │
│          │  └────────────────┘  │                              │
└──────────┴──────────────────────┴──────────────────────────────┘
```

**Referenz:** Visily Seite 14. Zwei-Spalten-Layout: Links Baumstruktur, rechts Editor.

### 4.4 Weinkarten-Verwaltung (Seite 15 Referenz)

```
┌──────────┬──────────────┬───────────────────────┬──────────────┐
│ SIDEBAR  │ 🔻 Filter    │  Tabelle               │ Detail-Panel │
│          │              │                        │ (Slide-in)   │
│          │ Regionen     │ Name  Region  Rebsorte │              │
│          │ ☐ Frankreich │ ──────────────────────│ Château M.   │
│          │ ☐ Italien    │ Château  Bordeaux ...  │ [Bild]       │
│          │ ☐ Österreich │ Riesling Pfalz   ...  │ Jahrgang     │
│          │              │ Tignanel Toskana ...   │ Preis        │
│          │ Weintyp      │                        │ Region       │
│          │ ☐ Rotwein    │                        │ Rebsorte     │
│          │ ☐ Weißwein   │                        │ Bestand      │
│          │              │                        │              │
│          │ Lagerstatus  │                        │ [Speichern]  │
│          │ ☐ Niedrig    │                        │ [Löschen]    │
└──────────┴──────────────┴───────────────────────┴──────────────┘
```

**Referenz:** Visily Seite 15. Drei-Spalten: Filter links, Tabelle Mitte, Detail-Slide rechts. Rotwein/Weißwein/Rosé mit farbigen Punkten. Bestandswarnung rot.

### 4.5 Template-Auswahl (Seite 16 Referenz)

```
┌──────────┬─────────────────────────────────┬────────────────────┐
│ SIDEBAR  │  Template-Auswahl               │  Live Vorschau     │
│          │                                  │  Echtzeit-Simulator│
│          │  Wählen Sie Ihren Stil           │                    │
│          │                                  │  ┌──────────────┐  │
│          │  ┌───────────┐ ┌───────────┐    │  │ 📱 Handy     │  │
│          │  │ Klassisch │ │ Modern ✓  │    │  │              │  │
│          │  │ Serif     │ │ Sans-Serif│    │  │  Vorschau    │  │
│          │  │ [Wählen]  │ │ Aktiv     │    │  │  der Karte   │  │
│          │  └───────────┘ └───────────┘    │  │  mit aktuellem│  │
│          │  ┌───────────┐ ┌───────────┐    │  │  Template    │  │
│          │  │ Elegant   │ │ Minimal   │    │  │              │  │
│          │  │ Weißraum  │ │ Nur Text  │    │  └──────────────┘  │
│          │  │ [Wählen]  │ │ [Wählen]  │    │  [iOS] [Android]   │
│          │  └───────────┘ └───────────┘    │                    │
│          │                                  │                    │
│          │  Detail-Vergleich (Tabelle)      │                    │
└──────────┴─────────────────────────────────┴────────────────────┘
```

### 4.6 Einstellungen (Seite 17 Referenz)

Sub-Navigation links (Allgemein, Sprache & Region, Demo-Daten, Konto), Formular rechts. Branding-Bereich mit Logo-Upload aus Bildarchiv.

---

## 5. GÄSTEANSICHT – 4 TEMPLATES

### 5.1 Template "Elegant" (Visily Seite 1-3)

**Charakter:** Ruhig, hochwertig, Serif-typografisch, dezente Icons
**Schriften:** Playfair Display (Überschriften), Inter (Fließtext)
**Farben:** Weiß, #DD3C71 Akzent, #565D6D Sekundärtext
**Layout:**
- Menü-Übersicht: Kategorie-Karten mit Icon + Artikelanzahl-Badge + Beschreibung
- Artikelliste: Thumbnail links (rund), Name + Beschreibung + Preis rechts, Badges (Klassiker/Vegetarisch/Empfehlung)
- Artikeldetail: Header-Bild, Allergene als Icons mit Label, Hauptzutaten-Box, Preis groß unten

### 5.2 Template "Modern" (Visily Seite 4-6)

**Charakter:** Bildlastig, bold, hoher Kontrast
**Schriften:** Montserrat (Headlines + Body)
**Farben:** Weiß, Schwarz, #DD3C71, große Bilder mit Overlay-Text
**Layout:**
- Menü-Übersicht: 2-Spalten Bild-Grid mit Kategorie-Namen als Overlay
- Artikelliste: Vollbreite Produktbilder, Preis rechts, Tags (Neu/Scharf), Zubereitungszeit-Badge
- Artikeldetail: Hero-Bild, Badges (Bestseller/Hot), Info-Icons (Zubereitungszeit/Kalorien/Frisch/Bio), Extras/Modifikatoren mit Preisen, Mengenauswahl + Warenkorb-Button

### 5.3 Template "Klassisch" (Visily Seite 7-9)

**Charakter:** Fine Dining, französisch inspiriert, Nummerierung, Storytelling
**Schriften:** Playfair Display (Headlines), leichte Kursiv-Beschreibungen
**Farben:** Schwarz/Weiß, minimal Akzent, viel Weißraum
**Layout:**
- Menü-Übersicht: Gangnummern (01, 02, 03...), große Kategoriebilder, Untertitel, Zitat oben
- Artikelliste: Nummerierte Produkte (01-05), Versalien-Namen, Kursiv-Beschreibungen, Tag-Badges (Signature/Neu)
- Artikeldetail: Zentriert, "Die Geschichte des Gerichts", Zutaten-Box, Allergene aufklappbar, Preis prominent

### 5.4 Template "Minimal" (Visily Seite 10-12)

**Charakter:** Reine Text-Hierarchie, maximale Lesbarkeit, keine Bilder
**Schriften:** Fette Grotesk (Headlines), Regular (Body)
**Farben:** Schwarz/Weiß, Akzent nur für Badge "Neu"
**Layout:**
- Menü-Übersicht: Kategorie-Namen als fette Überschriften, Artikelanzahl-Badge, Pfeil-Button, Wochenkarte-Banner
- Artikelliste: Tab-Filter (Alle/Getränke/Speisen/...), Produktname fett + Preis rechts, Beschreibung kursiv, Allergene inline als Codes [A, G, M]
- Artikeldetail: Name + Preis oben, Zubereitungszeit + Kalorien, Beschreibung, Eigenschaften als Pill-Tags, Zutaten-Text

---

## 6. KOMPONENTEN-BIBLIOTHEK

### 6.1 Buttons

```tsx
// Varianten über Token-Farben:
// Primary: bg-primary text-white rounded-md
// Secondary: bg-transparent border border-border text-text rounded-md
// Ghost: bg-transparent text-primary hover:bg-primary-subtle rounded-md
// Danger: bg-error text-white rounded-md

// Größen:
// sm: px-3 py-1.5 text-sm
// md: px-4 py-2 text-base
// lg: px-6 py-3 text-lg

<Button variant="primary" size="md" icon="save">
  Speichern
</Button>
```

### 6.2 Input-Felder

```tsx
// Standard: border border-border rounded-md px-4 py-2 text-base
// Focus: border-primary ring-1 ring-primary-light
// Error: border-error
// Label über dem Feld, Hilfetext darunter
```

### 6.3 Cards

```tsx
// Admin-Card: bg-surface rounded-lg shadow-card p-6 border border-border-subtle
// KPI-Card: wie Card + farbiges Icon oben links + Trend-Badge
// Template-Card: wie Card + aktiv-State mit primary Border
```

### 6.4 Badges/Tags

```tsx
// Pill: px-3 py-1 rounded-full text-xs font-medium
// Badge: px-2 py-0.5 rounded text-xs
// Farbe je nach Typ (aus Tokens):
// Vegetarisch → success, Neu → primary, Empfehlung → primary, Scharf → error
```

### 6.5 Navigation (Gästeansicht)

```tsx
// Bottom Tab Bar: fixed unten, 4-5 Items, Material Icons
// Icon + Label, aktiv = primary Farbe
// Höhe: 56px + safe-area-inset
```

---

## 7. GOOGLE FONTS LADEN

In `src/app/layout.tsx`:

```tsx
import { Playfair_Display, Inter, Montserrat } from 'next/font/google';

const playfair = Playfair_Display({
  subsets: ['latin'],
  variable: '--font-playfair',
  display: 'swap',
});

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
});

const montserrat = Montserrat({
  subsets: ['latin'],
  variable: '--font-montserrat',
  display: 'swap',
});
```

Material Symbols via CDN:
```html
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" />
```

---

## 8. IMPLEMENTIERUNGS-REIHENFOLGE

### Phase 1: Foundation (keine sichtbaren Änderungen)
1. `src/styles/tokens.css` erstellen → **BENUTZER FREIGABE EINHOLEN**
2. `tailwind.config.ts` Token-Mapping
3. `<Icon>` Komponente erstellen
4. Material Symbols CDN + Google Fonts einbinden
5. Button, Input, Card, Badge Basis-Komponenten

### Phase 2: Admin-Backend
6. Sidebar neu (Material Icons, heller Stil, User-Info unten)
7. Dashboard neu (KPI-Kacheln, Schnellzugriff)
8. Alle Emojis → Material Symbols austauschen
9. Produktliste: Styling anpassen (Token-Farben, abgerundete Cards)
10. Produkt-Editor: Styling anpassen
11. Kartenverwaltung: Styling anpassen
12. Weinkarte: Drei-Spalten-Layout (Filter + Tabelle + Detail-Slide)

### Phase 3: Gästeansicht
13. Template "Elegant" implementieren
14. Template "Modern" implementieren
15. Template "Klassisch" implementieren
16. Template "Minimal" implementieren
17. Template-Switcher über designConfig

### Phase 4: Integration
18. Template-Auswahl Seite im Admin (mit Live-Vorschau)
19. Einstellungen-Seite (Branding, Logo)
20. Bildarchiv: Styling an neues Design anpassen
21. QR-Code-Verwaltung: Styling anpassen

---

## 9. VISILY-REACT-EXPORT

Die exportierten React-Dateien liegen als ZIP bereit. Sie sind NICHT 1:1 verwendbar (Visily generiert eigenständige Vite-Apps), aber dienen als Referenz für:
- Exakte Farben und Abstände
- Komponenten-Struktur und Klassennamen
- Layout-Breakpoints

Dateien:
```
visily-responsive-multiscreens-react.zip
├── gastansicht-elegant-menuuebersicht/
├── gastansicht-elegant-artikelliste/
├── gastansicht-elegant-artikeldetail/
├── gastansicht-modern-menuuebersicht/
├── gastansicht-modern-artikelliste/
├── gastansicht-modern-artikeldetail/
├── gastansicht-klassisch-menuuebersicht/
├── gastansicht-klassisch-artikelliste/
├── gastansicht-klassisch-artikeldetail/
├── gastansicht-minimalistisch-menuuebersicht/
├── gastansicht-minimalistisch-artikelliste/
└── gastansicht-minimalistisch-artikeldetail/
```

Aus den Exports extrahierte Design-Werte:
- Akzentfarbe: `#DD3C71`
- Text primär: `#1A1A1A`
- Text sekundär: `#565D6D`
- Text muted: `#8E8E8E`
- Background subtle: `#FAFAFB`
- Background muted: `#F3F3F6`
- Selection: `rgba(219, 39, 119, 0.2)`

---

## 10. WICHTIGE HINWEISE

### Was sich NICHT ändert
- Prisma-Schema – keine DB-Änderungen
- API-Endpunkte – keine Backend-Änderungen
- Geschäftslogik – nur visuelles Redesign
- Funktionalität – alles bleibt wie es ist

### Reihenfolge der Freigabe
1. **Zuerst:** Token-Datei (Farben + Schriften) dem Benutzer zeigen
2. **Benutzer entscheidet:** Farben und Schriften anpassen
3. **Dann erst:** Programmierung starten

### Bestehende Konfiguration
- `next.config.mjs` (nicht .ts!)
- Sharp `sharp@0.33.2`
- PM2, Nginx (unverändert)
- `Menu.designConfig` und `Location.designConfig` (Json-Felder bereits vorhanden)

### Visily-Export als Projektdatei
Die ZIP-Datei `visily-responsive-multiscreens-react.zip` sollte dem Cowork-Projekt hinzugefügt werden als Design-Referenz. Die PDF `visily-multiscreens.pdf` enthält alle 17 Screens als visuelle Referenz.
