# fetch-api-sources.ps1 - Holt alle relevanten API- und Quell-Dateien vom Server
# ==================================================================================
$ErrorActionPreference = 'Stop'

$SERVER = "root@178.104.138.177"
$APP    = "/var/www/menucard-pro"
$LOCAL  = "server-src"

Write-Host ""
Write-Host "== API-Quelldateien vom Server holen ==" -ForegroundColor Cyan

# Lokales Verzeichnis erstellen
if (-not (Test-Path $LOCAL)) { New-Item -ItemType Directory -Path $LOCAL -Force | Out-Null }
if (-not (Test-Path "$LOCAL/api-v1")) { New-Item -ItemType Directory -Path "$LOCAL/api-v1" -Force | Out-Null }
if (-not (Test-Path "$LOCAL/app-public")) { New-Item -ItemType Directory -Path "$LOCAL/app-public" -Force | Out-Null }
if (-not (Test-Path "$LOCAL/lib")) { New-Item -ItemType Directory -Path "$LOCAL/lib" -Force | Out-Null }
if (-not (Test-Path "$LOCAL/components")) { New-Item -ItemType Directory -Path "$LOCAL/components" -Force | Out-Null }

# 1. API-Verzeichnisstruktur anzeigen
Write-Host "`n--- API-Verzeichnisstruktur ---" -ForegroundColor Yellow
ssh $SERVER "find $APP/src/app/api/v1 -name '*.ts' -o -name '*.tsx' | sort"

# 2. Alle API-Route-Dateien herunterladen
Write-Host "`n--- API-Dateien herunterladen ---" -ForegroundColor Yellow
ssh $SERVER "cd $APP; tar czf /tmp/api-src.tar.gz src/app/api/v1/"
scp "${SERVER}:/tmp/api-src.tar.gz" "$LOCAL/api-src.tar.gz"
Push-Location $LOCAL
tar xzf api-src.tar.gz
Pop-Location
Write-Host "  API-Dateien in $LOCAL/src/app/api/v1/" -ForegroundColor Green

# 3. Public Routes (Gaesteansicht)
Write-Host "`n--- Public-Routes herunterladen ---" -ForegroundColor Yellow
ssh $SERVER "cd $APP; tar czf /tmp/public-src.tar.gz src/app/'(public)'/"
scp "${SERVER}:/tmp/public-src.tar.gz" "$LOCAL/public-src.tar.gz"
Push-Location $LOCAL
tar xzf public-src.tar.gz
Pop-Location
Write-Host "  Public-Routes in $LOCAL/src/app/(public)/" -ForegroundColor Green

# 4. Lib-Dateien (prisma, auth, helpers)
Write-Host "`n--- Lib-Dateien herunterladen ---" -ForegroundColor Yellow
ssh $SERVER "cd $APP; tar czf /tmp/lib-src.tar.gz src/lib/"
scp "${SERVER}:/tmp/lib-src.tar.gz" "$LOCAL/lib-src.tar.gz"
Push-Location $LOCAL
tar xzf lib-src.tar.gz
Pop-Location
Write-Host "  Lib-Dateien in $LOCAL/src/lib/" -ForegroundColor Green

# 5. Components
Write-Host "`n--- Components herunterladen ---" -ForegroundColor Yellow
ssh $SERVER "cd $APP; tar czf /tmp/comp-src.tar.gz src/components/"
scp "${SERVER}:/tmp/comp-src.tar.gz" "$LOCAL/comp-src.tar.gz"
Push-Location $LOCAL
tar xzf comp-src.tar.gz
Pop-Location
Write-Host "  Components in $LOCAL/src/components/" -ForegroundColor Green

# 6. Prisma Schema (aktuell v2)
Write-Host "`n--- Prisma Schema ---" -ForegroundColor Yellow
scp "${SERVER}:${APP}/prisma/schema.prisma" "$LOCAL/schema.prisma"
Write-Host "  Schema in $LOCAL/schema.prisma" -ForegroundColor Green

# 7. Config-Dateien
Write-Host "`n--- Config-Dateien ---" -ForegroundColor Yellow
scp "${SERVER}:${APP}/next.config.mjs" "$LOCAL/next.config.mjs" 2>$null
scp "${SERVER}:${APP}/tailwind.config.ts" "$LOCAL/tailwind.config.ts" 2>$null
scp "${SERVER}:${APP}/tsconfig.json" "$LOCAL/tsconfig.json" 2>$null
scp "${SERVER}:${APP}/package.json" "$LOCAL/package.json" 2>$null
Write-Host "  Config-Dateien in $LOCAL/" -ForegroundColor Green

# Aufraumen
Remove-Item "$LOCAL/*.tar.gz" -Force 2>$null

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "  Alle Quell-Dateien heruntergeladen" -ForegroundColor Green
Write-Host "  Verzeichnis: $LOCAL/" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host ""
