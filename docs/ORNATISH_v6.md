# Zikrilla v6 — ma'lumot sayti + kuchli admin panel

## Nima o'zgaradi
- SAYT (/) — faqat ma'lumot: menyu va narxlar, mahsulot oynasida rasm/video galereya,
  filiallar (qo'ng'iroq + Yandex/Google yo'l), videolar, ijtimoiy tarmoqlar, operatorlar.
  Buyurtma — telefon/Telegram orqali. Mijoz xohlasa kabinetda keshbek balansi va QR kodini ko'radi.
- PANEL (/panel) — 6 bo'lim:
  Kassa (keshbek qo'shish/yechish/bekor qilish), Buyurtmalar (mobil ilovadan),
  Mahsulotlar (bir nechta rasm+video, jadvalda tez narx o'zgartirish),
  Filiallar (yangi qo'shish, xarita havolasidan joylashuv, ish vaqti, rasm),
  Sozlamalar (telefonlar, operatorlar, ijtimoiy tarmoqlar, bosh sahifa, e'lon,
  videolar, keshbek foizi, kategoriyalar), Mijozlar (qidiruv).
- MOBIL ILOVA (v5) — mahsulot, narx, rasm va filiallarni serverdan oladi:
  paneldagi o'zgarishlar ilovada ham ko'rinadi. Ilovani qayta yig'ish SHART EMAS.
- Mavjud mijozlar, ballar, buyurtmalar SAQLANADI (baza o'zi yangilanadi).

## O'RNATISH

1) Windows PowerShell:
   scp C:\dev\zikrilla_v6.zip root@95.179.250.214:/root/

2) Serverda (ssh root@95.179.250.214), bittadan:

   cd /root/zikrilla
   docker compose exec -T db pg_dump -U postgres zikrilla > /root/baza_v6dan_oldin.sql
   cp -r app /root/app_v5_nusxa
   cp -r site /root/site_v5_nusxa
   unzip -o /root/zikrilla_v6.zip
   docker compose up -d --build

3) Tekshirish:
   curl -s localhost:8000/health        -> "version":"0.6.0" chiqishi kerak
   Brauzer: http://95.179.250.214:8000/          (sayt, Ctrl+Shift+R)
            http://95.179.250.214:8000/panel     (panel)

4) Birinchi ish — panel > Sozlamalar: telefonlar, ijtimoiy tarmoq havolalari,
   operatorlar -> "Hammasini saqlash". Keyin Filiallar'da telefonlarni tekshiring.

## Agar nimadir ishlamasa — ORQAGA QAYTARISH (2 daqiqa)
   cd /root/zikrilla
   rm -rf app site && cp -r /root/app_v5_nusxa app && cp -r /root/site_v5_nusxa site
   docker compose up -d --build
(Baza yangi ustunlarga ega bo'ladi, lekin eski kod ularni e'tiborsiz qoldiradi — ishlayveradi.)

## Kunlik zaxira (agar hali o'rnatilmagan bo'lsa)
   cp /root/zikrilla/backup.sh /root/backup.sh && chmod +x /root/backup.sh && /root/backup.sh
   (crontab -l 2>/dev/null; echo "0 3 * * * /root/backup.sh >> /root/backup.log 2>&1") | crontab -

## Kassa uchun maslahat
- Har filial kompyuterida /panel ochiq tursin, yuqorida o'z filialini tanlasin.
- USB QR/shtrix-kod skaneri (arzon) ulansa, mijoz telefonidagi QR'ni skanerlash
  raqamni o'zi yozadi. Skanersiz — raqamni qo'lda yozish ham bo'ladi.
- Xato kiritilsa — "Oxirgi harakatlar"da "Bekor" tugmasi.
