# Backlog MenuCard Pro

Aufgeschobene Punkte, die bewusst nicht sofort umgesetzt werden. Jeder Eintrag hat Datum, Grund und Trigger für die spätere Umsetzung.

---

## Sicherheit

### Secrets rotieren (kritisch, Priorität 1)
- **Eingeplant:** 18.04.2026
- **Grund:** `.env.pre-ssl-20260414` lag im Git-Repo `rexei123/menucard-pro` und enthält: `DATABASE_URL` (DB-Passwort), `NEXTAUTH_SECRET`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `PIXABAY_API_KEY`, `GOOGLE_SEARCH_KEY`.
- **Aktueller Zustand:** Repo ist **privat**, Risiko begrenzt. Aber Secrets liegen im Git-Verlauf und wären bei Öffnung oder Zugriffserweiterung exponiert.
- **Trigger für Umsetzung:** Nach Abschluss Phase 0 (Staging läuft), noch vor Phase 1.
- **Schritte:**
  1. Neues DB-Passwort generieren, `.env` auf Server + Staging anpassen, pm2 restart
  2. Neuer `NEXTAUTH_SECRET` (forciert erneute Anmeldung aller Nutzer)
  3. S3-Keys neu generieren (Hetzner Object Storage Konsole)
  4. Pixabay + Google Search Keys rotieren
  5. `git filter-repo` zur Entfernung der Datei aus der History (optional, schützt gegen zukünftige Repo-Öffnung)
- **Aufwand:** ~2 Stunden.

## Infrastruktur

### Sentry für Produktionsfehler
- **Eingeplant:** 18.04.2026
- **Grund für Verschiebung:** Erst nach Phase 3 (Structured Logging). Sentry bringt nur Wert, wenn die Codebasis sauber logged.
- **Trigger für Umsetzung:** Nach Abschluss Phase 3 des Härtungslaufs, oder beim ersten nicht reproduzierbaren Produktionsfehler.
- **Aufwand:** ~2 Stunden (Free-Plan, 5k Events/Monat)
- **Link:** sentry.io/signup

### CX22 → CX32 Upgrade bei Bedarf
- **Eingeplant:** 18.04.2026
- **Grund für Verschiebung:** Aktuelle VM reicht. Upgrade nur, wenn Staging + Produktion + PostgreSQL die VM auslasten.
- **Trigger:** CPU > 80 % oder RAM > 80 % über 7 Tage.
- **Aufwand:** ~30 min (Hetzner Cloud Konsole, ca. 5 €/Monat mehr)

### Sanitized Production-Data-Sync für Staging
- **Eingeplant:** 18.04.2026
- **Grund für Verschiebung:** Start mit Seed-Daten reicht. DSGVO-Sync später, wenn Staging-Test mit Echtdaten gebraucht wird.
- **Trigger:** Erster Bug, der sich nur mit Produktions-Datenstruktur reproduzieren lässt.
- **Aufwand:** ~4 Stunden (Skript mit E-Mail-Maskierung, Passwort-Reset, Preis-Anonymisierung).

---

## Features

### A-5: Echte Produktdaten importieren
- **Eingeplant:** 17.04.2026
- **Grund für Verschiebung:** Benötigt echte Sonnblick-Karten (Speisen, Getränke, Weine) als CSV/Excel.
- **Trigger:** Hotel liefert Karten-Daten.
- **Aufwand:** ~1 Tag (Import-Validierung, Mapping, Verifikation).

### Feature-Flags für risikoreiche Änderungen
- **Eingeplant:** 18.04.2026
- **Grund für Verschiebung:** Aktuell genügt Branch-basiertes Rollout. Feature-Flags erst, wenn wir Änderungen graduell ausrollen müssen.
- **Trigger:** Erstes Feature, das ohne Big-Bang ausrollen soll.
- **Aufwand:** ~1 Tag (Unleash oder self-hosted Flagsmith, oder einfaches DB-Flag).

---

## Code-Qualität

### Jest-Unit-Tests ergänzend zu Playwright
- **Eingeplant:** 18.04.2026
- **Grund für Verschiebung:** Phase 4 konzentriert sich auf E2E-Smoke-Tests (Playwright). Unit-Tests für Utility-Funktionen (format-price, search-suggestions) sind ergänzend sinnvoll.
- **Trigger:** Nach Phase 4, wenn erste Utility-Bugs auftauchen.
- **Aufwand:** ~2 Tage.

### OpenAPI-Schema-Generierung aus zod
- **Eingeplant:** 18.04.2026
- **Grund für Verschiebung:** Erst muss zod flächendeckend im Einsatz sein (Phase 1). Danach lohnt sich die Generierung einer OpenAPI-Doku.
- **Trigger:** Nach Phase 1. Erste externe API-Nutzung (Website-Embed, Headless).
- **Aufwand:** ~1 Tag (`zod-to-openapi` + Swagger-UI-Route).

---

## Tooling

### Lighthouse-CI für Performance-Budget
- **Eingeplant:** 18.04.2026
- **Grund für Verschiebung:** Design und UX sind primär. Perf-Budget wird erst wichtig, wenn wir bundle-optimieren.
- **Trigger:** Wenn LCP-Messung > 3 s auf Mobile.
- **Aufwand:** ~0.5 Tag.

### Renovate für Dependency-Updates
- **Eingeplant:** 18.04.2026
- **Grund für Verschiebung:** Erst nach stabilem CI/CD. Automatische Dependency-PRs brauchen grüne Tests als Gatekeeper.
- **Trigger:** Nach Phase 4.
- **Aufwand:** ~0.5 Tag.

---

## Dieser Backlog wird gelebt

- **Erweitern:** Jedes "machen wir später" landet hier – nicht im Kopf.
- **Prüfen:** Monatlich beim Quality-Gate-Review.
- **Abarbeiten:** Wenn Trigger erreicht wird.
