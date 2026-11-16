import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/cash_models.dart';

class CashService {
  final ApiClient _api;
  CashService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<CashShiftModel?> getCurrent() async {
    final data =
        await _api.get(ApiEndpoints.cajaActual) as Map<String, dynamic>;
    return data['turno'] == null ? null : CashShiftModel.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final data = await _api.get('/api/caja/historial') as Map<String, dynamic>;
    return ((data['turnos'] as List?) ?? const [])
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<Map<String, dynamic>> open(
      {required double openingFloat,
      String? notes,
      String? idempotencyKey}) async {
    return (await _api.post(ApiEndpoints.cajaAperturas, headers: {
      if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
    }, body: {
      'fondo_inicial': openingFloat,
      if (notes != null && notes.trim().isNotEmpty)
        'observaciones': notes.trim(),
    })) as Map<String, dynamic>;
  }

  Future<void> addMovement(
      {required String type,
      required double amount,
      required String concept,
      String? reference}) async {
    await _api.post(ApiEndpoints.cajaMovimientos, body: {
      'tipo': type,
      'monto': amount,
      'concepto': concept,
      if (reference != null && reference.trim().isNotEmpty)
        'referencia': reference.trim(),
    });
  }

  Future<Map<String, dynamic>> close(
          {required double countedAmount, String? notes}) async =>
      (await _api.post(ApiEndpoints.cajaCierre, body: {
        'monto_contado': countedAmount,
        if (notes != null && notes.trim().isNotEmpty)
          'observaciones': notes.trim(),
      })) as Map<String, dynamic>;

  Future<File> saveCloseReceipt(int shiftId) async {
    final bytes = await _api.getBytes(ApiEndpoints.cajaComprobantePdf(shiftId));
    final directory = await getApplicationDocumentsDirectory();
    final file =
        File('${directory.path}${Platform.pathSeparator}CIERRE-$shiftId.pdf');
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<void> openSavedReceipt(File file) async {
    final result = await OpenFilex.open(file.path, type: 'application/pdf');
    if (result.type != ResultType.done) throw StateError(result.message);
  }

  Future<Map<String, dynamic>> issueCommercialInvoice(int saleId) async =>
      (await _api.post(ApiEndpoints.facturaComercial(saleId)))
          as Map<String, dynamic>;
}
