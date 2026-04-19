# ============================================================================
# Cleanup: Stray TS/TSX-Dateien aus dem Repo-Root nach .local-archive/
# Die Dateien sind alte Drafts, die Next.js beim Build als TypeScript-Check-
# Input aufnimmt und mit Import-Fehlern hochgehen. Live-Versionen sind in src/.
# ============================================================================

$ServerIP   = "178.104.138.177"
$ServerUser = "root"
$AppDir     = "/var/www/menucard-pro"
$StagingDir = "/var/www/menucard-pro-staging"

$files = @(
    "create-system-templates.ts",
    "design-edit-page.tsx",
    "design-editor-v2.tsx",
    "menu-pdf.tsx",
    "pdf-layout-tab.tsx",
    "seed-v2.ts",
    "template-edit-page-v2.tsx",
    "template-picker-drawer.tsx"
)

Write-Host ""
Write-Host "=== Cleanup: Stray Root-TS/TSX ===" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------------------
# 1. Archiv-Ziel anlegen + Dateien verschieben
# ----------------------------------------------------------------------
$archiveDir = ".local-archive\stray-root-ts-20260418"
if (-not (Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir | Out-Null
}

foreach ($f in $files) {
    if (Test-Path $f) {
        Write-Host "  mv $f -> $archiveDir\" -ForegroundColor Gray
        Move-Item -Path $f -Destination "$archiveDir\$f" -Force
    } else {
        Write-Host "  $f nicht im Working Tree (evtl. schon weg)" -ForegroundColor DarkGray
    }
}

# ----------------------------------------------------------------------
# 2. Git: Staging der Loeschungen
# ----------------------------------------------------------------------
Write-Host ""
Write-Host "[git] Staging deletes..." -ForegroundColor Yellow
& git add -u
if ($LASTEXITCODE -ne 0) {
    Write-Host "git add -u fehlgeschlagen." -ForegroundColor Red
    exit 1
}

& git status --short
Write-Host ""

# ----------------------------------------------------------------------
# 3. Commit + Push
# ----------------------------------------------------------------------
$msg = "Cleanup: 8 Draft-Dateien aus Repo-Root nach .local-archive (Build-Unblock fuer Staging+Prod)"
& git commit -m $msg
if ($LASTEXITCODE -ne 0) {
    Write-Host "Nichts zu committen oder commit fehlgeschlagen." -ForegroundColor Yellow
    exit 1
}

& git push
if ($LASTEXITCODE -ne 0) {
    Write-Host "push fehlgeschlagen." -ForegroundColor Red
    exit 1
}

Write-Host "Git OK" -ForegroundColor Green

# ----------------------------------------------------------------------
# 4. Staging-Repo pullen (damit der naechste Setup-Lauf den Fix hat)
#    Prod-Repo auch pullen (damit der naechste Prod-Deploy nicht haengt)
# ----------------------------------------------------------------------
Write-Host ""
Write-Host "Server: staging + prod repos pullen (nur code, keine Builds) ..." -ForegroundColor Yellow
Write-Host ""

$cmd = @"
set -e
echo '--- Prod ---'
cd $AppDir
git pull --ff-only origin main
echo 'Prod HEAD:' \$(git rev-parse --short HEAD)
echo
echo '--- Staging ---'
if [ -d $StagingDir/.git ]; then
    cd $StagingDir
    git fetch origin main
    git reset --hard origin/main
    echo 'Staging HEAD:' \$(git rev-parse --short HEAD)
else
    echo 'Staging-Verzeichnis existiert noch nicht (erster Setup-Lauf).'
fi
"@

ssh -t "$ServerUser@$ServerIP" $cmd
if ($LASTEXITCODE -ne 0) {
    Write-Host "Server-Pull fehlgeschlagen." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Cleanup abgeschlossen. Jetzt .\phase0-tag2-staging-run.ps1 erneut laufen lassen." -ForegroundColor Green
