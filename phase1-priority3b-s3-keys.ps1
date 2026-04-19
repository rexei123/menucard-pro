# ============================================================================
# PHASE 1 / PRIORITY 3B — S3-Keys Rotation (Launcher)
# ============================================================================
# Fragt lokal nach neuem S3_ACCESS_KEY und S3_SECRET_KEY und uebergibt sie
# per Pipe an das Server-Script (nicht per CLI-Arg, damit sie nicht in
# bash-history oder ps aux landen).
#
# Pre-Arbeit im S3-Provider-UI (VOR dem Live-Lauf):
#   1. Neuen Access-Key + Secret-Key erzeugen
#   2. Alten Access-Key NOCH NICHT deaktivieren (erst nach erfolgreichem Lauf)
#
# Aufruf:
#   .\phase1-priority3b-s3-keys.ps1 -DryRun
#   .\phase1-priority3b-s3-keys.ps1           # interaktive Bestaetigung
#   .\phase1-priority3b-s3-keys.ps1 -Yes      # ohne Rueckfrage
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

$RemoteScript  = "/var/www/menucard-pro/scripts/rotate-s3-keys.sh"
$LocalScript   = "scripts/rotate-s3-keys.sh"
$LocalLauncher = "phase1-priority3b-s3-keys.ps1"

Section "S3-Keys Rotation"

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
    & git commit -m "Phase 1 Priority-3B: S3-Keys Rotation (Server-Script + Launcher)"
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
    ssh "$ServerUser@$ServerIP" "bash $RemoteScript --dry-run < /dev/null"
    exit $LASTEXITCODE
}

# ----------------------------------------------------------------------
# Neue Keys lokal einlesen
# ----------------------------------------------------------------------
Step "2" "Neue S3-Keys lokal einlesen"
Write-Host "  Pre-Arbeit: Neuer Keypair im S3-Provider-UI erzeugt?" -ForegroundColor Gray
Write-Host ""
$newAcc = Read-Host "Neuer S3_ACCESS_KEY"
$newSecSecure = Read-Host "Neuer S3_SECRET_KEY (Eingabe maskiert)" -AsSecureString

if (-not $newAcc) { ErrLine "Access-Key leer - Abbruch."; exit 1 }
if (-not $newSecSecure -or $newSecSecure.Length -eq 0) { ErrLine "Secret-Key leer - Abbruch."; exit 1 }

# SecureString -> Klartext (kurzlebig, nur im Speicher der PS-Session)
$bstr    = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($newSecSecure)
$newSec  = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

Ok "Keys im Speicher (Access-Key laenge: $($newAcc.Length), Secret-Key laenge: $($newSec.Length))"

if (-not $Yes) {
    Write-Host ""
    Warn "Diese Aktion:"
    Write-Host "  - Ueberschreibt S3_ACCESS_KEY + S3_SECRET_KEY in beiden .env" -ForegroundColor Gray
    Write-Host "  - pm2 restart fuer Prod + Staging" -ForegroundColor Gray
    Write-Host "  - Verify via aws s3 ls (falls aws CLI auf Server installiert)" -ForegroundColor Gray
    Write-Host ""
    $a = Read-Host "Rotation jetzt durchfuehren? (y/n)"
    if ($a -ne 'y' -and $a -ne 'Y') {
        Warn "Abbruch durch User."
        exit 0
    }
}

# ----------------------------------------------------------------------
# Keys per Pipe an Remote-Script
# ----------------------------------------------------------------------
Step "3" "Rotation ausfuehren (Remote)"
$payload = "$newAcc`n$newSec`n"

# ssh OHNE -t, damit stdin durchgereicht wird
$payload | ssh "$ServerUser@$ServerIP" "bash $RemoteScript --yes"
$sshExit = $LASTEXITCODE

# Klartext-Secret aus Speicher ueberschreiben
$newSec    = $null
$payload   = $null
[System.GC]::Collect()

if ($sshExit -ne 0) {
    ErrLine "Rotation fehlgeschlagen (Exit $sshExit)."
    Warn "Log: /var/log/menucard-s3-rotation.log"
    exit $sshExit
}

Section "FERTIG"
Write-Host ""
Ok "S3-Keys rotiert."
Write-Host "Naechster Schritt im S3-Provider-UI: Alten Access-Key loeschen." -ForegroundColor Yellow
