# Changelog

Alle nennenswerten Änderungen an MenuCard Pro werden in dieser Datei dokumentiert.
Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.0.0/), die Versionierung folgt [Semantic Versioning](https://semver.org/lang/de/).

## [1.0.0] — 2026-04-14 — Stabiler Meilenstein

Erster öffentlich stabiler Release, live unter `https://menu.hotel-sonnblick.at`. Git-Tag `v1.0-stabil`.

### Hinzugefügt
- **Dokumentation:** CLAUDE.md, README.md, CHANGELOG.md, docs/API.md, docs/DATENMODELL.md, docs/DEPLOYMENT.md vollständig neu aufgesetzt.
- **Test-Infrastruktur:** Playwright-Script v4 mit 22 Check-Points (9 Admin-Screens, 4 Editoren, 9 Gäste-Karten).

### Geändert
- **Inventar:** Vollsicherung mit DB-Dump, Config-Archiv, Prisma-Schema-Snapshot, Git-Tag.
- **Security:** GitHub-Token aus Git-Remote-URL entfernt; Credential-Helper empfohlen.

### Gefixt
- **Gäste-Ansicht B-1 bis B-8:** Umlaut-Darstellung, Preis-Lokalisierung (de-AT Komma, en-GB Punkt), Rosé-Sonderzeichen, Volltextsuche inkl. Sektions-Name, sticky Nav Scroll-Verhalten, Plural-Logik für "Karten/Menus".

## [0.9.0] — 2026-04-14 — SSL & Domain

### Hinzugefügt
- **SSL/TLS:** Let's Encrypt-Zertifikat für `menu.hotel-sonnblick.at` mit automatischer Erneuerung.
- **DNS:** A-Record auf Hetzner-IP.
- **Nginx:** HTTPS-Redirect, HSTS.

## [0.8.0] — 2026-04-13 — UI-Redesign Phase 4

### Hinzugefügt
- **Phase 4a:** Template-Auswahl mit Vergleichstabelle und Aktiv-Badges.
- **Phase 4b:** Einstellungen-Seite mit Sub-Navigation (allergens, languages, theme, users), Toggles und System-Status.
- **Phase 4c:** Bildarchiv-Token-Patch (Blau → Rosa), QR-Code-Seite komplett neu gestaltet.

## [0.7.0] — 2026-04-12 — UI-Redesign Phase 3 (Templates)

### Hinzugefügt
- **Phase 3a:** Elegant-Template Gäste-Renderer (`classic-renderer.tsx`).
- **Phase 3b:** Minimal-Template Renderer.
- **Phase 3c:** Modern-Template mit Card-Layout, Highlight-Badges und 2-Spalten-Grid.
- **Phase 3d:** Classic-Template mit Fine-Dining-Nummerierung, Playfair Display und dekorativen Sektions-Headern.

### Geändert
- **Emojis:** Durchgängig durch Material Symbols ersetzt.

## [0.6.0] — 2026-04-11 — UI-Redesign Phase 1+2

### Hinzugefügt
- **Phase 1+2:** Design-Token-System und Admin-Sidebar.
- **Phase 2b:** Dashboard mit KPI-Kacheln und Schnellzugriff.

## [0.5.0] — 2026-04-10 — Bildarchiv

### Hinzugefügt
- **Phase 1-3:** Upload, Galerie, Websuche über SearXNG.
- **Phase 4+5:** MediaPicker-Dialog, Crop-Editor, Product-Media-API.
- **Sharp-Pipeline:** WebP-Konvertierung, 3 Größen (thumb/medium/large), EXIF-Rotation.

## [0.4.0] — 2026-04-08 — PDF-Export v2

### Hinzugefügt
- **Design-Editor:** 7 Akkordeons, Live-Vorschau (Digital-Tab + PDF-Tab).
- **PDF-Creator:** Eigene Admin-Seite `/admin/pdf-creator`.
- **Custom-Templates:** SYSTEM/CUSTOM-Unterscheidung, Duplicate-Funktion, Archivierung.
- **PDF-Engine:** `@react-pdf/renderer` mit `lib/pdf/menu-pdf.tsx` und eigenen Fonts.

## [0.3.0] — 2026-04-06 — Design-Editor-Verfeinerungen

### Hinzugefügt
- **Reset-Button** mit Bestätigungsdialog.
- **Benutzerdefinierte Vorlage** automatisch erkannt bei Overrides.

### Gefixt
- **Design-API:** Response-Feld heißt `designConfig` (nicht `mergedConfig`).
- **PATCH-Payload:** `{ designConfig: { digital: {...} } }` (Wrapper korrigiert).

## [0.2.0] — 2026-04-05 — Security-Hardening

### Hinzugefügt
- **Nginx:** Block-Regeln für `.git`, `.env`, `prisma`, `.bak`, `.sh`, `.sql`, `.log`, `node_modules`.
- **Security-Header:** `X-Frame-Options`, `X-Content-Type-Options`, `X-XSS-Protection`, `Referrer-Policy`.
- **Rate-Limiting:** 10r/s API, 3r/s Login.
- **`poweredByHeader: false`** in Next.js-Config.
- **`.gitignore`:** Erweitert um `.env*`, `*.bak`, `*.sql`, `*.log`.

## [0.1.0] — 2026-04-04 — CSV-Import & Bilder in Gäste-Ansicht

### Hinzugefügt
- **CSV-Import:** Vorschau-Tabelle, Inline-Editierung, Re-Validierung vor Import.
- **Automatische Erstellung** fehlender Produktgruppen und Füllmengen beim Import.
- **Produktbilder** in der öffentlichen Gäste-Ansicht.
- **Schema-Cleanup:** Konsolidierung der Translation-Tabellen.

## [0.0.x] — MVP — Admin-Grundgerüst und Gäste-Ansicht

Initiale Versionen mit Icon-Bar + List-Panel + Workspace, Produkt-Editor, Menu-Editor, QR-Code-Generator, Auto-Translate, Mehrsprachigkeit (DE/EN), öffentliche Kartenansicht, NextAuth-Login und Rollenmodell.

---

## Vorbereitet, aber noch nicht freigegeben

- Bestellfunktion (Datenmodell vorhanden, UI fehlt)
- Reservierungs-CTA
- Bestandsverwaltung (Mindestbestand, automatischer Sold-Out)
- Happy-Hour- und Saisonkarten-Logik
- Eventkarten (Hochzeiten, Seminare)
- Zimmermappe / In-Room-Dining
- Weinlexikon / Glossar
- Analytics v2 (Heatmaps, Conversion-Events)
- POS-Anbindung
- KI-Empfehlungen (Pairings)
- Embed-Widget / iFrame
- Dark Mode
- SSH-Key-only Login
