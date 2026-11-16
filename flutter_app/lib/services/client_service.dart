import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/client_model.dart';

class ClientService {
  final ApiClient _apiClient;

  ClientService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<ClientModel>> getClients() async {
    final response = await _apiClient.get(ApiEndpoints.clientes);
    if (response is Map && response.containsKey('clientes')) {
      final list = response['clientes'] as List;
      return list.map((item) => ClientModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<ClientModel>> searchClients(String query) async {
    final response = await _apiClient.get(
      ApiEndpoints.clientesBuscar,
      queryParameters: {'q': query},
    );
    if (response is Map && response.containsKey('clientes')) {
      final list = response['clientes'] as List;
      return list.map((item) => ClientModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<ClientModel> getClientById(int id) async {
    final response = await _apiClient.get(ApiEndpoints.clienteDetalle(id));
    return ClientModel.fromJson(response as Map<String, dynamic>);
  }

  Future<int> createClient({
    required String nombres,
    String? apellidos,
    String? telefono,
    String? correo,
    String? direccion,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.clientes,
      body: {
        'nombres': nombres,
        if (apellidos != null && apellidos.isNotEmpty) 'apellidos': apellidos,
        if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
        if (correo != null && correo.isNotEmpty) 'correo': correo,
        if (direccion != null && direccion.isNotEmpty) 'direccion': direccion,
      },
    );
    return response['cliente_id'] as int;
  }

  Future<void> updateClient(
    int id, {
    String? nombres,
    String? apellidos,
    String? telefono,
    String? correo,
    String? direccion,
  }) async {
    final body = <String, dynamic>{};
    if (nombres != null) body['nombres'] = nombres;
    if (apellidos != null) body['apellidos'] = apellidos;
    if (telefono != null) body['telefono'] = telefono;
    if (correo != null) body['correo'] = correo;
    if (direccion != null) body['direccion'] = direccion;

    await _apiClient.patch(ApiEndpoints.clienteDetalle(id), body: body);
  }
}
