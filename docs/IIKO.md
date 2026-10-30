
## iiko integratsiyasi (yangilash)
.env ga uch qator qo'shiladi:
    IIKO_API_LOGIN=...
    IIKO_APP_ID=...
    IIKO_CLIENT_SECRET=...
Keyin: docker compose up -d --build
Tekshiruv: /docs -> GET /admin/iiko/status
Filiallarni bog'lash (bir marta): POST /admin/iiko/map-stores
Menyu sinxroni (tashqi menyu yaratilgach): POST /admin/iiko/sync-menu?menu_id=<id>
