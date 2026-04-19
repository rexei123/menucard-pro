# ============================================================================
# PHASE 1 / PRIORITY 3A — GitHub Deploy-Key Rotation (Launcher)
# ============================================================================
# Rotiert /root/.ssh/id_ed25519_github_menucard auf dem Server.
# User bekommt den neuen Public-Key in der Terminal-Ausgabe - muss ihn dann
# in GitHub unter Settings > Deploy keys einhaengen und den alten entfernen.
#
# Aufruf:
#   .\phase1-priority3a-github-key.ps1 -DryRun
#   .\phase1-priority3a-github-key.ps1           # interaktive Bestaetigung
#   .\phase1-priority3a-github-key.ps1 -Yes      # ohne Rueckfrage
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

$RemoteScript  = "/var/www/menucard-pro/scripts/rotate-github-deploykey.sh"
$LocalScript   = "scripts/rotate-github-deploykey.sh"
$LocalLauncher = "phase1-priority3a-github-key.ps1"

Section "GitHub Deploy-Key Rotation"

Step "1" "Always-Sync: Lokales Script mit Server abgleichen"
& git add $LocalScript $LocalLauncher
if ($LASTEXITCODE -ne 0) { ErrLine "git add fehlgeschlagen."; exit 1 }
& git update-index --chmod=+x $LocalScript 2>$null

$staged = & git diff --cached --name-only
if (-not $staged) {
    Ok "Keine Aenderungen zu committen."
} else {
    Write-Host "  Zu committen:" -ForegroundColor Gray
    $staged | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    & git commit -m "Phase 1 Priority-3A: GitHub Deploy-Key Rotation (Server-Script + Launcher)"
    if ($LASTEXITCODE -ne 0) { ErrLine "git commit fehlgeschlagen."; exit 1 }
    & git push origin main
    if ($LASTEXITCODE -ne 0) { ErrLine "git push fehlgeschlagen."; exit 1 }
    Ok "Lokal committed + gepusht"
}

Step "1b" "Server: cleanup + pull + chmod +x"
$syncCmd = "cd /var/www/menucard-pro && " + `
           "git checkout -- $LocalScript 2>/dev/null || true; " + `
           "git pull --ff-only origin main && " + `
           "chmod +x $LocalScript && ls -l $LocalScript"
ssh "$ServerUser@$ServerIP" $syncCmd
if ($LASTEXITCODE -ne 0) { ErrLine "Server-Sync fehlgeschlagen."; exit 1 }
Ok "Server hat aktuelle Version"

if ($DryRun) {
    Step "2" "Remote Dry-Run"
    ssh -t "$ServerUser@$ServerIP" "bash $RemoteScript --dry-run"
    exit $LASTEXITCODE
}

if (-not $Yes) {
    Write-Host ""
    Warn "Diese Aktion:"
    Write-Host "  - Erzeugt neues ed25519-Keypair in /root/.ssh/" -ForegroundColor Gray
    Write-Host "  - Zeigt Public-Key - Sie muessen ihn in GitHub eintragen" -ForegroundColor Gray
    Write-Host "    (https://github.com/rexei123/menucard-pro/settings/keys)" -ForegroundColor Gray
    Write-Host "  - Testet SSH-Auth gegen github.com" -ForegroundColor Gray
    Write-Host "  - Swappt den Key atomar" -ForegroundColor Gray
    Write-Host ""
    $a = Read-Host "Rotation jetzt durchfuehren? (y/n)"
    if ($a -ne 'y' -and $a -ne 'Y') {
        Warn "Abbruch durch User."
        exit 0
    }
}

Step "2" "Rotation ausfuehren (Remote, interaktiv)"
Write-Host ""
# ssh -t ist fuer die interaktive read-Pause im Script wichtig
ssh -t "$ServerUser@$ServerIP" "bash $RemoteScript --yes"
$sshExit = $LASTEXITCODE

Write-Host ""
if ($sshExit -ne 0) {
    ErrLine "Rotation fehlgeschlagen (Exit $sshExit)."
    Warn "Log: /var/log/menucard-github-key-rotation.log"
    Warn "Backup: /var/backups/menucard-pro/github-deploykey-pre-rotation-<ts>/"
    exit $sshExit
}

Section "FERTIG"
Write-Host ""
Ok "GitHub Deploy-Key rotiert."
Write-Host "Naechster Schritt in GitHub: Alten Deploy-Key loeschen." -ForegroundColor Yellow
Write-Host "  https://github.com/rexei123/menucard-pro/settings/keys" -ForegroundColor Gray
