import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/inventory_movement_model.dart';
import '../models/product_model.dart';

class InventoryService {
  final ApiClient _apiClient;

  InventoryService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<ProductModel>> getProducts({
    String? categoria,
    bool incluirInactivos = false,
    int limite = 100,
  }) async {
    final params = <String, dynamic>{
      'incluir_inactivos': incluirInactivos,
      'limite': limite,
    };
    if (categoria != null && categoria.isNotEmpty) {
      params['categoria'] = categoria;
    }

    final response = await _apiClient.get(
      ApiEndpoints.productos,
      queryParameters: params,
    );

    if (response is Map && response.containsKey('productos')) {
      final list = response['productos'] as List;
      return list.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<ProductModel>> searchProducts(String query, {String? categoria}) async {
    final params = <String, dynamic>{'q': query};
    if (categoria != null && categoria.isNotEmpty) {
      params['categoria'] = categoria;
    }

    final response = await _apiClient.get(
      ApiEndpoints.productosBuscar,
      queryParameters: params,
    );

    if (response is Map && response.containsKey('productos')) {
      final list = response['productos'] as List;
      return list.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<ProductModel>> getLowStockProducts() async {
    final response = await _apiClient.get(ApiEndpoints.productosStockBajo);
    if (response is Map && response.containsKey('productos')) {
      final list = response['productos'] as List;
      return list.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<int> createProduct(ProductModel product) async {
    final response = await _apiClient.post(
      ApiEndpoints.productos,
      body: product.toJson(),
    );
    return response['producto_id'] as int;
  }

  Future<void> updateProduct(int id, Map<String, dynamic> changes) async {
    await _apiClient.patch(ApiEndpoints.productoDetalle(id), body: changes);
  }

  Future<void> deactivateProduct(int id) async {
    await _apiClient.delete(ApiEndpoints.productoDetalle(id));
  }

  Future<Map<String, dynamic>> recordStockMovement({
    required int productoId,
    required String tipo, // entrada | salida | ajuste
    required int cantidad,
    required String motivo,
    String? observaciones,
    bool ajusteAumenta = true,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.inventarioMovimientos,
      body: {
        'producto_id': productoId,
        'tipo': tipo,
        'cantidad': cantidad,
        'motivo': motivo,
        'observaciones': observaciones,
        'ajuste_aumenta': ajusteAumenta,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<List<InventoryMovementModel>> getMovements({int? productoId, int limite = 50}) async {
    final params = <String, dynamic>{'limite': limite};
    if (productoId != null) params['producto_id'] = productoId;

    final response = await _apiClient.get(
      ApiEndpoints.inventarioMovimientos,
      queryParameters: params,
    );

    if (response is Map && response.containsKey('movimientos')) {
      final list = response['movimientos'] as List;
      return list
          .map((item) => InventoryMovementModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
