# cleanup-runde4.ps1 - Server aufraeumen nach erfolgreichem Runde-4-Deploy
# -------------------------------------------------------------------
# 1) Listet alle .bak.runde2 + .bak.runde3 Backup-Dateien auf
# 2) Verschiebt reseed-system-templates.ts -> scripts/reseed-system-templates.ts
# 3) Loescht die Backup-Dateien
# 4) Loescht das runde3/ Arbeitsverzeichnis
# 5) Verifiziert mit HTTP-Check, dass die App weiterhin laeuft
# -------------------------------------------------------------------
$ErrorActionPreference = 'Stop'

Write-Host "== 1. Bestandsaufnahme: Backup-Dateien =="
ssh menucard "cd /var/www/menucard-pro && find src -maxdepth 10 -type f \( -name '*.bak.runde2' -o -name '*.bak.runde3' \) -printf '  %p  (%s bytes)\n' | sort"

Write-Host ""
Write-Host "== 2. Reseed-Tool sichern (runde3/reseed-system-templates.ts -> scripts/) =="
ssh menucard "cd /var/www/menucard-pro && mkdir -p scripts && if [ -f runde3/reseed-system-templates.ts ]; then mv runde3/reseed-system-templates.ts scripts/reseed-system-templates.ts && echo '  verschoben nach scripts/reseed-system-templates.ts'; else echo '  bereits verschoben oder nicht vorhanden'; fi"

Write-Host ""
Write-Host "== 3. Backup-Dateien loeschen =="
ssh menucard "cd /var/www/menucard-pro && COUNT=`$(find src -type f \( -name '*.bak.runde2' -o -name '*.bak.runde3' \) | wc -l) && find src -type f \( -name '*.bak.runde2' -o -name '*.bak.runde3' \) -delete && echo `"  `$COUNT Backup-Dateien geloescht`""

Write-Host ""
Write-Host "== 4. Arbeitsverzeichnis runde3/ loeschen =="
ssh menucard "cd /var/www/menucard-pro && if [ -d runde3 ]; then rm -rf runde3 && echo '  runde3/ geloescht'; else echo '  runde3/ bereits entfernt'; fi"

Write-Host ""
Write-Host "== 5. Gegenprobe: Keine Backup-Reste, keine runde3-Reste =="
ssh menucard "cd /var/www/menucard-pro && echo '  Backup-Reste:' && find src -type f \( -name '*.bak*' \) 2>/dev/null | head -10 && echo '  runde3-Reste:' && ls -la runde3 2>&1 | head -3 && echo '  scripts/-Inhalt:' && ls -la scripts/"

Write-Host ""
Write-Host "== 6. HTTP-Gegenprobe: App laeuft =="
ssh menucard "curl -sk -o /dev/null -w 'Login:    HTTP %{http_code}\n' https://menu.hotel-sonnblick.at/auth/login && curl -sk -o /dev/null -w 'Gaeste-1: HTTP %{http_code}\n' https://menu.hotel-sonnblick.at/hotel-sonnblick/restaurant/amerikanischer-abend && curl -sk -o /dev/null -w 'Gaeste-2: HTTP %{http_code}\n' https://menu.hotel-sonnblick.at/hotel-sonnblick/restaurant/jaegerabend"

Write-Host ""
Write-Host "== FERTIG =="
Write-Host "Server ist aufgeraeumt. Reseed-Tool liegt jetzt dauerhaft unter scripts/reseed-system-templates.ts"
