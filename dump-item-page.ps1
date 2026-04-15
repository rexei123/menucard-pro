# dump-item-page.ps1 - holt die Item-Detail-Seite + public-layouts fuer Runde 4
$ErrorActionPreference = 'Stop'
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Dst  = Join-Path $Here 'tests\design-compliance\source-dump'
New-Item -ItemType Directory -Force -Path $Dst | Out-Null

Write-Host "== Public-Routes tarbale bauen =="
ssh menucard @"
cd /var/www/menucard-pro && \
mkdir -p /tmp/itemdump && rm -rf /tmp/itemdump/* && \
find 'src/app/(public)' -type f -name 'page.tsx' -o -name 'layout.tsx' | while read f; do
  mkdir -p /tmp/itemdump/\`$(dirname `"\`$f`")
  cp `"\`$f`" /tmp/itemdump/\`$f
done && \
cp src/components/templates/*-renderer.tsx /tmp/itemdump/ 2>/dev/null && \
tar czf /tmp/itemdump.tgz -C /tmp/itemdump . && \
ls -la /tmp/itemdump.tgz
"@

Write-Host "== Archiv holen =="
scp menucard:/tmp/itemdump.tgz (Join-Path $Dst 'itemdump.tgz')

Write-Host "== Entpacken =="
tar -xzf (Join-Path $Dst 'itemdump.tgz') -C $Dst

Write-Host "== Struktur =="
Get-ChildItem -Recurse (Join-Path $Dst 'src') | Select-Object FullName,Length
