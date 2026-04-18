#!/bin/bash
# ─────────────────────────────────────────────────────
# MenuCard Pro — PostgreSQL-Restore
# Nutzung: bash restore-db.sh [backup-datei.sql.gz]
# Ohne Argument: zeigt verfügbare Backups an
# ─────────────────────────────────────────────────────

set -euo pipefail

BACKUP_DIR="/var/backups/menucard-pro"
DB_NAME="menucard_pro"
DB_USER="menucard"
APP_DIR="/var/www/menucard-pro"

# Passwort aus .env laden
export PGPASSWORD=$(grep -oP 'DATABASE_URL=.*:\/\/[^:]+:\K[^@]+' "$APP_DIR/.env" 2>/dev/null || echo "")

# Ohne Argument: Liste anzeigen
if [ -z "${1:-}" ]; then
    echo "Verfügbare Backups:"
    echo "─────────────────────────────────────"
    ls -lh "$BACKUP_DIR"/${DB_NAME}_*.sql.gz 2>/dev/null | awk '{print NR". "$NF" ("$5")"}'
    echo ""
    echo "Nutzung: bash restore-db.sh <dateiname.sql.gz>"
    exit 0
fi

BACKUP_FILE="$1"

# Prüfen ob Datei existiert
if [ ! -f "$BACKUP_FILE" ]; then
    # Auch im Backup-Verzeichnis suchen
    if [ -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
        BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE"
    else
        echo "FEHLER: Datei nicht gefunden: $BACKUP_FILE"
        exit 1
    fi
fi

echo "╔══════════════════════════════════════════╗"
echo "║  ACHTUNG: Datenbank wird überschrieben!  ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Backup: $BACKUP_FILE"
echo "Datenbank: $DB_NAME"
echo ""
read -p "Fortfahren? (ja/nein): " CONFIRM

if [ "$CONFIRM" != "ja" ]; then
    echo "Abgebrochen."
    exit 0
fi

# Vor Restore: Sicherheits-Backup erstellen
SAFETY_FILE="$BACKUP_DIR/${DB_NAME}_vor-restore_$(date +%Y-%m-%d_%H%M).sql.gz"
echo "Erstelle Sicherheits-Backup vor Restore..."
pg_dump -U "$DB_USER" -h 127.0.0.1 "$DB_NAME" --no-owner --no-acl | gzip > "$SAFETY_FILE"
echo "OK: $SAFETY_FILE"

# PM2 stoppen
echo "Stoppe menucard-pro..."
pm2 stop menucard-pro 2>/dev/null || true

# Restore durchführen
echo "Restore läuft..."
gunzip -c "$BACKUP_FILE" | psql -U "$DB_USER" -h 127.0.0.1 "$DB_NAME" --quiet 2>&1 | grep -c "ERROR" && echo "Warnungen beim Restore (kann normal sein)" || true

# PM2 starten
echo "Starte menucard-pro..."
pm2 restart menucard-pro

echo ""
echo "Restore abgeschlossen!"
echo "Sicherheits-Backup: $SAFETY_FILE"
