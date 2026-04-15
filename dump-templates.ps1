# dump-templates.ps1 - Holt Template-Renderer, Config-Reader und aktuelle DB-Configs
$ErrorActionPreference = 'Stop'
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Dest = Join-Path $Here 'tests\design-compliance\source-dump'
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

Write-Host "== Dateien dumpen =="
ssh menucard @"
cd /var/www/menucard-pro
mkdir -p /tmp/tpldump
# Rendering-Pipeline
cp src/components/menu-content.tsx                /tmp/tpldump/ 2>/dev/null || true
find src/components/templates -type f -name '*.tsx' -exec cp {} /tmp/tpldump/ \;
cp src/lib/design-config-reader.ts                /tmp/tpldump/ 2>/dev/null || true
cp src/lib/template-resolver.ts                   /tmp/tpldump/ 2>/dev/null || true
find src/lib/design-templates -type f -exec cp {} /tmp/tpldump/ \; 2>/dev/null || true
# DB-Configs der 4 SYSTEM-Templates
PGPASS=`$(grep -E '^DATABASE_URL=' .env | sed -E 's|.*://menucard:([^@]+)@.*|\1|')
PGPASSWORD=`$PGPASS psql -U menucard -h 127.0.0.1 -d menucard_pro -tAF'|' -c 'SELECT id, name, \"baseType\", config::text FROM \"DesignTemplate\" WHERE \"type\"::text=''SYSTEM'' ORDER BY \"baseType\";' > /tmp/tpldump/_db-configs.txt
# Auflistung
ls -la /tmp/tpldump/
tar -czf /tmp/tpldump.tgz -C /tmp/tpldump .
"@
scp menucard:/tmp/tpldump.tgz (Join-Path $Here 'tpldump.tgz')
tar -xzf (Join-Path $Here 'tpldump.tgz') -C $Dest
Write-Host "== Fertig =="
Get-ChildItem $Dest | Where-Object { $_.Name -match 'template|resolver|design|menu-content|_db' } | Format-Table Name, Length -AutoSize
