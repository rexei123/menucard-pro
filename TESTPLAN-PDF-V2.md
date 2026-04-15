# Testplan – PDF-Export v2

**Datum:** 14.04.2026 (aktualisiert)
**Tester:** Hotel Sonnblick
**URL:** https://menu.hotel-sonnblick.at/admin

Legende: ✅ erledigt / getestet · 🟡 implementiert, manueller Test offen · ⬜ offen · ⏭ nicht mehr relevant

---

## 1. Tab-System

| # | Test | Erwartet | Status |
|---|------|----------|--------|
| 1.1 | Admin → Karte → Design-Editor öffnen | Seite lädt ohne Fehler | 🟡 |
| 1.2 | Tab "Digital" (Vorlage/Typografie/Farben/Produkte/Elemente/Navigation) klicken | Digital-Editor erscheint mit Live-Vorschau | 🟡 |
| 1.3 | Tab "PDF-Layout" klicken | PDF-Editor mit 6 Akkordeons erscheint (Schritt 2a) | ✅ |
| 1.4 | Zwischen Tabs hin- und herwechseln | Kein Datenverlust, beide Editoren laden korrekt | 🟡 |

## 2. Template-Auswahl (PDF / Druck)

| # | Test | Erwartet | Status |
|---|------|----------|--------|
| 2.1 | Vorlage "Elegant" wählen → Vorschau aktualisieren | PDF im Elegant-Stil (Goldakzente, Dancing Script) | 🟡 |
| 2.2 | Vorlage "Modern" wählen → Vorschau aktualisieren | PDF im Modern-Stil | 🟡 |
| 2.3 | Vorlage "Klassisch" wählen → Vorschau aktualisieren | PDF im Klassisch-Stil (Cormorant Garamond) | 🟡 |
| 2.4 | Vorlage "Minimal" wählen → Vorschau aktualisieren | PDF im Minimal-Stil | 🟡 |
| 2.5 | Template wechseln mit Anpassungen → Warndialog | "Vorlage wechseln?" Dialog erscheint | 🟡 |

## 3. PDF-Vorschau & Download

| # | Test | Erwartet | Status |
|---|------|----------|--------|
| 3.1 | Vorschau-Toggle "PDF" klicken | PDF wird via pdf.js-Viewer im Vorschaubereich angezeigt | ✅ |
| 3.2 | Einstellung ändern → Vorschau aktualisiert sich automatisch | Änderung ist im PDF sichtbar | 🟡 |
| 3.3 | "In neuem Tab öffnen" oben rechts | Neuer Tab mit pdf.js-Viewer (kein Download) | ✅ |
| 3.4 | PDF-Creator → PDF herunterladen | PDF-Datei wird heruntergeladen | ✅ |
| 3.5 | Heruntergeladenes PDF in Adobe/Browser öffnen | Korrekt formatiert, alle Seiten vorhanden | ✅ |

## 4. Akkordeon-Sektionen (PDF-Layout Tab)

### 4.1 Seite & Papier
| # | Test | Erwartet | Status |
|---|------|----------|--------|
| 4.1.1 | Format A5 wählen → Vorschau | Kleineres Seitenformat | ⬜ |
| 4.1.2 | Querformat wählen → Vorschau | Seite ist breiter als hoch | ⬜ |
| 4.1.3 | Seitenzahlen deaktivieren | Keine Seitenzahlen im PDF | ⬜ |
| 4.1.4 | Hauptsprache auf "Englisch" ändern | Englische Überschriften im PDF | ⬜ |
| 4.1.5 | Beschreibungssprache "Nur Hauptsprache" | Keine Zweitsprach-Beschreibungen | ⬜ |

### 4.2 Titelseite
| # | Test | Erwartet | Status |
|---|------|----------|--------|
| 4.2.1 | Ohne Logo | Kein grauer Platzhalter, nur Titel + Akzentlinie + Hotel-Name (Schritt 2b-D) | ✅ |
| 4.2.2 | Zitat eingeben (DE + EN) | Zitat erscheint auf Deckblatt | ⬜ |
| 4.2.3 | Logo hochladen | Logo oberhalb Titel | ⬜ |

### 4.3 Inhaltsverzeichnis
| # | Test | Erwartet | Status |
|---|------|----------|--------|
| 4.3.1 | DE/EN identische Einträge (z. B. "Aperitif") | EN wird unterdrückt (Schritt 2b-B) | ✅ |
| 4.3.2 | DE/EN unterschiedliche Einträge (z. B. "Schaumwein/Sparkling Wine") | Beide sichtbar | ✅ |
| 4.3.3 | Zweisprachig deaktivieren | Nur DE-Einträge | ⬜ |

### 4.4 Typografie & Farben
| # | Test | Erwartet | Status |
|---|------|----------|--------|
| 4.4.1 | Kategorie-Titel Schrift ändern | Titel-Schrift ändert sich im PDF | ⬜ |
| 4.4.2 | Kategorie-Titel Größe ändern (z. B. 48pt) | Titel wird größer | ⬜ |
| 4.4.3 | Produktname Farbe ändern | Produktnamen in neuer Farbe | ⬜ |
| 4.4.4 | Preis-Schrift auf Bold ändern | Preise fett dargestellt | ⬜ |
| 4.4.5 | Akzentfarbe ändern (z. B. Rot) | Dekorelemente (Titelseite-Linie) in Rot | ⬜ |
| 4.4.6 | Seitenhintergrund ändern | Hintergrundfarbe ändert sich | ⬜ |
| 4.4.7 | Textfarbe ändern | Fließtext in neuer Farbe | ⬜ |

### 4.5 Produkt-Layout & Bilder
| # | Test | Erwartet | Status |
|---|------|----------|--------|
| 4.5.1 | Produkt mit mehreren Füllmengen (z. B. Canella "1/10 offen" + "Flasche 0,75l") | Preise zweispaltig: Label grau links, Betrag rechtsbündig (Schritt 2b-C) | ✅ |
| 4.5.2 | DE/EN-Beschreibung identisch | EN-Zeile wird unterdrückt (Schritt 2b-B) | ✅ |
| 4.5.3 | DE/EN-Beschreibung unterschiedlich | Beide Zeilen sichtbar, EN hellgrau kursiv (Schritt 2b-H) | ✅ |
| 4.5.4 | Winery-Text identisch zu Beschreibung (Perrier-Jouët) | Nur einmal angezeigt (Schritt 2b-B) | ✅ |
| 4.5.5 | "Beschreibung (EN)" global deaktivieren | Keine englischen Beschreibungen | ⬜ |
| 4.5.6 | Abstand "Kompakt" wählen | Produkte enger zusammen | ⬜ |
| 4.5.7 | Kategorie-Titel-Trennstrich | Keine kurze 60px-Linie unter Titel mehr (Schritt 2b-G) | ✅ |
| 4.5.8 | "Portion"-Label bei Aperitifs | Dezent grau, nicht dominant (Schritt 2b-F) | ✅ |

### 4.6 Kopf-/Fußzeile
| # | Test | Erwartet | Status |
|---|------|----------|--------|
| 4.6.1 | Fußzeile Standardtext | "Inklusivpreise in Euro · All prices incl. Taxes" mit Trennzeichen (Schritt 2b-E) | ✅ |
| 4.6.2 | Fußzeile deaktivieren | Keine Fußzeile im PDF | ⬜ |
| 4.6.3 | Fußzeile Text Links ändern | Neuer Text in Fußzeile links | ⬜ |
| 4.6.4 | Kopfzeile mit Kategorie-Name | Kategorie wiederholt oben auf jeder Seite | ✅ |

## 5. Benutzerdefinierte Vorlagen

| # | Test | Erwartet | Status |
|---|------|----------|--------|
| 5.1 | Einstellung ändern → Custom-Anzeige | "Benutzerdefiniert" wird erkannt | 🟡 |
| 5.2 | Namen eingeben → "Als Vorlage speichern" | Vorlage wird als Karte gespeichert | 🟡 |
| 5.3 | Gespeicherte Vorlage anklicken | Einstellungen werden geladen | 🟡 |
| 5.4 | 6 Vorlagen speichern → Limit | Max. 6 benutzerdefinierte Vorlagen | 🟡 |
| 5.5 | Vorlage löschen (Hover → ✕) | Vorlage wird entfernt | 🟡 |
| 5.6 | "Auf Standardwerte zurücksetzen" | Alle Anpassungen weg, Template-Defaults | 🟡 |
| 5.7 | Seite neu laden → Vorlagen prüfen | Gespeicherte Vorlagen noch vorhanden | 🟡 |

## 6. PDF-Creator Seite

| # | Test | Erwartet | Status |
|---|------|----------|--------|
| 6.1 | Sidebar → "PDF-Creator" klicken | Übersichtsseite mit allen Karten | 🟡 |
| 6.2 | PDF-Button bei einer Karte klicken | PDF wird heruntergeladen | ✅ |
| 6.3 | "Design bearbeiten" klicken | Design-Editor für diese Karte öffnet sich | 🟡 |

## 7. Alle Karten testen

| # | Karte | PDF generierbar | Status |
|---|-------|-----------------|--------|
| 7.1 | Weinkarte | Generierung OK, Layout prüfen | ⬜ |
| 7.2 | Barkarte | Getestet mit neuem Layout (2 Barkarten-PDFs) | ✅ |
| 7.3 | Gourmet Menü – Jägerabend | | ⬜ |
| 7.4 | Gourmet Menü – Schnitzel Abend | | ⬜ |
| 7.5 | Gourmet Menü – Österreichischer Abend | | ⬜ |
| 7.6 | Gourmet Menü – Italienischer Abend | | ⬜ |
| 7.7 | Gourmet Menü – Heimatabend | | ⬜ |
| 7.8 | Gourmet Menü – Gala Abend | | ⬜ |
| 7.9 | Gourmet Menü – Amerikanischer Abend | | ⬜ |

## 8. Qualitätsprüfung

| # | Test | Erwartet | Status |
|---|------|----------|--------|
| 8.1 | Digital-Editor funktioniert nach Änderungen | Keine Regression, Live-Vorschau OK | 🟡 |
| 8.2 | Gästeansicht funktioniert | Karten werden korrekt angezeigt | 🟡 |
| 8.3 | Mobile Ansicht Gästeansicht | Responsive, keine Fehler | 🟡 |
| 8.4 | Nach Schritt 2c: Dead-Code | Keine 404, alte /admin/menus/[id]/design-Route entfernt | ✅ |

---

## Stand 14.04.2026 – Schritt 2 komplett

**Implementiert (Code):**
- Schritt 2a: PDF-Layout-Tab mit 6 Akkordeons im Design-Editor
- Schritt 2b: PDF-Qualität (DE/EN-Dedup, Preis-Zweispalter, Titelseite-Cleanup, Fußzeile, Portion-Label, Kategorie-Trennlinie entfernt, EN-Farbe dezenter)
- Schritt 2c: Dead-Code-Cleanup (4 Dateien entfernt)
- PDF "In neuem Tab öffnen" via pdf.js-Wrapper

**Offen (manueller UI-Test durch Hotel):**
- 🟡 **Funktionale Tests** aller PDF-Einstellungen (Format, Sprache, Typografie, Farben) — 6 Akkordeons × ca. 3-5 Tests = ~20 Punkte
- ⬜ **Alle 9 Karten** als PDF generieren und Layout prüfen (7 Gourmet-Menüs + Weinkarte offen)
- 🟡 **Custom-Templates**: Speichern/Laden/Löschen der benutzerdefinierten Vorlagen
- 🟡 **Regression**: Digital-Editor und Gästeansicht nach PDF-Umbau prüfen

**Nicht mehr relevant:**
- Alte Tab-Struktur "Digital/PDF-Druck" (ist jetzt als 7 Tabs im Akkordeon-Stil)
- "Vorschau aktualisieren"-Button (Vorschau ist jetzt automatisch)
