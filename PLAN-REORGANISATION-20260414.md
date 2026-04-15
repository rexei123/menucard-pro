# MenuCard Pro — Reorganisations- & Weiterentwicklungsplan

**Erstellt:** 14.04.2026
**Ziel:** Aktuellen Stand perfekt sichern, dokumentieren, bereinigen — dann UI/UX-Original-Strategie fertigstellen — dann neue Features bauen.

---

## Phase 1 — Bestandsaufnahme & Vollsicherung (30 Min)

**Was:**
1. PostgreSQL-Vollbackup (`pg_dump` → `/root/menucard-backup-20260414.sql`)
2. Code-Stand als Git-Tag `v1.0-stabil` + Push zu GitHub
3. `.env`, Nginx-Config, PM2-Config gesichert (`/root/config-backup-20260414.tar.gz`)
4. Inventar-Snapshot: Datei-Baum, Dependencies, Routen, Prisma-Schema, DB-Zählerstände

**Deliverables:**
- SQL-Backup auf Server + lokal
- Git-Tag auf GitHub
- `INVENTAR-20260414.md` mit faktischem Ist-Zustand

**Freigabe:** Bestätigung, dass alles gesichert ist

---

## Phase 2 — Dokumentation neu aufsetzen (45 Min)

**Was:**
1. **CLAUDE.md** — komplett neu, reflektiert aktuellen Code (Routen, Datenmodell, Prozesse)
2. **README.md** — öffentliche Projektbeschreibung, Setup, Deployment
3. **CHANGELOG.md** — historisch ab MVP bis heute, Semantic Versioning
4. **API.md** — alle REST-Endpunkte mit Request/Response
5. **DATENMODELL.md** — Prisma-Schema visuell + erklärt
6. **DEPLOYMENT.md** — Schritt-für-Schritt Server-Setup, Backup, Restore

**Deliverables:** 6 aktualisierte MD-Dateien, konsistent und fehlerfrei

**Freigabe:** Dokumente kurz reviewen, dann commit

---

## Phase 3 — Memory-Bereinigung (15 Min)

**Was:**
1. Alle 10 Memory-Dateien reviewen
2. Veraltete Einträge löschen (z.B. "Phase 1-4 deployed" ist erledigt, gehört in CHANGELOG, nicht Memory)
3. Widersprüche auflösen (z.B. falsche Routen-Claims)
4. Memory-Einträge auf **3 Kern-Kategorien** reduzieren:
   - **User-Kontext** (Hotel, Windows, zwei Shells)
   - **Arbeitsweise-Feedback** (Scripts, keine Regex-Replacements, UTF-8)
   - **Projekt-Referenzen** (Server-IP, Auth, wichtige Test-IDs)

**Deliverables:**
- MEMORY.md schlank (max 6 Einträge)
- Alle Memory-Dateien aktuell und widerspruchsfrei

**Freigabe:** Kurz-Review der neuen MEMORY.md

---

## Phase 4 — Code- & Server-Cleanup (30 Min)

**Was:**
1. `.bak`-Dateien im Projekt löschen
2. Alte Test-Scripts in `/tmp` auf dem Server entfernen (`diag-pass2`, `fixes-pass3..6`, alte Playwright-Versionen v1–v3)
3. Alte SQL-Backups im `/root` ausdünnen (nur die letzten 2 behalten)
4. Ungenutzte Routen/Komponenten identifizieren (via `knip` oder manueller Check)
5. Obsolet gewordene Scripts im Projektordner in `/archive/2026-04/` verschieben

**Deliverables:** Saubere Projektstruktur, keine Karteileichen

**Freigabe:** OK zum Löschen

---

## Phase 5 — UI/UX-Original-Strategie fertigstellen (mehrere Arbeitsrunden)

**Referenz:** Original-Custom-Instructions (Hotel-Sonnblick-Produktbriefing)

**Was:**
1. **Gap-Analyse:** Produktbriefing Zeile für Zeile gegen aktuellen Stand
   - Was ist vollständig? (Häkchen)
   - Was fehlt oder ist unvollständig? (Liste)
   - Was ist aus dem Briefing, aber bewusst nicht im MVP? (separate Liste für später)

2. **Manuelle Test-Runde:** `TESTPROTOKOLL-MANUELL-V2.md` — 14 Sektionen durchgehen
   - Login & Session-Management
   - Dashboard & Karten-Übersicht
   - Produkt-Editor (alle Felder, Varianten, Bilder, Auto-Übersetzung)
   - Karten-Editor (Drag&Drop, Sichtbarkeit, Zeitsteuerung)
   - Design-Editor (7 Akkordeons, Live-Vorschau, PDF-Tab)
   - Gäste-Ansichten (4 Templates × Karten)
   - Bilder-Upload (Sharp/WebP)
   - CSV-Import
   - QR-Code-Download
   - Rollen & Rechte
   - Analytics
   - Regression (alte Funktionen)
   - Security (Nginx, Rate-Limit, Header)
   - Performance (Ladezeiten)

3. **Fix-Runden:** Jeder manuelle Befund wird gefixt, neu getestet, dokumentiert

4. **Abschluss:** Produkt-Briefing-Konformitäts-Report — was ist 100%, was ist bewusst ausgeklammert

**Deliverables:**
- Gap-Analyse-Dokument
- Alle manuellen Test-Befunde gefixt
- Konformitäts-Report

**Freigabe:** Nach jedem Test-Sektion und nach jedem Fix

---

## Phase 6 — Neue Features (langfristig, nach Freigabe)

**Kandidaten aus dem Original-Briefing, die im MVP ausgeklammert waren:**

1. **Bestellfunktion** (vorbereitet, nicht aktiv)
2. **Reservierungs-CTA**
3. **Bestandsverwaltung** (Mindestbestand, Ausverkauf-Automatik)
4. **Einkaufspreis-Kalkulation & Margen-Anzeige**
5. **Happy-Hour-Logik & Saisonkarten**
6. **Eventkarten** (Hochzeiten, Seminare)
7. **Zimmermappe / In-Room-Dining-Ansicht**
8. **Weinlexikon / Glossar**
9. **Analytics v2** (Heatmaps, Conversion-Events)
10. **POS-Anbindung** (optional)
11. **KI-Empfehlungen** (Pairing-Vorschläge, Tagesempfehlungen)
12. **Embed-Widget / iFrame**
13. **Dark Mode**
14. **SSH-Key-only Login**

**Priorisierung:** Nach Phase 5 gemeinsam nach Mehrwert × Aufwand.

---

## Zeitplan-Schätzung

| Phase | Aufwand | Status |
|---|---|---|
| 1. Sicherung | 30 Min | Bereit zu starten |
| 2. Doku | 45 Min | |
| 3. Memory | 15 Min | |
| 4. Cleanup | 30 Min | |
| 5. UI/UX-Tests | Mehrere Runden | |
| 6. Features | Langfristig | |

**Gesamtaufwand Phase 1–4: ca. 2 Stunden** (einmalige Grundlagenarbeit)
**Phase 5:** Je nach Anzahl Befunde 1–3 Arbeitstage
**Phase 6:** Pro Feature 2–8 Stunden

---

## Arbeitsweise

- **Ein Phase nach der anderen**, jeweils mit Freigabe-Punkt
- **Zwei-Shell-Workflow** beibehalten (PowerShell lokal + SSH-Server)
- **Keine Regex-Replacements** bei größeren TSX-Dateien — komplett neu schreiben
- **Jede Änderung:** Backup → Edit → Build → Test → Commit
- **Nach jedem Meilenstein:** Git-Tag

## Freigabe-Punkte

1. ✅ Plan freigegeben → Phase 1 starten
2. ⏳ Nach Phase 1: Sicherung bestätigt → Phase 2
3. ⏳ Nach Phase 2: Docs OK → Phase 3
4. ⏳ Nach Phase 3: Memory OK → Phase 4
5. ⏳ Nach Phase 4: Cleanup OK → Phase 5
6. ⏳ Nach Phase 5: Original-UI/UX 100% → Phase 6
