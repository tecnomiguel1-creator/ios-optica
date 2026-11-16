import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/storage/token_storage.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient;
  final ITokenStorage _storage;

  AuthService({ApiClient? apiClient, ITokenStorage? storage})
      : _apiClient = apiClient ?? ApiClient(),
        _storage = storage ?? SecureTokenStorage();

  Future<AuthResponse> login(String usuario, String contrasena) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      body: {
        'usuario': usuario,
        'contrasena': contrasena,
      },
      requiresAuth: false,
    );

    final authResponse = AuthResponse.fromJson(response as Map<String, dynamic>);
    await _storage.saveToken(authResponse.accessToken);
    await _storage.saveUserData(authResponse.usuario.toJson());

    return authResponse;
  }

  Future<UserModel> getMe() async {
    final response = await _apiClient.get(ApiEndpoints.me);
    final user = UserModel.fromJson(response as Map<String, dynamic>);
    await _storage.saveUserData(user.toJson());
    return user;
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<UserModel?> getSavedUser() async {
    final data = await _storage.getUserData();
    if (data != null) {
      return UserModel.fromJson(data);
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }
}
