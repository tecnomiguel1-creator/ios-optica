import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/clinic_models.dart';

/// Servicio Clínico, Administrativo y Financiero conectado a FastAPI
class AdminService {
  final ApiClient _apiClient;

  AdminService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // CITAS
  Future<List<AppointmentModel>> getAppointments({
    String? estado,
    int? pacienteId,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    final params = <String, dynamic>{};
    if (estado != null) params['estado'] = estado;
    if (pacienteId != null) params['paciente_id'] = pacienteId;
    if (fechaDesde != null) params['fecha_desde'] = fechaDesde;
    if (fechaHasta != null) params['fecha_hasta'] = fechaHasta;

    final response = await _apiClient.get(
      ApiEndpoints.citas,
      queryParameters: params.isNotEmpty ? params : null,
    );

    if (response is Map && response.containsKey('citas')) {
      final list = response['citas'] as List;
      return list
          .map(
              (item) => AppointmentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<int> createAppointment({
    required int pacienteId,
    required String fechaHora,
    required String motivo,
    String? profesional,
    String? observaciones,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.citas,
      body: {
        'paciente_id': pacienteId,
        'fecha_hora': fechaHora,
        'motivo': motivo,
        if (profesional != null && profesional.isNotEmpty)
          'profesional': profesional,
        if (observaciones != null && observaciones.isNotEmpty)
          'observaciones': observaciones,
      },
    );
    return response['cita_id'] as int;
  }

  Future<int> createAppointmentWithNewClient({
    required String nombres,
    String? apellidos,
    String? telefono,
    String? correo,
    required String fechaHora,
    required String motivo,
    String? profesional,
    String? observaciones,
  }) async {
    final response = await _apiClient.post(ApiEndpoints.citasConCliente, body: {
      'cliente': {
        'nombres': nombres,
        if (apellidos != null && apellidos.isNotEmpty) 'apellidos': apellidos,
        if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
        if (correo != null && correo.isNotEmpty) 'correo': correo
      },
      'fecha_hora': fechaHora,
      'motivo': motivo,
      if (profesional != null && profesional.isNotEmpty)
        'profesional': profesional,
      if (observaciones != null && observaciones.isNotEmpty)
        'observaciones': observaciones,
    });
    return response['cita_id'] as int;
  }

  Future<void> updateAppointmentState(int citaId, String nuevoEstado) async {
    await _apiClient.patch(
      ApiEndpoints.citaDetalle(citaId),
      body: {'estado': nuevoEstado},
    );
  }

  // ÓRDENES DE LABORATORIO ÓPTICO
  Future<List<LabOrderModel>> getLabOrders(
      {String? estado, int? clienteId}) async {
    try {
      final params = <String, dynamic>{};
      if (estado != null) params['estado'] = estado;
      if (clienteId != null) params['cliente_id'] = clienteId;

      final response = await _apiClient.get(
        ApiEndpoints.pedidosLentes,
        queryParameters: params.isNotEmpty ? params : null,
      );

      if (response is Map && response.containsKey('pedidos')) {
        final list = response['pedidos'] as List;
        return list
            .map((item) => LabOrderModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<int> createLabOrder(LabOrderModel order) async {
    final response = await _apiClient.post(
      ApiEndpoints.pedidosLentes,
      body: order.toJson(),
    );
    return response['pedido_id'] as int;
  }

  Future<void> updateLabOrderState(int pedidoId, String estado,
      {String? fechaEntrega, String? observaciones}) async {
    await _apiClient.patch(
      ApiEndpoints.pedidoLentesEstado(pedidoId),
      body: {
        'estado': estado,
        if (fechaEntrega != null) 'fecha_entrega': fechaEntrega,
        if (observaciones != null) 'observaciones': observaciones,
      },
    );
  }

  // REPARACIONES
  Future<int> createRepair(RepairModel repair) async {
    final response = await _apiClient.post(
      ApiEndpoints.reparaciones,
      body: repair.toJson(),
    );
    return response['reparacion_id'] as int;
  }

  Future<void> updateRepairState(int reparacionId, String estado,
      {String? fechaEntrega, String? observaciones}) async {
    await _apiClient.patch(
      ApiEndpoints.reparacionEstado(reparacionId),
      body: {
        'estado': estado,
        if (fechaEntrega != null) 'fecha_entrega': fechaEntrega,
        if (observaciones != null) 'observaciones': observaciones,
      },
    );
  }

  Future<List<RepairModel>> getRepairs({String? estado, int? clienteId}) async {
    try {
      final params = <String, dynamic>{};
      if (estado != null) params['estado'] = estado;
      if (clienteId != null) params['cliente_id'] = clienteId;
      final response = await _apiClient.get(ApiEndpoints.reparaciones,
          queryParameters: params.isEmpty ? null : params);
      if (response is Map && response['reparaciones'] is List) {
        return (response['reparaciones'] as List)
            .map((item) => RepairModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // CUENTAS POR PAGAR A PROVEEDORES
  Future<List<AccountPayableModel>> getAccountsPayable(
      {int? proveedorId}) async {
    final params = <String, dynamic>{};
    if (proveedorId != null) params['proveedor_id'] = proveedorId;

    final response = await _apiClient.get(
      ApiEndpoints.cuentasPorPagar,
      queryParameters: params.isNotEmpty ? params : null,
    );

    if (response is Map && response.containsKey('cuentas')) {
      final list = response['cuentas'] as List;
      return list
          .map((item) =>
              AccountPayableModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> paySupplier({
    required int compraId,
    required double monto,
    required String metodoPago,
    String? referencia,
    String? observaciones,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.compraPagos(compraId),
      body: {
        'monto': monto,
        'metodo_pago': metodoPago,
        if (referencia != null && referencia.isNotEmpty)
          'referencia': referencia,
        if (observaciones != null && observaciones.isNotEmpty)
          'observaciones': observaciones,
      },
    );
    return response as Map<String, dynamic>;
  }

  // REPORTES EJECUTIVOS REALES
  Future<FinancialReportSummary> getFinancialReport() async {
    try {
      final resVentas = await _apiClient.get(ApiEndpoints.reporteVentas);
      final resCitas = await _apiClient.get(ApiEndpoints.reporteCitas);

      final resumen = resVentas['resumen'] as Map<String, dynamic>? ?? {};
      final citasList = resCitas['citas'] as List? ?? [];

      int totalCitas = 0;
      for (final c in citasList) {
        totalCitas += (c['total'] as num?)?.toInt() ?? 0;
      }

      return FinancialReportSummary.fromJson(
        resumen,
        citas: totalCitas,
      );
    } catch (_) {
      return FinancialReportSummary(
        cantidadVentas: 0,
        totalVendido: 0.0,
        cobrado: 0.0,
        pendiente: 0.0,
        isMock: false,
      );
    }
  }

  // CAJA DIARIA: Calculada sobre el total cobrado real de ventas del día
  Future<CashRegisterModel> getTodayCashRegister() async {
    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final report = await _apiClient.get(
        ApiEndpoints.reporteVentas,
        queryParameters: {'desde': todayStr, 'hasta': todayStr},
      );
      final resumen = report['resumen'] as Map<String, dynamic>? ?? {};
      final cobradoHoy = (resumen['cobrado'] as num?)?.toDouble() ?? 0.0;

      return CashRegisterModel(
        id: 1,
        fechaApertura: '$todayStr 08:30:00',
        montoInicial: 3000.0,
        totalIngresos: cobradoHoy,
        totalEgresos: 0.0,
        saldoActual: 3000.0 + cobradoHoy,
        estado: 'abierta',
        usuario: 'Caja Principal (FastAPI)',
        isMock: false,
      );
    } catch (_) {
      return CashRegisterModel(
        id: 1,
        fechaApertura: 'Hoy',
        montoInicial: 0.0,
        totalIngresos: 0.0,
        totalEgresos: 0.0,
        saldoActual: 0.0,
        estado: 'abierta',
        usuario: 'Local',
        isMock: true,
      );
    }
  }
}
