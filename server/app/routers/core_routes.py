from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session, selectinload

from .. import config, telegram
from .. import loyalty_sync
from ..auth import api_error, current_user, db_session
from ..models import LoyaltyTx, Order, OrderItem, Product, Store, User
from ..routers.auth_routes import RegisterIn, _apply_profile
from ..schemas import loyalty_json, order_json, product_json, store_json, user_json

router = APIRouter(tags=["core"])


# ---------------- profil ----------------
@router.get("/me")
def me(user: User = Depends(current_user)):
    return {"user": user_json(user), "loyalty": loyalty_sync.loyalty_payload(user, loyalty_json(user))}


@router.patch("/me")
def update_me(body: RegisterIn, user: User = Depends(current_user), db: Session = Depends(db_session)):
    _apply_profile(user, body)
    db.add(user)
    db.commit()
    return {"user": user_json(user)}


# ---------------- ma'lumotnomalar ----------------
@router.get("/stores")
def stores(db: Session = Depends(db_session)):
    rows = db.query(Store).filter(Store.active).order_by(Store.sort, Store.id).all()
    return {"stores": [store_json(s) for s in rows]}


@router.get("/products")
def products(db: Session = Depends(db_session)):
    rows = db.query(Product).filter(Product.active).order_by(Product.sort, Product.id).all()
    return {"products": [product_json(p) for p in rows]}


# ---------------- buyurtmalar ----------------
class ItemIn(BaseModel):
    productId: str
    qty: int


class OrderIn(BaseModel):
    storeId: str
    type: str  # delivery | pickup
    items: list[ItemIn]
    slot: str = ""
    pointsToUse: int = 0
    address: dict | None = None


def _fmt(n: int) -> str:
    return f"{n:,}".replace(",", " ")


def _notify_new_order(o: Order, user: User, store: Store, prods: dict[str, Product]) -> None:
    where = (f"🚚 Yetkazish: {o.address_text or '—'}" if o.type == "delivery"
             else f"🏪 Olib ketish: {(store.name or {}).get('uz', store.id)}")
    lines = [f"🆕 Yangi buyurtma №{o.number}",
             f"👤 {(user.first_name + ' ' + user.last_name).strip() or '—'}  +{user.phone}",
             where, ""]
    for it in o.items:
        p = prods.get(it.product_id)
        nm = (p.name or {}).get("uz", it.product_id) if p else it.product_id
        lines.append(f"• {nm} × {it.qty} = {_fmt(it.price_at * it.qty)}")
    lines.append("")
    if o.delivery_fee:
        lines.append(f"Yetkazish: {_fmt(o.delivery_fee)}")
    if o.points_used:
        lines.append(f"Ball: −{_fmt(o.points_used)}")
    lines.append(f"💰 Jami: {_fmt(o.total)} so'm")
    telegram.send("\n".join(lines))


@router.post("/orders")
def create_order(body: OrderIn, user: User = Depends(current_user), db: Session = Depends(db_session)):
    if not body.items:
        raise api_error(400, "empty_cart", "Savat bo'sh")
    store = db.get(Store, body.storeId)
    if store is None or not store.active:
        raise api_error(400, "bad_store", "Filial topilmadi")

    prods: dict[str, Product] = {}
    subtotal = 0
    for it in body.items:
        if it.qty <= 0:
            raise api_error(400, "bad_qty", "Miqdor noto'g'ri")
        p = db.get(Product, it.productId)
        if p is None or not p.active:
            raise api_error(400, "bad_product", f"Mahsulot topilmadi: {it.productId}")
        prods[it.productId] = p
        subtotal += p.price * it.qty

    delivery = body.type == "delivery"
    fee = config.DELIVERY_FEE if delivery else 0

    cap = int(subtotal * config.POINTS_MAX_SHARE)
    max_points = (min(cap, user.points) // 1000) * 1000
    use = (min(max(body.pointsToUse, 0), max_points) // 1000) * 1000
    if loyalty_sync.iiko_mode():
        use = 0   # iiko rejimida ball faqat kassada ishlatiladi

    order = Order(
        user_id=user.id,
        store_id=store.id,
        type="delivery" if delivery else "pickup",
        slot=body.slot,
        subtotal=subtotal,
        delivery_fee=fee,
        points_used=use,
        total=subtotal + fee - use,
        address_text=(body.address or {}).get("text") if delivery else None,
        address_lat=(body.address or {}).get("lat") if delivery else None,
        address_lng=(body.address or {}).get("lng") if delivery else None,
    )
    db.add(order)
    db.flush()
    for it in body.items:
        db.add(OrderItem(order_id=order.id, product_id=it.productId, qty=it.qty,
                         price_at=prods[it.productId].price))
    if use > 0:
        user.points -= use
        db.add(LoyaltyTx(user_id=user.id, order_id=order.id, delta=-use, reason="order_spend"))
    db.commit()
    db.refresh(order)

    _notify_new_order(order, user, store, prods)   # Telegram — xato bo'lsa ham buyurtmaga ta'sir qilmaydi
    return {"order": order_json(order)}


@router.get("/orders")
def list_orders(user: User = Depends(current_user), db: Session = Depends(db_session)):
    rows = (db.query(Order).options(selectinload(Order.items))
            .filter(Order.user_id == user.id)
            .order_by(Order.created_at.desc()).limit(50).all())
    return {"orders": [order_json(o) for o in rows]}


@router.get("/orders/{order_id}")
def get_order(order_id: str, user: User = Depends(current_user), db: Session = Depends(db_session)):
    o = (db.query(Order).options(selectinload(Order.items))
         .filter(Order.id == order_id, Order.user_id == user.id).one_or_none())
    if o is None:
        raise api_error(404, "not_found", "Buyurtma topilmadi")
    return {"order": order_json(o)}
