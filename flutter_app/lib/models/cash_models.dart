class CashMovementModel {
  final int id;
  final String type;
  final String origin;
  final double amount;
  final String concept;
  final String? reference;
  final String createdAt;

  const CashMovementModel(
      {required this.id,
      required this.type,
      required this.origin,
      required this.amount,
      required this.concept,
      this.reference,
      required this.createdAt});

  factory CashMovementModel.fromJson(Map<String, dynamic> json) =>
      CashMovementModel(
        id: (json['id'] as num).toInt(),
        type: json['tipo'] as String,
        origin: json['origen'] as String,
        amount: (json['monto'] as num).toDouble(),
        concept: json['concepto'] as String,
        reference: json['referencia'] as String?,
        createdAt: json['creado_en']?.toString() ?? '',
      );
}

class CashShiftModel {
  final int id;
  final double openingFloat;
  final String openedAt;
  final String status;
  final List<CashMovementModel> movements;
  final double expectedBalance;
  final Map<String, double> paymentTotals;

  const CashShiftModel(
      {required this.id,
      required this.openingFloat,
      required this.openedAt,
      required this.status,
      required this.movements,
      required this.expectedBalance,
      required this.paymentTotals});

  factory CashShiftModel.fromJson(Map<String, dynamic> json) {
    final shift = json['turno'] as Map<String, dynamic>;
    final summary = json['resumen'] as Map<String, dynamic>? ?? const {};
    final methods = <String, double>{};
    for (final entry in (summary['pagos_no_efectivo'] as List? ?? const [])) {
      final row = entry as Map<String, dynamic>;
      methods[row['metodo_pago']?.toString() ?? 'otro'] =
          (row['total'] as num?)?.toDouble() ?? 0;
    }
    return CashShiftModel(
      id: (shift['id'] as num).toInt(),
      openingFloat: (shift['fondo_inicial'] as num).toDouble(),
      openedAt: shift['abierto_en']?.toString() ?? '',
      status: shift['estado'] as String? ?? 'abierta',
      movements: ((json['movimientos'] as List?) ?? const [])
          .map((e) => CashMovementModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      expectedBalance: (json['saldo_esperado'] as num).toDouble(),
      paymentTotals: methods,
    );
  }
}
