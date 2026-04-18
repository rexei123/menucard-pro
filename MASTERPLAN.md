# Master-Plan: MenuCard Pro – Stabilisierung und Infrastruktur Q2/2026

**Stand:** 18.04.2026
**Gilt ab:** sofort, nach Bestätigung durch Hotel Sonnblick
**Voraussetzung:** ARBEITSSCHEMA.md (verbindlich)

---

## 0. Zweck

Dieses Dokument definiert die **perfekte Lösung** für die nächsten 4–6 Wochen. In diesem Zeitraum wird MenuCard Pro von einem funktionalen Produktivsystem in ein **professionell wartbares, sicheres, testbares System** transformiert – ohne die Produktion zu gefährden.

Das Dokument ist aus der Synthese des gesamten bisherigen Gesprächs entstanden:

- Ehrliche Code-Analyse (25 % `@ts-nocheck`, 0 Tests, 3 offene Auth-Routen, keine Input-Validierung)
- ARBEITSSCHEMA.md (5-Phasen-Modell, Quality Gates)
- Bedarf nach einer parallelen Testumgebung (Staging)
- Bedarf nach Branch-basiertem Arbeiten (Git-Workflow)

---

## 1. Aktuelle Situation (Stand 18.04.2026)

### Was funktioniert
- Produktivsystem live unter `menu.hotel-sonnblick.at`
- v2-Datenmodell stabil (17.04.2026), 322 Produkte, 9 Karten
- Design-Compliance 8/8 PASS
- Tägliches DB-Backup (03:00, Rotation 7 Tage)
- Alle 9 Admin-Bugs + 6 von 7 "Bekannte Bugs" (A-1 bis A-4, A-6, A-7) behoben

### Was fehlt

| Lücke | Messung | Risiko |
|---|---|---|
| Test-Suite | 0 Tests | Regressions werden von Gästen entdeckt |
| Staging-Umgebung | keine | Jede Änderung ist Live-Test |
| Git-Branches | nur lokale Dateien | Kein Code-Rollback, kein Vier-Augen-Prinzip |
| `@ts-nocheck` | 31 Dateien (25 %) | Typfehler versteckt |
| Input-Validierung | kein `zod` | 500er statt 400er, Injection-Risiko |
| Offene Auth-Routen | 3 | Sicherheitslücke |
| Structured Logging | keins | Produktionsfehler unsichtbar |
| Error-Handling | 12 try/catch bei 30+ Routen | Unbehandelte Fehler |

---

## 2. Die perfekte Lösung (Zielzustand)

### Drei Säulen

**Säule 1 – Code-Isolation: Git + GitHub**
- Private GitHub-Repo als Single Source of Truth
- Feature-Branches für jede Änderung (`feature/`, `fix/`, `refactor/`)
- `main` = immer produktionsreif
- Conventional Commits für spätere Automatisierung (CHANGELOG)

**Säule 2 – Runtime-Isolation: Staging**
- `staging.menu.hotel-sonnblick.at` auf derselben Hetzner-VM
- Eigene DB (`menucard_pro_staging`), eigener PM2-Prozess, eigenes Nginx-Block
- HTTP-Basic-Auth (verhindert zufälligen Zugriff, erlaubt Demos an Hotel-Mitarbeiter)
- Seed-Daten (keine Produktions-Daten → DSGVO-sauber)

**Säule 3 – Verifikations-Gates: Tests + CI/CD**
- Playwright-Smoke-Suite (Login, Karte anlegen, Produkt anlegen, Gäste-Ansicht, PDF-Export)
- Git-basierter Deploy (kein `scp` mehr – Server zieht per `git pull`)
- Automatische Tests nach jedem Staging-Deploy
- Produktions-Deploy erst nach grünem Staging-Lauf

### Der neue Arbeitsfluss

```
Lokal (Dev)
   │
   ├─ git checkout -b fix/auth-pdf-routes
   ├─ Code ändern
   ├─ npm run build (lokal)
   ├─ Commit + git push
   │
Staging (staging.menu.hotel-sonnblick.at)
   │
   ├─ Auto-Deploy via Git-Hook
   ├─ Playwright Smoke-Tests (Ampel grün/rot)
   ├─ curl-Verifikation auf betroffene Endpoints
   ├─ Manuelle QA im Browser
   ├─ Optional: Demo für Hotel
   │
git merge to main
   │
Produktion (menu.hotel-sonnblick.at)
   │
   ├─ Auto-Deploy von main
   ├─ Post-Deploy-Smoke-Test
   ├─ pm2 logs Check
   └─ 60 s Beobachtung
```

Jede Änderung durchläuft diesen Pfad. Keine Ausnahmen.

---

## 3. Implementierungs-Reihenfolge

### Phase 0 – Infrastruktur (2–3 Tage, einmalig)

**Tag 1 – Git + GitHub**
- 0.1 GitHub-Repo anlegen oder prüfen (`hotelsonnblick/menucard-pro`, privat)
- 0.2 Aktuellen Code vollständig committen + pushen
- 0.3 Server-seitig: `/var/www/menucard-pro` zum Git-Repo machen (`git init`, `remote add`)
- 0.4 Deploy-Script umstellen: `scp` → `git pull + npm ci + build + prisma migrate + pm2 restart`
- 0.5 Verifikation: Kleine Änderung über den neuen Weg deployen

**Tag 2 – Staging-Umgebung**
- 0.6 Staging-DB anlegen (gleiche PostgreSQL-Instanz, neue DB)
- 0.7 Staging-Verzeichnis `/var/www/menucard-pro-staging`, `git clone`
- 0.8 Staging-`.env` (eigener `DATABASE_URL`, `NEXTAUTH_URL`)
- 0.9 PM2-Config erweitern: `menucard-pro-staging` auf Port 3001
- 0.10 Nginx-Server-Block für `staging.menu.hotel-sonnblick.at` mit HTTP-Basic-Auth
- 0.11 Let's Encrypt Zertifikat für Staging-Subdomain
- 0.12 Staging-Seed-Script: Demo-Karten, -Produkte, Test-User

**Tag 3 – Test-Infrastruktur**
- 0.13 Playwright installieren + konfigurieren
- 0.14 Basis-Smoke-Tests (Login, Menü-Liste, Produkt-Liste, Gäste-Ansicht, PDF)
- 0.15 GitHub-Actions-Workflow oder Server-Hook: Tests laufen nach Staging-Deploy automatisch
- 0.16 Abschluss-Test: Gesamter Flow einmal von `git push` bis Produktion

### Phase 1 – Sicherheit (1–2 Tage, jetzt im neuen Workflow)

- 1.1 Branch `fix/auth-pdf-routes` → drei offene Routen absichern (PDF, menu-PDF, QR-Generator)
- 1.2 Branch `feat/zod-validation` → `zod` installieren, Schemas für alle POST/PATCH/DELETE-Routen
- 1.3 Branch `feat/api-error-wrapper` → einheitlicher Error-Wrapper (400/401/403/500-Mapping)

### Phase 2 – Typsicherheit (2–3 Tage)

- 2.1 Branch `refactor/remove-ts-nocheck-api` → API-Routen
- 2.2 Branch `refactor/remove-ts-nocheck-admin` → Admin-Komponenten
- 2.3 Branch `refactor/remove-ts-nocheck-editors` → Editor-Komponenten
- Pro Commit max. 5 Dateien. Ziel: < 5 Dateien mit `@ts-nocheck`

### Phase 3 – Observability (1 Tag)

- 3.1 Branch `feat/structured-logging` → `pino` installieren, `console.*` ersetzen
- 3.2 Request-IDs in API-Wrapper
- 3.3 (Optional) Sentry-Integration für Produktionsfehler

### Phase 4 – Test-Ausbau (1–2 Tage)

- 4.1 Branch `test/admin-flows` → Karte anlegen, Produkt anlegen, Duplikat, Löschen
- 4.2 Branch `test/guest-flows` → Kartenansicht mobile, Filter, Suche, Sprache
- 4.3 Branch `test/regression-fixes` → Regressionstests für alle A-1 bis A-7 Bugs

### Gesamtaufwand

| Phase | Aufwand |
|---|---|
| Phase 0 (Infrastruktur) | 2–3 Tage |
| Phase 1 (Sicherheit) | 1–2 Tage |
| Phase 2 (Typsicherheit) | 2–3 Tage |
| Phase 3 (Observability) | 1 Tag |
| Phase 4 (Tests) | 1–2 Tage |
| **Gesamt** | **7–11 Arbeitstage** |

---

## 4. Kosten

| Posten | Kosten |
|---|---|
| Hetzner (Staging auf gleicher VM) | 0 € extra |
| GitHub (privates Repo im Free Plan) | 0 € |
| Let's Encrypt | 0 € |
| Playwright | 0 € |
| Sentry (optional, 5 k Events/Monat Free) | 0 € |
| **Einmaliger Arbeitsaufwand** | **7–11 Tage** |
| **Laufender Overhead pro Änderung** | **~10 %** (zahlt sich durch weniger Produktionsfehler mehrfach aus) |

---

## 5. Risiken und Gegenmaßnahmen

| Risiko | Wahrscheinlichkeit | Gegenmaßnahme |
|---|---|---|
| Staging-Umgebung lastet VM aus | niedrig | Monitoring; bei Bedarf CX22 → CX32 (~5 €/Monat mehr) |
| Staging-Daten veralten | mittel | Monatliches Refresh-Skript |
| Tests zu spröde (flaky) | mittel | Fokus auf stabile User-Flows, keine Pixel-Perfekt-Tests |
| Deploy-Automatik macht Unerwartetes | niedrig | Manueller Bestätigungs-Schritt vor Produktions-Deploy beibehalten |
| Git-Workflow verlangsamt Solo-Dev | niedrig | Kleine Branches, direkte Merges, kein Code-Review-Zwang |

---

## 6. Integration mit ARBEITSSCHEMA.md

Die 5 Phasen aus ARBEITSSCHEMA.md (§1) bleiben unverändert. Nach Umsetzung dieses Masterplans werden ergänzt:

- **§4 Umsetzung:** Git-Branch-Pflicht für jede Änderung
- **§5 Verifikation Stufe 2:** Automatisierter Staging-Test
- **§7 Deploy-Protokoll:** zweistufig (erst Staging, dann Produktion)

Die Aktualisierung von ARBEITSSCHEMA.md erfolgt als letzter Schritt der Phase 0.

---

## 7. Getroffene Entscheidungen (18.04.2026)

1. **GitHub-Repo:** `rexei123/menucard-pro` (existiert bereits, Branch `main`).
2. **Staging-Zugang:** **HTTP-Basic-Auth** (Entscheidung von Claude). Grund: Schneller einzurichten, ein Passwort teilbar für Hotel-Demos, verhindert Suchmaschinen-Indexierung, NextAuth-Login bleibt **zusätzlich** erhalten (doppelter Schutz).
3. **Staging-Domain:** **`gastro.hotel-sonnblick.at`** (DNS bereits gesetzt, wiederverwendet statt neuer Subdomain).
4. **Sentry:** **später** – Eintrag in `BACKLOG.md` hinterlegt, Trigger: nach Phase 3 oder erster nicht reproduzierbarer Produktionsfehler.
5. **Start:** **sofort** (18.04.2026).

## 8. Belastbare Routine (nicht Gute-Nacht)

Die bisherige Gute-Nacht-Routine bleibt eine persönliche End-of-Day-Zusammenfassung. Die Sicherung des Codes läuft unabhängig davon automatisch:

- **Jeder Commit wird sofort gepusht** (`git push` nach jedem sauberen Arbeitsstand)
- **Jeder Deploy läuft über `git pull`** – ohne Push kein Deploy
- **Kein Sammeln von Commits über Tage** – aktuell 165 offene Dateien im Repo, das soll nie wieder passieren
- **Feature-Branches** verhindern, dass halbe Änderungen auf `main` liegen

Diese Routine ist in `ARBEITSSCHEMA.md §7` als verbindlich hinterlegt.

---

## 8. Abschluss-Bild

Nach 7–11 Arbeitstagen hat MenuCard Pro:

- **Drei sauber getrennte Umgebungen:** Lokal / Staging / Produktion
- **Automatisierte Tests** als Sicherheitsnetz
- **Git-basierten Workflow** mit Feature-Branches
- **Vollständige Typsicherheit** (< 5 `@ts-nocheck`)
- **Input-Validierung** auf allen schreibenden Routen
- **Strukturiertes Logging** + Request-IDs
- **Keine Auth-Lücken**
- **Quality-Gate-Dashboard** (monatlich messbar)

Das System ist dann nicht nur live, sondern **professionell wartbar**. Jede Änderung stärkt, keine verkompliziert.

---

**Vorgeschlagener nächster Schritt:** Phase 0, Tag 1 – GitHub-Repo prüfen/anlegen und Server-seitige Git-Anbindung.
