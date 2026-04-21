# Feature: Design-Editor v2 (Opt 2 + 1 + 5)

**Branch:** `feature/design-editor-v2`
**Start:** 20.04.2026
**Status:** Sprint 0 + 1 abgeschlossen · Sprint 2 läuft (SchemaForm-Renderer)
**Verantwortlich:** Hotelier (Freigaben pro Gate) · Claude (Umsetzung + PLAN.md-Pflege)
**Roadmap-Grundlage:** `docs/DESIGN-EDITOR-ROADMAP-v1.md`
**Konzept-Grundlage:** `docs/DESIGN-EDITOR-KONZEPT-v1.md`

---

## Transparenz-Notiz zum übersprungenen Gate 0

Die Roadmap sieht Gate 0 vor (Hotelier testet Framer Free-Tier + Popmenu-Demo, deadline Mi 22.04.2026). **Auf explizite Entscheidung des Hoteliers 20.04.2026 wird Gate 0 übersprungen** ("Opt 2+1+5 jetzt programmieren"). Die Roadmap-Richtung (Schema-driven + Inline-Edit + AI-Theme) gilt als gesetzt. Lessons aus den Benchmark-Produkten fließen nur noch ein, wenn der Hotelier die Tests nachträglich macht.

## Gesetzte Defaults (ohne Rückfrage, Widerspruch jederzeit möglich)

| Thema | Default |
|---|---|
| Undo/Redo | 1 Ebene im MVP, Erweiterung nachträglich |
| Inline-Edit-Mehrsprachigkeit | DE primär, EN-Edit erst Phase 2.5 |
| AI-Theme-Scope | neue Templates + Vorschlag für bestehende |
| AI-Budget | 10 €/Mandant/Monat Soft-Cap, 25 € Hard-Cap |

---

## Scope

### Phase 1 — Schema-Fundament (5–8 AT)
- Schema-Inventar der 8 bestehenden Template-Komponenten (`Hero`, `SectionHeader`, `ItemCard`, `WineBlock`, `BeverageBlock`, `AllergenLegend`, `Footer`, `TitlePage`)
- TypeScript-Schema-Definitionen in `src/lib/design-templates/schemas/*.ts`
- Feldtypen: `boolean`, `select`, `color`, `number`, `text`, `font`, `slider`
- Generischer `<SchemaForm>`-Renderer
- Editor-Shell umbauen: Komponenten-Palette links · Live-Preview mitte · SchemaForm-Inspector rechts
- Migration der 5 bestehenden Template-Configs auf Schema-Format (Legacy-JSON-Fallback bleibt 30 Tage)

### Phase 2 — Inline-Edit (2–3 AT)
- `data-mc-editable`-Attribute auf Preview-Elementen
- Floating-Toolbar (Notion-Stil) für 5 Haupt-Slots: Hero-Text, Hero-Bild, Section-Titel, Akzentfarbe, Footer-Text
- Lock-Indikator für strukturelle Elemente
- SchemaForm-Inspector bleibt als Fallback für alle Felder

### Phase 3 — AI-Theme-Generator (4–6 AT)
- Prompt-zu-Config-Pipeline (Claude API, strukturierter JSON-Output gegen Phase-1-Schema)
- Library mit ~20 Referenz-Themes als Few-Shot-Examples
- Validierungs-Layer: Output muss Schema-valide sein, bei Fehler Re-Prompt (max 2 Retries)
- Budget-Monitoring: Zähler pro Mandant/Monat, Soft-Cap-Warnung, Hard-Cap-Block
- UI: neuer Entry-Flow `/admin/design/new` mit "Beschreiben" vs. "Leeres Template"

## Nicht-Scope

- Puck-Integration (Opt 3) — nicht jetzt
- Hybrid Designer/Editor-Mode (Opt 4) — nicht jetzt, erst wenn Mandanten-SaaS
- Drag & Drop zum Hinzufügen neuer Komponenten-Typen — nicht jetzt
- Undo/Redo >1 Ebene — nicht jetzt (siehe Defaults)

---

## Checklist

### Phase 1
- [x] Sprint 0: Schema-Inventar der 8 Komponenten dokumentiert (`docs/DESIGN-EDITOR-SCHEMA-INVENTAR.md`, 20.04.2026)
- [x] Sprint 1: TS-Schema-Definitionen für alle 8 Komponenten (11 Schemas: 6 Komponenten + 5 global, Commit `1e94127`, 21.04.2026)
- [x] Sprint 1: Schema-Validator (Runtime) + Self-Test (103/103 grün, `scripts/test-design-schemas.ts`, 21.04.2026)
- [ ] Sprint 2: `<SchemaForm>`-Renderer mit allen 8 Feldtypen (boolean, select, color, number, slider, text, font, multitoggle)
- [ ] Sprint 2: Self-Test für SchemaForm-Feld-Rendering (Render-Snapshot pro Feldtyp)
- [ ] Sprint 3: Editor-Shell-Umbau (3-Spalten-Layout)
- [ ] Sprint 3: Migration der 5 Template-Configs auf Schema-Format
- [ ] Sprint 3: Feature-Flag `USE_LEGACY_DESIGN_EDITOR=1` als Fallback
- [ ] Playwright-Smoke-Test: Schema-Editor lädt, ItemCard-Feld ändern, Preview aktualisiert
- [ ] **Gate 1:** Hotelier prüft Staging — ItemCard-Inspector rendert aus Schema
- [ ] **Gate 2:** Hotelier prüft Staging — alle 8 Komponenten auf Schema migriert

### Phase 2
- [ ] `data-mc-editable`-Attribute auf Preview-Elementen
- [ ] Floating-Toolbar-Komponente (Notion-Stil)
- [ ] Persistenz-Endpoint für Inline-Edits
- [ ] Lock-Indikator für strukturelle Elemente
- [ ] Undo 1 Ebene (In-Memory, Session-basiert)
- [ ] Playwright-E2E: Klick auf Hero → Toolbar öffnet → Textänderung → Persistenz
- [ ] **Gate 3:** Hotelier prüft Staging — 5 Inline-Slots funktionieren

### Phase 3
- [ ] Anthropic-API-Key (bereitgestellt vom Hotelier)
- [ ] AI-Prompt-Pipeline (structured output)
- [ ] Library ~20 Referenz-Themes als Few-Shot
- [ ] Schema-Validator als Post-Check mit Re-Prompt
- [ ] Budget-Zähler pro Mandant (DB-Tabelle `AIUsage`)
- [ ] Entry-Flow `/admin/design/new` mit Beschreiben-Option
- [ ] **Gate 4:** Hotelier macht 5 Prosa-Tests → 5 valide unterschiedliche Themes

### Abschluss
- [ ] Legacy-Akkordeon-Editor als `design-editor-legacy.tsx` umbenannt (30 Tage Haltefrist)
- [ ] Hotelier-Klartext-Freigabe für Prod-Merge
- [ ] Merge `feature/design-editor-v2` → `main` via `ship.ps1`
- [ ] **Gate 5:** Hotelier prüft Prod visuell
- [ ] Feature geschlossen, nach 30 Tagen Legacy-Editor löschen

---

## Go/No-Go-Gates

| Gate | Bedingung | Status |
|---|---|---|
| 0 | Hotelier-Test Framer + Popmenu-Demo | ⛔ übersprungen auf Hotelier-Entscheidung 20.04.2026 |
| 1 | Hotelier prüft Staging: ItemCard-Inspector rendert vollständig aus Schema, Änderung `priceStyle` → Preview-Update <300 ms | ⬜ |
| 2 | Hotelier prüft Staging: alle 8 Komponenten auf Schema migriert, 5 bestehende Template-Configs funktional | ⬜ |
| 3 | Hotelier prüft Staging: 5 Inline-Slots funktionieren (Hero-Text, Hero-Bild, Section-Titel, Akzentfarbe, Footer-Text), Persistenz + Undo ok | ⬜ |
| 4 | Hotelier-Prosa-Test: 5 unterschiedliche Beschreibungen → 5 valide, sichtbar unterschiedliche Themes; >80% ohne manuelle Korrektur | ⬜ |
| 5 | Prod-Deploy grün, Hotelier-Klartext-Freigabe "passt", alle bestehenden Templates funktionieren unverändert | ⬜ |

**Regel (Ritual):** Kein Gate darf übersprungen werden. Gate 0 ist auf explizite Hotelier-Entscheidung ausgenommen und dokumentiert.

---

## Rollback-Strategie

### Pro Phase

**Phase 1 (Schema):** Feature-Flag `USE_LEGACY_DESIGN_EDITOR=1` aktiviert den alten Akkordeon-Editor. Die Schema-Files bleiben in der Codebase, werden aber nicht geladen. Die `DesignTemplate.config` behält das alte Format bis Gate 2.

**Phase 2 (Inline-Edit):** Entfernung aller `data-mc-editable`-Attribute deaktiviert den Inline-Layer. Der SchemaForm-Inspector bleibt voll funktional.

**Phase 3 (AI):** Env-Flag `DESIGN_AI_ENABLED=false` blendet den AI-Entry-Flow aus. Kein Code-Rollback nötig.

### Git-Rollback vor Merge
```powershell
git checkout main
git branch -D feature/design-editor-v2   # lokal verwerfen (nur nach Backup!)
```

### Git-Rollback nach Merge
Revert-Commit auf main + `deploy.ps1`. Schema-Migrationen sind rückwärtskompatibel gebaut (Legacy-Config-Format bleibt lesbar).

---

## Delivery-Artefakte

- `docs/FEATURE-DESIGN-EDITOR-V2-PLAN.md` — dieses Dokument, aktive Pflege während Feature
- `docs/DESIGN-EDITOR-ROADMAP-v1.md` — Roadmap-Referenz (bleibt)
- `docs/DESIGN-EDITOR-KONZEPT-v1.md` — ursprüngliche 5-Optionen-Analyse (bleibt)
- `docs/DESIGN-EDITOR-SCHEMA-INVENTAR.md` — Sprint-0-Ergebnis (Komponenten-Inventar, Drift-Befund, Schema-Feldtypen)

---

## Sprint-0-Plan (Schema-Inventar) — abgeschlossen

Claude führt Sprint 0 autonom durch:

1. Read der 5 bestehenden SYSTEM-Template-Definitionen (`src/lib/design-templates/*.ts`)
2. Read der 4 Gäste-Renderer-Komponenten (`src/components/templates/*-renderer.tsx`) + `menu-content.tsx`
3. Pro Komponente: Liste aller konfigurierbaren Felder extrahieren (Typ + Label + aktueller Default)
4. Ergebnis als `docs/DESIGN-EDITOR-SCHEMA-INVENTAR.md` ablegen
5. Danach Sprint 1 starten — TS-Schema-Dateien schreiben

Kein Hotelier-Eingriff bis Gate 1.

---

## Sprint-1-Plan (Schema-Definitionen) — abgeschlossen 21.04.2026

**Lieferumfang:**
- `src/lib/design-templates/schemas/types.ts` — 8 Feldtypen + ComponentSchema + Validation-Types
- `src/lib/design-templates/schemas/validator.ts` — `validateField`, `validateSchema`, `applyDefaults`
- `src/lib/design-templates/schemas/shared/fonts.ts` — 10-Schrift-Whitelist + `isKnownFont`
- `src/lib/design-templates/schemas/shared/typography.ts` — wiederverwendbare `typoLevelFields`
- 11 Schema-Dateien: `hero`, `section-header`, `item-card` (inkl. WineBlock+BeverageBlock als Sub-Gruppen), `allergen-legend`, `footer`, `title-page`, `base` (grundstil/typografie/farben), `navigation`, `icons-badges`
- `scripts/test-design-schemas.ts` — 103 Checks: Schema-Struktur, Validator-Defaults, Fehleingabe-Detection, `applyDefaults`, visibleIf-Felder, Minimal-Template-Kompatibilität

**Commits:**
- `2b53a4d` — Sprint 0 + Sprint 1 Foundation (Types, Validator, Fonts, Typography)
- `1e94127` — Sprint 1 Komponenten-Schemas + Self-Test

---

## Sprint-2-Plan (SchemaForm-Renderer)

Claude führt Sprint 2 autonom durch, kein Hotelier-Eingriff bis Gate 1.

1. `src/components/admin/schema-form/` anlegen:
   - `SchemaForm.tsx` — Top-Level-Renderer: iteriert `ComponentSchema.groups`, rendert pro Feld die passende Field-Komponente, hält Form-State, ruft `validateSchema` bei jedem Change.
   - `FieldRenderer.tsx` — Switch pro `FieldDef.type` → delegiert an Field-Komponenten.
   - Einzelne Field-Komponenten: `BooleanField.tsx`, `SelectField.tsx`, `ColorField.tsx`, `NumberField.tsx`, `SliderField.tsx`, `TextField.tsx`, `FontField.tsx`, `MultiToggleField.tsx` — jede akzeptiert `{ def, value, onChange, error }`-Props, rendert im Admin-Roboto-Stil.
   - `FieldGroup.tsx` — klappbare Gruppe mit Label, wertet `visibleIf` pro Feld aus.
2. Wiederverwendung bestehender UI-Primitives aus `src/components/ui/` (badge, button, input-field) wo möglich, keine neuen Design-Tokens.
3. Integration-Harness in `scripts/test-schema-form.tsx` — rendert alle 11 Schemas mit ihren Defaults in einer einfachen HTML-Datei + Visual-Check-Hinweise.
4. Nach Sprint 2 → Sprint 3 (Editor-Shell-Umbau + Migration der Template-Configs).

---

## Lessons Learned

_Wird während des Features gepflegt._

**Aus Vorgänger-Feature (minimal-only-system, siehe dortigen PLAN.md):**
- LL #4: `docker exec -i` frisst Stdin im ssh-piped-bash → immer `</dev/null` anhängen
- LL #5: Neue Steps in `scripts/deploy.sh` greifen erst beim nächsten Deploy — in der Mitte eines Deploys gezogen hat keine Wirkung. Bei Deploys, die `scripts/deploy.sh` selbst verändern, Manual-Verifikation des neuen Schrittes einplanen.
