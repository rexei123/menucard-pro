# ============================================================================
# PHASE 1 / PRIORITY 2A — Admin-Passwort Rotation (Launcher)
# ============================================================================
# Rotiert das Admin-Passwort fuer admin@hotel-sonnblick.at in:
#   - Prod-DB     menucard_pro
#   - Staging-DB  menucard_pro_staging
#   - /root/.secrets/staging-admin-creds.txt (Klartext fuer Playwright)
#
# Ruft scripts/rotate-admin-password.sh auf dem Server auf. Falls das Script
# dort noch nicht liegt, wird es vorher automatisch committed + gepusht +
# auf dem Server gepullt (Auto-Bootstrap).
#
# Aufruf:
#   .\phase1-priority2a-admin-pw.ps1 -DryRun     # Plan zeigen
#   .\phase1-priority2a-admin-pw.ps1             # interaktive Bestaetigung
#   .\phase1-priority2a-admin-pw.ps1 -Yes        # ohne Rueckfrage
# ============================================================================

param(
    [switch]$Yes,
    [switch]$DryRun,
    [string]$ServerIP   = "178.104.138.177",
    [string]$ServerUser = "root"
)

$ErrorActionPreference = 'Continue'

function Section($t) { Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Cyan }
function Ok($t)      { Write-Host "OK   $t" -ForegroundColor Green }
function Warn($t)    { Write-Host "WARN $t" -ForegroundColor Yellow }
function ErrLine($t) { Write-Host "FAIL $t" -ForegroundColor Red }
function Step($n,$t) { Write-Host ""; Write-Host "[$n] $t" -ForegroundColor Yellow }

$RemoteScript  = "/var/www/menucard-pro/scripts/rotate-admin-password.sh"
$LocalScript   = "scripts/rotate-admin-password.sh"
$LocalLauncher = "phase1-priority2a-admin-pw.ps1"

Section "Admin-Passwort Rotation"

# ----------------------------------------------------------------------
# 1. Pruefen, ob das Server-Script schon existiert; falls nicht: Auto-Bootstrap
# ----------------------------------------------------------------------
Step "1" "Server-Script vorhanden?"
$check = ssh "$ServerUser@$ServerIP" "test -x $RemoteScript && echo YES || echo MISSING"
if ($LASTEXITCODE -ne 0) { ErrLine "SSH zum Server fehlgeschlagen."; exit 1 }
$check = ($check | Out-String).Trim()

if ($check -ne "YES") {
    Warn "$RemoteScript fehlt - Auto-Bootstrap laeuft."

    Step "1a" "Lokal committen + pushen"
    & git add --chmod=+x $LocalScript
    if ($LASTEXITCODE -ne 0) { ErrLine "git add --chmod=+x fehlgeschlagen."; exit 1 }
    & git add $LocalLauncher
    if ($LASTEXITCODE -ne 0) { ErrLine "git add Launcher fehlgeschlagen."; exit 1 }

    $staged = & git diff --cached --name-only
    if (-not $staged) {
        Warn "Nichts zu committen (Dateien bereits im Repo) - gehe davon aus, dass nur Server-Pull noetig ist."
    } else {
        Write-Host "  Zu committen:" -ForegroundColor Gray
        $staged | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

        $msg = @"
Phase 1 Priority-2A: Admin-Passwort-Rotation (Server-Script + Launcher)

- scripts/rotate-admin-password.sh: bcryptjs-basierte Rotation
  des admin@hotel-sonnblick.at Passworts in beiden DBs + Creds-File.
  Backup, DB-Updates mit Rollback bei Fehler, Dry-Run-Modus.
- phase1-priority2a-admin-pw.ps1: lokaler SSH-Launcher mit
  Auto-Bootstrap und -DryRun / -Yes Flags.
"@
        & git commit -m $msg
        if ($LASTEXITCODE -ne 0) { ErrLine "git commit fehlgeschlagen."; exit 1 }
        & git push origin main
        if ($LASTEXITCODE -ne 0) { ErrLine "git push fehlgeschlagen."; exit 1 }
    }
    Ok "Lokal committed + gepusht"

    Step "1b" "Server: pull + chmod +x"
    ssh "$ServerUser@$ServerIP" "cd /var/www/menucard-pro && git pull --ff-only origin main && chmod +x $LocalScript && ls -l $LocalScript"
    if ($LASTEXITCODE -ne 0) { ErrLine "Server-Bootstrap fehlgeschlagen."; exit 1 }
    Ok "Server hat Script bezogen"
} else {
    Ok "Script auf dem Server vorhanden"
}

# ----------------------------------------------------------------------
# 2. Dry-Run oder Live
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
    Write-Host "  - User.passwordHash von admin@hotel-sonnblick.at" -ForegroundColor Gray
    Write-Host "    in Prod-DB menucard_pro UND Staging-DB menucard_pro_staging" -ForegroundColor Gray
    Write-Host "  - /root/.secrets/staging-admin-creds.txt (Klartext)" -ForegroundColor Gray
    Write-Host "  - Bestehende Browser-Session des Admins wird ungueltig." -ForegroundColor Gray
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
ssh -t "$ServerUser@$ServerIP" "bash $RemoteScript --yes"
$sshExit = $LASTEXITCODE
Write-Host ""

if ($sshExit -ne 0) {
    ErrLine "Rotation fehlgeschlagen (Exit $sshExit)."
    Warn "Log auf Server:    /var/log/menucard-admin-pw-rotation.log"
    Warn "Backup auf Server: /var/backups/menucard-pro/admin-pw-pre-rotation-<ts>/"
    Warn "Das Server-Script hat einen automatischen Rollback versucht."
    exit $sshExit
}

Ok "Rotation durchgelaufen."

# ----------------------------------------------------------------------
# 5. Login-Smoke-Test mit neuem Passwort (optional, gegen Staging)
# ----------------------------------------------------------------------
Step "3" "Kurz-Check: Staging-Creds-File lesbar?"
$credsLines = ssh "$ServerUser@$ServerIP" "cat /root/.secrets/staging-admin-creds.txt 2>/dev/null | head -3"
if ($LASTEXITCODE -eq 0 -and $credsLines -match 'PASSWORD=') {
    Ok "Staging-Creds-File neu geschrieben (Inhalt oben in der Ausgabe sichtbar)."
} else {
    Warn "Staging-Creds-File konnte nicht verifiziert werden."
}

# ----------------------------------------------------------------------
# 6. Fertig
# ----------------------------------------------------------------------
Section "FERTIG"
Write-Host ""
Ok "Admin-Passwort wurde auf Prod + Staging + Creds-File rotiert."
Write-Host ""
Write-Host "Wichtig:" -ForegroundColor Yellow
Write-Host "  - Neues Passwort steht in der Remote-Ausgabe oben (Zeile: 'Passwort:')." -ForegroundColor Gray
Write-Host "    Bitte in Password-Manager uebernehmen und Terminal-Puffer leeren." -ForegroundColor Gray
Write-Host "  - Neu einloggen:  https://menu.hotel-sonnblick.at/auth/login" -ForegroundColor Gray
Write-Host "  - Backup alter Hashes + altes Creds-File:" -ForegroundColor Gray
Write-Host "    ssh $ServerUser@$ServerIP 'ls -la /var/backups/menucard-pro/admin-pw-pre-rotation-*'" -ForegroundColor Gray
Write-Host ""
