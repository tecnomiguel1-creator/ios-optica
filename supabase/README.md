# Preparación de Supabase (sin datos reales)

Esta carpeta no conecta Flutter ni el bot directamente a PostgreSQL. La futura
instancia Supabase será accesible únicamente por FastAPI usando `SUPABASE_DB_URL`
como variable de entorno externa al código.

## Prueba autorizada con datos ficticios

1. Crear un proyecto Supabase de **prueba** y obtener su URL de base de datos
   con TLS. No reutilizar `onlyeyes360` ni sus respaldos.
2. Exportar desde `onlyeyes360_test` con `pg_dump --schema-only` y revisar el
   resultado antes de cargarlo. Aplicar luego los archivos de `backend/migrations`.
3. Cargar únicamente una copia anonimizada/ficticia y ejecutar
   `backend/tests/integration_smoke.py` apuntando a esa base de prueba.
4. Mantener las tablas sin exponer por Data API; si se habilita alguna, activar
   RLS y aplicar políticas de mínimo privilegio. FastAPI conserva autenticación,
   permisos, bloqueo de inventario e idempotencia.

El proyecto remoto exclusivo de móvil se creó el 16-11-2026. No se han subido
datos, tablas ni respaldos de ONLY EYES. Antes de cambiar `DATABASE_URL` o
publicar una tabla se requiere aprobar la arquitectura de identidades y las
políticas RLS descritas en `docs/IOS_MOVIL_SUPABASE.md`.
