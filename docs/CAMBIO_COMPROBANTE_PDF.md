# Cambio: comprobante comercial PDF y ticket

Fecha: 14-11-2026. Alcance: solamente `onlyeyes360_test` durante pruebas.

## Qué cambió

- `backend/app/commerce.py`: generador único con ReportLab para A4 y 80 mm,
  consulta pagos persistidos, cambio y datos comerciales.
- `backend/migrations/20261114_datos_negocio_comprobante.sql`: perfil de
  negocio usado al imprimir.
- `backend/migrations/20261114_cambio_comprobante.sql`: columnas opcionales
  de efectivo recibido y cambio; los pagos anteriores conservan sus valores.
- Flutter: el botón **Imprimir Ticket** genera el PDF térmico real, y la vista
  previa reutiliza el cambio persistido al volver a abrir una venta.

## Cómo probar

1. En **Administración > Datos del negocio**, guardar nombre, dirección y
   teléfono.
2. Abrir caja y realizar una venta ficticia en efectivo, registrando lo
   recibido y el cambio; o usar un pago mixto/avance según corresponda.
3. En el comprobante seleccionar **Factura PDF** y abrir A4. Verificar que el
   total, pagos y cambio coincidan con la vista previa.
4. Seleccionar **Imprimir Ticket**. Se abre el mismo comprobante en 80 mm para
   que Windows permita elegir una impresora térmica.
5. Ejecutar `backend/tests/invoice_pdf_acceptance.py` para la prueba aislada.

## Resultado de la prueba automática

- A4: una página con recibo centrado y la misma distribución de bloques del
  comprobante POS; no usa una tabla cuadriculada ancha.
- Térmico: una página de rollo continuo, tres renglones incluida descripción
  larga, total, RD$5,200.00 recibido, RD$1,000.00 aplicado y RD$4,200.00 de
  cambio visibles.
- Caja: el cobro en efectivo aportó exactamente RD$1,000.00 al turno. Un pago
  mixto de RD$800.00 recibido / RD$600.00 aplicado en efectivo y RD$400.00 en
  tarjeta dejó sólo RD$600.00 en la gaveta.
- No hubo impresora física disponible, por lo que la salida en papel queda
  pendiente; los dos PDFs se renderizaron y se revisaron visualmente.

## Límite histórico

Si un pago anterior a la migración no tiene `cambio` guardado, el comprobante
omite sólo esa línea. No se calcula un cambio retrospectivo para no inventar
un dato financiero.

Los clientes anteriores que no enviaban efectivo recibido se distinguen de los
nuevos: FastAPI conserva `monto_recibido` y `cambio` como nulos. El PDF deja
visible el monto aplicado, bajo la etiqueta **Efectivo aplicado a la venta**,
pero omite los dos datos desconocidos.
