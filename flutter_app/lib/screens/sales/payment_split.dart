/// Reglas puras del cobro POS. Todos los cálculos se hacen en centavos para
/// evitar errores de punto flotante al dividir pagos y calcular devuelta.
class PaymentSplit {
  final int totalCents;
  final int cashCents;
  final int cardCents;
  final int transferCents;

  PaymentSplit({
    required double total,
    required double cash,
    required double card,
    required double transfer,
  })  : totalCents = _toCents(total),
        cashCents = _toCents(cash),
        cardCents = _toCents(card),
        transferCents = _toCents(transfer);

  static int _toCents(double amount) => (amount * 100).round();
  static double _toAmount(int cents) => cents / 100.0;

  int get nonCashCents => cardCents + transferCents;
  int get receivedCents => cashCents + nonCashCents;
  int get cashRequiredCents => totalCents > nonCashCents ? totalCents - nonCashCents : 0;
  int get changeCents => cashCents > cashRequiredCents ? cashCents - cashRequiredCents : 0;
  int get appliedCashCents => cashCents < cashRequiredCents ? cashCents : cashRequiredCents;

  double get total => _toAmount(totalCents);
  double get cashRequired => _toAmount(cashRequiredCents);
  double get change => _toAmount(changeCents);
  double get appliedCash => _toAmount(appliedCashCents);
  double get received => _toAmount(receivedCents);

  bool get hasNonCashExcess => nonCashCents > totalCents;
  bool get coversTotal => receivedCents >= totalCents;
  bool get isValid => totalCents > 0 && !hasNonCashExcess && coversTotal;

  String? get validationMessage {
    if (totalCents <= 0) return 'Agrega productos antes de cobrar.';
    if (hasNonCashExcess) {
      return 'Tarjeta y transferencia no pueden superar el total; la devuelta solo se entrega en efectivo.';
    }
    if (!coversTotal) {
      return 'Faltan RD\$ ${_toAmount(totalCents - receivedCents).toStringAsFixed(2)} para completar el cobro.';
    }
    return null;
  }

  /// Payload para el endpoint normal o para pagos mixtos. El efectivo enviado
  /// excluye la devuelta, de modo que la suma persiste exactamente el total.
  List<Map<String, dynamic>> get backendPayments {
    if (!isValid) return const [];
    final payments = <Map<String, dynamic>>[];
    if (appliedCashCents > 0) {
      payments.add({
        'monto': appliedCash,
        'metodo_pago': 'efectivo',
        'monto_recibido': _toAmount(cashCents),
        'cambio': change,
      });
    }
    if (cardCents > 0) {
      payments.add({'monto': _toAmount(cardCents), 'metodo_pago': 'tarjeta'});
    }
    if (transferCents > 0) {
      payments.add({'monto': _toAmount(transferCents), 'metodo_pago': 'transferencia'});
    }
    return payments;
  }
}
