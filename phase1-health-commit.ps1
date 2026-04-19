# ============================================================================
# PHASE 1 - /api/health commit-SHA aktivieren
# ============================================================================
# Problem: /api/health liefert aktuell commit:"unknown", weil die laufende
# Node-Instanz kein GIT_COMMIT in ihrer Umgebung hat.
#
# Fix (in dieser Reihenfolge):
#   1. Lokal: deploy.sh + deploy-staging.sh committen (setzen bei kuenftigen
#      Deploys GIT_COMMIT in .env und starten pm2 mit --update-env).
#   2. Server: git pull main (Prod + Staging).
#   3. Server: Einmalig manuell GIT_COMMIT in beide .env schreiben und
#      pm2 restart --update-env, damit der Effekt sofort da ist
#      (ohne auf den naechsten Deploy warten zu muessen).
#   4. Extern verifizieren, dass /api/health jetzt die echte SHA zeigt.
# ============================================================================

param(
    [string]$ServerIP   = "178.104.138.177",
    [string]$ServerUser = "root"
)

$ErrorActionPreference = 'Continue'

function Section($t) { Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Cyan }
function Ok($t)      { Write-Host "OK   $t" -ForegroundColor Green }
function Warn($t)    { Write-Host "WARN $t" -ForegroundColor Yellow }
function ErrLine($t) { Write-Host "FAIL $t" -ForegroundColor Red }
function Step($n,$t) { Write-Host ""; Write-Host "[$n] $t" -ForegroundColor Yellow }

Section "/api/health commit-SHA aktivieren"

# ----------------------------------------------------------------------
# 1. Lokal committen + pushen
# ----------------------------------------------------------------------
Step "1/4" "Lokal committen"

& git add scripts/deploy.sh scripts/deploy-staging.sh phase1-health-commit.ps1
if ($LASTEXITCODE -ne 0) { ErrLine "git add fehlgeschlagen."; exit 1 }

$staged = & git diff --cached --name-only
if (-not $staged) {
    Warn "Nichts zu committen (bereits im Repo)."
} else {
    Write-Host "  Zu committen:" -ForegroundColor Gray
    $staged | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

    $msg = @"
Deploy: GIT_COMMIT-SHA in .env setzen vor pm2 restart

- scripts/deploy.sh + scripts/deploy-staging.sh schreiben
  vor dem pm2 restart GIT_COMMIT=<sha> in .env (Update oder Append)
  und starten mit --update-env. Dadurch liefert /api/health
  ab jetzt die echte Commit-SHA statt 'unknown'.
- phase1-health-commit.ps1: einmaliger Launcher, der den Effekt
  sofort in beide laufenden Instanzen (Prod + Staging) traegt,
  ohne auf den naechsten Deploy warten zu muessen.
"@

    & git commit -m $msg
    if ($LASTEXITCODE -ne 0) { ErrLine "git commit fehlgeschlagen."; exit 1 }

    & git push origin main
    if ($LASTEXITCODE -ne 0) { ErrLine "git push fehlgeschlagen."; exit 1 }
}
Ok "Lokal fertig"

# ----------------------------------------------------------------------
# 2. Server: pull + einmalig GIT_COMMIT setzen + pm2 --update-env
# ----------------------------------------------------------------------
Step "2/4" "Server: pull + GIT_COMMIT in .env + pm2 restart --update-env"

$remoteCmd = @'
set -e

apply() {
    local DIR="$1"
    local NAME="$2"
    cd "$DIR"
    echo "--- $NAME ($DIR) ---"
    echo "HEAD vorher:  $(git rev-parse --short HEAD)"
    git pull --ff-only origin main
    local SHA
    SHA=$(git rev-parse HEAD)
    echo "HEAD nachher: $(git rev-parse --short HEAD)"
    if grep -q "^GIT_COMMIT=" .env; then
        sed -i "s|^GIT_COMMIT=.*|GIT_COMMIT=${SHA}|" .env
        echo "GIT_COMMIT aktualisiert"
    else
        echo "GIT_COMMIT=${SHA}" >> .env
        echo "GIT_COMMIT angehaengt"
    fi
    pm2 restart "$NAME" --update-env
    echo ""
}

apply /var/www/menucard-pro         menucard-pro
apply /var/www/menucard-pro-staging menucard-pro-staging

echo "--- pm2 status ---"
pm2 list | sed -n "1,30p"
'@

ssh -t "$ServerUser@$ServerIP" $remoteCmd
if ($LASTEXITCODE -ne 0) {
    ErrLine "Server-Update fehlgeschlagen."
    exit 1
}
Ok "Server-Instanzen neu gestartet"

# ----------------------------------------------------------------------
# 3. Kurz warten, dann externer Health-Check Prod
# ----------------------------------------------------------------------
Step "3/4" "Externer Health-Check Prod"
Start-Sleep -Seconds 3

try {
    $resp = Invoke-WebRequest -Uri "https://menu.hotel-sonnblick.at/api/health" `
                              -UseBasicParsing -TimeoutSec 15
    if ($resp.StatusCode -eq 200) {
        $json = $resp.Content | ConvertFrom-Json
        if ($json.commit -and $json.commit -ne 'unknown') {
            Ok "commit: $($json.commit)"
            Ok "env:    $($json.env)"
            Ok "node:   $($json.node)"
        } else {
            Warn "HTTP 200, aber commit ist '$($json.commit)' - evtl. Cache/Delay."
            Warn "In 30s nochmal pruefen:"
            Warn "  (Invoke-WebRequest 'https://menu.hotel-sonnblick.at/api/health' -UseBasicParsing).Content"
        }
    } else {
        Warn "HTTP $($resp.StatusCode)"
    }
} catch {
    ErrLine "Prod extern nicht erreichbar: $($_.Exception.Message)"
}

# ----------------------------------------------------------------------
# 4. Fertig
# ----------------------------------------------------------------------
Step "4/4" "Fertig"
Write-Host ""
Ok "/api/health liefert ab jetzt die echte Commit-SHA."
Write-Host ""
Write-Host "Check manuell:" -ForegroundColor Gray
Write-Host "  curl -s https://menu.hotel-sonnblick.at/api/health | ConvertFrom-Json" -ForegroundColor Gray
Write-Host ""
