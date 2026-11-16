import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/purchase_model.dart';

class PurchaseService {
  final ApiClient _apiClient;

  PurchaseService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<PurchaseModel>> getPurchases({String? estado, int limite = 100}) async {
    final params = <String, dynamic>{'limite': limite};
    if (estado != null) params['estado'] = estado;

    final response = await _apiClient.get(
      ApiEndpoints.compras,
      queryParameters: params,
    );

    if (response is Map && response.containsKey('compras')) {
      final list = response['compras'] as List;
      return list.map((item) => PurchaseModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<PurchaseModel> getPurchaseById(int id) async {
    final response = await _apiClient.get(ApiEndpoints.compraDetalle(id));
    final compraJson = response['compra'] as Map<String, dynamic>;
    final detallesJson = response['detalles'] as List?;
    return PurchaseModel.fromJson(compraJson, detallesJson);
  }

  Future<int> createPurchase({
    required int proveedorId,
    String? fechaCompra,
    String? numeroFactura,
    String? observaciones,
    double impuestos = 0.0,
    required List<Map<String, dynamic>> detalles,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.compras,
      body: {
        'proveedor_id': proveedorId,
        if (fechaCompra != null) 'fecha_compra': fechaCompra,
        if (numeroFactura != null) 'numero_factura': numeroFactura,
        if (observaciones != null) 'observaciones': observaciones,
        'impuestos': impuestos,
        'detalles': detalles,
      },
    );
    return response['compra_id'] as int;
  }

  Future<Map<String, dynamic>> receivePurchase(int id) async {
    final response = await _apiClient.post(ApiEndpoints.compraRecibir(id));
    return response as Map<String, dynamic>;
  }
}
