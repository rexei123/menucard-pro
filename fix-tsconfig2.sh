#!/bin/bash
cd /var/www/menucard-pro

python3 << 'PYEOF'
import json
with open('tsconfig.json') as f:
    d = json.load(f)
d['exclude'] = ['node_modules', 'scripts', 'tests']
with open('tsconfig.json', 'w') as f:
    json.dump(d, f, indent=2)
print('tsconfig.json exclude:', d['exclude'])
PYEOF

npm run build 2>&1 | tail -10
echo "EXIT=$?"

pm2 restart menucard-pro
sleep 5
echo "=== TEST ==="
echo -n "  menus="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/api/v1/menus; echo
echo -n "  abendkarte="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/restaurant/abendkarte; echo
echo -n "  weinkarte="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/restaurant/weinkarte; echo
echo -n "  barkarte="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/bar/barkarte; echo
echo -n "  admin="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/admin; echo
