import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/prescription_model.dart';

class PrescriptionService {
  final ApiClient _apiClient;

  PrescriptionService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<List<PrescriptionModel>> getPrescriptions() async {
    final response = await _apiClient.get(ApiEndpoints.recetas);
    if (response is Map && response.containsKey('recetas')) {
      final list = response['recetas'] as List;
      return list
          .map((item) => PrescriptionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<PrescriptionModel>> getPrescriptionsByPatient(int pacienteId) async {
    final response =
        await _apiClient.get(ApiEndpoints.recetasPorPaciente(pacienteId));
    if (response is Map && response.containsKey('recetas')) {
      final list = response['recetas'] as List;
      return list
          .map((item) => PrescriptionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<int> createPrescription(PrescriptionModel prescription) async {
    final response = await _apiClient.post(
      ApiEndpoints.recetas,
      body: prescription.toJson(),
    );
    return response['receta_id'] as int;
  }

  Future<PrescriptionModel> getPrescriptionById(int id) async {
    final response = await _apiClient.get(ApiEndpoints.recetaDetalle(id));
    return PrescriptionModel.fromJson(response as Map<String, dynamic>);
  }
}
