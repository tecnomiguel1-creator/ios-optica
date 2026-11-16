import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/supplier_model.dart';

class SupplierService {
  final ApiClient _apiClient;

  SupplierService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<SupplierModel>> getSuppliers({bool incluirInactivos = false}) async {
    final response = await _apiClient.get(
      ApiEndpoints.proveedores,
      queryParameters: {'incluir_inactivos': incluirInactivos},
    );
    if (response is Map && response.containsKey('proveedores')) {
      final list = response['proveedores'] as List;
      return list.map((item) => SupplierModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<SupplierModel>> searchSuppliers(String query) async {
    final response = await _apiClient.get(
      ApiEndpoints.proveedoresBuscar,
      queryParameters: {'q': query},
    );
    if (response is Map && response.containsKey('proveedores')) {
      final list = response['proveedores'] as List;
      return list.map((item) => SupplierModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<int> createSupplier(SupplierModel supplier) async {
    final response = await _apiClient.post(
      ApiEndpoints.proveedores,
      body: supplier.toJson(),
    );
    return response['proveedor_id'] as int;
  }

  Future<void> updateSupplier(int id, Map<String, dynamic> changes) async {
    await _apiClient.patch(ApiEndpoints.proveedorDetalle(id), body: changes);
  }
}
