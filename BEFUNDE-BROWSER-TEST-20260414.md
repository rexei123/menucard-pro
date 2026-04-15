# Befunde aus Browser-Test (Claude in Chrome)

**Datum:** 14.04.2026
**Tester:** Claude (via Claude in Chrome)
**Browser:** Chrome 1440×900 (Desktop)
**URL:** https://menu.hotel-sonnblick.at

---

## Zusammenfassung

| Schwere | Anzahl |
|---------|--------|
| 🔴 Hoch (Daten/Funktion fehlerhaft) | 4 |
| 🟡 Mittel (UI/UX-Mangel) | 3 |
| 🟢 Niedrig (Optimierung) | 1 |
| ✅ Funktioniert wie erwartet | 8 |

---

## 🔴 Hoch

### B-1: Umlaute fehlen auf der Startseite
**Pfad:** `/`
**Symptom:** Untertitel zeigt „Digitale Speise-, **Getraenke**- und Weinkarten **fuer** die gehobene Hotellerie"
**Erwartet:** „Getränke" und „für"
**Auswirkung:** Erster Eindruck wirkt fehlerhaft / unprofessionell
**Ort vermutlich:** Statischer Text in Landing-Page-Komponente

### B-2: Preisformat-Inkonsistenz auf Restaurant-Übersicht (DE)
**Pfad:** `/hotel-sonnblick/restaurant`
**Symptom:** 6 von 7 Gourmet-Menüs zeigen „€ 45.00" (Punkt), Gala Abend zeigt „€ 55,00" (Komma)
**Erwartet:** Einheitlich „€ 45,00" / „€ 55,00" in der DE-Ansicht
**Auswirkung:** Wirkt unprofessionell, unterschiedliche Formatierung pro Datensatz
**Vermutung:** Preise wurden uneinheitlich in der DB gespeichert (string `45.00` vs. `55,00`), Frontend formatiert nicht serverseitig nach Locale

### B-3: Inkonsistente Akzente zwischen Bar- und Weinkarte
**Pfad:** Barkarte vs. Weinkarte
**Symptom:**
| Produkt | Barkarte | Weinkarte |
|---------|----------|-----------|
| Schaumwein-Rosé | „SECCO ROSÉ PINK RIBBON" | „SECCO ROSE PINK RIBBON" |
| Champagner | „Champagne Perrier-Jouët, Épernay" | „Champagne Perrier-Jouet, Epernay" |

**Erwartet:** Identische Schreibweise — ein Produkt sollte nicht doppelt mit unterschiedlichen Schreibweisen existieren
**Vermutung:** Doppelte Datensätze in `Product`-Tabelle, Akzente bei Import verloren

### B-4: Suche durchsucht keine Kategorienamen
**Pfad:** Barkarte → Suche „cocktail"
**Symptom:** „0/161 Ergebnisse" trotz Kategorien „COCKTAILS" und „DESSERT COCKTAIL"
**Erwartet:** Zumindest Hinweis auf Kategorie oder Treffer der Produkte in dieser Kategorie
**Vermutung:** Volltextsuche bezieht nur `Product.name`/`description` ein, nicht `ProductGroup.name`

---

## 🟡 Mittel

### B-5: Kategorienavigation rechts abgeschnitten
**Pfad:** alle Karten mit langer Kategorieliste
**Symptom:** Letzte Kategorie wird angeschnitten („DES…" statt „DESSERTS"; „ROTWE…" statt „ROTWEIN ÖSTERREICH")
**Erwartet:** Kategorien horizontal scrollbar mit sichtbarem Scroll-Hinweis, oder Wrapping
**Beispiel:** Jägerabend, Weinkarte
**Auswirkung:** Gäste sehen nicht alle verfügbaren Kategorien

### B-6: Hauptgerichte ohne Preisanzeige
**Pfad:** `/hotel-sonnblick/restaurant/jaegerabend`
**Symptom:** Suppe (€ 5,00) und Zwischengericht (€ 7,50) zeigen Preise, aber alle Hauptgerichte (Hirschragout, Forelle, Risotto) ohne Preis
**Erwartet:** Entweder alle Produkte mit Preis oder ein Hinweis „im Menüpreis enthalten"
**Auswirkung:** Wirkt wie fehlende Daten oder Bug
**Klärung nötig:** Soll das so sein (Inklusivpreis im Gourmet-Menü)? Wenn ja, dann visuell erklären.

### B-7: Jahrgang fehlt auf Weinen
**Pfad:** `/hotel-sonnblick/restaurant/weinkarte`
**Symptom:** Bei keinem Wein wird ein Jahrgang angezeigt
**Erwartet:** Jahrgang als wesentliches Wein-Attribut sichtbar (z. B. neben Weinname)
**Vermutung:** Feld `ProductWineProfile.vintage` ist leer ODER wird in der Gästeansicht nicht gerendert

---

## 🟢 Niedrig

### B-8: Footer-Text wirkt blass
**Pfad:** alle Karten
**Symptom:** Footer „Hotel Sonnblick · Saalbach / Alle Preise in Euro inkl. MwSt. / Powered by MenuCard Pro" sehr hellgrau, schwer lesbar
**Erwartet:** Etwas mehr Kontrast (z. B. #888 statt geschätzt #d0d0d0)

---

## ✅ Funktioniert wie erwartet

| # | Test | Ergebnis |
|---|------|---------|
| OK-1 | Hierarchie-Navigation Hotel → Standort → Karte → Produkte | sauber, schnell |
| OK-2 | Sprachwechsel DE → EN: Titel, Kategorien, Produktnamen, Beschreibungen, Tags übersetzt | Hunter's Evening, Main Courses, Vegetarian – alles korrekt |
| OK-3 | Preisformat-Lokalisation: DE Komma, EN Punkt | korrekt |
| OK-4 | Sold-Out-Markierung (Secco Rosé Pink Ribbon) | Badge „Ausverkauft" + ausgegraut |
| OK-5 | Mehrfach-Preise pro Produkt (1/8 offen + Flasche 0,75l) | korrekt zweispaltig |
| OK-6 | Suche nach Produktnamen („veuve") | 1/161 Treffer, korrekt |
| OK-7 | Tags pro Produkt (Hersteller, Rebsorte, Region; Fleisch/Fisch/Vegetarisch) | sichtbar, plausibel |
| OK-8 | Standortauswahl zeigt Anzahl Karten („8 Karten" / „1 Karten") | Wert korrekt, aber siehe Anmerkung unten |

**Anmerkung zu OK-8:** „1 Karten" sollte „1 Karte" lauten (Singular). Klein, aber auffällig.

---

## Nicht testbar via Claude in Chrome (für manuelle Prüfung)

- Mobile-Viewport (Browser-Fenster lässt sich nicht unter Desktop-Auflösung verkleinern)
- Touch-Interaktionen
- PDF-Vorschau im pdf.js-Viewer (öffnet Tab — Test offen)
- Admin-Bereich (Login erforderlich)
- Filter-Dropdowns (rendern nativ, nicht im Screenshot erfassbar)

---

## Empfohlene Sofortmaßnahmen

1. **B-1 Umlaute auf Startseite:** schnell zu beheben, hoher Sichtbarkeitseffekt
2. **B-2 Preisformat:** serverseitige Formatierung über `Intl.NumberFormat('de-AT', { style: 'currency', currency: 'EUR' })` einbauen
3. **B-3 Akzente-Inkonsistenz:** Datenbereinigung — `SELECT id, name FROM "Product" WHERE name LIKE 'SECCO ROSE%' OR name LIKE 'PERRIER-JOUET%';` und manuell normalisieren
4. **B-7 Jahrgang:** Spalte `vintage` befüllen + im Frontend rendern (Akkordeon „Produkte" im Design-Editor → Toggle?)

---

## Sonderbeobachtung: Dual-Datenmodell Bar/Wein

Dass dieselben Schaumweine in Bar- und Weinkarte mit unterschiedlicher Schreibweise existieren, deutet auf zwei separate Datensätze pro Produkt hin (z. B. „Secco Rosé Pink Ribbon" als Schaumwein in der Bar UND als Schaumwein in der Weinkarte). Falls beabsichtigt: einen einheitlichen Stammdatensatz pflegen und nur die Zuordnung über `MenuPlacement` regeln. Falls unbeabsichtigt: doppelte Pflege ist Fehlerquelle Nr. 1 für solche Inkonsistenzen.
