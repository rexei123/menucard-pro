#!/bin/bash
# ============================================================================
# Diagnose: Wie laeuft PostgreSQL auf diesem Server?
# ============================================================================
set +e

echo "--- 1. OS-Users 'postgres' / 'pgsql' ---"
getent passwd postgres pgsql 2>&1
echo

echo "--- 2. Was lauscht auf 5432? ---"
ss -tlnp 2>/dev/null | grep -E ':5432|LISTEN' | head -5
echo

echo "--- 3. Docker-Container ---"
if command -v docker >/dev/null 2>&1; then
    docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}' 2>&1
else
    echo "docker nicht installiert"
fi
echo

echo "--- 4. pg_hba.conf finden ---"
find /etc /var/lib -maxdepth 4 -name pg_hba.conf 2>/dev/null | head -5
echo

echo "--- 5. menucard-Rolle: SUPERUSER / CREATEDB / CREATEROLE ---"
export PGPASSWORD=$(grep -oP 'DATABASE_URL=.*:\/\/[^:]+:\K[^@]+' /var/www/menucard-pro/.env 2>/dev/null || echo "")
if [ -n "$PGPASSWORD" ]; then
    psql -h 127.0.0.1 -U menucard -d menucard_pro -tAF ',' -c \
        "SELECT rolname, rolsuper, rolcreatedb, rolcreaterole FROM pg_roles WHERE rolname IN ('menucard','postgres')" \
        2>&1 | head -5
else
    echo "  .env-Passwort nicht extrahierbar"
fi
echo

echo "--- 6. Alle PG-Rollen ---"
if [ -n "$PGPASSWORD" ]; then
    psql -h 127.0.0.1 -U menucard -d menucard_pro -tAc \
        "SELECT rolname FROM pg_roles ORDER BY 1" 2>&1 | head -20
fi
echo

echo "--- 7. postgres via TCP (Peer-Auth testen) ---"
unset PGPASSWORD
psql -h 127.0.0.1 -U postgres -tAc 'SELECT 1' 2>&1 | head -3
echo
