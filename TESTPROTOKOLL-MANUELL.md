# Manuelles Testprotokoll — MenuCard Pro

**Stand:** 14.04.2026
**Tester:** ______________
**Browser:** ☐ Chrome ☐ Firefox ☐ Safari ☐ Edge
**Live-URL:** https://menu.hotel-sonnblick.at
**Admin-Login:** admin@hotel-sonnblick.at

---

## Legende

- ☐ offen
- ✅ geprüft, in Ordnung
- ❌ Fehler (Beschreibung in Spalte „Bemerkung")
- ⚠️ Auffälligkeit, aber nicht blockierend

---

## 0. Bereits automatisiert geprüft (nicht manuell nötig)

| Prüfung | Ergebnis |
|---------|----------|
| PM2 läuft, Next.js erreichbar auf 127.0.0.1:3000 | ✅ |
| Nginx läuft, HTTPS erreichbar | ✅ |
| Postgres erreichbar (pg_isready) | ✅ |
| Datenbank: 322 Produkte, 9 Karten, 10 QR-Codes, 27 Produktgruppen | ✅ |
| Alle 9 PDF-Karten generieren erfolgreich (HTTP 200, %PDF-Magic, 26–86 KB) | ✅ |
| API-Routen antworten (menus, products, qr-codes, media, design-templates, auth, translate, import) | ✅ |
| Security-Header: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection, Referrer-Policy, HSTS | ✅ |
| Blockierte Pfade: .env, .git, prisma, .bak, .sh, .sql → 404 | ✅ |
| Alte Design-Route `/admin/menus/[id]/design` entfernt | ✅ |
| Dead-Code Phase 2c: Dateien gelöscht, pdf-layout-tab vorhanden, pdf-viewer.html vorhanden | ✅ |
| Public Pages liefern 200 (Gästeansicht DE + EN) | ✅ |

---

## 1. Login & Auth

| # | Test | Schritte | Erwartet | Ergebnis | Bemerkung |
|---|------|---------|----------|---------|-----------|
| 1.1 | Admin-Login funktioniert | URL `/admin/login` öffnen, Zugangsdaten eingeben | Weiterleitung ins Dashboard | ☐ | |
| 1.2 | Falsches Passwort wird abgewiesen | Login mit falschem Passwort | Fehlermeldung, kein Zugriff | ☐ | |
| 1.3 | Logout-Button funktioniert | Im Admin ausloggen | Zurück auf Login-Seite | ☐ | |
| 1.4 | Unangemeldeter Zugriff auf `/admin/*` blockiert | Ohne Login `/admin/menus` aufrufen | Redirect nach `/admin/login` | ☐ | |
| 1.5 | Session bleibt nach Reload bestehen | Eingeloggt, F5 drücken | Dashboard bleibt sichtbar | ☐ | |

---

## 2. Admin — Kartenverwaltung

| # | Test | Schritte | Erwartet | Ergebnis | Bemerkung |
|---|------|---------|----------|---------|-----------|
| 2.1 | Übersicht zeigt alle 9 Karten | `/admin/menus` öffnen | 9 Karten (7× Gourmet-Menü, 1× Weinkarte, 1× Barkarte) | ☐ | |
| 2.2 | Karte öffnen | Eine Karte anklicken | Produktliste lädt | ☐ | |
| 2.3 | Drag & Drop Reihenfolge | Produkt in Karte nach oben/unten ziehen | Neue Reihenfolge persistiert nach Reload | ☐ | |
| 2.4 | Produkt „ausverkauft" markieren | Produkt auf Sold-Out setzen | In Gästeansicht als „ausverkauft" sichtbar | ☐ | |
| 2.5 | Produkt aus Karte entfernen | Entfernen-Button klicken | Produkt nicht mehr in Karte, aber im Katalog vorhanden | ☐ | |
| 2.6 | Produkt zu Karte hinzufügen | Aus Katalog hinzufügen | Erscheint in Karte | ☐ | |

---

## 3. Admin — Produkt-Editor

| # | Test | Schritte | Erwartet | Ergebnis | Bemerkung |
|---|------|---------|----------|---------|-----------|
| 3.1 | Produkt öffnen, Felder laden | Beliebiges Produkt öffnen | Name, Beschreibung, Preise geladen | ☐ | |
| 3.2 | Feld ändern und speichern | Beschreibung ändern, speichern | Änderung persistiert nach Reload | ☐ | |
| 3.3 | Auto-Übersetzung DE → EN | EN-Feld leer lassen, Übersetzen-Button | EN-Feld wird plausibel befüllt | ☐ | |
| 3.4 | Preise: mehrere Füllmengen × Preisebenen | Preise eintragen (z. B. 0,75l Flasche Restaurant) | Alle Preise speichern korrekt | ☐ | |
| 3.5 | Preiskalkulation (EK, %, Fix) | EK und % eingeben | VK wird korrekt berechnet | ☐ | |
| 3.6 | Allergene zuweisen | 2 Allergene anklicken, speichern | Sichtbar in Gästeansicht und PDF | ☐ | |
| 3.7 | Bild hochladen | JPG/PNG hochladen | Sharp erzeugt WebP (thumb/medium/large), Bild im Editor sichtbar | ☐ | |
| 3.8 | Bild löschen | Bild entfernen | Weg aus Editor und Gästeansicht | ☐ | |

---

## 4. Admin — Design-Editor

| # | Test | Schritte | Erwartet | Ergebnis | Bemerkung |
|---|------|---------|----------|---------|-----------|
| 4.1 | Design-Editor öffnet | `/admin/design`, Karte wählen | Split-View: Editor + Live-Vorschau | ☐ | |
| 4.2 | Tab-Wechsel Digital ↔ Analog | Tabs oben umschalten | Inhalt wechselt korrekt | ☐ | |
| 4.3 | Template wechseln (elegant/modern/classic/minimal) | Template auswählen | Live-Vorschau aktualisiert | ☐ | |
| 4.4 | Akkordeon 1: Typografie | Schriftfamilie/Größe/Farbe ändern | Vorschau passt sich an | ☐ | |
| 4.5 | Akkordeon 2: Farben | Primär-/Sekundärfarbe ändern | Vorschau zeigt neue Farben | ☐ | |
| 4.6 | Akkordeon 3: Kopf/Fuß | Logo-Upload, Footertext ändern | Sichtbar in Vorschau | ☐ | |
| 4.7 | Akkordeon 4: Titelseite | Titel/Untertitel/Badge ändern | Vorschau auf Titelseite aktualisiert | ☐ | |
| 4.8 | Akkordeon 5: Sektionen | Trennlinie ein/aus, Abstände | Vorschau ändert sich | ☐ | |
| 4.9 | Akkordeon 6: Produkte | Weingut-Anzeige, Beschreibung DE/EN, Preisformat | Vorschau ändert sich | ☐ | |
| 4.10 | Akkordeon 7: Sonstiges | Papierformat, Ränder | Vorschau ändert sich | ☐ | |
| 4.11 | Reset-to-Default funktioniert | Reset-Button klicken, bestätigen | Overrides verschwinden, Template-Default wirkt | ☐ | |
| 4.12 | „Benutzerdefiniert"-Label bei Overrides | Irgendeine Einstellung abweichend setzen | Template-Name zeigt „(benutzerdefiniert)" | ☐ | |
| 4.13 | Eigene Vorlage speichern | „Als Vorlage speichern", Name vergeben | Neue Vorlage in Liste sichtbar | ☐ | |
| 4.14 | Eigene Vorlage anwenden | Andere Karte öffnen, eigene Vorlage wählen | Einstellungen werden übernommen | ☐ | |
| 4.15 | Eigene Vorlage löschen | Vorlage entfernen | Weg aus Liste, keine Karten defekt | ☐ | |

---

## 5. PDF-Export v2

| # | Test | Schritte | Erwartet | Ergebnis | Bemerkung |
|---|------|---------|----------|---------|-----------|
| 5.1 | PDF-Vorschau im iframe | Design-Editor → PDF-Tab | Vorschau öffnet im pdf.js-Viewer, kein Download | ☐ | |
| 5.2 | „In neuem Tab öffnen" | Link oben rechts klicken | Neuer Tab mit pdf.js-Viewer, kein Chrome-Download | ☐ | |
| 5.3 | PDF generieren: Barkarte | PDF herunterladen | Öffnet sauber, Typografie korrekt, Preise zweispaltig | ☐ | |
| 5.4 | PDF generieren: Weinkarte | PDF herunterladen | Weingut/Name/Jahrgang, keine Dedup-Duplikate | ☐ | |
| 5.5 | PDF generieren: Gourmet-Menü (1 exemplarisch) | PDF herunterladen | Titelseite ohne grauen Logo-Kasten, Footer mit „·" | ☐ | |
| 5.6 | PDF generieren: alle restlichen Gourmet-Menüs | PDF jeweils öffnen | Layout durchgehend konsistent | ☐ | |
| 5.7 | Mehrsprachigkeit DE + EN im PDF | PDF mit aktiviertem EN | EN-Beschreibung in Grau, keine Duplikate mit DE/Name/Weingut | ☐ | |
| 5.8 | Footer-Text | Footer unten auf jeder Seite | „Inklusivpreise in Euro · All prices incl. Taxes" (mit `·`) | ☐ | |
| 5.9 | Seitenzahlen | Mehrseitige Karte | Seite X von Y korrekt | ☐ | |
| 5.10 | Bilder im PDF | Produkt mit Bild hat Bild im PDF | Bild sichtbar, nicht verzerrt | ☐ | |

---

## 6. Gäste-Ansicht (öffentlich)

| # | Test | Schritte | Erwartet | Ergebnis | Bemerkung |
|---|------|---------|----------|---------|-----------|
| 6.1 | QR-Code führt zu Karte | QR mit Handy scannen | Gästeansicht lädt <2s | ☐ | |
| 6.2 | Sprachwechsler DE ↔ EN | Flagge klicken | Inhalte wechseln vollständig, kein Fehlendes EN | ☐ | |
| 6.3 | Volltextsuche | Suche nach „Schnitzel" | Produkte werden gefiltert | ☐ | |
| 6.4 | Filter vegetarisch/vegan/alkoholfrei | Filter aktivieren | Nur passende Produkte sichtbar | ☐ | |
| 6.5 | Sticky-Kategorienavigation | Lang scrollen | Kategorieleiste bleibt oben sichtbar | ☐ | |
| 6.6 | Sold-Out-Produkt | Produkt wurde in 2.4 gesperrt | In Gästeansicht als „nicht verfügbar" markiert | ☐ | |
| 6.7 | Produkt-Detail öffnen | Auf Produkt tippen | Details, Bild, Allergene, Zusatzstoffe | ☐ | |
| 6.8 | Weinkarte-Filter | Rebsorte/Region/Jahrgang filtern | Funktioniert sauber | ☐ | |
| 6.9 | Mobile-Viewport (iPhone SE, 375px) | DevTools mobile | Keine horizontale Scrollbar, Buttons groß genug | ☐ | |
| 6.10 | Tablet-Viewport | iPad-Größe | Layout sauber, keine Überlappungen | ☐ | |
| 6.11 | Dark Mode (falls aktiv) | Einstellung prüfen | Noch nicht implementiert (siehe Schritt 5) | ⏭ | |

---

## 7. QR-Code-Verwaltung

| # | Test | Schritte | Erwartet | Ergebnis | Bemerkung |
|---|------|---------|----------|---------|-----------|
| 7.1 | QR-Code-Übersicht zeigt 10 Codes | `/admin/qr-codes` | 10 Einträge sichtbar | ☐ | |
| 7.2 | QR-Download PNG | Download klicken | PNG-Datei, öffnet, scannt korrekt | ☐ | |
| 7.3 | QR-Download SVG | Download klicken | SVG-Datei, scannt korrekt | ☐ | |
| 7.4 | QR-Download PDF (Tischaufsteller) | Download klicken | PDF mit Schnittmarken | ☐ | |
| 7.5 | QR mit Logo und Branding | QR öffnen | Logo eingebettet, Farben passen | ☐ | |

---

## 8. CSV-Import

| # | Test | Schritte | Erwartet | Ergebnis | Bemerkung |
|---|------|---------|----------|---------|-----------|
| 8.1 | CSV hochladen | Datei mit 5 Produkten | Vorschau-Tabelle erscheint | ☐ | |
| 8.2 | Inline-Edit in Vorschau | Zelle korrigieren | Änderung übernommen | ☐ | |
| 8.3 | Neu-Validierung | Nach Edit re-validieren | Fehler verschwinden | ☐ | |
| 8.4 | Import abschließen | Import-Button klicken | Produkte in Datenbank, in Produktliste sichtbar | ☐ | |
| 8.5 | Ungültige CSV | CSV mit Fehlern hochladen | Klare Fehlermeldung, kein Teilimport | ☐ | |

---

## 9. Regression — nicht beschädigt durch letzte Änderungen

| # | Test | Erwartet | Ergebnis | Bemerkung |
|---|------|---------|---------|-----------|
| 9.1 | Digital-Editor (Gästeansicht konfigurieren) funktioniert wie vor PDF-v2-Arbeiten | Keine Regression | ☐ | |
| 9.2 | Design-API GET/PATCH antwortet mit `designConfig`-Feld (nicht `mergedConfig`) | Keine Regression | ☐ | |
| 9.3 | Alle alten Custom-Templates nach Migration noch funktionsfähig | Keine Regression | ☐ | |
| 9.4 | Öffentliche Gästeansicht unverändert schnell (<2s first paint) | Performance ok | ☐ | |

---

## 10. Security (stichprobenhaft im Browser)

| # | Test | Erwartet | Ergebnis | Bemerkung |
|---|------|---------|---------|-----------|
| 10.1 | HTTPS erzwungen (HTTP → HTTPS Redirect) | 301 Redirect | ☐ | |
| 10.2 | SSL-Zertifikat gültig | Keine Browser-Warnung | ☐ | |
| 10.3 | HSTS-Header im Response (DevTools → Network) | `Strict-Transport-Security: max-age=31536000; includeSubDomains` | ☐ | |
| 10.4 | Rate-Limit Login (3 Falscheingaben schnell hintereinander) | Ab ~4. Versuch 429 | ☐ | |

---

## Zusammenfassung

**Getestet am:** ______________
**Blocker (müssen vor Freigabe behoben werden):**

- ______________________________
- ______________________________

**Nicht-blockierende Auffälligkeiten:**

- ______________________________
- ______________________________

**Status Gesamt:** ☐ Freigabe OK   ☐ Nacharbeit nötig

---

## Offene Aufgaben aus Roadmap (nicht Teil dieses Tests)

- Schritt 3: Embed-Code / iFrame-Widget
- Schritt 4: Massenänderungen (prozentuale Preisanpassungen)
- Schritt 5: Dark Mode für Gästeansicht
- Schritt 6 Phase B: `Menu.designConfig`-Spalte aus DB entfernen
