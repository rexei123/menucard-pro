# Design-Template-Strategie: Nur Minimal als SYSTEM

**Datum:** 20.04.2026
**Umfang:** Minimal als Never-Fail-Fallback neu aufgesetzt, Legacy-Templates archiviert

## Was sich ändert

Ab diesem Deploy gibt es nur noch **ein** aktives SYSTEM-Template:

| Template | Vorher | Nachher |
|---|---|---|
| Minimal | SYSTEM, sichtbar | SYSTEM, sichtbar, neu designt |
| Elegant | SYSTEM, sichtbar | SYSTEM, archiviert (UI blendet aus) |
| Modern | SYSTEM, sichtbar | SYSTEM, archiviert (UI blendet aus) |
| Classic | SYSTEM, sichtbar | SYSTEM, archiviert (UI blendet aus) |

Minimal fungiert als "Never-Fail-Fallback": Wenn ein CUSTOM-Template kaputt geht, greift der Editor automatisch auf Minimal zurück.

## Das neue Minimal

- **Schrift:** Inter überall (robust, selbst gehostet über `next/font`)
- **Farben:** Text `#1A1A1A` auf `#FFFFFF`, einziger Akzent `#1E3A5F` (Hotel-Dunkelblau)
- **Bilder:** deaktiviert (verlässliche Darstellung ohne S3/Ladeprobleme)
- **Typografie:** keine Uppercase-Body, kein Kursivtext, Line-Height 1.5 für Lesbarkeit
- **Navigation:** Sticky-TOC + Back-to-Top aktiviert (UX-Grundversorgung)
- **PDF-Analog:** A4, Titelseite + TOC + Legende aktiv, sichere Defaults

## Geänderte Dateien

| Datei | Änderung |
|---|---|
| `src/lib/design-templates/minimal.ts` | komplett neu aufgesetzt |
| `prisma/seed-design-templates.ts` | seedet nur noch Minimal (fasst Legacy nicht an) |
| `scripts/archive-legacy-system-templates.ts` | neu — idempotenter Archivierer mit Safety-Check |
| `scripts/deploy.sh` | neuer Step `[7b/9]`: führt Seed + Archivierung beim Deploy automatisch aus |

## Nächster Schritt

Einmal über `ship.ps1` deployen. Die Deploy-Pipeline erledigt dann:

1. Build mit neuer minimal.ts
2. Seed von Minimal in der DB mit neuen Werten
3. Archivierung von elegant/modern/classic (isArchived=true)
4. PM2-Restart + Smoke-Test

Das Archive-Script bricht ab, falls noch eine Karte auf ein Legacy-Template zeigt — dann muss die Karte zuerst auf Minimal umgestellt werden.

## Was nicht in diesem Paket enthalten ist

Der größere Umbau (Schema-basiertes Editor-System, SchemaForm-Renderer, Inline-Edit-Layer im Live-Preview) ist ein separates Projekt mit mehreren Deploys. Das Blueprint liegt in `docs/DESIGN-EDITOR-KONZEPT-v1.md`. Das aktuelle Paket liefert die **Fundamente**, auf denen der neue Editor später aufbauen kann:

- Robuster Fallback, der immer funktioniert
- Klare Datenstruktur (nur noch 1 SYSTEM + N CUSTOM)
- Kein Aufräumen mehr nötig, wenn die neue Editor-UI kommt

Offene Nachfolge-Tasks: #48 (Schema-System), #49 (SchemaForm), #50 (Inline-Edit).

## Rollback

Falls sich Minimal nach Deploy fehlerhaft rendert:

```sql
UPDATE "DesignTemplate" SET "isArchived"=false WHERE key IN ('elegant','modern','classic');
```

Damit sind die Legacy-Templates sofort wieder im Picker sichtbar und Karten können zurückgestellt werden.
