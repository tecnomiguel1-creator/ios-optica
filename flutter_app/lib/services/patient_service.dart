import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/patient_model.dart';
import '../models/prescription_model.dart';

class PatientService {
  final ApiClient _apiClient;

  PatientService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<PatientModel>> getPatients() async {
    final response = await _apiClient.get(ApiEndpoints.pacientes);
    if (response is Map && response.containsKey('pacientes')) {
      final list = response['pacientes'] as List;
      return list.map((item) => PatientModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<PatientModel>> searchPatients(String query) async {
    final response = await _apiClient.get(
      ApiEndpoints.pacientesBuscar,
      queryParameters: {'q': query},
    );
    if (response is Map && response.containsKey('pacientes')) {
      final list = response['pacientes'] as List;
      return list.map((item) => PatientModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<PatientModel> getPatientById(int id) async {
    final response = await _apiClient.get(ApiEndpoints.pacienteDetalle(id));
    return PatientModel.fromJson(response as Map<String, dynamic>);
  }

  Future<int> createPatient({
    required int clienteId,
    String? fechaNacimiento,
    String? antecedentes,
    String? alergias,
    String? observaciones,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.pacientes,
      body: {
        'cliente_id': clienteId,
        if (fechaNacimiento != null && fechaNacimiento.isNotEmpty)
          'fecha_nacimiento': fechaNacimiento,
        if (antecedentes != null && antecedentes.isNotEmpty)
          'antecedentes': antecedentes,
        if (alergias != null && alergias.isNotEmpty) 'alergias': alergias,
        if (observaciones != null && observaciones.isNotEmpty)
          'observaciones': observaciones,
      },
    );
    return response['paciente_id'] as int;
  }

  Future<void> updatePatient(
    int id, {
    String? fechaNacimiento,
    String? antecedentes,
    String? alergias,
    String? observaciones,
  }) async {
    final body = <String, dynamic>{};
    if (fechaNacimiento != null) body['fecha_nacimiento'] = fechaNacimiento;
    if (antecedentes != null) body['antecedentes'] = antecedentes;
    if (alergias != null) body['alergias'] = alergias;
    if (observaciones != null) body['observaciones'] = observaciones;

    await _apiClient.patch(ApiEndpoints.pacienteDetalle(id), body: body);
  }

  Future<Map<String, dynamic>> getPatientHistory(int id) async {
    final response = await _apiClient.get(ApiEndpoints.pacienteHistorial(id));
    final map = response as Map<String, dynamic>;
    final recetasJson = map['recetas'] as List? ?? [];
    final citasJson = map['citas'] as List? ?? [];

    return {
      'recetas': recetasJson
          .map((r) => PrescriptionModel.fromJson(r as Map<String, dynamic>))
          .toList(),
      'citas': citasJson,
    };
  }
}
