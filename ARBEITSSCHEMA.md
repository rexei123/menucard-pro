# Arbeitsschema MenuCard Pro

**Stand:** 18.04.2026  **Status:** Verbindlich für alle Folgeänderungen
**Gilt für:** Hotel Sonnblick · menu.hotel-sonnblick.at · Produktivsystem

Dieses Dokument beschreibt die verbindliche Vorgehensweise für jede Änderung am System. Ziel: Jede Änderung stärkt das System messbar — sie erhöht Stabilität, Sicherheit oder Klarheit, ohne Komplexität unnötig zu vergrößern.

---

## 0. Grundprinzip

Jede Änderung muss mindestens eines dieser Ziele verbessern, ohne eines zu verschlechtern:

1. **Weniger Bugs** (robuster)
2. **Weniger Komplexität** (einfacher)
3. **Mehr Sicherheit** (Auth, Validierung, Tenant-Scope)
4. **Mehr Testbarkeit** (kleinere Einheiten, klare Schnittstellen)
5. **Mehr Klarheit** (Typen, Benennung, Dokumentation)

Wenn eine Änderung eines dieser Kriterien verschlechtert, ohne die anderen klar zu verbessern: **Stopp und überdenken.**

---

## 1. Phasen-Modell jeder Änderung

Fünf Phasen, strikt sequenziell:

| # | Phase | Artefakt |
|---|---|---|
| 1 | Analyse | Scope- und Risiko-Check (mental oder kurz notiert) |
| 2 | Plan | Schriftlicher Plan bei Medium/Large Changes |
| 3 | Umsetzung | Code + Backups |
| 4 | Verifikation | Build, Smoke-Test, manuelle Prüfung |
| 5 | Dokumentation | Commit, Memory, CLAUDE.md, ggf. Changelog |

Überspringen einer Phase ist der häufigste Grund für Produktionsfehler.

---

## 2. Phase 1 – Analyse (vor Code)

### A. Scope-Check

- Was genau wird geändert? (1 Satz)
- Welche Dateien, DB-Tabellen, API-Routen, öffentlichen Seiten sind betroffen?
- Was darf **nicht** mit geändert werden? (Scope-Creep-Schutz)

### B. Komplexitäts-Budget

| Kategorie | Umfang | Vorgehen |
|---|---|---|
| **Small** | ≤ 3 Dateien, ≤ 100 LOC | Direkt umsetzen |
| **Medium** | 4–10 Dateien, ≤ 500 LOC | Kurzer Plan (siehe Phase 2) |
| **Large** | > 10 Dateien, > 500 LOC, DB-Migration, neue Abhängigkeit | ADR + Review-Pause |

### C. Risiko-Check

- **Hoch:** Auth, Payment, DB-Schema, Multi-Tenancy, PDF/QR-Generator, NextAuth-Config
- **Mittel:** Admin-Editoren, API-Routen, Prisma-Queries, Template-Konfiguration
- **Niedrig:** Nur UI, Wording, CSS, Icons, Reihenfolgen

Bei hohem Risiko: zusätzlich Rollback-Plan schriftlich fixieren.

### D. Abhängigkeits-Check

Neue npm-Pakete nur mit Antwort auf: Warum nötig? Größe? Lizenz? Maintenance-Status (letzter Commit < 12 Monate)? Alternative im Core?

---

## 3. Phase 2 – Plan

Bei Medium + Large Changes: Kurzplan im Chat oder als Datei, maximal 1 Seite:

- **Ziel** (1 Satz)
- **Warum jetzt** (1 Satz)
- **Was sich ändert** (Bullet-Liste, Dateien + Zweck)
- **Was sich NICHT ändert** (explizit, gegen Scope-Creep)
- **Teststrategie** (wie verifizieren wir Erfolg)
- **Rollback-Plan** (wie machen wir rückgängig, wenn etwas bricht)

Der Plan muss von Ihnen bestätigt werden, bevor umgesetzt wird.

---

## 4. Phase 3 – Umsetzung

### Unverrückbare Regeln

- **Backup-Prinzip:** Vor jeder größeren Änderung `cp datei datei.bak` auf dem Server; DB-Backup < 24h alt verifizieren.
- **Klein & rückholbar:** Eine Änderung = ein logischer Commit = ein Deploy.
- **Kein neuer `@ts-nocheck`.** Entfernung ist willkommen, Hinzufügen verboten.
- **Input-Validierung:** Jede neue POST/PATCH/DELETE-Route hat ein `zod`-Schema.
- **Auth-Check:** Jede neue API-Route prüft `getServerSession()` + Rolle über `hasMinRole()`.
- **Tenant-Scope:** Jede Prisma-Query ist auf `tenantId` oder `location.tenantId` eingegrenzt.
- **Kein stummer Fehler:** `catch (e) {}` ohne `console.error` oder Logger ist verboten.
- **Keine Regex-Ersetzung** in großen TSX-Dateien — komplett neu schreiben.
- **Material Symbols statt Emojis** in Gäste- und Admin-Oberfläche.

### TypeScript-Härte-Regel

Wenn eine Änderung eine Datei berührt, die `@ts-nocheck` trägt: Prüfen, ob der Header entfernt werden kann. Wenn ja, im selben Commit entfernen. Damit baut sich die Typsicherheit kontinuierlich auf.

### Komplexitäts-Warnsignale (Stop & Review)

Nicht weiter coden, wenn:

- Eine Datei wächst über 500 LOC
- Eine Funktion wächst über 50 LOC
- Eine Prisma-Query hat mehr als 3 Ebenen `include`
- Drei gleiche Code-Blöcke entstehen (Rule of Three → extrahieren)
- Ein Commit berührt mehr als 15 Dateien
- Copy-Paste zwischen Komponenten

---

## 5. Phase 4 – Verifikation (dreistufig)

### Stufe 1 – Build & Typecheck

```
npm run build
```

Muss ohne neue Warnungen durchlaufen. Build-Fehler = Deploy-Stop.

### Stufe 2 – Automatisierter Smoke-Test

Nach Einrichtung der Playwright-Suite (Phase 4 des Härtungslaufs):

```
npx playwright test smoke
```

Deckt mindestens: Login, Karte anlegen, Produkt anlegen, Gästeansicht, PDF-Export.

### Stufe 3 – Manuelle Verifikation

- Betroffene Admin-Seiten im Browser öffnen → keine Fehler in Console
- Betroffene Gäste-Seiten öffnen → Darstellung korrekt, Status 200
- Server-Logs prüfen:
  ```
  pm2 logs menucard-pro --lines 30 --err --nostream
  ```
- Bei hohem Risiko: Claude-in-Chrome-Lauf mit Screenshot-Vergleich

---

## 6. Phase 5 – Dokumentation

Immer, bei jedem Commit:

- **Commit-Message:** Was + Warum (nicht nur Was). Beispiel: `fix(qr): QRCode-Query auf locationId statt Relation (keine Prisma-Relation definiert)`
- **Memory-Update:** Bei neuen Mustern, Stolperfallen oder strategischen Entscheidungen → neue oder aktualisierte Datei in `.auto-memory/`
- **CLAUDE.md-Update:** Bei Schema-Änderungen, neuen Routen oder Konventionen
- **Changelog-Eintrag:** Bei Breaking Changes an API oder Datenmodell → `docs/CHANGELOG.md`

---

## 7. Belastbare Git-Routine (verbindlich ab 18.04.2026)

Die Gute-Nacht-Routine ist **nicht** die Sicherungs-Routine. Sie dient nur der End-of-Day-Zusammenfassung. Die eigentliche Sicherung läuft automatisch als Teil jeder Änderung:

**Regel 1 – Jede Änderung = Git-Commit + Push, sofort.**
Ein Commit, der nicht auf GitHub liegt, ist verloren. Deshalb: direkt nach jeder abgeschlossenen Änderung `git push`.

**Regel 2 – Jeder Deploy läuft über Git.**
Produktion und Staging ziehen Code per `git pull`. Es gibt keinen Weg, etwas zu deployen, ohne vorher zu pushen. Damit wird die Push-Routine zwingend.

**Regel 3 – Feature-Branch für jede Änderung.**
`git checkout -b feature/xxx` vor dem ersten Edit. `main` bleibt immer produktionsreif.

**Regel 4 – Kein Sammel-Commit über mehrere Tage.**
Wenn eine Änderung am Abend nicht fertig ist: als Draft-Commit pushen (`git commit -m "WIP: ..."`) oder stashen. Nie 165 lose Dateien liegen lassen.

## 8. Deploy-Protokoll (verbindlich, Git-basiert, Eine-Shell-Workflow)

Jeder Deploy folgt strikt diesem Ablauf in einer einzigen PowerShell:

1. **Backup-Check:** Letztes DB-Backup < 24h alt (`ls -lat /var/backups/menucard-pro/ | head`)
2. **Push:** `git push origin feature/xxx` (bei Bedarf `-u`)
3. **Staging-Deploy:** `ssh $SERVER "/var/www/menucard-pro-staging/deploy.sh feature/xxx"`
4. **Staging-Verifikation:** Playwright-Smoke-Tests auf `gastro.hotel-sonnblick.at` (grün/rot)
5. **curl-Check** auf mindestens drei betroffene Endpoints (Staging)
6. **Merge:** `git checkout main && git merge --no-ff feature/xxx && git push origin main`
7. **Produktions-Deploy:** `ssh $SERVER "/var/www/menucard-pro/deploy.sh main"`
8. **Produktions-Verifikation:** `curl` auf betroffene Endpoints + `pm2 logs menucard-pro --lines 15 --err --nostream`
9. **Rollback-Bereitschaft:** Bei Fehlern `git revert` + erneuter Deploy (kein manuelles `.bak`-Spiel mehr)

Kein Deploy ohne alle neun Schritte. Kein Deploy ohne vorherigen Staging-Lauf.

---

## 9. Quality Gates (monatlich messen)

Metriken, die sich nie verschlechtern dürfen. Messung am ersten Montag im Monat, Ergebnis in `docs/QUALITY-METRICS.md`:

| Metrik | 18.04.2026 | Ziel Q3/2026 | Hard Limit |
|---|---|---|---|
| Dateien mit `@ts-nocheck` | 31 | < 5 | darf nur sinken |
| Playwright-Testdateien | 0 | > 20 | darf nur steigen |
| API-Routen ohne Auth-Check | 3 | 0 | = 0 ab 01.05.2026 |
| POST/PATCH/DELETE-Routen ohne `zod` | ~30 | 0 | darf nur sinken |
| Offene Bugs (A-*, Prio 1) | 1 (A-5 deferred) | 0 | < 3 |
| Build-Warnungen | unbekannt | 0 | darf nur sinken |
| Dateien > 500 LOC | unbekannt | < 5 | darf nur sinken |
| `console.log` in Production-Code | 34 | < 10 | darf nur sinken |

Messung-Script: `scripts/measure-quality.sh` (anzulegen in Phase 3 des Härtungslaufs).

---

## 10. Definition of Done

Eine Änderung ist erst fertig, wenn **alle** Punkte erfüllt sind:

- [ ] Build grün (`npm run build` ohne neue Warnungen)
- [ ] Tests grün (sobald Test-Suite vorhanden)
- [ ] Manuell verifiziert (Admin-Sicht + Gäste-Sicht)
- [ ] PM2-Logs sauber (keine neuen Errors nach 60s Laufzeit)
- [ ] Commit mit aussagekräftiger Message ("Was + Warum")
- [ ] Memory / CLAUDE.md / Changelog aktualisiert, falls nötig
- [ ] Quality Gates nicht verschlechtert
- [ ] Rollback-Weg dokumentiert (bei Medium/Large Changes)

---

## 11. Sonderfälle

### DB-Migrationen (Prisma)

- Immer zuerst auf lokalem Branch testen (wenn vorhanden) oder mit DB-Dump
- `npx prisma db push` nur nach explizitem Backup und Bestätigung
- Nie destruktive Migrationen (Spalte löschen, Tabelle droppen) ohne Plan + Backup
- Schema-Änderungen immer in CLAUDE.md nachziehen

### Neue npm-Abhängigkeiten

- Zuerst im Chat begründen (Warum, Größe, Alternativen)
- `npm install --save-exact` (keine Range-Version)
- Lizenz prüfen (MIT, Apache 2.0, BSD OK; GPL/AGPL → Rückfrage)
- Lock-File committen

### UI-Redesign

- Keine Logik-Änderungen beim Design-Arbeiten (nur CSS, Farben, Schriften)
- Nach jeder Änderung Design-Compliance-Lauf: `bash design-compliance-remote.sh <tag>` → Ziel 8/8 PASS
- Screenshots im Memory-Ordner archivieren für Vorher/Nachher-Vergleich

### Öffentliche Gäste-Features

- Müssen auf Mobile zuerst getestet werden (Responsive)
- Performance-Budget: LCP < 2,5 s, TTFB < 500 ms (auf Cellular-Connection)
- Keine client-seitigen Analytics ohne DSGVO-Check

---

## 12. Umgang mit diesem Dokument

- **Revisionen** werden am Kopf mit Datum eingetragen, alte Fassungen in Git-History
- **Abweichungen** sind erlaubt, müssen aber im Commit begründet werden ("Abweichung von ARBEITSSCHEMA.md §X, weil …")
- **Verbesserungen** am Schema selbst sind willkommen — jede Session darf Feedback einbringen

---

**Nächste Überprüfung dieses Schemas:** 01.07.2026 oder nach jedem Produktionsvorfall.
