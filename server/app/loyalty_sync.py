"""Keshbek manbai: bizning baza yoki iikoCard.

.env da IIKO_LOYALTY=on bo'lsa:
  - mijoz balansi iikoCard'dan olinadi (sayt kabineti, ilova, panel);
  - ro'yxatdan o'tgan mijoz iiko'da ham ochiladi;
  - keshbek faqat iiko kassasida beriladi/yechiladi (paneldagi Kassa faqat ko'rsatadi).
IIKO_LOYALTY bo'sh/off bo'lsa hammasi avvalgidek bizning bazada ishlaydi.
iiko javob bermasa, xato chiqarmaymiz: oxirgi ma'lum balans ko'rsatiladi.
"""
import logging
import os
import threading
import time

from . import iiko
from .models import SessionLocal, User

log = logging.getLogger("loyalty")

_cache: dict[str, tuple[float, int]] = {}   # phone -> (vaqt, balans)
_CACHE_TTL = 30


def iiko_mode() -> bool:
    return os.getenv("IIKO_LOYALTY", "").lower() in ("on", "true", "1") and iiko.enabled()


def balance(user: User) -> int:
    """Ko'rsatiladigan balans. iiko rejimida iikoCard'dan, xato bo'lsa bizdagi oxirgi qiymat."""
    if not iiko_mode():
        return user.points
    hit = _cache.get(user.phone)
    if hit and time.time() - hit[0] < _CACHE_TTL:
        return hit[1]
    try:
        info = iiko.customer_info(user.phone)
        value = iiko.wallet_balance(info) if info else 0
        if info and info.get("id") and user.iiko_customer_id != info["id"]:
            _remember_id(user.id, info["id"])
    except Exception as e:  # iiko ishlamasa sayt yiqilmasin
        log.warning("iiko balance %s: %s", user.phone, e)
        return hit[1] if hit else user.points
    _cache[user.phone] = (time.time(), value)
    return value


def loyalty_payload(user: User, base: dict) -> dict:
    """schemas.loyalty_json natijasiga haqiqiy balans va manbani qo'shadi."""
    out = dict(base)
    out["balance"] = balance(user)
    out["source"] = "iiko" if iiko_mode() else "local"
    return out


def _remember_id(user_id: str, customer_id: str) -> None:
    db = SessionLocal()
    try:
        u = db.get(User, user_id)
        if u is not None:
            u.iiko_customer_id = customer_id
            db.commit()
    finally:
        db.close()


def sync_customer_async(user_id: str) -> None:
    """Ro'yxatdan o'tgan mijozni iiko'da ochish (fon rejimida, javobni kutdirmaydi)."""
    if not iiko_mode():
        return

    def run():
        db = SessionLocal()
        try:
            u = db.get(User, user_id)
            if u is None:
                return
            info = iiko.ensure_customer(u.phone, u.first_name, u.last_name)
            u.iiko_customer_id = info.get("id")
            db.commit()
            _cache.pop(u.phone, None)
            log.info("iiko: mijoz %s -> %s", u.phone, u.iiko_customer_id)
        except Exception as e:
            log.warning("iiko sync %s: %s", user_id, e)
        finally:
            db.close()

    threading.Thread(target=run, daemon=True).start()


def forget(phone: str) -> None:
    _cache.pop(phone, None)
