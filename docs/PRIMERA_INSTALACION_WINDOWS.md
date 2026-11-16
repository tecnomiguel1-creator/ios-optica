# ONLY EYES 360 - Primera instalación Windows

## Antes de instalar

1. Use una cuenta de Windows con permisos de administrador.
2. Instale PostgreSQL 18 o compatible mediante su instalador oficial. No se
   reemplazan servicios ni bases de datos PostgreSQL existentes.
3. Cree una base de datos exclusiva para la nueva tienda; no use
   `onlyeyes360` ni `onlyeyes360_test` para operación comercial.
4. Aplique el esquema/migraciones entregados y cree el primer administrador
   con una contraseña elegida por la empresa. No existen usuarios ni claves
   predeterminadas.

## Instalación

1. Ejecute `ONLY_EYES_360_Setup.exe` como administrador.
2. El instalador conserva datos y configuración existentes durante reparación,
   actualización o desinstalación. La configuración se guarda fuera de
   `Program Files` en `C:\ProgramData\ONLY EYES 360\onlyeyes.env`.
3. Copie el ejemplo creado en esa carpeta y complete únicamente la conexión
   de la nueva base. Nunca pegue credenciales en el instalador ni en tickets
   de soporte.
4. Abra ONLY EYES 360 desde el acceso directo. El login mostrará “Iniciando
   servidor local” mientras espera FastAPI y “Listo para entrar” al conectarse.

## Diagnóstico de soporte

- Registro local: `C:\ProgramData\ONLY EYES 360\logs\backend.log`.
- Estado local: `http://127.0.0.1:8000/health`.
- Si el puerto 8000 está ocupado, el iniciador anota el identificador del
  proceso en el registro. Soporte debe identificarlo antes de detenerlo; no
  se detienen aplicaciones ajenas automáticamente.
- La tarea “ONLY EYES 360 Backend” inicia el backend local con Windows y el
  iniciador reintenta tres veces si el proceso termina.

## Alcance de prueba

El empaquetado fue probado contra `onlyeyes360_test`. La instalación desde cero
en una PC/VM limpia, provisión automática de PostgreSQL y prueba de impresora
física requieren una máquina limpia, instalador oficial de PostgreSQL y el
hardware correspondiente; quedan pendientes antes de venta comercial.
