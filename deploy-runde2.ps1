# deploy-runde2.ps1 - Spielt die 4 TSX/CSS-Rewrites ein, baut, startet neu, läuft Compliance erneut.
$ErrorActionPreference = 'Stop'
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "== 1. Backup der Originaldateien auf dem Server =="
ssh menucard "cd /var/www/menucard-pro && for f in src/app/layout.tsx src/styles/admin-font.css src/app/auth/login/page.tsx src/components/admin/media-archive.tsx; do cp -n `"`$f`" `"`$f.bak.runde1`" 2>/dev/null && echo `"  backup: `$f`" || echo `"  bereits gesichert: `$f`"; done"

Write-Host "== 2. Upload der neuen Dateien =="
scp (Join-Path $Here 'runde2\src__app__layout.tsx')                     menucard:/var/www/menucard-pro/src/app/layout.tsx
scp (Join-Path $Here 'runde2\src__styles__admin-font.css')              menucard:/var/www/menucard-pro/src/styles/admin-font.css
scp (Join-Path $Here 'runde2\src__app__auth__login__page.tsx')          menucard:/var/www/menucard-pro/src/app/auth/login/page.tsx
scp (Join-Path $Here 'runde2\src__components__admin__media-archive.tsx') menucard:/var/www/menucard-pro/src/components/admin/media-archive.tsx

Write-Host "== 3. Build + Restart =="
ssh menucard "cd /var/www/menucard-pro && npm run build 2>&1 | tail -25 && pm2 restart menucard-pro && sleep 4 && curl -sk -o /dev/null -w 'HTTP %{http_code}\n' https://menu.hotel-sonnblick.at/auth/login"

Write-Host "== 4. Compliance-Pipeline neu (lädt geänderte mjs hoch und startet kompletten Test) =="
scp (Join-Path $Here 'design-compliance.mjs') menucard:/var/www/menucard-pro/design-compliance.mjs
ssh menucard "cd /var/www/menucard-pro && bash design-compliance-remote.sh 20260414b"

Write-Host "== 5. Bundle holen =="
scp menucard:/var/www/menucard-pro/tests/design-compliance/bundle.tgz (Join-Path $Here 'tests\design-compliance\bundle-runde2.tgz')
tar -xzf (Join-Path $Here 'tests\design-compliance\bundle-runde2.tgz') -C (Join-Path $Here 'tests\design-compliance') --overwrite

Write-Host ""
Write-Host "== FERTIG =="
Write-Host ("  Excel : " + (Join-Path $Here 'tests\design-compliance\DESIGN-COMPLIANCE-REPORT-20260414b.xlsx'))
Write-Host ("  JSON  : " + (Join-Path $Here 'tests\design-compliance\report.json'))
