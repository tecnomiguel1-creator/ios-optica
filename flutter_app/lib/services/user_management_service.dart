import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/user_model.dart';

/// Administración de cuentas internas. Las contraseñas sólo viajan al crear
/// una cuenta y nunca se guardan ni se vuelven a solicitar desde la interfaz.
class UserManagementService {
  final ApiClient _apiClient;

  UserManagementService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<UserModel>> getUsers() async {
    final response = await _apiClient.get(ApiEndpoints.usuarios);
    final users = (response as Map<String, dynamic>)['usuarios'] as List? ?? [];
    return users
        .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<UserModel> createUser({
    required String nombre,
    required String usuario,
    required String contrasena,
    required String rol,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.usuarios,
      body: {
        'nombre': nombre,
        'usuario': usuario,
        'contrasena': contrasena,
        'rol': rol,
      },
    );
    return UserModel.fromJson(response as Map<String, dynamic>);
  }
}
