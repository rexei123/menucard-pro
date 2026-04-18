#!/bin/bash
cd /var/www/menucard-pro

# tsconfig.json: scripts/ aus Build ausschliessen
python3 -c "
import json
with open('tsconfig.json') as f:
    d = json.load(f)
d['exclude'] = ['node_modules', 'scripts']
with open('tsconfig.json', 'w') as f:
    json.dump(d, f, indent=2)
print('tsconfig.json updated')
"

cat tsconfig.json | grep -A1 exclude

# Build
echo "=== npm run build ==="
npm run build 2>&1 | tail -10
echo "EXIT_CODE=$?"

# Restart + Test
pm2 restart menucard-pro
sleep 4
echo "=== Schnelltest ==="
echo -n "menus="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/api/v1/menus; echo
echo -n "abendkarte="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/restaurant/abendkarte; echo
echo -n "weinkarte="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/restaurant/weinkarte; echo
echo -n "barkarte="; curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/hotel-sonnblick/bar/barkarte; echo
