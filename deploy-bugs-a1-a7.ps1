# ============================================
# DEPLOY: Bekannte Bugs A-1 bis A-7
# A-1: GET /api/v1/products Listen-Endpoint
# A-2: GET /api/v1/variants Listen-Endpoint
# A-3: GET /api/v1/placements Listen-Endpoint
# A-4: POST /api/v1/menus (neue Kartenerstellung)
# A-6: Benutzerverwaltung (API + UI)
# A-7: Nginx client_max_body_size konsolidieren
# A-5: (deferred - echte Produktdaten vom Hotel)
# ============================================

$SERVER = "root@178.104.138.177"
$APP = "/var/www/menucard-pro"

Write-Host ""
Write-Host "=== DEPLOY: Bugs A-1 bis A-7 ===" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------------------
# 1. UPLOAD Code-Aenderungen (API + UI)
# ----------------------------------------------------------------------
Write-Host "[1/5] Upload Code..." -ForegroundColor Yellow

# A-1 ... A-4: API-Endpoints
scp "src/app/api/v1/products/route.ts"   "${SERVER}:${APP}/src/app/api/v1/products/route.ts"
scp "src/app/api/v1/variants/route.ts"   "${SERVER}:${APP}/src/app/api/v1/variants/route.ts"
scp "src/app/api/v1/placements/route.ts" "${SERVER}:${APP}/src/app/api/v1/placements/route.ts"
scp "src/app/api/v1/menus/route.ts"      "${SERVER}:${APP}/src/app/api/v1/menus/route.ts"

# A-6: Benutzer-API (NEU)
ssh $SERVER "mkdir -p $APP/src/app/api/v1/users/[id]"
scp "src/app/api/v1/users/route.ts"      "${SERVER}:${APP}/src/app/api/v1/users/route.ts"
scp "src/app/api/v1/users/[id]/route.ts" "${SERVER}:${APP}/src/app/api/v1/users/[id]/route.ts"

# A-6: Benutzer-UI
scp "src/app/admin/settings/users/page.tsx" "${SERVER}:${APP}/src/app/admin/settings/users/page.tsx"
scp "src/components/admin/users-admin.tsx"  "${SERVER}:${APP}/src/components/admin/users-admin.tsx"

# A-4: UI-Button "Neue Karte" im Menu-Panel
scp "src/components/admin/menu-list-panel.tsx" "${SERVER}:${APP}/src/components/admin/menu-list-panel.tsx"

Write-Host "[1/5] Upload fertig." -ForegroundColor Green

# ----------------------------------------------------------------------
# 2. BUILD + RESTART
# ----------------------------------------------------------------------
Write-Host "[2/5] Build + PM2 Restart..." -ForegroundColor Yellow
ssh $SERVER "cd $APP && npm run build && pm2 restart menucard-pro"
Start-Sleep -Seconds 3
Write-Host "[2/5] Build + Restart fertig." -ForegroundColor Green

# ----------------------------------------------------------------------
# 3. A-7: Nginx client_max_body_size konsolidieren
# ----------------------------------------------------------------------
Write-Host "[3/5] Nginx-Konfiguration pruefen..." -ForegroundColor Yellow

# Bash-Script lokal schreiben, per scp hochladen und ausfuehren
# (Vermeidet PowerShell-Escaping-Komplexitaet bei Heredocs)
$nginxScript = @'
#!/bin/bash
set -e
CONF=""
for CAND in /etc/nginx/sites-available/menucard-pro /etc/nginx/sites-available/menucard-pro.conf /etc/nginx/sites-available/menu.hotel-sonnblick.at; do
  if [ -f "$CAND" ]; then CONF="$CAND"; break; fi
done
if [ -z "$CONF" ]; then
  echo "WARNUNG: Keine passende Nginx-Config gefunden"
  ls /etc/nginx/sites-available/
  exit 0
fi
echo "Config-Datei: $CONF"
BACKUP="${CONF}.bak-$(date +%Y%m%d-%H%M%S)"
cp "$CONF" "$BACKUP"
echo "Backup: $BACKUP"
if grep -q "client_max_body_size" "$CONF"; then
  sed -i "s/client_max_body_size[[:space:]]\+[^;]*;/client_max_body_size 50M;/g" "$CONF"
  echo "client_max_body_size auf 50M aktualisiert."
else
  awk '/server[[:space:]]*\{/ && !done { print; print "    client_max_body_size 50M;"; done=1; next }1' "$CONF" > "${CONF}.tmp" && mv "${CONF}.tmp" "$CONF"
  echo "client_max_body_size 50M neu eingefuegt."
fi
if nginx -t; then
  systemctl reload nginx
  echo "Nginx neu geladen."
else
  echo "FEHLER: nginx -t fehlgeschlagen - Rollback!"
  cp "$BACKUP" "$CONF"
  exit 1
fi
echo "Aktueller Eintrag:"
grep -n "client_max_body_size" "$CONF" || echo "  (kein Eintrag)"
'@

$tmpScript = "nginx-fix.sh"
Set-Content -Path $tmpScript -Value $nginxScript -NoNewline -Encoding ASCII
scp $tmpScript "${SERVER}:/tmp/nginx-fix.sh"
ssh $SERVER "chmod +x /tmp/nginx-fix.sh && /tmp/nginx-fix.sh && rm /tmp/nginx-fix.sh"
Remove-Item $tmpScript
Write-Host "[3/5] Nginx fertig." -ForegroundColor Green

# ----------------------------------------------------------------------
# 4. VERIFIKATION per curl
# ----------------------------------------------------------------------
Write-Host "[4/5] API-Verifikation..." -ForegroundColor Yellow
$endpoints = @(
  @{ name = "GET  /api/v1/products   (A-1, 401 erwartet)"; url = "https://menu.hotel-sonnblick.at/api/v1/products" },
  @{ name = "GET  /api/v1/variants   (A-2, 401 erwartet)"; url = "https://menu.hotel-sonnblick.at/api/v1/variants" },
  @{ name = "GET  /api/v1/placements (A-3, 401 erwartet)"; url = "https://menu.hotel-sonnblick.at/api/v1/placements" },
  @{ name = "GET  /api/v1/menus      (A-4, 200 erwartet)"; url = "https://menu.hotel-sonnblick.at/api/v1/menus" },
  @{ name = "GET  /api/v1/users      (A-6, 401 erwartet)"; url = "https://menu.hotel-sonnblick.at/api/v1/users" },
  @{ name = "GET  /hotel-sonnblick/restaurant/abendkarte"; url = "https://menu.hotel-sonnblick.at/hotel-sonnblick/restaurant/abendkarte" }
)
foreach ($ep in $endpoints) {
  $code = curl.exe -s -o NUL -w "%{http_code}" $ep.url
  Write-Host ("  {0,-52} -> {1}" -f $ep.name, $code)
}

# POST /api/v1/menus (ohne Auth -> 401)
$postCode = curl.exe -s -o NUL -w "%{http_code}" -X POST -H "Content-Type: application/json" -d '{}' "https://menu.hotel-sonnblick.at/api/v1/menus"
Write-Host ("  {0,-52} -> {1}" -f "POST /api/v1/menus (A-4, 401 erwartet)", $postCode)

# ----------------------------------------------------------------------
# 5. PM2-Log-Check
# ----------------------------------------------------------------------
Write-Host "[5/5] PM2-Log-Check (letzte Errors)..." -ForegroundColor Yellow
ssh $SERVER "pm2 logs menucard-pro --lines 15 --nostream --err"

Write-Host ""
Write-Host "=== DEPLOY FERTIG ===" -ForegroundColor Green
Write-Host ""
Write-Host "Bitte im Browser pruefen:" -ForegroundColor Cyan
Write-Host "  1. /admin/menus            -> Button 'Neu' sichtbar, Anlegen einer neuen Karte" -ForegroundColor White
Write-Host "  2. /admin/settings/users   -> Benutzerliste, Anlegen, Bearbeiten, Loeschen" -ForegroundColor White
Write-Host "  3. /admin/analytics        -> weiterhin fehlerfrei" -ForegroundColor White
Write-Host ""
Write-Host "Hinweis A-5 (echte Produktdaten):" -ForegroundColor Yellow
Write-Host "  Benoetigt die echten Sonnblick-Karten (Speisen, Getraenke, Weine)." -ForegroundColor White
Write-Host "  Bitte als CSV/Excel bereitstellen - Import dann via /admin/import." -ForegroundColor White
