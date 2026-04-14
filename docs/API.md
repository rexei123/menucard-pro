# API-Dokumentation

Alle API-Endpunkte unter `/api/v1/*` benötigen eine gültige NextAuth-Session (Ausnahme: NextAuth selbst). Session-Cookie wird vom Login auf `/auth/login` gesetzt.

**Basis-URL (Produktion):** `https://menu.hotel-sonnblick.at/api/v1`
**Content-Type:** `application/json` (außer Upload: `multipart/form-data`)
**Authentifizierung:** Session-Cookie (HTTP-Only), JWT-basiert, 24 h Gültigkeit
**Rate-Limiting (Nginx):** 10 req/s auf `/api/*`, 3 req/s auf `/api/auth/*`

## Fehlerschema

```json
{ "error": "Beschreibung des Fehlers" }
```

Typische Status-Codes: `200 OK`, `201 Created`, `400 Bad Request`, `401 Unauthorized`, `404 Not Found`, `409 Conflict`, `500 Internal Server Error`.

---

## Auth

### `POST /api/auth/callback/credentials`
NextAuth-Login (intern aufgerufen vom `/auth/login`-Formular).
**Body (form-encoded):** `email`, `password`, `csrfToken`, `callbackUrl`
**Success:** 302 → `callbackUrl` mit Session-Cookie.

### `GET /api/auth/session`
Aktuelle Session.
**Response:** `{ user: { id, email, firstName, lastName, role, tenantId, tenantSlug } }` oder `{}`.

### `POST /api/auth/signout`
Logout.

---

## Produkte

### `POST /api/v1/products`
Neues Produkt anlegen. SKU wird automatisch vergeben (`SB-XXXX`).
**Body:** `{ type: "WINE"|"DRINK"|"FOOD"|"OTHER", name?, nameEn? }`
**Response:** `{ id, sku }` (201)

### `PATCH /api/v1/products/[id]`
Produkt aktualisieren. Komplexer Body mit verschachtelten Feldern.
**Body:**
```json
{
  "status": "ACTIVE"|"SOLD_OUT"|"ARCHIVED"|"DRAFT",
  "productGroupId": "...",
  "taxRateId": "...",
  "supplierId": "...",
  "isHighlight": false,
  "highlightType": "RECOMMENDATION"|"NEW"|"POPULAR"|"PREMIUM"|"SEASONAL"|"CHEFS_CHOICE",
  "sortOrder": 0,
  "internalNotes": "...",
  "translations": [
    { "languageCode": "de", "name": "...", "shortDescription": "...", "longDescription": "...", "servingSuggestion": "..." }
  ],
  "prices": [
    { "fillQuantityId": "...", "priceLevelId": "...", "price": 12.50, "purchasePrice": 8.00, "fixedMarkup": 2.00, "percentMarkup": 25, "isDefault": true }
  ],
  "wineProfile": { "winery": "...", "vintage": 2021, "grapeVarieties": ["Grüner Veltliner"], "region": "...", "country": "...", "style": "WHITE", "body": "MEDIUM", "sweetness": "DRY", "bottleSize": "0.75l", "alcoholContent": 12.5, "tastingNotes": "...", "foodPairing": "..." },
  "beverageDetail": { "brand": "...", "producer": "...", "category": "BEER", "alcoholContent": 5.0, "servingTemp": "6-8°C", "carbonated": true }
}
```

### `DELETE /api/v1/products/[id]`
Produkt löschen. Kaskadiert Translations, Prices, Placements, Media.

### `GET /api/v1/products/[id]/media`
Alle Medien eines Produkts.

### `POST /api/v1/products/[id]/media`
Medien-Zuordnung anlegen. Body: `{ mediaId, mediaType, isPrimary, sortOrder }`

### `PATCH /api/v1/products/[id]/media/[productMediaId]`
Produkt-Medien-Zuordnung aktualisieren (isPrimary-Flag, sortOrder).

### `DELETE /api/v1/products/[id]/media/[productMediaId]`
Produkt-Medien-Zuordnung entfernen (Media selbst bleibt).

---

## Karten (Menus)

### `GET /api/v1/menus`
Alle aktiven Karten (nicht archiviert) des eigenen Tenants.
**Response:** Array mit `{ id, slug, name, menuType, templateId, template, isActive }`

### `GET /api/v1/menus/[id]/pdf`
PDF einer Karte generieren. Via `@react-pdf/renderer` serverseitig.
**Response:** `application/pdf` mit `Content-Disposition: attachment; filename="..."`

### `GET /api/v1/menus/[id]/template`
Aktuell zugewiesenes Design-Template einer Karte.
**Response:** `{ template: {...}, templateId: "..." }`

### `PATCH /api/v1/menus/[id]/template`
Karte ein anderes Template zuweisen.
**Body:** `{ templateId: "..." }`
**Fehler:** 400 wenn Template archiviert, 404 wenn nicht gefunden.

---

## Platzierungen (Zuordnung Produkt → Kartensektion)

### `POST /api/v1/placements`
Produkt einer Sektion zuordnen.
**Body:** `{ menuSectionId, productId, sortOrder? }`
**Fehler:** 409 bei Duplikat.

### `PATCH /api/v1/placements/[id]`
Platzierung aktualisieren (Sichtbarkeit, Sortierung, Preis-Override, Highlight).
**Body:** `{ isVisible?, sortOrder?, priceOverride?, highlightType?, notes? }`

### `DELETE /api/v1/placements/[id]`
Platzierung entfernen.

---

## QR-Codes

### `GET /api/v1/qr-codes`
Alle QR-Codes des Tenants. Inkl. Location und Menu.

### `POST /api/v1/qr-codes`
Neuen QR-Code anlegen.
**Body:** `{ locationId, menuId?, label?, primaryColor?, bgColor?, shortCode? }`
**Verhalten:** shortCode wird auto-generiert (8–10 Zeichen), bei Kollision 10 Zeichen.

### `PATCH /api/v1/qr-codes/[id]`
Label, Farben oder Logo aktualisieren.

### `DELETE /api/v1/qr-codes/[id]`
QR-Code löschen.

### `GET /api/v1/qr-codes/generate?url=...&primaryColor=...&bgColor=...`
PNG/SVG-Rendering eines QR-Codes (ohne DB-Eintrag).
**Response:** `image/png`

---

## Design-Templates

### `GET /api/v1/design-templates?includeArchived=false`
Alle Templates des Tenants. Mit Zähler der zugewiesenen Menus.

### `POST /api/v1/design-templates`
Neues CUSTOM-Template anlegen. Max. 6 aktive CUSTOM gleichzeitig.
**Body:** `{ name, baseType: "elegant"|"modern"|"classic"|"minimal", config?: {...} }`

### `GET /api/v1/design-templates/[id]`
Einzelnes Template mit voller Config.

### `PATCH /api/v1/design-templates/[id]`
Template-Konfiguration aktualisieren. SYSTEM-Templates nicht editierbar.

### `DELETE /api/v1/design-templates/[id]`
Template archivieren (soft delete). SYSTEM-Templates nicht löschbar.

### `POST /api/v1/design-templates/[id]/duplicate`
Template duplizieren (auch SYSTEM → erzeugt CUSTOM-Kopie).
**Body:** `{ name }`

### `POST /api/v1/design-templates/[id]/restore`
Archiviertes Template wiederherstellen.

---

## Medien

### `GET /api/v1/media?category=...&type=...&orientation=...&assigned=...&q=...&page=1&limit=24&sort=newest`
Gefilterte Medien-Liste mit Pagination.
**Query-Parameter:**
- `category`: PHOTO | LOGO | DOCUMENT
- `type`: image | document
- `orientation`: portrait | landscape | square
- `assigned`: true | false (zu Produkt zugeordnet?)
- `q`: Volltextsuche (title, originalName, alt)
- `sort`: newest | oldest | name

### `POST /api/v1/media/upload`
Bild hochladen. Multipart-Form.
**Form:** `file` (max. 4 MB, JPEG/PNG/WebP/GIF), `productId?`, `mediaType?`, `category?`, `title?`
**Verhalten:** Sharp konvertiert zu WebP, erzeugt 3 Größen (thumb 300px, medium 800px, large 1600px), EXIF-Rotation automatisch.

### `GET /api/v1/media/[id]`
Einzelnes Medienobjekt.

### `PATCH /api/v1/media/[id]`
Metadaten aktualisieren (title, alt, category).

### `DELETE /api/v1/media/[id]`
Löscht DB-Eintrag und Dateien. Fehler, wenn noch zugeordnet.

### `PATCH /api/v1/media/[id]/crop`
Bild zuschneiden. Body: `{ x, y, width, height }` in Pixeln.

### `POST /api/v1/media/migrate`
Bestehende Bilder durch Sharp-Pipeline migrieren (Admin-only).

### `GET /api/v1/media/web-search?q=...`
SearXNG-Proxy für Bildsuche.

### `POST /api/v1/media/web-import`
Web-Bild importieren und durch Sharp-Pipeline leiten.
**Body:** `{ url, title?, category? }`

---

## Import

### `POST /api/v1/import`
CSV-Massenimport für Produkte inkl. Preise, Weinprofile und Getränkedetails.
**Body (JSON):** `{ csvData: "...", mode: "preview"|"commit", overrides?: [...] }`
**Verhalten:**
- `preview`: Parst CSV, validiert, gibt ParsedProduct-Array + Fehlerliste zurück.
- `commit`: Führt Import aus, erzeugt fehlende ProductGroups/FillQuantities automatisch.

---

## Übersetzung

### `POST /api/v1/translate`
Auto-Übersetzung über MyMemory-API.
**Body:** `{ text, from: "de", to: "en" }`
**Response:** `{ translated: "..." }`
**Fallback:** Bei Fehler wird der Originaltext zurückgegeben.

---

## PDF

### `GET /api/v1/pdf?tenant=...&location=...&menu=...&lang=de`
Öffentlicher PDF-Export ohne Login.
**Response:** `application/pdf`

---

## Rate-Limits (Nginx-Layer)

| Bereich | Limit | Burst |
|---|---|---|
| `/api/auth/*` | 3 req/s | 5 |
| `/api/*` | 10 req/s | 20 |

Bei Überschreitung: HTTP 503.

## Pagination-Konvention

Endpoints mit Listen-Ergebnissen akzeptieren `page` (1-basiert) und `limit` (Default 24). Response enthält `{ items: [...], total, page, limit }`.

## Versionierung

Die API ist unter `/api/v1` versioniert. Breaking Changes werden als `/api/v2` bereitgestellt; alte Version bleibt 6 Monate parallel verfügbar.
