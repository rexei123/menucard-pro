# ============================================================================
# Phase 0 Tag 2 Schritt 3: Staging-Seed aus Prod-Dump
#
# Ablauf:
#   1. scripts/seed-staging-from-prod.sh als +x markieren und committen/pushen
#   2. Server: Prod-Repo + Staging-Repo auf main pullen
#   3. Server: Script ausfuehren (Seed-Lauf)
# ============================================================================
$ServerIP   = "178.104.138.177"
$ServerUser = "root"
$AppDir     = "/var/www/menucard-pro"
$StagingDir = "/var/www/menucard-pro-staging"
$Script     = "scripts/seed-staging-from-prod.sh"

Write-Host ""
Write-Host "=== Staging-Seed aus Prod-Dump ===" -ForegroundColor Cyan
Write-Host ""

# Git: filemode +x + add in einem Schritt (funktioniert auch fuer untracked files),
# dann commit + push
Write-Host "[1] Git: commit + push ($Script)" -ForegroundColor Yellow
git add --chmod=+x $Script
if ($LASTEXITCODE -ne 0) { Write-Host "git add --chmod=+x fehlgeschlagen." -ForegroundColor Red; exit 1 }
git commit -m "Staging-Seed-Script aus Prod-Dump (mit Anonymisierung + Rollback)"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Nichts zu committen (Script evtl. schon unveraendert gepusht) - fahre fort." -ForegroundColor Yellow
}
git push
if ($LASTEXITCODE -ne 0) { Write-Host "push fehlgeschlagen." -ForegroundColor Red; exit 1 }

# Server: Prod + Staging pullen, dann Seed-Script ausfuehren
Write-Host ""
Write-Host "[2] Server: Prod + Staging pullen, Seed-Script ausfuehren" -ForegroundColor Yellow
Write-Host ""

$cmd = @"
set -e
echo '--- Prod pull ---'
cd $AppDir && git pull --ff-only origin main && echo 'Prod HEAD:' \$(git rev-parse --short HEAD)
echo
echo '--- Staging pull ---'
cd $StagingDir && git fetch origin main && git reset --hard origin/main && echo 'Staging HEAD:' \$(git rev-parse --short HEAD)
echo
echo '--- Seed-Lauf ---'
bash $AppDir/$Script
"@

ssh -t "${ServerUser}@${ServerIP}" $cmd
$rc = $LASTEXITCODE

Write-Host ""
if ($rc -eq 0) {
    Write-Host "Seed OK. Staging-DB ist jetzt ein Prod-Klon (mit anonymisierten Logins)." -ForegroundColor Green
    Write-Host ""
    Write-Host "Staging testen:" -ForegroundColor Yellow
    Write-Host "  ssh -L 3001:127.0.0.1:3001 root@$ServerIP" -ForegroundColor Yellow
    Write-Host "  -> http://127.0.0.1:3001" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Admin-Login: siehe Ausgabe oben bzw. /root/.secrets/staging-admin-creds.txt" -ForegroundColor Yellow
} else {
    Write-Host "Seed fehlgeschlagen (Exit $rc). Der Rollback-Dump liegt unter /var/backups/menucard-pro/staging-rollback/" -ForegroundColor Red
}
