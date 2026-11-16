import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';

/// Sincroniza los datos que se muestran en los comprobantes comerciales.
class BusinessProfileService {
  final ApiClient _api;
  BusinessProfileService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<void> save({
    required String nombreComercial,
    required String eslogan,
    required String rnc,
    required String direccion,
    required String telefono,
  }) async {
    await _api.post(ApiEndpoints.datosNegocio, body: {
      'nombre_comercial': nombreComercial,
      'eslogan': eslogan,
      'rnc': rnc,
      'direccion': direccion,
      'telefono': telefono,
    });
  }
}
