"""Ilova (models.dart) va sayt kutgan JSON shakllari."""
from .models import Order, Product, Store, User


def user_json(u: User) -> dict:
    address = None
    if u.address_text:
        address = {"text": u.address_text, "lat": u.address_lat, "lng": u.address_lng}
    return {
        "id": u.id,
        "phone": u.phone,
        "firstName": u.first_name,
        "lastName": u.last_name,
        "birthDate": u.birth_date,
        "gender": u.gender,
        "address": address,
        "email": u.email,
        "language": u.language,
        "registered": u.registered,
    }


def tier_of(points_lifetime: int) -> str:
    from . import config
    if points_lifetime >= config.TIER_GOLD_AT:
        return "gold"
    if points_lifetime >= config.TIER_SILVER_AT:
        return "silver"
    return "bronze"


def loyalty_json(u: User) -> dict:
    return {"balance": u.points, "tier": tier_of(u.points_lifetime), "iikoCustomerId": u.iiko_customer_id,
            "lifetime": u.points_lifetime}


def store_json(s: Store) -> dict:
    return {
        "id": s.id,
        "name": s.name,
        "address": s.address,
        "lat": s.lat,
        "lng": s.lng,
        "phone": s.phone,
        "hours": {"open": s.open, "close": s.close},
        "photo": s.photo or "",
        "sort": s.sort or 0,
        "sample": False,
    }


def product_json(p: Product) -> dict:
    media = list(p.media or [])
    # Ilova faqat `image` ni ko'radi: galereyadagi birinchi rasm muqova bo'ladi
    cover = next((m["url"] for m in media if m.get("type") == "image" and m.get("url")), None) or p.image
    return {
        "id": p.id,
        "name": p.name,
        "subtitle": p.subtitle,
        "ingredients": p.ingredients,
        "description": p.description or {"uz": "", "ru": "", "en": ""},
        "price": p.price,
        "image": cover,
        "media": media,
        "category": p.category,
        "lowStock": p.low_stock,
        "isExtra": p.is_extra,
        "rating": p.rating,
        "reviews": p.reviews,
        "grillMinutes": p.grill_minutes,
        "spicy": p.spicy,
        "weeklyDeal": p.weekly_deal,
        "unit": p.unit,
        "sort": p.sort or 0,
    }


def order_json(o: Order) -> dict:
    return {
        "id": o.id,
        "number": o.number,
        "status": o.status,
        "storeId": o.store_id,
        "items": [{"productId": i.product_id, "qty": i.qty} for i in o.items],
        "total": o.total,
        "createdAt": o.created_at.isoformat(),
    }
