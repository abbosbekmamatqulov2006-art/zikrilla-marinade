"""Telefon ekraniga push-xabar (Firebase Cloud Messaging, HTTP v1).

Sozlash: Firebase konsolidan "service account" JSON faylini yuklab, serverda
/root/zikrilla/app/firebase.json ga qo'yasiz (yoki .env da FCM_CREDENTIALS=yo'l).
Fayl bo'lmasa push yuborilmaydi — xabarlar baribir ilova ichidagi qutida ko'rinadi.

Ilova "all_uz", "all_ru", "all_en" mavzulariga (topic) obuna bo'ladi —
hammaga xabar shu mavzular orqali, shaxsiy xabar esa telefon tokeni orqali ketadi.
"""
import json
import logging
import os
import threading
import time

import httpx

log = logging.getLogger("push")

CRED_PATH = os.getenv("FCM_CREDENTIALS", os.path.join(os.path.dirname(os.path.abspath(__file__)), "firebase.json"))
_token: str | None = None
_token_at = 0.0
_project: str | None = None
_lock = threading.Lock()


def configured() -> bool:
    return os.path.isfile(CRED_PATH)


def project_id() -> str | None:
    global _project
    if _project is None and configured():
        try:
            with open(CRED_PATH, encoding="utf-8") as f:
                _project = json.load(f).get("project_id")
        except Exception as e:
            log.warning("firebase.json o'qilmadi: %s", e)
    return _project


def _access_token() -> str:
    global _token, _token_at
    with _lock:
        if _token and time.time() - _token_at < 45 * 60:
            return _token
        from google.auth.transport.requests import Request
        from google.oauth2 import service_account

        creds = service_account.Credentials.from_service_account_file(
            CRED_PATH, scopes=["https://www.googleapis.com/auth/firebase.messaging"])
        creds.refresh(Request())
        _token, _token_at = creds.token, time.time()
        return _token


def _send(message: dict) -> int:
    """Bitta xabar. Qaytaradi: HTTP status (404 — token eskirgan)."""
    url = f"https://fcm.googleapis.com/v1/projects/{project_id()}/messages:send"
    r = httpx.post(url, json={"message": message},
                   headers={"Authorization": f"Bearer {_access_token()}"}, timeout=20)
    if r.status_code != 200:
        log.warning("FCM %s: %s", r.status_code, r.text[:300])
    return r.status_code


def _payload(title: str, body: str, image: str | None, link: str | None, nid: int | None) -> dict:
    n = {"title": title[:120], "body": (body or "")[:240]}
    if image:
        n["image"] = image
    return {
        "notification": n,
        "data": {"link": link or "", "id": str(nid or "")},
        "android": {"priority": "high", "notification": {"channel_id": "zikrilla"}},
    }


def broadcast(title: dict, body: dict | None, image: str | None, link: str | None, nid: int | None) -> None:
    """Hammaga: har til uchun o'z mavzusiga. Fon rejimida."""
    if not configured():
        return

    def run():
        for lang in ("uz", "ru", "en"):
            try:
                t = (title or {}).get(lang) or (title or {}).get("uz") or ""
                b = (body or {}).get(lang) or (body or {}).get("uz") or ""
                _send({"topic": f"all_{lang}", **_payload(t, b, image, link, nid)})
            except Exception as e:
                log.warning("push broadcast %s: %s", lang, e)

    threading.Thread(target=run, daemon=True).start()


def to_tokens(tokens: list[str], lang: str, title: dict, body: dict | None, image: str | None,
              link: str | None, nid: int | None, on_dead=None) -> None:
    """Bitta mijozning telefonlariga. Eskirgan tokenlar on_dead(token) bilan o'chiriladi."""
    if not configured() or not tokens:
        return

    def run():
        t = (title or {}).get(lang) or (title or {}).get("uz") or ""
        b = (body or {}).get(lang) or (body or {}).get("uz") or ""
        for tok in tokens:
            try:
                if _send({"token": tok, **_payload(t, b, image, link, nid)}) == 404 and on_dead:
                    on_dead(tok)
            except Exception as e:
                log.warning("push token: %s", e)

    threading.Thread(target=run, daemon=True).start()
