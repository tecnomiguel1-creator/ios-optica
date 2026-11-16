
from datetime import datetime, timedelta, timezone
import os
from pathlib import Path
from dotenv import load_dotenv
import jwt
from pwdlib import PasswordHash

# Cargar la configuración privada
BASE_DIR = Path(__file__).resolve().parents[2]
load_dotenv(BASE_DIR / ".env")

# PROTECCION DE CONTRASEÑAS
password_hash = PasswordHash.recommended()

def crear_hash(contrasena: str) -> str:
    return password_hash.hash(contrasena)

def verificar_contrasena(
    contrasena: str,
    hash_guardado: str
) -> bool:
    return password_hash.verify(
        contrasena,
        hash_guardado
    )

# TOKENS DE INICIO DE SESION
def crear_token(usuario_id: int) -> str:
    clave = os.getenv("JWT_SECRET_KEY")

    if not clave:
        raise RuntimeError(
            "Falta JWT_SECRET_KEY en el archivo .env"
        )

    ahora = datetime.now(timezone.utc)

    datos = {
        "sub": str(usuario_id),
        "iat": ahora,
        "exp": ahora + timedelta(hours=8)
    }

    return jwt.encode(
        datos,
        clave,
        algorithm="HS256"
    )

# VERIFICAR TOKEN DE ACCESO
def verificar_token(token: str) -> int:
    clave = os.getenv("JWT_SECRET_KEY")

    if not clave:
        raise RuntimeError("Falta JWT_SECRET_KEY")

    datos = jwt.decode(
        token,
        clave,
        algorithms=["HS256"]
    )

    usuario_id = datos.get("sub")

    if not usuario_id:
        raise jwt.InvalidTokenError(
            "Token sin identificador de usuario"
        )

    return int(usuario_id)
