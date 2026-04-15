#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Git: Bildarchiv + SearXNG sichern und auf GitHub pushen
# ═══════════════════════════════════════════════════════════════
cd /var/www/menucard-pro

echo ""
echo "=== Git Sicherung ==="
echo ""

# DB-Backup vor Commit
echo "[1/4] Datenbank-Backup..."
pg_dump "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro" > /root/menucard-backup-20260412-bildarchiv.sql
echo "  Backup: /root/menucard-backup-20260412-bildarchiv.sql"

# Git Status
echo ""
echo "[2/4] Git Status..."
git status --short

# Stage alle relevanten Dateien
echo ""
echo "[3/4] Dateien stagen..."
git add src/app/admin/media/
git add src/app/admin/media/\[id\]/
git add src/app/api/v1/media/
git add src/components/admin/media-archive.tsx
git add src/components/admin/media-detail.tsx
git add src/components/admin/icon-bar.tsx
git add prisma/schema.prisma
git add .env 2>/dev/null || true

# Auch andere geaenderte Dateien
git add src/app/api/v1/media/upload/route.ts 2>/dev/null || true
git add src/app/api/v1/media/web-search/route.ts 2>/dev/null || true
git add src/app/api/v1/media/web-import/route.ts 2>/dev/null || true

echo "  Gestaged:"
git diff --cached --stat

# Commit
echo ""
echo "[4/4] Commit + Push..."
git commit -m "Bildarchiv Phase 1-3: Upload, Galerie, Websuche mit SearXNG

- Bildarchiv mit 4 Tabs: Fotos, Logos, Hochladen, Websuche
- Upload mit Sharp: 6 Formate (original, 16:9, 4:3, 1:1, 3:4, thumb)
- Detailansicht mit Formaten, Metadaten, Produktzuordnung
- SearXNG Docker fuer Bildersuche (Google+Bing+DDG)
- Wikimedia Commons (frei), Pixabay (API-Key)
- Web-Import mit automatischer Formatgenerierung
- Prisma Schema: MediaCategory, MediaSource Enums
- Admin Icon-Bar: Bildarchiv Menuepunkt"

if [ $? -eq 0 ]; then
  echo "  Commit erfolgreich!"
  echo ""
  echo "  Pushe zu GitHub..."
  git push origin main
  if [ $? -eq 0 ]; then
    echo ""
    echo "======================================"
    echo "  Alles gesichert auf GitHub!"
    echo "======================================"
  else
    echo "  Push fehlgeschlagen - evtl. SSH-Key pruefen"
  fi
else
  echo "  Nichts zu committen oder Fehler"
fi

echo ""
git log --oneline -3
echo ""
