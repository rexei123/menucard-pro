# deploy-runde4.ps1 - Runde 4: Compliance-Fixes auf Basis von Runde 3
# ---------------------------------------------------------------
# Fixes zur Erreichung von 56/58 PASS (4 verbleibende Fehler sind
# reine Content-Emojis, keine Design-Abweichungen):
#
#  1) menu-font.css  - Elegant/Classic body NICHT mehr forcieren,
#                       Default Inter laesst der Layout-Loader durch.
#                       Classic/Elegant h1,h2 -> Playfair Display.
#  2) classic.ts     - h1/h2 von 'Cormorant Garamond' -> 'Playfair Display'.
#                       Body bleibt Lato.
#  3) item/page.tsx  - Item-Detailseite rendert jetzt im
#                       mc-template-root / mc-template-${template}
#                       Wrapper und nutzt die CSS-Variablen statt
#                       hartkodierter 'Playfair Display'.
# ---------------------------------------------------------------
$ErrorActionPreference = 'Stop'
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "== 1. Backup der Originaldateien =="
ssh menucard "cd /var/www/menucard-pro && for f in 'src/styles/menu-font.css' 'src/lib/design-templates/classic.ts' 'src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx'; do cp -n `"`$f`" `"`$f.bak.runde3`" 2>/dev/null && echo `"  backup: `$f`" || echo `"  bereits gesichert: `$f`"; done"

Write-Host ""
Write-Host "== 2. Upload der neuen Dateien =="
scp (Join-Path $Here 'runde4\src__styles__menu-font.css')            menucard:/var/www/menucard-pro/src/styles/menu-font.css
scp (Join-Path $Here 'runde4\src__lib__design-templates__classic.ts') menucard:/var/www/menucard-pro/src/lib/design-templates/classic.ts
# Item-Detail-Seite (Pfad mit Klammern/Bracket-Parametern)
scp (Join-Path $Here 'runde4\src__app__public__item__page.tsx')      'menucard:/var/www/menucard-pro/src/app/(public)/[tenant]/[location]/[menu]/item/[itemId]/page.tsx'

Write-Host ""
Write-Host "== 3. DB-Reseed (Classic h1/h2 auf Playfair Display) =="
# reseed-system-templates.ts aus runde3 ist weiterhin gueltig und
# uebernimmt automatisch alle 4 SYSTEM-Templates aus den aktuellen TS-Files
ssh menucard "cd /var/www/menucard-pro && (npx tsx runde3/reseed-system-templates.ts || npx ts-node --transpile-only runde3/reseed-system-templates.ts)"

Write-Host ""
Write-Host "== 4. Build + Restart =="
ssh menucard "cd /var/www/menucard-pro && npm run build 2>&1 | tail -30 && pm2 restart menucard-pro && sleep 4 && curl -sk -o /dev/null -w 'HTTP %{http_code}\n' https://menu.hotel-sonnblick.at/auth/login"

Write-Host ""
Write-Host "== 5. Smoke-Test: Classic-Karte traegt mc-template-classic =="
ssh menucard 'cd /var/www/menucard-pro && MENU_SLUG=$(sudo -u postgres psql -d menucard_pro -tAc "SELECT m.slug FROM \"Menu\" m JOIN \"DesignTemplate\" d ON m.\"templateId\"=d.id WHERE d.\"baseType\"=''classic'' LIMIT 1") && LOC_SLUG=$(sudo -u postgres psql -d menucard_pro -tAc "SELECT l.slug FROM \"Menu\" m JOIN \"Location\" l ON m.\"locationId\"=l.id JOIN \"DesignTemplate\" d ON m.\"templateId\"=d.id WHERE d.\"baseType\"=''classic'' LIMIT 1") && echo "Classic-Karte: /hotel-sonnblick/$LOC_SLUG/$MENU_SLUG" && curl -sk "https://menu.hotel-sonnblick.at/hotel-sonnblick/$LOC_SLUG/$MENU_SLUG" | grep -oE "mc-template-(modern|minimal|classic|elegant)" | sort -u'

Write-Host ""
Write-Host "== 6. Smoke-Test: Item-Detail-Seite traegt mc-template-root =="
ssh menucard 'cd /var/www/menucard-pro && MENU_SLUG=$(sudo -u postgres psql -d menucard_pro -tAc "SELECT m.slug FROM \"Menu\" m JOIN \"DesignTemplate\" d ON m.\"templateId\"=d.id WHERE d.\"baseType\"=''modern'' LIMIT 1") && LOC_SLUG=$(sudo -u postgres psql -d menucard_pro -tAc "SELECT l.slug FROM \"Menu\" m JOIN \"Location\" l ON m.\"locationId\"=l.id JOIN \"DesignTemplate\" d ON m.\"templateId\"=d.id WHERE d.\"baseType\"=''modern'' LIMIT 1") && ITEM_ID=$(sudo -u postgres psql -d menucard_pro -tAc "SELECT mp.\"productId\" FROM \"MenuPlacement\" mp JOIN \"Menu\" m ON mp.\"menuId\"=m.id JOIN \"DesignTemplate\" d ON m.\"templateId\"=d.id WHERE d.\"baseType\"=''modern'' LIMIT 1") && echo "Item: /hotel-sonnblick/$LOC_SLUG/$MENU_SLUG/item/$ITEM_ID" && curl -sk "https://menu.hotel-sonnblick.at/hotel-sonnblick/$LOC_SLUG/$MENU_SLUG/item/$ITEM_ID" | grep -oE "mc-template-(root|modern|minimal|classic|elegant)" | sort -u'

Write-Host ""
Write-Host "== 7. Compliance-Pipeline neu starten =="
scp (Join-Path $Here 'design-compliance.mjs') menucard:/var/www/menucard-pro/design-compliance.mjs
ssh menucard "cd /var/www/menucard-pro && bash design-compliance-remote.sh 20260414d"

Write-Host ""
Write-Host "== 8. Bundle holen =="
scp menucard:/var/www/menucard-pro/tests/design-compliance/bundle.tgz (Join-Path $Here 'tests\design-compliance\bundle-runde4.tgz')

Write-Host ""
Write-Host "== FERTIG =="
Write-Host ("  Bundle : " + (Join-Path $Here 'tests\design-compliance\bundle-runde4.tgz'))
Write-Host ("  Excel  : auf Server unter tests/design-compliance/DESIGN-COMPLIANCE-REPORT-20260414d.xlsx")
Write-Host ""
Write-Host "Naechste Schritte:"
Write-Host "  - Bundle entpacken: tar -xzf tests\design-compliance\bundle-runde4.tgz -C tests\design-compliance"
Write-Host "  - Report-Excel pruefen - Zielwert: 56/58 PASS (verbleibende 4 Fehler = Content-Emojis)"
