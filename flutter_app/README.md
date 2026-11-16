# ONLY EYES 360 — Cliente Multiplataforma Flutter (Windows & Android)

Sistema de Gestión Integral para Ópticas y Consultorios Oftalmológicos.

---

## 1. Arquitectura del Proyecto

```
flutter_app/
├── lib/
│   ├── main.dart                      # Punto de entrada de la aplicación
│   ├── app.dart                       # Enrutador reactivo (Login vs Shell adaptativo)
│   ├── core/
│   │   ├── config/app_config.dart     # URL configurable del backend FastAPI, timeouts y claves
│   │   ├── theme/                     # Paleta médica óptica, tipografía Segoe UI y componentes M3
│   │   ├── network/                   # ApiClient con inyección Bearer JWT y manejo tipado de errores
│   │   ├── storage/token_storage.dart # Almacenamiento seguro del token JWT y perfil de usuario
│   │   └── utils/                     # Responsive (Desktop/Mobile) y Formatters (Dioptrías, Eje, DP, RD$)
│   ├── models/                        # Modelos espejo de FastAPI (User, Client, Patient, Rx, Product, Kardex, Purchase)
│   ├── services/                      # Servicios HTTP conectados al backend y repositorios desacoplados
│   ├── state/app_state.dart           # Gestor de estado ChangeNotifier (sesión, navegación, alertas stock bajo)
│   ├── screens/
│   │   ├── auth/login_screen.dart     # Inicio de sesión con prueba de conexión y selector de IP
│   │   ├── shell/                     # Sidebar persistente (Windows) y Drawer + BottomNav (Android)
│   │   ├── dashboard/                 # Panel con KPIs reales, alertas de stock bajo y accesos rápidos
│   │   ├── clients/                   # Directorio de clientes con búsqueda reactiva y alta de fichas
│   │   ├── patients/                  # Expedientes clínicos, tabla optométrica OD/OI e historial
│   │   ├── inventory/                 # Catálogo por categorías, alertas de stock crítico y movimientos Kardex
│   │   ├── purchases/                 # Órdenes de compra y recepción atómica que actualiza existencias
│   │   ├── sales/                     # Terminal POS con carrito, selección de cliente y ticket de impresión
│   │   └── admin/                     # Citas médicas, órdenes de taller para lentes, caja diaria y configuración
│   └── widgets/                       # Componentes reutilizables (StatCard, OpticalPrescriptionCard, EmptyState...)
└── test/
    ├── models_test.dart               # Pruebas unitarias de modelos, dioptrías, stock bajo y contratos
    └── widget_test.dart               # Pruebas de widgets (Tarjetas clínicas, prescripción OD/OI, estados vacíos)
```

---

## 2. Estado de Conexión con el Backend FastAPI

### Endpoints 100% Conectados al Backend Real
- **Autenticación**: `POST /api/auth/login`, `GET /api/auth/yo` (Token JWT HS256, 8 horas)
- **Clientes**: `GET /api/clientes`, `GET /api/clientes/buscar`, `POST /api/clientes`, `PATCH /api/clientes/{id}`
- **Pacientes**: `GET /api/pacientes`, `POST /api/pacientes`
- **Recetas**: `GET /api/recetas`, `POST /api/recetas`, `GET /api/pacientes/{id}/recetas`
- **Inventario**: `GET /api/productos`, `POST /api/productos`, `GET /api/productos/stock-bajo`, `PATCH /api/productos/{id}`, `DELETE /api/productos/{id}`
- **Kardex**: `POST /api/inventario/movimientos`, `GET /api/inventario/movimientos`
- **Proveedores**: `GET /api/proveedores`, `POST /api/proveedores`, `GET /api/proveedores/buscar`, `PATCH /api/proveedores/{id}`
- **Compras**: `GET /api/compras`, `POST /api/compras`, `POST /api/compras/{id}/recibir` (Recepción atómica)
- **Salud del Servidor**: `GET /health`, `GET /api/database/status`

### Módulos Desacoplados con Mock Repository (Pendientes en Backend)
- **Ventas & POS**: Carrito, emisión de factura térmica y cálculo de balance pendiente.
- **Caja Diaria**: Arqueo de gaveta, ingresos y egresos menores.
- **Agenda de Citas**: Programación de exámenes de la vista.
- **Taller de Lentes**: Control de biselado, tallado y tratamiento antirreflejo.
- *Nota de diseño*: Estos módulos están identificados con etiquetas `isMock: true` y listos para conectar cuando el backend implemente sus rutas.

---

## 3. Cómo Instalar Flutter SDK en Windows

Actualmente el SDK de Flutter no está presente en el `PATH` del equipo. Para instalarlo:

### Opción 1: Vía WinGet (Recomendado en Windows 11 / 10)
Abre PowerShell como Administrador y ejecuta:
```powershell
winget install Google.Flutter
```
Reinicia la terminal de PowerShell para que se recarguen las variables de entorno.

### Opción 2: Descarga Manual
1. Descarga el paquete oficial desde: https://docs.flutter.dev/get-started/install/windows/desktop
2. Extrae el archivo ZIP en `C:\src\flutter` (evita `C:\Program Files` para no tener problemas de permisos).
3. Añade `C:\src\flutter\bin` a la variable de entorno `PATH` de tu usuario.
4. Abre una nueva consola y valida ejecutando:
   ```powershell
   flutter doctor
   ```

---

## 4. Ejecución y Pruebas

### Ejecutar Pruebas
```powershell
cd flutter_app
flutter test
```

### Ejecutar en Windows Desktop
```powershell
cd flutter_app
flutter run -d windows
```

### Ejecutar en Android (Emulador o Dispositivo Físico)
```powershell
cd flutter_app
flutter run -d android
```

---

## 5. Requisitos de Red Local
- Si ejecutas en la **misma máquina (Windows)**: La app se conecta a `http://127.0.0.1:8000`.
- Si ejecutas en un **emulador Android**: Configura la URL en `http://10.0.2.2:8000`.
- Si ejecutas en un **celular físico conectado por Wi-Fi**: Configura la IP de tu PC (ejemplo: `http://192.168.1.15:8000`) desde el botón de engranaje en la pantalla de Login o en Configuración.
