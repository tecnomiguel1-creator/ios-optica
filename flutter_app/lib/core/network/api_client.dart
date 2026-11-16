import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Cliente HTTP robusto para ONLY EYES 360
/// Diseñado para interactuar de forma segura con el backend FastAPI
class ApiClient {
  final http.Client _client;
  final ITokenStorage _storage;

  ApiClient({http.Client? client, ITokenStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? SecureTokenStorage();

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final base = AppConfig.baseUrl.endsWith('/')
        ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
        : AppConfig.baseUrl;

    final urlString = '$base$path';
    final uri = Uri.parse(urlString);

    if (queryParameters != null && queryParameters.isNotEmpty) {
      final sanitizedParams = <String, String>{};
      queryParameters.forEach((key, value) {
        if (value != null) {
          sanitizedParams[key] = value.toString();
        }
      });
      return uri.replace(queryParameters: sanitizedParams);
    }

    return uri;
  }

  Future<Map<String, String>> _buildHeaders({
    bool requiresAuth = true,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (extraHeaders != null) headers.addAll(extraHeaders);
    return headers;
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .get(uri, headers: headers)
          .timeout(AppConfig.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message:
            'No se pudo conectar al servidor backend. Verifica que FastAPI esté iniciado en ${AppConfig.baseUrl}.',
        statusCode: 503,
      );
    } on TimeoutException {
      throw ApiException(
        message: 'Tiempo de espera agotado al conectar con el servidor.',
        statusCode: 408,
      );
    }
  }

  /// Descarga archivos binarios autenticados, por ejemplo PDFs comerciales.
  Future<List<int>> getBytes(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final headers = await _buildHeaders(
        requiresAuth: requiresAuth,
        extraHeaders: {'Accept': 'application/pdf'},
      );
      final response = await _client
          .get(uri, headers: headers)
          .timeout(AppConfig.receiveTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }
      _handleResponse(response);
      throw StateError('Respuesta binaria inesperada.');
    } on SocketException {
      throw ApiException(
        message: 'No se pudo conectar al servidor para descargar el PDF.',
        statusCode: 503,
      );
    } on TimeoutException {
      throw ApiException(
        message: 'Tiempo de espera agotado al descargar el PDF.',
        statusCode: 408,
      );
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    bool requiresAuth = true,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path);
      final requestHeaders = await _buildHeaders(
        requiresAuth: requiresAuth,
        extraHeaders: headers,
      );

      final response = await _client
          .post(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(AppConfig.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message:
            'No se pudo conectar al servidor backend. Verifica la conexión a ${AppConfig.baseUrl}.',
        statusCode: 503,
      );
    } on TimeoutException {
      throw ApiException(
        message: 'Tiempo de espera agotado al enviar la solicitud.',
        statusCode: 408,
      );
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(path);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(AppConfig.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Error de conexión con el backend en $path.',
        statusCode: 503,
      );
    } on TimeoutException {
      throw ApiException(
        message: 'Tiempo de espera agotado.',
        statusCode: 408,
      );
    }
  }

  Future<dynamic> delete(
    String path, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = _buildUri(path);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .delete(uri, headers: headers)
          .timeout(AppConfig.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Error de conexión al intentar eliminar recurso.',
        statusCode: 503,
      );
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic responseBody;
    try {
      if (response.body.isNotEmpty) {
        responseBody = jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {
      responseBody = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    }

    String errorMessage = 'Error en la solicitud (${response.statusCode})';
    if (responseBody is Map && responseBody.containsKey('detail')) {
      final detail = responseBody['detail'];
      if (detail is String) {
        errorMessage = detail;
      } else if (detail is List) {
        errorMessage = detail.map((e) => e['msg'] ?? e.toString()).join(', ');
      }
    }

    throw ApiException(
      message: errorMessage,
      statusCode: response.statusCode,
      details: responseBody,
    );
  }
}
