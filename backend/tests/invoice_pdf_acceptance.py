"""Aceptación del comprobante comercial; escribe únicamente en onlyeyes360_test."""
from __future__ import annotations

from pathlib import Path
import sys
from uuid import uuid4

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from fastapi.testclient import TestClient
from sqlalchemy import text
from app.database import SessionLocal
from app.main import app
from app.security import crear_hash, crear_token

MARK = f"PDF-{uuid4().hex[:10]}"
db = SessionLocal()
ids: dict[str, int] = {}


def request(client: TestClient, method: str, path: str, headers: dict, **kwargs):
    response = client.request(method, path, headers=headers, **kwargs)
    assert response.status_code < 400, f"{method} {path}: {response.status_code} {response.text}"
    return response


try:
    assert db.execute(text("SELECT current_database()")).scalar_one() == "onlyeyes360_test"
    previous_business = db.execute(text("SELECT * FROM datos_negocio WHERE id=1")).mappings().first()
    ids["user"] = db.execute(text("""INSERT INTO usuarios(nombre,usuario,password_hash,rol,activo)
        VALUES (:n,:u,:p,'administrador',true) RETURNING id"""),
        {"n": MARK, "u": MARK.lower(), "p": crear_hash("invoice-test")}).scalar_one()
    # Múltiples productos, incluida descripción larga que debe partirse en el PDF.
    for index, (price, name) in enumerate([
        (300, "Montura de prueba con descripción extensa para comprobar ajuste de texto en A4 y ticket térmico"),
        (300, "Lente antirreflejo ficticio"),
        (400, "Servicio de ajuste"),
    ]):
        ids[f"product{index}"] = db.execute(text("""INSERT INTO productos
            (codigo,nombre,categoria,precio_compra,precio_venta,stock_actual,stock_minimo,activo,itbis_tasa)
            VALUES (:c,:n,'otro',1,:price,10,0,true,0) RETURNING id"""),
            {"c": f"{MARK}-{index}", "n": name, "price": price}).scalar_one()
    db.commit()
    ids["box"] = db.execute(text("""INSERT INTO cajas_fisicas(id,nombre,activa)
        SELECT COALESCE(MAX(id),0)+1,:n,true FROM cajas_fisicas RETURNING id"""),
        {"n": f"Caja PDF {MARK}"}).scalar_one()
    ids["shift"] = db.execute(text("""INSERT INTO turnos_caja
        (usuario_id,caja_id,fondo_inicial,monto_esperado,estado) VALUES (:user,:box,0,0,'abierta') RETURNING id"""),
        {"user": ids["user"], "box": ids["box"]}).scalar_one()
    db.commit()
    headers = {"Authorization": f"Bearer {crear_token(ids['user'])}"}
    with TestClient(app) as client:
        request(client, "POST", "/api/datos-negocio", headers, json={
            "nombre_comercial": "Óptica de Prueba ONLY EYES", "eslogan": "Visión ficticia",
            "rnc": "101-00000-1", "direccion": "Av. Prueba 360, Santo Domingo",
            "telefono": "809-555-0360",
        })
        sale = request(client, "POST", "/api/ventas", headers, json={"detalles": [
            {"producto_id": ids["product0"], "cantidad": 1},
            {"producto_id": ids["product1"], "cantidad": 1},
            {"producto_id": ids["product2"], "cantidad": 1},
        ]}).json()
        ids["sale"] = sale["venta_id"]
        # Cobro confirmado como lo envía POS: recibido, aplicado y cambio se guardan juntos.
        paid = request(client, "POST", f"/api/ventas/{ids['sale']}/pagos", headers,
            json={"monto": "1000", "metodo_pago": "efectivo", "monto_recibido": "5200", "cambio": "4200"}).json()
        assert paid["estado"] == "pagada" and paid["monto_pagado"] == 1000
        cash = request(client, "GET", "/api/caja/actual", headers).json()
        assert cash["saldo_esperado"] == 1000 and cash["resumen"]["ventas_efectivo"] == 1000
        request(client, "POST", f"/api/ventas/{ids['sale']}/factura-comercial", headers)
        a4 = request(client, "GET", f"/api/ventas/{ids['sale']}/factura-comercial/pdf?formato=a4", headers)
        ticket = request(client, "GET", f"/api/ventas/{ids['sale']}/factura-comercial/pdf?formato=termica", headers)
        assert a4.content.startswith(b"%PDF") and ticket.content.startswith(b"%PDF")
        assert len(a4.content) > 1500 and len(ticket.content) > 1500
        output_dir = Path(__file__).resolve().parents[2].joinpath("output", "pdf")
        output_dir.mkdir(parents=True, exist_ok=True)
        a4_path = output_dir / "COMPROBANTE_EJEMPLO_A4.pdf"
        a4_path.write_bytes(a4.content)
        # La reimpresión usa los mismos pagos persistidos incluso después de releer la venta.
        reprint = request(client, "GET", f"/api/ventas/{ids['sale']}/factura-comercial/pdf?formato=a4", headers)
        assert reprint.content.startswith(b"%PDF") and len(reprint.content) > 1500
        (output_dir / "COMPROBANTE_EJEMPLO_REIMPRESION_A4.pdf").write_bytes(reprint.content)
        # Pago mixto: sólo la parte neta de efectivo entra a Caja (800 - 200 = 600).
        mixed = request(client, "POST", "/api/ventas", headers, json={"detalles": [
            {"producto_id": ids["product0"], "cantidad": 1},
            {"producto_id": ids["product1"], "cantidad": 1},
            {"producto_id": ids["product2"], "cantidad": 1},
        ]}).json()
        ids["mixed_sale"] = mixed["venta_id"]
        request(client, "POST", f"/api/ventas/{ids['mixed_sale']}/pagos-mixtos", headers, json={"pagos": [
            {"monto": "600", "metodo_pago": "efectivo", "monto_recibido": "800", "cambio": "200"},
            {"monto": "400", "metodo_pago": "tarjeta"},
        ]})
        assert request(client, "GET", "/api/caja/actual", headers).json()["saldo_esperado"] == 1600
finally:
    db.rollback()
    if "sale" in ids:
        db.execute(text("DELETE FROM facturas_comerciales WHERE venta_id=:id"), {"id": ids["sale"]})
        db.execute(text("DELETE FROM pagos_ventas WHERE venta_id=:id"), {"id": ids["sale"]})
        db.execute(text("DELETE FROM detalle_ventas WHERE venta_id=:id"), {"id": ids["sale"]})
        db.execute(text("DELETE FROM ventas WHERE id=:id"), {"id": ids["sale"]})
    if "mixed_sale" in ids:
        db.execute(text("DELETE FROM pagos_ventas WHERE venta_id=:id"), {"id": ids["mixed_sale"]})
        db.execute(text("DELETE FROM detalle_ventas WHERE venta_id=:id"), {"id": ids["mixed_sale"]})
        db.execute(text("DELETE FROM ventas WHERE id=:id"), {"id": ids["mixed_sale"]})
    for index in range(3):
        if f"product{index}" in ids:
            db.execute(text("DELETE FROM movimientos_inventario WHERE producto_id=:id"), {"id": ids[f"product{index}"]})
            db.execute(text("DELETE FROM productos WHERE id=:id"), {"id": ids[f"product{index}"]})
    if "user" in ids:
        db.execute(text("DELETE FROM movimientos_caja_app WHERE usuario_id=:id"), {"id": ids["user"]})
        db.execute(text("DELETE FROM turnos_caja WHERE usuario_id=:id"), {"id": ids["user"]})
        db.execute(text("DELETE FROM usuarios WHERE id=:id"), {"id": ids["user"]})
    if "box" in ids:
        db.execute(text("DELETE FROM cajas_fisicas WHERE id=:id"), {"id": ids["box"]})
    if 'previous_business' in locals() and previous_business:
        db.execute(text("""UPDATE datos_negocio SET nombre_comercial=:nombre_comercial,eslogan=:eslogan,
            rnc=:rnc,direccion=:direccion,telefono=:telefono WHERE id=1"""), dict(previous_business))
    db.commit()
    db.close()

print("INVOICE_PDF_ACCEPTANCE_OK")
