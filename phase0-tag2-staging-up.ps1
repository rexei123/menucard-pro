# ============================================================================
# Phase 0 Tag 2 Schritt 2: Staging PM2 + Nginx + Basic-Auth (+ optional SSL)
#
# Flags:
#   -EnableSsl    : DNS-Check + certbot --nginx + HTTPS-Smoke
#   (default)     : HTTP-only, Zugriff via SSH-Tunnel / Host-Header
# ============================================================================
param(
    [switch]$EnableSsl
)

$ServerIP   = "178.104.138.177"
$ServerUser = "root"

Write-Host ""
if ($EnableSsl) {
    Write-Host "=== Staging Schritt 2 (mit SSL): PM2 + Nginx + Basic-Auth + Let's Encrypt ===" -ForegroundColor Cyan
    Write-Host "Voraussetzung: DNS A-Record staging.menu.hotel-sonnblick.at -> $ServerIP" -ForegroundColor Yellow
} else {
    Write-Host "=== Staging Schritt 2 (HTTP-only): PM2 + Nginx + Basic-Auth ===" -ForegroundColor Cyan
    Write-Host "Kein SSL. Zugriff via SSH-Tunnel auf http://127.0.0.1:3001" -ForegroundColor Yellow
    Write-Host "SSL wird spaeter nachgezogen (DNS noch nicht gesetzt)." -ForegroundColor Yellow
}
Write-Host ""

$scriptLocal  = ".\phase0-tag2-staging-up.sh"
$scriptRemote = "/root/phase0-tag2-staging-up.sh"

if (-not (Test-Path $scriptLocal)) {
    Write-Host "phase0-tag2-staging-up.sh fehlt lokal." -ForegroundColor Red
    exit 1
}

# Upload mit LF-Normalisierung (Windows -> Linux)
Write-Host "[1] Upload Bootstrap-Script..." -ForegroundColor Yellow
$content = Get-Content -Raw $scriptLocal
$lf = $content -replace "`r`n", "`n"
$tempPath = Join-Path $env:TEMP "phase0-tag2-staging-up.sh"
[IO.File]::WriteAllText($tempPath, $lf)
scp $tempPath "${ServerUser}@${ServerIP}:${scriptRemote}"
if ($LASTEXITCODE -ne 0) { Write-Host "scp fehlgeschlagen." -ForegroundColor Red; exit 1 }

# Ausfuehren
Write-Host "[2] Ausfuehren..." -ForegroundColor Yellow
Write-Host ""
if ($EnableSsl) {
    ssh -t "${ServerUser}@${ServerIP}" "chmod +x ${scriptRemote} && ENABLE_SSL=1 bash ${scriptRemote}"
} else {
    ssh -t "${ServerUser}@${ServerIP}" "chmod +x ${scriptRemote} && bash ${scriptRemote}"
}
$rc = $LASTEXITCODE

Write-Host ""
if ($rc -eq 0) {
    if ($EnableSsl) {
        Write-Host "Schritt 2 (SSL) OK. Staging ist extern erreichbar:" -ForegroundColor Green
        Write-Host "  https://staging.menu.hotel-sonnblick.at" -ForegroundColor Green
    } else {
        Write-Host "Schritt 2 (HTTP) OK. Staging laeuft unter PM2." -ForegroundColor Green
        Write-Host ""
        Write-Host "Zugriff im Browser via SSH-Tunnel:" -ForegroundColor Yellow
        Write-Host "  ssh -L 3001:127.0.0.1:3001 root@$ServerIP" -ForegroundColor Yellow
        Write-Host "  -> http://127.0.0.1:3001" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Sobald DNS-Record gesetzt ist, SSL nachziehen mit:" -ForegroundColor Yellow
        Write-Host "  .\phase0-tag2-staging-up.ps1 -EnableSsl" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Basic-Auth-Zugangsdaten stehen oben in der Ausgabe - bitte im Passwort-Manager sichern!" -ForegroundColor Yellow
} else {
    Write-Host "Schritt 2 fehlgeschlagen (Exit $rc)." -ForegroundColor Red
}
