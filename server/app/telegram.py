"""Telegram xabarnomalar: yangi buyurtma operatorlar guruhiga tushadi.

.env:  TELEGRAM_BOT_TOKEN=...   TELEGRAM_CHAT_ID=...
Ikkisi bo'lmasa modul jim turadi (hech narsa buzilmaydi).
Yuborish alohida oqimda — Telegram sekin/ishlamay qolsa ham buyurtma to'xtamaydi.
"""
import logging
import os
import threading

import httpx

log = logging.getLogger("telegram")

TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
CHAT_ID = os.getenv("TELEGRAM_CHAT_ID", "")


def enabled() -> bool:
    return bool(TOKEN and CHAT_ID)


def send(text: str) -> None:
    if not enabled():
        return

    def _go():
        try:
            r = httpx.post(
                f"https://api.telegram.org/bot{TOKEN}/sendMessage",
                json={"chat_id": CHAT_ID, "text": text, "disable_web_page_preview": True},
                timeout=10,
            )
            if r.status_code != 200:
                log.warning("telegram %s: %s", r.status_code, r.text[:200])
        except Exception as e:  # noqa: BLE001
            log.warning("telegram yuborilmadi: %s", e)

    threading.Thread(target=_go, daemon=True).start()
