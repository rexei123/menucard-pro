#!/bin/bash
DB="postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"
psql "$DB" -c 'SELECT id, email, role, "isActive", "firstName", "lastName" FROM "User";'
