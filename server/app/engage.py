"""Xabarlar (bildirishnomalar) va xariddan keyingi baho so'rovlari.

- notify_all / notify_user — xabar yaratadi (ilova va sayt kabinetidagi qutiga) va push yuboradi (sozlangan bo'lsa).
- scan() — iikoCard tranzaksiyalaridan yangi xaridlarni topadi va N soatdan keyin baho so'raydi.
  Server ichida har 15 daqiqada fon rejimida ishlaydi (FEEDBACK_JOB=off bilan o'chiriladi).
"""
import logging
import os
import threading
import time
from datetime import datetime, timedelta, timezone

from sqlalchemy.orm import Session

from . import iiko, loyalty_sync, push
from .models import DeviceToken, FeedbackRequest, Notification, SessionLocal, Store, User, now
from .site_settings import get_site

log = logging.getLogger("engage")

PUBLIC_URL = os.getenv("PUBLIC_URL", "https://zikrilla-marinade.uz").rstrip("/")
TASHKENT = timezone(timedelta(hours=5))

FEEDBACK_TITLE = {"uz": "Xaridingiz yoqdimi?", "ru": "Как вам покупка?", "en": "How was your purchase?"}


def _abs(url: str | None) -> str | None:
    if not url:
        return None
    return url if url.startswith("http") else PUBLIC_URL + url


def _fill(d: dict | None) -> dict:
    d = d or {}
    base = d.get("uz") or d.get("ru") or d.get("en") or ""
    return {k: (d.get(k) or base) for k in ("uz", "ru", "en")}


# ===================================================== xabarlar
def notify_all(db: Session, kind: str, title: dict, body: dict | None = None, image: str | None = None,
               link: str | None = None, send_push: bool = True) -> Notification:
    n = Notification(kind=kind, title=_fill(title), body=_fill(body), image=image or None, link=link or None)
    db.add(n)
    db.commit()
    if send_push and push.configured():
        push.broadcast(n.title, n.body, _abs(n.image), n.link, n.id)
        n.pushed = True
        db.commit()
    return n


def notify_user(db: Session, user: User, kind: str, title: dict, body: dict | None = None,
                image: str | None = None, link: str | None = None) -> Notification:
    n = Notification(user_id=user.id, kind=kind, title=_fill(title), body=_fill(body), image=image or None, link=link)
    db.add(n)
    db.commit()
    tokens = [t.token for t in db.query(DeviceToken).filter(DeviceToken.user_id == user.id).all()]
    if tokens and push.configured():
        def dead(tok):
            s = SessionLocal()
            try:
                s.query(DeviceToken).filter(DeviceToken.token == tok).delete()
                s.commit()
            finally:
                s.close()
        push.to_tokens(tokens, user.language or "uz", n.title, n.body, _abs(n.image), n.link, n.id, on_dead=dead)
        n.pushed = True
        db.commit()
    return n


def auto_enabled(db: Session, what: str) -> bool:
    a = ((get_site(db).get("app") or {}).get("autoNotify") or {})
    return bool(a.get(what, True))


# ===================================================== baho so'rovlari
def _feedback_cfg(db: Session) -> dict:
    f = ((get_site(db).get("app") or {}).get("feedback") or {})
    return {"enabled": f.get("enabled", True), "delay": max(1, int(f.get("delayHours") or 24)),
            "question": _fill(f.get("question") or FEEDBACK_TITLE)}


def _parse_iiko_time(s: str | None) -> datetime | None:
    if not s:
        return None
    for fmt in ("%Y-%m-%d %H:%M:%S.%f", "%Y-%m-%d %H:%M:%S", "%Y-%m-%dT%H:%M:%S.%f", "%Y-%m-%dT%H:%M:%S"):
        try:
            return datetime.strptime(s[:26], fmt).replace(tzinfo=TASHKENT).astimezone(timezone.utc)
        except ValueError:
            continue
    return None


def _store_for(db: Session, org_id: str | None) -> str | None:
    if not org_id:
        return None
    s = db.query(Store).filter(Store.iiko_id == org_id).first()
    if s:
        return s.id
    for sid, oid in iiko.ORG_MAP.items():
        if oid == org_id and db.get(Store, sid):
            return sid
    return None


def add_request(db: Session, user_id: str, ref: str, store_id: str | None, amount: int | None,
                purchased_at: datetime, delay_hours: int) -> FeedbackRequest | None:
    """Baho so'rovini yaratadi. Bitta xarid — bitta so'rov; bir mijozga kuniga ko'pi bilan bittasi."""
    if db.query(FeedbackRequest).filter(FeedbackRequest.ref == ref).first():
        return None
    due = purchased_at + timedelta(hours=delay_hours)
    day_start = due - timedelta(hours=20)
    if db.query(FeedbackRequest).filter(FeedbackRequest.user_id == user_id,
                                        FeedbackRequest.due_at > day_start,
                                        FeedbackRequest.due_at <= due + timedelta(hours=20)).first():
        return None
    fr = FeedbackRequest(user_id=user_id, ref=ref, store_id=store_id, amount=amount,
                         purchased_at=purchased_at, due_at=due)
    db.add(fr)
    db.commit()
    return fr


def scan(db: Session) -> dict:
    """Yangi xaridlarni topish va vaqti kelgan so'rovlar bo'yicha xabar yuborish."""
    cfg = _feedback_cfg(db)
    out = {"newRequests": 0, "notified": 0, "expired": 0, "errors": 0}
    if not cfg["enabled"]:
        return out
    t = now()
    # 1) iikoCard'dagi xaridlar
    if loyalty_sync.iiko_mode():
        users = db.query(User).filter(User.registered.is_(True), User.iiko_customer_id.isnot(None)).all()
        frm, to = (t - timedelta(days=3)).astimezone(TASHKENT), t.astimezone(TASHKENT) + timedelta(hours=1)
        for u in users:
            try:
                txs = iiko.customer_transactions(u.iiko_customer_id, frm, to)
            except Exception as e:
                out["errors"] += 1
                log.warning("iiko tx %s: %s", u.phone, e)
                continue
            seen_orders = set()
            for tx in txs:
                order_sum = tx.get("orderSum") or 0
                key = tx.get("posOrderId") or (f"{tx.get('organizationId')}:{tx.get('orderNumber')}" if tx.get("orderNumber") else None)
                when = _parse_iiko_time(tx.get("whenCreatedOrder") or tx.get("whenCreated"))
                if not key or not when or float(order_sum) <= 0 or key in seen_orders:
                    continue
                seen_orders.add(key)
                if add_request(db, u.id, f"iiko:{key}"[:128], _store_for(db, tx.get("organizationId")),
                               int(float(order_sum)), when, cfg["delay"]):
                    out["newRequests"] += 1
    # 2) vaqti kelganlar — xabar
    due = (db.query(FeedbackRequest)
           .filter(FeedbackRequest.status == "pending", FeedbackRequest.notified.is_(False),
                   FeedbackRequest.due_at <= t).all())
    for fr in due:
        if fr.due_at < t - timedelta(days=3):
            fr.status = "expired"
            out["expired"] += 1
            db.commit()
            continue
        u = db.get(User, fr.user_id)
        if u is None:
            continue
        st = db.get(Store, fr.store_id) if fr.store_id else None
        body = {"uz": "Mahsulotni 5 yulduzda baholang va fikringizni yozing — bu bizga yaxshilanishga yordam beradi.",
                "ru": "Оцените покупку от 1 до 5 звёзд и оставьте отзыв — это помогает нам стать лучше.",
                "en": "Rate it from 1 to 5 stars and leave a comment — it helps us improve."}
        if st:
            for k in body:
                body[k] = f"{(st.name or {}).get(k) or ''}: {body[k]}".lstrip(": ")
        notify_user(db, u, "feedback", cfg["question"], body, None, f"feedback:{fr.id}")
        fr.notified = True
        db.commit()
        out["notified"] += 1
    # 3) eski, javobsiz so'rovlar
    old = (db.query(FeedbackRequest)
           .filter(FeedbackRequest.status == "pending", FeedbackRequest.due_at < t - timedelta(days=7)).all())
    for fr in old:
        fr.status = "expired"
        out["expired"] += 1
    db.commit()
    return out


_started = False


def start_background() -> None:
    """Har 15 daqiqada scan(). Server ishga tushganda bir marta chaqiriladi."""
    global _started
    if _started or os.getenv("FEEDBACK_JOB", "on").lower() in ("off", "false", "0"):
        return
    _started = True

    def loop():
        time.sleep(60)
        while True:
            db = SessionLocal()
            try:
                r = scan(db)
                if any(r.values()):
                    log.info("feedback scan: %s", r)
            except Exception as e:
                log.warning("feedback scan: %s", e)
            finally:
                db.close()
            time.sleep(15 * 60)

    threading.Thread(target=loop, daemon=True).start()
