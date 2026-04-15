# continue-runde3.ps1 - Holt Smoke-Test + Compliance-Pipeline + Bundle nach
# (deploy-runde3.ps1 hat Schritte 1-5 erfolgreich durchgezogen, Step 6 ist
#  wegen eines PowerShell-Escape-Bugs mit lokalem psql abgebrochen)
$ErrorActionPreference = 'Stop'
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "== 6. Smoke-Test: Modern-Karte rendert mc-template-modern =="
ssh menucard 'cd /var/www/menucard-pro && MENU_SLUG=$(sudo -u postgres psql -d menucard_pro -tAc "SELECT m.slug FROM \"Menu\" m JOIN \"DesignTemplate\" d ON m.\"templateId\"=d.id WHERE d.\"baseType\"=''modern'' LIMIT 1") && LOC_SLUG=$(sudo -u postgres psql -d menucard_pro -tAc "SELECT l.slug FROM \"Menu\" m JOIN \"Location\" l ON m.\"locationId\"=l.id JOIN \"DesignTemplate\" d ON m.\"templateId\"=d.id WHERE d.\"baseType\"=''modern'' LIMIT 1") && echo "Modern-Karte: /hotel-sonnblick/$LOC_SLUG/$MENU_SLUG" && curl -sk "https://menu.hotel-sonnblick.at/hotel-sonnblick/$LOC_SLUG/$MENU_SLUG" | grep -oE "mc-template-(modern|minimal|classic|elegant)" | sort -u'

Write-Host ""
Write-Host "== 7. Compliance-Pipeline neu starten =="
scp (Join-Path $Here 'design-compliance.mjs') menucard:/var/www/menucard-pro/design-compliance.mjs
ssh menucard "cd /var/www/menucard-pro && bash design-compliance-remote.sh 20260414c"

Write-Host ""
Write-Host "== 8. Bundle holen =="
scp menucard:/var/www/menucard-pro/tests/design-compliance/bundle.tgz (Join-Path $Here 'tests\design-compliance\bundle-runde3.tgz')

Write-Host ""
Write-Host "== FERTIG =="
Write-Host ("  Bundle : " + (Join-Path $Here 'tests\design-compliance\bundle-runde3.tgz'))
Write-Host ""
Write-Host "Bundle entpacken (wenn gewuenscht):"
Write-Host "  tar -xzf tests\design-compliance\bundle-runde3.tgz -C tests\design-compliance"
