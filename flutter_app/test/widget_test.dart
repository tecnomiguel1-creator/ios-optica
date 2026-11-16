import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:only_eyes_360/models/prescription_model.dart';
import 'package:only_eyes_360/widgets/empty_state.dart';
import 'package:only_eyes_360/widgets/optical_prescription_card.dart';
import 'package:only_eyes_360/widgets/stat_card.dart';

void main() {
  group('ONLY EYES 360 - Pruebas de Componentes UI y Widgets', () {
    testWidgets('StatCard renderiza título, valor numérico e ícono', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Pacientes Activos',
              value: '142',
              subtitle: 'Fichas clínicas en sistema',
              icon: Icons.people_outline,
            ),
          ),
        ),
      );

      expect(find.text('PACIENTES ACTIVOS'), findsOneWidget);
      expect(find.text('142'), findsOneWidget);
      expect(find.text('Fichas clínicas en sistema'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('OpticalPrescriptionCard renderiza tabla OD / OI con datos clínicos',
        (WidgetTester tester) async {
      final rx = PrescriptionModel(
        id: 101,
        pacienteId: 12,
        fechaReceta: '2026-11-04',
        odEsfera: 1.25,
        odCilindro: -0.75,
        odEje: 90,
        oiEsfera: -2.00,
        oiCilindro: 0.0,
        oiEje: 180,
        adicion: 2.00,
        distanciaPupilar: 63.0,
        diagnostico: 'Astigmatismo y presbicia incipiente',
        profesional: 'Dra. Laura Morales',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OpticalPrescriptionCard(prescription: rx),
            ),
          ),
        ),
      );

      expect(find.text('Receta #101'), findsOneWidget);
      expect(find.text('Dra. Laura Morales'), findsOneWidget);
      expect(find.text('OD (Derecho)'), findsOneWidget);
      expect(find.text('OI (Izquierdo)'), findsOneWidget);
      expect(find.text('+1.25 D'), findsOneWidget);
      expect(find.text('-2.00 D'), findsOneWidget);
      expect(find.text('90°'), findsOneWidget);
      expect(find.text('+2.00 D'), findsOneWidget);
      expect(find.text('63.0 mm'), findsOneWidget);
    });

    testWidgets('EmptyState renderiza mensaje amigable y botón de acción',
        (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Sin existencias',
              message: 'No hay productos que coincidan.',
              buttonText: 'Crear Producto',
              onAction: () => buttonPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Sin existencias'), findsOneWidget);
      expect(find.text('No hay productos que coincidan.'), findsOneWidget);
      expect(find.text('Crear Producto'), findsOneWidget);

      await tester.tap(find.text('Crear Producto'));
      expect(buttonPressed, true);
    });
  });
}
