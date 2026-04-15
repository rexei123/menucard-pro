# dump-missing.ps1 - Holt die letzten fehlenden Dateien für Runde 2
$ErrorActionPreference = 'Stop'
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Dest = Join-Path $Here 'tests\design-compliance\source-dump'
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

Write-Host "== Dump fehlende Dateien =="
scp menucard:/var/www/menucard-pro/src/components/admin/media-archive.tsx (Join-Path $Dest 'src__components__admin__media-archive.tsx')
scp menucard:/var/www/menucard-pro/src/components/admin/icon-bar.tsx      (Join-Path $Dest 'src__components__admin__icon-bar.tsx')
scp menucard:/var/www/menucard-pro/src/styles/admin-font.css              (Join-Path $Dest 'src__styles__admin-font.css')

Write-Host "== Fertig =="
Get-ChildItem $Dest -Filter '*.tsx','*.css' | Format-Table Name, Length -AutoSize
