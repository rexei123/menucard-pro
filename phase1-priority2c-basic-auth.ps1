# ============================================================================
# PHASE 1 / PRIORITY 2C — Staging Nginx Basic-Auth Rotation (Launcher)
# ============================================================================
# Rotiert das Basic-Auth-Passwort (User 'sonnblick') fuer das Staging-VHost.
# Aendert:
#   - /etc/nginx/.htpasswd-staging  (nur Zeile 'sonnblick:...')
#   - /root/.secrets/staging-basic-auth.txt (Klartext)
#
# Ruft scripts/rotate-staging-basic-auth.sh auf dem Server auf. Vor jedem Lauf
# werden lokale Aenderungen am Script+Launcher automatisch committed, gepusht
# und auf dem Server gepullt (Always-Sync).
#
# Aufruf:
#   .\phase1-priority2c-basic-auth.ps1 -DryRun     # Plan zeigen
#   .\phase1-priority2c-basic-auth.ps1             # interaktive Bestaetigung
#   .\phase1-priority2c-basic-auth.ps1 -Yes        # ohne Rueckfrage
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

$RemoteScript  = "/var/www/menucard-pro/scripts/rotate-staging-basic-auth.sh"
$LocalScript   = "scripts/rotate-staging-basic-auth.sh"
$LocalLauncher = "phase1-priority2c-basic-auth.ps1"

Section "Staging Nginx Basic-Auth Rotation"

# ----------------------------------------------------------------------
# 1. Always-Sync: commit (falls noetig) + push + server pull
# ----------------------------------------------------------------------
Step "1" "Always-Sync: Lokales Script mit Server abgleichen"

# Reihenfolge wichtig: erst add (damit Datei im Index), dann chmod-Bit setzen
& git add $LocalScript $LocalLauncher
if ($LASTEXITCODE -ne 0) { ErrLine "git add fehlgeschlagen."; exit 1 }
& git update-index --chmod=+x $LocalScript 2>$null

$staged = & git diff --cached --name-only
if (-not $staged) {
    Ok "Keine Aenderungen zu committen - Script im Repo aktuell."
} else {
    Write-Host "  Zu committen:" -ForegroundColor Gray
    $staged | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

    $msg = @"
Phase 1 Priority-2C: Staging Basic-Auth-Rotation (Server-Script + Launcher)

- scripts/rotate-staging-basic-auth.sh: htpasswd -b basierte Rotation
  fuer User 'sonnblick' in /etc/nginx/.htpasswd-staging.
  Backup, nginx -t + reload, Verify via curl, Rollback bei Fehler.
- phase1-priority2c-basic-auth.ps1: lokaler SSH-Launcher mit
  Always-Sync und -DryRun / -Yes Flags.
"@
    & git commit -m $msg
    if ($LASTEXITCODE -ne 0) { ErrLine "git commit fehlgeschlagen."; exit 1 }
    & git push origin main
    if ($LASTEXITCODE -ne 0) { ErrLine "git push fehlgeschlagen."; exit 1 }
    Ok "Lokal committed + gepusht"
}

Step "1b" "Server: cleanup + pull + chmod +x"
# git checkout -- wirft lokale Script-Mode-Aenderungen weg (chmod-Diff vom
# vorherigen Lauf), macht damit pull --ff-only idempotent.
$syncCmd = "cd /var/www/menucard-pro && " + `
           "git checkout -- $LocalScript 2>/dev/null || true; " + `
           "git pull --ff-only origin main && " + `
           "chmod +x $LocalScript && ls -l $LocalScript"
ssh "$ServerUser@$ServerIP" $syncCmd
if ($LASTEXITCODE -ne 0) { ErrLine "Server-Sync fehlgeschlagen."; exit 1 }
Ok "Server hat aktuelle Version"

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
    Write-Host "  - /etc/nginx/.htpasswd-staging  (User 'sonnblick')" -ForegroundColor Gray
    Write-Host "  - /root/.secrets/staging-basic-auth.txt (Klartext)" -ForegroundColor Gray
    Write-Host "  - nginx reload" -ForegroundColor Gray
    Write-Host "  - Bestehende Browser-Basic-Auth-Sessions werden ungueltig." -ForegroundColor Gray
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
    Warn "Log auf Server:    /var/log/menucard-basic-auth-rotation.log"
    Warn "Backup auf Server: /var/backups/menucard-pro/basic-auth-pre-rotation-<ts>/"
    Warn "Das Server-Script hat einen automatischen Rollback versucht."
    exit $sshExit
}

Ok "Rotation durchgelaufen."

# ----------------------------------------------------------------------
# 5. Kurz-Check
# ----------------------------------------------------------------------
Step "3" "Kurz-Check: Creds-File lesbar?"
$credsLines = ssh "$ServerUser@$ServerIP" "cat /root/.secrets/staging-basic-auth.txt 2>/dev/null | head -4"
if ($LASTEXITCODE -eq 0 -and $credsLines -match 'PASSWORD=') {
    Ok "Creds-File neu geschrieben (Inhalt oben in der Ausgabe sichtbar)."
} else {
    Warn "Creds-File konnte nicht verifiziert werden."
}

# ----------------------------------------------------------------------
# 6. Fertig
# ----------------------------------------------------------------------
Section "FERTIG"
Write-Host ""
Ok "Staging Basic-Auth wurde rotiert."
Write-Host ""
Write-Host "Wichtig:" -ForegroundColor Yellow
Write-Host "  - Neues Passwort in der Remote-Ausgabe oben (Zeile: 'Passwort:')." -ForegroundColor Gray
Write-Host "    Bitte in Password-Manager uebernehmen und Terminal-Puffer leeren." -ForegroundColor Gray
Write-Host "  - Creds auslesen:  ssh $ServerUser@$ServerIP 'cat /root/.secrets/staging-basic-auth.txt'" -ForegroundColor Gray
Write-Host "  - Backup:          ssh $ServerUser@$ServerIP 'ls -la /var/backups/menucard-pro/basic-auth-pre-rotation-*'" -ForegroundColor Gray
Write-Host ""
