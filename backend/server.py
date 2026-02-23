"""
Notebook Backend + Admin Bridge API
Supabase HTTP API üzerinden admin operasyonlarını sağlar
"""
from fastapi import FastAPI, HTTPException, Header, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import os, httpx, secrets
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="Notebook Backend + Admin Bridge", version="2.0.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SUPABASE_URL = "https://lugshtlpcgcrbelsombz.supabase.co"
SUPABASE_ANON_KEY = os.environ.get("SUPABASE_ANON_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx1Z3NodGxwY2djcmJlbHNvbWJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4MTk2MzAsImV4cCI6MjA4NzM5NTYzMH0.FeLzVIpYmbMErW3-sbIg1LgrzbaysmpwTBX0ht0YVi8")
ADMIN_API_KEY = os.environ.get("ADMIN_API_KEY", "nb-admin-7x9k2m4p8q1r5s3t6u0v")
# Admin JWT token (demo user token for SECURITY DEFINER fonksiyonları)
ADMIN_JWT = os.environ.get("ADMIN_JWT", "")


async def verify_admin_key(x_admin_key: str = Header(...)):
    """Admin API key doğrulama"""
    if x_admin_key != ADMIN_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid admin key")
    return x_admin_key


async def supabase_rpc(function_name: str, params: dict = None, jwt: str = None) -> dict:
    """Supabase RPC fonksiyonu çağır"""
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Content-Type": "application/json",
    }
    if jwt:
        headers["Authorization"] = f"Bearer {jwt}"
    else:
        headers["Authorization"] = f"Bearer {SUPABASE_ANON_KEY}"

    async with httpx.AsyncClient(timeout=15.0) as client:
        r = await client.post(
            f"{SUPABASE_URL}/rest/v1/rpc/{function_name}",
            headers=headers,
            json=params or {},
        )
        if r.status_code >= 400:
            raise HTTPException(status_code=r.status_code, detail=r.text)
        return r.json()


# ──────────────────────────────────────────────────────────────────────────────
# PUBLIC ENDPOINTS
# ──────────────────────────────────────────────────────────────────────────────

@app.get("/api/health")
async def health():
    return {"status": "ok", "service": "notebook-backend", "supabase_url": SUPABASE_URL}


@app.get("/api/config")
async def get_config():
    return {"supabase_url": SUPABASE_URL, "app_name": "Notebook", "version": "2.0.0"}


# ──────────────────────────────────────────────────────────────────────────────
# ADMIN BRIDGE ENDPOINTS
# ──────────────────────────────────────────────────────────────────────────────

@app.get("/api/admin/stats")
async def admin_stats(
    authorization: str = Header(default=""),
    _: str = Depends(verify_admin_key)
):
    """Dashboard istatistikleri"""
    jwt = authorization.replace("Bearer ", "") if authorization else None
    data = await supabase_rpc("get_admin_stats", {}, jwt=jwt or SUPABASE_ANON_KEY)
    # RPC array döndürür, ilk elemanı al
    if isinstance(data, list) and data:
        return data[0]
    return data


@app.get("/api/admin/users")
async def admin_users(
    limit: int = 50,
    offset: int = 0,
    search: str = None,
    authorization: str = Header(default=""),
    _: str = Depends(verify_admin_key)
):
    """Tüm kullanıcıları listele"""
    jwt = authorization.replace("Bearer ", "") if authorization else None
    params = {"p_limit": limit, "p_offset": offset}
    if search:
        params["p_search"] = search
    return await supabase_rpc("get_all_profiles", params, jwt=jwt or SUPABASE_ANON_KEY)


@app.get("/api/admin/notes")
async def admin_notes(
    limit: int = 50,
    offset: int = 0,
    search: str = None,
    user_id: str = None,
    authorization: str = Header(default=""),
    _: str = Depends(verify_admin_key)
):
    """Tüm notları listele"""
    jwt = authorization.replace("Bearer ", "") if authorization else None
    params = {"p_limit": limit, "p_offset": offset}
    if search:
        params["p_search"] = search
    if user_id:
        params["p_user_id"] = user_id
    return await supabase_rpc("get_all_notes", params, jwt=jwt or SUPABASE_ANON_KEY)


@app.get("/api/admin/growth")
async def admin_growth(
    days: int = 7,
    authorization: str = Header(default=""),
    _: str = Depends(verify_admin_key)
):
    """Büyüme istatistikleri"""
    jwt = authorization.replace("Bearer ", "") if authorization else None
    return await supabase_rpc("get_growth_stats", {"p_days": days}, jwt=jwt or SUPABASE_ANON_KEY)


@app.post("/api/admin/notes/{note_id}/archive")
async def admin_archive_note(
    note_id: str,
    authorization: str = Header(default=""),
    _: str = Depends(verify_admin_key)
):
    """Notu arşivle"""
    jwt = authorization.replace("Bearer ", "") if authorization else None
    result = await supabase_rpc("admin_archive_note", {"p_note_id": note_id}, jwt=jwt or SUPABASE_ANON_KEY)
    return {"success": True, "result": result}


@app.post("/api/admin/notes/{note_id}/restore")
async def admin_restore_note(
    note_id: str,
    authorization: str = Header(default=""),
    _: str = Depends(verify_admin_key)
):
    """Notu geri yükle"""
    jwt = authorization.replace("Bearer ", "") if authorization else None
    result = await supabase_rpc("admin_restore_note", {"p_note_id": note_id}, jwt=jwt or SUPABASE_ANON_KEY)
    return {"success": True, "result": result}
