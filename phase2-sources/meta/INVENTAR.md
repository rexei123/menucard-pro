# MenuCard Pro — Inventar

**Stichtag:** 2026-04-14 15:28:21
**Git-HEAD:** 410ecdf (main)
**Git-Remote:** https://github.com/rexei123/menucard-pro.git
**Tag:** v1.0-stabil
**Sicherungen in:** `/root/backups-20260414`

---

## Laufzeit-Umgebung

| Komponente | Version |
|---|---|
| Node.js | v22.22.2 |
| npm | 10.9.7 |
| Next.js | 14.2.21 |
| Prisma | ^5.22.0 |

## Datenbank-Zählerstände (40 Tabellen)

| Tabelle | Anzahl |
|---|---|

| Additive | 0 |
| AdditiveTranslation | 0 |
| Allergen | 0 |
| AllergenTranslation | 0 |
| AnalyticsEvent | 0 |
| CustomFieldDefinition | 0 |
| CustomFieldTranslation | 0 |
| DesignTemplate | 5 |
| FillQuantity | 18 |
| Location | 2 |
| LocationTranslation | 4 |
| Media | 3 |
| Menu | 9 |
| MenuPlacement | 337 |
| MenuSection | 65 |
| MenuSectionTranslation | 130 |
| MenuTranslation | 18 |
| PriceLevel | 4 |
| Product | 322 |
| ProductAllergen | 0 |
| ProductBeverageDetail | 137 |
| ProductCustomFieldValue | 0 |
| ProductGroup | 27 |
| ProductGroupTranslation | 54 |
| ProductMedia | 3 |
| ProductPairing | 0 |
| ProductPrice | 298 |
| ProductTag | 32 |
| ProductTranslation | 644 |
| ProductWineProfile | 91 |
| QRCode | 10 |
| Supplier | 0 |
| Tag | 6 |
| TagTranslation | 12 |
| TaxRate | 2 |
| Tenant | 1 |
| TenantLanguage | 2 |
| Theme | 1 |
| TimeRule | 0 |
| User | 1 |

## Backup-Artefakte

| Datei | Größe |
|---|---|
| admin-pages-20260414.txt | 316 |
| api-routes-20260414.txt | 637 |
| config-20260414.tar.gz | 1.9K |
| db-counts-20260414.txt | 1.6K |
| deps-20260414.json | 1.3K |
| menucard-db-20260414.sql | 434K |
| package-20260414.json | 1.4K |
| pm2-dump-20260414.pm2 | 6.8K |
| schema-20260414.prisma | 21K |
| tree-20260414.txt | 4.0K |

## Dependencies

- Laufzeit-Packages: **17**
- Dev-Packages: **14**
- Volle Liste: `deps-20260414.json`

## Code-Struktur

- API-Routen: 27
- Admin-Seiten: 18
- Source-Baum: `tree-20260414.txt`

## API-Routen (vollständig)

```
/api/auth/[...nextauth]
/api/v1/design-templates
/api/v1/design-templates/[id]
/api/v1/design-templates/[id]/duplicate
/api/v1/design-templates/[id]/restore
/api/v1/import
/api/v1/media
/api/v1/media/[id]
/api/v1/media/[id]/crop
/api/v1/media/migrate
/api/v1/media/upload
/api/v1/media/web-import
/api/v1/media/web-search
/api/v1/menus
/api/v1/menus/[id]/pdf
/api/v1/menus/[id]/template
/api/v1/pdf
/api/v1/placements
/api/v1/placements/[id]
/api/v1/products
/api/v1/products/[id]
/api/v1/products/[id]/media
/api/v1/products/[id]/media/[productMediaId]
/api/v1/qr-codes
/api/v1/qr-codes/generate
/api/v1/qr-codes/[id]
/api/v1/translate
```

## Admin-Seiten (vollständig)

```
/admin
/admin/analytics
/admin/design
/admin/design/[id]/edit
/admin/import
/admin/items
/admin/items/[id]
/admin/media
/admin/media/[id]
/admin/menus
/admin/menus/[id]
/admin/pdf-creator
/admin/qr-codes
/admin/settings
/admin/settings/allergens
/admin/settings/languages
/admin/settings/theme
/admin/settings/users
```

## Git-Status

```
410ecdf chore: pre-reorganisation snapshot 2026-04-14
38c609c UI-Redesign Phase 4c: Bildarchiv Token-Patch (Blau→Rosa) und QR-Code Seite komplett neu gestaltet
8f4a54d UI-Redesign Phase 4b: Einstellungen-Seite mit Sub-Navigation, Toggles und System-Status
da078d3 UI-Redesign Phase 4a: Template-Auswahl Seite mit Vergleichstabelle und Aktiv-Badges
e8f1128 UI-Redesign Phase 3d: Classic Template mit Fine-Dining Nummerierung, Playfair Display und dekorativen Sektions-Headern
ad520a1 UI-Redesign Phase 3c: Modern Template mit Card-Layout, Highlight-Badges und 2-Spalten Grid
e32aaf3 feat: UI-Redesign Phase 3b – Minimal Gästeansicht-Template
6a8bed9 feat: UI-Redesign Phase 3a – Elegant Gästeansicht-Template
bda96f0 refactor: Alle Emojis durch Material Symbols ersetzt
c9e15c1 feat: UI-Redesign Phase 2b – Dashboard mit KPI-Kacheln und Schnellzugriff
```

---

## Status der Absicherung

- [x] PostgreSQL-Dump: `menucard-db-20260414.sql` (436K)
- [x] Config-Archiv: `config-20260414.tar.gz` (4.0K)
- [x] Prisma-Schema: `schema-20260414.prisma`
- [x] PM2-Dump: `pm2-dump-20260414.pm2`
- [x] Dependencies-Snapshot: `deps-20260414.json`
- [x] DB-Zählerstände: `db-counts-20260414.txt`
- [x] API-Routen + Admin-Seiten Listing
- [x] Git-Commit + Tag `v1.0-stabil` + Push zu GitHub

