# MenuCard Pro – Karten-Design-System
## Detaillierte Implementierungsanweisung
## Version: FINAL · Stand: 10.04.2026

---

## 1. ÜBERBLICK & PRINZIPIEN

### Was gebaut wird
Ein Karten-Design-System das jede Karte (Weinkarte, Barkarte, Gourmet-Menü) individuell gestaltbar macht. Es gibt zwei strikt getrennte Bereiche:

- **Digitale Ansicht** – Was der Gast am Bildschirm sieht (Handy, Desktop, Embed)
- **Analoge Ansicht** – PDF-Download für Druck/Papierkarten

Beide Bereiche haben eigene Render-Engines, eigene Konfigurationen und eigene Vorlagen. Sie teilen die gleiche Produktdatenbank, werden aber unabhängig voneinander gestaltet.

### Design-Prinzipien
1. **Template-First:** Der Benutzer startet nie bei Null. Immer eine Vorlage als Ausgangspunkt.
2. **Alles überschreibbar:** Nach Template-Wahl kann jeder Parameter einzeln angepasst werden.
3. **Live-Vorschau:** Jede Änderung ist sofort sichtbar – kein Speichern-und-Hoffen.
4. **Einfach für Anfänger, mächtig für Profis:** Template wählen reicht für 80% der Fälle. Die restlichen 20% können alles feintunen.
5. **Daten einmal pflegen:** Produkte, Preise, Übersetzungen existieren zentral. Design ist nur die Darstellungsschicht.

### Referenzen & Wettbewerbsanalyse
- **WinePad:** Mächtige Sortier-Hierarchie (10 Ebenen, up/down, pro Ebene Checkboxen). Aber: technische UI, keine Vorschau, kein Design-Editor. → Wir übernehmen die Hierarchie-Logik, verpacken sie in modernes UI.
- **Menury:** Maximal einfach (4 Schritte: Anlegen → Design → Kategorien → Sprache). Aber: keine Feinsteuerung, Custom nur per manuellem Service. → Wir bieten Self-Service-Customization.
- **iMenuPro:** Auto-Formatierung, Style-Wechsel ohne Neutippen, Live-Sync Print/Digital/QR. → Wir übernehmen das Konzept "Inhalt bleibt, nur Darstellung ändert sich."
- **Bestehende Sonnblick-Weinkarte (PDF):** Handschrift-Header, 3-stufige Hierarchie (Kategorie→Land→Rebsorte), Flaschenfotos am Seitenende, zweisprachig DE/EN, gepunktetes Inhaltsverzeichnis. → Das ist der Qualitätsstandard den wir mindestens erreichen müssen.

---

## 2. DATENBANK

### Schema-Erweiterung

Auf der `Menu`-Tabelle ein JSON-Feld:

```prisma
model Menu {
  // ... bestehende Felder ...
  designConfig  Json?   // Design-Konfiguration
}
```

Struktur:
```json
{
  "digital": { ... },
  "analog": { ... }
}
```

Jeder Bereich ist unabhängig. Wenn ein Feld `null` ist, wird der Template-Default verwendet.

---

## 3. VORLAGEN (für beide Bereiche)

4 kuratierte Vorlagen die als Startpunkt dienen:

| Vorlage | Für | Stil |
|---------|-----|------|
| **Elegant** | Weinkarten, Gala-Menüs | Serif (Playfair Display), warme Töne, viel Weißraum, feine Linien |
| **Modern** | Barkarte, Cocktails | Sans-Serif (Inter), dunkler Hintergrund möglich, große Bilder, Badges |
| **Klassisch** | Restaurant-Menüs, Themenabende | Bordüren, Menügang-Struktur, zentriert, Fixpreis prominent |
| **Minimal** | Frühstück, Room Service, Minibar | Max. Lesbarkeit, große Schrift, wenig Dekoration, Listen-Format |

Jede Vorlage definiert Defaults für ALLE Konfigurationsparameter. Der Benutzer überschreibt nur was er ändern will.

Verfügbare Schriften (kuratiert, via next/font geladen):
- **Serif:** Playfair Display, Cormorant Garamond, Libre Baskerville
- **Sans:** Source Sans 3, Inter, Lato, Open Sans
- **Display:** Josefin Sans, Raleway, Montserrat
- **Script (nur Analog):** Dancing Script, Great Vibes, Sacramento

---

## 4. DIGITALE ANSICHT

### 4.1 Admin-UI: Design-Editor

Im Admin unter Karten → Karte auswählen erscheint ein neuer Tab "Design" neben dem bestehenden Karten-Inhalt-Tab.

```
┌──────┬────────────┬──────────────────────────┬───────────────────┐
│ ICON │  KARTEN-   │    DESIGN-EDITOR          │   LIVE-VORSCHAU   │
│ BAR  │  LISTE     │    (Akkordeon-Bereiche)   │   (rechtes Panel) │
│      │            │                           │                   │
│      │ Weinkarte  │  ▸ Vorlage & Grundstil    │   [📱] [💻]       │
│      │ Barkarte   │  ▾ Typografie             │                   │
│      │ ...        │  ▸ Farben & Flächen       │   Live-Rendering  │
│      │            │  ▸ Icons & Badges         │   der Karte mit   │
│      │            │  ▸ Produktdarstellung     │   aktueller Config │
│      │            │  ▸ Navigation & Inhalt    │                   │
│      │            │  ▸ Kopf- & Fußbereich     │   [Vorschau ↗]    │
└──────┴────────────┴──────────────────────────┴───────────────────┘
```

### 4.2 Konfigurationsbereiche (Digital)

#### 4.2.1 Vorlage & Grundstil
- **Vorlage:** Elegant / Modern / Klassisch / Minimal (setzt alle Defaults)
- **Stimmung:** Hell / Warm / Dunkel (beeinflusst Farbpalette)
- **Dichte:** Luftig / Normal / Kompakt (steuert Abstände/Padding/Schriftgrößen)

#### 4.2.2 Typografie
Jede Textstufe einzeln konfigurierbar:

| Stufe | Beschreibung | Parameter |
|-------|-------------|-----------|
| H1 (Karten-Titel) | "Weinkarte" | Schrift, Größe (px), Gewicht, Farbe, Transform, Letter-Spacing |
| H2 (Sektions-Titel) | "Schaumwein" | Schrift, Größe, Gewicht, Farbe, Transform, Letter-Spacing |
| H3 (Produkt-Name) | "Grüner Veltliner Smaragd 2023" | Schrift, Größe, Gewicht, Farbe |
| Body (Beschreibung) | Weinbeschreibung | Schrift, Größe, Gewicht, Farbe, Stil (Normal/Italic) |
| Price (Preis) | "€ 68,10" | Schrift, Größe, Gewicht, Farbe, Format |
| Meta (Zusatzinfo) | Allergene, Herkunft | Schrift, Größe, Farbe |

#### 4.2.3 Farben & Flächen
Logische Farbbereiche:
- **Seiten-Hintergrund:** Farbe ODER Bild-Upload (mit Opacity-Slider 0-100%)
- **Kopfbereich:** Hintergrundfarbe + Textfarbe
- **Sektions-Header:** Hintergrundfarbe + Linienfarbe + Linienstärke (px) + Linienstil (durchgezogen/gestrichelt/doppelt/keine)
- **Produkt-Zeile:** Hintergrund + Hover-Farbe + Trennlinienfarbe + Trennlinienstil
- **Preis-Linie:** Stil (gepunktet/Linie/keine) + Farbe (Verbindungslinie Name→Preis)
- **Akzentfarben:** Primär + Empfehlung + Neu + Premium (für Badges/Highlights)

#### 4.2.4 Icons & Badges
- **Icon-Stil:** Emoji (🍷🍸) / Outlined (Linien-Icons) / Filled (ausgefüllt) / Keine
- **Sektions-Icons:** Pro Sektion konfigurierbar (Dropdown)
- **Badge-Anzeige:** Checkboxen für Empfehlung / Neu / Premium / Vegetarisch / Vegan / Bio
- **Badge-Stil:** Farbiger Punkt / Pill-Tag / Icon / Farbiger Rand
- **Allergene:** Position (Am Produkt / Am Seitenende / Aus) + Stil (Nummern / Abkürzungen / Icons)

#### 4.2.5 Produktdarstellung
- **Bilder:** Ein/Aus, Stil (Farbe/Schwarzweiß/Sepia), Form (Rechteck/Rund/Abgerundet), Größe (Slider px), Position (Links/Rechts/Nur Hauptbild)
- **Beschreibung:** Kurzbeschreibung ein/aus, Langbeschreibung ein/aus, Max Zeilen (Slider)
- **Preis-Layout:** Position (Rechts/Unter Name/Unter Beschreibung), Währung (€), Format (€ 12,50 / 12,50 € / EUR 12.50), Mehrere Preise (Alle/Günstigsten/Teuersten), Füllmenge zeigen (Ja/Nein)
- **Weindetails (nur bei type=WINE):** Checkboxen für Weingut/Jahrgang/Rebsorte/Region/Land/Alkohol/Ausbau + Anzeige-Position (Unter Name / Aufklappbar / Nur auf Detailseite)
- **Getränkedetails (nur bei type=DRINK/BAR):** Checkboxen für Alkoholgehalt/Zutaten/Serviertemperatur

#### 4.2.6 Navigation & Inhaltsverzeichnis
- **Inhaltsverzeichnis:** Ein/Aus + Position (Oben unter Header / Sticky Sidebar / Dropdown) + Stil (Einfache Liste / Tabs / Pill-Buttons)
- **Sticky-Navigation:** Ein/Aus + Stil (Tabs / Unterstrichen / Pills)
- **Scroll-Verhalten:** Smooth Scroll (Ja/Nein) + Aktive Sektion hervorheben (Ja/Nein) + "Nach oben" Button (Ja/Nein)
- **Leere Sektionen:** Automatisch ausblenden (Ja/Nein)
- **Auto-Generierung:** Das Inhaltsverzeichnis generiert sich automatisch aus den aktiven Sektionen mit sichtbaren Produkten. Keine manuelle Pflege nötig.

#### 4.2.7 Kopf- & Fußbereich
- **Logo:** Bild-Upload + Position (Links/Zentriert/Rechts) + Größe (Slider px)
- **Titel:** Text (Default = Kartenname, editierbar) + Ein/Aus
- **Untertitel:** Text (z.B. "Saison 2025/26") + Ein/Aus
- **Hintergrundbild:** Upload + Overlay-Opacity (Slider) + Overlay-Farbe
- **Header-Höhe:** Klein (nur Logo+Titel) / Normal (Logo+Titel+Untertitel) / Groß (Vollbild mit Hintergrundbild)
- **Fußzeile:** Ein/Aus + Text + Allergen-Hinweis automatisch (Ja/Nein) + Preishinweis (Ja/Nein)

### 4.3 Live-Vorschau
- Rechtes Panel im Editor, immer sichtbar
- Umschaltbar: 📱 Handy (375px) / 💻 Desktop (volle Breite)
- Jede Änderung aktualisiert sofort (kein Speichern nötig)
- Button "Vorschau im neuen Tab ↗" für Fullscreen-Test
- Technisch: iframe oder React-Portal mit Config als Props

### 4.4 Render-Engine (Digital)
- React-Komponenten die Config als Props erhalten
- Template-Komponente wählt Layout basierend auf `template` Feld
- CSS Custom Properties für Farben/Schriften (schnell wechselbar)
- Schriften via `next/font` geladen (Performance)
- Responsive: Mobile-first, Desktop-Erweiterung

---

## 5. ANALOGE ANSICHT (PDF)

### 5.1 Admin-UI: PDF-Editor

Eigener Tab "PDF" im Karten-Design mit 3 Unter-Tabs:

```
┌─────────────────────────────────────────────────┐
│  [📐 Aufbau]    [🎨 Design]    [📄 Vorschau]    │
└─────────────────────────────────────────────────┘
```

### 5.2 Tab: 📐 Aufbau

#### 5.2.1 Sortier-Hierarchie
Inspiriert von WinePad, aber mit Drag & Drop statt Checkbox-Matrix.

Verfügbare Ebenen (per Drag & Drop sortierbar):

| Ebene | Beispiel |
|-------|---------|
| KATEGORIE | Schaumwein, Weißwein, Rotwein |
| HERKUNFTSLAND | Österreich, Frankreich, Italien |
| REBSORTE | Grüner Veltliner, Riesling, Merlot |
| HERKUNFTSREGION | Wachau, Kamptal, Burgund |
| HERKUNFTSGEBIET | Spitz, Dürnstein, Joching |
| PRODUZENT/WEINGUT | Domäne Wachau, Hirtzberger |
| CHARAKTER/STIL | Brut, Trocken, Halbtrocken |
| APPELLATION | Wachau DAC, Kamptal DAC |
| JAHRGANG | 2023, 2022, 2024 |
| PRODUKT | Einzelne Weine/Getränke |

Pro Ebene 3 Toggles:
- **[Seite]** = Neue Seite vor dieser Ebene beginnen
- **[Text]** = Beschreibung/Details anzeigen
- **[Header]** = Überschrift anzeigen

Nicht benötigte Ebenen in "Nicht verwendet"-Bereich ziehen.

**Beispiel Weinkarte:**
```
≡ 1. KATEGORIE         [Seite ✓] [Text ✓] [Header ✓]
≡ 2. HERKUNFTSLAND      [Seite ○] [Text ✓] [Header ✓]
≡ 3. REBSORTE           [Seite ○] [Text ○] [Header ✓]
≡ 4. PRODUKT            [Seite ○] [Text ✓] [Header –]
─────────────────────────────
Nicht verwendet:
≡ HERKUNFTSREGION  ≡ PRODUZENT  ≡ APPELLATION  ≡ JAHRGANG
```

**Beispiel Barkarte (flacher):**
```
≡ 1. KATEGORIE         [Seite ✓] [Text ○] [Header ✓]
≡ 2. PRODUKT            [Seite ○] [Text ✓] [Header –]
```

#### 5.2.2 Inhalt auswählen
Checkboxen welche Produktgruppen im PDF:
- Gruppen mit Produktanzahl: [✓] Schaumwein (7) [✓] Weißwein (40) ...
- [Alle auswählen] / [Alle abwählen] Buttons

#### 5.2.3 Sonderseiten
- [✓] Titelseite (Deckblatt)
- [✓] Inhaltsverzeichnis (auto-generiert mit Seitenzahlen)
- [✓] Legende / Zeichenerklärung (auto-generiert aus verwendeten Icons/Kürzeln)
- [✓] QR-Code Seite (Link zur digitalen Karte)
- [+ Freie Seite hinzufügen] (Text/Bild für Weinphilosophie, Team, etc.)
- [✓] Zwischenseiten/Bildseiten zwischen Hauptkategorien

#### 5.2.4 Sprache
- Hauptsprache: Dropdown (Default: Deutsch)
- Zweite Sprache: Dropdown (Englisch / Keine)
- Anwendung: ● Überall / ○ Nur Titelseite / ○ Nur Produktnamen
- Beschreibungen: ● Beide Sprachen / ○ Nur Hauptsprache

#### 5.2.5 Seitenformat
- Format: A4 Hochformat / A4 Querformat / A5 Hochformat / Benutzerdefiniert (mm×mm)
- Ränder: Schmal (15mm) / Normal (20mm) / Breit (25mm) / Benutzerdefiniert (je Seite einzeln)
- Beschnitt: Checkbox 3mm Bleed (für professionellen Druck)
- Seitenzahlen: Ein/Aus, Start bei (Default 1), Titelseite mitzählen (Default Nein)

### 5.3 Tab: 🎨 Design

#### 5.3.1 Titelseite
Referenz: Bestehende Weinkarte Seite 1 (Hirsch-Logo auf grauem Block, Zitat DE/EN)
- **Logo:** Upload + Hintergrundfarbe oder Hintergrundbild + Position (oberes Drittel/zentriert) + Größe (Slider)
- **Zitat/Text:** Ein/Aus + Text DE + Text EN + Autor + Schrift (Script/Serif/Sans)
- **Freie Textblöcke:** Hinzufügen/Entfernen/Sortieren (für Begrüßungstext, Widmung)

#### 5.3.2 Inhaltsverzeichnis
Referenz: Bestehende Weinkarte Seite 2 (gepunktete Linien, zweisprachig, eingerückt)
- **Tiefe:** Nur Hauptkategorien / Hauptkategorien + Länder / Alle verwendeten Ebenen
- **Verbindungslinie:** Gepunktet (........... 3) / Durchgezogen (——— 3) / Nur Seitenzahl / Ohne Seitenzahl
- **Zweisprachig:** Ja/Nein (z.B. "SCHAUMWEIN / SPARKLING ........... 3")
- **Einrückung:** Unterkategorien eingerückt (Ja/Nein)
- **Position:** Nach Titelseite / Am Ende des Dokuments

#### 5.3.3 Typografie (PDF-spezifisch, in pt)
| Stufe | Beschreibung | Parameter |
|-------|-------------|-----------|
| Sektions-Titel | "Schaumwein / Sparkling" | Schrift (inkl. Script!), Größe (pt), Farbe, Trennlinie darunter (Ja/Nein + Farbe) |
| Unterkategorie | "ÖSTERREICH / AUSTRIA" | Schrift, Größe, Farbe, Versalien (Ja/Nein), Zweisprachig |
| Sub-Gruppierung | "Grüner Veltliner" | Schrift, Größe, Region rechts anzeigen (Ja/Nein) |
| Produktname | "GV Terrassen Smaragd 2023" | Schrift, Größe, Gewicht |
| Weingut-Zeile | "Domäne Wachau, Dürnstein" | Schrift, Größe, Farbe |
| Beschreibung | Verkostungsnotiz | Schrift, Größe, Textausrichtung (Blocksatz/Links), Zeilenabstand |
| Preis | "0,75  68,10 €" | Schrift, Größe, Gewicht, Position |

Zusätzliche Schriften für Script-Header (wie in der bestehenden Karte):
Dancing Script, Great Vibes, Sacramento, Pacifico

#### 5.3.4 Farben (PDF)
- Seiten-Hintergrund (Default: Weiß)
- Text-Hauptfarbe
- Akzentfarbe (für Linien, Sektions-Header, Ornamente)
- Preis-Farbe
- Fußzeilen-Farbe

#### 5.3.5 Produkt-Layout (PDF)
Referenz: Bestehende Weinkarte Seiten 3-7

Pro Produkt:
```
Grüner Veltliner Terrassen Smaragd 2023 | Wachau DAC ✹ ☺    0,75   68,10 €
Domäne Wachau, Dürnstein
Mittleres Gelbgrün, Silberreflexe. Zart nach Zitrus...
Medium yellow green, silver reflections. Delicate notes...
```

Konfigurierbar:
- **Name-Zeile:** Checkboxen was nach dem Namen steht (Rebsorten-Kürzel, Appellation, Stil, Icons)
- **Weingut-Zeile:** Ein/Aus + Inhalt (Weingut, Ort, Region)
- **Beschreibung:** DE ein/aus + EN ein/aus + Layout (Untereinander / 2 Spalten nebeneinander) + Textausrichtung (Blocksatz/Links) + Max. Zeichen (0=unbegrenzt)
- **Preis:** Format (Füllmenge + Preis) + Position (Rechtsbündig auf Name-Zeile) + Mehrere Preise untereinander
- **Abstand:** Klein (6pt) / Normal (12pt) / Groß (18pt) + Trennlinie zwischen Produkten (Ja/Nein)

#### 5.3.6 Bilder im PDF
Referenz: Bestehende Karte zeigt Flaschenfotos am Seitenende
- **Bilder zeigen:** Ein/Aus
- **Position:** Am Seitenende (Flaschenreihe) / Neben jedem Produkt (links/rechts) / Keine
- **Am Seitenende:** Max. Flaschen pro Reihe (Slider 2-6) + Höhe (Slider mm)
- **Stil:** Farbe / Schwarzweiß / Freigestellt (transparenter Hintergrund)
- **Bildtyp-Filter:** Checkboxen BOTTLE / LABEL / SERVING / AMBIANCE

#### 5.3.7 Kopf- & Fußzeile
Referenz: Bestehende Karte hat Script-Sektionsname oben + "Inklusivpreise..." unten
- **Kopfzeile (ab Seite 2):** Sektionsname wiederholen (Ja/Nein) + Stil + Trennlinie
- **Fußzeile:** Ein/Aus + Text links ("Inklusivpreise in Euro All prices incl. Taxes") + Text Mitte (Logo/leer) + Text rechts (Seitenzahl) + Trennlinie oben

#### 5.3.8 Seitenumbruch-Logik
Automatische Regeln (Checkboxen):
- [✓] Hauptkategorie immer auf neuer Seite
- [✓] Kein Produkt über Seitenumbruch teilen (Orphan/Widow Protection)
- [✓] Min. 2 Produkte nach Unterkategorie-Header
- [✓] Bilder-Reihe nicht vom zugehörigen Text trennen

Manuelle Umbrüche:
- Im Karteneditor pro Produkt ein Flag "Seitenumbruch danach" setzbar

### 5.4 Tab: 📄 Vorschau
- Seitenweise blätterbar: ◄ Seite 3 / 46 ►
- Zoom-Slider (50% - 200%)
- Doppelseiten-Ansicht (optional)
- **[⬇ PDF Download]** Button

### 5.5 Render-Engine (PDF)
- `@react-pdf/renderer` für serverseitige PDF-Generierung
- Template-Komponenten die analog Config als Props erhalten
- Seitenumbruch-Logik in der Render-Engine eingebaut
- Auto-Inhaltsverzeichnis: Erster Render-Pass zählt Seiten, zweiter Pass generiert Verzeichnis
- Schriften eingebettet im PDF (kein Systemfont-Abhängigkeit)

---

## 6. DESIGN-CONFIG JSON (Komplett)

```json
{
  "digital": {
    "template": "elegant",
    "mood": "warm",
    "density": "normal",
    "typography": {
      "h1": { "font": "Playfair Display", "size": 32, "weight": 700, "color": "#2C1810", "transform": "none", "spacing": 0.02 },
      "h2": { "font": "Playfair Display", "size": 22, "weight": 600, "color": "#8B6914", "transform": "uppercase", "spacing": 0.05 },
      "h3": { "font": "Source Sans 3", "size": 16, "weight": 600, "color": "#333333" },
      "body": { "font": "Source Sans 3", "size": 14, "weight": 400, "color": "#777777", "style": "italic" },
      "price": { "font": "Source Sans 3", "size": 16, "weight": 700, "color": "#6B4C1E", "format": "€ {price}" },
      "meta": { "font": "Source Sans 3", "size": 11, "color": "#AAAAAA" }
    },
    "colors": {
      "pageBackground": "#FFF8F0",
      "headerBackground": "#8B6914",
      "headerText": "#FFFFFF",
      "sectionHeaderBg": "transparent",
      "sectionLine": "#D4A853",
      "sectionLineWidth": 1,
      "sectionLineStyle": "solid",
      "productBg": "transparent",
      "productHover": "#FFF5E6",
      "productDivider": "#F0E6D4",
      "priceLine": "dotted",
      "priceLineColor": "#D4C4A8",
      "accentPrimary": "#8B6914",
      "accentRecommend": "#D4A853",
      "accentNew": "#4A7C59",
      "accentPremium": "#7B2D3F"
    },
    "icons": { "style": "outlined", "sectionIcons": {} },
    "badges": { "show": ["recommendation", "new", "premium", "vegetarian", "bio"], "style": "pill" },
    "allergens": { "position": "product", "style": "numbers" },
    "products": {
      "showImages": true, "imageStyle": "color", "imageShape": "rounded", "imageSize": 64, "imagePosition": "left",
      "showShortDesc": true, "showLongDesc": false, "descMaxLines": 2,
      "pricePosition": "right", "currency": "€", "priceFormat": "€ {price}", "showAllPrices": true, "showFillQuantity": true,
      "wineDetails": ["winery", "vintage", "grape", "region"], "wineDetailPosition": "below",
      "drinkDetails": ["alcohol", "ingredients"]
    },
    "navigation": { "showToc": true, "tocPosition": "sticky", "tocStyle": "pills", "stickyNav": true, "smoothScroll": true, "highlightActive": true, "showBackToTop": true, "hideEmptySections": true },
    "header": { "logo": null, "logoPosition": "center", "logoSize": 120, "title": null, "subtitle": null, "backgroundImage": null, "overlayOpacity": 0.6, "height": "normal" },
    "footer": { "show": true, "text": "Hotel Sonnblick · Kaprun", "showAllergenNote": true, "showPriceNote": true }
  },

  "analog": {
    "template": "elegant",
    "hierarchy": [
      { "level": "KATEGORIE", "newPage": true, "showText": true, "showHeader": true },
      { "level": "HERKUNFTSLAND", "newPage": false, "showText": true, "showHeader": true },
      { "level": "REBSORTE", "newPage": false, "showText": false, "showHeader": true },
      { "level": "PRODUKT", "newPage": false, "showText": true, "showHeader": false }
    ],
    "content": { "groups": ["all"], "showTitlePage": true, "showToc": true, "showLegend": true, "showQrPage": true, "freePages": [], "interPages": false },
    "language": { "primary": "de", "secondary": "en", "secondaryScope": "all", "descriptionLang": "both" },
    "page": { "format": "A4", "orientation": "portrait", "margins": "normal", "customMargins": null, "bleed": false, "pageNumbers": true, "pageNumberStart": 1, "countTitlePage": false },
    "titlePage": { "logo": null, "logoBgColor": "#555555", "logoBgImage": null, "logoPosition": "upperThird", "logoSize": 200, "quote": null, "quoteEN": null, "quoteAuthor": null, "quoteFont": "Dancing Script", "freeBlocks": [] },
    "toc": { "depth": "categoryAndCountry", "lineStyle": "dotted", "bilingual": true, "indented": true, "position": "afterTitle" },
    "typography": {
      "sectionTitle": { "font": "Dancing Script", "size": 36, "color": "#333333", "dividerLine": true, "dividerColor": "#C8A850" },
      "subCategory": { "font": "Source Sans 3", "size": 14, "weight": 700, "color": "#333333", "uppercase": true, "bilingual": true },
      "subGrouping": { "font": "Playfair Display", "size": 18, "color": "#333333", "showRegionRight": true },
      "productName": { "font": "Source Sans 3", "size": 12, "weight": 700, "color": "#000000" },
      "winery": { "font": "Source Sans 3", "size": 10, "color": "#777777" },
      "description": { "font": "Source Sans 3", "size": 10, "color": "#333333", "align": "justify", "lineHeight": 1.4 },
      "price": { "font": "Source Sans 3", "size": 11, "weight": 700, "color": "#000000" }
    },
    "colors": { "pageBg": "#FFFFFF", "textMain": "#333333", "accent": "#C8A850", "priceColor": "#000000", "footerColor": "#999999" },
    "productLayout": {
      "nameLineShow": ["grapeAbbrev", "appellation", "style", "icons"],
      "wineryShow": ["winery", "city", "region"],
      "descDE": true, "descEN": true, "descLayout": "stacked", "descAlign": "justify", "descMaxChars": 0,
      "priceFormat": "{fill}  {price} €", "multiplePrices": "stacked",
      "spacing": "normal", "dividerLine": false
    },
    "images": { "show": true, "position": "pageBottom", "maxPerRow": 4, "height": 120, "style": "color", "typeFilter": ["BOTTLE", "LABEL"] },
    "headerFooter": {
      "header": { "repeatSectionName": true, "font": "Dancing Script", "dividerLine": true },
      "footer": { "show": true, "textLeft": "Inklusivpreise in Euro All prices incl. Taxes", "textCenter": "", "textRight": "{pageNumber}", "dividerLine": true }
    },
    "pageBreaks": { "newPagePerMainCategory": true, "noOrphanProducts": true, "minProductsAfterHeader": 2, "keepImagesWithText": true }
  }
}
```

---

## 7. IMPLEMENTIERUNGS-REIHENFOLGE

### Phase 1: Grundgerüst
1. DB: `designConfig` JSON-Feld auf Menu-Tabelle hinzufügen
2. Default-Configs für die 4 Vorlagen als JSON-Dateien erstellen
3. API: GET/PATCH `designConfig` auf `/api/v1/menus/[id]`

### Phase 2: Digitale Ansicht
4. Template-Komponenten für die 4 Vorlagen (Gästeansicht)
5. Config-Reader: Gästeansicht liest `designConfig.digital` und wendet Styles an
6. Design-Editor UI im Admin (7 Akkordeon-Bereiche)
7. Live-Vorschau Panel (iframe oder React-Portal)

### Phase 3: Analoge Ansicht
8. PDF-Render-Engine mit `@react-pdf/renderer`
9. Sortier-Hierarchie-Logik (Ebenen-System)
10. Aufbau-Tab UI (Hierarchie Drag&Drop + Gruppen-Checkboxen + Sprache)
11. Design-Tab UI (Titelseite, Typografie, Farben, Produktlayout, Bilder)
12. Vorschau-Tab (PDF inline anzeigen + Download)
13. Seitenumbruch-Logik
14. Auto-Inhaltsverzeichnis mit Seitenzahlen
15. Titelseite + Legende + QR-Code Sonderseiten

### Phase 4: Verfeinerung
16. Responsive Preview-Modes (📱/💻/📄)
17. Config-Import/Export (Designs zwischen Karten kopieren)
18. Template-Sharing (Design von Weinkarte auf Barkarte übertragen)

---

## 8. TECHNISCHE HINWEISE

### Bestehender Stack
- Next.js 14, TypeScript, Tailwind CSS, Prisma, PostgreSQL
- Server: Hetzner 178.104.138.177
- Bilder: Sharp (WebP, 3 Größen), lokal auf Disk
- PDF: `@react-pdf/renderer` (bereits installiert)
- Schriften: `next/font` (bereits konfiguriert)

### Wichtige Constraints
- `next.config.mjs` (nicht .ts!)
- TypeScript `Set` iteration: `Array.from(new Set(...))`
- PowerShell `&&` geht nicht → Semikolon `;` verwenden
- `.next` Cache löschen bei hartnäckigen Problemen
- Nginx `client_max_body_size 10M`

### Prisma Schema
Aktuelles Schema hat bereits: Product, ProductTranslation, ProductPrice, ProductWineProfile, ProductBeverageDetail, ProductMedia, MenuPlacement, ProductGroup (27 hierarchisch), Menu, MenuSection.

Die `designConfig` erweitert nur das Menu-Model – keine neuen Tabellen nötig.
