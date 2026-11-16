# Registro de Cambios: Rediseño Visual Ejecutivo y Profesional (República Dominicana)
**Fecha:** 2026-11-06  
**Sistema:** ONLY EYES 360  
**Razón Social:** Óptica ONLY EYES S.R.L.  
**Eslogan Corporativo:** Un compromiso con tu visión  
**Entorno:** Flutter 3.38.5 / Dart 3.10.4 para Windows (x64) y Android  

---

## 1. Alcance y Respaldo de Seguridad

Se preservó estrictamente la regla de aislamiento del desarrollo paralelo:
- **Ámbito exclusivo:** Trabajo ejecutado 100% dentro del directorio `flutter_app/`.
- **Integridad del Backend:** Ningún archivo de `backend/`, PostgreSQL, migraciones ni credenciales fue alterado.
- **Cálculos Financieros:** No se alteraron los tipos de datos numéricos ni las fórmulas de cálculo de FastAPI; el formateo monetario opera exclusivamente en la capa de presentación.

### Respaldos Generados para Restauración Inmediata:
1. `backups/flutter-app-pre-redisenio-ejecutivo-20261106.tar.gz` (62.5 MB - Contiene árbol completo de la app antes de las modificaciones).
2. `backups/flutter-app-pre-redisenio-ejecutivo-source.zip` (151 KB - Código fuente limpio).
3. `flutter_app/build/windows/x64/runner/Release/only_eyes_360_pre_redisenio.exe` (Binario compilado anterior preservado).

### Procedimiento de Restauración (Rollback):
En caso de requerir volver a la versión anterior de inmediato:
```powershell
# Extraer respaldo limpio sobre flutter_app
tar -xzf backups/flutter-app-pre-redisenio-ejecutivo-20261106.tar.gz
```

---

## 2. Pantallas y Componentes Mejorados

### A. Identidad Visual y Tema Corporativo
- **Constantes Canónicas:** Definidas en `AppColors`:
  - `companyName = 'Óptica ONLY EYES S.R.L.'`
  - `systemName = 'ONLY EYES 360'`
  - `companySlogan = 'Un compromiso con tu visión'`
- **Paleta Ejecutiva:** Azul Zafiro Óptico (`#0F4C81`), Deep Navy Slate (`#0A192F`), Teal Clínico (`#00A896`), Cyan de Visión (`#0288D1`), fondos suaves Slate (`#F8FAFC`) y estados discretos para confirmaciones y alertas.

### B. Formato Monetario Dominicano Automático (`Formatters.formatCurrency`)
- Presentación monetaria estándar: `RD$1,500.00`, `RD$12,500.50`, `RD$1,000,000.00`.
- Soporte para separadores de miles y dos decimales exactos sin recurrir a casting de punto flotante que altere los cálculos del backend.

### C. Inicio de Sesión (`LoginScreen`)
- Incorporación del logotipo oficial `BrandLogo`, nombre corporativo "Óptica ONLY EYES S.R.L." y eslogan "Un compromiso con tu visión".
- Indicador visual de estado de conexión al backend en tiempo real con selector de URL.
- Campos con bordes refinados y micro-interacciones de foco.

### D. Menú Lateral Ejecutivo (`AdaptiveNavigationShell`)
- Encabezado con logotipo, razón social oficial y eslogan en azul hielo.
- Píldora de selección activa (`#38BDF8`) con borde izquierdo acentuado.
- Terminología dominicana en todas las opciones:
  - *Dashboard* (Panel Principal)
  - *Clientes*
  - *Pacientes y Recetas*
  - *Inventario y Catálogo*
  - *Compras y Proveedores*
  - *Punto de Venta (POS)*
  - *Citas y Agenda*
  - *Taller Óptico y Laboratorio*
  - *Caja Diaria y Cuadre*
  - *Configuración General*

### E. Punto de Venta (POS) y Pagos Mixtos (`PosScreen`)
- Barra de filtros rápidos por categoría óptica (Monturas, Cristales, Lentes de Contacto, Medicamentos, Accesorios, Servicios).
- Conservación íntegra de la lógica de pagos mixtos (Efectivo, Tarjeta, Transferencia) desarrollada por Codex.
- Presentación clara de: Subtotal, Descuento comercial, ITBIS por producto (según FastAPI), Cobertura autorizada ARS, Diferencia a pagar por el cliente, Total de la venta y Devuelta en efectivo.

### F. Nuevo Componente Desacoplado: Cobertura de Seguro Médico (`InsuranceCoverageCard`)
- Selector desplegable de Aseguradoras / ARS privadas de República Dominicana (*Primera ARS de Humano*, *Mapfre Salud ARS*, *ARS Universal*, *ARS Monumental*, *ARS Renacer*, *ARS Simag*, *ARS GMA*, *ARS Futuro*, *ARS Yunen*).
- **Regla cumplida:** Excluye SeNaSa y regímenes subsidiados.
- Campo monetario para *Monto autorizado por la ARS* (RD$).
- Campo para *Número de autorización*.
- Resumen financiero en vivo: Total de la venta, Cobertura autorizada, Diferencia a pagar por el cliente, Pagos realizados y Balance pendiente.
- Arquitectura desacoplada: no simula cobros ficticios en PostgreSQL; anota la referencia en las observaciones de la orden hasta que Codex active los modelos formales de aseguradoras en el backend.

### G. Catálogo e Inventario (`ProductListScreen` y `ProductFormDialog`)
- Clasificación visual por categorías ópticas:
  - Monturas
  - Cristales oftálmicos
  - Lentes de contacto
  - Medicamentos oftálmicos
  - Accesorios y estuches
  - Servicios ópticos
  - Laboratorio y reparaciones
- Precios de venta y costos de compra presentados en formato `RD$`.

### H. Compras y Recepción de Mercancía (`PurchaseListScreen` y `NewPurchaseScreen`)
- Nuevo diálogo de auditoría e inspección técnica de órdenes de compra con desglose de productos solicitados, cantidades, costos unitarios e impuestos.
- Botón directo para confirmación de recepción física de mercancía que actualiza existencias e historial en el Kardex.

### I. Caja Diaria y Cuadre de Turno (`CashRegisterScreen`)
- Nomenclatura dominicana: *Caja Diaria y Cuadre de Caja*, *Fondo Inicial de Apertura*, *Ingresos de Caja*, *Retiros / Egresos* y *Cuadre y Cierre de Turno*.
- Indicadores claros de efectivo esperado en gaveta y balance final.

### J. Configuración General (`SettingsScreen`)
- Perfil comercial actualizado con: Óptica ONLY EYES S.R.L., eslogan comercial, RNC dominicano, dirección en Santo Domingo, D.N. y teléfono de contacto.

---

## 3. Pruebas y Resultados de Verificación

### Análisis Estático (`flutter analyze`):
```powershell
flutter analyze
# Analyzing flutter_app...
# No issues found! (ran in 1.5s)
```

### Conjunto de Pruebas Automatizadas (`flutter test`):
```powershell
flutter test
# 00:03 +37: All tests passed! (37 de 37 pruebas aprobadas - 100%)
```

### Cobertura de Pruebas:
- `test/branding_test.dart` (14 pruebas de proporción de logotipo y colores).
- `test/models_test.dart` (9 pruebas de parseo, contratos FastAPI y formateo monetario).
- `test/responsive_layout_test.dart` (3 pruebas de layouts en 400×800, 1366×768 y 1920×1080).
- `test/widget_test.dart` (1 prueba de componentes).
- `test/workshop_and_forms_test.dart` (7 pruebas de taller óptico, dialogs y facturación comercial).
- `test/insurance_and_pos_test.dart` (3 pruebas de cobertura de seguro médico, reactividad financiera y pantallas compactas).

### Compilación Windows:
- Binario verificado y generado satisfactoriamente: `build\windows\x64\runner\Release\only_eyes_360.exe`.
