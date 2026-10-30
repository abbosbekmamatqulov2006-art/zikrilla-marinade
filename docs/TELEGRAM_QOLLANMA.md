# 1) Buyurtmalar Telegram guruhga tushishi

## A. Bot yaratish (telefonda, 3 daqiqa)
1. Telegram'da @BotFather ni oching -> /newbot
2. Nom: Zikrilla Buyurtmalar ; username: masalan zikrilla_orders_bot
3. BotFather TOKEN beradi (123456:ABC-...) — saqlang, hech kimga bermang.

## B. Operatorlar guruhi
1. Telegram'da yangi guruh: "Zikrilla — buyurtmalar", operatorlarni qo'shing
2. Botni ham guruhga qo'shing
3. Guruhga istalgan xabar yozing (masalan: test)
4. Brauzerda oching (TOKEN o'rniga o'zingiznikini):
   https://api.telegram.org/botTOKEN/getUpdates
   Javobda "chat":{"id":-100xxxxxxxxx ...} — shu minusli raqam CHAT_ID.

## C. Serverga o'rnatish
Windows PowerShell (zip chiqarilgan papkada):
   scp app\telegram.py root@95.179.250.214:/root/zikrilla/app/telegram.py
   scp app\routers\core_routes.py root@95.179.250.214:/root/zikrilla/app/routers/core_routes.py
   scp backup.sh root@95.179.250.214:/root/backup.sh

Serverda (ssh root@95.179.250.214):
   nano /root/zikrilla/.env
     oxiriga 2 qator:
     TELEGRAM_BOT_TOKEN=123456:ABC-...
     TELEGRAM_CHAT_ID=-100xxxxxxxxx
     (Ctrl+O, Enter, Ctrl+X)
   cd /root/zikrilla && docker compose up -d --build

Tekshirish: saytdan buyurtma bering -> guruhga darhol xabar keladi.

# 2) Kunlik zaxira nusxa (MUHIM — hozir bazaning nusxasi yo'q)
Serverda:
   chmod +x /root/backup.sh && /root/backup.sh
   (crontab -l 2>/dev/null; echo "0 3 * * * /root/backup.sh >> /root/backup.log 2>&1") | crontab -
Har kuni 03:00 da /root/backups ga nusxa tushadi, 14 kunlik saqlanadi.
