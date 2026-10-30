import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+psycopg://postgres:postgres@localhost:5432/zikrilla")
JWT_SECRET = os.getenv("JWT_SECRET", "dev-secret-change-me")
DEBUG = os.getenv("DEBUG", "true").lower() == "true"
SMS_PROVIDER = os.getenv("SMS_PROVIDER", "mock")
ESKIZ_EMAIL = os.getenv("ESKIZ_EMAIL", "")
ESKIZ_PASSWORD = os.getenv("ESKIZ_PASSWORD", "")
ESKIZ_FROM = os.getenv("ESKIZ_FROM", "4546")
ADMIN_KEY = os.getenv("ADMIN_KEY", "admin")

DELIVERY_FEE = int(os.getenv("DELIVERY_FEE", "15000"))
CASHBACK_PERCENT = int(os.getenv("CASHBACK_PERCENT", "5"))       # har mahsulotdan % ball
POINTS_MAX_SHARE = float(os.getenv("POINTS_MAX_SHARE", "0.3"))   # savdoning ko'pi bilan 30% ball bilan

# OTP qoidalari
OTP_TTL_SECONDS = 180        # kod amal qilish muddati
OTP_RESEND_SECONDS = 60      # qayta yuborish oralig'i
OTP_MAX_ATTEMPTS = 5         # bitta kodga necha marta urinish
OTP_MAX_PER_DAY = 10         # bitta raqamga kunlik limit

# Daraja (tier) chegaralari — jami yig'ilgan ball bo'yicha
TIER_SILVER_AT = 100_000
TIER_GOLD_AT = 300_000

TOKEN_DAYS = 90              # JWT amal qilish muddati (kun)
