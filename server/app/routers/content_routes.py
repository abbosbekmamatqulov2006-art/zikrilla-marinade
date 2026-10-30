"""v6: sozlamalar, filiallar boshqaruvi, kassa-keshbek, mijoz kabineti."""
import re
import uuid

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from .. import iiko, loyalty_sync
from ..auth import api_error, current_user, db_session, require_admin
from ..models import LoyaltyTx, Order, Store, User
from ..schemas import loyalty_json, store_json, tier_of
from ..site_settings import cashback_max_share, cashback_percent, get_site, save_site

public = APIRouter(tags=["content"])
admin = APIRouter(prefix="/admin", tags=["admin-content"], dependencies=[Depends(require_admin)])

PHONE_RE = re.compile(r"^998\d{9}$")


def _phone(raw: str) -> str:
    d = re.sub(r"\D", "", raw or "")
    if len(d) == 9:
        d = "998" + d
    if not PHONE_RE.match(d):
        raise api_error(400, "invalid_phone", "Telefon 998XXXXXXXXX ko'rinishida bo'lsin")
    return d


def _tx_json(t: LoyaltyTx) -> dict:
    return {"id": t.id, "delta": t.delta, "reason": t.reason, "amount": t.amount,
            "storeId": t.store_id, "note": t.note, "createdAt": t.created_at.isoformat()}


# =================== ochiq (sayt va ilova) ===================
@public.get("/settings")
def public_settings(db: Session = Depends(db_session)):
    return {"settings": get_site(db)}


@public.get("/me/loyalty")
def my_loyalty(user: User = Depends(current_user), db: Session = Depends(db_session)):
    rows = (db.query(LoyaltyTx).filter(LoyaltyTx.user_id == user.id)
            .order_by(LoyaltyTx.created_at.desc()).limit(50).all())
    return {"loyalty": loyalty_sync.loyalty_payload(user, loyalty_json(user)),
            "history": [_tx_json(t) for t in rows]}


# =================== sozlamalar ===================
@admin.get("/settings")
def admin_get_settings(db: Session = Depends(db_session)):
    return {"settings": get_site(db)}


@admin.put("/settings")
def admin_put_settings(body: dict, db: Session = Depends(db_session)):
    value = body.get("settings", body)
    if not isinstance(value, dict):
        raise api_error(400, "bad_settings", "Noto'g'ri format")
    return {"settings": save_site(db, value)}


# =================== filiallar ===================
class Lx(BaseModel):
    uz: str = ""
    ru: str = ""
    en: str = ""


class StoreIn(BaseModel):
    id: str | None = None
    name: Lx
    address: Lx = Lx()
    lat: float
    lng: float
    phone: str = ""
    open: str = "09:00"
    close: str = "22:00"
    active: bool = True
    sort: int = 0
    photo: str = ""


def _fill(lx: Lx) -> dict:
    d = lx.model_dump()
    base = d["uz"] or d["ru"] or d["en"]
    return {k: (v or base) for k, v in d.items()}


@admin.get("/stores")
def admin_stores(db: Session = Depends(db_session)):
    rows = db.query(Store).order_by(Store.sort, Store.id).all()
    return {"stores": [store_json(s) | {"active": s.active, "iikoId": s.iiko_id} for s in rows]}


@admin.post("/stores")
def admin_upsert_store(body: StoreIn, db: Session = Depends(db_session)):
    if not re.match(r"^\d{2}:\d{2}$", body.open) or not re.match(r"^\d{2}:\d{2}$", body.close):
        raise api_error(400, "bad_hours", "Ish vaqti 09:00 ko'rinishida bo'lsin")
    if not (-90 <= body.lat <= 90 and -180 <= body.lng <= 180):
        raise api_error(400, "bad_coords", "Koordinatalar noto'g'ri")
    if not (body.name.uz or body.name.ru):
        raise api_error(400, "bad_name", "Filial nomini kiriting")
    if body.id:
        s = db.get(Store, body.id)
        if s is None:
            raise api_error(404, "not_found", "Tahrirlanayotgan filial topilmadi")
    else:
        sid = re.sub(r"[^a-z0-9]+", "", (body.name.uz or body.name.ru).lower())[:20] or "filial"
        if db.get(Store, sid) is not None:            # nomdosh filial bor — ustiga yozmaymiz
            sid = f"{sid}{uuid.uuid4().hex[:4]}"
        s = Store(id=sid)
        db.add(s)
    s.name = _fill(body.name)
    s.address = _fill(body.address)
    s.lat, s.lng = body.lat, body.lng
    s.phone = body.phone.strip()
    s.open, s.close = body.open, body.close
    s.active = body.active
    s.sort = body.sort
    s.photo = body.photo or None
    db.commit()
    return {"store": store_json(s) | {"active": s.active}}


@admin.delete("/stores/{store_id}")
def admin_delete_store(store_id: str, db: Session = Depends(db_session)):
    s = db.get(Store, store_id)
    if s is None:
        raise api_error(404, "not_found", "Filial topilmadi")
    used = db.query(Order).filter(Order.store_id == store_id).first() is not None
    if used:
        s.active = False          # tarixdagi buyurtmalar buzilmasin
        db.commit()
        return {"ok": True, "deleted": False, "hidden": True}
    db.delete(s)
    db.commit()
    return {"ok": True, "deleted": True}


# =================== kassa: keshbek ===================
class EarnIn(BaseModel):
    phone: str
    amount: int                  # xarid summasi, so'm
    storeId: str | None = None
    name: str | None = None      # yangi mijoz bo'lsa ismi


class SpendIn(BaseModel):
    phone: str
    points: int
    amount: int | None = None    # xarid summasi (chegarani tekshirish uchun)
    storeId: str | None = None


def _customer(db: Session, phone: str) -> User | None:
    return db.query(User).filter(User.phone == phone).one_or_none()


def _customer_json(u: User, db: Session) -> dict:
    rows = (db.query(LoyaltyTx).filter(LoyaltyTx.user_id == u.id)
            .order_by(LoyaltyTx.created_at.desc()).limit(15).all())
    return {"id": u.id, "phone": u.phone, "name": f"{u.first_name} {u.last_name}".strip(),
            "registered": u.registered, "balance": loyalty_sync.balance(u), "lifetime": u.points_lifetime,
            "source": "iiko" if loyalty_sync.iiko_mode() else "local",
            "tier": tier_of(u.points_lifetime), "history": [_tx_json(t) for t in rows]}


@admin.get("/kassa/lookup")
def kassa_lookup(phone: str, db: Session = Depends(db_session)):
    p = _phone(phone)
    u = _customer(db, p)
    if u is None and loyalty_sync.iiko_mode():
        # bizning bazada yo'q, lekin iiko kassasida ochilgan mijoz
        try:
            info = iiko.customer_info(p)
        except iiko.IikoError:
            info = None
        if info:
            return {"phone": p, "percent": cashback_percent(db), "maxShare": cashback_max_share(db),
                    "iikoMode": True,
                    "customer": {"id": None, "phone": p, "registered": False, "source": "iiko",
                                 "name": " ".join(x for x in (info.get("name"), info.get("surname")) if x),
                                 "balance": iiko.wallet_balance(info), "lifetime": 0, "tier": "bronze",
                                 "history": []}}
    return {"phone": p, "customer": _customer_json(u, db) if u else None,
            "percent": cashback_percent(db), "maxShare": cashback_max_share(db),
            "iikoMode": loyalty_sync.iiko_mode()}


def _block_in_iiko_mode():
    if loyalty_sync.iiko_mode():
        raise api_error(409, "iiko_mode", "Keshbek endi iiko kassasida beriladi va yechiladi. "
                                           "Mijozni iiko kassasida telefon raqami bilan chekka biriktiring.")


@admin.post("/kassa/earn")
def kassa_earn(body: EarnIn, db: Session = Depends(db_session)):
    _block_in_iiko_mode()
    p = _phone(body.phone)
    if body.amount <= 0 or body.amount > 100_000_000:
        raise api_error(400, "bad_amount", "Xarid summasi noto'g'ri")
    u = _customer(db, p)
    if u is None:                              # kassada yangi mijoz — shu yerning o'zida ochiladi
        u = User(phone=p, first_name=(body.name or "").strip()[:64], registered=False)
        db.add(u)
        db.flush()
    pts = int(round(body.amount * cashback_percent(db) / 100))
    u.points += pts
    u.points_lifetime += pts
    db.add(LoyaltyTx(user_id=u.id, delta=pts, reason="kassa_earn", amount=body.amount, store_id=body.storeId))
    db.commit()
    return {"ok": True, "added": pts, "customer": _customer_json(u, db)}


@admin.post("/kassa/spend")
def kassa_spend(body: SpendIn, db: Session = Depends(db_session)):
    _block_in_iiko_mode()
    p = _phone(body.phone)
    u = _customer(db, p)
    if u is None:
        raise api_error(404, "no_customer", "Bu raqamda mijoz yo'q")
    if body.points <= 0:
        raise api_error(400, "bad_points", "Ball miqdori noto'g'ri")
    if body.points > u.points:
        raise api_error(400, "not_enough", f"Balansda {u.points} ball bor")
    if body.amount:
        cap = int(body.amount * cashback_max_share(db))
        if body.points > cap:
            raise api_error(400, "over_cap", f"Bu xaridda ko'pi bilan {cap} ball ishlatiladi")
    u.points -= body.points
    db.add(LoyaltyTx(user_id=u.id, delta=-body.points, reason="kassa_spend", amount=body.amount, store_id=body.storeId))
    db.commit()
    return {"ok": True, "spent": body.points, "customer": _customer_json(u, db)}


@admin.post("/kassa/undo/{tx_id}")
def kassa_undo(tx_id: int, db: Session = Depends(db_session)):
    _block_in_iiko_mode()
    t = db.get(LoyaltyTx, tx_id)
    if t is None or t.reason not in ("kassa_earn", "kassa_spend"):
        raise api_error(404, "not_found", "Bekor qilinadigan kassa amali topilmadi")
    if db.query(LoyaltyTx).filter(LoyaltyTx.note == f"undo:{t.id}").first():
        raise api_error(400, "already", "Bu amal allaqachon bekor qilingan")
    u = db.get(User, t.user_id)
    if t.delta > 0 and u.points < t.delta:
        raise api_error(400, "not_enough", "Ballar allaqachon ishlatilgan — bekor qilib bo'lmaydi")
    u.points -= t.delta
    if t.reason == "kassa_earn":
        u.points_lifetime = max(0, u.points_lifetime - t.delta)
    db.add(LoyaltyTx(user_id=u.id, delta=-t.delta, reason="kassa_undo", amount=t.amount,
                     store_id=t.store_id, note=f"undo:{t.id}"))
    db.commit()
    return {"ok": True, "customer": _customer_json(u, db)}
