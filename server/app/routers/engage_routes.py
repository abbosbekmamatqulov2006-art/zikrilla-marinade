"""Xabarlar va baholar: mijoz (ilova, sayt kabineti) va admin panel uchun."""
from datetime import timedelta

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from .. import engage, push
from ..auth import api_error, current_user, db_session, require_admin
from ..models import DeviceToken, FeedbackRequest, Notification, Product, Review, Store, User, now

public = APIRouter(tags=["engage"])
admin = APIRouter(prefix="/admin", tags=["admin-engage"], dependencies=[Depends(require_admin)])

BROADCAST_DAYS = 60


def _n_json(n: Notification, seen_at) -> dict:
    return {"id": n.id, "kind": n.kind, "title": n.title, "body": n.body or {}, "image": n.image or "",
            "link": n.link or "", "createdAt": n.created_at.isoformat(), "personal": n.user_id is not None,
            "unread": seen_at is None or n.created_at > seen_at}


def _user_notifs(db: Session, u: User, limit: int = 50):
    since = max(u.created_at - timedelta(days=3), now() - timedelta(days=BROADCAST_DAYS))
    return (db.query(Notification)
            .filter(or_(Notification.user_id == u.id, Notification.user_id.is_(None)),
                    Notification.created_at >= since)
            .order_by(Notification.created_at.desc()).limit(limit).all())


def _store_name(db: Session, sid: str | None) -> dict | None:
    s = db.get(Store, sid) if sid else None
    return s.name if s else None


# ============================================================ mijoz
@public.get("/me/notifications")
def my_notifications(user: User = Depends(current_user), db: Session = Depends(db_session)):
    rows = _user_notifs(db, user)
    items = [_n_json(n, user.notif_seen_at) for n in rows]
    return {"items": items, "unread": sum(1 for i in items if i["unread"])}


@public.post("/me/notifications/seen")
def notifications_seen(user: User = Depends(current_user), db: Session = Depends(db_session)):
    user.notif_seen_at = now()
    db.commit()
    return {"ok": True}


class DeviceIn(BaseModel):
    token: str
    platform: str = "android"


@public.post("/me/device")
def register_device(body: DeviceIn, user: User = Depends(current_user), db: Session = Depends(db_session)):
    tok = body.token.strip()
    if not tok or len(tok) > 500:
        raise api_error(400, "bad_token")
    d = db.get(DeviceToken, tok)
    if d is None:
        d = DeviceToken(token=tok)
        db.add(d)
    d.user_id, d.platform = user.id, body.platform[:16]
    db.commit()
    return {"ok": True}


@public.get("/me/feedback")
def my_pending_feedback(user: User = Depends(current_user), db: Session = Depends(db_session)):
    rows = (db.query(FeedbackRequest)
            .filter(FeedbackRequest.user_id == user.id, FeedbackRequest.status == "pending",
                    FeedbackRequest.due_at <= now())
            .order_by(FeedbackRequest.due_at.desc()).limit(3).all())
    return {"items": [{"id": r.id, "storeId": r.store_id, "store": _store_name(db, r.store_id),
                       "amount": r.amount, "purchasedAt": r.purchased_at.isoformat()} for r in rows]}


class FeedbackIn(BaseModel):
    requestId: int | None = None
    rating: int
    comment: str | None = None
    productId: str | None = None
    storeId: str | None = None
    source: str = "app"


@public.post("/me/feedback")
def send_feedback(body: FeedbackIn, user: User = Depends(current_user), db: Session = Depends(db_session)):
    if not 1 <= body.rating <= 5:
        raise api_error(400, "bad_rating", "Baho 1 dan 5 gacha")
    day_ago = now() - timedelta(days=1)
    if db.query(Review).filter(Review.user_id == user.id, Review.created_at >= day_ago).count() >= 10:
        raise api_error(429, "too_many", "Bugun juda ko'p baho yuborildi")
    store_id = body.storeId
    fr = None
    if body.requestId:
        fr = db.get(FeedbackRequest, body.requestId)
        if fr is None or fr.user_id != user.id:
            raise api_error(404, "not_found")
        if fr.status == "done":
            raise api_error(400, "already", "Bu xaridga baho berilgan")
        store_id = store_id or fr.store_id
    if body.productId and db.get(Product, body.productId) is None:
        raise api_error(400, "bad_product")
    if store_id and db.get(Store, store_id) is None:
        store_id = None
    r = Review(user_id=user.id, request_id=fr.id if fr else None, store_id=store_id, product_id=body.productId,
               rating=body.rating, comment=(body.comment or "").strip()[:2000] or None,
               source=body.source if body.source in ("app", "site") else "app")
    db.add(r)
    if fr:
        fr.status = "done"
    db.commit()
    return {"ok": True, "id": r.id}


@public.post("/me/feedback/{rid}/dismiss")
def dismiss_feedback(rid: int, user: User = Depends(current_user), db: Session = Depends(db_session)):
    fr = db.get(FeedbackRequest, rid)
    if fr is None or fr.user_id != user.id:
        raise api_error(404, "not_found")
    if fr.status == "pending":
        fr.status = "dismissed"
        db.commit()
    return {"ok": True}


# ============================================================ admin: xabarlar
class NotifyIn(BaseModel):
    title: dict
    body: dict | None = None
    image: str | None = None
    link: str | None = None
    push: bool = True


@admin.get("/notifications")
def admin_notifications(db: Session = Depends(db_session)):
    rows = (db.query(Notification).filter(Notification.user_id.is_(None))
            .order_by(Notification.created_at.desc()).limit(100).all())
    personal = db.query(func.count(Notification.id)).filter(Notification.user_id.isnot(None)).scalar()
    return {"items": [_n_json(n, None) | {"pushed": n.pushed} for n in rows],
            "personalCount": personal,
            "push": {"configured": push.configured(), "project": push.project_id()},
            "devices": db.query(func.count(DeviceToken.token)).scalar()}


@admin.post("/notifications")
def admin_send_notification(body: NotifyIn, db: Session = Depends(db_session)):
    t = body.title or {}
    if not (t.get("uz") or t.get("ru") or t.get("en")):
        raise api_error(400, "bad_title", "Sarlavhani kiriting")
    n = engage.notify_all(db, "promo", t, body.body, body.image, body.link, send_push=body.push)
    return {"ok": True, "id": n.id, "pushed": n.pushed}


@admin.delete("/notifications/{nid}")
def admin_delete_notification(nid: int, db: Session = Depends(db_session)):
    n = db.get(Notification, nid)
    if n is None:
        raise api_error(404, "not_found")
    db.delete(n)
    db.commit()
    return {"ok": True}


# ============================================================ admin: baholar
@admin.get("/reviews")
def admin_reviews(max_rating: int = 5, store: str | None = None, product: str | None = None,
                  limit: int = 200, db: Session = Depends(db_session)):
    q = db.query(Review).filter(Review.rating <= max_rating)
    if store:
        q = q.filter(Review.store_id == store)
    if product:
        q = q.filter(Review.product_id == product)
    rows = q.order_by(Review.created_at.desc()).limit(min(limit, 500)).all()
    users = {u.id: u for u in db.query(User).filter(User.id.in_({r.user_id for r in rows})).all()} if rows else {}
    out = []
    for r in rows:
        u = users.get(r.user_id)
        p = db.get(Product, r.product_id) if r.product_id else None
        out.append({"id": r.id, "rating": r.rating, "comment": r.comment or "", "createdAt": r.created_at.isoformat(),
                    "source": r.source, "storeId": r.store_id, "store": _store_name(db, r.store_id),
                    "productId": r.product_id, "product": p.name if p else None,
                    "customer": {"name": f"{u.first_name} {u.last_name}".strip() if u else "", "phone": u.phone if u else ""}})
    return {"items": out}


@admin.get("/reviews/summary")
def admin_reviews_summary(db: Session = Depends(db_session)):
    total, avg = db.query(func.count(Review.id), func.avg(Review.rating)).one()
    dist = {i: 0 for i in range(1, 6)}
    for rating, cnt in db.query(Review.rating, func.count(Review.id)).group_by(Review.rating).all():
        dist[int(rating)] = cnt
    by_store = [{"storeId": sid, "store": _store_name(db, sid), "count": c, "avg": round(float(a), 2)}
                for sid, c, a in db.query(Review.store_id, func.count(Review.id), func.avg(Review.rating))
                .filter(Review.store_id.isnot(None)).group_by(Review.store_id).all()]
    by_product = []
    for pid, c, a in (db.query(Review.product_id, func.count(Review.id), func.avg(Review.rating))
                      .filter(Review.product_id.isnot(None)).group_by(Review.product_id).all()):
        p = db.get(Product, pid)
        by_product.append({"productId": pid, "product": p.name if p else {"uz": pid}, "count": c, "avg": round(float(a), 2)})
    pending = db.query(func.count(FeedbackRequest.id)).filter(FeedbackRequest.status == "pending").scalar()
    answered = db.query(func.count(FeedbackRequest.id)).filter(FeedbackRequest.status == "done").scalar()
    asked = db.query(func.count(FeedbackRequest.id)).filter(FeedbackRequest.notified.is_(True)).scalar()
    return {"count": total or 0, "avg": round(float(avg), 2) if avg else None, "distribution": dist,
            "byStore": sorted(by_store, key=lambda x: x["avg"]),
            "byProduct": sorted(by_product, key=lambda x: x["avg"]),
            "requests": {"pending": pending, "answered": answered, "asked": asked}}


@admin.post("/feedback/scan")
def admin_feedback_scan(db: Session = Depends(db_session)):
    """Xaridlarni hozir tekshirish (odatda server o'zi har 15 daqiqada qiladi)."""
    return engage.scan(db)
