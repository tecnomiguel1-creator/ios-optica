from contextlib import asynccontextmanager
from typing import Literal

import httpx
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file="../.env", extra="ignore")
    ollama_url: str = "http://127.0.0.1:11434"
    ollama_model: str = "llama3.2:3b"
    gemini_api_key: str = ""
    whatsapp_verify_token: str = ""


settings = Settings()


class AskRequest(BaseModel):
    prompt: str = Field(min_length=1, max_length=8000)
    provider: Literal["ollama"] = "ollama"


class AskResponse(BaseModel):
    provider: str
    answer: str


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.http = httpx.AsyncClient(timeout=90)
    yield
    await app.state.http.aclose()


app = FastAPI(title="ONLY EYES 360", version="0.1.0", lifespan=lifespan)


@app.get("/health")
async def health():
    return {"status": "ok", "service": "only-eyes-360"}


@app.post("/api/ask", response_model=AskResponse)
async def ask(request: AskRequest):
    try:
        response = await app.state.http.post(
            f"{settings.ollama_url}/api/generate",
            json={"model": settings.ollama_model, "prompt": request.prompt, "stream": False},
        )
        response.raise_for_status()
        return AskResponse(provider="ollama", answer=response.json()["response"])
    except (httpx.HTTPError, KeyError) as exc:
        raise HTTPException(503, "No se pudo conectar con Ollama. Instálalo, ejecútalo y descarga el modelo configurado.") from exc


@app.get("/webhooks/whatsapp")
async def verify_whatsapp(
    mode: str = Query(alias="hub.mode"),
    verify_token: str = Query(alias="hub.verify_token"),
    challenge: str = Query(alias="hub.challenge"),
):
    if mode == "subscribe" and verify_token == settings.whatsapp_verify_token:
        return int(challenge) if challenge.isdigit() else challenge
    raise HTTPException(403, "Token de verificación inválido")


@app.post("/webhooks/whatsapp", status_code=200)
async def receive_whatsapp(payload: dict):
    # Meta debe verificar la firma X-Hub-Signature-256 antes de procesar eventos reales.
    return {"received": True}
