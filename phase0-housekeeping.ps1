# ============================================================================
# PHASE 0 HOUSEKEEPING - einmaliges Nachziehen offener Infra-Dateien
# ============================================================================
# Zieht alle waehrend Phase 0 lokal entstandenen Dateien nach:
#   - phase0-tag2-* / phase0-tag3-* Bootstrap-Scripts (ein- bis zweimalig)
#   - playwright.config.ts + tests/e2e/*  (Test-Gate-Infrastruktur)
#   - package.json / package-lock.json (Playwright-Dependencies)
#
# KEIN Test-Gate, KEIN Staging, KEIN Prod-Deploy - reine Code-Infra,
# die das Laufzeitverhalten nicht beruehrt. Commit landet direkt auf main.
# Prod-Deploy kommt beim naechsten Feature-Lauf mit ship.ps1 durch.
#
# Aufruf:
#   .\phase0-housekeeping.ps1          # interaktiv
#   .\phase0-housekeeping.ps1 -Yes     # ohne Rueckfrage
#   .\phase0-housekeeping.ps1 -DryRun  # nur Plan anzeigen
# ============================================================================

param(
    [switch]$Yes,
    [switch]$DryRun
)

# Native Git-Befehle schreiben ihre normale Ausgabe nach stderr. Mit
# ErrorActionPreference=Stop wuerde jede gitNormalZeile zum Script-Abbruch.
# Wir pruefen Fehler ausschliesslich ueber $LASTEXITCODE.
$ErrorActionPreference = 'Continue'

function Section($t) { Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Cyan }
function Ok($t)      { Write-Host "OK   $t" -ForegroundColor Green }
function Warn($t)    { Write-Host "WARN $t" -ForegroundColor Yellow }
function ErrLine($t) { Write-Host "FAIL $t" -ForegroundColor Red }
function Step($n,$t) { Write-Host ""; Write-Host "[$n] $t" -ForegroundColor Yellow }

# ----------------------------------------------------------------------
# 0. Plausibilitaet
# ----------------------------------------------------------------------
Section "Phase 0 Housekeeping"

if (-not (Test-Path "package.json") -or -not (Test-Path "ship.ps1")) {
    ErrLine "Bitte im MenuCard-Pro-Projektverzeichnis ausfuehren."
    exit 1
}

$currentBranch = (& git rev-parse --abbrev-ref HEAD).Trim()
Write-Host "  Branch: $currentBranch" -ForegroundColor Gray

if ($currentBranch -ne "main") {
    Warn "Nicht auf main. Wechsle bitte: git checkout main"
    exit 1
}

# Remote-Sync pruefen
& git fetch origin main *>$null
if ($LASTEXITCODE -ne 0) {
    ErrLine "git fetch fehlgeschlagen (Exit $LASTEXITCODE)."
    exit 1
}
$behind = (& git rev-list --count HEAD..origin/main).Trim()
if ([int]$behind -gt 0) {
    Warn "main ist $behind Commit(s) hinter origin. Bitte zuerst: git pull --ff-only"
    exit 1
}
Ok "main ist synchron mit origin"

# ----------------------------------------------------------------------
# 1. Einsammeln
# ----------------------------------------------------------------------
Step "1" "Offene Dateien ermitteln"

$porcelain = & git status --porcelain
if (-not $porcelain) {
    Ok "Working-Tree ist clean - nichts zu tun."
    exit 0
}

$files = @()
foreach ($line in $porcelain) {
    $path = ($line.Substring(3)).Trim()
    $files += $path
}

Write-Host "  Zu committen:" -ForegroundColor Gray
$files | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

# ----------------------------------------------------------------------
# 2. DRY-RUN
# ----------------------------------------------------------------------
if ($DryRun) {
    Section "DRY-RUN"
    Write-Host "  git add -A" -ForegroundColor Gray
    Write-Host "  git commit -m 'Phase 0 Housekeeping: ...'" -ForegroundColor Gray
    Write-Host "  git push origin main" -ForegroundColor Gray
    Ok "Dry-Run Ende"
    exit 0
}

# ----------------------------------------------------------------------
# 3. Bestaetigung
# ----------------------------------------------------------------------
if (-not $Yes) {
    $a = Read-Host "Alle oben gelisteten Dateien in 1 Commit auf main pushen? (y/n)"
    if ($a -ne 'y' -and $a -ne 'Y') {
        Warn "Abbruch durch User."
        exit 0
    }
}

# ----------------------------------------------------------------------
# 4. Add + Commit + Push
# ----------------------------------------------------------------------
Step "2" "Dateien stagen"
foreach ($f in $files) {
    & git add -- $f
    if ($LASTEXITCODE -ne 0) { ErrLine "git add $f fehlgeschlagen."; exit 1 }
}
Ok "Alle $($files.Count) Eintraege gestaget"

Step "3" "Commit"
$msg = @"
Phase 0 Housekeeping: Infra-Scripts, Playwright-Setup, Package-Updates

Nachgezogene Dateien aus Phase 0 (Arbeitsschema + Deploy-Pipeline + Test-Gate):
- Tag-2 Staging-Setup Bootstrap-Scripts (phase0-tag2-*)
- Tag-3 Fix/Launch-Scripts (phase0-tag3-*)
- Playwright-Konfiguration + E2E-Testsuite (playwright.config.ts, tests/e2e/)
- package.json / package-lock.json (Playwright als devDependency)

Reine Dev-Infrastruktur, beruehrt kein Laufzeitverhalten. Ermoeglicht
Reproduzierbarkeit der Test-Gate-Pipeline fuer Folge-Mitwirkende und
spaetere Sessions.
"@

& git commit -m $msg
if ($LASTEXITCODE -ne 0) { ErrLine "git commit fehlgeschlagen."; exit 1 }
Ok "Commit erstellt"

Step "4" "Push origin/main"
& git push origin main
if ($LASTEXITCODE -ne 0) { ErrLine "git push fehlgeschlagen."; exit 1 }
Ok "main gepusht"

# ----------------------------------------------------------------------
# 5. Fertig
# ----------------------------------------------------------------------
Section "HOUSEKEEPING FERTIG"
Write-Host ""
Ok "Phase 0 ist jetzt vollstaendig versioniert."
Write-Host ""
Write-Host "Was als Naechstes:" -ForegroundColor Cyan
Write-Host "  - Memory aktualisieren: Phase 0 vollstaendig abgeschlossen" -ForegroundColor Gray
Write-Host "  - Task #32 auf completed setzen" -ForegroundColor Gray
Write-Host "  - Task #33: Secrets rotieren" -ForegroundColor Gray
Write-Host ""
