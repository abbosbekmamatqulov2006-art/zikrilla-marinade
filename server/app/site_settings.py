"""Sayt/ilova sozlamalari: standart qiymatlar + bazadagi o'zgarishlar."""
import copy

from sqlalchemy.orm import Session

from .models import Setting

KEY = "site"

DEFAULTS: dict = {
    "phone": "+998783337272",
    "operators": [
        {"label": {"uz": "Buyurtma va savollar", "ru": "Заказы и вопросы", "en": "Orders and questions"},
         "phone": "+998783337272"},
    ],
    "telegramOrder": "",
    "social": {"instagram": "", "telegram": "", "youtube": "", "facebook": "", "tiktok": ""},
    "hero": {
        "title": {"uz": "Sixga terilgan, marinadda yetilgan",
                  "ru": "Нанизано на шампур, выдержано в маринаде",
                  "en": "Skewered and rested in marinade"},
        "subtitle": {"uz": "Olovga tashlashga tayyor go'sht — donasiga sotamiz. Qo'ng'iroq qiling: olib ketasiz yoki yetkazib beramiz.",
                     "ru": "Мясо, готовое к огню — продаём поштучно. Позвоните: заберёте сами или привезём.",
                     "en": "Meat that's ready for the fire — sold by the piece. Call us: pick up or get it delivered."},
        "image": "/app/assets/assets/img/hero_mix.jpg",
    },
    "announcement": {"uz": "", "ru": "", "en": ""},
    "about": {"uz": "Sixlangan marinadlar — oilaviy dasturxon uchun. Toshkent va Chorvoqda filiallarimiz bor.",
              "ru": "Маринады на шампурах — для семейного дастархана. Филиалы в Ташкенте и Чарваке.",
              "en": "Skewered marinades for the family table. Branches in Tashkent and Charvak."},
    "videos": [],          # [{"title": {uz,ru,en}, "url": "/uploads/x.mp4" | "https://youtu.be/..."}]
    "categories": [
        {"id": "skewers", "name": {"uz": "Sixlangan", "ru": "Шашлык", "en": "Skewers"}},
        {"id": "minced", "name": {"uz": "Qiyma", "ru": "Люля", "en": "Kebab"}},
        {"id": "chicken", "name": {"uz": "Tovuq", "ru": "Курица", "en": "Chicken"}},
        {"id": "fish", "name": {"uz": "Baliq", "ru": "Рыба", "en": "Fish"}},
        {"id": "sets", "name": {"uz": "Komplektlar", "ru": "Наборы", "en": "Sets"}},
        {"id": "extras", "name": {"uz": "Ko'mir va sous", "ru": "Уголь и соусы", "en": "Coal & sauces"}},
    ],
    "cashback": {
        "percent": 5, "maxShare": 30,
        # Darajalar (tariflar): "from" — jami yig'ilgan ball shu songa yetganda daraja ochiladi
        "tiers": [
            {"id": "bronze", "from": 0,
             "name": {"uz": "Bronza", "ru": "Бронза", "en": "Bronze"},
             "perks": {"uz": "Har xariddan keshbek", "ru": "Кешбэк с каждой покупки", "en": "Cashback on every purchase"}},
            {"id": "silver", "from": 100000,
             "name": {"uz": "Kumush", "ru": "Серебро", "en": "Silver"},
             "perks": {"uz": "Doimiy mijozlar uchun", "ru": "Для постоянных клиентов", "en": "For regular customers"}},
            {"id": "gold", "from": 300000,
             "name": {"uz": "Oltin", "ru": "Золото", "en": "Gold"},
             "perks": {"uz": "Eng sodiq mijozlar uchun", "ru": "Для самых преданных клиентов", "en": "For our most loyal customers"}},
        ],
        "note": {"uz": "Ball kassada beriladi va kassada ishlatiladi. Xarid paytida telefon raqamingizni ayting.",
                 "ru": "Баллы начисляются и списываются на кассе. Назовите номер телефона при покупке.",
                 "en": "Points are earned and spent at the till. Give your phone number when you pay."},
    },
    # ---------------- mobil ilova ----------------
    "app": {
        "ordering": "call",            # call — qo'ng'iroq/Telegram orqali; cart — ilovada savat va buyurtma
        "banners": [],                 # [{"image","title":{},"subtitle":{},"link":"catalog|cat:<id>|school|url:https://..."}]
        "sections": {                  # bosh sahifadagi bo'limlar: true — ko'rinadi, false — yashirin
            "categories": True, "calculator": True, "school": True,
            "videos": True, "deals": True, "stores": True, "contacts": True,
        },
        "school": [
            {"id": "skewer-guide", "image": "/app/assets/assets/img/guide_hero.jpg", "video": "", "minutes": 4,
             "title": {"uz": "Sixga qanday terish kerak", "ru": "Как правильно нанизывать шашлык",
                       "en": "How to skewer meat properly"},
             "text": {
                 "uz": "1. Sixni namlab oling. Yog'och six bo'lsa 20 daqiqa suvda turishi kerak — mangalda kuymaydi.\n\n"
                       "2. Go'shtni tola bo'ylab tering. Six tolani kesib o'tsa, go'sht pishganda to'kilib ketadi.\n\n"
                       "3. Yog'ni oralatib joylang. Har 2 bo'lak go'shtdan keyin 1 bo'lak dumba — shira ichida qoladi.\n\n"
                       "4. Tez-tez aylantirmang. Har 2–3 daqiqada aylantiring, mangalda jami 12 daqiqa.\n\n"
                       "Muhim: go'sht bo'laklari orasida 2–3 mm joy qoldiring — shunda ichi pishadi.",
                 "ru": "1. Замочите шампуры. Деревянные шампуры держите 20 минут в воде — на мангале не сгорят.\n\n"
                       "2. Нанизывайте поперёк волокон. Тогда мясо не развалится при жарке.\n\n"
                       "3. Чередуйте с курдюком. После каждых 2 кусочков мяса — 1 кусочек курдюка, сок останется внутри.\n\n"
                       "4. Не переворачивайте часто. Каждые 2–3 минуты, всего 12 минут на мангале.\n\n"
                       "Важно: оставляйте 2–3 мм между кусочками — так мясо прожарится внутри.",
                 "en": "1. Soak the skewers. Keep wooden skewers in water for 20 minutes so they don't burn.\n\n"
                       "2. Skewer across the grain so the pieces don't fall apart while cooking.\n\n"
                       "3. Alternate with fat: after every 2 pieces of meat add 1 piece of fat to keep the juices in.\n\n"
                       "4. Don't flip too often: turn every 2–3 minutes, 12 minutes total on the grill.\n\n"
                       "Important: leave 2–3 mm between pieces so the meat cooks through."}},
        ],
    },
}


def _merge(base: dict, over: dict) -> dict:
    out = copy.deepcopy(base)
    for k, v in (over or {}).items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = _merge(out[k], v)
        else:
            out[k] = v
    return out


_current_tiers: list = DEFAULTS["cashback"]["tiers"]


def current_tiers() -> list:
    """Oxirgi o'qilgan sozlamalardagi darajalar (tier hisoblash uchun, bazaga murojaatsiz)."""
    return _current_tiers


def get_site(db: Session) -> dict:
    global _current_tiers
    row = db.get(Setting, KEY)
    site = _merge(DEFAULTS, row.value if row and isinstance(row.value, dict) else {})
    tiers = (site.get("cashback") or {}).get("tiers")
    if isinstance(tiers, list) and tiers:
        _current_tiers = tiers
    return site


def save_site(db: Session, value: dict) -> dict:
    row = db.get(Setting, KEY)
    if row is None:
        row = Setting(key=KEY, value=value)
        db.add(row)
    else:
        row.value = value
    db.commit()
    return get_site(db)


def cashback_percent(db: Session) -> float:
    try:
        return float(get_site(db)["cashback"]["percent"])
    except (KeyError, TypeError, ValueError):
        return 5.0


def cashback_max_share(db: Session) -> float:
    try:
        return float(get_site(db)["cashback"]["maxShare"]) / 100
    except (KeyError, TypeError, ValueError):
        return 0.3
