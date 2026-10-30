# Zikrilla mobil ilovasi — to'liq manba kodi (v5)

Tarkib:
- lib/          — ilovaning barcha Dart kodi (ekranlar, server bilan aloqa, katalog, keshbek)
- pubspec.yaml  — kutubxonalar ro'yxati
- assets/img/   — rasmlar va logotip
- android_eslatma/ — android papkasi uchun qo'lda qilingan o'zgarishlar

## Noldan yig'ish (yangi kompyuterda)
1. Flutter, Android Studio o'rnatilgan bo'lsin
2. Shu papkani C:\dev\zikrilla_marinade ga chiqaring
3. cd C:\dev\zikrilla_marinade
   flutter create --org uz.zikrilla --project-name zikrilla_marinade .
4. android_eslatma dagi 2 o'zgarishni AndroidManifest.xml ga kiriting
5. flutter pub get
   flutter build apk --release --dart-define=API_URL=http://95.179.250.214:8000

Diqqat: yangi `flutter create` yangi imzo kaliti yaratadi — bunday APK
eski ilova ustiga o'rnatilmaydi. Shuning uchun asl `android` papkasini saqlang.

## Server
Ilova http://95.179.250.214:8000 serveriga ulanadi (Vultr). Server kodi serverda:
/root/zikrilla. Uni kompyuterga nusxalash:
    scp -r root@95.179.250.214:/root/zikrilla C:\dev\server_nusxa
