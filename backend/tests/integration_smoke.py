"""Prueba de integración contra onlyeyes360_test con limpieza garantizada.

Ejecutar: .venv\\Scripts\\python tests\\integration_smoke.py
Nunca apunta a la base de producción: aborta antes de escribir si la conexión
efectiva no es exactly onlyeyes360_test.
"""
from __future__ import annotations

from pathlib import Path
import sys
from uuid import uuid4

# Permite ejecutar el archivo directamente desde backend/ o desde tests/.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi.testclient import TestClient
from sqlalchemy import text

from app.database import SessionLocal, engine
from app.main import app
from app.security import crear_hash, crear_token


MARK = f"INT-{uuid4().hex[:12]}"
db = SessionLocal()
ids: dict[str, int] = {}


def request(client: TestClient, method: str, path: str, **kwargs):
    response = client.request(method, path, **kwargs)
    assert response.status_code < 400, f"{method} {path}: {response.status_code} {response.text}"
    return response.json() if response.headers.get("content-type", "").startswith("application/json") else response.content


try:
    assert db.execute(text("select current_database()")).scalar_one() == "onlyeyes360_test"
    # Caja temporal: el humo integral no debe cerrar ni competir con la
    # gaveta principal que pueda estar utilizando la aplicación instalada.
    ids["box"] = db.execute(text("""INSERT INTO cajas_fisicas(id,nombre,activa)
      SELECT COALESCE(MAX(id),0)+1,:name,true FROM cajas_fisicas RETURNING id"""),
      {"name": f"Caja integración {MARK}"}).scalar_one()
    ids["user"] = db.execute(text("""INSERT INTO usuarios(nombre,usuario,password_hash,rol,activo)
      VALUES (:mark,:username,:password,'administrador',true) RETURNING id"""),
      {"mark": MARK, "username": MARK.lower(), "password": crear_hash("integration-only")}).scalar_one()
    ids["client"] = db.execute(text("INSERT INTO clientes(nombres,apellidos,telefono) VALUES (:name,'Prueba','8095550000') RETURNING id"), {"name": MARK}).scalar_one()
    ids["patient"] = db.execute(text("INSERT INTO pacientes(cliente_id) VALUES (:client) RETURNING id"), {"client": ids["client"]}).scalar_one()
    ids["supplier"] = db.execute(text("INSERT INTO proveedores(nombre,activo) VALUES (:name,true) RETURNING id"), {"name": MARK}).scalar_one()
    ids["product"] = db.execute(text("""INSERT INTO productos(codigo,nombre,categoria,precio_compra,precio_venta,stock_actual,stock_minimo,activo,itbis_tasa)
      VALUES (:code,:name,'otro',1,2,0,0,true,0) RETURNING id"""), {"code": MARK, "name": MARK}).scalar_one()
    db.commit()

    token = crear_token(ids["user"])
    headers = {"Authorization": f"Bearer {token}"}
    with TestClient(app) as client:
        managed = request(client, "POST", "/api/usuarios", headers=headers, json={
            "nombre": f"Cajera {MARK}", "usuario": f"cashier-{MARK.lower()}",
            "contrasena": "integration-only", "rol": "cajero",
        })
        ids["managed_user"] = managed["id"]
        assert managed["rol"] == "cajero"
        assert any(row["id"] == ids["managed_user"] for row in request(client, "GET", "/api/usuarios", headers=headers)["usuarios"])
        assert request(client, "PUT", f"/api/notificaciones/consentimientos/{ids['client']}", headers=headers, json={"whatsapp_habilitado": True})["whatsapp_habilitado"]
        purchase = request(client, "POST", "/api/compras", headers=headers, json={
            "proveedor_id": ids["supplier"], "numero_factura": MARK,
            "detalles": [{"producto_id": ids["product"], "cantidad": 5, "precio_unitario": "1.25"}],
        })
        ids["purchase"] = purchase["compra_id"]
        assert request(client, "POST", f"/api/compras/{ids['purchase']}/recibir", headers=headers)["estado"] == "recibida"
        payables = request(client, "GET", "/api/cuentas-por-pagar", headers=headers)["cuentas"]
        assert any(account["compra_id"] == ids["purchase"] for account in payables)
        assert request(client, "POST", f"/api/compras/{ids['purchase']}/pagos", headers=headers, json={"monto": "0.25", "metodo_pago": "transferencia"})["saldo"] == 6
        prescription = request(client, "POST", "/api/recetas", headers=headers, json={"paciente_id": ids["patient"], "profesional": "Prueba"})
        ids["prescription"] = prescription["receta_id"]
        appointment = request(client, "POST", "/api/citas", headers=headers, json={"paciente_id": ids["patient"], "fecha_hora": "2026-11-11T10:00:00", "motivo": "Prueba"})
        ids["appointment"] = appointment["cita_id"]
        appointment_new = request(client, "POST", "/api/citas/con-cliente", headers=headers, json={
            "cliente": {"nombres": f"Cita {MARK}", "telefono": "8095550011"},
            "fecha_hora": "2026-11-12T10:00:00", "motivo": "Primera consulta",
        })
        ids["appointment_new"] = appointment_new["cita_id"]
        ids["patient_new"] = appointment_new["paciente_id"]
        ids["client_new"] = appointment_new["cliente_id"]
        duplicate_appointment = client.post("/api/citas/con-cliente", headers=headers, json={
            "cliente": {"nombres": f"Cita {MARK}", "telefono": "8095550011"},
            "fecha_hora": "2026-11-13T10:00:00", "motivo": "No debe duplicarse",
        })
        assert duplicate_appointment.status_code == 409
        order = request(client, "POST", "/api/pedidos-lentes", headers=headers, json={"cliente_id": ids["client"], "receta_id": ids["prescription"]})
        ids["order"] = order["pedido_id"]
        assert order["codigo"] == f"OE-PED-{ids['order']:06d}"
        request(client, "PATCH", f"/api/pedidos-lentes/{ids['order']}/estado", headers=headers, json={"estado": "en_laboratorio", "observaciones": MARK})
        assert len(request(client, "GET", f"/api/taller/pedido/{ids['order']}/historial", headers=headers)["historial"]) == 2
        repair = request(client, "POST", "/api/reparaciones", headers=headers, json={"cliente_id": ids["client"], "tipo": "reparacion", "descripcion": "Prueba"})
        ids["repair"] = repair["reparacion_id"]
        assert repair["codigo"] == f"OE-REP-{ids['repair']:06d}"
        request(client, "PATCH", f"/api/reparaciones/{ids['repair']}/estado", headers=headers, json={"estado": "en_reparacion", "observaciones": MARK})
        assert len(request(client, "GET", f"/api/taller/reparacion/{ids['repair']}/historial", headers=headers)["historial"]) == 2
        request(client, "PATCH", f"/api/reparaciones/{ids['repair']}/estado", headers=headers, json={"estado": "listo", "observaciones": MARK})
        queued = request(client, "POST", "/api/notificaciones/procesar", headers=headers)
        assert queued["proveedor"] == "simulado" and len(queued["procesadas"]) == 1
        status = request(client, "POST", "/api/notificaciones/simular-mensaje", headers=headers, json={"texto": repair["codigo"]})
        assert "LISTO" in status["respuesta"]
        ids["shift"] = request(client, "POST", "/api/caja/aperturas", headers=headers, json={"fondo_inicial":"10", "caja_id": ids["box"]})["turno_id"]
        contextual_sale = request(client, "POST", "/api/ventas", headers=headers, json={
            "cliente_nuevo": {"nombres": f"POS {MARK}", "telefono": "8095550022"},
            "detalles": [{"producto_id": ids["product"], "cantidad": 1}],
        })
        ids["contextual_sale"] = contextual_sale["venta_id"]
        contextual_row = next(row for row in request(client, "GET", "/api/ventas", headers=headers)["ventas"] if row["id"] == ids["contextual_sale"])
        ids["contextual_client"] = contextual_row["cliente_id"]
        assert contextual_row["cliente_id"] and contextual_row["nombres"] == f"POS {MARK}"
        sale = request(client, "POST", "/api/ventas", headers=headers, json={"cliente_id": ids["client"], "detalles": [{"producto_id": ids["product"], "cantidad": 2}]})
        ids["sale"] = sale["venta_id"]
        assert request(client, "POST", f"/api/ventas/{ids['sale']}/pagos-mixtos", headers=headers, json={"pagos":[{"monto":"2.00","metodo_pago":"efectivo"},{"monto":"2.00","metodo_pago":"tarjeta"}]})["estado"] == "pagada"
        credit_sale = request(client, "POST", "/api/ventas", headers=headers, json={"cliente_id": ids["client"], "detalles": [{"producto_id": ids["product"], "cantidad": 1}]})
        ids["credit_sale"] = credit_sale["venta_id"]
        receivables = request(client, "GET", "/api/cuentas-por-cobrar", headers=headers)["cuentas"]
        assert any(account["venta_id"] == ids["credit_sale"] for account in receivables)
        request(client, "POST", f"/api/ventas/{ids['sale']}/factura-comercial", headers=headers)
        pdf = client.get(f"/api/ventas/{ids['sale']}/factura-comercial/pdf", headers=headers)
        assert pdf.status_code == 200 and pdf.content.startswith(b"%PDF")
        cash = request(client, "GET", "/api/caja/actual", headers=headers)
        assert cash["saldo_esperado"] == 12
        request(client, "POST", "/api/caja/movimientos", headers=headers, json={"tipo":"ingreso","monto":"2.50","concepto":MARK})
        assert request(client, "POST", "/api/caja/cierre", headers=headers, json={"monto_contado":"14.50"})["diferencia"] == 0
        for path in ("/api/compras", "/api/recetas", "/api/citas", "/api/pedidos-lentes", "/api/reparaciones", "/api/caja/actual", "/api/reportes/ventas", "/api/reportes/inventario", "/api/reportes/compras", "/api/reportes/citas"):
            request(client, "GET", path, headers=headers)
        for period in ("dia", "mes", "ano"):
            series = request(client, "GET", "/api/reportes/ventas-serie", headers=headers, params={"periodo": period})
            assert series["periodo"] == period and isinstance(series["serie"], list)
    print("INTEGRATION_SMOKE_OK")
finally:
    # Solo borra las filas enlazadas a identificadores creados por esta prueba.
    db.rollback()
    if ids:
        for statement, key in [
            ("DELETE FROM pagos_ventas WHERE venta_id=:id", "contextual_sale"),
            ("DELETE FROM detalle_ventas WHERE venta_id=:id", "contextual_sale"),
            ("DELETE FROM ventas WHERE id=:id", "contextual_sale"),
            ("DELETE FROM pagos_ventas WHERE venta_id=:id", "credit_sale"),
            ("DELETE FROM detalle_ventas WHERE venta_id=:id", "credit_sale"),
            ("DELETE FROM ventas WHERE id=:id", "credit_sale"),
            ("DELETE FROM facturas_comerciales WHERE venta_id=:id", "sale"),
            ("DELETE FROM pagos_ventas WHERE venta_id=:id", "sale"),
            ("DELETE FROM detalle_ventas WHERE venta_id=:id", "sale"),
            ("DELETE FROM ventas WHERE id=:id", "sale"),
            ("DELETE FROM movimientos_inventario WHERE producto_id=:id", "product"),
            ("DELETE FROM movimientos_caja_app WHERE turno_id=:id", "shift"),
            ("DELETE FROM turnos_caja WHERE id=:id", "shift"),
            ("DELETE FROM cajas_fisicas WHERE id=:id", "box"),
            ("DELETE FROM notificaciones_cliente WHERE cliente_id=:id", "client"),
            ("DELETE FROM consentimientos_notificacion WHERE cliente_id=:id", "client"),
            ("DELETE FROM historial_estados_taller WHERE tipo_trabajo='pedido' AND trabajo_id=:id", "order"),
            ("DELETE FROM historial_estados_taller WHERE tipo_trabajo='reparacion' AND trabajo_id=:id", "repair"),
            ("DELETE FROM pedidos_lentes WHERE id=:id", "order"),
            ("DELETE FROM reparaciones WHERE id=:id", "repair"),
            ("DELETE FROM citas WHERE id=:id", "appointment"),
            ("DELETE FROM citas WHERE id=:id", "appointment_new"),
            ("DELETE FROM recetas WHERE id=:id", "prescription"),
            ("DELETE FROM detalle_compras WHERE compra_id=:id", "purchase"),
            ("DELETE FROM pagos_compras WHERE compra_id=:id", "purchase"),
            ("DELETE FROM compras WHERE id=:id", "purchase"),
            ("DELETE FROM productos WHERE id=:id", "product"),
            ("DELETE FROM proveedores WHERE id=:id", "supplier"),
            ("DELETE FROM pacientes WHERE id=:id", "patient"),
            ("DELETE FROM pacientes WHERE id=:id", "patient_new"),
            ("DELETE FROM clientes WHERE id=:id", "client"),
            ("DELETE FROM clientes WHERE id=:id", "client_new"),
            ("DELETE FROM clientes WHERE id=:id", "contextual_client"),
            ("DELETE FROM usuarios WHERE id=:id", "user"),
            ("DELETE FROM usuarios WHERE id=:id", "managed_user"),
        ]:
            if key in ids:
                db.execute(text(statement), {"id": ids[key]})
        db.commit()
    db.close()
