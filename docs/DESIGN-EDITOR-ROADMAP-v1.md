# Design-Editor v2 — Roadmap

**Stand:** 20.04.2026 · **Freigabe:** Hotelier 20.04.2026 ("roadmap freigegen")
**Grundlage:** `docs/DESIGN-EDITOR-KONZEPT-v1.md` (19.04.2026, Empfehlung: Option 2 + 1 + 5)
**Status:** freigegeben als Richtung · Branch `feature/design-editor-v2` wird nach Gate 0 angelegt
**Verantwortlich:** Hotelier (Freigaben, Gate-0-Tests) · Claude (Umsetzung + PLAN.md-Pflege pro Phase)

---

## Richtung (verbindlich)

| Phase | Inhalt | Aufwand | Tasks |
|---|---|---|---|
| **Phase 1 — Fundament** | Schema-getriebener Editor (Option 2) | 5–8 AT | #48 + #49 + Sprint 0 |
| **Phase 2 — Interaktion** | Inline-Edit auf Live-Preview (Option 1) | 2–3 AT | #50 |
| **Phase 3 — Leuchtturm** | AI-Theme-Generator (Option 5) | 4–6 AT | neu |
| **Summe** | | **11–17 AT (≈ 3–4 Wochen)** | |

**Bewusst nicht jetzt:**
- **Puck-Integration (Option 3)** — erst relevant, wenn Hoteliers komplett neue Komponenten-Typen selbst hinzufügen sollen
- **Hybrid Designer/Editor (Option 4)** — erst relevant, wenn MenuCard Pro über Hotel Sonnblick hinaus als Mandanten-SaaS positioniert wird

---

## Gate 0 — Voraussetzungen (vor Branch-Anlage)

1. **Minimal-Only-Feature abgeschlossen** (Gate 5 erreicht) — ✅ 20.04.2026
2. **Hotelier-Selbsterfahrung:**
   - 30 min Framer-Free-Tier (Inline-Edit erleben)
   - Popmenu-Demo ansehen (Branchen-Tiefe erleben)
   - Deadline: **Mi 22.04.2026**
3. **Hotelier bestätigt im Klartext:** "Ja, Opt 2+1+5 bleibt die Richtung"

Erst dann: Branch `feature/design-editor-v2` mit `docs/FEATURE-DESIGN-EDITOR-V2-PLAN.md` als erstem Commit (per Ritual).

---

## Phase 1 — Schema-Fundament (Woche 1–2)

**Ziel:** Jede Editor-Erweiterung ist danach eine Zeile im Schema, kein UI-Code.

**Sprint 0 (½ AT):** Schema-Inventar der bestehenden Template-Komponenten
  - `Hero`, `SectionHeader`, `ItemCard`, `WineBlock`, `BeverageBlock`, `AllergenLegend`, `Footer`, `TitlePage`

**Sprint 1 (3 AT):** TypeScript-Schema-Definitionen + Validator in `src/lib/design-templates/schemas/*.ts`. Feldtypen: `boolean`, `select`, `color`, `number`, `text`, `font`, `slider`

**Sprint 2 (3 AT):** Generischer `<SchemaForm>`-Renderer — Inspector wird automatisch aus Schema generiert

**Sprint 3 (1–2 AT):** Editor-Shell umbauen — links Komponenten-Palette, mitte Live-Preview, rechts SchemaForm-Inspector. Akkordeons raus.

**Gate 1:** Inspector rendert `ItemCard`-Felder vollständig aus Schema, Hotelier ändert `priceStyle` und sieht Preview-Update in <300 ms
**Gate 2:** Alle 8 Komponenten auf Schema migriert, Migration der 5 bestehenden Template-Configs auf Schema-Format abgeschlossen (Legacy-JSON-Fallback bleibt 30 Tage)

---

## Phase 2 — Inline-Edit-Layer (Woche 3)

**Ziel:** Hotelier klickt direkt im Preview auf Element → Popover öffnet die wichtigsten Felder.

**Umfang:**
- `data-mc-editable="<component>.<field>"` auf Preview-Elementen
- Floating-Toolbar (Notion-Stil) für 5 Haupt-Slots: Hero-Text, Hero-Bild, Section-Titel, Akzentfarbe, Footer-Text
- Rest bleibt über SchemaForm-Inspector editierbar
- Klarer Lock-Indikator für gesperrte Strukturelemente (blauer Outline-Mode)

**Gate 3:** 5 Inline-Slots funktionieren auf Staging, Änderung wird persistiert, Undo funktioniert (1 Ebene reicht fürs MVP)

---

## Phase 3 — AI-Theme-Generator (Woche 4)

**Ziel:** "Beschreib deine Marke" → Theme entsteht in <10 Sekunden.

**Umfang:**
- Prompt-zu-Config-Pipeline (Claude API mit strukturiertem JSON-Output, Schema der Phase 1 als Ziel-Format)
- Library mit ~20 Referenz-Themes als Few-Shot-Examples
- Validierungs-Layer: AI-Output muss durch Schema-Validator, bei Fehler Re-Prompt
- UI: neuer Entry-Flow in `/admin/design/new` ("Beschreiben" vs. "Leeres Template")
- Kosten-Monitoring: Anzahl Generierungen pro Monat, Cap pro Mandant

**Gate 4:** Hotelier-Prosa-Test mit 5 unterschiedlichen Beschreibungen → 5 valide, sichtbar unterschiedliche Themes

---

## Gate 5 — Abschluss

- Gesamtsystem auf Prod
- Hotelier-Klartext-Freigabe: Editor ersetzt Akkordeon-Version, Altstand kann entfernt werden
- Altes `design-editor.tsx` wird als `design-editor-legacy.tsx` 30 Tage stehen gelassen, dann gelöscht

---

## Branch-Strategie

**Primärvorschlag:** Ein Feature-Branch `feature/design-editor-v2` mit Milestone-Tags `ph1-schema-done`, `ph2-inline-done`, `ph3-ai-done`. Staging-Deploy nach jedem Milestone, Gate-Freigabe vom Hotelier pro Phase. Merge erst nach Gate 5.

**Alternative (falls Risiko pro Phase eskalieren sollte):** Drei eigenständige Branches mit eigenen `FEATURE-…-PLAN.md`. Entscheidung endgültig an Gate 0.

---

## Rollback-Strategie

- **Phase 1:** Altes Akkordeon-UI bleibt als Fallback via Feature-Flag `USE_LEGACY_DESIGN_EDITOR=1` bis Gate 2 durch
- **Phase 2:** Inline-Layer hängt an `data-mc-editable`-Attributen — Entfernung des Attributs deaktiviert Inline-Edit, Inspector arbeitet weiter
- **Phase 3:** AI-Layer ist reiner Zusatz-Flow. Deaktivierung durch `DESIGN_AI_ENABLED=false` ohne Editor-Auswirkung

---

## Erfolgskriterien (messbar)

- Neues Editor-Feld hinzufügen = 1 Zeile im Schema (heute: 3–5 Stellen in `design-editor.tsx`)
- Hotelier editiert Hero-Text ohne den Inspector rechts zu öffnen
- AI-Theme-Generierung liefert in >80% der Fälle ein valides Theme ohne manuelle Korrektur
- Editor-Shell-Code schrumpft um >50%

---

## Offene Fragen (vor Gate 0 zu klären)

1. Untergrenze Undo/Redo: nur 1 Schritt (einfach) oder unbegrenzt (Puck-Niveau)?
2. Mehrsprachigkeit im Inline-Edit: sprachabhängige Felder sofort oder erst Phase 2.5?
3. AI-Theme-Generator: nur für neue Templates oder auch "Theme-Vorschlag für bestehendes Template"?
4. Budget-Cap für AI-Aufrufe pro Mandant/Monat?

---

## Bezug zu existierenden Tasks

- **#48 Phase 1: Schema-System bauen** → Sprint 0 + 1 (Inventar + TS-Schemas)
- **#49 Phase 1: SchemaForm-Renderer** → Sprint 2
- **#50 Phase 1: Inline-Edit-Layer im Live-Preview** → gehört in **Phase 2**, nicht Phase 1 (Task-Titel wird beim Branch-Start korrigiert)
- **neu anzulegen:** Phase 3 — AI-Theme-Generator (wenn Gate 0 positiv)

---

## Referenzen

- `docs/DESIGN-EDITOR-KONZEPT-v1.md` — 5 Architektur-Optionen + Benchmarks (Popmenu, Framer, Puck)
- `MenuCard-Pro-Strategie-v3.md` — Gesamtstrategie (Stand 17.04.2026)
- `docs/FEATURE-MINIMAL-ONLY-SYSTEM-PLAN.md` — abgeschlossenes Vorgänger-Feature, Vorlage für PLAN.md-Struktur
