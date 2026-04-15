#!/bin/bash
# MenuCard Pro – Alte Type-Dateien bereinigen
# item.types.ts entfernen, menu.types.ts aktualisieren
# Datum: 10.04.2026

set -e
cd /var/www/menucard-pro

echo "=== Alte Type-Dateien Fix ==="

# Backup
cp src/types/item.types.ts src/types/item.types.ts.bak
cp src/types/menu.types.ts src/types/menu.types.ts.bak
echo "[1/4] Backups erstellt"

# item.types.ts entfernen
rm src/types/item.types.ts
echo "[2/4] item.types.ts entfernt"

# menu.types.ts neu schreiben ohne MenuItemWithDetails
cat > src/types/menu.types.ts << 'EOF'
import type {
  Menu,
  MenuTranslation,
  MenuSection,
  MenuSectionTranslation,
  Location,
  LocationTranslation,
} from '@prisma/client';

export type MenuWithTranslations = Menu & {
  translations: MenuTranslation[];
};

export type MenuWithSections = MenuWithTranslations & {
  sections: (MenuSection & {
    translations: MenuSectionTranslation[];
  })[];
};

export type LocationWithMenus = Location & {
  translations: LocationTranslation[];
  menus: MenuWithTranslations[];
};

export type { Menu, MenuTranslation, MenuSection, MenuSectionTranslation } from '@prisma/client';
EOF
echo "[3/4] menu.types.ts aktualisiert"

# Build + Restart
echo ""
echo "=== Build ==="
npm run build

echo ""
echo "=== PM2 Restart ==="
pm2 restart menucard-pro

echo ""
echo "[4/4] Fertig!"
