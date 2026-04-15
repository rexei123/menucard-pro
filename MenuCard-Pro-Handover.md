# MenuCard Pro – Projektzusammenfassung
## Stand: 10.04.2026

---

## PROJEKT
- **Name:** MenuCard Pro
- **Zweck:** Digitale Speise-, Getränke- und Weinkarten für Hotel Sonnblick, Saalbach
- **Stack:** Next.js 14, TypeScript, Tailwind CSS, Prisma, PostgreSQL, NextAuth, PM2, Nginx
- **GitHub:** https://github.com/rexei123/menucard-pro (public)

---

## SERVER
- **IP:** 178.104.138.177
- **SSH:** `ssh root@178.104.138.177`
- **App:** `/var/www/menucard-pro`
- **DB:** `psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"`
- **Admin:** admin@hotel-sonnblick.at / Sonnblick2026!
- **PM2:** `pm2 restart menucard-pro`
- **Build:** `npm run build && pm2 restart menucard-pro`
- **Nginx:** Reverse proxy → localhost:3000, `client_max_body_size 10M`
- **Desktop erich-PC:** `C:\Users\erich\Desktop`
- **Desktop User-PC (Firma):** `C:\Users\User\OneDrive\Desktop`

---

## DEPLOYMENT-WORKFLOW
1. Datei in Claude erstellen → Download
2. PowerShell 1 (lokal): `scp C:\Users\User\OneDrive\Desktop\DATEI root@178.104.138.177:/var/www/menucard-pro/`
3. PowerShell 2 (SSH): `cd /var/www/menucard-pro && bash DATEI.sh` oder `psql ... -f DATEI.sql`
4. UTF-8 mit echten Umlauten – kein ASCII-Workaround nötig

---

## DATEN
- **9 Karten:** 7 Gourmet-Menüs (EVENT), 1 Weinkarte (WINE), 1 Barkarte (BAR)
- **322 Produkte** (zentrale Produktdatenbank)
- **640 Übersetzungen** (DE + EN)
- **298 Preise** (mit Füllmengen + Preisebenen + EK/Fix/%)
- **91 Weinprofile**, 139 Getränkedetails
- **337 Kartenzuordnungen** (MenuPlacement)
- **27 Produktgruppen** (hierarchisch)
- **4 Preisebenen**, **18 Füllmengen**, **2 Steuersätze**, **9 QR-Codes**

---

## ERLEDIGTE FEATURES

### Gästeansicht (Public)
- ✅ Kartenansicht mit Sektionen, Produkten, Preisen
- ✅ Artikeldetail-Seite (alle Produkte klickbar)
- ✅ Volltextsuche + Filter (Weinstil, Land)
- ✅ Sprachwechsler DE/EN, QR-Code Redirect
- ✅ Mobile-Optimierung (next/font, Skeleton-Loading, PWA-Meta)
- ✅ Frontend liest von Product/MenuPlacement
- ✅ Ausgetrunken-Anzeige (isVisible=false → Sold Out in Gästekarte)

### Admin
- ✅ **Neues Layout:** Icon-Bar (aufklappbar, Default offen) + List-Panel (resizable) + Workspace
- ✅ Dashboard mit Stats (Karten, Artikel, QR-Codes)
- ✅ QR-Code-Verwaltung
- ✅ **Produktliste:** Suche, Filter (Typ/Gruppe/Status), Kartennamen angezeigt
- ✅ **Neues Produkt anlegen** (+ Artikel Button, Auto-SKU)
- ✅ **Produkt-Editor:**
  - Status, Typ, Produktgruppe, Highlight
  - Übersetzungen DE + EN mit Auto-Translate (MyMemory API, Farbstatus grau/orange/grün)
  - Preise & Kalkulation (EK → +Fix€ → ×Aufschlag% → =VK, Marge farbcodiert ≥65% grün/≥50% gelb/<50% rot)
  - Weinprofil, Getränkedetail editierbar
  - Rezeptur / Interne Notizen
  - **Bilder-Upload:** Drag & Drop + Datei-Dialog, Sharp-Optimierung (WebP, 3 Größen), Kategorien (LABEL/BOTTLE/SERVING/AMBIANCE), Hauptbild-Markierung
  - Kartenplatzierungen (read-only)
  - Sticky Save Bar, Unsaved-Changes Guard
  - Produkt löschen mit Doppelbestätigung
- ✅ **Kartenverwaltung:**
  - List-Panel mit Suche
  - Karten-Editor mit Drag & Drop Produkte zuordnen/entfernen
  - Produktpool rechts (zeigt nur nicht-zugeordnete Produkte) mit Filter (Typ/Gruppe/Status)
  - Visuelle Lücken-Animation beim Drag
  - Ausgetrunken-Toggle (grüner Punkt → 🚫) mit Übertragung in Gästekarte
  - ✕ Entfernen (ein Klick)
- ✅ **Logout-Button** + **Neu laden Button** (für Entwicklungsphase)
- ✅ APIs: Products CRUD, Translate, Placements CRUD, Media Upload/Delete/Patch, QR-Codes

### Infrastruktur
- ✅ Nginx Reverse Proxy (client_max_body_size 10M)
- ✅ Zentrale Produktdatenbank (20 Tabellen)
- ✅ Sharp Bildverarbeitung (WebP, EXIF-Strip, 3 Größen: thumb/medium/large)
- ✅ Umlaute komplett gefixt
- ✅ Schriftgrößen standardisiert (alle 2 Stufen hoch)

---

## AKTUELL OFFENER FIX

**Alte MenuItem-Tabellen:** Cleanup-Script wurde gestartet, Tabellen aus DB gedroppt, aber Prisma-Schema hat noch 2 Fehler:
1. Doppelte `productMedia` Zeile in Model `Media`
2. `Inventory` Model referenziert noch `MenuItem`

**Fix-Befehl der noch ausgeführt werden muss:**
```bash
cd /var/www/menucard-pro; python3 -c "
c = open('prisma/schema.prisma').read()
c = c.replace('  productMedia ProductMedia[]\n  productMedia     ProductMedia[]', '  productMedia ProductMedia[]')
import re
c = re.sub(r'\nmodel Inventory \{[^}]+\}\n', '\n', c)
c = re.sub(r'\n{3,}', '\n\n', c)
open('prisma/schema.prisma', 'w').write(c)
print('Fixed')
"; npx prisma db push --accept-data-loss; npm run build; pm2 restart menucard-pro
```

---

## DATENBANKARCHITEKTUR (AKTUELL)

### Zentrale Produktdatenbank
```
Product (322 Produkte)
├── ProductTranslation (DE+EN)
├── ProductPrice (Füllmenge × Preisebene, mit EK/Fix/%)
├── ProductWineProfile
├── ProductBeverageDetail
├── ProductAllergen, ProductTag
├── ProductMedia (Sharp: WebP, thumb/medium/large)
├── ProductCustomFieldValue
└── MenuPlacement (Zuordnung zu Karten mit isVisible/sortOrder)

ProductGroup (27, hierarchisch)
PriceLevel (4): Restaurant, Bar, Room Service, Einkauf
FillQuantity (18): Flasche 0,75l, 1/8 offen, etc.
TaxRate (2): Getränke 20%, Speisen 10%
```

### Alte Tabellen (ENTFERNT aus DB, Schema-Fix noch ausstehend)
MenuItem, MenuItemTranslation, PriceVariant, WineProfile, BeverageDetail, Pairing
MenuItemAllergen, MenuItemAdditive, MenuItemTag, MenuItemMedia

---

## NÄCHSTE SCHRITTE

### Sofort (offener Fix)
- Schema-Bereinigung abschließen (siehe Fix-Befehl oben)

### Priorität 1
- PDF-Export v2 (Layout-Tool mit Template-Auswahl)
- QR-Codes auf neues Layout (List-Panel + Workspace)

### Priorität 2
- Massenänderungen (Global/Gruppe/Produkt)
- Bilder in Gästekarte anzeigen
- Bilder in Produktliste als Thumbnail

### Priorität 3
- T-036 Dark Mode
- T-045 CSV-Import
- T-049 Theme-Editor
- T-055 Sold-Out Toggle
- Domain menu.hotel-sonnblick.at + SSL

---

## BACKUPS
- `/root/menucard-pre-cleanup-20260410.sql` (vor Tabellen-Cleanup)
- `/root/menucard-backup-20260410.sql`
- `/root/menucard-backup-20260409.sql`
- `/root/menucard-pre-products.sql`
- GitHub: main branch

---

## TECHNISCHE DETAILS & LEARNINGS
- `next.config.mjs` (nicht .ts)
- NextAuth Route bei `/api/auth/[...nextauth]/`
- TypeScript `Set` iteration: `Array.from(new Set(...))` statt `[...new Set(...)]`
- PowerShell `&&` funktioniert nicht → Semikolon `;` verwenden
- Bash `!` in Strings: einfache Anführungszeichen oder `\!`
- `sharp` für Bildverarbeitung: `.rotate()` für Auto-EXIF, `.webp()` für Konvertierung
- Nginx `client_max_body_size 10M` in `/etc/nginx/conf.d/upload.conf`
- Drag & Drop: `useRef` für State im Drop-Handler (useState ist veraltet in Closures)
- `.next` Cache löschen bei hartnäckigen Problemen: `rm -rf .next`
- MyMemory Translation API: `https://api.mymemory.translated.net/get?q=...&langpair=de|en`

---

## STARTBEFEHL FÜR NEUEN CHAT
```
Weiter mit MenuCard Pro – Hotel Sonnblick.
Server: 178.104.138.177, SSH root, /var/www/menucard-pro
GitHub: rexei123/menucard-pro (public)
DB: psql "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"
Admin: admin@hotel-sonnblick.at / Sonnblick2026!
Status: 322 Produkte, 9 Karten, Admin mit neuem Layout (Icon-Bar + List-Panel + Workspace),
Produkt-Editor mit Auto-Translate, Preiskalkulation, Bilder-Upload (Sharp/WebP) live.
Kartenverwaltung mit Drag&Drop, Produktpool, Ausgetrunken-Toggle.
OFFENER FIX: Prisma-Schema Cleanup (doppelte productMedia Zeile + Inventory Model entfernen).
Nächster Schritt: Schema-Fix, dann PDF-Export v2.
Desktop-Pfad: C:\Users\User\OneDrive\Desktop (Firma), C:\Users\erich\Desktop (Home)
```
