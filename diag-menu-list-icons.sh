#!/bin/bash
cd /var/www/menucard-pro
echo "=== 1. menu-list-panel.tsx (komplett) ==="
cat -n src/components/admin/menu-list-panel.tsx

echo ""
echo "=== 2. Icon-Komponente ==="
cat -n src/components/ui/icon.tsx

echo ""
echo "=== 3. Material Symbols Import in layout / globals ==="
grep -rn "material-symbols" src/app/layout* src/app/admin/ src/styles/ 2>/dev/null | head -20

echo ""
echo "=== 4. celebration / local_bar Vorkommen ==="
grep -rn "celebration\|local_bar" src/ 2>/dev/null | head -20
