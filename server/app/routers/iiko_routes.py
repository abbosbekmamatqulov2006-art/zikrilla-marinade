"""iiko admin endpointlari (X-Admin-Key bilan, /docs orqali ishlatiladi)."""
import logging

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from .. import iiko, loyalty_sync
from ..auth import api_error, db_session, require_admin
from ..models import LoyaltyTx, Product, Store, User

log = logging.getLogger("iiko.routes")

router = APIRouter(prefix="/admin/iiko", tags=["iiko"], dependencies=[Depends(require_admin)])


@router.get("/status")
def iiko_status():
    """Ulanishni tekshirish: tashkilotlar + tashqi menyular ro'yxati."""
    if not iiko.enabled():
        raise api_error(400, "iiko_disabled", ".env da IIKO_API_LOGIN / IIKO_APP_ID / IIKO_CLIENT_SECRET yo'q")
    try:
        return iiko.status()
    except iiko.IikoError as e:
        raise api_error(502, "iiko_error", str(e))


@router.post("/map-stores")
def map_stores(db: Session = Depends(db_session)):
    """Filiallarga iiko organizationId larni yozib qo'yish (bir martalik)."""
    updated = []
    for store_id, org_id in iiko.ORG_MAP.items():
        s = db.get(Store, store_id)
        if s is not None:
            s.iiko_id = org_id
            updated.append(store_id)
    db.commit()
    return {"mapped": updated}


@router.post("/sync-menu")
def sync_menu(menu_id: str, db: Session = Depends(db_session)):
    """Tashqi menyudan narxlarni bizning mahsulotlarga tortish.

    Moslashtirish nom bo'yicha (kichik harfda, bo'shliqlarsiz taqqoslanadi):
    iiko'dagi mahsulot nomi bizning ru/en/uz nomlardan biriga to'g'ri kelsa,
    narx yangilanadi va iiko_id yozib qo'yiladi. Mos kelmaganlar ro'yxatda qaytadi
    — ularni admin keyin qo'lda bog'laydi (/admin/iiko/link-product).
    """
    if not iiko.enabled():
        raise api_error(400, "iiko_disabled", ".env sozlanmagan")
    try:
        data = iiko.menu_by_id(menu_id, list(iiko.ORG_MAP.values()))
    except iiko.IikoError as e:
        raise api_error(502, "iiko_error", str(e))

    def norm(s: str) -> str:
        return "".join((s or "").lower().split())

    ours: dict[str, Product] = {}
    for p in db.query(Product).all():
        for lang in ("ru", "en", "uz"):
            ours[norm((p.name or {}).get(lang, ""))] = p

    matched, unmatched = [], []
    for cat in data.get("itemCategories", []):
        for item in cat.get("items", []):
            name = item.get("name", "")
            sizes = item.get("itemSizes") or [{}]
            prices = (sizes[0].get("prices") or [{}])
            price = prices[0].get("price")
            p = ours.get(norm(name))
            if p is None:
                unmatched.append({"iikoName": name, "iikoId": item.get("itemId"), "price": price})
                continue
            p.iiko_id = item.get("itemId")
            if price:
                p.price = int(price)
            matched.append({"our": p.id, "iikoName": name, "price": p.price})
    db.commit()
    log.info("iiko sync: %d matched, %d unmatched", len(matched), len(unmatched))
    return {"matched": matched, "unmatched": unmatched}


@router.post("/link-product")
def link_product(product_id: str, iiko_item_id: str, db: Session = Depends(db_session)):
    """Mos kelmagan mahsulotni qo'lda bog'lash."""
    p = db.get(Product, product_id)
    if p is None:
        raise api_error(404, "not_found", "Mahsulot topilmadi")
    p.iiko_id = iiko_item_id
    db.commit()
    return {"ok": True, "product": p.id, "iikoId": iiko_item_id}


# ================= iikoCard (keshbek) =================
@router.get("/loyalty/status")
def loyalty_status():
    """iikoCard ulanishi: dastur, hamyon va rejim (IIKO_LOYALTY)."""
    if not iiko.enabled():
        raise api_error(400, "iiko_disabled", ".env da iiko kalitlari yo'q")
    try:
        prog = iiko.loyalty_program()
    except iiko.IikoError as e:
        raise api_error(502, "iiko_error", str(e))
    return {"program": prog, "organization": iiko.LOYALTY_ORG, "iikoMode": loyalty_sync.iiko_mode()}


@router.get("/loyalty/customer")
def loyalty_customer(phone: str):
    """Telefon bo'yicha iiko'dagi mijoz va balans."""
    digits = "".join(ch for ch in phone if ch.isdigit())
    if len(digits) == 9:
        digits = "998" + digits
    try:
        info = iiko.customer_info(digits)
    except iiko.IikoError as e:
        raise api_error(502, "iiko_error", str(e))
    if not info:
        return {"phone": digits, "found": False}
    return {"phone": digits, "found": True, "id": info.get("id"),
            "name": " ".join(x for x in (info.get("name"), info.get("surname")) if x),
            "balance": iiko.wallet_balance(info), "wallets": info.get("walletBalances")}


@router.post("/loyalty/migrate")
def loyalty_migrate(dry_run: bool = True, db: Session = Depends(db_session)):
    """Bizning bazadagi ballarni iikoCard'ga ko'chirish (bir martalik).

    dry_run=true (standart) — hech narsa o'zgarmaydi, faqat kim va qancha ko'chishi ko'rsatiladi.
    dry_run=false — har bir mijoz iiko'da ochiladi va balansi hamyoniga qo'shiladi.
    Bir mijoz ikki marta ko'chirilmaydi (loyalty_tx dagi 'iiko_migrate' yozuvi bo'yicha).
    """
    if not iiko.enabled():
        raise api_error(400, "iiko_disabled", ".env da iiko kalitlari yo'q")
    done_ids = {t.user_id for t in db.query(LoyaltyTx).filter(LoyaltyTx.reason == "iiko_migrate").all()}
    users = db.query(User).filter(User.points > 0).order_by(User.created_at).all()
    plan, moved, errors = [], [], []
    for u in users:
        if u.id in done_ids:
            continue
        plan.append({"phone": u.phone, "points": u.points})
        if dry_run:
            continue
        try:
            info = iiko.ensure_customer(u.phone, u.first_name, u.last_name)
            iiko.topup(info["id"], u.points, "Zikrilla sayt/ilova keshbekidan ko'chirildi")
            u.iiko_customer_id = info["id"]
            db.add(LoyaltyTx(user_id=u.id, delta=0, reason="iiko_migrate", amount=u.points,
                             note=f"iiko:{info['id']}"[:128]))
            db.commit()
            loyalty_sync.forget(u.phone)
            moved.append({"phone": u.phone, "points": u.points})
        except Exception as e:
            db.rollback()
            errors.append({"phone": u.phone, "error": str(e)[:200]})
    total = sum(x["points"] for x in plan)
    return {"dryRun": dry_run, "customers": len(plan), "totalPoints": total,
            "plan": plan if dry_run else None, "moved": moved, "errors": errors}
