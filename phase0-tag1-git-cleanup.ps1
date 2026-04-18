# ============================================
# PHASE 0 - TAG 1 - SCHRITT 1 (v2, robust)
# Lokalen Git-Zustand bereinigen und auf GitHub pushen
# ============================================

# Kein $ErrorActionPreference = "Stop" - PowerShell wuerde sonst Stderr von nativen
# Kommandos (z.B. "git ls-files" bei nicht getrackten Dateien) als Fehler werten.
# Wir pruefen $LASTEXITCODE manuell.

Write-Host ""
Write-Host "=== PHASE 0 TAG 1 - GIT CLEANUP (v2) ===" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------------------
# 0. STALE LOCK PRUEFEN UND LOESEN
# ----------------------------------------------------------------------
Write-Host "[0/8] Git-Lock pruefen..." -ForegroundColor Yellow

$lockFile = ".git/index.lock"
if (Test-Path $lockFile) {
    Write-Host "  WARNUNG: $lockFile existiert." -ForegroundColor Red
    Write-Host "  Bitte sicherstellen, dass KEIN anderer Git-Client laeuft:" -ForegroundColor Yellow
    Write-Host "    - GitHub Desktop geschlossen?" -ForegroundColor Gray
    Write-Host "    - VS Code geschlossen (oder Git-Extension deaktiviert)?" -ForegroundColor Gray
    Write-Host "    - Kein 'git commit' in anderem Terminal offen?" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Lock-Datei loeschen und fortfahren? (y/n)" -ForegroundColor Cyan
    $ans = Read-Host
    if ($ans -ne "y") {
        Write-Host "Abgebrochen." -ForegroundColor Yellow
        exit 0
    }
    Remove-Item $lockFile -Force
    Write-Host "  Lock entfernt." -ForegroundColor Green
} else {
    Write-Host "  Kein Lock vorhanden." -ForegroundColor Green
}

# Hilfsfunktion: Git-Call mit Exit-Check
# ($Args ist reserviert in PowerShell - deshalb $GitArgs)
function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$GitArgs)
    $output = & git @GitArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  FEHLER bei: git $($GitArgs -join ' ')" -ForegroundColor Red
        Write-Host "  $output" -ForegroundColor Red
        throw "Git-Kommando fehlgeschlagen"
    }
    return $output
}

# ----------------------------------------------------------------------
# 1. VORAUSSETZUNGEN
# ----------------------------------------------------------------------
Write-Host ""
Write-Host "[1/8] Voraussetzungen pruefen..." -ForegroundColor Yellow
$remote = & git remote get-url origin 2>$null
Write-Host "  Remote: $remote" -ForegroundColor Gray
$branch = & git branch --show-current
Write-Host "  Branch: $branch" -ForegroundColor Gray
Write-Host "[1/8] OK" -ForegroundColor Green

# ----------------------------------------------------------------------
# 2. UNERWUENSCHTE DATEIEN AUS INDEX
# ----------------------------------------------------------------------
Write-Host ""
Write-Host "[2/8] Sensible/unerwuenschte Dateien aus Tracking entfernen..." -ForegroundColor Yellow

$toUntrack = @(
    ".env.pre-ssl-20260414",
    "README.md.bak",
    "prisma/schema.prisma.bak",
    "prisma/schema.prisma.bak-bildarchiv",
    "prisma/schema.prisma.bak-dup",
    "prisma/schema.prisma.bak.20260414-055346",
    "src/components/admin/design-editor.tsx.bak-20260414-113916",
    "tailwind.config.ts.bak-redesign"
)

foreach ($f in $toUntrack) {
    # Stderr komplett schlucken, nur Exit-Code nutzen
    & git ls-files --error-unmatch $f *> $null
    if ($LASTEXITCODE -eq 0) {
        & git rm --cached --quiet $f *> $null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  entfernt: $f" -ForegroundColor Gray
        } else {
            Write-Host "  FEHLER beim Entfernen: $f" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "  nicht getrackt (OK): $f" -ForegroundColor DarkGray
    }
}
Write-Host "[2/8] OK" -ForegroundColor Green

# ----------------------------------------------------------------------
# 2.5 DATEIEN IN .local-archive/ VERSCHIEBEN (damit "git add -A" sie
#     nicht wieder zurueck staged; .gitignore greift nicht fuer zuvor
#     getrackte Dateien, solange sie am gleichen Pfad liegen)
# ----------------------------------------------------------------------
Write-Host ""
Write-Host "[3/8] Lokale Dateien nach .local-archive/ verschieben..." -ForegroundColor Yellow

$archive = ".local-archive"
if (-not (Test-Path $archive)) {
    New-Item -ItemType Directory -Path $archive -Force | Out-Null
    Write-Host "  Ordner erstellt: $archive" -ForegroundColor Gray
}

foreach ($f in $toUntrack) {
    if (Test-Path $f) {
        # Zielpfad: .local-archive/<basename>
        $basename = [System.IO.Path]::GetFileName($f)
        $target = Join-Path $archive $basename

        # Wenn Zieldatei schon existiert (z.B. zweiter Lauf), Suffix anhaengen
        if (Test-Path $target) {
            $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $target = Join-Path $archive "$basename.$stamp"
        }

        Move-Item -LiteralPath $f -Destination $target -Force
        Write-Host "  archiviert: $f  ->  $target" -ForegroundColor Gray
    } else {
        Write-Host "  bereits weg (OK): $f" -ForegroundColor DarkGray
    }
}
Write-Host "[3/8] OK" -ForegroundColor Green

# ----------------------------------------------------------------------
# 4. .gitignore STAGEN
# ----------------------------------------------------------------------
Write-Host ""
Write-Host "[4/8] .gitignore stagen..." -ForegroundColor Yellow
Invoke-Git add .gitignore | Out-Null
Write-Host "[4/8] OK" -ForegroundColor Green

# ----------------------------------------------------------------------
# 5. ALLES UEBRIGE MIT "git add -A"
# ----------------------------------------------------------------------
Write-Host ""
Write-Host "[5/8] Restliche Aenderungen stagen (git add -A)..." -ForegroundColor Yellow
Invoke-Git add -A | Out-Null
Write-Host "[5/8] OK" -ForegroundColor Green

# ----------------------------------------------------------------------
# 6. VERIFIKATION + SELBSTHEILUNG
# Falls trotz Vorbereitung noch .bak/.env.pre im Index liegen:
# aus Index entfernen UND Datei auf Platte ins Archiv verschieben.
# Nur Added/Modified flaggen - Deleted ist OK (Bereinigung, gewollt).
# ----------------------------------------------------------------------
Write-Host ""
Write-Host "[6/8] Sicherheits-Check + Selbstheilung..." -ForegroundColor Yellow

function Get-BadStaged {
    $lines = & git diff --cached --name-status
    $result = @()
    foreach ($line in $lines) {
        if (-not $line) { continue }
        $parts = $line -split "`t"
        $st = $parts[0]
        $p  = $parts[1]
        if ($st -match "^[AMCR]") {
            if ($p -match "\.bak" -or
                $p -match "\.env\.pre" -or
                $p -match "\.~lock" -or
                ($p -match "^\.env" -and $p -ne ".env.example")) {
                $result += $p
            }
        }
    }
    return ,$result
}

$maxAttempts = 3
$attempt = 0
$bad = Get-BadStaged

while ($bad.Count -gt 0 -and $attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "  Versuch $attempt`: $($bad.Count) Dateien un-stagen + archivieren..." -ForegroundColor Yellow

    foreach ($p in $bad) {
        Write-Host "    -> $p" -ForegroundColor Cyan

        # Diagnose: was sieht der Index wirklich?
        $lsOut = & git ls-files --stage -- "$p" 2>&1
        if ($lsOut) {
            Write-Host "       [diag] ls-files: $lsOut" -ForegroundColor DarkGray
        } else {
            Write-Host "       [diag] ls-files liefert nichts fuer diesen Pfad" -ForegroundColor DarkGray
        }

        # 1. Versuch: "git reset HEAD -- <pfad>" (korrekte Variante fuer Status 'A')
        $resetOut = & git reset -q HEAD -- "$p" 2>&1
        $resetExit = $LASTEXITCODE
        if ($resetExit -ne 0) {
            Write-Host "       [reset] exit=$resetExit out=$resetOut" -ForegroundColor Yellow
        } else {
            Write-Host "       [reset] OK" -ForegroundColor DarkGray
        }

        # 2. Fallback: Plumbing-Variante, entfernt Index-Eintrag roh
        $nameOnly = & git diff --cached --name-only -- "$p" 2>&1
        if ($nameOnly) {
            Write-Host "       [fallback] update-index --force-remove" -ForegroundColor Yellow
            $uiOut = & git update-index --force-remove -- "$p" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "       [update-index] FEHLER: $uiOut" -ForegroundColor Red
            } else {
                Write-Host "       [update-index] OK" -ForegroundColor DarkGray
            }
        }

        # Datei auf Platte archivieren (mit und ohne Slash-Variante probieren)
        $candidates = @($p, ($p -replace '/', '\'))
        $moved = $false
        foreach ($cand in $candidates) {
            if (Test-Path -LiteralPath $cand) {
                $basename = [System.IO.Path]::GetFileName($cand)
                $target = Join-Path $archive $basename
                if (Test-Path -LiteralPath $target) {
                    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
                    $target = Join-Path $archive "$basename.$stamp"
                }
                Move-Item -LiteralPath $cand -Destination $target -Force
                Write-Host "       archiviert: $cand  ->  $target" -ForegroundColor Gray
                $moved = $true
                break
            }
        }
        if (-not $moved) {
            Write-Host "       (Datei nicht auf Platte - nur Index-Leiche)" -ForegroundColor DarkGray
        }
    }
    $bad = Get-BadStaged
}

$deletedCount = ((& git diff --cached --name-status) | Where-Object { $_ -match "^D`t" } | Measure-Object).Count
if ($deletedCount -gt 0) {
    Write-Host "  $deletedCount Dateien werden aus dem Index entfernt (gewollt)." -ForegroundColor Gray
}

if ($bad.Count -gt 0) {
    Write-Host "  FEHLER: Selbstheilung nach $maxAttempts Versuchen gescheitert:" -ForegroundColor Red
    $bad | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
    exit 1
}
Write-Host "  Staging ist sauber (keine unerwuenschten Neuzugaenge)." -ForegroundColor Green
Write-Host "[6/8] OK" -ForegroundColor Green

# ----------------------------------------------------------------------
# 7. STATUS-UEBERSICHT + BESTAETIGUNG
# ----------------------------------------------------------------------
Write-Host ""
Write-Host "[7/8] Uebersicht vor Commit (erste 40 Eintraege):" -ForegroundColor Yellow
Write-Host ""

# Gestagede Aenderungen mit Typ (A/M/D/R) aus git holen
$staged = & git diff --cached --name-status
$staged | Select-Object -First 40 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
$total = ($staged | Measure-Object).Count

if ($total -eq 0) {
    Write-Host ""
    Write-Host "  Keine gestagedten Aenderungen. Nichts zu committen." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "  Gesamt gestaged: $total Dateien" -ForegroundColor Cyan
Write-Host ""
Write-Host "Commit und Push auf origin/main durchfuehren? (y/n)" -ForegroundColor Cyan
$ans = Read-Host
if ($ans -ne "y") {
    Write-Host "Abgebrochen. Index bleibt vorbereitet." -ForegroundColor Yellow
    exit 0
}

# ----------------------------------------------------------------------
# 8. COMMIT + PUSH
# ----------------------------------------------------------------------
Write-Host ""
Write-Host "[8/8] Commit und Push..." -ForegroundColor Yellow

$commitMsg = @"
chore: Phase 0 Tag 1 - Arbeitsschema, Masterplan, Git-Hygiene

- ARBEITSSCHEMA.md: 5-Phasen-Modell, Quality Gates, belastbare Git-Routine, Deploy-Protokoll
- MASTERPLAN.md: Drei-Saeulen-Architektur (Git / Staging / Tests)
- BACKLOG.md: Secret-Rotation (kritisch), Sentry, weitere aufgeschobene Punkte
- .gitignore: Umfassende Regeln fuer env-Backups, .bak, Office-Locks, Reports
- Entfernt aus Tracking: .env.pre-ssl-20260414 (enthielt Secrets), 7 .bak-Dateien
- Integriert seit 17.04.2026: Admin-Bugs A-1 bis A-7 (6 von 7), QRCode-Fix, Benutzerverwaltung

SECURITY: Secrets-Rotation noetig (siehe BACKLOG.md Prio 1).
"@

Invoke-Git commit -m $commitMsg | Out-Null
Invoke-Git push origin main | Out-Null

Write-Host ""
Write-Host "=== FERTIG ===" -ForegroundColor Green
Write-Host ""
Write-Host "GitHub-Stand pruefen: https://github.com/rexei123/menucard-pro/commits/main" -ForegroundColor Cyan
Write-Host "Naechster Schritt: Server zum Git-Repo machen." -ForegroundColor Cyan
