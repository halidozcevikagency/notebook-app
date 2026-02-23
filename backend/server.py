"""
Minimal FastAPI backend for Notebook App
Supabase tüm backend işlemlerini üstlendiğinden bu servis
sağlık kontrolü ve temel API proxy işlevleri sağlar
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="Notebook Backend", version="1.0.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/api/health")
async def health():
    """Sağlık kontrolü endpoint'i"""
    return {
        "status": "ok",
        "service": "notebook-backend",
        "supabase_url": "https://lugshtlpcgcrbelsombz.supabase.co"
    }


@app.get("/api/config")
async def get_config():
    """Frontend için genel konfigürasyon"""
    return {
        "supabase_url": "https://lugshtlpcgcrbelsombz.supabase.co",
        "app_name": "Notebook",
        "version": "1.0.0"
    }
