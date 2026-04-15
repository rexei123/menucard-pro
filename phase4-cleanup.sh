#!/bin/bash
# phase4-cleanup.sh
# SSH-Terminal auf dem Server - /var/www/menucard-pro
# Erster Aufruf: DRY RUN (nichts wird gelöscht, nur aufgelistet)
# Zweiter Aufruf mit --apply: tatsächlicher Löschvorgang
#
# Verwendung:
#   ssh root@178.104.138.177
#   cd /var/www/menucard-pro
#   bash phase4-cleanup.sh            # Dry-Run
#   bash phase4-cleanup.sh --apply    # nachdem die Liste geprüft wurde

set -euo pipefail

APPLY=0
if [[ "${1:-}" == "--apply" ]]; then
    APPLY=1
fi

echo "=============================================="
if [[ $APPLY -eq 1 ]]; then
    echo "  Phase 4 Cleanup — APPLY-Modus"
else
    echo "  Phase 4 Cleanup — DRY RUN (nichts wird gelöscht)"
fi
echo "=============================================="
echo ""

# ----------------------------------------------
# 1. .bak-Dateien im App-Verzeichnis
# ----------------------------------------------
echo "== 1. .bak-Dateien in /var/www/menucard-pro =="
mapfile -t BAK_FILES < <(find /var/www/menucard-pro -type f \( -name "*.bak" -o -name "*.bak.*" -o -name "*~" \) 2>/dev/null | grep -v "/node_modules/" | grep -v "/.next/" | grep -v "/.git/")
if [[ ${#BAK_FILES[@]} -eq 0 ]]; then
    echo "  (keine)"
else
    for f in "${BAK_FILES[@]}"; do
        size=$(du -h "$f" | cut -f1)
        echo "  $size  $f"
    done
    echo "  Gesamt: ${#BAK_FILES[@]} Dateien"
    if [[ $APPLY -eq 1 ]]; then
        for f in "${BAK_FILES[@]}"; do rm -v "$f"; done
    fi
fi
echo ""

# ----------------------------------------------
# 2. Alte /tmp-Scripts und -Artefakte
# ----------------------------------------------
echo "== 2. /tmp-Artefakte (*.mjs, *.sh, *.json, *.tar.gz > 7 Tage) =="
mapfile -t TMP_FILES < <(find /tmp -maxdepth 2 -type f \( -name "*.mjs" -o -name "*.sh" -o -name "*.json" -o -name "*.tar.gz" -o -name "phase*-*" -o -name "playwright-*" -o -name "menucard-*" \) -mtime +7 2>/dev/null)
if [[ ${#TMP_FILES[@]} -eq 0 ]]; then
    echo "  (keine älter als 7 Tage)"
else
    for f in "${TMP_FILES[@]}"; do
        size=$(du -h "$f" | cut -f1)
        mtime=$(stat -c "%y" "$f" | cut -d' ' -f1)
        echo "  $size  $mtime  $f"
    done
    echo "  Gesamt: ${#TMP_FILES[@]} Dateien"
    if [[ $APPLY -eq 1 ]]; then
        for f in "${TMP_FILES[@]}"; do rm -v "$f"; done
    fi
fi
echo ""

# ----------------------------------------------
# 3. Alte DB-Dumps in /root (vor 14.04.2026)
# ----------------------------------------------
echo "== 3. Alte DB-Dumps und Cleanup-Backups in /root =="
mapfile -t OLD_DUMPS < <(find /root -maxdepth 1 -type f \( -name "menucard-*.sql" -o -name "menu-content-pre-*" \) ! -newer /root/backups-20260414 2>/dev/null || true)
# Zusätzlich: gezielte Altdateien
for specific in \
    /root/menucard-pre-cleanup-20260410.sql \
    /root/menucard-backup-20260410.sql \
    /root/menucard-pass3-20260414.sql \
    /root/menucard-pass4-20260414.sql \
    /root/menucard-pass5-20260414.sql; do
    [[ -f "$specific" ]] && OLD_DUMPS+=("$specific")
done
# Deduplizieren
mapfile -t OLD_DUMPS < <(printf '%s\n' "${OLD_DUMPS[@]}" | sort -u)

if [[ ${#OLD_DUMPS[@]} -eq 0 ]]; then
    echo "  (keine)"
else
    ARCHIVE_DIR="/root/archive-pre-v1.0"
    for f in "${OLD_DUMPS[@]}"; do
        [[ ! -f "$f" ]] && continue
        size=$(du -h "$f" | cut -f1)
        mtime=$(stat -c "%y" "$f" | cut -d' ' -f1)
        echo "  $size  $mtime  $f  → archiviert nach $ARCHIVE_DIR/"
    done
    if [[ $APPLY -eq 1 ]]; then
        mkdir -p "$ARCHIVE_DIR"
        for f in "${OLD_DUMPS[@]}"; do
            [[ -f "$f" ]] && mv -v "$f" "$ARCHIVE_DIR/"
        done
        echo ""
        echo "  Komprimiere Archiv..."
        tar czf "/root/archive-pre-v1.0-$(date +%Y%m%d).tar.gz" -C /root archive-pre-v1.0
        rm -rf "$ARCHIVE_DIR"
        ls -lh /root/archive-pre-v1.0-*.tar.gz
    fi
fi
echo ""

# ----------------------------------------------
# 4. Alte .pre-security-Dateien aus Phase 1
# ----------------------------------------------
echo "== 4. .pre-security-Backups aus Phase 1 =="
mapfile -t PRE_SEC < <(find /var/www/menucard-pro /root -maxdepth 3 -type f -name "*.pre-security" 2>/dev/null || true)
if [[ ${#PRE_SEC[@]} -eq 0 ]]; then
    echo "  (keine)"
else
    for f in "${PRE_SEC[@]}"; do echo "  $f"; done
    if [[ $APPLY -eq 1 ]]; then
        for f in "${PRE_SEC[@]}"; do rm -v "$f"; done
    fi
fi
echo ""

# ----------------------------------------------
# 5. .next-Build-Cache (regeneriert sich bei npm run build)
# ----------------------------------------------
echo "== 5. .next-Build-Cache =="
if [[ -d /var/www/menucard-pro/.next ]]; then
    size=$(du -sh /var/www/menucard-pro/.next | cut -f1)
    echo "  /var/www/menucard-pro/.next ($size)"
    echo "  HINWEIS: Wird NICHT gelöscht (zur Laufzeit benötigt)."
    echo "  Bei Problemen manuell: rm -rf .next && npm run build && pm2 restart menucard-pro"
fi
echo ""

# ----------------------------------------------
# 6. Festplatten-Status danach
# ----------------------------------------------
echo "== 6. Festplatten-Status =="
df -h / | tail -1
echo ""

# ----------------------------------------------
# 7. Phase 1 / 2 Artefakte im App-Verzeichnis
# ----------------------------------------------
echo "== 7. Phase-Scripts im App-Verzeichnis =="
mapfile -t PHASE_FILES < <(find /var/www/menucard-pro -maxdepth 1 -type f \( -name "phase*-*.sh" -o -name "phase*-*.ps1" -o -name "playwright-admin-tests-*.mjs" \) 2>/dev/null)
if [[ ${#PHASE_FILES[@]} -eq 0 ]]; then
    echo "  (keine)"
else
    echo "  (bleiben liegen — werden per Git verwaltet, nicht automatisch gelöscht)"
    for f in "${PHASE_FILES[@]}"; do echo "  $f"; done
fi
echo ""

echo "=============================================="
if [[ $APPLY -eq 1 ]]; then
    echo "  Cleanup abgeschlossen."
else
    echo "  DRY RUN fertig. Zum Ausführen:"
    echo "    bash phase4-cleanup.sh --apply"
fi
echo "=============================================="
