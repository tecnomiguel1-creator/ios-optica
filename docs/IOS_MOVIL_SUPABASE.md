# ONLY EYES 360 para iPhone

## Estado de la base móvil

La carpeta `flutter_app/ios` contiene el proyecto iOS generado desde el mismo
Flutter que usa Windows. El identificador de paquete es
`com.onlyeyes360.mobile` y la aplicación solicita acceso a la red local de la
óptica.

El proyecto Supabase exclusivo para móvil es `ONLY EYES 360 Mobile`
(`fzsvdzgpjnteobdtjqoo`) en Sudamérica. Sus claves privadas no se guardan en
este repositorio, en la IPA ni en el instalador Windows. La URL y la clave
publicable se inyectan al compilar mediante `--dart-define`.

La interfaz móvil conserva los módulos del sistema de PC de forma cómoda: en
teléfonos se oculta la barra lateral, queda un menú desplegable con todas las
opciones y una barra inferior para Inicio, Pacientes, Inventario y POS.

## Arquitectura segura

1. El móvil usa el mismo FastAPI que Windows para autenticación, permisos,
   inventario, Punto de Venta y Caja.
2. Supabase se emplea como canal remoto y sincronización, no como una copia
   pública de las tablas comerciales.
3. Cuando haya Wi-Fi local sin Internet, el teléfono apunta a FastAPI dentro
   de la red de la óptica. Cuando vuelva Internet, una cola local sincroniza
   operaciones pendientes sin duplicarlas.
4. Cada operación de venta o Caja mantiene una clave de idempotencia. El
   servidor es quien confirma el resultado final.

El cliente iOS inicializa Supabase solo si recibe las dos variables públicas.
No se permite que el teléfono escriba directamente ventas, pagos, inventario o
Caja mediante la Data API de Supabase; así una caja abierta o cerrada desde
Windows se observa y valida igual desde el móvil.

Para operar también fuera de la red local se necesita una URL HTTPS accesible
del FastAPI compartido. `127.0.0.1` solo sirve en el PC del servidor. Sin esa
URL el modo local por Wi-Fi sigue funcionando, pero no puede sincronizar una
venta de un móvil remoto con la PC.

## Compilar y firmar en Mac

Una IPA para un iPhone normal requiere Xcode y una firma válida de Apple. En
una Mac, desde `flutter_app`, configurar el equipo y el perfil de firma en
Xcode y ejecutar:

```bash
flutter pub get
flutter build ipa --release \
  --dart-define=LOCAL_BACKEND_URL=http://IP_LOCAL_DE_LA_OPTICA:8000 \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<clave_publicable>
```

La clave publicable puede estar en la app; las claves de servicio y contraseñas
de base de datos nunca se incluyen en el teléfono.

## Generar la IPA sin firmar en GitHub

El flujo `.github/workflows/ios-unsigned-ipa.yml` construye en macOS la
aplicación y publica `ONLY_EYES_360_unsigned.ipa` como artefacto. En el
repositorio privado configure estas variables de Actions:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `LOCAL_BACKEND_URL` (una URL HTTPS o la IP LAN del FastAPI)

La IPA sin firmar no se instala sola en un iPhone estándar. Después de
descargarla hay que firmarla con el certificado y perfil Apple del titular, sin
subir estos archivos a GitHub.

## Decisión pendiente antes de activar sincronización

Elegir una sola identidad para el personal:

- **FastAPI actual (recomendado):** conserva las cuentas y roles de Windows;
  FastAPI valida las solicitudes móviles y sincroniza con Supabase.
- **Supabase Auth:** requiere crear o migrar cuentas del personal y enlazar
  explícitamente los roles actuales antes de habilitar ventas o Caja.

No se debe exponer `ventas`, `pagos_ventas`, `turnos_caja` ni inventario por la
Data API de Supabase hasta completar esa decisión y sus políticas RLS.
