# ============================================
# PHASE 0 TAG 1 SCHRITT 2 (LAUNCHER)
# Laedt das Bash-Script auf den Server hoch und fuehrt es dort aus.
# Eine Shell: scp + ssh kombiniert.
# ============================================

$ServerIP = "178.104.138.177"
$ServerUser = "root"
$LocalScript = "phase0-tag2-server-git.sh"
$RemoteScript = "/tmp/phase0-tag2-server-git.sh"

Write-Host ""
Write-Host "=== Phase 0 Tag 1 Schritt 2 - Server zum Git-Repo machen ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Haelt an, sobald der Deploy Key in GitHub eingetragen werden muss."
Write-Host "Das Script zeigt dann den Public Key und eine URL - dort einfuegen,"
Write-Host "zurueck ins Terminal kommen und ENTER druecken."
Write-Host ""

if (-not (Test-Path $LocalScript)) {
    Write-Host "FEHLER: $LocalScript nicht gefunden (muss im CWD liegen)." -ForegroundColor Red
    exit 1
}

Write-Host "Upload..." -ForegroundColor Yellow
scp $LocalScript "${ServerUser}@${ServerIP}:${RemoteScript}"
if ($LASTEXITCODE -ne 0) {
    Write-Host "FEHLER: scp fehlgeschlagen." -ForegroundColor Red
    exit 1
}

Write-Host "Ausfuehrung startet... (ssh -t fuer interaktive Prompts)" -ForegroundColor Yellow
Write-Host ""

# -t: TTY allocieren, damit read-Prompts im Bash-Script funktionieren
ssh -t "${ServerUser}@${ServerIP}" "bash $RemoteScript"
$sshExit = $LASTEXITCODE

Write-Host ""
if ($sshExit -eq 0) {
    Write-Host "Server-Script erfolgreich durchgelaufen." -ForegroundColor Green
} else {
    Write-Host "Server-Script mit Exit-Code $sshExit beendet." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Naechster Schritt: Git-basiertes Deploy-Script auf dem Server (Schritt 3)." -ForegroundColor Cyan
