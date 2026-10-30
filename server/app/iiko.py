"""iikoCloud integratsiyasi.

.env talab qiladi: IIKO_API_LOGIN, IIKO_APP_ID, IIKO_CLIENT_SECRET
Token 1 soat yashaydi — 50 daqiqada avtomatik yangilanadi.
"""
import logging
import os
import time

import httpx

log = logging.getLogger("iiko")

IIKO_BASE = os.getenv("IIKO_BASE", "https://api-ru.iiko.services")
IIKO_API_LOGIN = os.getenv("IIKO_API_LOGIN", "")
IIKO_APP_ID = os.getenv("IIKO_APP_ID", "")
IIKO_CLIENT_SECRET = os.getenv("IIKO_CLIENT_SECRET", "")

# Bizning filial id -> iiko organizationId (organizations so'rovidan tasdiqlangan)
ORG_MAP = {
    "kokcha": "2ee6702d-dbc8-4265-88e1-f6e46f83a752",
    "sulola": "40303fac-90a7-4f9c-b1c1-3f9c1244ca48",
    "allon": "9a5b6c34-8bec-46b2-9e27-5b9c30192ecc",
    "yunusobod": "101d3da8-ae06-4d77-a266-d93ed6317de0",
    "beshqayragoch": "17d2c235-6c10-4064-89e7-b3b2cac42cd4",
    "humson": "2982979d-340c-4024-be5d-6c1c038dbc62",
}


class IikoError(Exception):
    pass


_token: str | None = None
_token_at: float = 0.0
_TOKEN_TTL = 50 * 60  # 50 daqiqa


def enabled() -> bool:
    return bool(IIKO_API_LOGIN and IIKO_APP_ID and IIKO_CLIENT_SECRET)


def _get_token() -> str:
    global _token, _token_at
    if _token and time.time() - _token_at < _TOKEN_TTL:
        return _token
    r = httpx.post(
        f"{IIKO_BASE}/api/v2/access_token",
        json={"apiLogin": IIKO_API_LOGIN, "appId": IIKO_APP_ID, "clientSecret": IIKO_CLIENT_SECRET},
        timeout=20,
    )
    if r.status_code != 200 or "token" not in r.json():
        raise IikoError(f"iiko auth failed: {r.status_code} {r.text[:300]}")
    _token = r.json()["token"]
    _token_at = time.time()
    return _token


def _post(path: str, body: dict) -> dict:
    r = httpx.post(
        f"{IIKO_BASE}{path}",
        json=body,
        headers={"Authorization": f"Bearer {_get_token()}"},
        timeout=30,
    )
    data = r.json() if r.content else {}
    if r.status_code != 200:
        raise IikoError(f"iiko {path}: {r.status_code} {str(data)[:300]}")
    return data


# ---------- ma'lumot olish ----------
def organizations() -> list[dict]:
    return _post("/api/1/organizations", {}).get("organizations", [])


def terminal_groups(org_id: str) -> list[dict]:
    out = _post("/api/1/terminal_groups", {"organizationIds": [org_id]}).get("terminalGroups", [])
    items: list[dict] = []
    for g in out:
        items.extend(g.get("items", []))
    return items


def external_menus() -> dict:
    """{'externalMenus': [...], 'priceCategories': [...]}"""
    return _post("/api/2/menu", {})


def menu_by_id(menu_id: str, org_ids: list[str]) -> dict:
    """Tashqi menyu tarkibi (itemCategories -> items, narxlar bilan)."""
    return _post("/api/2/menu/by_id", {"externalMenuId": menu_id, "organizationIds": org_ids})


def status() -> dict:
    """Tez tekshiruv: ulanish + tashkilotlar + tashqi menyular."""
    orgs = organizations()
    menus = external_menus().get("externalMenus", [])
    return {
        "connected": True,
        "organizations": [{"id": o["id"], "name": o["name"]} for o in orgs],
        "externalMenus": menus,
        "orgMapCovered": sorted(ORG_MAP.keys()),
    }


# ================= iikoCard (loyallik) =================
# Mijozlar bazasi butun tarmoq uchun bitta; so'rovlar bitta tashkilot nomidan yuboriladi.
LOYALTY_ORG = os.getenv("IIKO_LOYALTY_ORG", ORG_MAP["yunusobod"])
_program_cache: dict | None = None
_program_at: float = 0.0


def iiko_phone(phone: str) -> str:
    """998XXXXXXXXX -> +998XXXXXXXXX (iiko shu formatni kutadi)."""
    return "+" + phone.lstrip("+")


def loyalty_program() -> dict:
    """Faol bonus dasturi: {'id', 'name', 'walletId'}. 1 soat keshlanadi."""
    global _program_cache, _program_at
    if _program_cache and time.time() - _program_at < 3600:
        return _program_cache
    d = _post("/api/1/loyalty/iiko/program", {"organizationId": LOYALTY_ORG, "withoutMarketingCampaigns": True})
    progs = d.get("Programs") or d.get("programs") or []
    active = [p for p in progs if p.get("isActive")] or progs
    if not active:
        raise IikoError("iikoCard: faol loyallik dasturi topilmadi")
    p = active[0]
    _program_cache = {"id": p.get("id"), "name": p.get("name"), "walletId": p.get("walletId")}
    _program_at = time.time()
    return _program_cache


def customer_info(phone: str) -> dict | None:
    """Mijoz iiko'da bo'lsa ma'lumoti, bo'lmasa None."""
    r = httpx.post(
        f"{IIKO_BASE}/api/1/loyalty/iiko/customer/info",
        json={"organizationId": LOYALTY_ORG, "type": "phone", "phone": iiko_phone(phone)},
        headers={"Authorization": f"Bearer {_get_token()}"},
        timeout=30,
    )
    if r.status_code == 200:
        d = r.json()
        return d if d.get("id") else None
    if r.status_code == 400:          # iiko "bunday mijoz yo'q" ni 400 bilan qaytaradi
        log.info("iiko customer/info %s: %s", phone, r.text[:200])
        return None
    raise IikoError(f"iiko customer/info: {r.status_code} {r.text[:300]}")


def wallet_balance(info: dict) -> int:
    """Mijozning bonus hamyonidagi balans (so'm)."""
    wallet_id = None
    try:
        wallet_id = loyalty_program().get("walletId")
    except IikoError:
        pass
    total = 0.0
    for w in info.get("walletBalances") or []:
        if (wallet_id and w.get("id") == wallet_id) or (not wallet_id and w.get("type") == 1):
            total += float(w.get("balance") or 0)
    return int(round(total))


def ensure_customer(phone: str, name: str = "", surname: str = "") -> dict:
    """Mijozni iiko'da topadi yoki ochadi va bonus dasturiga qo'shadi. Qaytaradi: customer info."""
    info = customer_info(phone)
    if info is None:
        body = {"organizationId": LOYALTY_ORG, "phone": iiko_phone(phone)}
        if name:
            body["name"] = name
        if surname:
            body["surName"] = surname
        cid = _post("/api/1/loyalty/iiko/customer/create_or_update", body).get("id")
        if not cid:
            raise IikoError("iiko: mijoz yaratilmadi")
        info = {"id": cid, "walletBalances": []}
    prog = loyalty_program()
    has_wallet = any(w.get("id") == prog.get("walletId") for w in info.get("walletBalances") or [])
    if not has_wallet and prog.get("id"):
        try:
            _post("/api/1/loyalty/iiko/customer/program/add",
                  {"organizationId": LOYALTY_ORG, "customerId": info["id"], "programId": prog["id"]})
        except IikoError as e:      # allaqachon dasturda bo'lsa iiko xato qaytarishi mumkin
            log.info("program/add: %s", e)
        info = customer_info(phone) or info
    return info


def topup(customer_id: str, amount: int, comment: str) -> None:
    prog = loyalty_program()
    _post("/api/1/loyalty/iiko/customer/wallet/topup", {
        "organizationId": LOYALTY_ORG, "customerId": customer_id,
        "walletId": prog["walletId"], "sum": amount, "comment": comment,
    })
