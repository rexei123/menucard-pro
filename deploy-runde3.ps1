# deploy-runde3.ps1 - Runde 3: Template-Renderer-Bug fix + Modern/Minimal-Fonts
# - Fixt template-resolver.ts (Wrapper-Bug)
# - Setzt Modern: Inter -> Montserrat
# - Setzt Minimal: Inter -> Space Grotesk
# - Aktualisiert design-config-reader.ts (Sans-Serif Fallback)
# - Wrappt menu-content.tsx in mc-template-${template}
# - Neue menu-font.css mit :has() Regeln
# - Layout: Roboto + Space Grotesk eingebunden, CSS-Imports erweitert
# - DB-Reseed der SYSTEM-Templates damit DB-Configs die neuen Fonts haben
$ErrorActionPreference = 'Stop'
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "== 1. Backup der Originaldateien =="
ssh menucard "cd /var/www/menucard-pro && for f in src/lib/template-resolver.ts src/lib/design-config-reader.ts src/lib/design-templates/modern.ts src/lib/design-templates/minimal.ts src/components/menu-content.tsx src/app/layout.tsx; do cp -n `"`$f`" `"`$f.bak.runde2`" 2>/dev/null && echo `"  backup: `$f`" || echo `"  bereits gesichert: `$f`"; done"

Write-Host "== 2. Upload der neuen Dateien =="
scp (Join-Path $Here 'runde3\src__lib__template-resolver.ts')              menucard:/var/www/menucard-pro/src/lib/template-resolver.ts
scp (Join-Path $Here 'runde3\src__lib__design-config-reader.ts')           menucard:/var/www/menucard-pro/src/lib/design-config-reader.ts
scp (Join-Path $Here 'runde3\src__lib__design-templates__modern.ts')       menucard:/var/www/menucard-pro/src/lib/design-templates/modern.ts
scp (Join-Path $Here 'runde3\src__lib__design-templates__minimal.ts')      menucard:/var/www/menucard-pro/src/lib/design-templates/minimal.ts
scp (Join-Path $Here 'runde3\src__components__menu-content.tsx')           menucard:/var/www/menucard-pro/src/components/menu-content.tsx
scp (Join-Path $Here 'runde3\src__app__layout.tsx')                        menucard:/var/www/menucard-pro/src/app/layout.tsx
scp (Join-Path $Here 'runde3\src__styles__menu-font.css')                  menucard:/var/www/menucard-pro/src/styles/menu-font.css

Write-Host "== 3. Reseed-Script hochladen =="
ssh menucard "mkdir -p /var/www/menucard-pro/runde3"
scp (Join-Path $Here 'runde3\reseed-system-templates.ts')                  menucard:/var/www/menucard-pro/runde3/reseed-system-templates.ts

Write-Host "== 4. DB-Reseed (SYSTEM-Templates Modern/Minimal mit neuen Fonts) =="
ssh menucard "cd /var/www/menucard-pro && (npx tsx runde3/reseed-system-templates.ts || npx ts-node --transpile-only runde3/reseed-system-templates.ts)"

Write-Host "== 5. Build + Restart =="
ssh menucard "cd /var/www/menucard-pro && npm run build 2>&1 | tail -30 && pm2 restart menucard-pro && sleep 4 && curl -sk -o /dev/null -w 'HTTP %{http_code}\n' https://menu.hotel-sonnblick.at/auth/login"

Write-Host "== 6. Smoke-Test: Modern-Karte rendert Montserrat =="
ssh menucard "curl -sk https://menu.hotel-sonnblick.at/hotel-sonnblick/restaurant/$(psql -U menucard -d menucard_pro -tAc \`"select slug from \\\`"Menu\\\`" m join \\\`"DesignTemplate\\\`" d on m.\\\`"templateId\\\`"=d.id where d.\\\`"baseType\\\`"='modern' limit 1\`") 2>/dev/null | grep -oE 'mc-template-modern' | head -1 || echo 'WARN: mc-template-modern marker not found'"

Write-Host "== 7. Compliance-Pipeline neu starten =="
scp (Join-Path $Here 'design-compliance.mjs') menucard:/var/www/menucard-pro/design-compliance.mjs
ssh menucard "cd /var/www/menucard-pro && bash design-compliance-remote.sh 20260414c"

Write-Host "== 8. Bundle holen =="
scp menucard:/var/www/menucard-pro/tests/design-compliance/bundle.tgz (Join-Path $Here 'tests\design-compliance\bundle-runde3.tgz')

Write-Host ""
Write-Host "== FERTIG =="
Write-Host ("  Bundle : " + (Join-Path $Here 'tests\design-compliance\bundle-runde3.tgz'))
Write-Host ("  Excel  : auf Server unter tests/design-compliance/DESIGN-COMPLIANCE-REPORT-20260414c.xlsx")
Write-Host ""
Write-Host "Naechste Schritte:"
Write-Host "  - Bundle entpacken: tar -xzf tests\design-compliance\bundle-runde3.tgz -C tests\design-compliance"
Write-Host "  - Report-Excel pruefen, ggf. PASS/FAIL durchgehen"
