# ONLY EYES 360 — desarrollo aislado

## iPhone y sincronización (16-11-2026)

- Se añadió el destino iOS al mismo cliente Flutter que usa Windows. En
  teléfonos, la navegación se organiza mediante un menú lateral desplegable y
  una barra inferior; se preservan los módulos y el diseño comercial.
- Se preparó la inicialización opcional de Supabase con configuración pública
  por compilación. Los cobros, la Caja y el inventario continúan validándose en
  FastAPI para que PC y teléfono compartan una única fuente de verdad.
- El flujo de GitHub Actions `.github/workflows/ios-unsigned-ipa.yml` compila
  una IPA sin firmar en macOS. Los certificados Apple, las contraseñas y las
  claves de servicio no se incluyen en el repositorio ni en el artefacto.
- La guía de despliegue y las condiciones de sincronización están en
  `docs/IOS_MOVIL_SUPABASE.md`.
- El SQL completo y seguro para crear el esquema remoto sin datos está en
  `supabase/migrations/001_onlyeyes360_test_schema.sql`.
- El archivo `render.yaml` y `docs/PUBLICAR_FASTAPI_RENDER.md` preparan FastAPI
  para una URL HTTPS compartida por el móvil y Windows, sin guardar la
  contraseña de Supabase en Git.

Esta copia es el entorno de recuperación y desarrollo. Su conexión fue
verificada contra `onlyeyes360_test`; no debe apuntarse a `onlyeyes360`.

## Recuperación realizada

- El cliente Flutter avanzado se integró en `flutter_app/`. El origen recuperado
  permanece intacto y el cliente mínimo anterior quedó resguardado en `work/`.
- La API comercial incorpora productos, proveedores, kardex, ventas, pagos
  simples/mixtos, saldos por cobrar, control de stock con bloqueo de filas e
  idempotencia. Los importes se calculan con `Decimal`.
- Se reconstruyeron compras y recepción atómica, cuentas por pagar, recetas,
  citas, órdenes de lentes, reparaciones, caja por turno, factura comercial
  no fiscal (PDF local) y reportes de ventas, inventario, compras y citas.
- La ruta de estado informa la base de datos conectada efectivamente.
- No se habilitaron e-CF/NCF reales ni envíos de WhatsApp. Las funciones de IA
  heredadas no forman parte del cliente final.

## Comprobaciones realizadas

- SQLAlchemy: `onlyeyes360_test` en PostgreSQL 18.6.
- Esquema: 36 tablas y 35 claves foráneas.
- Flutter: 40 pruebas aprobadas.
- Integración: `backend/tests/integration_smoke.py` crea un flujo comercial y
  clínico completo en `onlyeyes360_test` y elimina sus datos temporales al
  finalizar.
- Prueba Windows manual (10-11-2026): inicio de sesión, navegación autenticada
  y todas las pantallas principales fueron abiertas con el ejecutable Release.
  La corrección asociada tipa los filtros opcionales de PostgreSQL para que
  Ventas y las métricas del Dashboard funcionen sin filtros.
- Validación financiera ficticia (11-11-2026): desde Flutter se registró el
  cliente y producto de prueba, se repuso una unidad por Kardex, se abrió caja,
  se cobró una venta mixta de RD$100.00 (RD$50.00 efectivo + RD$50.00 tarjeta)
  y se abrió su factura comercial PDF. El comprobante ahora desglosa cada medio
  de pago y la emisión del PDF crea el comprobante comercial idempotente antes
  de descargarlo. También se corrigió la conciliación: los nuevos cobros en
  efectivo alimentan el turno abierto de caja; tarjeta y transferencia no se
  contabilizan como efectivo.
- Taller y laboratorio (11-11-2026): se agregó la migración
  `backend/migrations/20261111_laboratorio_codigos_historial.sql`, aplicada
  únicamente a `onlyeyes360_test`. Los pedidos de lentes y reparaciones reciben
  códigos persistentes `OE-PED-######` y `OE-REP-######`; los cambios de estado
  conservan usuario, fecha y observaciones en un historial consultable. La
  pantalla recuperada muestra ahora ese código sin cambiar colores, navegación
  ni componentes.
- Notificaciones (11-11-2026): se incorporó un bot de reglas con proveedor
  **simulado**: consentimiento revocable, cola deduplicada, recordatorios de
  citas de 24 h, aviso de trabajo listo, consulta por código y atención humana.
  No hay llamadas a Meta, correo ni WhatsApp real. Las migraciones viven en
  `backend/migrations/20261111_notificaciones_simuladas.sql` y el flujo está
  cubierto por la prueba de integración.
- Empaquetado Windows (11-11-2026): `backend/run_server.py` se compila como
  `backend/dist/only-eyes-backend/only-eyes-backend.exe`; el guion de Inno Setup
  `installer/ONLY_EYES_360.iss` instala Flutter, backend, accesos y una tarea
  local de inicio automático sin requerir consola para empleados. El `.env`
  siempre se crea fuera del paquete de compilación y no contiene secretos.
- Bot e integración futura (11-11-2026): `app/notifications.py` implementa
  recordatorios y avisos mediante proveedor simulado, consentimiento revocable,
  deduplicación y consulta no sensible por código. Supabase se prepara en
  `supabase/` como destino de prueba, con FastAPI como única capa de negocio;
  no se creó ninguna cuenta ni se envió información externa.
- Configuración operativa (11-11-2026): se retiró de la pantalla de ajustes la
  dirección/IP del servidor para el personal. La misma pantalla conserva el
  diseño recuperado y separa **Administración** (ITBIS y usuarios), **Datos del
  negocio** y **Seguros**. Los administradores pueden crear cuentas de cajero,
  administrador, gerente o supervisor; cada venta conserva y muestra el
  nombre de la persona que inició sesión. La migración
  `backend/migrations/20261111_roles_usuarios.sql` se aplicó exclusivamente a
  `onlyeyes360_test` para admitir esos roles.
- Navegación administrativa (11-11-2026): **Administración** reemplaza a
  “Configuración” en la barra lateral; **Datos del negocio** y **Seguros** se
  abren como opciones independientes de esa misma barra, sin pestañas internas
  duplicadas.
- Reportes financieros (11-11-2026): la barra lateral incluye **Reportes y
  Estadísticas**, con gráfico de ventas/cobros por día, mes o año y cuentas por
  cobrar de clientes. Debajo de Compras y Proveedores se añadió **Cuentas por
  pagar**, con los saldos por proveedor y registro de pagos con validación de
  saldo. La serie se obtiene de `/api/reportes/ventas-serie`; todos los datos
  proceden exclusivamente de `onlyeyes360_test` durante el desarrollo.
- Flujo de atención (11-11-2026): la barra agrupa **Pacientes y Recetas**
  (expediente clínico) y **Clientes y Citas** (agenda) sin un directorio de
  clientes independiente. En la agenda se busca primero un paciente existente;
  si no existe, “Nuevo cliente y paciente” conserva los datos en el formulario
  y crea cliente, paciente y cita en una sola transacción al confirmar. Si la
  cita falla, no queda un cliente huérfano. Se valida el posible duplicado por
  nombre, apellido y teléfono.
- Alta contextual en POS (11-11-2026): el campo **Cliente de la venta** busca
  por nombre o teléfono con sugerencias que muestran datos de contacto. La
  opción **+ Agregar** sólo aparece después de buscar y el cliente nuevo se
  guarda junto con la venta, nunca por escribir en el buscador. También existe
  “Continuar como consumidor final”. La prueba de integración verifica alta
  contextual, selección de existentes, rechazo de cliente duplicado al agendar,
  recepción de compra, cuentas por pagar/cobrar, pagos mixtos, caja, factura y
  reportes; todos los datos temporales se eliminan al terminar.
- Comprobante y PDF comercial (11-11-2026): el comprobante del POS muestra el
  SKU, cantidades, precio, descuento y pagos individuales; no inventa RNC,
  teléfonos ni garantías. El cambio se calcula sólo desde efectivo entregado
  sobre el efectivo aplicable: el pago exacto no genera devuelta y tarjeta o
  transferencia nunca generan cambio. La factura comercial genera PDF A4 o
  térmico con datos persistidos de venta, cliente, cajero, detalle y pagos;
  sigue siendo un documento comercial no fiscal.

## Verificación

```powershell
cd C:\ONLY_EYES_360_DESARROLLO\backend
..\.venv\Scripts\python.exe tests\integration_smoke.py

cd ..\flutter_app
flutter test
flutter analyze
flutter build windows
```

La aplicación Windows necesita que FastAPI esté iniciado en `127.0.0.1:8000`
para que la pantalla de inicio indique que el backend está conectado. El
inicio de sesión reintenta automáticamente y muestra “Iniciando servidor
local”, “Servidor iniciado; esperando conexión con la base de datos” o
“Listo para entrar”, según el estado real.

### Arranque local de desarrollo

En esta computadora, `service/OnlyEyesDevelopmentBackend.vbs` se copia a la
carpeta Inicio del usuario para arrancar FastAPI oculto al iniciar sesión. Usa
la copia de desarrollo y el `.env` local; antes de cualquier escritura se
verifica que la conexión efectiva sea `onlyeyes360_test`. Si el servidor no
está disponible, el login comunica el estado de recuperación y permite
reintentar tocando ese aviso; la comprobación directa es
`http://127.0.0.1:8000/health`.

### Caja diaria

La caja es por usuario y turno. El efectivo esperado se calcula en FastAPI con
`Decimal`: fondo inicial + cobros netos en efectivo + ingresos - egresos. Un
cobro en efectivo requiere turno abierto y se registra de forma atómica junto
con el pago; tarjeta y transferencia quedan fuera de la gaveta. El administrador
puede consultar turnos cerrados mediante `/api/caja/historial`. La guía y
prueba de aceptación están en `docs/CAMBIO_CAJA_DIARIA.md`.

Al entrar a **Caja Diaria y Cuadre**, la aplicación consulta el turno del
usuario conectado. Sin turno muestra **Caja cerrada** y **Abrir caja**; con un
turno existente muestra **Continuar turno** con su hora y fondo inicial. La
apertura permite RD$0.00 y requiere confirmación. La API bloquea aperturas
simultáneas del mismo cajero y admite un reintento seguro con clave de
idempotencia. Si falla la consulta aparece **Reintentar**, nunca un turno
anterior como si estuviera vigente.

#### Caja física, pagos y migración 20261114

La migración `backend/migrations/20261114_caja_fisica_pagos_turno.sql` agrega
la **Caja principal**, garantiza un solo turno abierto por caja física y enlaza
los cobros nuevos con su turno y cajero. Los pagos y facturas anteriores se
conservan: su vínculo de turno permanece nulo.

La migración tiene una protección explícita y sólo se puede aplicar en
`onlyeyes360_test`. Para desarrollo, con la conexión ya confirmada a esa base:

```powershell
cd C:\ONLY_EYES_360_DESARROLLO\backend
..\.venv\Scripts\python.exe -c "from pathlib import Path; from app.database import engine; sql=Path('migrations/20261114_caja_fisica_pagos_turno.sql').read_text(); c=engine.raw_connection(); c.cursor().execute(sql); c.commit()"
```

Archivos principales: `backend/app/commerce.py`, la migración anterior,
`backend/tests/cash_register_acceptance.py`,
`flutter_app/lib/screens/admin/cash_register_screen.dart`,
`flutter_app/lib/services/cash_service.dart` y
`flutter_app/lib/models/cash_models.dart`.

La prueba de aceptación de caja crea y elimina sus propios datos ficticios. En
ella se verifica apertura en RD$0, cobro con caja cerrada, idempotencia,
pagos mixtos, avance y abono en turnos distintos, crédito sin abono, permisos,
faltante con observación y la jornada RD$2,000 + RD$4,500 efectivo − RD$500 =
RD$6,000 esperado. Ejecútela con:

```powershell
cd C:\ONLY_EYES_360_DESARROLLO\backend
..\.venv\Scripts\python.exe tests\cash_register_acceptance.py
```

#### Comprobantes comerciales A4 y ticket 80 mm - 14-11-2026

El botón **Factura PDF** y **Imprimir Ticket** comparten el mismo comprobante
comercial persistido. La factura A4 usa tabla con SKU, descripción que se parte
en varias líneas, cantidad, precio, descuento y total; el ticket usa el mismo
contenido en rollo de 80 mm. Ambos muestran datos configurados en
**Administración > Datos del negocio**, logo, cajero, cliente o
**Consumidor final**, subtotal, descuento, ITBIS, total, cobros por método,
abonos/saldo y cambio cuando está guardado en el pago.

La migración `backend/migrations/20261114_datos_negocio_comprobante.sql` crea
el perfil comercial y `backend/migrations/20261114_cambio_comprobante.sql`
guarda `monto_recibido` y `cambio` por pago. Se aplicaron sólo en
`onlyeyes360_test`. Los comprobantes históricos que no tenían cambio guardado
se reimprimen correctamente, pero omiten esa línea porque no es posible
reconstruirla con certeza.

Para probar el documento sin tocar datos de trabajo, desde la raíz del
proyecto ejecute:

```powershell
.\.venv\Scripts\python.exe backend\tests\invoice_pdf_acceptance.py
```

La prueba crea y elimina una venta ficticia con tres renglones y efectivo
recibido RD$5,200.00 para una venta de RD$1,000.00; valida efectivo aplicado
RD$1,000.00, cambio RD$4,200.00, ingreso neto de Caja RD$1,000.00 y una
reimpresión desde los pagos persistidos. También valida un pago mixto donde
sólo los RD$600.00 netos de efectivo ingresan a Caja. Deja muestras en
`output\pdf` para inspección.

Archivos principales: `backend/app/commerce.py`,
`flutter_app/lib/screens/sales/receipt_dialog.dart`,
`flutter_app/lib/screens/sales/commercial_invoice_dialog.dart`,
`flutter_app/lib/models/sale_model.dart`,
`flutter_app/lib/services/business_profile_service.dart` y
`backend/tests/invoice_pdf_acceptance.py`.

Los comprobantes creados por versiones anteriores que enviaban sólo el monto
aplicado ya no se reinterpretan como efectivo recibido. Si `monto_recibido` o
`cambio` no se guardaron, la reimpresión omite esas líneas y conserva sólo
**Efectivo aplicado a la venta**. Esto evita mostrar una devuelta inexistente.

En la versión 0.5.8 se corrigió el cobro de **un solo pago en efectivo**:
ahora el POS también envía `monto_recibido` y `cambio` en ese caso (antes sólo
los enviaba el pago mixto). Por tanto, una venta nueva con efectivo mayor al
total conserva y muestra el importe entregado y su devuelta al descargar o
reimprimir el comprobante.

La ventana de **Factura PDF** utiliza los mismos campos del pago para que su
resumen coincida con la tarjeta de comprobante del POS y con los formatos A4 y
térmico.

El POS incluye **Historial** para consultar ventas anteriores y abrir su
comprobante sin crear un nuevo cobro ni modificar inventario o Caja.

### Distribución Windows

El instalador Inno Setup empaqueta Flutter Release y el backend. La conexión de
una instalación comercial se mantiene fuera del paquete, en `ProgramData`, y
el procedimiento para primera instalación y soporte está en
`docs/PRIMERA_INSTALACION_WINDOWS.md`. Los cambios, evidencias de prueba y
límites pendientes de la versión 0.5.4 están en
`docs/CAMBIO_INSTALACION_WINDOWS.md`.

## Antes de ejecutar

1. Copia el ZIP a la PC que funcionará como servidor.
2. Extrae el ZIP y abre PowerShell **como administrador** en esa carpeta.
3. Revisa `install-only-eyes-360.ps1`. El script pide confirmación antes de
   instalar cada herramienta mediante WinGet.
4. Ejecuta `Set-ExecutionPolicy -Scope Process Bypass` y luego
   `./install-only-eyes-360.ps1`.
5. Copia `.env.example` a `.env`, define `DATABASE_URL` y las claves de IA que
   quieras usar. Las claves no van dentro del ZIP.

## Desarrollo local, después de instalar dependencias

```powershell
cd backend
py -3.14 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --host 127.0.0.1 --port 8000
```

La API queda en `http://127.0.0.1:8000/docs`. El endpoint de WhatsApp es solo
un webhook de recepción: requiere una cuenta Business, app de Meta, número y
verificación oficial antes de poder usarse.

## Seguridad

No publiques el servidor local directamente a internet ni guardes contraseñas o
tokens en Git. Para acceso remoto seguro se necesita definir una solución de
red/autenticación antes de exponerlo.

## Aislamiento de cajas físicas y aceptación - 15-11-2026

- La apertura mantiene la **Caja principal** como predeterminada. Un usuario de
  administración puede indicar una caja física activa distinta mediante
  `caja_id`; los demás roles no pueden seleccionar la gaveta de otro puesto.
  Los bloqueos e índices existentes siguen evitando dos turnos abiertos en una
  misma caja.
- `backend/tests/cash_register_acceptance.py` e
  `backend/tests/integration_smoke.py` ahora crean una caja física temporal y
  la eliminan al terminar. Se ejecutan exclusivamente contra
  `onlyeyes360_test` sin modificar un turno abierto de la Caja principal.
- El 15-11-2026 aprobaron: `flutter analyze`, 41 pruebas Flutter,
  `cash_register_acceptance.py`, `integration_smoke.py` e
  `invoice_pdf_acceptance.py`. La jornada de Caja cubre efectivo con caja
  cerrada, doble clic, pago mixto, exacto, sobrante, faltante de RD$200,
  avance/abono posterior, crédito y permisos.

## Historial de ventas y reimpresión - 15-11-2026

- El botón **Historial** del POS permite buscar directamente por número de
  venta o comprobante antes de abrir el comprobante, descargar el PDF A4 o
  reimprimir el ticket. La consulta no registra cobros, movimientos de Caja ni
  salidas de inventario.
- La verificación se ejecuta sólo contra `onlyeyes360_test`. El paquete de
  esta mejora es la versión 0.5.14.

## Instalación autónoma Windows - 15-11-2026

- La versión 0.5.16 crea siempre el acceso directo del Escritorio y la tarea
  de inicio `ONLY EYES 360 Backend`; ya no quedan como opciones que puedan
  desmarcarse accidentalmente durante una instalación o actualización. Un
  inicio de respaldo al entrar a Windows protege equipos con políticas locales
  que impidan registrar tareas de sistema.
