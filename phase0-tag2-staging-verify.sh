#!/usr/bin/env bash
set -euo pipefail

SECRET_FILE="/root/.secrets/staging-basic-auth.txt"
STAGING_DOMAIN="staging.menu.hotel-sonnblick.at"

if [ ! -f "$SECRET_FILE" ]; then
    echo "FEHLER: $SECRET_FILE fehlt" >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$SECRET_FILE"

echo "=== ohne Auth ==="
curl -o /dev/null -s -w "HTTP %{http_code}\n" \
    -H "Host: $STAGING_DOMAIN" \
    http://127.0.0.1/

echo "=== mit Auth ==="
curl -o /dev/null -s -w "HTTP %{http_code}\n" \
    -H "Host: $STAGING_DOMAIN" \
    -u "$USER:$PASS" \
    http://127.0.0.1/

echo "=== PM2 ==="
pm2 list --no-color 2>/dev/null | grep -E "(id|menucard)" || pm2 status

echo ""
echo "=== Basic-Auth (Klartext) ==="
echo "User: $USER"
echo "Pass: $PASS"
echo "Domain: $DOMAIN"
