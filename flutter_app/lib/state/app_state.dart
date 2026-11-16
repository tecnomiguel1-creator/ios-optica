import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/inventory_service.dart';

enum AppSection {
  dashboard,
  patients,
  inventory,
  purchases,
  sales,
  appointments,
  labOrders,
  cashRegister,
  settings,
  businessData,
  insurance,
  accountsPayable,
  reports,
}

class AppState extends ChangeNotifier {
  final AuthService _authService;
  final InventoryService _inventoryService;
  final ApiClient _apiClient;

  AppState({
    AuthService? authService,
    InventoryService? inventoryService,
    ApiClient? apiClient,
  })  : _authService = authService ?? AuthService(),
        _inventoryService = inventoryService ?? InventoryService(),
        _apiClient = apiClient ?? ApiClient();

  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  AppSection _activeSection = AppSection.dashboard;
  int _lowStockCount = 0;
  bool _isBackendConnected = false;
  String? _connectionError;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  AppSection get activeSection => _activeSection;
  int get lowStockCount => _lowStockCount;
  bool get isBackendConnected => _isBackendConnected;
  String? get connectionError => _connectionError;

  void setActiveSection(AppSection section) {
    if (_activeSection != section) {
      _activeSection = section;
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AppConfig.loadLocalSettings();
      await checkBackendConnection();
      final hasToken = await _authService.isLoggedIn();
      if (hasToken) {
        try {
          _currentUser = await _authService.getMe();
          _isAuthenticated = true;
          await refreshLowStockCount();
        } catch (_) {
          // Si el token expiró o falló
          await _authService.logout();
          _isAuthenticated = false;
          _currentUser = null;
        }
      } else {
        _isAuthenticated = false;
        _currentUser = null;
      }
    } catch (e) {
      _connectionError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkBackendConnection() async {
    _connectionError = 'Iniciando servidor local...';
    notifyListeners();
    for (var attempt = 0; attempt < 6; attempt++) {
      try {
        final res =
            await _apiClient.get(ApiEndpoints.health, requiresAuth: false);
        _isBackendConnected = res is Map && res['status'] == 'ok';
        if (_isBackendConnected) {
          _connectionError = null;
          notifyListeners();
          return true;
        }
        _connectionError =
            'Servidor iniciado; esperando conexión con la base de datos...';
      } catch (_) {
        _isBackendConnected = false;
        _connectionError = attempt < 5
            ? 'Iniciando servidor local...'
            : 'No se pudo conectar al servidor local. Contacta soporte.';
      }
      notifyListeners();
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return false;
  }

  Future<void> login(
    String usuario,
    String contrasena, {
    bool startAtCashRegister = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final authResponse = await _authService.login(usuario, contrasena);
      _currentUser = authResponse.usuario;
      _isAuthenticated = true;
      // En Windows se mantiene el control de turno antes de operar POS. La
      // aplicación móvil es de supervisión y abre su resumen ligero.
      _activeSection =
          startAtCashRegister ? AppSection.cashRegister : AppSection.dashboard;
      await refreshLowStockCount();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _isAuthenticated = false;
    _activeSection = AppSection.dashboard;
    notifyListeners();
  }

  Future<void> refreshLowStockCount() async {
    if (!_isAuthenticated) return;
    try {
      final lowStockList = await _inventoryService.getLowStockProducts();
      _lowStockCount = lowStockList.length;
      notifyListeners();
    } catch (_) {
      // Ignora en caso de fallo de red puntual
    }
  }

  Future<void> updateBackendUrl(String newUrl) async {
    await AppConfig.saveBaseUrl(newUrl);
    await checkBackendConnection();
    notifyListeners();
  }
}
