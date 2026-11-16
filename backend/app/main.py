
from contextlib import asynccontextmanager
from typing import Literal
import secrets

import httpx
from fastapi import FastAPI, HTTPException, Query, Depends
from fastapi.responses import PlainTextResponse
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import text
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
import jwt
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.security import crear_hash, verificar_contrasena, crear_token, verificar_token


# CONEXION CON POSTGRESQL
from app.database import get_db, engine
from app.commerce import router as commerce_router
from app.notifications import router as notifications_router

# COORDINADOR DE IAS PARA DESARROLLO
from app.ai.coordinador import seleccionar_ia


# CONFIGURACION DEL SISTEMA
class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file="../.env",
        extra="ignore"
    )

    ollama_url: str = "http://127.0.0.1:11434"
    ollama_model: str = "qwen2.5-coder:7b-instruct"

    gemini_api_key: str = ""
    gemini_model: str = "gemini-2.5-flash"

    whatsapp_verify_token: str = ""

    # Alta única para una instalación cloud vacía. Estas variables se deben
    # definir solo en el proveedor seguro y eliminarse tras el primer acceso.
    bootstrap_admin_name: str = "Administrador inicial"
    bootstrap_admin_username: str = ""
    bootstrap_admin_password: str = ""


settings = Settings()


def crear_administrador_inicial_si_corresponde() -> None:
    """Crea una única cuenta inicial únicamente si usuarios está vacío.

    La contraseña llega desde una variable segura del proveedor de despliegue;
    no se registra, no se devuelve por HTTP y nunca se almacena en el proyecto.
    """
    usuario = settings.bootstrap_admin_username.strip()
    contrasena = settings.bootstrap_admin_password

    if not usuario or not contrasena:
        return
    if len(contrasena) < 12:
        raise RuntimeError("BOOTSTRAP_ADMIN_PASSWORD debe tener al menos 12 caracteres.")

    try:
        with engine.begin() as db:
            tiene_tabla = db.execute(
                text("SELECT to_regclass('public.usuarios') IS NOT NULL")
            ).scalar_one()
            if not tiene_tabla:
                return

            existe_usuario = db.execute(
                text("SELECT EXISTS (SELECT 1 FROM usuarios)")
            ).scalar_one()
            if existe_usuario:
                return

            db.execute(
                text("""
                    INSERT INTO usuarios (nombre, usuario, password_hash, rol, activo)
                    VALUES (:nombre, :usuario, :password_hash, 'administrador', true)
                """),
                {
                    "nombre": settings.bootstrap_admin_name.strip() or "Administrador inicial",
                    "usuario": usuario,
                    "password_hash": crear_hash(contrasena),
                },
            )
    except SQLAlchemyError as exc:
        raise RuntimeError("No se pudo preparar el administrador inicial.") from exc


# DATOS DE LAS PETICIONES
class AskRequest(BaseModel):
    prompt: str = Field(min_length=1, max_length=8000)
    provider: Literal["ollama", "gemini"] = "ollama"


class AskResponse(BaseModel):
    provider: str
    answer: str


class TrabajoIA(BaseModel):
    trabajo: str = Field(min_length=1, max_length=100)
    prompt: str = Field(min_length=1, max_length=8000)


# CLIENTE HTTP
@asynccontextmanager
async def lifespan(app: FastAPI):
    crear_administrador_inicial_si_corresponde()
    app.state.http = httpx.AsyncClient(timeout=120)
    try:
        yield
    finally:
        await app.state.http.aclose()


# APLICACION PRINCIPAL
app = FastAPI(
    title="ONLY EYES 360",
    version="0.4.0",
    lifespan=lifespan
)
app.include_router(commerce_router)
app.include_router(notifications_router)


# COMPROBAR SERVIDOR
@app.get("/health")
async def health():
    database_ready = True
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
    except Exception:
        database_ready = False
    return {
        "status": "ok" if database_ready else "starting",
        "service": "only-eyes-360",
        "database_ready": database_ready,
    }


# COMPROBAR POSTGRESQL
@app.get("/api/database/status")
def database_status(db: Session = Depends(get_db)):
    try:
        total = db.execute(text("""
            SELECT COUNT(*)
            FROM information_schema.tables
            WHERE table_schema = 'public'
            AND table_type = 'BASE TABLE'
        """)).scalar_one()

        return {
            "estado": "conectado",
            # Se obtiene de la conexión efectiva, nunca de un valor fijo.
            "base_datos": db.execute(text("SELECT current_database()")).scalar_one(),
            "tablas": total
        }

    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail="No se pudo consultar PostgreSQL."
        ) from exc


# CONSULTAR OLLAMA
async def consultar_ollama(prompt: str):
    try:
        response = await app.state.http.post(
            f"{settings.ollama_url.rstrip('/')}/api/generate",
            json={
                "model": settings.ollama_model,
                "prompt": prompt,
                "stream": False
            }
        )

        response.raise_for_status()
        answer = response.json()["response"]

        return AskResponse(
            provider="ollama",
            answer=answer
        )

    except (httpx.HTTPError, KeyError, ValueError) as exc:
        raise HTTPException(
            status_code=503,
            detail="No se pudo consultar Ollama. Comprueba que este iniciado."
        ) from exc


# CONSULTAR GEMINI
async def consultar_gemini(prompt: str):
    if not settings.gemini_api_key:
        raise HTTPException(
            status_code=503,
            detail="Gemini no esta configurado. Falta GEMINI_API_KEY."
        )

    url = (
        "https://generativelanguage.googleapis.com/v1beta/"
        f"models/{settings.gemini_model}:generateContent"
    )

    try:
        response = await app.state.http.post(
            url,
            headers={
                "x-goog-api-key": settings.gemini_api_key
            },
            json={
                "contents": [
                    {
                        "parts": [
                            {"text": prompt}
                        ]
                    }
                ]
            }
        )

        response.raise_for_status()
        data = response.json()

        parts = data["candidates"][0]["content"]["parts"]
        answer = "\n".join(
            part["text"]
            for part in parts
            if "text" in part
        )

        if not answer:
            raise ValueError("Gemini no devolvio texto.")

        return AskResponse(
            provider="gemini",
            answer=answer
        )

    except httpx.HTTPStatusError as exc:
        if exc.response.status_code in (401, 403):
            detail = "Gemini rechazo la clave o los permisos."
        elif exc.response.status_code == 429:
            detail = "Gemini alcanzo su limite de solicitudes."
        else:
            detail = "Gemini devolvio un error."

        raise HTTPException(
            status_code=503,
            detail=detail
        ) from exc

    except (
        httpx.RequestError,
        KeyError,
        IndexError,
        ValueError
    ) as exc:
        raise HTTPException(
            status_code=503,
            detail="No se pudo obtener una respuesta valida de Gemini."
        ) from exc


# SELECCIONAR IA SEGUN EL TRABAJO
@app.get("/api/ia/seleccionar")
async def seleccionar_inteligencia(trabajo: str):
    raise HTTPException(
        status_code=410,
        detail="Las funciones de IA están deshabilitadas en esta versión."
    )


# EJECUTAR TRABAJOS CON EL COORDINADOR
@app.post("/api/ia/ejecutar")
async def ejecutar_trabajo_ia(solicitud: TrabajoIA):
    raise HTTPException(
        status_code=410,
        detail="Las funciones de IA están deshabilitadas en esta versión."
    )


# CONSULTAS DIRECTAS A OLLAMA O GEMINI
@app.post("/api/ask", response_model=AskResponse)
async def ask(request: AskRequest):
    raise HTTPException(
        status_code=410,
        detail="Las funciones de IA están deshabilitadas en esta versión."
    )


# VERIFICACION DE WHATSAPP
@app.get(
    "/webhooks/whatsapp",
    response_class=PlainTextResponse
)
async def verify_whatsapp(
    mode: str = Query(alias="hub.mode"),
    verify_token: str = Query(alias="hub.verify_token"),
    challenge: str = Query(alias="hub.challenge")
):
    if (
        settings.whatsapp_verify_token
        and mode == "subscribe"
        and secrets.compare_digest(
            verify_token,
            settings.whatsapp_verify_token
        )
    ):
        return challenge

    raise HTTPException(
        status_code=403,
        detail="Token de verificacion invalido."
    )


# RECEPCION DE WHATSAPP
# PENDIENTE DE IMPLEMENTAR SEGURIDAD
@app.post("/webhooks/whatsapp")
async def receive_whatsapp(payload: dict):
    # Antes de usar en produccion:
    # Validar firma de Meta.
    # Verificar eventos.
    # Evitar mensajes duplicados.
    # Guardar eventos autorizados.

    return {
        "received": True
    }


# AUTENTICACION JWT PARA RUTAS PROTEGIDAS
bearer = HTTPBearer(auto_error=False)


def obtener_usuario_actual(
    credenciales: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db)
):
    error = HTTPException(
        status_code=401,
        detail="Inicia sesion con un token valido.",
        headers={"WWW-Authenticate": "Bearer"}
    )

    if credenciales is None or credenciales.scheme.lower() != "bearer":
        raise error

    try:
        usuario_id = verificar_token(credenciales.credentials)
    except (jwt.PyJWTError, ValueError, TypeError):
        raise error

    cuenta = db.execute(
        text("""
            SELECT id, nombre, usuario, rol, activo
            FROM usuarios
            WHERE id = :usuario_id
        """),
        {"usuario_id": usuario_id}
    ).mappings().first()

    if cuenta is None or not cuenta["activo"]:
        raise error

    return dict(cuenta)


# MODELO PARA REGISTRAR CLIENTES
class ClienteCrear(BaseModel):
    nombres: str = Field(min_length=1, max_length=100)
    apellidos: str | None = None
    telefono: str | None = None
    correo: str | None = None
    direccion: str | None = None


# REGISTRAR CLIENTE EN POSTGRESQL
@app.post("/api/clientes", status_code=201)
def crear_cliente(
    cliente: ClienteCrear,
    db: Session = Depends(get_db),
    usuario_actual: dict = Depends(obtener_usuario_actual)
):
    try:
        resultado = db.execute(
            text("""
                INSERT INTO clientes (
                    nombres,
                    apellidos,
                    telefono,
                    correo,
                    direccion
                )
                VALUES (
                    :nombres,
                    :apellidos,
                    :telefono,
                    :correo,
                    :direccion
                )
                RETURNING id
            """),
            cliente.model_dump()
        )

        cliente_id = resultado.scalar_one()
        db.commit()

        return {
            "mensaje": "Cliente registrado correctamente",
            "cliente_id": cliente_id
        }

    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="No se pudo registrar el cliente."
        )

# CONSULTAR CLIENTES REGISTRADOS
@app.get("/api/clientes")
def listar_clientes(
    db: Session = Depends(get_db),
    usuario_actual: dict = Depends(obtener_usuario_actual)
):
    resultado = db.execute(text("""
        SELECT
            id,
            nombres,
            apellidos,
            telefono,
            correo,
            direccion,
            fecha_registro
        FROM clientes
        ORDER BY id DESC
        LIMIT 100
    """))

    clientes = resultado.mappings().all()

    return {
        "total": len(clientes),
        "clientes": [
            dict(cliente)
            for cliente in clientes
        ]
    }

# BUSCAR CLIENTES POR NOMBRE O TELEFONO
@app.get("/api/clientes/buscar")
def buscar_clientes(
    q: str = Query(min_length=1, max_length=100),
    db: Session = Depends(get_db),
    usuario_actual: dict = Depends(obtener_usuario_actual)
):
    resultado = db.execute(
        text("""
            SELECT
                id,
                nombres,
                apellidos,
                telefono,
                correo,
                direccion
            FROM clientes
            WHERE nombres ILIKE :busqueda
               OR apellidos ILIKE :busqueda
               OR telefono ILIKE :busqueda
               OR CONCAT_WS(' ', nombres, apellidos)
                  ILIKE :busqueda
            ORDER BY nombres, apellidos
            LIMIT 50
        """),
        {"busqueda": f"%{q}%"}
    )

    clientes = [
        dict(fila)
        for fila in resultado.mappings().all()
    ]

    return {
        "total": len(clientes),
        "clientes": clientes
    }

# MODELO PARA ACTUALIZAR CLIENTES
class ClienteActualizar(BaseModel):
    nombres: str | None = Field(default=None, min_length=1, max_length=100)
    apellidos: str | None = Field(default=None, max_length=100)
    telefono: str | None = Field(default=None, max_length=30)
    correo: str | None = Field(default=None, max_length=150)
    direccion: str | None = None


# ACTUALIZAR CLIENTE
@app.patch("/api/clientes/{cliente_id}")
def actualizar_cliente(
    cliente_id: int,
    datos: ClienteActualizar,
    db: Session = Depends(get_db),
    usuario_actual: dict = Depends(obtener_usuario_actual)
):
    cambios = datos.model_dump(exclude_unset=True)

    if not cambios:
        raise HTTPException(
            status_code=400,
            detail="Debes indicar al menos un dato para actualizar."
        )

    if "nombres" in cambios and cambios["nombres"] is None:
        raise HTTPException(
            status_code=422,
            detail="El nombre no puede ser nulo."
        )

    columnas = ", ".join(
        f"{campo} = :{campo}"
        for campo in cambios
    )

    cambios["cliente_id"] = cliente_id

    resultado = db.execute(
        text(f"""
            UPDATE clientes
            SET {columnas}
            WHERE id = :cliente_id
            RETURNING id, nombres, apellidos,
                      telefono, correo, direccion
        """),
        cambios
    )

    cliente = resultado.mappings().first()

    if cliente is None:
        db.rollback()
        raise HTTPException(
            status_code=404,
            detail="Cliente no encontrado."
        )

    db.commit()

    return {
        "mensaje": "Cliente actualizado correctamente",
        "cliente": dict(cliente)
    }

# CONSULTAR LA FICHA DE UN CLIENTE
@app.get("/api/clientes/{cliente_id}")
def obtener_cliente(
    cliente_id: int,
    db: Session = Depends(get_db),
    usuario_actual: dict = Depends(obtener_usuario_actual)
):
    resultado = db.execute(
        text("""
            SELECT
                id,
                nombres,
                apellidos,
                telefono,
                correo,
                direccion,
                fecha_registro
            FROM clientes
            WHERE id = :cliente_id
        """),
        {"cliente_id": cliente_id}
    )

    cliente = resultado.mappings().first()

    if cliente is None:
        raise HTTPException(
            status_code=404,
            detail="Cliente no encontrado."
        )

    return dict(cliente)


# INICIO DE SESION DE ONLY EYES 360
class LoginRequest(BaseModel):
    usuario: str = Field(min_length=1)
    contrasena: str = Field(min_length=1)


@app.post("/api/auth/login")
def iniciar_sesion(
    datos: LoginRequest,
    db: Session = Depends(get_db)
):
    resultado = db.execute(
        text("""
            SELECT id, nombre, usuario,
                   password_hash, rol, activo
            FROM usuarios
            WHERE usuario = :usuario
        """),
        {"usuario": datos.usuario}
    )

    cuenta = resultado.mappings().first()

    if (
        cuenta is None
        or not cuenta["activo"]
        or not verificar_contrasena(
            datos.contrasena,
            cuenta["password_hash"]
        )
    ):
        raise HTTPException(
            status_code=401,
            detail="Usuario o contraseña incorrectos."
        )

    token = crear_token(cuenta["id"])

    return {
        "access_token": token,
        "token_type": "bearer",
        "usuario": {
            "id": cuenta["id"],
            "nombre": cuenta["nombre"],
            "usuario": cuenta["usuario"],
            "rol": cuenta["rol"]
        }
    }


# DATOS DEL USUARIO QUE HA INICIADO SESION
@app.get("/api/auth/yo")
def mi_cuenta(usuario_actual: dict = Depends(obtener_usuario_actual)):
    return {
        "id": usuario_actual["id"],
        "nombre": usuario_actual["nombre"],
        "usuario": usuario_actual["usuario"],
        "rol": usuario_actual["rol"]
    }
    

# REGISTRAR PACIENTES - ONLY EYES 360

from datetime import date
from pydantic import BaseModel


class PacienteCrear(BaseModel):
    cliente_id: int
    fecha_nacimiento: date | None = None
    antecedentes: str | None = None
    alergias: str | None = None
    observaciones: str | None = None


@app.post("/api/pacientes", status_code=201)
def crear_paciente(
    datos: PacienteCrear,
    db: Session = Depends(get_db),
    usuario_actual: dict = Depends(obtener_usuario_actual),
):
    try:
        resultado = db.execute(
            text("""
                INSERT INTO pacientes (
                    cliente_id,
                    fecha_nacimiento,
                    antecedentes,
                    alergias,
                    observaciones
                )
                VALUES (
                    :cliente_id,
                    :fecha_nacimiento,
                    :antecedentes,
                    :alergias,
                    :observaciones
                )
                RETURNING id
            """),
            datos.model_dump()
        )

        paciente_id = resultado.scalar_one()
        db.commit()

        return {
            "mensaje": "Paciente registrado correctamente",
            "paciente_id": paciente_id
        }

    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="El cliente no existe o ya tiene una ficha de paciente."
        ) from exc

# CONSULTAR PACIENTES REGISTRADOS

@app.get("/api/pacientes")
def listar_pacientes(
    db: Session = Depends(get_db),
    usuario_actual: dict = Depends(obtener_usuario_actual)
):
    resultado = db.execute(text("""
        SELECT
            p.id,
            p.cliente_id,
            c.nombres,
            c.apellidos,
            c.telefono,
            p.fecha_nacimiento,
            p.antecedentes,
            p.alergias,
            p.observaciones,
            p.fecha_registro
        FROM pacientes p
        INNER JOIN clientes c
            ON p.cliente_id = c.id
        ORDER BY p.id DESC
        LIMIT 100
    """))

    pacientes = resultado.mappings().all()

    return {
        "total": len(pacientes),
        "pacientes": [dict(p) for p in pacientes]
    }
