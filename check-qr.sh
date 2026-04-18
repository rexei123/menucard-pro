#!/bin/bash
DB="postgresql://menucard:ccTFFSJtuN7l1dC17PzT8Q@127.0.0.1:5432/menucard_pro"
psql "$DB" -c 'SELECT id, "shortCode", label, "menuId", "locationId", "isActive" FROM "QRCode";'
psql "$DB" -c "SELECT column_name FROM information_schema.columns WHERE table_name='QRCode' ORDER BY ordinal_position;"
