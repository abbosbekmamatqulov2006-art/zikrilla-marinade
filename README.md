# Zikrilla Marinade — sayt, admin panel, mobil ilova

Zikrilla Marinade (Toshkent, 6 filial) uchun mijozlar sayti, admin panel, keshbek tizimi va Flutter mobil ilova.

- **Sayt** — mahsulotlar, narxlar, rasm/videolar, filiallar, operatorlar. Buyurtma telefon yoki Telegram orqali.
- **Admin panel** (`/panel/`) — mahsulot, narx, filial, sozlamalar, kassa-keshbek, mijozlar.
- **Keshbek** — faqat kassada beriladi/yechiladi; mijoz balansini sayt va ilovada ko'radi.
- **Mobil ilova** — Flutter (Android + iOS), ma'lumotlarni shu serverdan oladi.

## Tuzilishi

```
server/            FastAPI + PostgreSQL backend
  app/             API kodi (routers/, models.py, sms.py, iiko.py, telegram.py ...)
  site/            Asosiy sayt (index.html)
  panel/           Admin panel (index.html)
  Dockerfile, docker-compose.yml, .env.example, backup.sh
mobile/            Flutter ilova (lib/, assets/, pubspec.yaml)
docs/              O'rnatish, iiko va Telegram qo'llanmalari
```

## Serverni ishga tushirish

```bash
cd server
cp .env.example .env      # qiymatlarni to'ldiring
docker compose up -d --build
curl -s localhost:8000/health
```

- Sayt: `http://<server>:8000/`
- Panel: `http://<server>:8000/panel/` (kalit: `.env` dagi `ADMIN_KEY`)
- API hujjatlari: `http://<server>:8000/docs`

Test rejimi: `.env` da `DEBUG=true` va `SMS_PROVIDER=mock` — SMS yuborilmaydi, kod javobda qaytadi.

## Mobil ilova

```bash
cd mobile
flutter create . --platforms=android,ios   # android/ va ios/ papkalarini yaratish (bir marta)
flutter pub get
flutter build apk --release --dart-define=API_URL=https://<domen>
```

`android/`, `ios/` papkalari va imzo kaliti (keystore) repoda **yo'q** — ular ilova egasida saqlanadi.
AndroidManifest uchun eslatmalar: `mobile/android_eslatma/`.

## Xavfsizlik

- `.env`, imzo kalitlari, baza nusxalari va yuklangan fayllar repoga yuklanmaydi (`.gitignore`).
- Kodda hech qanday parol yoki kalit yo'q; hammasi `.env` orqali beriladi.
- `ADMIN_KEY` ni albatta uzun va tasodifiy qiling: standart qiymat (`admin`) faqat lokal sinov uchun.

## Litsenziya

Kod "SHUXRAT DODA" MChJ (Zikrilla Marinade) mulki. Ko'rish uchun ochiq; ruxsatsiz tijoriy foydalanish taqiqlanadi.
