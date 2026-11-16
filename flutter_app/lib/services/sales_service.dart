import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/sale_model.dart';

/// Servicio de Ventas, Cobros y Cuentas por Cobrar conectado a FastAPI
class SalesService {
  final ApiClient _apiClient;

  SalesService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<SaleModel>> getSales({
    int? clienteId,
    String? estado,
    int limite = 100,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'limite': limite,
      'offset': offset,
    };
    if (clienteId != null) params['cliente_id'] = clienteId;
    if (estado != null) params['estado'] = estado;

    final response = await _apiClient.get(
      ApiEndpoints.ventas,
      queryParameters: params,
    );

    if (response is Map && response.containsKey('ventas')) {
      final list = response['ventas'] as List;
      return list
          .map((item) => SaleModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<SaleModel> getSaleById(int id) async {
    final response = await _apiClient.get(ApiEndpoints.ventaDetalle(id));
    final ventaJson = response['venta'] as Map<String, dynamic>;
    final detallesJson = response['detalles'] as List?;
    final pagosJson = response['pagos'] as List?;

    return SaleModel.fromJson(
      ventaJson,
      detalles: detallesJson,
      pagosJson: pagosJson,
    );
  }

  Future<Map<String, dynamic>> createSale({
    int? clienteId,
    String tipoComprobante = 'sin_ncf',
    double impuestos = 0.0,
    String? observaciones,
    Map<String, dynamic>? clienteNuevo,
    required List<SaleItemModel> items,
    String? idempotencyKey,
  }) async {
    final detallesPayload = items
        .map((i) => {
              'producto_id': i.productoId,
              'cantidad': i.cantidad,
              'descuento': i.descuento,
            })
        .toList();

    final response = await _apiClient.post(
      ApiEndpoints.ventas,
      body: {
        if (clienteId != null) 'cliente_id': clienteId,
        if (clienteNuevo != null) 'cliente_nuevo': clienteNuevo,
        'tipo_comprobante': tipoComprobante,
        'impuestos': impuestos,
        if (observaciones != null && observaciones.isNotEmpty)
          'observaciones': observaciones,
        'detalles': detallesPayload,
      },
      headers:
          idempotencyKey == null ? null : {'Idempotency-Key': idempotencyKey},
    );

    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerPayment({
    required int ventaId,
    required double monto,
    required String metodoPago,
    double? montoRecibido,
    double? cambio,
    String? referencia,
    String? observaciones,
    String? idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.ventaPagos(ventaId),
      body: {
        'monto': monto,
        'metodo_pago': metodoPago,
        // El importe aplicado y el efectivo entregado no siempre son iguales:
        // por ejemplo, RD$5,200 recibidos para aplicar RD$1,000 y devolver
        // RD$4,200. Se conservan para el comprobante y la reimpresión.
        if (montoRecibido != null) 'monto_recibido': montoRecibido,
        if (cambio != null) 'cambio': cambio,
        if (referencia != null && referencia.isNotEmpty)
          'referencia': referencia,
        if (observaciones != null && observaciones.isNotEmpty)
          'observaciones': observaciones,
      },
      headers:
          idempotencyKey == null ? null : {'Idempotency-Key': idempotencyKey},
    );
    return response as Map<String, dynamic>;
  }

  /// Liquida varios medios de pago en una única solicitud atómica al backend.
  Future<Map<String, dynamic>> registerMixedPayments({
    required int ventaId,
    required List<Map<String, dynamic>> pagos,
    String? idempotencyKey,
  }) async {
    if (pagos.length < 2) {
      throw ArgumentError(
          'Se requieren al menos dos pagos para un cobro mixto.');
    }
    final response = await _apiClient.post(
      ApiEndpoints.ventaPagosMixtos(ventaId),
      body: {'pagos': pagos},
      headers:
          idempotencyKey == null ? null : {'Idempotency-Key': idempotencyKey},
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelSale(int ventaId) async {
    final response = await _apiClient.post(ApiEndpoints.ventaAnular(ventaId));
    return response as Map<String, dynamic>;
  }

  Future<List<AccountReceivableModel>> getAccountsReceivable({
    int? clienteId,
    int limite = 100,
  }) async {
    final params = <String, dynamic>{'limite': limite};
    if (clienteId != null) params['cliente_id'] = clienteId;

    final response = await _apiClient.get(
      ApiEndpoints.cuentasPorCobrar,
      queryParameters: params,
    );

    if (response is Map && response.containsKey('cuentas')) {
      final list = response['cuentas'] as List;
      return list
          .map((item) =>
              AccountReceivableModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
