# MenuCard Pro — Roadmap & offene Bausteine
## Stand: 17.04.2026

Dieses Dokument listet alle noch umzusetzenden Bausteine — geordnet nach Kategorie und empfohlener Reihenfolge. Grundlage ist die Strategie v3.

---

## A. BEKANNTE BUGS & TECHNISCHE SCHULDEN

Sofort behebbar, keine neuen Features — nur Korrekturen am Bestehenden.

| # | Baustein | Beschreibung | Aufwand |
|---|---|---|---|
| A-1 | API: GET /products fehlt | POST existiert, aber kein GET-Handler für Produktliste. Admin nutzt eigene Queries, aber API ist unvollständig. | Klein |
| A-2 | API: GET /variants fehlt | Nur POST exportiert, kein Abruf einzelner Varianten-Listen über API. | Klein |
| A-3 | API: GET /placements fehlt | Nur POST + DELETE, kein Listen-Endpoint für Kartenzuordnungen. | Klein |
| A-4 | API: POST /menus fehlt | Karten können nicht über die API erstellt werden (nur GET). | Klein |
| A-5 | Echte Produktdaten | Aktuell 322 Testprodukte mit teilweise falschen Umlauten und Dummy-Beschreibungen. Müssen durch echte Sonnblick-Daten ersetzt werden. | Mittel |
| A-6 | Benutzerverwaltung | Nur 1 Admin-User. Keine UI zum Anlegen/Bearbeiten von Benutzern (Seite existiert unter /admin/settings/users, aber leer). | Mittel |
| A-7 | Nginx: Upload-Größe | `client_max_body_size 10M` in separater Conf, sollte in menucard-pro Config konsolidiert werden. | Klein |

**Empfohlene Reihenfolge:** A-1 → A-2 → A-3 → A-4 (API-Kompletierung als Block), dann A-5 (Echtdaten), A-6 (Benutzer).

---

## B. GÄSTEANSICHT — VERBESSERUNGEN

Features, die den Gast direkt betreffen.

| # | Baustein | Beschreibung | Aufwand | Abhängigkeit |
|---|---|---|---|---|
| B-1 | Reservierungs-CTA | Button/Link zu Reservierungssystem in der Gästeansicht (z.B. zu Resmio, Quandoo oder eigene Telefonnr.) | Klein | — |
| B-2 | Dark Mode | Dunkles Farbschema für alle 4 Gäste-Templates. Automatisch (System) oder manuell umschaltbar. | Mittel | — |
| B-3 | Embed-Widget / iFrame | Route `/embed/{tenant}/{menu}` mit schlankem Layout ohne Header/Footer. iFrame-Code-Generator im Admin. | Mittel | — |
| B-4 | SEO-Optimierung | Meta-Tags, Open Graph, Schema.org `Menu`-Markup für Google Rich Results. | Klein | — |
| B-5 | Weinlexikon / Glossar | Eigene Seite mit Rebsorten, Regionen, Weinbegriffen. Verlinkung aus Produktdetails. | Mittel | — |
| B-6 | Bestellfunktion (Gast-UI) | Gäste können aus der Karte heraus bestellen. Warenkorb, Tischnummer, Bestätigung. | Hoch | C-1 |

**Empfohlene Reihenfolge:** B-1 → B-4 → B-2 → B-3 → B-5 → B-6

---

## C. ADMIN — NEUE FUNKTIONEN

Erweiterungen des Admin-Backends.

| # | Baustein | Beschreibung | Aufwand | Abhängigkeit |
|---|---|---|---|---|
| C-1 | Bestellsystem (Backend) | Order, OrderLine, OrderLineModifier — Prisma-Modelle existieren bereits im Schema. API-Endpoints und Admin-UI für Bestellübersicht, Status-Workflow (7 States). | Hoch | — |
| C-2 | Bestandsverwaltung | StockLevel-Modell existiert im Schema. UI für Lagermengen, Mindestbestand, automatischer Sold-Out wenn Bestand = 0. | Mittel | — |
| C-3 | Zeitsteuerung | TimeRule-Modell existiert im Schema. Karten automatisch nach Tageszeit/Wochentag ein-/ausblenden (Frühstück, Lunch, Dinner, Bar, Happy Hour). | Mittel | — |
| C-4 | Modifier-Gruppen | ModifierGroup, Modifier, ProductModifierGroup — Modelle existieren. UI für Extras/Beilagen/Größen pro Produkt (z.B. "Pommes +2,50€"). | Mittel | — |
| C-5 | Eventkarten | Temporäre Karten für Hochzeiten, Seminare, Feiern. Start-/Enddatum, eigenes Design. | Klein | — |
| C-6 | Massenänderungen | Preise auf Gruppen-/Kategorieebene ändern (z.B. "alle Weine +5%"). | Mittel | — |
| C-7 | Pairings-Editor | Speisen-Wein-Zuordnung. Manuell und/oder KI-gestützt. ProductPairing-Modell existiert. | Mittel | — |
| C-8 | CSV-Export | Karten/Produkte als CSV herunterladen. Gegenstück zum bestehenden CSV-Import. | Klein | — |
| C-9 | PDF-Vorlagen v2 | Mehrere Layouts: A4, A5, Tischkarte, Barkarte. Template-Auswahl im Admin. | Mittel | — |
| C-10 | Zimmermappe / In-Room | Room-Service-Karte als digitale Zimmermappe mit QR-Code pro Zimmer. | Mittel | C-3 |

**Empfohlene Reihenfolge:** C-5 → C-8 → C-6 → C-9 → C-2 → C-3 → C-4 → C-7 → C-10 → C-1

---

## D. ANALYTICS & INTELLIGENZ

Datengetriebene Features.

| # | Baustein | Beschreibung | Aufwand | Abhängigkeit |
|---|---|---|---|---|
| D-1 | Analytics v2 | Heatmaps, Conversion-Events, Sprachverteilung, Trend-Analysen. Aktuell: Basis-KPIs (Produkte, Karten, QR-Scans). | Hoch | — |
| D-2 | KI-Empfehlungen | Intelligente Weinvorschläge basierend auf Speisenauswahl. "Dazu passt..." in der Gästeansicht. | Hoch | C-7 |

**Empfohlene Reihenfolge:** D-1 → D-2

---

## E. INFRASTRUKTUR & SICHERHEIT

Server, Deployment, Betrieb.

| # | Baustein | Beschreibung | Aufwand | Abhängigkeit |
|---|---|---|---|---|
| E-1 | SSH-Key-only Login | Passwort-Auth deaktivieren, nur Key-basiert. Server-Sicherheit härten. | Klein | — |
| E-2 | Monitoring / Alerting | PM2 Monitoring, Uptime-Checks, Benachrichtigung bei Ausfall. | Klein | — |
| E-3 | Staging-Umgebung | Zweite Instanz zum Testen vor Live-Deployment. | Mittel | — |
| E-4 | CI/CD Pipeline | Automatischer Build + Deploy bei Git-Push (z.B. GitHub Actions). | Mittel | E-3 |

**Empfohlene Reihenfolge:** E-1 → E-2 → E-3 → E-4

---

## F. SKALIERUNG (ZUKUNFT)

Langfristige Features für Wachstum über Hotel Sonnblick hinaus.

| # | Baustein | Beschreibung | Aufwand | Abhängigkeit |
|---|---|---|---|---|
| F-1 | Multi-Tenant Onboarding | Selbstregistrierung für neue Betriebe. Eigener Tenant, eigene Daten, eigenes Branding. | Hoch | — |
| F-2 | POS-Anbindung | Kassenintegration (Datenmodell vorbereitet). Synchronisation Produkte/Preise. | Hoch | C-1 |
| F-3 | Rezept-Verwaltung | RecipeComponent-Modell existiert. Zutaten, Mengen, Kosten pro Gericht. | Mittel | — |
| F-4 | Multi-Sprachen (3+) | Über DE/EN hinaus: IT, FR, etc. Architektur unterstützt es bereits. | Mittel | — |

---

## EMPFOHLENE GESAMTREIHENFOLGE

Basierend auf Geschäftswert, Aufwand und Abhängigkeiten:

### Sprint 1 — Fundament stabilisieren
1. **A-1 bis A-4:** API-Lücken schließen (GET /products, /variants, /placements + POST /menus)
2. **A-6:** Benutzerverwaltung UI
3. **E-1:** SSH-Key-only Login

### Sprint 2 — Gästeerlebnis verbessern
4. **B-1:** Reservierungs-CTA
5. **B-4:** SEO (Meta-Tags, Schema.org)
6. **B-2:** Dark Mode
7. **C-5:** Eventkarten

### Sprint 3 — Admin-Power-Features
8. **C-8:** CSV-Export
9. **C-6:** Massenänderungen (Preise)
10. **C-9:** PDF-Vorlagen v2
11. **B-3:** Embed-Widget / iFrame

### Sprint 4 — Betriebslogik
12. **C-2:** Bestandsverwaltung (StockLevel)
13. **C-3:** Zeitsteuerung (TimeRule)
14. **C-4:** Modifier-Gruppen (Extras/Beilagen)
15. **C-10:** Zimmermappe / In-Room-Dining

### Sprint 5 — Intelligenz & Interaktion
16. **D-1:** Analytics v2
17. **C-7:** Pairings-Editor
18. **B-5:** Weinlexikon / Glossar
19. **D-2:** KI-Empfehlungen

### Sprint 6 — Bestellsystem
20. **C-1:** Bestellsystem Backend (Order, OrderLine)
21. **B-6:** Bestellfunktion Gast-UI

### Zukunft — Skalierung
22. **F-1:** Multi-Tenant Onboarding
23. **F-2:** POS-Anbindung
24. **F-3:** Rezept-Verwaltung
25. **F-4:** Multi-Sprachen (3+)

---

## LEGENDE

| Symbol | Bedeutung |
|---|---|
| Klein | < 1 Tag Aufwand |
| Mittel | 1-3 Tage Aufwand |
| Hoch | 3+ Tage Aufwand |
| Schema existiert | Prisma-Modell vorhanden, API/UI fehlt |

---

*Dieses Dokument wird fortlaufend aktualisiert. Referenz: `MenuCard-Pro-Strategie-v3.md`*
