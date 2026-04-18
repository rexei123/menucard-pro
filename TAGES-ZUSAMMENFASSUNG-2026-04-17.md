# Tages-Zusammenfassung — 17. April 2026

## Was heute erledigt wurde

### 1. Taxonomie-Überarbeitung (komplett)
- **Umlaut-Bugs behoben** — Alle fehlerhaften DB-Einträge korrigiert (Österreich, Südsteiermark, Grüner Veltliner, Käse & Obst, Edelbrände, Säfte, Heiße Getränke)
- **Hierarchische Kategorien** — 3 Hauptgruppen angelegt: Lebensmittel (10% MwSt), Alkoholische Getränke (20% MwSt), Sonstiges. Bestehende Kategorien darunter verschoben.
- **Regionen 3-stufig** — Land → Region → Lage (z.B. Österreich → Burgenland → Mittelburgenland). Neue: Deutschland (Mosel, Rheingau, Pfalz), Portugal (Douro), Leithaberg, Vulkanland.
- **Rebsorten gruppiert** — Weissweinreben, Rotweinreben, Cuvée/Verschnitt als Elternknoten.
- **Neue Stile** — Edelsüß, Naturwein hinzugefügt.
- **Admin-Seite** — `/admin/settings/taxonomy` mit Baumansicht, 6 Tabs, CRUD (Hinzufügen, Bearbeiten, Löschen).
- **Produkt-Editor** — Hierarchische Breadcrumb-Pills, Baum-Navigation mit collapsible Groups.
- **API** — `/api/v1/taxonomy` (GET tree/flat, POST), `/api/v1/taxonomy/[id]` (GET, PATCH, DELETE mit Depth-Kaskade).

### 2. Jahrgangs-Duplikation für Weine (komplett)
- **Neues DB-Feld** `Product.lineageId` — verknüpft alle Jahrgänge desselben Weins.
- **Neue API** `POST /api/v1/products/[id]/duplicate` — kopiert alle Daten, passt Jahrgang an.
- **UI** — Grüner Button "Neuen Jahrgang anlegen" im Produkt-Editor (nur bei Weinen sichtbar).
- **Getestet** — Duplikation von Blaufränkisch Moric 2021→2022 erfolgreich (alle Daten inkl. Preise übernommen).

### 3. Bugfixes
- `TaxRate`-Modell — Fehlende Tenant-Relation im Prisma-Schema ergänzt.
- `Menu.isArchived` — Nicht-existierendes Feld in menus/route.ts durch `status: { not: 'ARCHIVED' }` ersetzt.
- DB-Spalten manuell per SQL hinzugefügt (lineageId, taxRate, taxLabel) weil `prisma db push` an Theme.config-NULL-Wert scheiterte.

## Neue/geänderte Dateien
- `prisma/schema.prisma` — lineageId auf Product, tenant-Relation auf TaxRate, taxRate/taxLabel auf TaxonomyNode
- `src/app/api/v1/taxonomy/route.ts` — Komplett neu (Tree-Mode, Slug-Generation)
- `src/app/api/v1/taxonomy/[id]/route.ts` — Komplett neu (PATCH mit Depth-Kaskade)
- `src/app/api/v1/products/[id]/duplicate/route.ts` — NEU
- `src/app/api/v1/menus/route.ts` — Bugfix isArchived
- `src/app/admin/settings/taxonomy/page.tsx` — NEU (Server-Component)
- `src/components/admin/taxonomy-manager.tsx` — NEU (Client-Component ~300 Zeilen)
- `src/components/admin/product-editor.tsx` — Jahrgangs-Button + Dialog, hierarchische Taxonomie
- `src/components/admin/icon-bar.tsx` — Klassifizierung-Link in Sidebar
- `src/app/admin/items/[id]/page.tsx` — Erweiterte Taxonomy-Daten für Editor
- `scripts/migrate-taxonomy.sql` — Umlaut-Fixes + Hierarchie-Migration
- `scripts/add-columns.sql` — Manuelle Spalten-Migration

## Nächste Schritte / Offene Punkte
- **taxRate/taxLabel auf Kategorien setzen** — Die DB-Spalten existieren, aber die Werte (10%/20%) sind noch nicht gesetzt (PATCH-API hatte 500 weil Spalten noch nicht existierten, jetzt existieren sie)
- **Seed-Dateien aktualisieren** — seed-v2.ts, seed-wine.sh haben noch alte Umlaut-Fehler (nur Live-DB korrigiert)
- **Prisma db push reparieren** — Theme.config NULL-Problem lösen, damit zukünftige Schema-Pushes sauber durchlaufen
- **Roadmap-DOCX** — War geplant, wurde durch Taxonomie-Überarbeitung verschoben
