"""Admin API (X-Admin-Key bilan): buyurtmalar, mahsulotlar, media, mijozlar."""
import os
import re
import uuid

from fastapi import APIRouter, Depends, File, UploadFile
from pydantic import BaseModel
from sqlalchemy.orm import Session, selectinload

from ..auth import api_error, db_session, require_admin
from ..models import LoyaltyTx, Order, OrderItem, Product, User
from ..schemas import order_json, product_json
from ..site_settings import cashback_percent

router = APIRouter(prefix="/admin", tags=["admin"], dependencies=[Depends(require_admin)])

FLOW = ["accepted", "preparing", "ready", "done", "cancelled"]


# ---------------- buyurtmalar (ilovadan keladiganlar) ----------------
@router.get("/orders")
def all_orders(status: str | None = None, db: Session = Depends(db_session)):
    q = (db.query(Order)
         .options(selectinload(Order.items), selectinload(Order.user))
         .order_by(Order.created_at.desc()))
    if status:
        q = q.filter(Order.status == status)
    out = []
    for o in q.limit(200).all():
        out.append(order_json(o) | {
            "type": o.type, "slot": o.slot, "address": o.address_text,
            "subtotal": o.subtotal, "deliveryFee": o.delivery_fee, "pointsUsed": o.points_used,
            "customer": {
                "name": f"{o.user.first_name} {o.user.last_name}".strip() if o.user else "",
                "phone": o.user.phone if o.user else "",
            },
        })
    return {"orders": out}


@router.post("/orders/{order_id}/status")
def set_status(order_id: str, status: str, db: Session = Depends(db_session)):
    if status not in FLOW:
        raise api_error(400, "bad_status", f"Holat quyidagilardan biri bo'lsin: {FLOW}")
    o = db.query(Order).options(selectinload(Order.items)).filter(Order.id == order_id).one_or_none()
    if o is None:
        raise api_error(404, "not_found", "Buyurtma topilmadi")
    prev = o.status
    o.status = status

    if status == "done" and o.points_earned == 0:
        pct = cashback_percent(db)
        earned = 0
        for it in o.items:
            earned += round(it.price_at * pct / 100) * it.qty
        user = db.get(User, o.user_id)
        user.points += earned
        user.points_lifetime += earned
        o.points_earned = earned
        db.add(LoyaltyTx(user_id=user.id, order_id=o.id, delta=earned, reason="order_earn"))

    if status == "cancelled" and prev != "cancelled" and o.points_used > 0:
        user = db.get(User, o.user_id)
        user.points += o.points_used
        db.add(LoyaltyTx(user_id=user.id, order_id=o.id, delta=o.points_used, reason="order_refund"))

    db.commit()
    return {"order": order_json(o)}


# ---------------- mahsulotlar ----------------
@router.get("/products")
def admin_products(db: Session = Depends(db_session)):
    rows = db.query(Product).order_by(Product.sort, Product.id).all()
    return {"products": [product_json(p) | {"active": p.active, "iikoId": p.iiko_id, "rawImage": p.image}
                         for p in rows]}


class Lx(BaseModel):
    ru: str = ""
    en: str = ""
    uz: str = ""


class MediaIn(BaseModel):
    type: str          # image | video
    url: str


class ProductIn(BaseModel):
    id: str | None = None
    name: Lx
    subtitle: Lx = Lx()
    ingredients: Lx = Lx()
    description: Lx = Lx()
    price: int
    image: str = ""
    media: list[MediaIn] = []
    category: str = "skewers"
    lowStock: bool = False
    isExtra: bool | None = None
    spicy: bool = False
    weeklyDeal: bool = False
    grillMinutes: int = 12
    unit: Lx | None = None
    active: bool = True
    sort: int = 0


def _fill(lx: Lx) -> dict:
    d = lx.model_dump()
    base = d["uz"] or d["ru"] or d["en"]
    return {k: (v or base) for k, v in d.items()}


@router.post("/products")
def upsert_product(body: ProductIn, db: Session = Depends(db_session)):
    if body.price < 0:
        raise api_error(400, "bad_price", "Narx manfiy bo'lmaydi")
    if not (body.name.uz or body.name.ru):
        raise api_error(400, "bad_name", "Mahsulot nomini kiriting")
    if body.id:
        p = db.get(Product, body.id)
        if p is None:
            raise api_error(404, "not_found", "Tahrirlanayotgan mahsulot topilmadi")
    else:
        pid = re.sub(r"[^a-z0-9]+", "-", (body.name.uz or body.name.ru).lower()).strip("-")[:24] or "p"
        if db.get(Product, pid) is not None:          # nomdosh mahsulot bor — ustiga yozmaymiz
            pid = f"{pid}-{uuid.uuid4().hex[:5]}"
        p = Product(id=pid, rating=4.8, reviews=0)
        db.add(p)
    media = [m.model_dump() for m in body.media if m.url and m.type in ("image", "video")]
    first_img = next((m["url"] for m in media if m["type"] == "image"), "")
    p.name = _fill(body.name)
    p.subtitle = _fill(body.subtitle)
    p.ingredients = _fill(body.ingredients)
    p.description = _fill(body.description)
    p.price = body.price
    p.media = media
    p.image = first_img or body.image or p.image or ""
    p.category = body.category
    p.low_stock = body.lowStock
    p.is_extra = body.isExtra if body.isExtra is not None else body.category == "extras"
    p.spicy = body.spicy
    p.weekly_deal = body.weeklyDeal
    p.grill_minutes = body.grillMinutes
    p.unit = _fill(body.unit) if body.unit and (body.unit.uz or body.unit.ru) else None
    p.active = body.active
    p.sort = body.sort
    db.commit()
    return {"ok": True, "product": product_json(p) | {"active": p.active}}


@router.post("/products/{product_id}/price")
def set_price(product_id: str, price: int, db: Session = Depends(db_session)):
    p = db.get(Product, product_id)
    if p is None:
        raise api_error(404, "not_found", "Mahsulot topilmadi")
    if price < 0:
        raise api_error(400, "bad_price", "Narx manfiy bo'lmaydi")
    p.price = price
    db.commit()
    return {"ok": True, "id": p.id, "price": p.price}


@router.delete("/products/{product_id}")
def delete_product(product_id: str, db: Session = Depends(db_session)):
    p = db.get(Product, product_id)
    if p is None:
        raise api_error(404, "not_found", "Mahsulot topilmadi")
    used = db.query(OrderItem).filter(OrderItem.product_id == product_id).first() is not None
    if used:
        p.active = False       # buyurtmalar tarixida bor — yashiriladi
        db.commit()
        return {"ok": True, "deleted": False, "hidden": True}
    db.delete(p)
    db.commit()
    return {"ok": True, "deleted": True}


# ---------------- media yuklash ----------------
UPLOAD_DIR = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "uploads"))
IMAGE_EXT = {".jpg", ".jpeg", ".png", ".webp"}
VIDEO_EXT = {".mp4", ".webm", ".mov"}
MAX_MB = 80


@router.post("/upload")
async def upload(file: UploadFile = File(...)):
    ext = os.path.splitext(file.filename or "")[1].lower()
    if ext not in IMAGE_EXT | VIDEO_EXT:
        raise api_error(400, "bad_type", "Faqat rasm (jpg, png, webp) yoki video (mp4, webm, mov)")
    data = await file.read()
    if len(data) > MAX_MB * 1024 * 1024:
        raise api_error(400, "too_big", f"Fayl {MAX_MB} MB dan oshmasin")
    os.makedirs(UPLOAD_DIR, exist_ok=True)
    name = uuid.uuid4().hex[:12] + ext
    with open(os.path.join(UPLOAD_DIR, name), "wb") as f:
        f.write(data)
    return {"ok": True, "url": f"/uploads/{name}", "type": "video" if ext in VIDEO_EXT else "image"}


# ---------------- mijozlar ----------------
@router.get("/users")
def users(q: str | None = None, db: Session = Depends(db_session)):
    query = db.query(User)
    if q:
        like = f"%{q.strip()}%"
        query = query.filter((User.phone.ilike(like)) | (User.first_name.ilike(like)) | (User.last_name.ilike(like)))
    rows = query.order_by(User.created_at.desc()).limit(500).all()
    return {"users": [{"id": u.id, "phone": u.phone, "name": f"{u.first_name} {u.last_name}".strip(),
                       "points": u.points, "lifetime": u.points_lifetime, "registered": u.registered,
                       "createdAt": u.created_at.isoformat()} for u in rows]}
