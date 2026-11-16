import 'package:flutter_test/flutter_test.dart';
import 'package:only_eyes_360/screens/sales/payment_split.dart';

void main() {
  group('PaymentSplit', () {
    test('divide tarjeta y efectivo y descuenta la devuelta del pago enviado',
        () {
      final split = PaymentSplit(total: 100, cash: 50, card: 60, transfer: 0);

      expect(split.isValid, isTrue);
      expect(split.change, 10);
      expect(split.appliedCash, 40);
      expect(split.backendPayments, [
        {
          'monto': 40.0,
          'metodo_pago': 'efectivo',
          'monto_recibido': 50.0,
          'cambio': 10.0,
        },
        {'monto': 60.0, 'metodo_pago': 'tarjeta'},
      ]);
    });

    test('admite tarjeta y transferencia sin efectivo', () {
      final split =
          PaymentSplit(total: 125.50, cash: 0, card: 50, transfer: 75.50);

      expect(split.isValid, isTrue);
      expect(split.change, 0);
      expect(split.backendPayments.length, 2);
    });

    test(
        'pago exacto no genera cambio y efectivo mayor genera sólo su diferencia',
        () {
      final exacto = PaymentSplit(total: 200, cash: 200, card: 0, transfer: 0);
      final conCambio =
          PaymentSplit(total: 200, cash: 2000, card: 0, transfer: 0);
      final mixto = PaymentSplit(total: 200, cash: 150, card: 100, transfer: 0);

      expect(exacto.change, 0);
      expect(conCambio.change, 1800);
      expect(conCambio.backendPayments.single['monto'], 200.0);
      expect(mixto.change, 50);
      expect(mixto.backendPayments, [
        {
          'monto': 100.0,
          'metodo_pago': 'efectivo',
          'monto_recibido': 150.0,
          'cambio': 50.0,
        },
        {'monto': 100.0, 'metodo_pago': 'tarjeta'},
      ]);
    });

    test('rechaza faltantes y exceso que no se puede devolver en efectivo', () {
      final faltante =
          PaymentSplit(total: 100, cash: 20, card: 30, transfer: 0);
      final nonCashExcess =
          PaymentSplit(total: 100, cash: 0, card: 101, transfer: 0);

      expect(faltante.isValid, isFalse);
      expect(faltante.validationMessage, contains('Faltan'));
      expect(nonCashExcess.isValid, isFalse);
      expect(nonCashExcess.validationMessage, contains('devuelta'));
    });
  });
}
