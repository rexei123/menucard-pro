---
name: menucard-pro
description: "MenuCard Pro – das digitale Menükarten-System für Hotel Sonnblick. Verwende diesen Skill bei JEDER Aufgabe, die mit MenuCard Pro zu tun hat: Deployment, Server-Wartung, neue Features, Bugfixes, Datenbankänderungen, Script-Erstellung, CSV-Import, Prisma-Schema, Bildverarbeitung, oder allgemeine Projektfragen. Auch wenn der Benutzer nur 'Server', 'Deploy', 'Script', 'Datenbank', 'Karten', 'Produkte', 'Import' oder ähnliches sagt – dieser Skill ist gemeint."
---

# MenuCard Pro – Projekt-Skill

Digitale Speise-, Getränke- und Weinkarten per QR-Code für Hotel Sonnblick, Saalbach (Österreich).

## Stack

- **Frontend/Backend:** Next.js 14 (App Router), TypeScript, Tailwind CSS
- **Datenbank:** PostgreSQL mit Prisma ORM
- **Auth:** NextAuth.js
- **Bildverarbeitung:** Sharp (WebP: thumb 200x200, medium 600xN, large 1011xN)
- **Prozessmanager:** PM2 (`menucard-pro`)
- **Reverse Proxy:** Nginx
- **Server:** Hetzner CX22, IP `178.104.138.177`
- **GitHub:** `rexei123/menucard-pro` (public)

## Server-Pfade

| Was | Pfad |
|---|---|
| App-Verzeichnis | `/var/www/menucard-pro` |
| Uploads | `/var/www/menucard-pro/public/uploads/{large,medium,thumb}/` |
| PM2 Logs | `pm2 logs menucard-pro --lines 50` |
| DB-Backups | `/root/menucard-backup-*.sql` |
| Seed-Archiv | `/root/seed-archive/` |

## Deployment-Workflow

Der Benutzer arbeitet auf Windows (PowerShell). Der typische Ablauf:

1. **Script schreiben** – Datei im Cowork-Projektordner erstellen (`.sh`)
2. **Hochladen** – per `scp` zum Server
3. **Ausführen** – per SSH auf dem Server `bash /root/scriptname.sh`

### Wichtige Konventionen für Scripts

- Immer `#!/bin/bash` und `set -e` am Anfang
- Immer `cd /var/www/menucard-pro` als erstes
- Am Ende: `npm run build 2>&1 | tail -5` und `pm2 restart menucard-pro`
- Für Schema-Änderungen: `npx prisma db push` (nicht migrate)
- Python-Inline statt Heredoc für komplexe Dateimanipulationen (Heredoc macht auf dem Server Probleme)
- UTF-8 mit echten Umlauten – kein ASCII-Workaround nötig

### scp-Pfade des Benutzers

Der Benutzer hat zwei PCs:
- **Firma:** `C:\Users\User\OneDrive\Desktop\`
- **Home (erich):** `C:\Users\erich\Documents\Claude\Projects\Menucard Pro\`

Der Home-Pfad ist der bevorzugte Cowork-Projektordner. Achtung: Windows zeigt "Dokumente" an, der Pfad ist aber `Documents`.

### PowerShell-Besonderheiten

- `&&` funktioniert nicht in PowerShell → Semikolon `;` verwenden
- Pfade mit Leerzeichen in Anführungszeichen: `"Menucard Pro\script.sh"`

### Typischer scp-Befehl (Home)

```powershell
scp "C:\Users\erich\Documents\Claude\Projects\Menucard Pro\script-name.sh" root@178.104.138.177:/root/
```

## Datenarchitektur

Das zentrale Modell ist **Product** (nicht MenuItem – das alte Modell wurde entfernt).

### Wichtige Modelle

- **Product** – Zentrales Produkt (type: WINE, DRINK, FOOD)
- **ProductTranslation** – Name, Beschreibungen (DE/EN)
- **ProductPrice** – Preise mit FillQuantity + PriceLevel (Prisma connect-Syntax!)
- **ProductWineProfile** – Weindaten (Weingut, Jahrgang, Rebsorte, etc.)
- **ProductBeverageDetail** – Getränkedaten (Marke, Kategorie, Alkohol, etc.)
- **ProductMedia** – Bilder (isPrimary, sortOrder)
- **MenuPlacement** – Verknüpft Product mit MenuSection (mit sortOrder, soldOut-Toggle)
- **Menu** – Karte mit Sections, QR-Codes
- **ProductGroup** – Produktgruppen mit Übersetzungen

### Enum-Werte (wichtig für Import/API)

- **ProductType:** WINE, DRINK, FOOD
- **BeverageCategory:** BEER, SPIRIT, COCKTAIL, SOFT_DRINK, JUICE, WATER, HOT_DRINK, SMOOTHIE, OTHER
- **WineStyle:** RED, WHITE, ROSE, SPARKLING, DESSERT, FORTIFIED, ORANGE, NATURAL
- **Body:** LIGHT, MEDIUM_LIGHT, MEDIUM, MEDIUM_FULL, FULL
- **Sweetness:** BONE_DRY, DRY, OFF_DRY, MEDIUM_DRY, MEDIUM_SWEET, SWEET, VERY_SWEET

### Prisma-Besonderheiten

- Bei Relationen immer `connect`-Syntax verwenden: `fillQuantity: { connect: { id: fqId } }` statt `fillQuantityId: fqId`
- `Array.from(map.entries())` statt direkte Map-Iteration (TypeScript downlevelIteration)
- Schema-Änderungen: `npx prisma db push` (kein migrate in Production)

## Admin-Credentials

- **URL:** `http://178.104.138.177:3000/admin` (oder via Nginx)
- **Login:** `admin@hotel-sonnblick.at` / `Sonnblick2026!`
- **DB:** `postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro`

## Aktueller Stand (April 2026)

- 322+ Produkte, 9 Karten (7 Gourmet-Menüs, 1 Weinkarte, 1 Barkarte)
- Admin: Icon-Bar + List-Panel + Workspace Layout
- Features: Produkt-Editor, Auto-Translate DE/EN, Preiskalkulation, Bilder-Upload, Kartenverwaltung mit Drag&Drop, CSV-Import
- Gästeansicht: Kartenansicht mit Thumbnails, Artikeldetail mit Bildern, Volltextsuche, Filter, Sprachwechsler, Sold-Out

## Kommunikation

- Sprache: Deutsch, Sie-Form
- Professionell aber einladend (Hotelbranche)
- Antworten kurz und effizient halten
- Immer aus Sicht des Hotels kommunizieren
