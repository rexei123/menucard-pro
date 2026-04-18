#!/bin/bash
cd /var/www/menucard-pro
DB="postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"

# Neuen bcrypt-Hash generieren
HASH=$(node -e "const bcrypt = require('bcryptjs'); console.log(bcrypt.hashSync('Sonnblick2026%', 10));")

echo "Hash: $HASH"

psql "$DB" -c "UPDATE \"User\" SET \"passwordHash\" = '$HASH' WHERE email = 'admin@hotel-sonnblick.at';"
echo "Passwort zurueckgesetzt."
