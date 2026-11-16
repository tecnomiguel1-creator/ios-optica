import 'package:shared_preferences/shared_preferences.dart';

import 'mobile_sync_config.dart';

// ONLY EYES 360 - Configuración Centralizada de la Aplicación
// Permite configurar la URL del backend dinámicamente o por variables de entorno

class AppConfig {
  static const String appName = 'ONLY EYES 360';
  static const String appVersion = '1.0.0';
  static const String appSubtitle = 'Sistema de Gestión Integral para Ópticas';

  // URL base por defecto del backend FastAPI
  // En Windows Desktop: 127.0.0.1:8000
  // En Android Emulator: 10.0.2.2:8000
  // En dispositivo físico: IP local (ej. 192.168.1.X:8000)
  static String baseUrl = MobileSyncConfig.localBackendUrl.isNotEmpty
      ? MobileSyncConfig.localBackendUrl
      : 'http://127.0.0.1:8000';
  static double itbisRate = 0.18;

  // Datos comerciales oficiales configurables (sin valores ficticios por defecto)
  static String companyRnc = '';
  static String companyAddress = '';
  static String companyPhone = '';

  // Catálogo de aseguradoras ARS privadas de referencia (configurable)
  static List<String> arsList = [
    'Primera ARS de Humano',
    'Mapfre Salud ARS',
    'ARS Universal',
    'ARS Monumental',
    'ARS Renacer',
    'ARS Simag',
    'ARS GMA (Grupo Médico Asociado)',
    'ARS Futuro',
    'ARS Yunen',
  ];

  // Configuración de timeouts de red
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 25);

  // Claves de almacenamiento
  static const String tokenKey = 'jwt_access_token';
  static const String userKey = 'current_user_profile';
  static const String baseUrlKey = 'custom_base_url';
  static const String itbisRateKey = 'itbis_rate';
  static const String companyRncKey = 'company_rnc';
  static const String companyAddressKey = 'company_address';
  static const String companyPhoneKey = 'company_phone';
  static const String arsListKey = 'ars_custom_list';

  static Future<void> loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(baseUrlKey);
    if (savedUrl != null && savedUrl.trim().isNotEmpty) setBaseUrl(savedUrl);
    final savedRate = prefs.getDouble(itbisRateKey);
    if (savedRate != null && savedRate >= 0 && savedRate <= 1) {
      itbisRate = savedRate;
    }
    companyRnc = prefs.getString(companyRncKey) ?? '';
    companyAddress = prefs.getString(companyAddressKey) ?? '';
    companyPhone = prefs.getString(companyPhoneKey) ?? '';

    final savedArs = prefs.getStringList(arsListKey);
    if (savedArs != null && savedArs.isNotEmpty) {
      arsList = savedArs;
    }
  }

  static Future<void> saveArsList(List<String> list) async {
    arsList = List<String>.from(list);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(arsListKey, arsList);
  }

  static Future<void> saveBusinessProfile({
    required String rnc,
    required String address,
    required String phone,
  }) async {
    companyRnc = rnc.trim();
    companyAddress = address.trim();
    companyPhone = phone.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(companyRncKey, companyRnc);
    await prefs.setString(companyAddressKey, companyAddress);
    await prefs.setString(companyPhoneKey, companyPhone);
  }

  // Opciones de configuración de entorno
  static void setBaseUrl(String url) {
    if (url.endsWith('/')) {
      baseUrl = url.substring(0, url.length - 1);
    } else {
      baseUrl = url;
    }
  }

  static Future<void> saveBaseUrl(String url) async {
    setBaseUrl(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(baseUrlKey, baseUrl);
  }

  static Future<void> saveItbisRate(double rate) async {
    if (rate < 0 || rate > 1) throw ArgumentError.value(rate, 'rate');
    itbisRate = rate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(itbisRateKey, rate);
  }
}
