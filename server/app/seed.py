"""Boshlang'ich ma'lumotlar: 6 real filial + 9 mahsulot (ilovadagi data.dart'dan ko'chirilgan).

Ishga tushirish:  python -m app.seed
Qayta ishga tushirsa mavjudlarini yangilaydi (narxni admin o'zgartirgan bo'lsa, tegmaydi).
"""
from .models import Product, SessionLocal, Store, init_db

STORES = [
    dict(id="beshqayragoch",
         name={"ru": "Zikrilla Бешкайрагач", "en": "Zikrilla Beshkairagach", "uz": "Zikrilla Beshqayrag‘och"},
         address={"ru": "Учтепинский район, 1-й проезд Назарбек, 48",
                  "en": "Uchtepa district, Nazarbek 1st lane, 48",
                  "uz": "Uchtepa tumani, Nazarbek 1-tor ko‘chasi, 48"},
         lat=41.307336, lng=69.161724, phone="+998783337272", open="08:00", close="01:00"),
    dict(id="kokcha",
         name={"ru": "Zikrilla Кукча", "en": "Zikrilla Kukcha", "uz": "Zikrilla Ko‘kcha"},
         address={"ru": "Шайхантахурский район, ул. Шерози, 4",
                  "en": "Shaykhantakhur district, Sherozi st., 4",
                  "uz": "Shayxontohur tumani, Sheroziy ko‘chasi, 4"},
         lat=41.321684, lng=69.210333, phone="+998783337272", open="00:00", close="00:00"),
    dict(id="allon",
         name={"ru": "Zikrilla Аллон", "en": "Zikrilla Allon", "uz": "Zikrilla Allon"},
         address={"ru": "Алмазарский район, ул. Фараби, 291Б",
                  "en": "Almazar district, Farobiy st., 291B",
                  "uz": "Olmazor tumani, Farobiy ko‘chasi, 291B"},
         lat=41.340704, lng=69.215234, phone="+998783337272", open="08:00", close="23:00"),
    dict(id="sulola",
         name={"ru": "Zikrilla Сулола", "en": "Zikrilla Sulola", "uz": "Zikrilla Sulola"},
         address={"ru": "Алмазарский район, Келесское шоссе, 46Б",
                  "en": "Almazar district, Keles road, 46B",
                  "uz": "Olmazor tumani, Keles yo‘li ko‘chasi, 46B"},
         lat=41.369175, lng=69.225361, phone="+998783337272", open="08:00", close="23:00"),
    dict(id="yunusobod",
         name={"ru": "Zikrilla Юнусабад", "en": "Zikrilla Yunusabad", "uz": "Zikrilla Yunusobod"},
         address={"ru": "Юнусабадский район, ул. Богишамол, 215",
                  "en": "Yunusabad district, Bogishamol st., 215",
                  "uz": "Yunusobod tumani, Bog‘ishamol ko‘chasi, 215"},
         lat=41.350853, lng=69.323591, phone="+998783337272", open="08:00", close="23:00"),
    dict(id="humson",
         name={"ru": "Zikrilla Хумсан", "en": "Zikrilla Khumsan", "uz": "Zikrilla Humson"},
         address={"ru": "Бостанлыкский р-н, пос. Чарвак, массив Фазогир, 2",
                  "en": "Bostanlyk district, Charvak, Fazogir area, 2",
                  "uz": "Bo‘stonliq tumani, Chorvoq shaharchasi, Fazogir massivi, 2"},
         lat=41.629762, lng=69.939205, phone="+998783337272", open="10:00", close="23:00"),
]

PRODUCTS = [
    dict(id="lamb", price=16000, image="assets/img/lamb.jpg", category="skewers",
         low_stock=True, rating=4.8, reviews=132, weekly_deal=True, grill_minutes=12,
         name={"ru": "Бараний шашлык", "en": "Lamb skewer", "uz": "Qo‘y six"},
         subtitle={"ru": "Классический маринад · штука 80–85 г", "en": "Classic marinade · 80–85 g per piece",
                   "uz": "Jaydari marinad · donasi 80–85 gr"},
         ingredients={"ru": "Баранина, лук, зира, чёрный перец, соль",
                      "en": "Lamb, onion, cumin, black pepper, salt",
                      "uz": "Qo‘y go‘shti, piyoz, zira, qora qalampir, tuz"}),
    dict(id="chicken", price=8000, image="assets/img/chicken.jpg", category="chicken",
         rating=4.7, reviews=98, grill_minutes=15, weekly_deal=True,
         name={"ru": "Куриное бедро", "en": "Chicken thigh", "uz": "Tovuq bedro"},
         subtitle={"ru": "Сливочно-чесночный маринад · штука 80–85 г",
                   "en": "Creamy garlic marinade · 80–85 g per piece",
                   "uz": "Qaymoqli-sarimsoqli marinad · donasi 80–85 gr"},
         ingredients={"ru": "Куриное бедро, чеснок, йогурт, паприка, соль",
                      "en": "Chicken thigh, garlic, yogurt, paprika, salt",
                      "uz": "Tovuq bedro, sarimsoq, qatiq, paprika, tuz"}),
    dict(id="qiyma", price=10000, image="assets/img/qiyma.jpg", category="minced",
         rating=4.9, reviews=210, grill_minutes=10, weekly_deal=True,
         name={"ru": "Люля гиждуван", "en": "Gijduvon kebab", "uz": "Qiyma g‘ijduvon"},
         subtitle={"ru": "Рубленое мясо по-гиждувански · штука 80–85 г",
                   "en": "Gijduvon-style minced meat · 80–85 g per piece",
                   "uz": "G‘ijduvoncha qiyma · donasi 80–85 gr"},
         ingredients={"ru": "Говядина, курдюк, лук, зира, кориандр, соль",
                      "en": "Beef, lamb fat, onion, cumin, coriander, salt",
                      "uz": "Mol go‘shti, dumba, piyoz, zira, kashnich, tuz"}),
    dict(id="virezka", price=17000, image="assets/img/chef.jpg", category="skewers",
         rating=4.9, reviews=76, grill_minutes=9, spicy=True,
         name={"ru": "Вырезка", "en": "Tenderloin", "uz": "Virezka"},
         subtitle={"ru": "Говяжья вырезка с перцем · штука 80–85 г",
                   "en": "Peppered beef tenderloin · 80–85 g per piece",
                   "uz": "Qalampirli mol virezkasi · donasi 80–85 gr"},
         ingredients={"ru": "Говяжья вырезка, чёрный перец, лук, соль",
                      "en": "Beef tenderloin, black pepper, onion, salt",
                      "uz": "Mol virezkasi, qora qalampir, piyoz, tuz"}),
    dict(id="kofta", price=11000, image="assets/img/qiyma_tray.jpg", category="minced",
         rating=4.6, reviews=54, grill_minutes=10, spicy=True,
         name={"ru": "Люля острое", "en": "Spicy kofta", "uz": "Achchiq qiyma"},
         subtitle={"ru": "С аджикой и перцем · штука 80–85 г",
                   "en": "With adjika and chili · 80–85 g per piece",
                   "uz": "Adjika va qalampir bilan · donasi 80–85 gr"},
         ingredients={"ru": "Говядина, аджика, красный перец, лук, соль",
                      "en": "Beef, adjika, red pepper, onion, salt",
                      "uz": "Mol go‘shti, adjika, qizil qalampir, piyoz, tuz"}),
    dict(id="fish", price=19000, image="assets/img/grill_man.jpg", category="fish",
         low_stock=True, rating=4.5, reviews=31, grill_minutes=7,
         name={"ru": "Шашлык из сёмги", "en": "Salmon skewer", "uz": "Losos six"},
         subtitle={"ru": "Лимон и укроп · штука 80–85 г", "en": "Lemon and dill · 80–85 g per piece",
                   "uz": "Limon va ukrop bilan · donasi 80–85 gr"},
         ingredients={"ru": "Сёмга, лимон, укроп, оливковое масло, соль",
                      "en": "Salmon, lemon, dill, olive oil, salt",
                      "uz": "Losos, limon, ukrop, zaytun moyi, tuz"}),
    dict(id="coal", price=32000, image="assets/img/coal.jpg", category="extras", is_extra=True, reviews=40,
         name={"ru": "Уголь 3 кг", "en": "Coal 3 kg", "uz": "Ko‘mir 3 kg"},
         subtitle={"ru": "Берёзовый уголь для мангала", "en": "Birch charcoal for the grill",
                   "uz": "Mangal uchun qayin ko‘miri"},
         ingredients={"ru": "Берёзовый древесный уголь", "en": "Birch wood charcoal", "uz": "Qayin daraxti ko‘miri"},
         unit={"ru": "упаковка", "en": "pack", "uz": "qadoq"}),
    dict(id="sauce", price=12000, image="assets/img/sauce.jpg", category="extras", is_extra=True, reviews=62,
         name={"ru": "Соус", "en": "Sauce", "uz": "Sous"},
         subtitle={"ru": "Томатный соус с зеленью · 250 г", "en": "Tomato herb sauce · 250 g",
                   "uz": "Ko‘katli pomidor sousi · 250 gr"},
         ingredients={"ru": "Томаты, чеснок, кинза, перец, соль",
                      "en": "Tomatoes, garlic, cilantro, pepper, salt",
                      "uz": "Pomidor, sarimsoq, kashnich, qalampir, tuz"},
         unit={"ru": "шт", "en": "pc", "uz": "dona"}),
    dict(id="skewer", price=18000, image="assets/img/skewer.jpg", category="extras", is_extra=True, reviews=22,
         name={"ru": "Шампуры", "en": "Skewers", "uz": "Shampur"},
         subtitle={"ru": "Набор из 10 стальных шампуров", "en": "Set of 10 steel skewers",
                   "uz": "10 ta po‘lat shampur to‘plami"},
         ingredients={"ru": "Нержавеющая сталь", "en": "Stainless steel", "uz": "Zanglamas po‘lat"},
         unit={"ru": "набор", "en": "set", "uz": "to‘plam"}),
]


def run() -> None:
    init_db()
    db = SessionLocal()
    try:
        for s in STORES:
            row = db.get(Store, s["id"])
            if row is None:
                db.add(Store(**s))
            else:
                for k, v in s.items():
                    setattr(row, k, v)
        for p in PRODUCTS:
            row = db.get(Product, p["id"])
            if row is None:
                db.add(Product(**p))
            else:
                for k, v in p.items():
                    if k == "price":
                        continue  # admin o'zgartirgan narxni seed qayta yozmasin
                    setattr(row, k, v)
        db.commit()
        print(f"Seed OK: {len(STORES)} filial, {len(PRODUCTS)} mahsulot")
    finally:
        db.close()


if __name__ == "__main__":
    run()
