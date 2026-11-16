# Cambios recientes

## Inicio de sesión iPhone con base cloud vacía - 16-11-2026

- FastAPI puede crear una única cuenta administradora inicial si y sólo si la
  tabla `usuarios` no contiene registros y el proveedor seguro configura
  `BOOTSTRAP_ADMIN_USERNAME` y `BOOTSTRAP_ADMIN_PASSWORD`.
- La contraseña se hashea con Argon2, nunca se escribe en registros ni se
  incorpora al repositorio. Las variables de bootstrap son temporales y deben
  borrarse en Render tras comprobar el primer inicio de sesión.

## Historial de ventas POS - 15-11-2026

- Versión **0.5.12**: se incorporó el botón visible **Historial** en el POS.
  Permite abrir comprobantes ya confirmados sin crear ventas, cobros,
  movimientos de Caja ni salidas de inventario adicionales. Desde el
  comprobante histórico están disponibles los formatos A4 y térmico con la
  fecha, numeración e importes registrados originalmente.
- La instalación 0.5.12 se comprobó contra `onlyeyes360_test`; el ejecutable
  instalado y los recursos de Flutter coinciden por hash con el Release que
  contiene este cambio.

## Comprobante comercial PDF y ticket - 14-11-2026

- PDF A4 y ticket térmico 80 mm usan el mismo origen de venta, pagos y perfil
  comercial. Incluyen logo, contacto configurado, leyenda no fiscal, artículos,
  impuestos, totales, pagos, abonos y saldo.
- Se persisten el efectivo recibido y el cambio por pago. La vista previa,
  el PDF y el ticket muestran el mismo cambio; se verificó el caso ficticio
  RD$5,000.00 recibido / RD$445.00 aplicado / RD$4,555.00 de cambio.
- **Imprimir Ticket** abre directamente el comprobante en formato térmico en
  el visor de Windows. La selección física de la impresora sigue siendo del
  operador; no se enviaron impresiones reales durante esta prueba.
- Datos del negocio ahora se sincronizan de Administración a FastAPI para que
  los comprobantes no dependan sólo de configuración local. Históricos sin
  cambio persistido omiten esa línea al reimprimirse.
- El A4 dejó de usar una tabla ancha: ahora centra un comprobante con la misma
  secuencia de encabezado, separadores, bloques de producto, total y pie que
  la tarjeta **Comprobante de Venta** del POS. La prueba vigente usa
  RD$5,200.00 recibidos, RD$1,000.00 aplicados y RD$4,200.00 de cambio.
- Se eliminó el respaldo engañoso de pagos: si Flutter no envía `monto_recibido`
  y `cambio`, FastAPI guarda valores nulos en lugar de copiar el monto aplicado.
  Así las reimpresiones históricas no convierten RD$1,000.00 aplicados en un
  supuesto efectivo recibido de RD$1,000.00.
- Corrección 0.5.8: el flujo de pago único en efectivo ya no descarta
  `monto_recibido` ni `cambio` al llamar a FastAPI. Antes ese error afectaba la
  venta normal y sólo el pago mixto conservaba esos campos.
- Versión 0.5.9: el campo de cobro del POS ahora se llama **Efectivo recibido**
  para que la cajera indique el dinero entregado por el cliente y el sistema
  pueda mostrar el cambio en el comprobante.
- Versión 0.5.10: el resumen de la ventana **Factura PDF** muestra también el
  efectivo recibido, el efectivo aplicado y la devuelta que ya figuraban en la
  vista previa y en el documento PDF. Los comprobantes históricos sin importe
  recibido siguen omitiendo esa línea.
- Versión 0.5.11: **Imprimir Ticket** guarda y abre directamente el PDF de
  80 mm desde el comprobante del POS, evitando el diálogo automático que podía
  cerrarse sin dejar el archivo térmico disponible.

## Caja diaria y cuadre - 13-11-2026

- El cobro en efectivo exige un turno de caja abierto y devuelve el mensaje
  **“Abre tu caja para cobrar en efectivo”** si no existe.
- El movimiento de efectivo de una venta se inserta dentro de la misma
  transacción que el pago. Los pagos con tarjeta y transferencia no aumentan
  la gaveta.
- Se añadió idempotencia al cobro iniciado desde POS y un historial de turnos
  para administradores (`GET /api/caja/historial`).
- El cuadre guarda esperado, contado, diferencia y observación; el conteo no
  se rellena automáticamente para que sea un arqueo físico real.

## Flujo de apertura de caja - 14-11-2026

- Se corrigió la pantalla para diferenciar **Caja cerrada**, **Abrir caja** y
  **Continuar turno**. Un turno persistente se recupera tras cerrar o reiniciar
  la aplicación, y un error de consulta muestra una acción de reintento.
- La apertura acepta fondo inicial RD$0.00, sólo se registra tras confirmar y
  usa idempotencia más bloqueo transaccional por usuario para evitar aperturas
  duplicadas por doble clic o reintento.
- El POS detecta el rechazo de efectivo con caja cerrada, conserva el carrito
  y ofrece llevar a la pantalla **Abrir caja**.
- Se cerró en `onlyeyes360_test` el turno ficticio abandonado #26 del usuario
  de prueba con su efectivo esperado; se preservó en el historial con
  diferencia RD$0.00. No se modificó producción.

## Caja física y trazabilidad de cobros - 14-11-2026

- Se aplicó exclusivamente a `onlyeyes360_test` la migración
  `20261114_caja_fisica_pagos_turno.sql`: añade Caja principal, exclusión de
  turno abierto por caja física y campos opcionales de turno/cajero para pagos.
  Los pagos históricos siguen intactos y sin turno cuando corresponde.
- Todo pago nuevo, incluso tarjeta, transferencia, avance o abono posterior,
  exige turno abierto y queda asociado al turno que lo recibió. El cierre toma
  bloqueo del turno; un cobro concurrente se incluye o se rechaza si ya cerró.
- El cuadre requiere observación si no coincide, presenta los cobros por método
  y permite emitir un comprobante PDF interno del cierre. Administración ve el
  historial; caja sólo ve su propio turno.

## Instalación local Windows - 13-11-2026

- La configuración de base de datos del paquete se lee desde `ProgramData`,
  fuera del instalador y de `Program Files`; los logs también son locales y no
  escriben credenciales.
- El login reintenta el backend local y comunica estados de arranque claros.
- Se incorporó el manual `docs/PRIMERA_INSTALACION_WINDOWS.md` con límites de
  validación de PC limpia, PostgreSQL e impresión física.

## Paquete Windows 0.5.1 - 13-11-2026

- Se regeneró el Release de Flutter, el ejecutable autocontenido de FastAPI y
  el instalador Inno Setup. El backend del paquete toma su configuración de
  `ProgramData`, nunca del instalador ni de `Program Files`.
- `/health` ahora confirma una consulta real a PostgreSQL y reporta si la base
  aún no está disponible; el login presenta estados de arranque y reintenta.
- El lanzador instalado conserva tres reintentos y un registro local sin
  credenciales. El instalador crea la tarea de inicio `ONLY EYES 360 Backend`.
- La prueba de integración se hizo exclusivamente contra `onlyeyes360_test`.
  La validación de una PC/VM limpia, aprovisionamiento de PostgreSQL y una
  impresora física sigue pendiente antes de venta comercial.

## Caja física aislada - 15-11-2026

- La apertura acepta `caja_id` para una caja física activa. La interfaz sigue
  abriendo Caja principal; sólo administración puede elegir otra caja. Se
  preservan los bloqueos de concurrencia por usuario y gaveta.
- Las pruebas de aceptación e integración usan una caja temporal y la limpian,
  por lo que ya no dependen del estado de la Caja principal en
  `onlyeyes360_test`.

## 0.5.14 - Historial de ventas localizable

- Se añadió un buscador al historial del POS. Acepta el número de venta o de
  comprobante y abre el mismo comprobante histórico para descargar el PDF A4
  o reimprimir el ticket, sin crear una operación comercial nueva.

## 0.5.16 - Inicio local obligatorio

- El acceso directo de Escritorio y el arranque automático del backend pasan a
  ser componentes obligatorios del instalador. Corrige instalaciones donde la
  tarea local podía omitirse por ser una casilla opcional.
- La tarea se registra desde un script de instalación con las rutas protegidas
  y se añade un inicio de respaldo al iniciar sesión de Windows.
# Cambios recientes

## 16-11-2026 — Base iPhone y compilación de IPA

- Generado el destino iOS del cliente Flutter con identificador
  `com.onlyeyes360.mobile` y permiso limitado para red local.
- Añadida navegación móvil: menú lateral para todos los módulos y accesos
  inferiores a Inicio, Pacientes, Inventario y POS.
- Añadida inicialización segura y opcional del proyecto Supabase móvil mediante
  variables públicas de compilación; no se exponen tablas comerciales ni se
  suben contraseñas o claves de servicio.
- Añadido el flujo de GitHub Actions para construir una IPA sin firmar y
  descargarla como artefacto para su firma posterior por el propietario.
- Generado el SQL completo de las 41 tablas desde `onlyeyes360_test`, sin
  registros ni secretos, y con RLS activado para impedir acceso público directo
  a ventas, Caja, pacientes e inventario.
- Añadida definición `render.yaml` para publicar FastAPI como servicio HTTPS
  con las variables privadas `DATABASE_URL` y `JWT_SECRET_KEY` fuera del
  repositorio.

