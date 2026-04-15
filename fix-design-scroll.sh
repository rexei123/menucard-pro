#!/bin/bash
# Fügt Scroll-Container-Layout für /admin/design/ hinzu
set -e
cd /var/www/menucard-pro

echo "[1/3] layout.tsx für /admin/design/ anlegen..."
cat > src/app/admin/design/layout.tsx << 'ENDOFFILE'
export default function DesignLayout({ children }: { children: React.ReactNode }) {
  return <main className="flex-1 overflow-y-auto">{children}</main>;
}
ENDOFFILE

echo "[2/3] Build..."
rm -rf .next
npm run build 2>&1 | tail -10

echo "[3/3] Restart..."
pm2 restart menucard-pro

echo ""
echo "Fertig. /admin/design kann jetzt gescrollt werden."
