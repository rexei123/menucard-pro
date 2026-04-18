#!/bin/bash
# ─────────────────────────────────────────────────────
# MenuCard Pro — Tägliches PostgreSQL-Backup
# Cron: 0 3 * * * /var/www/menucard-pro/scripts/backup-db.sh
# ─────────────────────────────────────────────────────

set -euo pipefail

# Konfiguration
BACKUP_DIR="/var/backups/menucard-pro"
DB_NAME="menucard_pro"
DB_USER="menucard"
RETENTION_DAYS=7
APP_DIR="/var/www/menucard-pro"

# Passwort aus .env laden
export PGPASSWORD=$(grep -oP 'DATABASE_URL=.*:\/\/[^:]+:\K[^@]+' "$APP_DIR/.env" 2>/dev/null || echo "")
TIMESTAMP=$(date +%Y-%m-%d_%H%M)
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql.gz"
LOG_FILE="$BACKUP_DIR/backup.log"

# Verzeichnis sicherstellen
mkdir -p "$BACKUP_DIR"

# Backup erstellen (komprimiert)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starte Backup..." >> "$LOG_FILE"

if pg_dump -U "$DB_USER" -h 127.0.0.1 "$DB_NAME" --no-owner --no-acl | gzip > "$BACKUP_FILE"; then
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] OK: $BACKUP_FILE ($SIZE)" >> "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] FEHLER: Backup fehlgeschlagen!" >> "$LOG_FILE"
    exit 1
fi

# Alte Backups löschen (älter als RETENTION_DAYS)
DELETED=$(find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime +$RETENTION_DAYS -delete -print | wc -l)
if [ "$DELETED" -gt 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $DELETED alte Backups gelöscht (> ${RETENTION_DAYS} Tage)" >> "$LOG_FILE"
fi

# Zusammenfassung
TOTAL=$(find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" | wc -l)
TOTAL_SIZE=$(du -sh "$BACKUP_DIR"/*.sql.gz 2>/dev/null | tail -1 | cut -f1)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Gesamt: $TOTAL Backups" >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"
