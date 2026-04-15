# phase2-upload.ps1
# PowerShell - lokal ausfuehren auf dem Entwickler-PC
# Laedt die 6 neuen Dokumente auf den Server und committet sie

$ErrorActionPreference = "Stop"
$Server   = "root@178.104.138.177"
$RemoteApp= "/var/www/menucard-pro"
$LocalDir = "C:\Users\erich\Documents\Claude\Projects\Menucard Pro"
$DocsNew  = Join-Path $LocalDir "docs-new"

Write-Host "=== Phase 2 Upload ===" -ForegroundColor Cyan
Write-Host "Quelle: $DocsNew"
Write-Host "Ziel:   $Server : $RemoteApp"
Write-Host ""

# 1. Lokale Dateien pruefen
$Files = @("CLAUDE.md","README.md","CHANGELOG.md","API.md","DATENMODELL.md","DEPLOYMENT.md")
foreach ($f in $Files) {
    $p = Join-Path $DocsNew $f
    if (-not (Test-Path $p)) { throw "Fehlt: $p" }
    Write-Host "OK  $f ($((Get-Item $p).Length) Bytes)"
}
Write-Host ""

# 2. Server-Backup der alten Docs
Write-Host "== Server-Backup alter Dokumente ==" -ForegroundColor Yellow
$BackupCmd = @"
cd $RemoteApp
mkdir -p docs-backup-`$(date +%Y%m%d-%H%M)
for f in CLAUDE.md README.md CHANGELOG.md; do
    [ -f `"`$f`" ] && cp `"`$f`" docs-backup-`$(date +%Y%m%d-%H%M)/ 2>/dev/null || true
done
[ -d docs ] && cp -r docs docs-backup-`$(date +%Y%m%d-%H%M)/docs-old 2>/dev/null || true
ls -la docs-backup-* | tail -20
"@
ssh $Server $BackupCmd

# 3. Upload der neuen Dokumente
Write-Host ""
Write-Host "== Upload ==" -ForegroundColor Yellow
scp (Join-Path $DocsNew "CLAUDE.md")      "${Server}:${RemoteApp}/CLAUDE.md"
scp (Join-Path $DocsNew "README.md")      "${Server}:${RemoteApp}/README.md"
scp (Join-Path $DocsNew "CHANGELOG.md")   "${Server}:${RemoteApp}/CHANGELOG.md"

ssh $Server "mkdir -p $RemoteApp/docs"
scp (Join-Path $DocsNew "API.md")         "${Server}:${RemoteApp}/docs/API.md"
scp (Join-Path $DocsNew "DATENMODELL.md") "${Server}:${RemoteApp}/docs/DATENMODELL.md"
scp (Join-Path $DocsNew "DEPLOYMENT.md")  "${Server}:${RemoteApp}/docs/DEPLOYMENT.md"

# 4. Git-Commit + Push auf dem Server
Write-Host ""
Write-Host "== Git-Commit + Push ==" -ForegroundColor Yellow
$GitCmd = @"
cd $RemoteApp
git add CLAUDE.md README.md CHANGELOG.md docs/API.md docs/DATENMODELL.md docs/DEPLOYMENT.md
git status --short
git commit -m 'docs: Vollstaendige Dokumentations-Ueberarbeitung (v1.0-stabil)

- CLAUDE.md: aktualisierte Projektstruktur, Routen, Datenstand
- README.md: Live-Zugaenge und Kennzahlen, Setup-Anleitung
- CHANGELOG.md: Versionshistorie ab 0.0.x (MVP) bis 1.0.0 (2026-04-14)
- docs/API.md: alle 27 Endpunkte mit Payloads und Fehlercodes
- docs/DATENMODELL.md: 28 Modelle und 12 Enums dokumentiert
- docs/DEPLOYMENT.md: Server-Setup, Backup/Restore, Troubleshooting'
git push origin main
"@
ssh $Server $GitCmd

# 5. Lokal synchronisieren (damit lokal dieselben Dateien liegen)
Write-Host ""
Write-Host "== Lokale Synchronisation ==" -ForegroundColor Yellow
Copy-Item (Join-Path $DocsNew "CLAUDE.md")    (Join-Path $LocalDir "CLAUDE.md")    -Force
Copy-Item (Join-Path $DocsNew "README.md")    (Join-Path $LocalDir "README.md")    -Force
Copy-Item (Join-Path $DocsNew "CHANGELOG.md") (Join-Path $LocalDir "CHANGELOG.md") -Force
$LocalDocs = Join-Path $LocalDir "docs"
if (-not (Test-Path $LocalDocs)) { New-Item -ItemType Directory -Path $LocalDocs | Out-Null }
Copy-Item (Join-Path $DocsNew "API.md")         (Join-Path $LocalDocs "API.md")         -Force
Copy-Item (Join-Path $DocsNew "DATENMODELL.md") (Join-Path $LocalDocs "DATENMODELL.md") -Force
Copy-Item (Join-Path $DocsNew "DEPLOYMENT.md")  (Join-Path $LocalDocs "DEPLOYMENT.md")  -Force

Write-Host ""
Write-Host "=== Phase 2 abgeschlossen ===" -ForegroundColor Green
Write-Host "Pruefen Sie den Commit unter https://github.com/rexei123/menucard-pro/commits/main"
