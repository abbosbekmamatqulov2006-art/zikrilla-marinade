import random
import re
from datetime import date, timedelta

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from .. import config
from ..auth import api_error, current_user, db_session, make_token
from ..models import OtpCode, User, now
from ..schemas import user_json
from .. import loyalty_sync
from ..sms import SmsError, send_sms

router = APIRouter(prefix="/auth", tags=["auth"])

PHONE_RE = re.compile(r"^998\d{9}$")


class PhoneIn(BaseModel):
    phone: str


class VerifyIn(BaseModel):
    phone: str
    code: str


class RegisterIn(BaseModel):
    firstName: str
    lastName: str
    birthDate: str
    gender: str | None = None
    address: dict
    email: str | None = None
    language: str = "uz"


@router.post("/send-code")
def send_code(body: PhoneIn, db: Session = Depends(db_session)):
    phone = body.phone.strip()
    if not PHONE_RE.match(phone):
        raise api_error(400, "invalid_phone", "Raqam 998XXXXXXXXX ko'rinishida bo'lishi kerak")

    today = date.today().isoformat()
    otp = db.get(OtpCode, phone)
    t = now()

    if otp is not None:
        since = (t - otp.last_sent_at).total_seconds()
        if since < config.OTP_RESEND_SECONDS:
            raise api_error(429, "too_many_requests", "Kod yaqinda yuborilgan",
                            retry_in=int(config.OTP_RESEND_SECONDS - since))
        if otp.day == today and otp.sent_today >= config.OTP_MAX_PER_DAY:
            raise api_error(429, "daily_limit", "Bugungi limit tugadi, ertaga urinib ko'ring")

    code = f"{random.randint(0, 9999):04d}"
    if otp is None:
        otp = OtpCode(phone=phone, day=today)
        db.add(otp)
    otp.code = code
    otp.expires_at = t + timedelta(seconds=config.OTP_TTL_SECONDS)
    otp.attempts = 0
    otp.last_sent_at = t
    otp.sent_today = (otp.sent_today or 0) + 1 if otp.day == today else 1
    otp.day = today
    db.commit()

    try:
        send_sms(phone, f"Zikrilla Marinade ilovasi va saytida ro'yxatdan o'tish uchun tasdiqlash kodi: {code}. Kodni hech kimga bermang.")
    except SmsError:
        db.rollback()
        raise api_error(502, "sms_failed", "SMS yuborib bo'lmadi, keyinroq urinib ko'ring")

    out: dict = {"resendIn": config.OTP_RESEND_SECONDS}
    if config.DEBUG:
        out["devCode"] = code  # test rejimida ilova kodni ekranda ko'rsatadi
    return out


@router.post("/verify")
def verify(body: VerifyIn, db: Session = Depends(db_session)):
    phone = body.phone.strip()
    otp = db.get(OtpCode, phone)
    if otp is None or now() > otp.expires_at:
        raise api_error(400, "code_expired", "Kod muddati tugagan, qaytadan oling")
    if otp.attempts >= config.OTP_MAX_ATTEMPTS:
        raise api_error(429, "too_many_attempts", "Urinishlar tugadi, yangi kod oling")
    if body.code.strip() != otp.code:
        otp.attempts += 1
        db.commit()
        raise api_error(400, "invalid_code", "Kod noto'g'ri")

    db.delete(otp)  # kod bir martalik
    user = db.query(User).filter(User.phone == phone).one_or_none()
    if user is None:
        user = User(phone=phone)
        db.add(user)
    db.commit()

    return {
        "token": make_token(user.id),
        "registered": user.registered,
        "user": user_json(user) if user.registered else None,
    }


def _apply_profile(user: User, d: RegisterIn) -> None:
    user.first_name = d.firstName.strip()
    user.last_name = d.lastName.strip()
    user.birth_date = d.birthDate
    user.gender = d.gender
    user.address_text = (d.address or {}).get("text")
    user.address_lat = (d.address or {}).get("lat")
    user.address_lng = (d.address or {}).get("lng")
    user.email = d.email
    user.language = d.language
    user.registered = True


@router.post("/register")
def register(body: RegisterIn, user: User = Depends(current_user), db: Session = Depends(db_session)):
    _apply_profile(user, body)
    db.add(user)
    db.commit()
    loyalty_sync.sync_customer_async(user.id)
    return {"user": user_json(user)}
