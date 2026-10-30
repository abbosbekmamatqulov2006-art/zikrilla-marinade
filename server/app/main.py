import logging
import os

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles

from .models import init_db
from .routers import admin_routes, auth_routes, content_routes, core_routes, iiko_routes

logging.basicConfig(level=logging.INFO)

app = FastAPI(title="Zikrilla API", version="0.6.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(HTTPException)
async def api_exception_handler(request: Request, exc: HTTPException):
    """Ilova kutgan xato formati: {"error": code, "message": ..., "retryIn": ...}"""
    detail = exc.detail if isinstance(exc.detail, dict) else {"error": str(exc.detail)}
    return JSONResponse(status_code=exc.status_code, content=detail)


@app.on_event("startup")
def startup():
    init_db()


@app.get("/health")
def health():
    return {"ok": True, "service": "zikrilla-api", "version": app.version}


@app.get("/panel", include_in_schema=False)
def _panel_slash():
    return RedirectResponse(url="/panel/")


@app.get("/app", include_in_schema=False)
def _app_slash():
    return RedirectResponse(url="/app/")


app.include_router(auth_routes.router)
app.include_router(core_routes.router)
app.include_router(admin_routes.router)
app.include_router(iiko_routes.router)
app.include_router(content_routes.public)
app.include_router(content_routes.admin)

_base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Flutter veb ilova — /app/
_web_dir = os.path.join(_base, "web")
if os.path.isdir(_web_dir):
    app.mount("/app", StaticFiles(directory=_web_dir, html=True), name="webapp")

# Yuklangan rasm/videolar
_up_dir = os.path.join(_base, "uploads")
os.makedirs(_up_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=_up_dir), name="uploads")

# Admin panel — /panel/
_panel_dir = os.path.join(_base, "panel")
if os.path.isdir(_panel_dir):
    app.mount("/panel", StaticFiles(directory=_panel_dir, html=True), name="panel")

# Asosiy sayt — ildizda; API yo'llari yuqorida, shuning uchun ular ustun
_site_dir = os.path.join(_base, "site")
if os.path.isdir(_site_dir):
    app.mount("/", StaticFiles(directory=_site_dir, html=True), name="site")
