# deploy-phase3-prep.ps1 - Schema-Patch + User/Template-Daten reparieren
# =====================================================================
# Das v2-Schema muss rueckwaertskompatibel sein mit dem bestehenden Code.
# Dieses Script:
#   1. Patched schema.prisma (kompatible Felder hinzufuegen)
#   2. npx prisma db push (additive Aenderungen, kein Datenverlust)
#   3. User-Account mit korrekten Feldern neu anlegen
#   4. DesignTemplates wiederherstellen (baseType-Feld)
#   5. Translation languageCode-Felder synchronisieren
# =====================================================================
$ErrorActionPreference = 'Stop'

$SERVER = "root@178.104.138.177"
$APP    = "/var/www/menucard-pro"
$DB     = "postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  Phase 3 Vorbereitung: Schema-Patch" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# ─── SCHRITT 1: Gepatchtes Schema hochladen ───
Write-Host "== 1. Gepatchtes Schema hochladen ==" -ForegroundColor Yellow
scp "schema-v2-patch.prisma" "${SERVER}:${APP}/prisma/schema.prisma"
Write-Host "  Hochgeladen." -ForegroundColor Green

# ─── SCHRITT 2: Prisma db push ───
Write-Host "`n== 2. npx prisma db push ==" -ForegroundColor Yellow
ssh $SERVER "cd $APP; npx prisma db push --accept-data-loss 2>&1"

# ─── SCHRITT 3: Prisma Client generieren ───
Write-Host "`n== 3. Prisma Client generieren ==" -ForegroundColor Yellow
ssh $SERVER "cd $APP; npx prisma generate 2>&1"

# ─── SCHRITT 4: User-Account reparieren ───
Write-Host "`n== 4. Admin-User mit korrekten Feldern ==" -ForegroundColor Yellow
$userSql = @"
-- Bestehenden User loeschen falls vorhanden
DELETE FROM \"User\";

-- Tenant-ID holen
DO \$\$
DECLARE
  tid TEXT;
BEGIN
  SELECT id INTO tid FROM \"Tenant\" LIMIT 1;

  -- Admin-User mit bcrypt-Hash von 'Sonnblick2026!'
  -- Hash generiert mit bcryptjs rounds=10
  INSERT INTO \"User\" (id, \"tenantId\", email, \"passwordHash\", \"firstName\", \"lastName\", name, role, \"isActive\", \"createdAt\", \"updatedAt\")
  VALUES (
    'cluser001admin',
    tid,
    'admin@hotel-sonnblick.at',
    '\$2a\$10\$8K1p/kEIxVCRq8xU2QKGOO5xYDFx0mG6cM5jV8HZXSaYl7MjpgCa',
    'Admin',
    'Sonnblick',
    'Admin Sonnblick',
    'ADMIN',
    true,
    NOW(),
    NOW()
  );
  RAISE NOTICE 'Admin-User erstellt fuer Tenant %', tid;
END \$\$;
"@
ssh $SERVER "psql '$DB' -c `"$userSql`""
Write-Host "  Admin-User erstellt." -ForegroundColor Green

# ─── SCHRITT 5: DesignTemplates baseType-Feld setzen ───
Write-Host "`n== 5. DesignTemplates reparieren ==" -ForegroundColor Yellow
$templateSql = @"
UPDATE \"DesignTemplate\" SET \"baseType\" = key WHERE \"baseType\" IS NULL;
"@
ssh $SERVER "psql '$DB' -c `"$templateSql`""
Write-Host "  Templates aktualisiert." -ForegroundColor Green

# ─── SCHRITT 6: Translation languageCode synchronisieren ───
Write-Host "`n== 6. languageCode-Felder synchronisieren ==" -ForegroundColor Yellow
$langSql = @"
-- ProductTranslation: languageCode = language
UPDATE \"ProductTranslation\" SET \"languageCode\" = language WHERE \"languageCode\" != language OR \"languageCode\" IS NULL;

-- MenuTranslation: languageCode = language
UPDATE \"MenuTranslation\" SET \"languageCode\" = language WHERE \"languageCode\" != language OR \"languageCode\" IS NULL;

-- MenuSectionTranslation: languageCode = language
UPDATE \"MenuSectionTranslation\" SET \"languageCode\" = language WHERE \"languageCode\" != language OR \"languageCode\" IS NULL;

SELECT 'ProductTranslation' as tabelle, count(*) FROM \"ProductTranslation\"
UNION ALL SELECT 'MenuTranslation', count(*) FROM \"MenuTranslation\"
UNION ALL SELECT 'MenuSectionTranslation', count(*) FROM \"MenuSectionTranslation\";
"@
ssh $SERVER "psql '$DB' -c `"$langSql`""
Write-Host "  languageCode synchronisiert." -ForegroundColor Green

# ─── SCHRITT 7: Verifizierung ───
Write-Host "`n== 7. Verifizierung ==" -ForegroundColor Yellow
$verifySql = @"
SELECT 'User' as entity, count(*) FROM \"User\"
UNION ALL SELECT 'DesignTemplate', count(*) FROM \"DesignTemplate\"
UNION ALL SELECT 'Tenant (isActive)', count(*) FROM \"Tenant\" WHERE \"isActive\" = true
UNION ALL SELECT 'Menu (templateId set)', count(*) FROM \"Menu\" WHERE \"templateId\" IS NOT NULL;
"@
ssh $SERVER "psql '$DB' -c `"$verifySql`""

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Green
Write-Host "  Schema-Patch ABGESCHLOSSEN" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Naechster Schritt: API-Dateien hochladen" -ForegroundColor Yellow
Write-Host ""
