# ============================================================================
# PHASE 0 TAG 3 SCHRITT 1 - PLAYWRIGHT-SMOKE-SUITE (Launcher)
# ============================================================================
# Startet die Playwright-E2E-Suite gegen die Staging-Instanz.
#
# Voraussetzung: SSH-Tunnel in EINER eigenen PowerShell offen:
#     ssh -N -L 3001:127.0.0.1:3001 root@178.104.138.177
#
# Dadurch wird Basic-Auth umgangen und direkt gegen den PM2-Prozess getestet.
#
# Ablauf:
#   1. Dependencies pruefen/installieren (@playwright/test + chromium)
#   2. Tunnel-Reachability pruefen (http://127.0.0.1:3001)
#   3. Admin-Credentials vom Server ziehen
#   4. npm run test:e2e ausfuehren
#   5. Bei Fehlern HTML-Report oeffnen
# ============================================================================

param(
    [switch]$Ui,
    [switch]$Headed,
    [string]$ServerIP    = "178.104.138.177",
    [string]$ServerUser  = "root",
    [string]$BaseUrl     = "http://127.0.0.1:3001",
    [string]$TenantSlug  = "hotel-sonnblick"
)

$ErrorActionPreference = "Stop"

function Section($text) { Write-Host ""; Write-Host "=== $text ===" -ForegroundColor Cyan }
function Ok($text)      { Write-Host "OK  $text" -ForegroundColor Green }
function Warn($text)    { Write-Host "WARN $text" -ForegroundColor Yellow }
function Err($text)     { Write-Host "FEHLER $text" -ForegroundColor Red }

# ----------------------------------------------------------------------
# 0. Projekt-Root pruefen
# ----------------------------------------------------------------------
if (-not (Test-Path "package.json") -or -not (Test-Path "playwright.config.ts")) {
    Err "Bitte im MenuCard-Pro-Projektverzeichnis ausfuehren (package.json + playwright.config.ts erwartet)."
    exit 1
}

# ----------------------------------------------------------------------
# 1. Dependencies
# ----------------------------------------------------------------------
Section "1) Dependencies pruefen"

$pwLocal = Join-Path $PWD "node_modules\@playwright\test\package.json"
if (-not (Test-Path $pwLocal)) {
    Warn "@playwright/test fehlt - fuehre npm install aus ..."
    & npm install
    if ($LASTEXITCODE -ne 0) { Err "npm install fehlgeschlagen."; exit 1 }
}
Ok "@playwright/test vorhanden"

# Chromium installiert?
$pwCache = Join-Path $env:USERPROFILE "AppData\Local\ms-playwright"
$chromiumInstalled = (Test-Path $pwCache) -and ((Get-ChildItem $pwCache -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "chromium-*" }).Count -gt 0)
if (-not $chromiumInstalled) {
    Warn "Chromium-Browser fehlt - fuehre playwright install chromium aus ..."
    & npx playwright install chromium
    if ($LASTEXITCODE -ne 0) { Err "playwright install fehlgeschlagen."; exit 1 }
}
Ok "Chromium-Browser installiert"

# ----------------------------------------------------------------------
# 2. SSH-Tunnel pruefen
# ----------------------------------------------------------------------
Section "2) SSH-Tunnel pruefen ($BaseUrl)"

try {
    $probe = Invoke-WebRequest -Uri $BaseUrl -UseBasicParsing -TimeoutSec 3 -MaximumRedirection 0 -ErrorAction Stop
    $code = [int]$probe.StatusCode
} catch [System.Net.WebException] {
    $code = 0
    if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
} catch {
    $code = 0
}

if ($code -lt 200 -or $code -ge 500) {
    Err "Kein Tunnel auf $BaseUrl erreichbar (Code: $code)."
    Write-Host ""
    Write-Host "  Bitte in einer separaten PowerShell oeffnen und offen lassen:" -ForegroundColor Yellow
    Write-Host "    ssh -N -L 3001:127.0.0.1:3001 $ServerUser@$ServerIP" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
Ok "Tunnel erreichbar (HTTP $code)"

# ----------------------------------------------------------------------
# 3. Admin-Credentials vom Server ziehen
# ----------------------------------------------------------------------
Section "3) Staging-Admin-Credentials vom Server laden"

$credsRaw = & ssh "$ServerUser@$ServerIP" "cat /root/.secrets/staging-admin-creds.txt 2>/dev/null || true"
if ($LASTEXITCODE -ne 0 -or -not $credsRaw) {
    Err "Konnte /root/.secrets/staging-admin-creds.txt nicht lesen."
    exit 1
}

# Erwartetes Format (aus seed-staging-from-prod.sh):
#   EMAIL=admin@hotel-sonnblick.at
#   PASSWORD=<klartext>
$adminEmail = $null
$adminPass  = $null
foreach ($line in ($credsRaw -split "`n")) {
    $line = $line.Trim()
    if ($line -match '^EMAIL=(.+)$')         { $adminEmail = $Matches[1] }
    elseif ($line -match '^PASSWORD=(.+)$')  { $adminPass  = $Matches[1] }
    elseif ($line -match '^ADMIN_EMAIL=(.+)$') { $adminEmail = $Matches[1] }
    elseif ($line -match '^ADMIN_PASS=(.+)$')  { $adminPass  = $Matches[1] }
}

if (-not $adminEmail -or -not $adminPass) {
    Err "EMAIL / PASSWORD nicht in /root/.secrets/staging-admin-creds.txt gefunden."
    Write-Host "Inhalt:" -ForegroundColor Gray
    Write-Host $credsRaw -ForegroundColor Gray
    exit 1
}
Ok "Credentials geladen fuer $adminEmail"

# ----------------------------------------------------------------------
# 4. Playwright-Suite starten
# ----------------------------------------------------------------------
Section "4) Playwright-Suite starten"

$env:BASE_URL           = $BaseUrl
$env:ADMIN_EMAIL        = $adminEmail
$env:ADMIN_PASS         = $adminPass
$env:PUBLIC_TENANT_SLUG = $TenantSlug

Write-Host "  BASE_URL           = $BaseUrl" -ForegroundColor Gray
Write-Host "  PUBLIC_TENANT_SLUG = $TenantSlug" -ForegroundColor Gray
Write-Host "  ADMIN_EMAIL        = $adminEmail" -ForegroundColor Gray
Write-Host "  ADMIN_PASS         = ***" -ForegroundColor Gray
Write-Host ""

if ($Ui) {
    & npm run test:e2e:ui
} elseif ($Headed) {
    & npm run test:e2e:headed
} else {
    & npm run test:e2e
}
$testExit = $LASTEXITCODE

# ----------------------------------------------------------------------
# 5. Zusammenfassung / Report
# ----------------------------------------------------------------------
Section "5) Zusammenfassung"

if ($testExit -eq 0) {
    Ok "Alle Playwright-Tests bestanden."
    Write-Host ""
    Write-Host "  Report:  .\playwright-report\index.html" -ForegroundColor Gray
    exit 0
}

Err "Playwright-Suite fehlgeschlagen (Exit $testExit)."
$report = Join-Path $PWD "playwright-report\index.html"
if (Test-Path $report) {
    Write-Host "  Oeffne HTML-Report ..." -ForegroundColor Yellow
    Start-Process $report
}
exit $testExit
