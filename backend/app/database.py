
import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Cargar las variables de entorno
# In the Windows package the executable is placed in <app>\\backend; during
# development it remains two folders above this module.  Both load the same
# external .env, which is deliberately excluded from installers and Git.
BASE_DIR = (Path(sys.executable).resolve().parent.parent
            if getattr(sys, "frozen", False)
            else Path(__file__).resolve().parents[2])
# Producción local: fuera de Program Files y del instalador. Desarrollo:
# conserva el .env del proyecto. Ninguna ruta imprime el contenido sensible.
PROGRAM_DATA = Path(os.getenv("PROGRAMDATA", r"C:\ProgramData")) / "ONLY EYES 360"
ENV_FILE = Path(os.getenv("ONLY_EYES_ENV_FILE", PROGRAM_DATA / "onlyeyes.env"))
load_dotenv(ENV_FILE if ENV_FILE.exists() else BASE_DIR / ".env")

# Conexión a PostgreSQL
DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError("Falta DATABASE_URL en .env")

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True
)

SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    autocommit=False
)

# Sesión para utilizar en FastAPI
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
