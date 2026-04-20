# Feature: Minimal als einziges SYSTEM-Template (Never-Fail-Fallback)

**Branch:** `feature/minimal-only-system`
**Start:** 20.04.2026
**Status:** Gate 2 erledigt — Hotelier-Freigabe für Merge steht an (Gate 3)
**Verantwortlich:** Hotelier (Freigabe) · Claude (Umsetzung + Pflege dieses Dokuments)

---

## Scope

- **Minimal** wird neu designed als Never-Fail-Fallback (Inter, `#1A1A1A` auf `#FFFFFF`, Akzent `#1E3A5F`, keine Bilder, keine Uppercase-Body, Line-Height 1.5, A4-PDF-Analog mit TOC + Titelseite)
- **Elegant / Modern / Classic** bleiben in der DB (Legacy-Zugriffe), werden aber via `isArchived=true` aus dem Picker ausgeblendet
- Neues Script `scripts/archive-legacy-system-templates.ts`: archiviert idempotent und **bricht ab**, wenn noch eine Karte auf ein Legacy-Template zeigt (Safety-Check)
- `scripts/deploy.sh` bekommt Step `[7b/9]`, `scripts/deploy-staging.sh` bekommt Step `[6b/8]`: Seed + Archive laufen automatisch, wenn `src/lib/design-templates/*.ts` oder `prisma/seed-design-templates.ts` im Deploy-Diff sind

## Nicht-Scope

- Schema-System (Task #48 — separates Projekt, mehrere Deploys)
- SchemaForm-Renderer (Task #49)
- Inline-Edit-Layer im Live-Preview (Task #50)

## Checklist

- [x] `src/lib/design-templates/minimal.ts` neu aufgesetzt (Never-Fail-Config)
- [x] `prisma/seed-design-templates.ts` seedet nur noch Minimal (fasst Legacy nicht an)
- [x] `scripts/archive-legacy-system-templates.ts` erstellt (idempotent, Safety-Check)
- [x] `scripts/deploy.sh` Step `[7b/9]` eingebaut
- [x] `scripts/deploy-staging.sh` Step `[6b/8]` eingebaut
- [x] Commit `210d6bc`, Branch `feature/minimal-only-system` gepusht
- [x] Staging via `ship.ps1 -StagingOnly` deployed
- [x] Test-Gate grün (Playwright-Smoke-Suite)
- [x] Staging-DB manuell korrigiert: alle Karten auf Minimal, Legacy archiviert (nötig, weil beim ersten Staging-Deploy `NEEDS_TEMPLATE_SEED=0` war — siehe Lessons Learned)
- [x] **Gate 2:** Hotelier hat Staging visuell geprüft — Picker zeigt "Aktive Vorlagen (2)" mit Minimal + test 1, "Archiv (3)" mit Elegant/Klassisch/Modern · Bestätigung 20.04.2026 ("das passt")
- [x] Working-Tree bereinigt: Branch-Dateien restored, fremde Modifikationen gestashed (`stash@{0}: secrets-rotation-wip`)
- [ ] **Gate 3 OFFEN:** Explizite Merge-Freigabe vom Hotelier im Klartext
- [ ] Merge `feature/minimal-only-system` → `main` via `ship.ps1`
- [ ] **Gate 4 OFFEN:** Prod-Deploy erfolgreich (Step `[7b/9]` läuft auto: `prisma db push` + seed + archive)
- [ ] **Gate 5 OFFEN:** Hotelier prüft Prod visuell auf `https://menu.hotel-sonnblick.at`
- [ ] Feature geschlossen, Delivery-Artefakte aufgeräumt

## Go/No-Go-Gates

| Gate | Bedingung | Status |
|---|---|---|
| 1 | Playwright-Smoke-Suite grün gegen Staging | ✅ 20.04.2026 |
| 2 | Hotelier hat Staging visuell geprüft: Picker zeigt **nur** Minimal als SYSTEM + bestehende CUSTOM-Vorlagen · alle 3 Karten (abendkarte, barkarte, weinkarte) rendern sauber in Minimal · Admin-Login OK | ✅ 20.04.2026 |
| 3 | Hotelier gibt **im Klartext** Merge-Freigabe ("Merge", nicht nur `y` in `ship.ps1`) | ⬜ |
| 4 | Prod-Deploy erfolgreich, Step `[7b/9]` grün, PM2-Restart ohne Crash, Smoke HTTP 200 | ⬜ |
| 5 | Hotelier hat Prod visuell geprüft (Gäste-Ansicht + Admin-Picker) | ⬜ |

**Regel:** Kein Gate darf übersprungen werden. Wenn ein Schritt das aktuelle offene Gate überspringen würde, zuerst explizit beim Hotelier zurückfragen.

## Rollback

**DB-Rollback (Legacy-Templates wieder sichtbar machen):**
```sql
UPDATE "DesignTemplate" SET "isArchived"=false WHERE key IN ('elegant','modern','classic');
```

**Git-Rollback vor Merge:**
```powershell
git checkout main
git branch -D feature/minimal-only-system   # lokal verwerfen
```

**Git-Rollback nach Merge:** Revert-Commit auf main erzeugen, via `deploy.ps1` deployen.

## Delivery-Artefakte

- `docs/DESIGN-MINIMAL-REBRAND-20260420.md` — Kontext-Report, wird nach Feature-Abschluss im Projekt gepflegt
- `.claude-delivery/minimal-only-system.bundle` — Git-Bundle aus der Delivery-Session, **obsolet** nach Checkout (kann nach Feature-Abschluss gelöscht werden)
- `deliver-minimal-rebrand.ps1` — Einmal-Helper, **obsolet** nach Checkout (kann gelöscht werden)

## Lessons Learned (für zukünftige Deploys relevant)

**1. Staging-Deploy überspringt conditional Steps bei leerem Diff**
Der Staging-Deploy vergleicht `git diff PRE_DEPLOY_HEAD..TARGET_HEAD`. Wenn Staging bereits auf dem Ziel-Commit steht (z.B. nach einem fehlgeschlagenen ship.ps1-Retry), ist der Diff leer → `NEEDS_TEMPLATE_SEED=0` → Step `[6b/8]` wird übersprungen. Fix hier war manuelle SQL-Korrektur. Langfristig: Deploy-Script sollte auch bei leerem Diff prüfen, ob Soll-Zustand in der DB erreicht ist.

**2. `prisma db push` lief auf Staging nie für diesen Branch**
Gleicher Grund (`NEEDS_PRISMA=0`). Deshalb fehlt der `TemplateType`-Enum in der Staging-DB. Der Seed wirft `type "public.TemplateType" does not exist`. Auf Prod irrelevant, weil Prod den Enum seit früheren Deploys hat.

**3. Prod-Stand ist glücklich**
Alle 3 Prod-Karten zeigen bereits auf `minimal` (Hotelier hatte sie vor Beginn dieser Arbeit manuell umgestellt). Deshalb greift der Safety-Check des Archive-Scripts auf Prod nicht, und Step `[7b/9]` läuft beim Prod-Deploy sauber durch.

**4. `docker exec -i` frisst Stdin beim gepipten Bash-Script**
Klassischer Fallstrick: `ssh host "echo $b64 | base64 -d | bash"` mit `docker exec -i` im Script → erste `docker exec`-Zeile frisst den Rest des Scripts auf. Fix: `</dev/null` an jede `docker exec`-Zeile anhängen, oder Script via `/tmp/run.sh` ausführen.
