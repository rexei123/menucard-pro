# dump-public.ps1 - holt src/app/(public)/** komplett fuer Runde 4 Analyse
$ErrorActionPreference = 'Stop'
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Dst  = Join-Path $Here 'tests\design-compliance\source-dump'
New-Item -ItemType Directory -Force -Path $Dst | Out-Null

Write-Host "== Public-Routes + Template-Renderer tarball bauen =="
ssh menucard "cd /var/www/menucard-pro && tar czf /tmp/publicdump.tgz 'src/app/(public)' src/components/templates 2>&1 | head -10"

Write-Host "== Archiv holen =="
scp menucard:/tmp/publicdump.tgz (Join-Path $Dst 'publicdump.tgz')

Write-Host "== Entpacken =="
tar -xzf (Join-Path $Dst 'publicdump.tgz') -C $Dst

Write-Host "== Struktur =="
Get-ChildItem -Recurse -Filter *.tsx (Join-Path $Dst 'src') | Select-Object FullName,Length
