# git-init.ps1 - Git-Repository initialisieren und ersten Commit erstellen
# -----------------------------------------------------------------------
# Nach dem Ausfuehren:
#   1. GitHub-Repo erstellen: github.com/new -> Name: "menucard-pro"
#   2. Remote hinzufuegen:  git remote add origin https://github.com/IHR-USERNAME/menucard-pro.git
#   3. Pushen:              git push -u origin main
# -----------------------------------------------------------------------
$ErrorActionPreference = 'Stop'

Write-Host "== 1. Git-Repository initialisieren =="
git init
git branch -m main

Write-Host ""
Write-Host "== 2. Git-User konfigurieren (lokal fuer dieses Repo) =="
git config user.email "hotelsonnblick@gmail.com"
git config user.name "Hotel Sonnblick"

Write-Host ""
Write-Host "== 3. Alle Dateien stagen =="
git add -A

Write-Host ""
Write-Host "== 4. Status =="
git status --short | Select-Object -First 30
$count = (git status --short | Measure-Object).Count
Write-Host "  ... $count Dateien insgesamt"

Write-Host ""
Write-Host "== 5. Erster Commit =="
git commit -m "Initial commit: MenuCard Pro Projektdateien

Enthaelt:
- CLAUDE.md (Arbeitsanweisungen, Design-Strategie 2.0)
- README.md, CHANGELOG.md
- Abschlussbericht Design-Strategie 2.0
- Deploy-Skripte (Runde 2-4)
- Compliance-Pipeline (design-compliance.mjs, Reports)
- Dokumentation (docs/)
- Fix- und Setup-Skripte
- Testprotokolle und Playwright-Tests"

Write-Host ""
Write-Host "== FERTIG =="
Write-Host ""
Write-Host "Naechste Schritte:"
Write-Host "  1. Neues Repository auf GitHub erstellen:"
Write-Host "     -> https://github.com/new"
Write-Host "     -> Name: menucard-pro (privat empfohlen)"
Write-Host "     -> KEIN README/gitignore/License hinzufuegen (haben wir schon)"
Write-Host ""
Write-Host "  2. Remote verbinden und pushen:"
Write-Host "     git remote add origin https://github.com/IHR-USERNAME/menucard-pro.git"
Write-Host "     git push -u origin main"
