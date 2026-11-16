"""Operaciones comerciales transaccionales para ONLY EYES 360.

Este módulo usa exclusivamente la sesión inyectada por FastAPI. Los importes se
reciben y calculan como ``Decimal``; nunca como ``float``.
"""
from __future__ import annotations

from datetime import date, datetime, timedelta
from decimal import Decimal, ROUND_HALF_UP
from io import BytesIO
import hashlib
import json
from pathlib import Path
import sys
from typing import Literal

import jwt
from fastapi import APIRouter, Depends, Header, HTTPException, Query
from fastapi.responses import Response
from fastapi.encoders import jsonable_encoder
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, KeepTogether

from app.database import get_db
from app.security import crear_hash, verificar_token

router = APIRouter(prefix="/api", tags=["comercial"])
bearer = HTTPBearer(auto_error=False)
MONEY = Decimal("0.01")


def money(value: Decimal) -> Decimal:
    return Decimal(value).quantize(MONEY, rounding=ROUND_HALF_UP)


def current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db),
) -> dict:
    denied = HTTPException(status_code=401, detail="Inicia sesión con un token válido.")
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise denied
    try:
        user_id = verificar_token(credentials.credentials)
    except (jwt.PyJWTError, ValueError, TypeError):
        raise denied
    user = db.execute(text("SELECT id, nombre, usuario, rol, activo FROM usuarios WHERE id=:id"), {"id": user_id}).mappings().first()
    if not user or not user["activo"]:
        raise denied
    return dict(user)


def manager(user: dict = Depends(current_user)) -> dict:
    if user["rol"] not in {"admin", "administrador", "gerente", "supervisor"}:
        raise HTTPException(status_code=403, detail="No tienes permiso para esta operación.")
    return user


class ProductIn(BaseModel):
    codigo: str = Field(min_length=1, max_length=50)
    nombre: str = Field(min_length=1, max_length=150)
    categoria: Literal["montura", "cristal", "medicamento", "accesorio", "otro"] = "otro"
    marca: str | None = Field(default=None, max_length=100)
    descripcion: str | None = None
    precio_compra: Decimal = Field(default=Decimal("0"), ge=0)
    precio_venta: Decimal = Field(ge=0)
    stock_actual: int = Field(default=0, ge=0)
    stock_minimo: int = Field(default=0, ge=0)
    itbis_tasa: Decimal = Field(default=Decimal("0"), ge=0, le=1)


class StockMoveIn(BaseModel):
    producto_id: int
    tipo: Literal["entrada", "salida", "ajuste"]
    cantidad: int = Field(gt=0)
    motivo: str = Field(min_length=1, max_length=200)
    observaciones: str | None = None
    ajuste_aumenta: bool = True


class SupplierIn(BaseModel):
    nombre: str = Field(min_length=1, max_length=150)
    rnc: str | None = Field(default=None, max_length=20)
    telefono: str | None = Field(default=None, max_length=30)
    correo: str | None = Field(default=None, max_length=150)
    direccion: str | None = None
    contacto: str | None = Field(default=None, max_length=150)
    observaciones: str | None = None


class SaleLineIn(BaseModel):
    producto_id: int
    cantidad: int = Field(gt=0)
    descuento: Decimal = Field(default=Decimal("0"), ge=0)


class NewSaleClientIn(BaseModel):
    nombres: str = Field(min_length=1, max_length=100)
    apellidos: str | None = Field(default=None, max_length=100)
    telefono: str | None = Field(default=None, max_length=30)
    correo: str | None = Field(default=None, max_length=150)


class SaleIn(BaseModel):
    cliente_id: int | None = None
    cliente_nuevo: NewSaleClientIn | None = None
    tipo_comprobante: str = Field(default="sin_ncf", max_length=30)
    impuestos: Decimal = Field(default=Decimal("0"), ge=0)
    observaciones: str | None = None
    detalles: list[SaleLineIn] = Field(min_length=1)


class PaymentIn(BaseModel):
    monto: Decimal = Field(gt=0)
    metodo_pago: Literal["efectivo", "tarjeta", "transferencia", "credito", "seguro", "otro"]
    referencia: str | None = Field(default=None, max_length=100)
    observaciones: str | None = None
    monto_recibido: Decimal | None = Field(default=None, gt=0)
    # None distingue comprobantes antiguos/sistemas clientes que no capturaron
    # efectivo recibido. No se debe inventar ese dato al reimprimir.
    cambio: Decimal | None = Field(default=None, ge=0)


class MixedPaymentsIn(BaseModel):
    pagos: list[PaymentIn] = Field(min_length=2)


class SystemUserIn(BaseModel):
    """Alta de usuarios desde Administración; nunca expone hashes ni claves."""
    nombre: str = Field(min_length=2, max_length=150)
    usuario: str = Field(min_length=3, max_length=60, pattern=r"^[A-Za-z0-9._-]+$")
    contrasena: str = Field(min_length=4, max_length=128)
    rol: Literal["administrador", "cajero", "gerente", "supervisor"] = "cajero"


class BusinessProfileIn(BaseModel):
    """Datos que se imprimen en comprobantes; nunca contiene credenciales."""
    nombre_comercial: str = Field(min_length=2, max_length=160)
    eslogan: str | None = Field(default=None, max_length=200)
    rnc: str | None = Field(default=None, max_length=30)
    direccion: str | None = Field(default=None, max_length=300)
    telefono: str | None = Field(default=None, max_length=50)


@router.get("/usuarios")
def list_system_users(db: Session = Depends(get_db), user: dict = Depends(manager)):
    rows = db.execute(text("""SELECT id, nombre, usuario, rol, activo
        FROM usuarios ORDER BY activo DESC, nombre ASC, id ASC""")).mappings().all()
    return {"usuarios": [dict(row) for row in rows]}


@router.post("/usuarios", status_code=201)
def create_system_user(data: SystemUserIn, db: Session = Depends(get_db), user: dict = Depends(manager)):
    try:
        user_id = db.execute(text("""INSERT INTO usuarios(nombre, usuario, password_hash, rol, activo)
            VALUES (:nombre, :usuario, :password_hash, :rol, true) RETURNING id"""), {
            "nombre": data.nombre.strip(),
            "usuario": data.usuario.strip(),
            "password_hash": crear_hash(data.contrasena),
            "rol": data.rol,
        }).scalar_one()
        db.commit()
        return {"id": user_id, "nombre": data.nombre.strip(), "usuario": data.usuario.strip(), "rol": data.rol, "activo": True}
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Ese nombre de usuario ya existe.") from exc


@router.get("/datos-negocio")
def business_profile(db: Session = Depends(get_db), user: dict = Depends(current_user)):
    row = db.execute(text("""SELECT nombre_comercial, eslogan, rnc, direccion, telefono
        FROM datos_negocio WHERE id=1""")).mappings().first()
    return dict(row) if row else {
        "nombre_comercial": "Óptica ONLY EYES S.R.L.", "eslogan": "Un compromiso con tu visión",
        "rnc": None, "direccion": None, "telefono": None,
    }


@router.post("/datos-negocio")
def save_business_profile(data: BusinessProfileIn, db: Session = Depends(get_db), user: dict = Depends(manager)):
    values = {key: (value.strip() if isinstance(value, str) else value)
              for key, value in data.model_dump().items()}
    db.execute(text("""INSERT INTO datos_negocio(id,nombre_comercial,eslogan,rnc,direccion,telefono,actualizado_en)
        VALUES (1,:nombre_comercial,:eslogan,:rnc,:direccion,:telefono,now())
        ON CONFLICT (id) DO UPDATE SET nombre_comercial=EXCLUDED.nombre_comercial,
        eslogan=EXCLUDED.eslogan,rnc=EXCLUDED.rnc,direccion=EXCLUDED.direccion,
        telefono=EXCLUDED.telefono,actualizado_en=now()"""), values)
    db.commit()
    return values


def idempotent_response(db: Session, user_id: int, operation: str, key: str | None, payload: BaseModel) -> dict | None:
    if not key:
        return None
    if len(key) > 128:
        raise HTTPException(422, "Idempotency-Key excede 128 caracteres.")
    digest = hashlib.sha256(payload.model_dump_json().encode()).hexdigest()
    old = db.execute(text("""SELECT solicitud_hash, respuesta FROM claves_idempotencia
                            WHERE operacion=:op AND clave=:key AND usuario_id=:uid"""),
                     {"op": operation, "key": key, "uid": user_id}).mappings().first()
    if old:
        if old["solicitud_hash"] != digest:
            raise HTTPException(409, "La clave de idempotencia ya fue usada con otra solicitud.")
        if old["respuesta"] is not None:
            return old["respuesta"]
    return None


def save_idempotency(db: Session, user_id: int, operation: str, key: str | None, payload: BaseModel, response: dict) -> None:
    if not key:
        return
    digest = hashlib.sha256(payload.model_dump_json().encode()).hexdigest()
    db.execute(text("""INSERT INTO claves_idempotencia(operacion, clave, usuario_id, solicitud_hash, respuesta, completado_en)
                    VALUES (:op,:key,:uid,:hash,CAST(:response AS jsonb),now())"""),
               {"op": operation, "key": key, "uid": user_id, "hash": digest,
                "response": json.dumps(jsonable_encoder(response))})


@router.get("/productos")
def products(categoria: str | None = None, incluir_inactivos: bool = False, limite: int = Query(100, ge=1, le=500), db: Session = Depends(get_db), user: dict = Depends(current_user)):
    rows = db.execute(text("""SELECT * FROM productos WHERE (CAST(:cat AS varchar) IS NULL OR categoria=CAST(:cat AS varchar))
        AND (:all OR activo=true) ORDER BY nombre LIMIT :limit"""), {"cat": categoria, "all": incluir_inactivos, "limit": limite}).mappings().all()
    return {"productos": [dict(r) for r in rows]}


@router.get("/productos/buscar")
def search_products(q: str = Query(min_length=1, max_length=100), categoria: str | None = None, db: Session = Depends(get_db), user: dict = Depends(current_user)):
    rows = db.execute(text("""SELECT * FROM productos WHERE activo=true AND (CAST(:cat AS varchar) IS NULL OR categoria=CAST(:cat AS varchar))
        AND (codigo ILIKE :q OR nombre ILIKE :q OR marca ILIKE :q) ORDER BY nombre LIMIT 100"""), {"q": f"%{q}%", "cat": categoria}).mappings().all()
    return {"productos": [dict(r) for r in rows]}


@router.get("/productos/stock-bajo")
def low_stock(db: Session = Depends(get_db), user: dict = Depends(current_user)):
    rows = db.execute(text("SELECT * FROM productos WHERE activo=true AND stock_actual <= stock_minimo ORDER BY stock_actual, nombre")).mappings().all()
    return {"productos": [dict(r) for r in rows]}


@router.post("/productos", status_code=201)
def create_product(data: ProductIn, db: Session = Depends(get_db), user: dict = Depends(manager)):
    try:
        row = db.execute(text("""INSERT INTO productos(codigo,nombre,categoria,marca,descripcion,precio_compra,precio_venta,stock_actual,stock_minimo,activo,itbis_tasa)
          VALUES (:codigo,:nombre,:categoria,:marca,:descripcion,:precio_compra,:precio_venta,:stock_actual,:stock_minimo,true,:itbis_tasa) RETURNING id"""),
          {**data.model_dump(), "precio_compra": money(data.precio_compra), "precio_venta": money(data.precio_venta)}).scalar_one()
        db.commit(); return {"producto_id": row}
    except IntegrityError as exc:
        db.rollback(); raise HTTPException(409, "El código de producto ya existe.") from exc


@router.patch("/productos/{product_id}")
def update_product(product_id: int, data: ProductIn, db: Session = Depends(get_db), user: dict = Depends(manager)):
    values = data.model_dump(); values.update({"id": product_id, "precio_compra": money(data.precio_compra), "precio_venta": money(data.precio_venta)})
    row = db.execute(text("""UPDATE productos SET codigo=:codigo,nombre=:nombre,categoria=:categoria,marca=:marca,descripcion=:descripcion,
      precio_compra=:precio_compra,precio_venta=:precio_venta,stock_minimo=:stock_minimo,itbis_tasa=:itbis_tasa WHERE id=:id RETURNING id"""), values).first()
    if not row: db.rollback(); raise HTTPException(404, "Producto no encontrado.")
    db.commit(); return {"producto_id": product_id}


@router.delete("/productos/{product_id}")
def deactivate_product(product_id: int, db: Session = Depends(get_db), user: dict = Depends(manager)):
    found = db.execute(text("UPDATE productos SET activo=false WHERE id=:id AND activo=true RETURNING id"), {"id": product_id}).first()
    if not found: db.rollback(); raise HTTPException(404, "Producto no encontrado.")
    db.commit(); return {"producto_id": product_id, "activo": False}


@router.post("/inventario/movimientos", status_code=201)
def stock_movement(data: StockMoveIn, db: Session = Depends(get_db), user: dict = Depends(manager)):
    product = db.execute(text("SELECT id,stock_actual FROM productos WHERE id=:id FOR UPDATE"), {"id": data.producto_id}).mappings().first()
    if not product: db.rollback(); raise HTTPException(404, "Producto no encontrado.")
    delta = data.cantidad if data.tipo == "entrada" or (data.tipo == "ajuste" and data.ajuste_aumenta) else -data.cantidad
    new_stock = product["stock_actual"] + delta
    if new_stock < 0: db.rollback(); raise HTTPException(409, "Stock insuficiente.")
    db.execute(text("UPDATE productos SET stock_actual=:stock WHERE id=:id"), {"stock": new_stock, "id": data.producto_id})
    move_id = db.execute(text("""INSERT INTO movimientos_inventario(producto_id,tipo,cantidad,stock_anterior,stock_nuevo,motivo,observaciones)
       VALUES (:producto_id,:tipo,:cantidad,:old,:new,:motivo,:observaciones) RETURNING id"""), {**data.model_dump(), "old": product["stock_actual"], "new": new_stock}).scalar_one()
    db.commit(); return {"movimiento_id": move_id, "stock_actual": new_stock}


@router.get("/inventario/movimientos")
def movements(producto_id: int | None = None, limite: int = Query(50, ge=1, le=500), db: Session = Depends(get_db), user: dict = Depends(current_user)):
    rows = db.execute(text("SELECT * FROM movimientos_inventario WHERE (CAST(:id AS bigint) IS NULL OR producto_id=CAST(:id AS bigint)) ORDER BY fecha_movimiento DESC,id DESC LIMIT :limit"), {"id": producto_id, "limit": limite}).mappings().all()
    return {"movimientos": [dict(r) for r in rows]}


@router.get("/proveedores")
def suppliers(incluir_inactivos: bool = False, db: Session = Depends(get_db), user: dict = Depends(current_user)):
    rows = db.execute(text("SELECT * FROM proveedores WHERE (:all OR activo=true) ORDER BY nombre"), {"all": incluir_inactivos}).mappings().all()
    return {"proveedores": [dict(r) for r in rows]}


@router.post("/proveedores", status_code=201)
def create_supplier(data: SupplierIn, db: Session = Depends(get_db), user: dict = Depends(manager)):
    supplier_id = db.execute(text("""INSERT INTO proveedores(nombre,rnc,telefono,correo,direccion,contacto,observaciones,activo)
      VALUES (:nombre,:rnc,:telefono,:correo,:direccion,:contacto,:observaciones,true) RETURNING id"""), data.model_dump()).scalar_one()
    db.commit(); return {"proveedor_id": supplier_id}


@router.get("/proveedores/buscar")
def search_suppliers(q:str=Query(min_length=1,max_length=100),db:Session=Depends(get_db),user:dict=Depends(current_user)):
    rows=db.execute(text("SELECT * FROM proveedores WHERE activo=true AND (nombre ILIKE :q OR rnc ILIKE :q OR contacto ILIKE :q) ORDER BY nombre LIMIT 100"),{"q":f"%{q}%"}).mappings().all(); return {"proveedores":[dict(x) for x in rows]}


@router.patch("/proveedores/{supplier_id}")
def update_supplier(supplier_id:int,data:SupplierIn,db:Session=Depends(get_db),user:dict=Depends(manager)):
    row=db.execute(text("""UPDATE proveedores SET nombre=:nombre,rnc=:rnc,telefono=:telefono,correo=:correo,direccion=:direccion,contacto=:contacto,observaciones=:observaciones
      WHERE id=:id RETURNING id"""),data.model_dump()|{"id":supplier_id}).first()
    if not row: db.rollback(); raise HTTPException(404,"Proveedor no encontrado.")
    db.commit(); return {"proveedor_id":supplier_id}


def sale_summary(db: Session, sale_id: int) -> dict:
    sale = db.execute(text("""SELECT v.*, u.nombre AS vendedor_nombre, u.usuario AS vendedor_usuario,
        CONCAT_WS(' ', c.nombres, c.apellidos) AS cliente_nombre
        FROM ventas v LEFT JOIN usuarios u ON u.id=v.usuario_id
        LEFT JOIN clientes c ON c.id=v.cliente_id WHERE v.id=:id"""), {"id": sale_id}).mappings().first()
    if not sale: raise HTTPException(404, "Venta no encontrada.")
    details = db.execute(text("""SELECT d.*,p.codigo,p.nombre AS producto_nombre FROM detalle_ventas d JOIN productos p ON p.id=d.producto_id WHERE venta_id=:id"""), {"id": sale_id}).mappings().all()
    payments = db.execute(text("SELECT * FROM pagos_ventas WHERE venta_id=:id ORDER BY id"), {"id": sale_id}).mappings().all()
    data = dict(sale); data["saldo"] = money(data["total"] - data["monto_pagado"])
    return {"venta": data, "detalles": [dict(r) for r in details], "pagos": [dict(r) for r in payments]}


@router.post("/ventas", status_code=201)
def create_sale(data: SaleIn, idempotency_key: str | None = Header(default=None, alias="Idempotency-Key"), db: Session = Depends(get_db), user: dict = Depends(current_user)):
    cached = idempotent_response(db, user["id"], "venta.crear", idempotency_key, data)
    if cached is not None: return cached
    subtotal = Decimal("0")
    locked: list[tuple[SaleLineIn, dict, Decimal]] = []
    try:
        client_id = data.cliente_id
        if data.cliente_nuevo is not None:
            draft = data.cliente_nuevo
            existing = db.execute(text("""SELECT id FROM clientes WHERE lower(nombres)=lower(:name)
                AND COALESCE(lower(apellidos),'')=COALESCE(lower(:last),'')
                AND (CAST(:phone AS varchar) IS NULL OR telefono=CAST(:phone AS varchar)) LIMIT 1 FOR UPDATE"""), {"name": draft.nombres.strip(), "last": draft.apellidos.strip() if draft.apellidos else None, "phone": draft.telefono.strip() if draft.telefono else None}).first()
            client_id = existing[0] if existing else db.execute(text("""INSERT INTO clientes(nombres,apellidos,telefono,correo)
                VALUES (:name,:last,:phone,:email) RETURNING id"""), {"name": draft.nombres.strip(), "last": draft.apellidos.strip() if draft.apellidos else None, "phone": draft.telefono.strip() if draft.telefono else None, "email": draft.correo.strip() if draft.correo else None}).scalar_one()
        for line in data.detalles:
            product = db.execute(text("SELECT id,nombre,precio_venta,stock_actual,activo FROM productos WHERE id=:id FOR UPDATE"), {"id": line.producto_id}).mappings().first()
            if not product or not product["activo"]: raise HTTPException(422, f"Producto {line.producto_id} no disponible.")
            if product["stock_actual"] < line.cantidad: raise HTTPException(409, f"Stock insuficiente para {product['nombre']}.")
            line_total = money(product["precio_venta"] * line.cantidad - line.descuento)
            if line_total < 0: raise HTTPException(422, "El descuento supera el importe del producto.")
            subtotal += line_total; locked.append((line, dict(product), line_total))
        subtotal = money(subtotal); total = money(subtotal + data.impuestos)
        sale_id = db.execute(text("""INSERT INTO ventas(cliente_id,numero_factura,tipo_comprobante,subtotal,descuento,impuestos,total,monto_pagado,estado,observaciones,usuario_id)
             VALUES (:cliente_id,'PENDIENTE',:tipo, :subtotal,0,:tax,:total,0,'pendiente',:notes,:user) RETURNING id"""),
             {"cliente_id": client_id, "tipo": data.tipo_comprobante, "subtotal": subtotal, "tax": money(data.impuestos), "total": total, "notes": data.observaciones, "user": user["id"]}).scalar_one()
        db.execute(text("UPDATE ventas SET numero_factura=:number WHERE id=:id"), {"number": f"V-{sale_id:08d}", "id": sale_id})
        for line, product, line_total in locked:
            db.execute(text("""INSERT INTO detalle_ventas(venta_id,producto_id,cantidad,precio_unitario,descuento)
                VALUES (:sale,:product,:qty,:price,:discount)"""), {"sale": sale_id,"product": line.producto_id,"qty": line.cantidad,"price": money(product["precio_venta"]),"discount": money(line.descuento)})
            new_stock = product["stock_actual"] - line.cantidad
            db.execute(text("UPDATE productos SET stock_actual=:stock WHERE id=:id"), {"stock": new_stock,"id": line.producto_id})
            db.execute(text("""INSERT INTO movimientos_inventario(producto_id,tipo,cantidad,stock_anterior,stock_nuevo,motivo,observaciones)
              VALUES (:id,'salida',:qty,:old,:new,'Venta',:note)"""), {"id":line.producto_id,"qty":line.cantidad,"old":product["stock_actual"],"new":new_stock,"note":f"Venta {sale_id}"})
        result = {"venta_id": sale_id, "numero_factura": f"V-{sale_id:08d}", "total": total, "estado": "pendiente"}
        save_idempotency(db, user["id"], "venta.crear", idempotency_key, data, result); db.commit(); return result
    except HTTPException:
        db.rollback(); raise
    except IntegrityError as exc:
        db.rollback(); raise HTTPException(409, "No se pudo registrar la venta.") from exc


@router.get("/ventas")
def sales(cliente_id: int | None = None, estado: str | None = None, limite: int = Query(100, ge=1, le=500), offset: int = Query(0, ge=0), db: Session = Depends(get_db), user: dict = Depends(current_user)):
    rows = db.execute(text("""SELECT v.*,c.nombres,c.apellidos,u.nombre AS vendedor_nombre,u.usuario AS vendedor_usuario FROM ventas v
       LEFT JOIN clientes c ON c.id=v.cliente_id LEFT JOIN usuarios u ON u.id=v.usuario_id
       WHERE (CAST(:client AS bigint) IS NULL OR v.cliente_id=CAST(:client AS bigint)) AND (CAST(:state AS varchar) IS NULL OR v.estado=CAST(:state AS varchar)) ORDER BY v.id DESC LIMIT :limit OFFSET :offset"""), {"client":cliente_id,"state":estado,"limit":limite,"offset":offset}).mappings().all()
    return {"ventas": [dict(r) | {"saldo": money(r["total"]-r["monto_pagado"])} for r in rows]}


@router.get("/ventas/{sale_id}")
def sale_detail(sale_id: int, db: Session = Depends(get_db), user: dict = Depends(current_user)):
    return sale_summary(db, sale_id)


def pay_sale(db: Session, sale_id: int, payments: list[PaymentIn], user_id: int) -> dict:
    sale = db.execute(text("SELECT * FROM ventas WHERE id=:id FOR UPDATE"), {"id": sale_id}).mappings().first()
    if not sale: raise HTTPException(404, "Venta no encontrada.")
    if sale["estado"] == "anulada": raise HTTPException(409, "No se puede cobrar una venta anulada.")
    amount = money(sum((p.monto for p in payments), Decimal("0")))
    balance = money(sale["total"] - sale["monto_pagado"])
    if amount > balance: raise HTTPException(409, "El pago excede el saldo pendiente.")
    # Todo cobro comercial pertenece a un turno: efectivo, tarjeta,
    # transferencia, avance y abono posterior. La cerradura evita que un cierre
    # concurrente deje un pago fuera del cuadre.
    cash_shift = open_shift(db, user_id, for_update=True)
    if not cash_shift:
        raise HTTPException(409, "Abre la caja para continuar.")
    for p in payments:
        applied = money(p.monto)
        received = money(p.monto_recibido) if p.monto_recibido is not None else None
        change = money(p.cambio) if p.cambio is not None else None
        calculated_change = change if change is not None else Decimal("0")
        if p.metodo_pago != "efectivo" and (calculated_change != 0 or (received is not None and received != applied)):
            raise HTTPException(422,"El cambio sólo se permite para efectivo.")
        if p.metodo_pago == "efectivo" and received is not None and money(received-calculated_change) != applied:
            raise HTTPException(422,"El efectivo recibido menos el cambio debe coincidir con el cobro aplicado.")
        if p.metodo_pago == "efectivo" and received is None and calculated_change != 0:
            raise HTTPException(422,"No se puede registrar cambio sin efectivo recibido.")
        db.execute(text("""INSERT INTO pagos_ventas(venta_id,monto,metodo_pago,referencia,observaciones,turno_caja_id,usuario_id,monto_recibido,cambio)
            VALUES (:sale,:amount,:method,:reference,:notes,:turn,:user,:received,:change)"""), {"sale":sale_id,"amount":applied,"method":p.metodo_pago,"reference":p.referencia,"notes":p.observaciones,"turn":cash_shift["id"],"user":user_id,"received":received,"change":change})
        # Only physical cash belongs in the till. Card and transfer payments are
        # settled externally and must not inflate the expected cash count.
        if p.metodo_pago == "efectivo":
            db.execute(text("""INSERT INTO movimientos_caja_app
                    (turno_id,usuario_id,tipo,origen,monto,concepto,referencia)
                    VALUES (:turn,:user,'ingreso','venta',:amount,:concept,:reference)"""), {
                    "turn": cash_shift["id"], "user": user_id, "amount": money(p.monto),
                    "concept": f"Cobro en efectivo venta #{sale_id}",
                    "reference": f"VENTA-{sale_id}",
                })
    paid = money(sale["monto_pagado"] + amount); status = "pagada" if paid == sale["total"] else "parcial"
    db.execute(text("UPDATE ventas SET monto_pagado=:paid,estado=:status WHERE id=:id"), {"paid":paid,"status":status,"id":sale_id})
    return {"venta_id":sale_id,"monto_pagado":paid,"saldo":money(sale["total"]-paid),"estado":status}


@router.post("/ventas/{sale_id}/pagos", status_code=201)
def payment(sale_id: int, data: PaymentIn, idempotency_key: str | None = Header(default=None, alias="Idempotency-Key"), db: Session = Depends(get_db), user: dict = Depends(current_user)):
    cached=idempotent_response(db,user["id"],f"venta.{sale_id}.pago",idempotency_key,data)
    if cached is not None:return cached
    try:
        result=pay_sale(db,sale_id,[data],user["id"]); save_idempotency(db,user["id"],f"venta.{sale_id}.pago",idempotency_key,data,result); db.commit(); return result
    except HTTPException: db.rollback(); raise


@router.post("/ventas/{sale_id}/pagos-mixtos", status_code=201)
def mixed_payment(sale_id: int, data: MixedPaymentsIn, idempotency_key: str | None = Header(default=None, alias="Idempotency-Key"), db: Session = Depends(get_db), user: dict = Depends(current_user)):
    cached=idempotent_response(db,user["id"],f"venta.{sale_id}.pagos_mixtos",idempotency_key,data)
    if cached is not None:return cached
    try:
        result=pay_sale(db,sale_id,data.pagos,user["id"]); save_idempotency(db,user["id"],f"venta.{sale_id}.pagos_mixtos",idempotency_key,data,result); db.commit(); return result
    except HTTPException: db.rollback(); raise


@router.get("/cuentas-por-cobrar")
def receivables(cliente_id: int | None = None, limite: int = Query(100, ge=1, le=500), db: Session = Depends(get_db), user: dict = Depends(current_user)):
    rows=db.execute(text("""SELECT v.id venta_id,v.cliente_id,c.nombres,c.apellidos,v.fecha_venta,v.total,v.monto_pagado,
      v.total-v.monto_pagado saldo,v.estado FROM ventas v LEFT JOIN clientes c ON c.id=v.cliente_id
      WHERE v.estado IN ('pendiente','parcial') AND (CAST(:client AS bigint) IS NULL OR v.cliente_id=CAST(:client AS bigint)) ORDER BY v.fecha_venta LIMIT :limit"""),{"client":cliente_id,"limit":limite}).mappings().all()
    return {"cuentas":[dict(r) for r in rows]}


@router.post("/ventas/{sale_id}/anular")
def cancel_sale(sale_id:int,db:Session=Depends(get_db),user:dict=Depends(manager)):
    sale=db.execute(text("SELECT * FROM ventas WHERE id=:id FOR UPDATE"),{"id":sale_id}).mappings().first()
    if not sale: raise HTTPException(404,"Venta no encontrada.")
    if sale["estado"]=="anulada": return {"venta_id":sale_id,"estado":"anulada","ya_anulada":True}
    if sale["monto_pagado"]>0: raise HTTPException(409,"Una venta con pagos no puede anularse sin reversar sus cobros.")
    lines=db.execute(text("SELECT * FROM detalle_ventas WHERE venta_id=:id"),{"id":sale_id}).mappings().all()
    for line in lines:
        product=db.execute(text("SELECT stock_actual FROM productos WHERE id=:id FOR UPDATE"),{"id":line["producto_id"]}).mappings().first()
        if product:
            new=product["stock_actual"]+line["cantidad"]; db.execute(text("UPDATE productos SET stock_actual=:stock WHERE id=:id"),{"stock":new,"id":line["producto_id"]})
            db.execute(text("INSERT INTO movimientos_inventario(producto_id,tipo,cantidad,stock_anterior,stock_nuevo,motivo,observaciones) VALUES (:id,'entrada',:qty,:old,:new,'Anulación de venta',:note)"),{"id":line["producto_id"],"qty":line["cantidad"],"old":product["stock_actual"],"new":new,"note":f"Venta {sale_id}"})
    db.execute(text("UPDATE ventas SET estado='anulada' WHERE id=:id"),{"id":sale_id}); db.commit(); return {"venta_id":sale_id,"estado":"anulada"}


# Compras, clínica, caja y documentos. Se apoyan únicamente en las tablas ya
# existentes en onlyeyes360_test; no crean ni modifican el esquema.
class PurchaseLineIn(BaseModel):
    producto_id: int
    cantidad: int = Field(gt=0)
    precio_unitario: Decimal = Field(gt=0)


class PurchaseIn(BaseModel):
    proveedor_id: int
    fecha_compra: date | None = None
    numero_factura: str | None = Field(default=None, max_length=100)
    observaciones: str | None = None
    impuestos: Decimal = Field(default=Decimal("0"), ge=0)
    detalles: list[PurchaseLineIn] = Field(min_length=1)


class AppointmentIn(BaseModel):
    paciente_id: int
    fecha_hora: datetime
    motivo: str = Field(min_length=1, max_length=200)
    profesional: str | None = Field(default=None, max_length=150)
    observaciones: str | None = None


class NewClientForAppointmentIn(BaseModel):
    nombres: str = Field(min_length=1, max_length=100)
    apellidos: str | None = Field(default=None, max_length=100)
    telefono: str | None = Field(default=None, max_length=30)
    correo: str | None = Field(default=None, max_length=150)


class AppointmentWithNewClientIn(BaseModel):
    cliente: NewClientForAppointmentIn
    fecha_hora: datetime
    motivo: str = Field(min_length=1, max_length=200)
    profesional: str | None = Field(default=None, max_length=150)
    observaciones: str | None = None


class StatusIn(BaseModel):
    estado: str = Field(min_length=1, max_length=30)
    fecha_entrega: datetime | None = None
    observaciones: str | None = None


class PrescriptionIn(BaseModel):
    paciente_id: int
    fecha_receta: date | None = None
    od_esfera: Decimal | None = None
    od_cilindro: Decimal | None = None
    od_eje: int | None = Field(default=None, ge=0, le=180)
    oi_esfera: Decimal | None = None
    oi_cilindro: Decimal | None = None
    oi_eje: int | None = Field(default=None, ge=0, le=180)
    adicion: Decimal | None = None
    distancia_pupilar: Decimal | None = None
    diagnostico: str | None = None
    observaciones: str | None = None
    profesional: str | None = Field(default=None, max_length=150)


class LabOrderIn(BaseModel):
    cliente_id: int
    receta_id: int | None = None
    venta_id: int | None = None
    fecha_estimada: date | None = None
    tipo_cristal: str | None = Field(default=None, max_length=100)
    tipo_montura: str | None = Field(default=None, max_length=100)
    laboratorio: str | None = Field(default=None, max_length=150)
    observaciones: str | None = None


class RepairIn(BaseModel):
    cliente_id: int
    venta_id: int | None = None
    tipo: Literal["reparacion", "garantia"] = "reparacion"
    descripcion: str = Field(min_length=1)
    fecha_estimada: date | None = None
    costo: Decimal = Field(default=Decimal("0"), ge=0)
    observaciones: str | None = None


class CashOpenIn(BaseModel):
    fondo_inicial: Decimal = Field(ge=0)
    observaciones: str | None = Field(default=None, max_length=5000)
    # La interfaz abre la caja principal por omisión. El identificador permite
    # que administración opere otra caja física ya registrada, sin convertir
    # la caja principal en un recurso compartido entre sucursales o pruebas.
    caja_id: int | None = Field(default=None, ge=1)


class CashMovementIn(BaseModel):
    tipo: Literal["ingreso", "egreso"]
    monto: Decimal = Field(gt=0)
    concepto: str = Field(min_length=1, max_length=500)
    referencia: str | None = Field(default=None, max_length=100)


class CashCloseIn(BaseModel):
    monto_contado: Decimal = Field(ge=0)
    observaciones: str | None = Field(default=None, max_length=5000)


@router.get("/compras")
def purchases(estado: str | None = None, limite: int = Query(100, ge=1, le=500), db: Session = Depends(get_db), user: dict = Depends(current_user)):
    rows = db.execute(text("""SELECT c.*, p.nombre proveedor_nombre FROM compras c JOIN proveedores p ON p.id=c.proveedor_id
      WHERE (CAST(:state AS varchar) IS NULL OR c.estado=CAST(:state AS varchar)) ORDER BY c.id DESC LIMIT :limit"""), {"state": estado, "limit": limite}).mappings().all()
    return {"compras": [dict(r) for r in rows]}


@router.post("/compras", status_code=201)
def create_purchase(data: PurchaseIn, db: Session = Depends(get_db), user: dict = Depends(manager)):
    supplier = db.execute(text("SELECT id FROM proveedores WHERE id=:id AND activo=true"), {"id": data.proveedor_id}).first()
    if not supplier: raise HTTPException(422, "Proveedor no disponible.")
    subtotal = money(sum((line.precio_unitario * line.cantidad for line in data.detalles), Decimal("0")))
    try:
        purchase_id = db.execute(text("""INSERT INTO compras(proveedor_id,numero_factura,fecha_compra,subtotal,impuestos,total,estado,observaciones)
          VALUES (:supplier,:number,:date,:subtotal,:tax,:total,'pendiente',:notes) RETURNING id"""),
          {"supplier":data.proveedor_id,"number":data.numero_factura,"date":data.fecha_compra or date.today(),"subtotal":subtotal,"tax":money(data.impuestos),"total":money(subtotal+data.impuestos),"notes":data.observaciones}).scalar_one()
        for line in data.detalles:
            product = db.execute(text("SELECT id FROM productos WHERE id=:id FOR UPDATE"), {"id":line.producto_id}).first()
            if not product: raise HTTPException(422, f"Producto {line.producto_id} no existe.")
            db.execute(text("INSERT INTO detalle_compras(compra_id,producto_id,cantidad,precio_unitario) VALUES (:purchase,:product,:qty,:price)"), {"purchase":purchase_id,"product":line.producto_id,"qty":line.cantidad,"price":money(line.precio_unitario)})
        db.commit(); return {"compra_id":purchase_id}
    except HTTPException:
        db.rollback(); raise


@router.get("/compras/{purchase_id}")
def purchase_detail(purchase_id: int, db: Session = Depends(get_db), user: dict = Depends(current_user)):
    purchase = db.execute(text("SELECT c.*,p.nombre proveedor_nombre FROM compras c JOIN proveedores p ON p.id=c.proveedor_id WHERE c.id=:id"), {"id":purchase_id}).mappings().first()
    if not purchase: raise HTTPException(404,"Compra no encontrada.")
    details=db.execute(text("SELECT d.*,p.codigo,p.nombre producto_nombre FROM detalle_compras d JOIN productos p ON p.id=d.producto_id WHERE compra_id=:id"),{"id":purchase_id}).mappings().all()
    return {"compra":dict(purchase),"detalles":[dict(x) for x in details]}


@router.post("/compras/{purchase_id}/recibir")
def receive_purchase(purchase_id: int, db: Session = Depends(get_db), user: dict = Depends(manager)):
    purchase=db.execute(text("SELECT * FROM compras WHERE id=:id FOR UPDATE"),{"id":purchase_id}).mappings().first()
    if not purchase: raise HTTPException(404,"Compra no encontrada.")
    if purchase["estado"] == "recibida": return {"compra_id":purchase_id,"estado":"recibida","ya_recibida":True}
    if purchase["estado"] == "anulada": raise HTTPException(409,"No se puede recibir una compra anulada.")
    lines=db.execute(text("SELECT * FROM detalle_compras WHERE compra_id=:id"),{"id":purchase_id}).mappings().all()
    try:
        for line in lines:
            product=db.execute(text("SELECT stock_actual FROM productos WHERE id=:id FOR UPDATE"),{"id":line["producto_id"]}).mappings().first()
            if not product: raise HTTPException(409,"Producto eliminado durante la recepción.")
            new_stock=product["stock_actual"]+line["cantidad"]
            db.execute(text("UPDATE productos SET stock_actual=:stock,precio_compra=:price WHERE id=:id"),{"stock":new_stock,"price":line["precio_unitario"],"id":line["producto_id"]})
            db.execute(text("""INSERT INTO movimientos_inventario(producto_id,tipo,cantidad,stock_anterior,stock_nuevo,motivo,observaciones)
              VALUES (:product,'entrada',:qty,:old,:new,'Recepción de compra',:note)"""),{"product":line["producto_id"],"qty":line["cantidad"],"old":product["stock_actual"],"new":new_stock,"note":f"Compra {purchase_id}"})
        db.execute(text("UPDATE compras SET estado='recibida' WHERE id=:id"),{"id":purchase_id}); db.commit()
        return {"compra_id":purchase_id,"estado":"recibida"}
    except HTTPException:
        db.rollback(); raise


@router.post("/compras/{purchase_id}/pagos", status_code=201)
def pay_purchase(purchase_id:int, data:PaymentIn, db:Session=Depends(get_db), user:dict=Depends(manager)):
    purchase=db.execute(text("SELECT * FROM compras WHERE id=:id FOR UPDATE"),{"id":purchase_id}).mappings().first()
    if not purchase: raise HTTPException(404,"Compra no encontrada.")
    paid=db.execute(text("SELECT COALESCE(SUM(monto),0) FROM pagos_compras WHERE compra_id=:id"),{"id":purchase_id}).scalar_one()
    if money(paid+data.monto)>money(purchase["total"]): raise HTTPException(409,"El pago excede el saldo de la compra.")
    db.execute(text("INSERT INTO pagos_compras(compra_id,monto,metodo_pago,referencia,observaciones) VALUES (:id,:amount,:method,:reference,:notes)"),{"id":purchase_id,"amount":money(data.monto),"method":data.metodo_pago,"reference":data.referencia,"notes":data.observaciones}); db.commit()
    return {"compra_id":purchase_id,"monto_pagado":money(paid+data.monto),"saldo":money(purchase["total"]-paid-data.monto)}


@router.get("/cuentas-por-pagar")
def payables(proveedor_id:int|None=None, limite:int=Query(100,ge=1,le=500),db:Session=Depends(get_db),user:dict=Depends(current_user)):
    rows=db.execute(text("""SELECT c.id compra_id,c.proveedor_id,p.nombre proveedor_nombre,c.fecha_compra,c.total,COALESCE(SUM(pg.monto),0) monto_pagado,
      c.total-COALESCE(SUM(pg.monto),0) saldo,c.estado FROM compras c JOIN proveedores p ON p.id=c.proveedor_id LEFT JOIN pagos_compras pg ON pg.compra_id=c.id
      WHERE c.estado<>'anulada' AND (CAST(:supplier AS bigint) IS NULL OR c.proveedor_id=CAST(:supplier AS bigint)) GROUP BY c.id,p.nombre HAVING c.total>COALESCE(SUM(pg.monto),0) ORDER BY c.fecha_compra LIMIT :limit"""),{"supplier":proveedor_id,"limit":limite}).mappings().all()
    return {"cuentas":[dict(x) for x in rows]}


@router.get("/recetas")
def prescriptions(db:Session=Depends(get_db),user:dict=Depends(current_user)):
    rows=db.execute(text("SELECT * FROM recetas ORDER BY fecha_receta DESC,id DESC LIMIT 200")).mappings().all(); return {"recetas":[dict(x) for x in rows]}


@router.post("/recetas",status_code=201)
def create_prescription(data:PrescriptionIn,db:Session=Depends(get_db),user:dict=Depends(current_user)):
    if not db.execute(text("SELECT id FROM pacientes WHERE id=:id"),{"id":data.paciente_id}).first(): raise HTTPException(422,"Paciente no encontrado.")
    values=data.model_dump(); values["fecha_receta"]=values["fecha_receta"] or date.today()
    rid=db.execute(text("""INSERT INTO recetas(paciente_id,fecha_receta,od_esfera,od_cilindro,od_eje,oi_esfera,oi_cilindro,oi_eje,adicion,distancia_pupilar,diagnostico,observaciones,profesional)
       VALUES (:paciente_id,:fecha_receta,:od_esfera,:od_cilindro,:od_eje,:oi_esfera,:oi_cilindro,:oi_eje,:adicion,:distancia_pupilar,:diagnostico,:observaciones,:profesional) RETURNING id"""),values).scalar_one(); db.commit(); return {"receta_id":rid}


@router.get("/recetas/{recipe_id}")
def prescription_detail(recipe_id:int,db:Session=Depends(get_db),user:dict=Depends(current_user)):
    row=db.execute(text("SELECT * FROM recetas WHERE id=:id"),{"id":recipe_id}).mappings().first()
    if not row: raise HTTPException(404,"Receta no encontrada.")
    return dict(row)


@router.get("/pacientes/{patient_id}/recetas")
def prescriptions_for_patient(patient_id:int,db:Session=Depends(get_db),user:dict=Depends(current_user)):
    rows=db.execute(text("SELECT * FROM recetas WHERE paciente_id=:id ORDER BY fecha_receta DESC,id DESC"),{"id":patient_id}).mappings().all(); return {"recetas":[dict(x) for x in rows]}


@router.get("/citas")
def appointments(estado:str|None=None,paciente_id:int|None=None,fecha_desde:date|None=None,fecha_hasta:date|None=None,db:Session=Depends(get_db),user:dict=Depends(current_user)):
    rows=db.execute(text("""SELECT ci.*,c.nombres,c.apellidos,c.telefono FROM citas ci JOIN pacientes pa ON pa.id=ci.paciente_id JOIN clientes c ON c.id=pa.cliente_id
      WHERE (CAST(:state AS varchar) IS NULL OR ci.estado=CAST(:state AS varchar)) AND (CAST(:patient AS bigint) IS NULL OR ci.paciente_id=CAST(:patient AS bigint)) AND (CAST(:start AS date) IS NULL OR ci.fecha_hora>=CAST(:start AS date)) AND (CAST(:end AS date) IS NULL OR ci.fecha_hora<CAST(:end AS date)+interval '1 day') ORDER BY ci.fecha_hora"""),{"state":estado,"patient":paciente_id,"start":fecha_desde,"end":fecha_hasta}).mappings().all(); return {"citas":[dict(x) for x in rows]}


@router.post("/citas",status_code=201)
def create_appointment(data:AppointmentIn,db:Session=Depends(get_db),user:dict=Depends(current_user)):
    if not db.execute(text("SELECT id FROM pacientes WHERE id=:id"),{"id":data.paciente_id}).first(): raise HTTPException(422,"Paciente no encontrado.")
    cid=db.execute(text("INSERT INTO citas(paciente_id,usuario_id,fecha_hora,motivo,estado,profesional,observaciones) VALUES (:patient,:user,:when,:reason,'pendiente',:professional,:notes) RETURNING id"),{"patient":data.paciente_id,"user":user["id"],"when":data.fecha_hora,"reason":data.motivo,"professional":data.profesional,"notes":data.observaciones}).scalar_one(); db.commit(); return {"cita_id":cid}


@router.post("/citas/con-cliente", status_code=201)
def create_appointment_with_new_client(data: AppointmentWithNewClientIn, db: Session = Depends(get_db), user: dict = Depends(current_user)):
    """Crea cliente, paciente y cita como una única operación atómica."""
    try:
        client = data.cliente
        existing = db.execute(text("""SELECT id FROM clientes WHERE lower(nombres)=lower(:name)
            AND COALESCE(lower(apellidos),'')=COALESCE(lower(:last),'')
            AND (CAST(:phone AS varchar) IS NULL OR telefono=CAST(:phone AS varchar)) LIMIT 1 FOR UPDATE"""), {
            "name": client.nombres.strip(), "last": client.apellidos.strip() if client.apellidos else None,
            "phone": client.telefono.strip() if client.telefono else None,
        }).first()
        if existing:
            raise HTTPException(409, "Ya existe un cliente con esos datos. Selecciónalo en la búsqueda.")
        client_id = db.execute(text("""INSERT INTO clientes(nombres,apellidos,telefono,correo)
            VALUES (:name,:last,:phone,:email) RETURNING id"""), {
                "name": client.nombres.strip(), "last": client.apellidos.strip() if client.apellidos else None,
                "phone": client.telefono.strip() if client.telefono else None,
                "email": client.correo.strip() if client.correo else None,
            }).scalar_one()
        patient_id = db.execute(text("INSERT INTO pacientes(cliente_id) VALUES (:client) RETURNING id"), {"client": client_id}).scalar_one()
        appointment_id = db.execute(text("""INSERT INTO citas(paciente_id,usuario_id,fecha_hora,motivo,estado,profesional,observaciones)
            VALUES (:patient,:user,:when,:reason,'pendiente',:professional,:notes) RETURNING id"""), {
                "patient": patient_id, "user": user["id"], "when": data.fecha_hora, "reason": data.motivo,
                "professional": data.profesional, "notes": data.observaciones,
            }).scalar_one()
        db.commit()
        return {"cita_id": appointment_id, "cliente_id": client_id, "paciente_id": patient_id}
    except HTTPException:
        db.rollback(); raise
    except IntegrityError as exc:
        db.rollback(); raise HTTPException(409, "No se pudo registrar la cita; revisa si el cliente ya existe.") from exc


@router.patch("/citas/{appointment_id}")
def update_appointment(appointment_id:int,data:StatusIn,db:Session=Depends(get_db),user:dict=Depends(current_user)):
    if data.estado not in {"pendiente","confirmada","completada","cancelada","no_asistio"}: raise HTTPException(422,"Estado de cita inválido.")
    row=db.execute(text("UPDATE citas SET estado=:state,observaciones=COALESCE(:notes,observaciones) WHERE id=:id RETURNING id"),{"state":data.estado,"notes":data.observaciones,"id":appointment_id}).first()
    if not row: db.rollback(); raise HTTPException(404,"Cita no encontrada.")
    db.commit(); return {"cita_id":appointment_id,"estado":data.estado}


@router.get("/pedidos-lentes")
def lab_orders(estado:str|None=None,cliente_id:int|None=None,db:Session=Depends(get_db),user:dict=Depends(current_user)):
    rows=db.execute(text("""SELECT pl.*,c.nombres,c.apellidos FROM pedidos_lentes pl JOIN clientes c ON c.id=pl.cliente_id
       WHERE (CAST(:state AS varchar) IS NULL OR pl.estado=CAST(:state AS varchar)) AND (CAST(:client AS bigint) IS NULL OR pl.cliente_id=CAST(:client AS bigint)) ORDER BY pl.id DESC"""),{"state":estado,"client":cliente_id}).mappings().all()
    return {"pedidos":[dict(x) for x in rows]}


def register_work_status(db: Session, work_type: str, work_id: int, status: str, user_id: int, notes: str | None = None) -> None:
    db.execute(text("""INSERT INTO historial_estados_taller
        (tipo_trabajo,trabajo_id,estado,usuario_id,observaciones)
        VALUES (:type,:id,:status,:user,:notes)"""), {
        "type": work_type, "id": work_id, "status": status,
        "user": user_id, "notes": notes,
    })


@router.get("/taller/{work_type}/{work_id}/historial")
def work_history(work_type: Literal["pedido", "reparacion"], work_id: int, db: Session = Depends(get_db), user: dict = Depends(current_user)):
    rows = db.execute(text("""SELECT h.*, u.nombre AS usuario_nombre
        FROM historial_estados_taller h LEFT JOIN usuarios u ON u.id=h.usuario_id
        WHERE h.tipo_trabajo=:type AND h.trabajo_id=:id ORDER BY h.creado_en"""),
        {"type": work_type, "id": work_id}).mappings().all()
    return {"historial": [dict(row) for row in rows]}


@router.post("/pedidos-lentes",status_code=201)
def create_lab_order(data:LabOrderIn,db:Session=Depends(get_db),user:dict=Depends(current_user)):
    if not db.execute(text("SELECT id FROM clientes WHERE id=:id"),{"id":data.cliente_id}).first(): raise HTTPException(422,"Cliente no encontrado.")
    values=data.model_dump(); values["user"]=user["id"]
    pid=db.execute(text("""INSERT INTO pedidos_lentes(cliente_id,receta_id,venta_id,usuario_id,fecha_estimada,tipo_cristal,tipo_montura,laboratorio,estado,observaciones,codigo)
       VALUES (:cliente_id,:receta_id,:venta_id,:user,:fecha_estimada,:tipo_cristal,:tipo_montura,:laboratorio,'pendiente',:observaciones,CONCAT('TMP-PED-',txid_current())) RETURNING id"""),values).scalar_one()
    code=f"OE-PED-{pid:06d}"
    db.execute(text("UPDATE pedidos_lentes SET codigo=:code WHERE id=:id"), {"code": code, "id": pid})
    register_work_status(db, "pedido", pid, "pendiente", user["id"], data.observaciones)
    db.commit(); return {"pedido_id":pid,"codigo":code}


@router.patch("/pedidos-lentes/{order_id}/estado")
def update_lab_order(order_id:int,data:StatusIn,db:Session=Depends(get_db),user:dict=Depends(current_user)):
    allowed={"pendiente","en_preparacion","en_laboratorio","listo","entregado","cancelado"}
    if data.estado not in allowed: raise HTTPException(422,"Estado de pedido inválido.")
    row=db.execute(text("""UPDATE pedidos_lentes SET estado=:state,fecha_entrega=CASE WHEN :delivered THEN COALESCE(:date,now()) ELSE fecha_entrega END,
       observaciones=COALESCE(:notes,observaciones) WHERE id=:id RETURNING id"""),{"state":data.estado,"delivered":data.estado=="entregado","date":data.fecha_entrega,"notes":data.observaciones,"id":order_id}).first()
    if not row: db.rollback(); raise HTTPException(404,"Pedido no encontrado.")
    register_work_status(db, "pedido", order_id, data.estado, user["id"], data.observaciones)
    if data.estado == "listo":
        from app.notifications import enqueue_ready_work
        enqueue_ready_work(db, "pedido", order_id)
    db.commit(); return {"pedido_id":order_id,"estado":data.estado}


@router.get("/reparaciones")
def repairs(estado:str|None=None,cliente_id:int|None=None,db:Session=Depends(get_db),user:dict=Depends(current_user)):
    rows=db.execute(text("""SELECT r.*,c.nombres,c.apellidos FROM reparaciones r JOIN clientes c ON c.id=r.cliente_id
       WHERE (CAST(:state AS varchar) IS NULL OR r.estado=CAST(:state AS varchar)) AND (CAST(:client AS bigint) IS NULL OR r.cliente_id=CAST(:client AS bigint)) ORDER BY r.id DESC"""),{"state":estado,"client":cliente_id}).mappings().all()
    return {"reparaciones":[dict(x) for x in rows]}


@router.post("/reparaciones",status_code=201)
def create_repair(data:RepairIn,db:Session=Depends(get_db),user:dict=Depends(current_user)):
    if not db.execute(text("SELECT id FROM clientes WHERE id=:id"),{"id":data.cliente_id}).first(): raise HTTPException(422,"Cliente no encontrado.")
    values=data.model_dump(); values["costo"]=money(data.costo); values["user"]=user["id"]
    rid=db.execute(text("""INSERT INTO reparaciones(cliente_id,venta_id,usuario_id,tipo,descripcion,fecha_estimada,costo,estado,observaciones,codigo)
       VALUES (:cliente_id,:venta_id,:user,:tipo,:descripcion,:fecha_estimada,:costo,'recibido',:observaciones,CONCAT('TMP-REP-',txid_current())) RETURNING id"""),values).scalar_one()
    code=f"OE-REP-{rid:06d}"
    db.execute(text("UPDATE reparaciones SET codigo=:code WHERE id=:id"), {"code": code, "id": rid})
    register_work_status(db, "reparacion", rid, "recibido", user["id"], data.observaciones)
    db.commit(); return {"reparacion_id":rid,"codigo":code}


@router.patch("/reparaciones/{repair_id}/estado")
def update_repair(repair_id:int,data:StatusIn,db:Session=Depends(get_db),user:dict=Depends(current_user)):
    allowed={"recibido","en_revision","en_reparacion","listo","entregado","cancelado"}
    if data.estado not in allowed: raise HTTPException(422,"Estado de reparación inválido.")
    row=db.execute(text("""UPDATE reparaciones SET estado=:state,fecha_entrega=CASE WHEN :delivered THEN COALESCE(:date,now()) ELSE fecha_entrega END,
       observaciones=COALESCE(:notes,observaciones) WHERE id=:id RETURNING id"""),{"state":data.estado,"delivered":data.estado=="entregado","date":data.fecha_entrega,"notes":data.observaciones,"id":repair_id}).first()
    if not row: db.rollback(); raise HTTPException(404,"Reparación no encontrada.")
    register_work_status(db, "reparacion", repair_id, data.estado, user["id"], data.observaciones)
    if data.estado == "listo":
        from app.notifications import enqueue_ready_work
        enqueue_ready_work(db, "reparacion", repair_id)
    db.commit(); return {"reparacion_id":repair_id,"estado":data.estado}


def open_shift(db:Session,user_id:int,for_update:bool=False) -> dict | None:
    lock=" FOR UPDATE" if for_update else ""
    row=db.execute(text(f"SELECT * FROM turnos_caja WHERE usuario_id=:user AND estado='abierta' ORDER BY id DESC LIMIT 1{lock}"),{"user":user_id}).mappings().first()
    return dict(row) if row else None


def shift_payload(db:Session,shift:dict) -> dict:
    moves=db.execute(text("SELECT * FROM movimientos_caja_app WHERE turno_id=:id ORDER BY id"),{"id":shift["id"]}).mappings().all()
    manual=sum((x["monto"] if x["tipo"]=="ingreso" else -x["monto"] for x in moves),Decimal("0"))
    expected=money(shift["fondo_inicial"]+manual)
    cash_sales=sum((x["monto"] for x in moves if x["origen"] == "venta" and x["tipo"] == "ingreso"),Decimal("0"))
    manual_income=sum((x["monto"] for x in moves if x["origen"] == "manual" and x["tipo"] == "ingreso"),Decimal("0"))
    manual_expense=sum((x["monto"] for x in moves if x["origen"] == "manual" and x["tipo"] == "egreso"),Decimal("0"))
    payments=db.execute(text("""SELECT metodo_pago,COALESCE(SUM(monto),0) total FROM pagos_ventas
        WHERE turno_caja_id=:id
        GROUP BY metodo_pago"""),{"id":shift["id"]}).mappings().all()
    return {"turno":shift,"movimientos":[dict(x) for x in moves],"saldo_esperado":expected,
            "resumen":{"ventas_efectivo":money(cash_sales),"ingresos_manuales":money(manual_income),"egresos_manuales":money(manual_expense),"pagos_no_efectivo":[dict(x) for x in payments]}}


@router.get("/caja/actual")
def current_shift(db:Session=Depends(get_db),user:dict=Depends(current_user)):
    shift=open_shift(db,user["id"]); return {"turno":None,"movimientos":[],"saldo_esperado":Decimal("0")} if not shift else shift_payload(db,shift)


@router.post("/caja/aperturas",status_code=201)
def open_cash(data:CashOpenIn, idempotency_key: str | None = Header(default=None, alias="Idempotency-Key"), db:Session=Depends(get_db),user:dict=Depends(current_user)):
    """Abre un único turno por cajero, incluso ante doble clic o reintento."""
    cached = idempotent_response(db, user["id"], "caja_apertura", idempotency_key, data)
    if cached:
        return cached
    box_id = data.caja_id or 1
    # Solo administración puede elegir una caja distinta a la principal. Así
    # una cajera no abre accidentalmente un turno en la gaveta de otro puesto.
    if box_id != 1 and user["rol"] not in {"admin", "administrador", "gerente", "supervisor"}:
        raise HTTPException(403, "Solo administración puede seleccionar otra caja física.")
    box = db.execute(text("SELECT id FROM cajas_fisicas WHERE id=:id AND activa=true"), {"id": box_id}).first()
    if not box:
        raise HTTPException(422, "La caja física seleccionada no está disponible.")
    # Serializa la apertura de la caja física seleccionada. La cerradura se
    # libera al confirmar la transacción y evita dos turnos en la misma gaveta.
    db.execute(text("SELECT pg_advisory_xact_lock(:user_id)"), {"user_id": user["id"]})
    db.execute(text("SELECT pg_advisory_xact_lock(:box_id)"), {"box_id": box_id})
    if open_shift(db,user["id"]):
        db.rollback()
        raise HTTPException(409,"Ya existe un turno de caja abierto para este usuario.")
    if db.execute(text("SELECT id FROM turnos_caja WHERE caja_id=:box AND estado='abierta' FOR UPDATE"), {"box": box_id}).first():
        db.rollback()
        raise HTTPException(409,"La caja física seleccionada ya está abierta por otro cajero.")
    try:
        tid=db.execute(text("INSERT INTO turnos_caja(usuario_id,caja_id,fondo_inicial,monto_esperado,estado,observaciones) VALUES (:user,:box,:float,:float,'abierta',:notes) RETURNING id"),{"user":user["id"],"box":box_id,"float":money(data.fondo_inicial),"notes":data.observaciones}).scalar_one()
        response={"turno_id":tid}
        save_idempotency(db, user["id"], "caja_apertura", idempotency_key, data, response)
        db.commit()
        return response
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(409,"No se pudo abrir la caja porque ya existe un turno activo.") from exc


@router.post("/caja/movimientos",status_code=201)
def cash_movement(data:CashMovementIn,db:Session=Depends(get_db),user:dict=Depends(current_user)):
    shift=open_shift(db,user["id"])
    if not shift: raise HTTPException(409,"Abre un turno de caja antes de registrar movimientos.")
    mid=db.execute(text("INSERT INTO movimientos_caja_app(turno_id,usuario_id,tipo,origen,monto,concepto,referencia) VALUES (:turn,:user,:type,'manual',:amount,:concept,:reference) RETURNING id"),{"turn":shift["id"],"user":user["id"],"type":data.tipo,"amount":money(data.monto),"concept":data.concepto,"reference":data.referencia}).scalar_one(); db.commit(); return {"movimiento_id":mid}


@router.get("/caja/movimientos")
def cash_movements(db:Session=Depends(get_db),user:dict=Depends(current_user)):
    shift=open_shift(db,user["id"])
    if not shift:return {"movimientos":[]}
    rows=db.execute(text("SELECT * FROM movimientos_caja_app WHERE turno_id=:id ORDER BY id"),{"id":shift["id"]}).mappings().all(); return {"movimientos":[dict(x) for x in rows]}


@router.post("/caja/cierre")
def close_cash(data:CashCloseIn,db:Session=Depends(get_db),user:dict=Depends(current_user)):
    shift=open_shift(db,user["id"],for_update=True)
    if not shift: raise HTTPException(409,"No hay turno de caja abierto.")
    payload=shift_payload(db,shift); expected=payload["saldo_esperado"]; counted=money(data.monto_contado)
    difference=money(counted-expected)
    if difference != 0 and not (data.observaciones or "").strip():
        db.rollback()
        raise HTTPException(422,"Indica una observación para registrar la diferencia de caja.")
    updated=db.execute(text("UPDATE turnos_caja SET cerrado_en=now(),monto_esperado=:expected,monto_contado=:counted,diferencia=:diff,estado='cerrada',observaciones=COALESCE(:notes,observaciones) WHERE id=:id AND estado='abierta'"),{"expected":expected,"counted":counted,"diff":difference,"notes":data.observaciones,"id":shift["id"]})
    if updated.rowcount != 1:
        db.rollback()
        raise HTTPException(409,"El turno ya fue cerrado; actualiza la pantalla.")
    db.commit()
    return {"turno_id":shift["id"],"monto_esperado":expected,"monto_contado":counted,"diferencia":difference,"estado_cuadre":"cuadrada" if difference == 0 else ("faltante" if difference < 0 else "sobrante")}


@router.get("/caja/historial")
def cash_history(fecha_desde: date | None = None, fecha_hasta: date | None = None, usuario_id: int | None = None, db: Session = Depends(get_db), user: dict = Depends(manager)):
    rows=db.execute(text("""SELECT t.*,u.nombre usuario_nombre FROM turnos_caja t JOIN usuarios u ON u.id=t.usuario_id
      WHERE (CAST(:start AS date) IS NULL OR t.abierto_en>=CAST(:start AS date))
      AND (CAST(:end AS date) IS NULL OR t.abierto_en<CAST(:end AS date)+interval '1 day')
      AND (CAST(:uid AS bigint) IS NULL OR t.usuario_id=CAST(:uid AS bigint))
      ORDER BY t.abierto_en DESC LIMIT 200"""),{"start":fecha_desde,"end":fecha_hasta,"uid":usuario_id}).mappings().all()
    return {"turnos":[dict(row) | {"resumen": shift_payload(db,dict(row))["resumen"]} for row in rows]}


@router.post("/ventas/{sale_id}/factura-comercial",status_code=201)
def commercial_invoice(sale_id:int,db:Session=Depends(get_db),user:dict=Depends(manager)):
    sale=db.execute(text("SELECT id FROM ventas WHERE id=:id"),{"id":sale_id}).first()
    if not sale: raise HTTPException(404,"Venta no encontrada.")
    existing=db.execute(text("SELECT * FROM facturas_comerciales WHERE venta_id=:id AND anulada_en IS NULL"),{"id":sale_id}).mappings().first()
    if existing:return {"factura":dict(existing),"ya_emitida":True}
    iid=db.execute(text("INSERT INTO facturas_comerciales(venta_id,numero,emitida_por,formato,nota_legal) VALUES (:sale,:number,:user,'comercial','Documento comercial no fiscal') RETURNING id,numero"),{"sale":sale_id,"number":f"COM-{sale_id:08d}","user":user["id"]}).mappings().one(); db.commit(); return {"factura":dict(iid)}


def pdf_document(lines: list[str], thermal: bool = False) -> bytes:
    """PDF sencillo pero real, construido sólo con datos persistidos de la venta."""
    width = 226 if thermal else 595
    height = max(250, len(lines) * 15 + 80) if thermal else 842
    x, y, font = (12, height - 30, 8) if thermal else (42, height - 48, 10)
    parts = [f"BT /F1 {font} Tf {x} {y} Td"]
    for index, value in enumerate(lines):
        safe = value.encode("latin-1", "replace").decode("latin-1").replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")
        if index: parts.append("0 -15 Td")
        parts.append(f"({safe[:120]}) Tj")
    parts.append("ET")
    stream="\n".join(parts).encode("latin-1")
    objects=[b"<< /Type /Catalog /Pages 2 0 R >>",b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {width} {height}] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>".encode(),b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",b"<< /Length "+str(len(stream)).encode()+b" >>\nstream\n"+stream+b"\nendstream"]
    output=b"%PDF-1.4\n"; offsets=[]
    for index,obj in enumerate(objects,1): offsets.append(len(output)); output+=f"{index} 0 obj\n".encode()+obj+b"\nendobj\n"
    start=len(output); output+=b"xref\n0 6\n0000000000 65535 f \n"+b"".join(f"{x:010d} 00000 n \n".encode() for x in offsets)+f"trailer << /Size 6 /Root 1 0 R >>\nstartxref\n{start}\n%%EOF".encode(); return output


def invoice_pdf_document(sale: dict, invoice: dict, details: list[dict], payments: list[dict], business: dict, thermal: bool) -> bytes:
    """Recibo centrado: A4 conserva la proporción visual del comprobante POS."""
    stream = BytesIO()
    receipt_width = 68 * mm if thermal else 112 * mm
    thermal_height = max(250 * mm, (185 + len(details) * 43 + len(payments) * 16) * mm)
    if thermal:
        page_size, side = (80 * mm, thermal_height), 6 * mm
    else:
        page_size, side = A4, (A4[0] - receipt_width) / 2
    doc = SimpleDocTemplate(stream, pagesize=page_size, leftMargin=side,
        rightMargin=side, topMargin=9 * mm if thermal else 20 * mm,
        bottomMargin=9 * mm if thermal else 20 * mm)
    styles = getSampleStyleSheet()
    normal = ParagraphStyle('receipt', parent=styles['Normal'], fontName='Helvetica',
        fontSize=8 if thermal else 9, leading=10 if thermal else 12)
    muted = ParagraphStyle('muted', parent=normal, fontSize=6.8 if thermal else 8,
        leading=8.5 if thermal else 10, textColor=colors.HexColor('#64748B'), alignment=1)
    heading = ParagraphStyle('heading', parent=normal, fontName='Helvetica-Bold',
        fontSize=13 if thermal else 15, leading=15 if thermal else 18, alignment=1,
        textColor=colors.HexColor('#0B5269'))
    centered = ParagraphStyle('centered', parent=normal, alignment=1)
    right = ParagraphStyle('right', parent=normal, alignment=2)
    strong_right = ParagraphStyle('strong-right', parent=right, fontName='Helvetica-Bold')
    strong = ParagraphStyle('strong', parent=normal, fontName='Helvetica-Bold')
    money_fmt = lambda value: f"RD${money(Decimal(str(value))):,.2f}"

    def rule():
        line = Table([['']], colWidths=[receipt_width], rowHeights=[0.35])
        line.setStyle(TableStyle([('BACKGROUND', (0, 0), (-1, -1), colors.HexColor('#D1D5DB')),
            ('LEFTPADDING', (0, 0), (-1, -1), 0), ('RIGHTPADDING', (0, 0), (-1, -1), 0),
            ('TOPPADDING', (0, 0), (-1, -1), 0), ('BOTTOMPADDING', (0, 0), (-1, -1), 0)]))
        return line

    def row(label: str, value: str, *, bold: bool = False, green: bool = False):
        value_style = strong_right if bold else right
        if green:
            value_style = ParagraphStyle('green-value', parent=value_style, textColor=colors.HexColor('#047857'))
        label_style = strong if bold else normal
        if green:
            label_style = ParagraphStyle('green-label', parent=label_style, textColor=colors.HexColor('#047857'))
        table = Table([[Paragraph(label, label_style), Paragraph(value, value_style)]],
            colWidths=[receipt_width * .57, receipt_width * .43])
        table.setStyle(TableStyle([('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('TOPPADDING', (0, 0), (-1, -1), 2), ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
            ('LEFTPADDING', (0, 0), (-1, -1), 0), ('RIGHTPADDING', (0, 0), (-1, -1), 0)]))
        return table

    story = []
    logo = ((Path(getattr(sys, '_MEIPASS', Path(__file__).resolve().parents[2])) / 'assets' / 'only_eyes_logo.jpg')
        if getattr(sys, 'frozen', False) else Path(__file__).resolve().parents[2] / 'flutter_app' / 'assets' / 'branding' / 'only_eyes_logo.jpg')
    if logo.exists():
        image = Image(str(logo), width=31 * mm if thermal else 36 * mm,
            height=16 * mm if thermal else 19 * mm)
        image.hAlign = 'CENTER'
        story += [image, Spacer(1, 1.5 * mm)]
    story += [Paragraph(business.get('nombre_comercial') or 'Óptica ONLY EYES S.R.L.', heading),
        Paragraph(business.get('eslogan') or 'Un compromiso con tu visión', muted)]
    for contact in [business.get('direccion'), business.get('telefono'),
                    f"RNC {business['rnc']}" if business.get('rnc') else None]:
        if contact:
            story.append(Paragraph(str(contact), muted))
    story += [Spacer(1, 2.5 * mm), Paragraph('COMPROBANTE COMERCIAL NO FISCAL',
        ParagraphStyle('legal', parent=centered, fontName='Helvetica-Bold', fontSize=7.5 if thermal else 8.5,
            textColor=colors.HexColor('#374151'))), Spacer(1, 2 * mm), rule(), Spacer(1, 1.5 * mm)]
    client = sale.get('cliente') or 'Consumidor final'
    date_text = sale['fecha_venta'].strftime('%d/%m/%Y %I:%M %p')
    metadata = [
        [Paragraph(f"<b>No:</b> {invoice['numero']}", normal), Paragraph(date_text, right)],
        [Paragraph(f"<b>Venta:</b> {sale['numero_factura']}", normal), Paragraph(f"<b>Cajero:</b> {sale.get('cajero') or 'No disponible'}", right)],
        [Paragraph(f"<b>Cliente:</b> {client}", normal), ''],
    ]
    meta = Table(metadata, colWidths=[receipt_width * .54, receipt_width * .46])
    meta.setStyle(TableStyle([('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 0), (-1, -1), 1), ('BOTTOMPADDING', (0, 0), (-1, -1), 1),
        ('LEFTPADDING', (0, 0), (-1, -1), 0), ('RIGHTPADDING', (0, 0), (-1, -1), 0)]))
    story += [meta, Spacer(1, 1.5 * mm), rule(), Spacer(1, 2 * mm),
        Paragraph('SKU · DESCRIPCIÓN · CANTIDAD · PRECIO · DESCUENTO · TOTAL',
            ParagraphStyle('items-head', parent=centered, fontName='Helvetica-Bold', fontSize=6.4 if thermal else 7))]
    for item in details:
        product = [Spacer(1, 1.8 * mm),
            Paragraph(f"<b>{item['codigo']}</b>  {item['nombre']}", normal),
            Paragraph(f"{item['cantidad']} x {money_fmt(item['precio_unitario'])} · Desc. {money_fmt(item['descuento'])}", muted),
            Paragraph(f"<b>Total línea: {money_fmt(item['total'])}</b>", strong_right),
            Spacer(1, 1.6 * mm), rule()]
        story.append(KeepTogether(product))
    story += [Spacer(1, 2 * mm), row('Subtotal:', money_fmt(sale['subtotal'])),
        row('Descuento aplicado:', f"-{money_fmt(sale['descuento'])}"),
        row('ITBIS / Impuestos:', money_fmt(sale['impuestos'])), rule(),
        row('Total de la venta:', money_fmt(sale['total']), bold=True), rule(), Spacer(1, 1.5 * mm)]
    cash = [payment for payment in payments if payment['metodo_pago'] == 'efectivo']
    received = [Decimal(str(payment['monto_recibido'])) for payment in cash if payment.get('monto_recibido') is not None]
    cash_applied = sum((Decimal(str(payment['monto'])) for payment in cash), Decimal('0'))
    change = sum((Decimal(str(payment.get('cambio') or 0)) for payment in cash), Decimal('0'))
    paid = sum((Decimal(str(payment['monto'])) for payment in payments), Decimal('0'))
    if received:
        story.append(row('Efectivo recibido:', money_fmt(sum(received, Decimal('0')))))
    if cash:
        story.append(row('Efectivo aplicado a la venta:', money_fmt(cash_applied)))
    if change:
        story.append(row('Cambio devuelto:', money_fmt(change), bold=True, green=True))
    for payment in payments:
        if payment['metodo_pago'] != 'efectivo':
            story.append(row(f"{str(payment['metodo_pago']).title()} aplicada:", money_fmt(payment['monto'])))
    balance = max(Decimal('0'), Decimal(str(sale['total'])) - paid)
    story += [row('Pagado / abono:', money_fmt(paid)), row('Saldo pendiente:', money_fmt(balance), bold=balance > 0),
        Spacer(1, 3 * mm), rule(), Spacer(1, 3 * mm),
        Paragraph('¡Gracias por confiar en ONLY EYES 360!<br/>Conserve este comprobante comercial.', muted)]
    doc.build(story)
    return stream.getvalue()


@router.get("/ventas/{sale_id}/factura-comercial/pdf")
def commercial_invoice_pdf(sale_id:int,formato:str="a4",db:Session=Depends(get_db),user:dict=Depends(current_user)):
    if formato not in {"a4", "termica"}: raise HTTPException(422, "Formato de factura no válido.")
    sale=db.execute(text("""SELECT v.*, CONCAT_WS(' ',c.nombres,c.apellidos) cliente,
        u.nombre cajero FROM ventas v LEFT JOIN clientes c ON c.id=v.cliente_id
        LEFT JOIN usuarios u ON u.id=v.usuario_id WHERE v.id=:id"""),{"id":sale_id}).mappings().first()
    invoice=db.execute(text("SELECT numero FROM facturas_comerciales WHERE venta_id=:id AND anulada_en IS NULL"),{"id":sale_id}).mappings().first()
    if not sale or not invoice: raise HTTPException(404,"Primero emite la factura comercial.")
    details=db.execute(text("""SELECT p.codigo,p.nombre,d.cantidad,d.precio_unitario,d.descuento,
        (d.cantidad*d.precio_unitario-d.descuento) total FROM detalle_ventas d
        JOIN productos p ON p.id=d.producto_id WHERE d.venta_id=:id ORDER BY d.id"""),{"id":sale_id}).mappings().all()
    payments=db.execute(text("SELECT metodo_pago,monto,monto_recibido,COALESCE(cambio,0) cambio FROM pagos_ventas WHERE venta_id=:id ORDER BY id"),{"id":sale_id}).mappings().all()
    business=db.execute(text("SELECT nombre_comercial,eslogan,rnc,direccion,telefono FROM datos_negocio WHERE id=1")).mappings().first()
    content=invoice_pdf_document(dict(sale),dict(invoice),[dict(x) for x in details],[dict(x) for x in payments],dict(business) if business else {},formato=="termica")
    suffix="ticket" if formato == "termica" else "a4"
    return Response(content,media_type="application/pdf",headers={"Content-Disposition":f'inline; filename="{invoice["numero"]}-{suffix}.pdf"'})


@router.get("/caja/{shift_id}/comprobante/pdf")
def cash_close_receipt_pdf(shift_id:int, db:Session=Depends(get_db), user:dict=Depends(current_user)):
    """Comprobante interno, no fiscal, para un turno cerrado."""
    shift=db.execute(text("""SELECT t.*,u.nombre usuario_nombre,c.nombre caja_nombre
        FROM turnos_caja t JOIN usuarios u ON u.id=t.usuario_id
        JOIN cajas_fisicas c ON c.id=t.caja_id WHERE t.id=:id"""),{"id":shift_id}).mappings().first()
    if not shift: raise HTTPException(404,"Turno de caja no encontrado.")
    elevated=user["rol"] in {"admin","administrador","gerente","supervisor"}
    if shift["usuario_id"] != user["id"] and not elevated: raise HTTPException(403,"No tienes permiso para consultar este cierre.")
    if shift["estado"] != "cerrada": raise HTTPException(409,"El comprobante se genera después del cierre.")
    payload=shift_payload(db,dict(shift)); summary=payload["resumen"]
    difference=money(shift["diferencia"] or Decimal("0"))
    state="CUADRADA" if difference == 0 else ("FALTANTE" if difference < 0 else "SOBRANTE")
    lines=["OPTICA ONLY EYES S.R.L.","CIERRE DE CAJA - DOCUMENTO INTERNO",f"Caja: {shift['caja_nombre']}  Turno: {shift['id']}",f"Cajero/a: {shift['usuario_nombre']}",f"Apertura: {shift['abierto_en']:%d/%m/%Y %I:%M %p}",f"Cierre: {shift['cerrado_en']:%d/%m/%Y %I:%M %p}","-"*48,f"Fondo inicial: RD${money(shift['fondo_inicial']):,.2f}",f"Ventas efectivo: RD${money(summary['ventas_efectivo']):,.2f}",f"Ingresos manuales: RD${money(summary['ingresos_manuales']):,.2f}",f"Egresos manuales: RD${money(summary['egresos_manuales']):,.2f}"]
    lines.extend([f"{row['metodo_pago'].title()}: RD${money(row['total']):,.2f}" for row in summary["pagos_no_efectivo"]])
    lines.extend(["-"*48,f"Efectivo esperado: RD${money(shift['monto_esperado']):,.2f}",f"Efectivo contado: RD${money(shift['monto_contado']):,.2f}",f"{state}: RD${abs(difference):,.2f}"])
    if shift["observaciones"]: lines.append(f"Observacion: {shift['observaciones']}")
    return Response(pdf_document(lines,thermal=True),media_type="application/pdf",headers={"Content-Disposition":f'inline; filename="CIERRE-{shift_id}.pdf"'})


@router.get("/reportes/ventas")
def sales_report(desde:date|None=None,hasta:date|None=None,db:Session=Depends(get_db),user:dict=Depends(current_user)):
    start=desde or date.today().replace(day=1); end=hasta or date.today()
    summary=db.execute(text("""SELECT COUNT(*) cantidad_ventas,COALESCE(SUM(total),0) total_vendido,COALESCE(SUM(monto_pagado),0) cobrado,
      COALESCE(SUM(total-monto_pagado),0) pendiente FROM ventas WHERE fecha_venta>=:start AND fecha_venta<:end+interval '1 day' AND estado<>'anulada'"""),{"start":start,"end":end}).mappings().one()
    return {"desde":start,"hasta":end,"resumen":dict(summary)}


@router.get("/reportes/ventas-serie")
def sales_series(periodo: Literal["dia", "mes", "ano"] = "dia", db: Session = Depends(get_db), user: dict = Depends(current_user)):
    """Serie real de ventas para gráficos internos, sin datos fiscales externos."""
    today = date.today()
    if periodo == "dia":
        start = today - timedelta(days=13)
        bucket, label = "day", "YYYY-MM-DD"
    elif periodo == "mes":
        start = today.replace(day=1) - timedelta(days=334)
        bucket, label = "month", "YYYY-MM"
    else:
        start = date(today.year - 4, 1, 1)
        bucket, label = "year", "YYYY"
    rows = db.execute(text("""SELECT to_char(date_trunc(CAST(:bucket AS text), fecha_venta), CAST(:label AS text)) etiqueta,
        COALESCE(SUM(total),0) total, COALESCE(SUM(monto_pagado),0) cobrado, COUNT(*) cantidad
        FROM ventas WHERE fecha_venta>=:start AND fecha_venta<:end + interval '1 day' AND estado<>'anulada'
        GROUP BY date_trunc(CAST(:bucket AS text), fecha_venta)
        ORDER BY date_trunc(CAST(:bucket AS text), fecha_venta)"""), {
            "bucket": bucket, "label": label, "start": start, "end": today,
        }).mappings().all()
    return {"periodo": periodo, "desde": start, "hasta": today, "serie": [dict(row) for row in rows]}


@router.get("/reportes/inventario")
def inventory_report(db:Session=Depends(get_db),user:dict=Depends(current_user)):
    rows=db.execute(text("SELECT categoria,COUNT(*) productos,COALESCE(SUM(stock_actual),0) unidades,COALESCE(SUM(stock_actual*precio_compra),0) valor_costo FROM productos WHERE activo=true GROUP BY categoria ORDER BY categoria")).mappings().all(); return {"inventario":[dict(x) for x in rows]}


@router.get("/reportes/compras")
def purchases_report(desde:date|None=None,hasta:date|None=None,db:Session=Depends(get_db),user:dict=Depends(current_user)):
    start=desde or date.today().replace(day=1); end=hasta or date.today(); rows=db.execute(text("SELECT estado,COUNT(*) cantidad,COALESCE(SUM(total),0) total FROM compras WHERE fecha_compra BETWEEN :start AND :end GROUP BY estado"),{"start":start,"end":end}).mappings().all(); return {"compras":[dict(x) for x in rows]}


@router.get("/reportes/citas")
def appointments_report(desde:date|None=None,hasta:date|None=None,db:Session=Depends(get_db),user:dict=Depends(current_user)):
    start=desde or date.today(); end=hasta or start; rows=db.execute(text("SELECT estado,COUNT(*) total FROM citas WHERE fecha_hora>=:start AND fecha_hora<:end+interval '1 day' GROUP BY estado"),{"start":start,"end":end}).mappings().all(); return {"citas":[dict(x) for x in rows]}

