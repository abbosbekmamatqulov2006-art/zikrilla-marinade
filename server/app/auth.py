from datetime import datetime, timedelta, timezone

import jwt
from fastapi import Depends, Header, HTTPException
from sqlalchemy.orm import Session

from . import config
from .models import SessionLocal, User


def db_session():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def make_token(user_id: str) -> str:
    payload = {
        "sub": user_id,
        "exp": datetime.now(timezone.utc) + timedelta(days=config.TOKEN_DAYS),
    }
    return jwt.encode(payload, config.JWT_SECRET, algorithm="HS256")


def api_error(status: int, code: str, message: str | None = None, retry_in: int | None = None):
    """Ilovadagi ApiException kutgan formatda xato: {"error": code, "message": ..., "retryIn": ...}"""
    detail: dict = {"error": code}
    if message:
        detail["message"] = message
    if retry_in is not None:
        detail["retryIn"] = retry_in
    return HTTPException(status_code=status, detail=detail)


def current_user(
    authorization: str = Header(default=""),
    db: Session = Depends(db_session),
) -> User:
    if not authorization.startswith("Bearer "):
        raise api_error(401, "unauthorized")
    token = authorization.removeprefix("Bearer ").strip()
    try:
        payload = jwt.decode(token, config.JWT_SECRET, algorithms=["HS256"])
    except jwt.PyJWTError:
        raise api_error(401, "unauthorized")
    user = db.get(User, payload.get("sub", ""))
    if user is None:
        raise api_error(401, "unauthorized")
    return user


def require_admin(x_admin_key: str = Header(default="")):
    if x_admin_key != config.ADMIN_KEY:
        raise api_error(403, "forbidden", "Admin kalit noto'g'ri")
