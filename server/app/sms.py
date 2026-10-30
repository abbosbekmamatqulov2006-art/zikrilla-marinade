"""SMS yuborish qatlami.

SMS_PROVIDER=mock  -> hech narsa yuborilmaydi, kod log'da ko'rinadi (DEBUG=true bo'lsa javobda ham qaytadi)
SMS_PROVIDER=eskiz -> Eskiz.uz orqali real SMS (shartnoma + alfa-nomer tayyor bo'lgach .env to'ldiriladi)
"""
import logging
import time

import httpx

from . import config

log = logging.getLogger("sms")


class SmsError(Exception):
    pass


def send_sms(phone: str, text: str) -> None:
    if config.SMS_PROVIDER == "eskiz":
        _eskiz_send(phone, text)
    else:
        log.info("MOCK SMS -> +%s: %s", phone, text)


# ---------------- Eskiz.uz ----------------
_eskiz_token: str | None = None
_eskiz_token_at: float = 0.0
_TOKEN_TTL = 20 * 24 * 3600  # Eskiz tokeni ~30 kun yashaydi; 20 kunda yangilaymiz


def _eskiz_auth() -> str:
    global _eskiz_token, _eskiz_token_at
    if _eskiz_token and time.time() - _eskiz_token_at < _TOKEN_TTL:
        return _eskiz_token
    r = httpx.post(
        "https://notify.eskiz.uz/api/auth/login",
        data={"email": config.ESKIZ_EMAIL, "password": config.ESKIZ_PASSWORD},
        timeout=15,
    )
    if r.status_code != 200:
        raise SmsError(f"Eskiz auth failed: {r.status_code} {r.text[:200]}")
    _eskiz_token = r.json()["data"]["token"]
    _eskiz_token_at = time.time()
    return _eskiz_token


def _eskiz_send(phone: str, text: str) -> None:
    token = _eskiz_auth()
    r = httpx.post(
        "https://notify.eskiz.uz/api/message/sms/send",
        headers={"Authorization": f"Bearer {token}"},
        data={"mobile_phone": phone, "message": text, "from": config.ESKIZ_FROM},
        timeout=15,
    )
    if r.status_code not in (200, 201):
        raise SmsError(f"Eskiz send failed: {r.status_code} {r.text[:200]}")
