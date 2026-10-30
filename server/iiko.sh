#!/bin/bash
# iikoCard tekshiruvlari. Ishlatish (serverda, /root/zikrilla ichida):
#   bash iiko.sh status              -> dastur va hamyon, rejim
#   bash iiko.sh mijoz 998901234567  -> iiko'dagi mijoz va balans
#   bash iiko.sh kochirish-sinov     -> kim va qancha ball ko'chishini ko'rsatadi (hech narsa o'zgarmaydi)
#   bash iiko.sh kochirish           -> ballarni haqiqatan iiko'ga ko'chiradi (bir marta)
cd "$(dirname "$0")"
K=$(grep '^ADMIN_KEY=' .env | head -1 | cut -d= -f2- | awk '{print $1}')
U=http://localhost:8000/admin/iiko
case "$1" in
  status)          curl -s -H "X-Admin-Key: $K" "$U/loyalty/status" ;;
  mijoz)           curl -s -H "X-Admin-Key: $K" "$U/loyalty/customer?phone=$2" ;;
  kochirish-sinov) curl -s -X POST -H "X-Admin-Key: $K" "$U/loyalty/migrate?dry_run=true" ;;
  kochirish)       curl -s -X POST -H "X-Admin-Key: $K" "$U/loyalty/migrate?dry_run=false" ;;
  *) echo "bash iiko.sh status | mijoz <telefon> | kochirish-sinov | kochirish"; exit 1 ;;
esac | python3 -m json.tool
