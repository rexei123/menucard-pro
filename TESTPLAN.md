# MenuCard Pro – Testplan
## Stand: 11.04.2026

---

## Automatische Tests

Zwei Scripts zum Ausführen auf dem Server:

**Funktionale Bugtests:**
```
bash test-bugs.sh
```
Prüft: Login, Admin-Seiten, Menü-API, Design-API (Laden/Speichern/Reset), Templates, Produkt-API, Gästeansicht, QR-Codes, Datenbank-Konsistenz, PM2-Status, Festplatte.

**Sicherheitstests:**
```
bash test-security.sh
```
Prüft: Auth-Schutz aller API-Routen, Login-Sicherheit (falsches PW, SQL-Injection), sensible Dateien (.env, .git, prisma), HTTP-Security-Header, XSS in Design-Config, CORS, PostgreSQL-Zugriff, Nginx, Firewall, npm-Schwachstellen.

---

## Manueller Testplan – Im Browser durchklicken

### A. Admin-Login

| Nr | Test | Erwartet | OK? |
|----|------|----------|-----|
| A1 | Login mit korrekten Daten | Dashboard wird angezeigt | |
| A2 | Login mit falschem Passwort | Fehlermeldung, kein Zugang | |
| A3 | Login mit leerem E-Mail-Feld | Validierungsfehler | |
| A4 | Abmelden und Admin-Seite aufrufen | Redirect zu Login | |

### B. Dashboard

| Nr | Test | Erwartet | OK? |
|----|------|----------|-----|
| B1 | Dashboard lädt | Karten-Anzahl, Produkte, QR-Codes sichtbar | |
| B2 | Sidebar auf-/zuklappen | Smooth Animation, Icons bleiben sichtbar | |
| B3 | Alle Sidebar-Links funktionieren | Jede Seite öffnet sich korrekt | |

### C. Kartenverwaltung

| Nr | Test | Erwartet | OK? |
|----|------|----------|-----|
| C1 | Karten-Liste öffnen | Alle 9 Karten werden angezeigt | |
| C2 | Karte anklicken | Editor öffnet sich mit Produkten | |
| C3 | Produkt-Reihenfolge ändern (Drag & Drop) | Neue Reihenfolge wird gespeichert | |
| C4 | Produkt als ausverkauft markieren | Badge erscheint, Gästeansicht zeigt es | |

### D. Design-Editor

| Nr | Test | Erwartet | OK? |
|----|------|----------|-----|
| D1 | Design-Editor öffnen | 7 Akkordeon-Bereiche + Vorschau sichtbar | |
| D2 | Vorlage wechseln (z.B. Elegant → Modern) | Live-Vorschau ändert sich sofort | |
| D3 | Typografie ändern (Schrift, Größe, Farbe) | Vorschau zeigt Änderung, Auto-Save | |
| D4 | Farbe ändern (Color-Picker) | Sofort in Vorschau sichtbar | |
| D5 | Alle 7 Akkordeons öffnen/schließen | Smooth Animation, keine Fehler | |
| D6 | Handy/Desktop-Vorschau umschalten | iFrame-Größe ändert sich korrekt | |
| D7 | "Zurücksetzen"-Button klicken | Bestätigungsdialog erscheint | |
| D8 | Reset bestätigen | Alle Einstellungen auf Template-Default | |
| D9 | Reset abbrechen | Nichts passiert, Dialog schließt sich | |
| D10 | Einstellung ändern → "Benutzerdefiniert" | Blaue Custom-Karte erscheint unter Templates | |
| D11 | Vorlage wechseln bei Custom-Änderungen | Warnung: "Änderungen gehen verloren" | |
| D12 | Seite neu laden nach Änderungen | Alle gespeicherten Einstellungen bleiben erhalten | |

### E. Produkt-Editor

| Nr | Test | Erwartet | OK? |
|----|------|----------|-----|
| E1 | Neues Produkt anlegen | Formular öffnet sich, Pflichtfelder markiert | |
| E2 | Produkt mit Bild hochladen | Bild wird in WebP konvertiert, Thumbnails erstellt | |
| E3 | Übersetzung DE + EN pflegen | Beide Sprachen speicherbar | |
| E4 | Preis mit Füllmenge anlegen | Korrekte Anzeige in Karte | |
| E5 | Weinprofil ausfüllen (Rebsorte, Jahrgang, etc.) | Alle Felder speicherbar | |
| E6 | Produkt löschen | Bestätigung → Produkt entfernt | |
| E7 | Sonderzeichen im Namen (ö, ü, é, ñ) | Korrekte Anzeige überall | |

### F. CSV-Import

| Nr | Test | Erwartet | OK? |
|----|------|----------|-----|
| F1 | Gültige CSV hochladen | Vorschau mit allen Spalten | |
| F2 | CSV mit Fehlern hochladen | Fehler werden rot markiert, editierbar | |
| F3 | Fehler in Vorschau korrigieren | Neu-Validierung, grün wenn OK | |
| F4 | Import bestätigen | Produkte werden erstellt/aktualisiert | |
| F5 | Doppelter Import (gleiche SKUs) | Upsert – bestehende Produkte aktualisiert | |
| F6 | Leere CSV hochladen | Fehlermeldung | |

### G. Gästeansicht

| Nr | Test | Erwartet | OK? |
|----|------|----------|-----|
| G1 | Karte per URL öffnen (Desktop) | Vollständige Karte mit allen Produkten | |
| G2 | Karte am Handy öffnen | Mobile-optimierte Ansicht | |
| G3 | Sprachwechsel DE ↔ EN | Alle Texte wechseln, URL ändert sich | |
| G4 | Suchfunktion nutzen | Ergebnisse erscheinen live | |
| G5 | Filter anwenden (vegetarisch, vegan, etc.) | Nur passende Produkte angezeigt | |
| G6 | Produktdetail öffnen | Bild, Beschreibung, Allergene, Preis sichtbar | |
| G7 | Navigation (Sticky-Menü, Back-to-Top) | Funktioniert smooth | |
| G8 | Ladezeit messen (erste Aufruf) | Unter 3 Sekunden | |
| G9 | Ausverkauftes Produkt | Korrekt als nicht verfügbar markiert | |

### H. QR-Codes

| Nr | Test | Erwartet | OK? |
|----|------|----------|-----|
| H1 | QR-Code erstellen für eine Karte | QR-Code wird generiert und angezeigt | |
| H2 | QR-Code scannen (Handy-Kamera) | Öffnet die richtige Karte | |
| H3 | QR-Code als PNG herunterladen | Datei wird korrekt gespeichert | |
| H4 | QR-Code als SVG herunterladen | Vektordatei, skalierbar | |

### I. PDF-Export

| Nr | Test | Erwartet | OK? |
|----|------|----------|-----|
| I1 | PDF einer Karte generieren | PDF wird erstellt und heruntergeladen | |
| I2 | PDF enthält alle Produkte | Vollständige Liste mit Preisen | |
| I3 | PDF-Formatierung prüfen | Lesbar, sauberes Layout | |
| I4 | PDF in DE und EN generieren | Sprache korrekt in PDF | |

---

## Bekannte Risiken / Offene Punkte

- **Kein SSL/HTTPS:** Domain + SSL-Zertifikat wartet auf IT. Bis dahin keine verschlüsselte Verbindung.
- **Backup-Strategie:** Manuelle SQL-Dumps vorhanden, aber kein automatisches Backup-System.
- **Rate-Limiting:** Noch nicht konfiguriert in Nginx – bei öffentlichem Launch nachrüsten.
- **Rollen & Rechte:** Aktuell nur OWNER-Rolle implementiert.

---

## So teilen Sie die Ergebnisse

Nach dem Durchlaufen der Tests:
1. Automatische Tests: Kopieren Sie die Konsolenausgabe
2. Manuelle Tests: Markieren Sie in der OK-Spalte mit ✓ oder ✗
3. Teilen Sie mir die Ergebnisse – ich fixe alle gefundenen Probleme
