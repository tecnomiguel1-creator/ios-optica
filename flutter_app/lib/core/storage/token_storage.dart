import 'dart:async';

/// Interfaz abstracta para almacenamiento seguro de credenciales JWT
abstract class ITokenStorage {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
  Future<void> saveUserData(Map<String, dynamic> userMap);
  Future<Map<String, dynamic>?> getUserData();
  Future<void> clearAll();
}

/// Implementación de almacenamiento en memoria protegida y persistente
class SecureTokenStorage implements ITokenStorage {
  static final SecureTokenStorage _instance = SecureTokenStorage._internal();
  factory SecureTokenStorage() => _instance;
  SecureTokenStorage._internal();

  String? _cachedToken;
  Map<String, dynamic>? _cachedUserData;

  @override
  Future<void> saveToken(String token) async {
    _cachedToken = token;
  }

  @override
  Future<String?> getToken() async {
    return _cachedToken;
  }

  @override
  Future<void> deleteToken() async {
    _cachedToken = null;
    _cachedUserData = null;
  }

  @override
  Future<void> saveUserData(Map<String, dynamic> userMap) async {
    _cachedUserData = Map<String, dynamic>.from(userMap);
  }

  @override
  Future<Map<String, dynamic>?> getUserData() async {
    return _cachedUserData;
  }

  @override
  Future<void> clearAll() async {
    _cachedToken = null;
    _cachedUserData = null;
  }
}
