import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:only_eyes_360/core/theme/app_theme.dart';
import 'package:only_eyes_360/core/utils/formatters.dart';
import 'package:only_eyes_360/screens/sales/insurance_coverage_card.dart';
import 'package:only_eyes_360/screens/sales/pos_screen.dart';

Widget _cartViewportUnderTest() {
  return PosCartViewport(
    header: const Text('Venta actual'),
    clientSection: const TextField(
      decoration: InputDecoration(labelText: 'Cliente (opcional)'),
    ),
    cartContent: Container(
      height: 190,
      alignment: Alignment.center,
      color: const Color(0xFFF8FAFC),
      child: const Text('Aún no hay artículos'),
    ),
    paymentAndTotals: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Cobro'),
        const SizedBox(height: 10),
        const TextField(decoration: InputDecoration(labelText: 'Efectivo')),
        const SizedBox(height: 10),
        InsuranceCoverageCard(
          totalVenta: 8500,
          onMontoAutorizadoChanged: (_) {},
          onArsChanged: (_) {},
          onNumeroAutorizacionChanged: (_) {},
        ),
        const SizedBox(height: 12),
        const Text('TOTAL A PAGAR'),
        const Text('RD\$8,500.00'),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {},
          child: const Text('Cobrar e imprimir comprobante'),
        ),
      ],
    ),
  );
}

Future<void> _pumpCartViewport(WidgetTester tester, Size surfaceSize) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: surfaceSize.width >= 1100 ? 520 : surfaceSize.width - 24,
            height: surfaceSize.height - 24,
            child: _cartViewportUnderTest(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ONLY EYES 360 - Cobertura de Seguro Médico y Formato Dominicano', () {
    test(
        'Formatters formatea moneda dominicana consistente con miles y dos decimales',
        () {
      expect(Formatters.formatCurrency(1500), 'RD\$1,500.00');
      expect(Formatters.formatCurrency(12500.5), 'RD\$12,500.50');
      expect(Formatters.formatCurrency(1000000), 'RD\$1,000,000.00');
      expect(Formatters.formatCurrency(0), 'RD\$0.00');
      expect(Formatters.formatCurrency(null), 'RD\$0.00');
    });

    testWidgets(
        'InsuranceCoverageCard inicia inactivo y se expande al activar switch',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      double montoAutorizado = 0.0;
      String? arsSeleccionada;
      String? numeroAuth;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: InsuranceCoverageCard(
                totalVenta: 8500.0,
                pagosRealizados: 0.0,
                onMontoAutorizadoChanged: (val) => montoAutorizado = val,
                onArsChanged: (val) => arsSeleccionada = val,
                onNumeroAutorizacionChanged: (val) => numeroAuth = val,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe mostrar el título del componente
      expect(find.text('Cobertura de seguro médico'), findsOneWidget);
      expect(
          find.text('Toca para aplicar autorización de ARS'), findsOneWidget);

      // Los campos de ARS aún no están visibles
      expect(find.text('Aseguradora / ARS privada *'), findsNothing);

      // Tocar el switch para activarlo
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Ahora deben aparecer los campos de seguro médico
      expect(find.text('Aseguradora / ARS privada *'), findsOneWidget);
      expect(find.text('Número de autorización'), findsOneWidget);
      expect(find.text('Monto autorizado por la ARS *'), findsOneWidget);

      // Verificamos el resumen financiero inicial
      expect(find.text('Total de la venta:'), findsOneWidget);
      expect(find.text('RD\$8,500.00'), findsWidgets);
      expect(find.text('Diferencia a pagar por el cliente:'), findsOneWidget);

      // Ingresar número de autorización
      final authField =
          find.widgetWithText(TextFormField, 'Número de autorización');
      await tester.enterText(authField, 'AUT-889900');
      await tester.pumpAndSettle();

      // Ingresar monto autorizado
      final amountField =
          find.widgetWithText(TextFormField, 'Monto autorizado por la ARS *');
      await tester.enterText(amountField, '3000.00');
      await tester.pumpAndSettle();

      expect(numeroAuth, 'AUT-889900');
      expect(arsSeleccionada, isNull);
      expect(montoAutorizado, 3000.0);
      expect(find.text('RD\$3,000.00'), findsOneWidget);
      expect(find.text('RD\$5,500.00'), findsOneWidget); // Diferencia cliente
    });

    testWidgets(
        'InsuranceCoverageCard no desborda en pantallas compactas 400x700',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: InsuranceCoverageCard(
                totalVenta: 12500.0,
                pagosRealizados: 4000.0,
                onMontoAutorizadoChanged: (_) {},
                onArsChanged: (_) {},
                onNumeroAutorizacionChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Activar switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Sin desbordamientos de RenderFlex
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'POS evita el desbordamiento de 71 píxeles en ventana intermedia',
        (tester) async {
      await _pumpCartViewport(tester, const Size(1024, 640));

      expect(find.text('Aún no hay artículos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('POS evita el desbordamiento de 81 píxeles en escritorio',
        (tester) async {
      await _pumpCartViewport(tester, const Size(1366, 768));

      await tester.ensureVisible(find.text('Cobrar e imprimir comprobante'));
      expect(find.text('TOTAL A PAGAR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'POS permite desplazar ARS sin el desbordamiento de 309 píxeles',
        (tester) async {
      await _pumpCartViewport(tester, const Size(800, 600));

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Cobrar e imprimir comprobante'));

      expect(find.text('Monto autorizado por la ARS *'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
