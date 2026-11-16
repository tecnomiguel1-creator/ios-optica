import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:only_eyes_360/core/theme/app_theme.dart';
import 'package:only_eyes_360/models/clinic_models.dart';
import 'package:only_eyes_360/models/sale_model.dart';
import 'package:only_eyes_360/screens/clients/client_form_dialog.dart';
import 'package:only_eyes_360/screens/inventory/product_form_dialog.dart';
import 'package:only_eyes_360/screens/sales/commercial_invoice_dialog.dart';

void main() {
  group('ONLY EYES 360 - Pruebas de Formularios, Taller y Facturas Comerciales', () {
    testWidgets('CommercialInvoiceDialog no desborda en ventana compacta 800x600', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testSale = SaleModel(
        id: 99,
        numeroFactura: 'FAC-2026-0099',
        clienteNombre: 'Carmen Santana',
        fechaVenta: '2026-11-05',
        subtotal: 5000.0,
        impuestos: 900.0,
        total: 5900.0,
        metodoPago: 'efectivo',
        estadoPago: 'pagada',
        montoPagado: 5900.0,
        balancePendiente: 0.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CommercialInvoiceDialog(sale: testSale),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Comprobante Comercial: FAC-2026-0099'), findsOneWidget);
      expect(find.textContaining('Carmen Santana'), findsWidgets);
      expect(find.text('Imprimir / Reimprimir', skipOffstage: false), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ClientFormDialog valida campos obligatorios y navega', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ClientFormDialog(
              onSaved: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nuevo Cliente'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);

      // Intentar enviar sin nombres debe mostrar validación
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();

      expect(find.text('Requerido'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProductFormDialog renderiza selector de categorías dominicanas', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ProductFormDialog(
              onSaved: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nuevo Producto Óptico'), findsOneWidget);
      expect(find.text('Monturas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('LabOrderModel y RepairModel manejan precios, abonos y saldos', () {
      final labOrder = LabOrderModel(
        id: 1,
        clienteId: 10,
        estado: 'en_laboratorio',
        tipoCristal: 'Policarbonato Antirreflejo',
        tipoMontura: 'Acetato Ray-Ban',
        precio: 4500.0,
        abono: 2000.0,
      );

      expect(labOrder.precio, 4500.0);
      expect(labOrder.abono, 2000.0);
      expect(labOrder.saldo, 2500.0);

      final repair = RepairModel(
        id: 2,
        clienteId: 10,
        tipo: 'Soldadura de puente',
        descripcion: 'Puente fracturado',
        costo: 800.0,
        abono: 500.0,
        estado: 'recibido',
      );

      expect(repair.costo, 800.0);
      expect(repair.abono, 500.0);
      expect(repair.saldo, 300.0);
    });
  });
}
