import uuid
from datetime import datetime, timezone

from sqlalchemy import (JSON, Boolean, DateTime, Float, ForeignKey, Integer,
                        Sequence, String, Text, create_engine, text)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship, sessionmaker

from .config import DATABASE_URL

engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, expire_on_commit=False)


def now() -> datetime:
    return datetime.now(timezone.utc)


def new_id() -> str:
    return uuid.uuid4().hex


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"
    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    phone: Mapped[str] = mapped_column(String(12), unique=True, index=True)  # 998XXXXXXXXX
    first_name: Mapped[str] = mapped_column(String(64), default="")
    last_name: Mapped[str] = mapped_column(String(64), default="")
    birth_date: Mapped[str | None] = mapped_column(String(10))
    gender: Mapped[str | None] = mapped_column(String(8))
    address_text: Mapped[str | None] = mapped_column(Text)
    address_lat: Mapped[float | None] = mapped_column(Float)
    address_lng: Mapped[float | None] = mapped_column(Float)
    email: Mapped[str | None] = mapped_column(String(128))
    language: Mapped[str] = mapped_column(String(2), default="uz")
    registered: Mapped[bool] = mapped_column(Boolean, default=False)
    points: Mapped[int] = mapped_column(Integer, default=0)
    points_lifetime: Mapped[int] = mapped_column(Integer, default=0)
    iiko_customer_id: Mapped[str | None] = mapped_column(String(64))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now)

    orders: Mapped[list["Order"]] = relationship(back_populates="user")


class OtpCode(Base):
    __tablename__ = "otp_codes"
    phone: Mapped[str] = mapped_column(String(12), primary_key=True)
    code: Mapped[str] = mapped_column(String(6))
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    attempts: Mapped[int] = mapped_column(Integer, default=0)
    last_sent_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now)
    sent_today: Mapped[int] = mapped_column(Integer, default=1)
    day: Mapped[str] = mapped_column(String(10), default="")


class Store(Base):
    __tablename__ = "stores"
    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    name: Mapped[dict] = mapped_column(JSON)
    address: Mapped[dict] = mapped_column(JSON)
    lat: Mapped[float] = mapped_column(Float)
    lng: Mapped[float] = mapped_column(Float)
    phone: Mapped[str] = mapped_column(String(16), default="")
    open: Mapped[str] = mapped_column(String(5), default="09:00")
    close: Mapped[str] = mapped_column(String(5), default="22:00")
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    iiko_id: Mapped[str | None] = mapped_column(String(64))
    sort: Mapped[int] = mapped_column(Integer, default=0)
    photo: Mapped[str | None] = mapped_column(String(256))


class Product(Base):
    __tablename__ = "products"
    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    name: Mapped[dict] = mapped_column(JSON)
    subtitle: Mapped[dict] = mapped_column(JSON)
    ingredients: Mapped[dict] = mapped_column(JSON)
    price: Mapped[int] = mapped_column(Integer)
    image: Mapped[str] = mapped_column(String(256), default="")
    category: Mapped[str] = mapped_column(String(32))
    low_stock: Mapped[bool] = mapped_column(Boolean, default=False)
    is_extra: Mapped[bool] = mapped_column(Boolean, default=False)
    rating: Mapped[float] = mapped_column(Float, default=4.8)
    reviews: Mapped[int] = mapped_column(Integer, default=0)
    grill_minutes: Mapped[int] = mapped_column(Integer, default=12)
    spicy: Mapped[bool] = mapped_column(Boolean, default=False)
    weekly_deal: Mapped[bool] = mapped_column(Boolean, default=False)
    unit: Mapped[dict | None] = mapped_column(JSON)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    iiko_id: Mapped[str | None] = mapped_column(String(64))
    # v6: galereya va to'liq tavsif
    description: Mapped[dict | None] = mapped_column(JSON)       # {uz, ru, en}
    media: Mapped[list | None] = mapped_column(JSON)              # [{"type":"image"|"video","url":...}]
    sort: Mapped[int] = mapped_column(Integer, default=0)


class Order(Base):
    __tablename__ = "orders"
    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    number: Mapped[int] = mapped_column(Integer, Sequence("order_number_seq", start=1001), unique=True, index=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    store_id: Mapped[str] = mapped_column(ForeignKey("stores.id"))
    type: Mapped[str] = mapped_column(String(8))
    slot: Mapped[str] = mapped_column(String(16), default="")
    status: Mapped[str] = mapped_column(String(12), default="accepted")
    subtotal: Mapped[int] = mapped_column(Integer)
    delivery_fee: Mapped[int] = mapped_column(Integer, default=0)
    points_used: Mapped[int] = mapped_column(Integer, default=0)
    points_earned: Mapped[int] = mapped_column(Integer, default=0)
    total: Mapped[int] = mapped_column(Integer)
    address_text: Mapped[str | None] = mapped_column(Text)
    address_lat: Mapped[float | None] = mapped_column(Float)
    address_lng: Mapped[float | None] = mapped_column(Float)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now)

    user: Mapped[User] = relationship(back_populates="orders")
    items: Mapped[list["OrderItem"]] = relationship(back_populates="order", cascade="all, delete-orphan")


class OrderItem(Base):
    __tablename__ = "order_items"
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    order_id: Mapped[str] = mapped_column(ForeignKey("orders.id"), index=True)
    product_id: Mapped[str] = mapped_column(ForeignKey("products.id"))
    qty: Mapped[int] = mapped_column(Integer)
    price_at: Mapped[int] = mapped_column(Integer)

    order: Mapped[Order] = relationship(back_populates="items")


class LoyaltyTx(Base):
    """Ball harakatlari jurnali."""
    __tablename__ = "loyalty_tx"
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    order_id: Mapped[str | None] = mapped_column(String(32))
    delta: Mapped[int] = mapped_column(Integer)
    reason: Mapped[str] = mapped_column(String(32))   # order_earn | order_spend | kassa_earn | kassa_spend | ...
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now)
    # v6: kassa tafsilotlari
    amount: Mapped[int | None] = mapped_column(Integer)           # xarid summasi (kassa)
    store_id: Mapped[str | None] = mapped_column(String(32))
    note: Mapped[str | None] = mapped_column(String(128))


class Setting(Base):
    """Sayt va ilova sozlamalari (kalit -> JSON). Paneldan tahrirlanadi."""
    __tablename__ = "settings"
    key: Mapped[str] = mapped_column(String(64), primary_key=True)
    value: Mapped[dict | list | None] = mapped_column(JSON)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now, onupdate=now)


class Event(Base):
    __tablename__ = "events"
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[str | None] = mapped_column(String(32), index=True)
    name: Mapped[str] = mapped_column(String(64), index=True)
    props: Mapped[dict | None] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now, index=True)


# Mavjud bazaga yangi ustunlarni xavfsiz qo'shish (bir necha marta ishlasa ham zarari yo'q)
_MIGRATIONS = [
    "ALTER TABLE products ADD COLUMN IF NOT EXISTS description JSON",
    "ALTER TABLE products ADD COLUMN IF NOT EXISTS media JSON",
    "ALTER TABLE products ADD COLUMN IF NOT EXISTS sort INTEGER DEFAULT 0",
    "ALTER TABLE products ALTER COLUMN image TYPE VARCHAR(256)",
    "ALTER TABLE products ALTER COLUMN category TYPE VARCHAR(32)",
    "ALTER TABLE stores ADD COLUMN IF NOT EXISTS sort INTEGER DEFAULT 0",
    "ALTER TABLE stores ADD COLUMN IF NOT EXISTS photo VARCHAR(256)",
    "ALTER TABLE loyalty_tx ADD COLUMN IF NOT EXISTS amount INTEGER",
    "ALTER TABLE loyalty_tx ADD COLUMN IF NOT EXISTS store_id VARCHAR(32)",
    "ALTER TABLE loyalty_tx ADD COLUMN IF NOT EXISTS note VARCHAR(128)",
]


def init_db() -> None:
    Base.metadata.create_all(engine)
    with engine.begin() as conn:
        for sql in _MIGRATIONS:
            conn.execute(text(sql))
