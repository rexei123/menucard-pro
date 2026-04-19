# ============================================================================
# PHASE 1 - SECRETS ROTATION (Launcher)
# ============================================================================
# Rotiert die Priority-1-Secrets von MenuCard Pro (Prod + Staging):
#   - NEXTAUTH_SECRET Prod  (neu, zufaellig, 48 Byte base64)
#   - NEXTAUTH_SECRET Staging (neu, unabhaengig)
#   - DB-Passwort fuer den 'menucard'-PG-User (+ synchroner .env-Update)
#
# Ruft /var/www/menucard-pro/scripts/rotate-secrets.sh via SSH auf.
# Das Script ist idempotent-ish (immer voller Backup + Rollback bei Fehler).
#
# Ablauf (durch das Server-Script):
#   1. Discovery der aktuellen Werte (maskiert)
#   2. Backup beider .env nach /var/backups/menucard-pro/secrets-pre-rotation-<ts>
#   3. ALTER USER menucard WITH PASSWORD '<neu>' (als superuser via psql)
#   4. beide .env atomar neu schreiben
#   5. pm2 restart beide Apps mit --update-env
#   6. curl /api/health verifiziert Prod + Staging
#
# Bei Fehler: automatischer Rollback (.env restore + DB-Passwort zurueck).
#
# Voraussetzung: Rotation-Script muss bereits auf dem Server liegen
#                (per git push + deploy). Dieses Script prueft das ab.
#
# Aufruf:
#   .\phase1-secrets-rotation.ps1 -DryRun     # nur Plan anzeigen
#   .\phase1-secrets-rotation.ps1             # interaktive Bestaetigung am Server
#   .\phase1-secrets-rotation.ps1 -Yes        # ohne Rueckfragen (Vorsicht)
# ============================================================================

param(
    [switch]$Yes,
    [switch]$DryRun,
    [string]$ServerIP   = "178.104.138.177",
    [string]$ServerUser = "root"
)

# Native Git/SSH-Tools schreiben oft auf stderr -> nicht stoppen
$ErrorActionPreference = 'Continue'

function Section($t)  { Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Cyan }
function Ok($t)       { Write-Host "OK   $t" -ForegroundColor Green }
function Warn($t)     { Write-Host "WARN $t" -ForegroundColor Yellow }
function ErrLine($t)  { Write-Host "FAIL $t" -ForegroundColor Red }
function Step($n,$t)  { Write-Host ""; Write-Host "[$n] $t" -ForegroundColor Yellow }

$RemoteScript = "/var/www/menucard-pro/scripts/rotate-secrets.sh"

Section "Secrets-Rotation"

# ----------------------------------------------------------------------
# 1. Pruefen ob das Server-Script da ist (muss vorher committed + deployed sein)
# ----------------------------------------------------------------------
Step "1" "Server-Script vorhanden?"
$check = ssh "$ServerUser@$ServerIP" "test -x $RemoteScript && echo YES || echo MISSING"
if ($LASTEXITCODE -ne 0) {
    ErrLine "SSH zum Server fehlgeschlagen."
    exit 1
}
$check = ($check | Out-String).Trim()
if ($check -ne "YES") {
    ErrLine "Rotation-Script fehlt auf dem Server: $RemoteScript"
    Warn "Bitte zuerst:"
    Warn "  git add scripts/rotate-secrets.sh phase1-secrets-rotation.ps1"
    Warn "  git commit -m 'Phase 1: Secrets-Rotation (Launcher + Server-Script)'"
    Warn "  git push"
    Warn "  ssh $ServerUser@$ServerIP 'cd /var/www/menucard-pro && git pull --ff-only origin main && chmod +x scripts/rotate-secrets.sh'"
    exit 1
}
Ok "Script vorhanden und ausfuehrbar"

# ----------------------------------------------------------------------
# 2. Dry-Run
# ----------------------------------------------------------------------
if ($DryRun) {
    Step "2" "Remote Dry-Run"
    ssh -t "$ServerUser@$ServerIP" "bash $RemoteScript --dry-run"
    exit $LASTEXITCODE
}

# ----------------------------------------------------------------------
# 3. Lokale Sicherheitsabfrage
# ----------------------------------------------------------------------
if (-not $Yes) {
    Write-Host ""
    Warn "Diese Aktion aendert LIVE auf Produktion:"
    Write-Host "  - NEXTAUTH_SECRET Prod + Staging (alle Admin-Sessions weg)" -ForegroundColor Gray
    Write-Host "  - DB-Passwort 'menucard' in PostgreSQL + beiden .env-Dateien" -ForegroundColor Gray
    Write-Host "  - pm2 restart menucard-pro + menucard-pro-staging" -ForegroundColor Gray
    Write-Host ""
    $a = Read-Host "Rotation jetzt durchfuehren? (y/n)"
    if ($a -ne 'y' -and $a -ne 'Y') {
        Warn "Abbruch durch User."
        exit 0
    }
}

# ----------------------------------------------------------------------
# 4. Remote-Ausfuehrung
# ----------------------------------------------------------------------
Step "2" "Rotation ausfuehren (Remote)"
Write-Host ""

$flags = "--yes"
ssh -t "$ServerUser@$ServerIP" "bash $RemoteScript $flags"
$sshExit = $LASTEXITCODE

Write-Host ""

if ($sshExit -ne 0) {
    ErrLine "Rotation fehlgeschlagen (Exit $sshExit)."
    Warn "Log auf Server:     /var/log/menucard-secrets-rotation.log"
    Warn "Backup auf Server:  /var/backups/menucard-pro/secrets-pre-rotation-<ts>/"
    Warn "Das Server-Script hat einen automatischen Rollback versucht."
    exit $sshExit
}

Ok "Rotation durchgelaufen."

# ----------------------------------------------------------------------
# 5. Externer Smoke-Test von aussen
# ----------------------------------------------------------------------
Step "3" "Externer Health-Check (von Ihrem Rechner)"

Start-Sleep -Seconds 2

try {
    $resp = Invoke-WebRequest -Uri "https://menu.hotel-sonnblick.at/api/health" `
                              -UseBasicParsing -TimeoutSec 15
    if ($resp.StatusCode -eq 200) {
        Ok "menu.hotel-sonnblick.at/api/health -> HTTP 200"
        Write-Host $resp.Content -ForegroundColor Green
    } else {
        Warn "HTTP $($resp.StatusCode)"
    }
} catch {
    ErrLine "Extern nicht erreichbar: $($_.Exception.Message)"
    Warn "Evtl. Cache/Delay - in 30s nochmal versuchen:"
    Warn "  (Invoke-WebRequest 'https://menu.hotel-sonnblick.at/api/health' -UseBasicParsing).Content"
}

# ----------------------------------------------------------------------
# 6. Fertig
# ----------------------------------------------------------------------
Section "FERTIG"
Write-Host ""
Ok "Secrets-Rotation abgeschlossen."
Write-Host ""
Write-Host "Wichtig:" -ForegroundColor Yellow
Write-Host "  - Admin-Session ist ungueltig. Bitte einmal neu einloggen:" -ForegroundColor Gray
Write-Host "    https://menu.hotel-sonnblick.at/auth/login" -ForegroundColor Gray
Write-Host "  - Die neuen Secrets stehen ausschliesslich in den .env-Dateien" -ForegroundColor Gray
Write-Host "    auf dem Server. Es gibt KEIN lokales File-Kopie." -ForegroundColor Gray
Write-Host "  - Backup der alten Secrets:" -ForegroundColor Gray
Write-Host "    ssh $ServerUser@$ServerIP 'ls -la /var/backups/menucard-pro/secrets-pre-rotation-*'" -ForegroundColor Gray
Write-Host ""
