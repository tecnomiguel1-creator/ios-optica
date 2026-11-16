"""Jornada ficticia de caja; aborta si la conexión no es onlyeyes360_test."""
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

mark = f"CAJA-{uuid4().hex[:10]}"
db = SessionLocal(); ids: dict[str, int] = {}

def api(client, method, path, headers, **kwargs):
    response = client.request(method, path, headers=headers, **kwargs)
    assert response.status_code < 400, f"{method} {path}: {response.status_code} {response.text}"
    return response.json()

try:
    assert db.execute(text("select current_database()")).scalar_one() == "onlyeyes360_test"
    # La prueba usa una gaveta temporal para no interferir con un turno abierto
    # que la persona esté usando en la caja principal de onlyeyes360_test.
    ids["box"] = db.execute(text("""INSERT INTO cajas_fisicas(id,nombre,activa)
        SELECT COALESCE(MAX(id),0)+1,:name,true FROM cajas_fisicas RETURNING id"""), {"name": f"Caja aceptación {mark}"}).scalar_one()
    ids["user"] = db.execute(text("INSERT INTO usuarios(nombre,usuario,password_hash,rol,activo) VALUES (:n,:u,:p,'administrador',true) RETURNING id"), {"n": mark, "u": mark.lower(), "p": crear_hash("cash-test")}).scalar_one()
    ids["second_user"] = db.execute(text("INSERT INTO usuarios(nombre,usuario,password_hash,rol,activo) VALUES (:n,:u,:p,'administrador',true) RETURNING id"), {"n": f"{mark}-2", "u": f"{mark.lower()}-2", "p": crear_hash("cash-test")}).scalar_one()
    ids["cashier"] = db.execute(text("INSERT INTO usuarios(nombre,usuario,password_hash,rol,activo) VALUES (:n,:u,:p,'cajero',true) RETURNING id"), {"n": f"{mark}-cashier", "u": f"{mark.lower()}-cashier", "p": crear_hash("cash-test")}).scalar_one()
    ids["product"] = db.execute(text("""INSERT INTO productos(codigo,nombre,categoria,precio_compra,precio_venta,stock_actual,stock_minimo,activo,itbis_tasa)
        VALUES (:c,:n,'otro',500,1000,10,0,true,0) RETURNING id"""), {"c": mark, "n": mark}).scalar_one(); db.commit()
    ids["day_product"] = db.execute(text("""INSERT INTO productos(codigo,nombre,categoria,precio_compra,precio_venta,stock_actual,stock_minimo,activo,itbis_tasa)
        VALUES (:c,:n,'otro',4000,7500,5,0,true,0) RETURNING id"""), {"c": f"{mark}-DAY", "n": f"{mark}-DAY"}).scalar_one(); db.commit()
    headers = {"Authorization": f"Bearer {crear_token(ids['user'])}"}
    second_headers = {"Authorization": f"Bearer {crear_token(ids['second_user'])}"}
    cashier_headers = {"Authorization": f"Bearer {crear_token(ids['cashier'])}"}
    cash_open = {"caja_id": ids["box"]}
    with TestClient(app) as client:
        forbidden_box = client.post("/api/caja/aperturas", headers=cashier_headers, json={**cash_open,"fondo_inicial":"0"})
        assert forbidden_box.status_code == 403 and "administración" in forbidden_box.text
        # Efectivo con caja cerrada debe ser rechazado.
        first = api(client, "POST", "/api/ventas", headers, json={"detalles":[{"producto_id":ids["product"],"cantidad":1}]})
        ids["first_sale"] = first["venta_id"]
        closed = client.post(f"/api/ventas/{first['venta_id']}/pagos", headers=headers, json={"monto":"1000","metodo_pago":"efectivo"})
        assert closed.status_code == 409 and "Abre la caja para continuar" in closed.text
        closed_card = client.post(f"/api/ventas/{first['venta_id']}/pagos", headers=headers, json={"monto":"1000","metodo_pago":"tarjeta"})
        assert closed_card.status_code == 409 and "Abre la caja para continuar" in closed_card.text
        opening_key = "cash-open-acceptance-key"
        opening = api(client, "POST", "/api/caja/aperturas", {**headers,"Idempotency-Key":opening_key}, json={**cash_open,"fondo_inicial":"2000"})
        ids["shift"] = opening["turno_id"]
        # La misma solicitud tras un fallo de red recupera el turno original,
        # nunca crea una segunda apertura.
        assert api(client, "POST", "/api/caja/aperturas", {**headers,"Idempotency-Key":opening_key}, json={**cash_open,"fondo_inicial":"2000"}) == opening
        physical_duplicate = client.post("/api/caja/aperturas", headers=second_headers, json={**cash_open,"fondo_inicial":"1"})
        assert physical_duplicate.status_code == 409 and "caja física" in physical_duplicate.text
        duplicate = client.post("/api/caja/aperturas", headers=headers, json={**cash_open,"fondo_inicial":"1"})
        assert duplicate.status_code == 409
        sale = api(client, "POST", "/api/ventas", headers, json={"detalles":[{"producto_id":ids["product"],"cantidad":1}]})
        ids["sale"] = sale["venta_id"]
        key = "cash-acceptance-key"
        payment = api(client, "POST", f"/api/ventas/{ids['sale']}/pagos-mixtos", {**headers,"Idempotency-Key":key}, json={"pagos":[{"monto":"600","metodo_pago":"efectivo"},{"monto":"400","metodo_pago":"tarjeta"}]})
        assert payment["estado"] == "pagada"
        retry = api(client, "POST", f"/api/ventas/{ids['sale']}/pagos-mixtos", {**headers,"Idempotency-Key":key}, json={"pagos":[{"monto":"600","metodo_pago":"efectivo"},{"monto":"400","metodo_pago":"tarjeta"}]})
        assert retry == payment
        current = api(client, "GET", "/api/caja/actual", headers)
        assert current["saldo_esperado"] == 2600 and current["resumen"]["ventas_efectivo"] == 600
        api(client, "POST", "/api/caja/movimientos", headers, json={"tipo":"egreso","monto":"100","concepto":"Cambio ficticio"})
        assert api(client, "GET", "/api/caja/actual", headers)["saldo_esperado"] == 2500
        close = api(client, "POST", "/api/caja/cierre", headers, json={"monto_contado":"2450","observaciones":"Faltante ficticio"})
        assert close["diferencia"] == -50
        assert api(client, "GET", "/api/caja/actual", headers)["turno"] is None
        second_close = client.post("/api/caja/cierre", headers=headers, json={"monto_contado":"2450"})
        assert second_close.status_code == 409
        ids["exact_shift"] = api(client, "POST", "/api/caja/aperturas", headers, json={**cash_open,"fondo_inicial":"100"})["turno_id"]
        assert api(client, "POST", "/api/caja/cierre", headers, json={"monto_contado":"100"})["diferencia"] == 0
        ids["surplus_shift"] = api(client, "POST", "/api/caja/aperturas", headers, json={**cash_open,"fondo_inicial":"100"})["turno_id"]
        assert api(client, "POST", "/api/caja/cierre", headers, json={"monto_contado":"110","observaciones":"Sobrante ficticio"})["diferencia"] == 10
        # Jornada solicitada: 2,000 + 4,500 efectivo - 500 gasto = 6,000.
        ids["day_shift"] = api(client, "POST", "/api/caja/aperturas", headers, json={**cash_open,"fondo_inicial":"2000"})["turno_id"]
        day_sale = api(client, "POST", "/api/ventas", headers, json={"detalles":[{"producto_id":ids["day_product"],"cantidad":1}]})
        ids["day_sale"] = day_sale["venta_id"]
        api(client, "POST", f"/api/ventas/{ids['day_sale']}/pagos-mixtos", {**headers,"Idempotency-Key":"day-mixed"}, json={"pagos":[{"monto":"4500","metodo_pago":"efectivo"},{"monto":"2000","metodo_pago":"tarjeta"},{"monto":"1000","metodo_pago":"transferencia"}]})
        api(client, "POST", "/api/caja/movimientos", headers, json={"tipo":"egreso","monto":"500","concepto":"Gasto ficticio"})
        day_current = api(client, "GET", "/api/caja/actual", headers)
        assert day_current["saldo_esperado"] == 6000
        totals = {item["metodo_pago"]: item["total"] for item in day_current["resumen"]["pagos_no_efectivo"]}
        assert totals["tarjeta"] == 2000 and totals["transferencia"] == 1000
        missing_note = client.post("/api/caja/cierre", headers=headers, json={"monto_contado":"5800"})
        assert missing_note.status_code == 422 and "observación" in missing_note.text
        day_close = api(client, "POST", "/api/caja/cierre", headers, json={"monto_contado":"5800","observaciones":"Faltante físico ficticio"})
        assert day_close["diferencia"] == -200 and day_close["estado_cuadre"] == "faltante"
        # Avance y abono posterior: cada pago queda asociado a un turno distinto.
        ids["advance_shift"] = api(client, "POST", "/api/caja/aperturas", headers, json={**cash_open,"fondo_inicial":"0"})["turno_id"]
        advance_sale = api(client, "POST", "/api/ventas", headers, json={"detalles":[{"producto_id":ids["product"],"cantidad":1}]})
        ids["advance_sale"] = advance_sale["venta_id"]
        api(client, "POST", f"/api/ventas/{ids['advance_sale']}/pagos", headers, json={"monto":"200","metodo_pago":"efectivo"})
        api(client, "POST", "/api/caja/cierre", headers, json={"monto_contado":"200"})
        ids["settlement_shift"] = api(client, "POST", "/api/caja/aperturas", headers, json={**cash_open,"fondo_inicial":"0"})["turno_id"]
        api(client, "POST", f"/api/ventas/{ids['advance_sale']}/pagos", headers, json={"monto":"800","metodo_pago":"tarjeta"})
        payment_turns = [r[0] for r in db.execute(text("SELECT turno_caja_id FROM pagos_ventas WHERE venta_id=:sale ORDER BY id"), {"sale":ids["advance_sale"]}).all()]
        assert payment_turns == [ids["advance_shift"], ids["settlement_shift"]]
        api(client, "POST", "/api/caja/cierre", headers, json={"monto_contado":"0"})
        # Una venta sin abono permanece en cuentas por cobrar.
        credit_sale = api(client, "POST", "/api/ventas", headers, json={"detalles":[{"producto_id":ids["product"],"cantidad":1}]})
        ids["credit_sale"] = credit_sale["venta_id"]
        accounts = api(client, "GET", "/api/cuentas-por-cobrar", headers)["cuentas"]
        assert any(row["venta_id"] == ids["credit_sale"] and row["saldo"] == 1000 for row in accounts)
        assert client.get("/api/caja/historial", headers=headers).status_code == 200
        assert client.get("/api/caja/historial", headers=cashier_headers).status_code == 403
finally:
    db.rollback()
    for sql, key in [("DELETE FROM claves_idempotencia WHERE usuario_id=:id", "user"),("DELETE FROM claves_idempotencia WHERE usuario_id=:id", "second_user"),("DELETE FROM claves_idempotencia WHERE usuario_id=:id", "cashier"),("DELETE FROM pagos_ventas WHERE venta_id=:id", "sale"),("DELETE FROM pagos_ventas WHERE venta_id=:id", "day_sale"),("DELETE FROM pagos_ventas WHERE venta_id=:id", "advance_sale"),("DELETE FROM detalle_ventas WHERE venta_id=:id", "sale"),("DELETE FROM detalle_ventas WHERE venta_id=:id", "day_sale"),("DELETE FROM detalle_ventas WHERE venta_id=:id", "advance_sale"),("DELETE FROM detalle_ventas WHERE venta_id=:id", "credit_sale"),("DELETE FROM ventas WHERE id=:id", "sale"),("DELETE FROM ventas WHERE id=:id", "day_sale"),("DELETE FROM ventas WHERE id=:id", "advance_sale"),("DELETE FROM ventas WHERE id=:id", "credit_sale"),("DELETE FROM movimientos_caja_app WHERE turno_id=:id", "shift"),("DELETE FROM movimientos_caja_app WHERE turno_id=:id", "day_shift"),("DELETE FROM movimientos_caja_app WHERE turno_id=:id", "advance_shift"),("DELETE FROM movimientos_caja_app WHERE turno_id=:id", "settlement_shift"),("DELETE FROM turnos_caja WHERE id=:id", "shift"),("DELETE FROM turnos_caja WHERE id=:id", "exact_shift"),("DELETE FROM turnos_caja WHERE id=:id", "surplus_shift"),("DELETE FROM turnos_caja WHERE id=:id", "day_shift"),("DELETE FROM turnos_caja WHERE id=:id", "advance_shift"),("DELETE FROM turnos_caja WHERE id=:id", "settlement_shift"),("DELETE FROM detalle_ventas WHERE venta_id=:id", "first_sale"),("DELETE FROM ventas WHERE id=:id", "first_sale"),("DELETE FROM movimientos_inventario WHERE producto_id=:id", "product"),("DELETE FROM movimientos_inventario WHERE producto_id=:id", "day_product"),("DELETE FROM productos WHERE id=:id", "product"),("DELETE FROM productos WHERE id=:id", "day_product"),("DELETE FROM usuarios WHERE id=:id", "cashier"),("DELETE FROM usuarios WHERE id=:id", "second_user"),("DELETE FROM usuarios WHERE id=:id", "user"),("DELETE FROM cajas_fisicas WHERE id=:id", "box")]:
        if key in ids: db.execute(text(sql), {"id":ids[key]})
    db.commit(); db.close()

print("CASH_REGISTER_ACCEPTANCE_OK")
