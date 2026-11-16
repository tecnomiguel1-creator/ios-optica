/// Catálogo exacto de endpoints verificados del backend FastAPI de ONLY EYES 360
class ApiEndpoints {
  // Verificación y salud
  static const String health = '/health';
  static const String databaseStatus = '/api/database/status';

  // Autenticación
  static const String login = '/api/auth/login';
  static const String me = '/api/auth/yo';
  static const String usuarios = '/api/usuarios';
  static const String datosNegocio = '/api/datos-negocio';

  // Clientes
  static const String clientes = '/api/clientes';
  static const String clientesBuscar = '/api/clientes/buscar';
  static String clienteDetalle(int id) => '/api/clientes/$id';

  // Pacientes
  static const String pacientes = '/api/pacientes';
  static const String pacientesBuscar = '/api/pacientes/buscar';
  static String pacienteDetalle(int id) => '/api/pacientes/$id';
  static String pacienteHistorial(int id) => '/api/pacientes/$id/historial';

  // Recetas Oftalmológicas
  static const String recetas = '/api/recetas';
  static String recetaDetalle(int id) => '/api/recetas/$id';
  static String recetasPorPaciente(int pacienteId) =>
      '/api/pacientes/$pacienteId/recetas';

  // Inventario y Productos
  static const String productos = '/api/productos';
  static const String productosBuscar = '/api/productos/buscar';
  static const String productosStockBajo = '/api/productos/stock-bajo';
  static String productoDetalle(int id) => '/api/productos/$id';
  static const String inventarioMovimientos = '/api/inventario/movimientos';

  // Proveedores
  static const String proveedores = '/api/proveedores';
  static const String proveedoresBuscar = '/api/proveedores/buscar';
  static String proveedorDetalle(int id) => '/api/proveedores/$id';

  // Compras y Cuentas por Pagar
  static const String compras = '/api/compras';
  static String compraDetalle(int id) => '/api/compras/$id';
  static String compraRecibir(int id) => '/api/compras/$id/recibir';
  static String compraPagos(int id) => '/api/compras/$id/pagos';
  static const String cuentasPorPagar = '/api/cuentas-por-pagar';

  // Ventas y Cuentas por Cobrar
  static const String ventas = '/api/ventas';
  static String ventaDetalle(int id) => '/api/ventas/$id';
  static String ventaPagos(int id) => '/api/ventas/$id/pagos';
  static String ventaPagosMixtos(int id) => '/api/ventas/$id/pagos-mixtos';
  static String ventaAnular(int id) => '/api/ventas/$id/anular';
  static const String cuentasPorCobrar = '/api/cuentas-por-cobrar';

  // Citas y Agenda Optométrica
  static const String citas = '/api/citas';
  static const String citasConCliente = '/api/citas/con-cliente';
  static String citaDetalle(int id) => '/api/citas/$id';

  // Órdenes de laboratorio óptico
  static const String pedidosLentes = '/api/pedidos-lentes';
  static String pedidoLentesEstado(int id) => '/api/pedidos-lentes/$id/estado';

  // Reparaciones
  static const String reparaciones = '/api/reparaciones';
  static String reparacionEstado(int id) => '/api/reparaciones/$id/estado';

  // Caja y documentos comerciales no fiscales (requieren migracion 0001 en API)
  static const String cajaActual = '/api/caja/actual';
  static const String cajaAperturas = '/api/caja/aperturas';
  static const String cajaMovimientos = '/api/caja/movimientos';
  static const String cajaCierre = '/api/caja/cierre';
  static String cajaComprobantePdf(int shiftId) =>
      '/api/caja/$shiftId/comprobante/pdf';
  static String facturaComercial(int ventaId) =>
      '/api/ventas/$ventaId/factura-comercial';
  static String facturaComercialPdf(int ventaId) =>
      '/api/ventas/$ventaId/factura-comercial/pdf';

  // Reportes y Analíticas
  static const String reporteVentas = '/api/reportes/ventas';
  static const String reporteVentasSerie = '/api/reportes/ventas-serie';
  static const String reporteInventario = '/api/reportes/inventario';
  static const String reporteCompras = '/api/reportes/compras';
  static const String reporteCitas = '/api/reportes/citas';

  // Asistente IA
  static const String ask = '/api/ask';
  static const String iaSeleccionar = '/api/ia/seleccionar';
  static const String iaEjecutar = '/api/ia/ejecutar';
}
