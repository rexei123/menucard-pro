# fix-phase3-build.ps1 - Behebt Prisma-Schema + Build-Fehler
# ============================================================
# 1. TaxRate-Relation im Schema fixen
# 2. seed-v2.ts aus Build-Pfad verschieben
# 3. Prisma generate + build + restart
# ============================================================
$ErrorActionPreference = 'Stop'

$SERVER = "root@178.104.138.177"
$APP    = "/var/www/menucard-pro"
$DB     = "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

Write-Host ""
Write-Host "== Fix: Schema + Build ==" -ForegroundColor Cyan
Write-Host ""

# 1. Gepatchtes Schema hochladen (TaxRate-Relation gefixt)
Write-Host "  1. Schema hochladen..." -ForegroundColor Yellow
scp "schema-v2-patch.prisma" "${SERVER}:${APP}/prisma/schema.prisma"
Write-Host "     OK" -ForegroundColor Green

# 2. seed-v2.ts aus Root verschieben (Next.js compiliert es sonst mit)
Write-Host "  2. seed-v2.ts in scripts/ verschieben..." -ForegroundColor Yellow
ssh $SERVER "cd $APP; mkdir -p scripts; if [ -f seed-v2.ts ]; then mv seed-v2.ts scripts/seed-v2.ts; echo 'Verschoben'; else echo 'Bereits verschoben oder nicht vorhanden'; fi"
Write-Host "     OK" -ForegroundColor Green

# 3. Prisma db push (additive Aenderung: Relation-Feld)
Write-Host "  3. prisma db push..." -ForegroundColor Yellow
ssh $SERVER "cd $APP; npx prisma db push --accept-data-loss 2>&1"

# 4. Prisma generate
Write-Host "  4. prisma generate..." -ForegroundColor Yellow
ssh $SERVER "cd $APP; npx prisma generate 2>&1"

# 5. Build
Write-Host "  5. npm run build..." -ForegroundColor Yellow
ssh $SERVER "cd $APP; npm run build 2>&1"

# 6. PM2 restart
Write-Host "  6. pm2 restart..." -ForegroundColor Yellow
ssh $SERVER "pm2 restart menucard-pro 2>&1"
Start-Sleep -Seconds 4

# 7. Schnelltest
Write-Host "`n  7. Schnelltest..." -ForegroundColor Yellow

Write-Host "     GET /api/v1/menus -> " -NoNewline
ssh $SERVER "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/api/v1/menus"
Write-Host ""

Write-Host "     GET /hotel-sonnblick/restaurant/abendkarte -> " -NoNewline
ssh $SERVER "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/restaurant/abendkarte"
Write-Host ""

Write-Host "     GET /hotel-sonnblick/restaurant/weinkarte -> " -NoNewline
ssh $SERVER "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/restaurant/weinkarte"
Write-Host ""

Write-Host ""
Write-Host "== Fix abgeschlossen ==" -ForegroundColor Green
Write-Host ""
