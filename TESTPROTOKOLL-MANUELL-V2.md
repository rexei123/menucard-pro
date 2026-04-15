# Manuelles Testprotokoll – MenuCard Pro
**Stand:** 14.04.2026
**URL:** https://menu.hotel-sonnblick.at
**Zweck:** Was sich nicht sinnvoll automatisieren lässt – visuelle Design-Treue, Interaktionen, Usability

## Wie nutzen?
Jeden Block Punkt für Punkt durchgehen, ✅ / ❌ / ⚠ markieren, Befunde mit kurzer Notiz ergänzen.

---

## 1. Login & Auth
- [ ] Login mit korrekten Daten → Weiterleitung auf Dashboard
- [ ] Login mit falschem Passwort → Fehlermeldung sichtbar, keine Weiterleitung
- [ ] Logout-Link erreichbar, Logout funktioniert
- [ ] Nach Logout: /admin gibt Redirect auf /auth/login
- [ ] Passwort-Sichtbarkeit (Auge-Icon) funktioniert falls vorhanden

## 2. Admin-Dashboard
- [ ] Kennzahlen korrekt (Produkte, Karten, QR-Codes)
- [ ] Letzte Änderungen werden angezeigt
- [ ] Navigation zu allen Hauptbereichen möglich
- [ ] Sidebar alle Icons sichtbar + Hover-Tooltips

## 3. Kartenverwaltung
- [ ] Liste zeigt alle 9 Karten, sortiert nach sortOrder
- [ ] Karte anlegen → Eingabemaske öffnet, speichert, taucht in Liste auf
- [ ] Karte duplizieren (falls Feature vorhanden)
- [ ] Karte archivieren / reaktivieren
- [ ] **Drag & Drop Sortierung** — reiht in Liste um, Reihenfolge wird nach Reload gehalten
- [ ] Klick auf Karte → Produkte der Karte sichtbar
- [ ] Produkte per Drag & Drop umsortieren
- [ ] Sichtbarkeit toggeln (isVisible)
- [ ] Als "Ausverkauft" markieren → Gäste-Ansicht zeigt Badge

## 4. Produkt-Editor
### 4.1 Alle Felder (Speisen)
- [ ] Name, Kurzbeschreibung, Langbeschreibung
- [ ] Preis + mehrere Preisebenen (Restaurant, Bar, Room Service, Einkauf)
- [ ] Varianten/Größen anlegen, speichern, löschen
- [ ] Allergene als Icons, multi-select
- [ ] Zusatzstoffe
- [ ] Bilder hochladen, Reihenfolge ändern, Haupt-Bild markieren
- [ ] Tags
- [ ] Verfügbarkeit
- [ ] Empfehlungen / Pairings

### 4.2 Wein-Profil
- [ ] Weingut, Weinname, Jahrgang (numerisch)
- [ ] Rebsorten als Tag-Input (mehrere)
- [ ] Region/Land/Appellation
- [ ] Stil/Ausbau/Süße/Körper
- [ ] Flaschengröße, Glas-/Karaffen-/Flasche-Preise
- [ ] Verkostungsnotizen, Speiseempfehlung
- [ ] Interne Notizen

### 4.3 Getränke-Detail
- [ ] Volumen, Alkoholgehalt, Marke
- [ ] Serviertemperatur, Food-Pairing

### 4.4 Auto-Translate
- [ ] DE eingeben → EN-Übersetzung automatisch befüllt
- [ ] EN manuell überschrieben → bleibt erhalten
- [ ] Fallback wenn Übersetzung fehlt (DE wird gezeigt)

### 4.5 Preis-Kalkulation
- [ ] EK-Preis eingeben, Fix-Aufschlag %, gewünschte Marge
- [ ] Kalkulierter VK stimmt
- [ ] Marge-Anzeige im Editor korrekt

## 5. Design-Editor

### 5.1 Digital (7 Akkordeons)
- [ ] Akkordeon 1 — Template-Wahl (elegant/modern/classic/minimal)
- [ ] Akkordeon 2 — Typografie (Schriftart, Größen, Gewichte)
- [ ] Akkordeon 3 — Farben (primär, sekundär, Hintergrund, Text)
- [ ] Akkordeon 4 — Produkte (Layout, Bilder, Abstände, Preis-Position)
- [ ] Akkordeon 5 — Navigation (Sticky, Tabs, Suche)
- [ ] Akkordeon 6 — Badges (Highlights, Saisonal, Empfehlung)
- [ ] Akkordeon 7 — Stimmung/Dichte
- [ ] **Live-Vorschau** aktualisiert sich bei jedem Change unmittelbar
- [ ] "Benutzerdefiniert" taucht auf, wenn Overrides vorhanden
- [ ] Reset-Button fragt via Dialog nach
- [ ] Reset stellt Template-Default wieder her
- [ ] Speichern persistiert (Reload → gleicher Stand)

### 5.2 PDF/Analog (10 Akkordeons)
- [ ] pdf.js-Viewer rendert Vorschau
- [ ] Alle 4 Templates (elegant/modern/classic/minimal) erzeugen saubere PDFs
- [ ] A4, A5, Tischkarte, Bar-Karte auswählbar
- [ ] Logo/Hintergrund funktioniert
- [ ] Download als PDF startet korrekt

### 5.3 Custom-Vorlagen
- [ ] Eigene Vorlage speichern (max 4)
- [ ] Custom-Vorlage laden, editieren, löschen

## 6. Gäste-Ansicht — Templates einzeln

Pro Template auf **Desktop, Tablet, Mobile** prüfen:

### 6.1 elegant (Standard)
- [ ] Typografie (Playfair Display Serif) sauber
- [ ] Sticky-Nav funktioniert, **Kategorienamen nicht abgeschnitten** (B-5)
- [ ] Preise rechtsbündig, tabellarisch
- [ ] Highlight-Badges sichtbar
- [ ] Bilder laden (WebP, responsive)

### 6.2 modern
- [ ] Separater Renderer aktiv (ModernSection)
- [ ] Abweichendes Spacing / Farben / Sektion-Header

### 6.3 classic
- [ ] ClassicSection-Renderer aktiv
- [ ] Serifen-Typografie, klassisches Layout

### 6.4 minimal
- [ ] MinimalSection-Renderer aktiv
- [ ] Reduziert, viel Whitespace
- [ ] Preise sichtbar pro Variante

### 6.5 Sprachwechsel
- [ ] DE ↔ EN per Button umschaltbar
- [ ] URL-Parameter `?lang=en` bleibt nach Navigation erhalten
- [ ] Fehlt EN-Übersetzung → fällt auf DE zurück

### 6.6 Suche + Filter
- [ ] Volltextsuche findet Produkte nach Name
- [ ] Sucht jetzt auch in Kategorienamen (B-4)
- [ ] "Keine Ergebnisse" bei leerem Treffer
- [ ] "Filter zurücksetzen" leert Query + Filter
- [ ] Wein-Stilfilter zeigt nur passende Weine
- [ ] Länder-Filter funktioniert
- [ ] Mehrere Filter kombinierbar

### 6.7 Artikeldetail-Seite
- [ ] Tap auf Produkt → Detailseite lädt
- [ ] Großes Bild, alle Preise, Allergene, Beschreibung
- [ ] Zurück-Button wie erwartet

## 7. Bildarchiv
- [ ] Galerie-Ansicht zeigt alle Bilder
- [ ] Upload: Einzelbild, Mehrfach-Upload
- [ ] Upload von JPG, PNG, WebP, HEIC klappt
- [ ] **Crop-Editor** öffnet, kann zuschneiden, speichert zurück
- [ ] 3 Größen werden generiert (thumb/medium/large)
- [ ] Nginx upload limit nicht überschritten (10 MB)
- [ ] MediaPicker im Produkt-Editor: Bild auswählen → übernommen
- [ ] Websuche (SearXNG) liefert Kandidaten
- [ ] Bilder löschen funktioniert

## 8. CSV-Import
- [ ] Datei-Upload zeigt Vorschau-Tabelle
- [ ] Inline-Edit in Vorschau möglich
- [ ] Neu-Validierung nach Edit
- [ ] Import speichert in DB
- [ ] Fehlerzeilen werden markiert (nicht importiert)
- [ ] JSON- und Excel-Import falls unterstützt

## 9. QR-Codes
- [ ] Liste aller QR-Codes sichtbar
- [ ] Neu anlegen: pro Karte/Bereich/Tisch
- [ ] Download PNG, SVG, PDF
- [ ] Logo im QR-Code optional
- [ ] QR-Code scannen mit Handy → öffnet richtige Karte
- [ ] QR bleibt gleich bei Karten-Änderung (statisch)

## 10. Roles & Rechte (falls aktiv)
- [ ] Editor-User kann nur editieren, nicht Users verwalten
- [ ] Manager sieht keine System-Settings
- [ ] Owner hat Vollzugriff

## 11. Analyse & Reporting
- [ ] Dashboard zeigt QR-Scans / Seitenaufrufe
- [ ] Top-Produkte / Top-Kategorien
- [ ] Sprachverteilung

## 12. Regression — Fix-Runde 14.04.2026
- [x] B-1 "Getränke" / "für" auf Startseite **Playwright OK**
- [x] B-2 Preisformat einheitlich in Restaurant-Übersicht **Playwright OK**
- [x] B-3 Akzente (Rosé, Jouët) in Gäste-Ansicht **DB verifiziert**
- [x] B-4 Suche nach Kategorie (z.B. "cocktail") liefert Treffer **Playwright OK: 30/161**
- [x] B-5 Kategorienav nicht abgeschnitten auf allen 3 Viewports **Playwright OK**
- [x] B-8 "1 Karte" vs "2 Karten" auf Tenant-Seite **Code gepatcht**
- [ ] Visuell nachvollziehen (manuell, Screenshot-Vergleich)

## 13. Security Smoke
- [ ] HTTPS erzwungen (HTTP redirectet auf HTTPS)
- [ ] HSTS-Header vorhanden
- [ ] /admin ohne Login → Redirect /auth/login
- [ ] API `/api/v1/...` verlangt Auth
- [ ] `.env`, `.git`, `prisma/` nicht erreichbar (404/403)
- [ ] Rate-Limiting greift bei 10+ requests/sec auf API
- [ ] Rate-Limiting greift bei 3+ Login-Attempts

## 14. Performance
- [ ] Lighthouse Mobile Score > 85
- [ ] Gäste-Karte erste Sichtbarkeit < 1.5s auf 4G
- [ ] Bilder lazy-loaded
- [ ] Cache-Header sinnvoll
