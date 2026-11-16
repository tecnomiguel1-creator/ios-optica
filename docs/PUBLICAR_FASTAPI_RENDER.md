# Publicar FastAPI para ONLY EYES 360 Mobile

Este despliegue deja FastAPI como la única capa de negocio. El móvil y Windows
usan las mismas reglas de Caja, inventario, cobros y permisos; Supabase ofrece
PostgreSQL remoto, no sustituye el API.

## Antes de crear el servicio

1. Ejecutar `supabase/migrations/001_onlyeyes360_test_schema.sql` en el SQL
   Editor del proyecto **ONLY EYES 360 Mobile**. El archivo no carga datos.
2. En Supabase, pulsar **Connect** y elegir **Session pooler**. Render trabaja
   normalmente desde red IPv4 y la conexión directa de Supabase puede requerir
   IPv6. Copiar la cadena completa, reemplazando `[YOUR-PASSWORD]` solo dentro
   de Render; no colocarla en GitHub, Flutter ni archivos del repositorio.
3. Mantener el repositorio conectado a GitHub. `render.yaml` contiene el
   arranque y no guarda secretos.

## Crear el servidor en Render

1. Iniciar sesión en [Render](https://dashboard.render.com/) con GitHub.
2. Elegir **New +** → **Blueprint** y seleccionar `ios-optica`.
3. Confirmar el servicio `only-eyes-360-api` definido en `render.yaml`.
4. En sus variables de entorno, definir `DATABASE_URL` con la cadena de
   **Session pooler** de Supabase. `JWT_SECRET_KEY` se genera automáticamente
   y se mantiene privada en Render.
5. Crear el Blueprint y esperar el estado **Live**.
6. Abrir `<URL-DE-RENDER>/health`. Debe devolver `status: ok`.

La URL HTTPS que Render asigna, por ejemplo
`https://only-eyes-360-api.onrender.com`, es el valor de
`LOCAL_BACKEND_URL` en GitHub Actions. No añadir `/api` ni una barra final.

## Limitación del plan gratuito

Render indica que un Web Service gratuito entra en pausa tras 15 minutos sin
uso. La primera petición del móvil puede tardar mientras despierta. Para
operación continua de Caja se recomienda un plan que mantenga el servicio
activo.
