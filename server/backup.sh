#!/bin/bash
# Zikrilla bazasining kunlik zaxira nusxasi. Oxirgi 14 kunini saqlaydi.
set -e
DIR=/root/backups
mkdir -p "$DIR"
cd /root/zikrilla
docker compose exec -T db pg_dump -U postgres zikrilla | gzip > "$DIR/zikrilla_$(date +%F_%H%M).sql.gz"
tar czf "$DIR/uploads_$(date +%F).tar.gz" -C /root/zikrilla uploads 2>/dev/null || true
find "$DIR" -type f -mtime +14 -delete
echo "backup OK: $(ls -1 $DIR | tail -2)"
