# ONLY EYES 360 - Cambio de instalación Windows 0.5.3

## Objetivo

Dejar el Release de Windows listo para instalar la aplicación y su backend
local, sin requerir Flutter, VS Code ni Python en el equipo del personal.

## Archivos incluidos

- `flutter_app/build/windows/x64/runner/Release`: aplicación Flutter Release.
- `backend/dist/only-eyes-backend`: backend FastAPI empaquetado con sus
  dependencias.
- `installer/ONLY_EYES_360.iss`: instalador Inno Setup.
- `installer/service/start-backend.cmd`: inicio local, registro y hasta tres
  reintentos tras una caída.
- `installer/service/OnlyEyesBackend.vbs`: iniciador silencioso invocado por
  Windows Script Host.

## Comportamiento instalado

1. El acceso directo abre ONLY EYES 360 sin consola.
2. La tarea `ONLY EYES 360 Backend` intenta iniciar el backend local con
   Windows. El instalador también lo inicia una vez al finalizar.
3. La configuración comercial vive fuera del paquete en
   `C:\ProgramData\ONLY EYES 360\onlyeyes.env`; el instalador sólo entrega un
   ejemplo y no contiene claves ni contraseñas.
4. Los diagnósticos van a
   `C:\ProgramData\ONLY EYES 360\logs\backend.log`.
   Si el puerto 8000 ya está ocupado, el registro conserva el identificador
   del proceso conflictivo sin cerrar aplicaciones ajenas.
5. El login reintenta el servidor local y distingue inicio del servidor,
   espera por base de datos y disponibilidad para entrar.

## Resultados reales de esta versión

| Verificación | Resultado |
| --- | --- |
| Release Windows de Flutter | Correcto |
| Empaquetado del backend | Correcto |
| Compilación de Inno Setup | Correcto; `installer/output/ONLY_EYES_360_Setup.exe` generado |
| `flutter analyze` | Correcto, sin incidencias |
| `flutter test --concurrency=1` | Correcto, 41 pruebas |
| Prueba backend de caja | Correcto, `CASH_REGISTER_ACCEPTANCE_OK` |
| Prueba backend de integración | Correcto, `INTEGRATION_SMOKE_OK` |
| `GET /health` con backend reiniciado | Correcto; base lista |
| Base usada en estas pruebas | Exclusivamente `onlyeyes360_test` (39 tablas) |

Además, el Release visual mostró **Listo para entrar** tras conectarse al
backend local. El turno ficticio abierto que provocaba la pantalla de caja
activa fue cerrado y quedó en el historial de `onlyeyes360_test`.

La versión 0.5.3 incorpora el cuadre por caja física, el enlace de todos los
cobros nuevos al turno que los recibe y el comprobante PDF interno de cierre.

## Cómo repetir la prueba de caja

1. Conecte el entorno de desarrollo a `onlyeyes360_test`.
2. Abra caja con RD$2,000.00.
3. Registre una venta ficticia de RD$1,000.00 con RD$600.00 efectivo y
   RD$400.00 tarjeta.
4. Registre un egreso de RD$100.00: el esperado debe ser RD$2,500.00.
5. Cuente RD$2,450.00 y cierre: el turno debe registrar faltante RD$50.00.

La automatización también cubre un turno exacto, un sobrante, un reintento de
cobro y la prohibición de cobrar efectivo con la caja cerrada.

## Pendientes obligatorios antes de venta comercial

- Validar instalación desde cero y reinicio automático en una PC o VM Windows
  limpia. Este entorno no dispone de una.
- Distribuir o seleccionar el instalador oficial de PostgreSQL y la política
  de respaldos. La aplicación no reemplaza instalaciones de PostgreSQL
  existentes ni crea una base comercial sin que el instalador proporcione sus
  credenciales.
- Completar un asistente de aprovisionamiento que aplique el esquema en una
  base nueva y cree el primer administrador elegido por la empresa. No se
  habilitó una clave predeterminada por seguridad.
- Validar impresión física. Guardar o visualizar el comprobante PDF sí se
  puede probar sin impresora.
- Si Microsoft Defender bloquea un instalador sin firma, no se debe eludir la
  protección: la entrega comercial requiere firma de código o distribución
  aprobada por el administrador de TI.
