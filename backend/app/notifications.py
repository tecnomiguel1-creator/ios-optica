"""Notificaciones transaccionales; por defecto solo proveedor simulado.

Nunca usa credenciales ni transmite mensajes reales si NOTIFICATION_PROVIDER no
se configura explícitamente fuera de desarrollo.
"""
from __future__ import annotations

from datetime import datetime, timedelta
from uuid import uuid4
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.database import get_db
from app.commerce import current_user

router = APIRouter(prefix="/api/notificaciones", tags=["notificaciones"])
SANTO_DOMINGO = ZoneInfo("America/Santo_Domingo")


class ConsentIn(BaseModel):
    whatsapp_habilitado: bool


class SimulateMessageIn(BaseModel):
    texto: str


def enqueue_ready_work(db: Session, work_type: str, work_id: int) -> bool:
    """Encola aviso si el cliente consintió. No realiza ningún envío."""
    table = "pedidos_lentes" if work_type == "pedido" else "reparaciones"
    row = db.execute(text(f"""SELECT t.cliente_id,t.codigo,c.telefono,
        COALESCE(co.whatsapp_habilitado,false) consentido
        FROM {table} t JOIN clientes c ON c.id=t.cliente_id
        LEFT JOIN consentimientos_notificacion co ON co.cliente_id=t.cliente_id
        WHERE t.id=:id"""), {"id": work_id}).mappings().first()
    if not row or not row["consentido"] or not row["telefono"]:
        return False
    key = f"listo:{work_type}:{work_id}"
    db.execute(text("""INSERT INTO notificaciones_cliente
        (cliente_id,tipo,trabajo_tipo,trabajo_id,plantilla,deduplicacion_clave)
        VALUES (:client,'trabajo_listo',:type,:id,'trabajo_listo',:key)
        ON CONFLICT (deduplicacion_clave) DO NOTHING"""),
        {"client": row["cliente_id"], "type": work_type, "id": work_id, "key": key})
    return True


def simulate_delivery(db: Session, notification_id: int) -> dict:
    row = db.execute(text("SELECT * FROM notificaciones_cliente WHERE id=:id FOR UPDATE"), {"id": notification_id}).mappings().first()
    if not row:
        raise HTTPException(404, "Notificación no encontrada.")
    if row["estado"] in {"enviado", "entregado"}:
        return {"id": notification_id, "estado": row["estado"], "duplicado_evitado": True}
    provider_id = f"SIM-{uuid4().hex[:12].upper()}"
    db.execute(text("""UPDATE notificaciones_cliente SET estado='enviado', proveedor='simulado',
        proveedor_id=:provider, intentos=intentos+1, enviado_en=now(), error=NULL WHERE id=:id"""),
        {"provider": provider_id, "id": notification_id})
    return {"id": notification_id, "estado": "enviado", "proveedor_id": provider_id, "simulado": True}


@router.put("/consentimientos/{cliente_id}")
def update_consent(cliente_id: int, data: ConsentIn, db: Session = Depends(get_db), user: dict = Depends(current_user)):
    if not db.execute(text("SELECT id FROM clientes WHERE id=:id"), {"id": cliente_id}).first():
        raise HTTPException(404, "Cliente no encontrado.")
    db.execute(text("""INSERT INTO consentimientos_notificacion(cliente_id,whatsapp_habilitado,otorgado_en,revocado_en)
        VALUES (:id,:enabled,CASE WHEN :enabled THEN now() END,CASE WHEN NOT :enabled THEN now() END)
        ON CONFLICT (cliente_id) DO UPDATE SET whatsapp_habilitado=EXCLUDED.whatsapp_habilitado,
        otorgado_en=CASE WHEN EXCLUDED.whatsapp_habilitado THEN now() ELSE consentimientos_notificacion.otorgado_en END,
        revocado_en=CASE WHEN NOT EXCLUDED.whatsapp_habilitado THEN now() ELSE NULL END, actualizado_en=now()"""),
        {"id": cliente_id, "enabled": data.whatsapp_habilitado})
    db.commit(); return {"cliente_id": cliente_id, "whatsapp_habilitado": data.whatsapp_habilitado}


@router.get("")
def list_notifications(db: Session = Depends(get_db), user: dict = Depends(current_user)):
    rows = db.execute(text("SELECT * FROM notificaciones_cliente ORDER BY id DESC LIMIT 200")).mappings().all()
    return {"notificaciones": [dict(x) for x in rows], "proveedor": "simulado"}


@router.post("/procesar")
def process_notifications(db: Session = Depends(get_db), user: dict = Depends(current_user)):
    now = datetime.now(SANTO_DOMINGO)
    upcoming = db.execute(text("""SELECT ci.id,pa.cliente_id FROM citas ci
        JOIN pacientes pa ON pa.id=ci.paciente_id JOIN clientes c ON c.id=pa.cliente_id
        JOIN consentimientos_notificacion co ON co.cliente_id=c.id AND co.whatsapp_habilitado=true
        WHERE ci.estado='pendiente' AND c.telefono IS NOT NULL
        AND ci.fecha_hora >= :start AND ci.fecha_hora < :end"""),
        {"start": now + timedelta(hours=23), "end": now + timedelta(hours=25)}).mappings().all()
    for appointment in upcoming:
        db.execute(text("""INSERT INTO notificaciones_cliente(cliente_id,tipo,cita_id,plantilla,deduplicacion_clave,programado_para)
            VALUES (:client,'recordatorio_cita',:appointment,'recordatorio_cita',:key,now())
            ON CONFLICT (deduplicacion_clave) DO NOTHING"""),
            {"client": appointment["cliente_id"], "appointment": appointment["id"], "key": f"cita-24h:{appointment['id']}"})
    pending = db.execute(text("SELECT id FROM notificaciones_cliente WHERE estado='pendiente' AND programado_para<=now() FOR UPDATE")).scalars().all()
    delivered = [simulate_delivery(db, notification_id) for notification_id in pending]
    db.commit(); return {"procesadas": delivered, "proveedor": "simulado"}


@router.post("/simular-mensaje")
def simulate_incoming(data: SimulateMessageIn, db: Session = Depends(get_db), user: dict = Depends(current_user)):
    code = data.texto.strip().upper()
    if code in {"HORARIO", "HORARIOS"}:
        return {"respuesta": "Horario y ubicación: consulte la configuración de la óptica.", "simulado": True}
    if code in {"HUMANO", "ASESOR", "AYUDA"}:
        return {"respuesta": "Solicitud registrada para atención por un empleado.", "simulado": True}
    if code.startswith("OE-PED-") or code.startswith("OE-REP-"):
        table = "pedidos_lentes" if code.startswith("OE-PED-") else "reparaciones"
        row = db.execute(text(f"SELECT codigo,estado,fecha_estimada FROM {table} WHERE codigo=:code"), {"code": code}).mappings().first()
        if not row: return {"respuesta": "No se encontró ese código.", "simulado": True}
        return {"respuesta": f"{row['codigo']}: estado {row['estado'].upper()}.", "simulado": True}
    return {"respuesta": "Escriba OE-PED-###### u OE-REP-######, HORARIOS o HUMANO.", "simulado": True}
