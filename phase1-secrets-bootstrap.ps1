# ============================================================================
# PHASE 1 - SECRETS ROTATION BOOTSTRAP (einmalig)
# ============================================================================
# Legt die Secrets-Rotation-Scripts auf dem Server ab:
#
#   1. Lokal: scripts/rotate-secrets.sh + phase1-secrets-rotation.ps1 committen + pushen
#   2. Server: git pull origin main + chmod +x
#   3. Server: Dry-Run des Rotation-Scripts als Smoke-Check
#
# Danach kann die eigentliche Rotation gestartet werden:
#
#   .\phase1-secrets-rotation.ps1 -DryRun   # Plan anschauen
#   .\phase1-secrets-rotation.ps1           # Rotation durchfuehren
#
# Dieses Script fuehrt KEINE Rotation durch. Es stellt nur die Werkzeuge bereit.
# ============================================================================

param(
    [string]$ServerIP   = "178.104.138.177",
    [string]$ServerUser = "root"
)

$ErrorActionPreference = 'Continue'

function Section($t)  { Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Cyan }
function Ok($t)       { Write-Host "OK   $t" -ForegroundColor Green }
function Warn($t)     { Write-Host "WARN $t" -ForegroundColor Yellow }
function ErrLine($t)  { Write-Host "FAIL $t" -ForegroundColor Red }
function Step($n,$t)  { Write-Host ""; Write-Host "[$n] $t" -ForegroundColor Yellow }

$AppDir = "/var/www/menucard-pro"

Section "Bootstrap Secrets-Rotation"

# ----------------------------------------------------------------------
# 1. Lokal: Executable-Bit setzen, stagen, committen, pushen
# ----------------------------------------------------------------------
Step "1/3" "Lokal committen und pushen"

# Executable-Bit fuer die Shell-Datei im Git-Index markieren (Windows -> Linux)
& git add --chmod=+x scripts/rotate-secrets.sh
if ($LASTEXITCODE -ne 0) {
    ErrLine "git add --chmod=+x fehlgeschlagen."
    exit 1
}
& git add phase1-secrets-rotation.ps1 phase1-secrets-bootstrap.ps1
if ($LASTEXITCODE -ne 0) {
    ErrLine "git add fehlgeschlagen."
    exit 1
}

$staged = & git diff --cached --name-only
if (-not $staged) {
    Warn "Nichts zu committen (Dateien bereits im Repo)."
} else {
    Write-Host "  Zu committen:" -ForegroundColor Gray
    $staged | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

    $msg = @"
Phase 1: Secrets-Rotation (Launcher + Server-Script)

- scripts/rotate-secrets.sh: Orchestriert Rotation von NEXTAUTH_SECRET
  (Prod + Staging) und DB-Passwort ('menucard'-User). Backup, atomares
  .env-Rewrite, pm2 restart, automatischer Rollback bei Fehler.
- phase1-secrets-rotation.ps1: lokaler SSH-Launcher mit -DryRun, Yes,
  externem Health-Check nach der Rotation.

Priority-1-Scope: NEXTAUTH + DB-PW. Admin-Passwort, GitHub-Key, S3 usw.
folgen in spaeteren Rotation-Laeufen.
"@

    & git commit -m $msg
    if ($LASTEXITCODE -ne 0) { ErrLine "git commit fehlgeschlagen."; exit 1 }

    & git push origin main
    if ($LASTEXITCODE -ne 0) { ErrLine "git push fehlgeschlagen."; exit 1 }
}
Ok "Lokal fertig"

# ----------------------------------------------------------------------
# 2. Server: pull + chmod + Smoke
# ----------------------------------------------------------------------
Step "2/3" "Server: pull + chmod + Dry-Run"

$remoteCmd = @"
set -e
cd $AppDir
echo 'Vorher HEAD:' \$(git rev-parse --short HEAD)
git pull --ff-only origin main
echo 'Nachher HEAD:' \$(git rev-parse --short HEAD)
chmod +x scripts/rotate-secrets.sh
ls -l scripts/rotate-secrets.sh
echo ''
echo '--- Dry-Run ---'
bash scripts/rotate-secrets.sh --dry-run
echo ''
echo 'Bootstrap OK'
"@

ssh -t "$ServerUser@$ServerIP" $remoteCmd
if ($LASTEXITCODE -ne 0) {
    ErrLine "Server-Bootstrap fehlgeschlagen."
    exit 1
}
Ok "Server-Setup fertig"

# ----------------------------------------------------------------------
# 3. Hinweis
# ----------------------------------------------------------------------
Step "3/3" "Naechster Schritt"
Write-Host ""
Write-Host "Die Werkzeuge liegen jetzt auf dem Server." -ForegroundColor Gray
Write-Host "Fuer die eigentliche Rotation:" -ForegroundColor Gray
Write-Host ""
Write-Host "  .\phase1-secrets-rotation.ps1 -DryRun   # Plan im Detail" -ForegroundColor Yellow
Write-Host "  .\phase1-secrets-rotation.ps1           # Rotation live durchfuehren" -ForegroundColor Yellow
Write-Host ""
Write-Host "Beachten Sie: Nach der Rotation muessen Sie sich einmal neu einloggen." -ForegroundColor Cyan
Write-Host ""
