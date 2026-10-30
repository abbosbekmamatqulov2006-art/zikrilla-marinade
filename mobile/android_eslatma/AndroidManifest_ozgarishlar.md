# android papkasi haqida

`android/` papkasi `flutter create` buyrug'i bilan avtomatik yaratiladi,
shuning uchun bu zipda yo'q. Sizning kompyuteringizdagi
C:\dev\zikrilla_marinade\android — haqiqiy nusxa (imzo kaliti shu yerda),
uni ALOHIDA zaxiralang.

Yangidan yaratilsa, android\app\src\main\AndroidManifest.xml ga qo'lda
qo'shilgan 2 ta o'zgarish:

1) <manifest ...> dan keyin, <application dan oldin:
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

2) <application ichiga:
    android:usesCleartextTraffic="true"
   (HTTPS ga o'tilgach bu qatorni olib tashlash kerak)
