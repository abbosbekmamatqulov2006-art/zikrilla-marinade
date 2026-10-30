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
    "cashback": {"percent": 5, "maxShare": 30},
}


def _merge(base: dict, over: dict) -> dict:
    out = copy.deepcopy(base)
    for k, v in (over or {}).items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = _merge(out[k], v)
        else:
            out[k] = v
    return out


def get_site(db: Session) -> dict:
    row = db.get(Setting, KEY)
    return _merge(DEFAULTS, row.value if row and isinstance(row.value, dict) else {})


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
