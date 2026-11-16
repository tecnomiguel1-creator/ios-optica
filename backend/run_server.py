"""Punto de entrada empaquetable del backend local ONLY EYES 360."""
import os

import uvicorn


if __name__ == "__main__":
    # Solo loopback: nunca expone PostgreSQL ni FastAPI a Internet directamente.
    uvicorn.run("app.main:app", host="127.0.0.1", port=int(os.getenv("ONLY_EYES_PORT", "8000")), log_level="info")
