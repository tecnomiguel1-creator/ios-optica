import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:only_eyes_360/core/theme/app_theme.dart';
import 'package:only_eyes_360/widgets/stat_card.dart';
import 'package:only_eyes_360/widgets/empty_state.dart';

void main() {
  group('ONLY EYES 360 - Verificación de Layouts Responsivos y RenderFlex', () {
    const windowSizes = [
      Size(400, 800),   // Ventana móvil / panel estrecho
      Size(800, 600),   // Ventana reducida desktop
      Size(1024, 768),  // Ventana portátil estándar
      Size(1280, 720),  // HD reducido
      Size(1280, 800),  // Ventana desktop normal HD
      Size(1366, 768),  // Resolución frecuente en Windows
      Size(1920, 1080), // Ventana maximizada Full HD
    ];

    for (final size in windowSizes) {
      testWidgets('StatCards no desbordan en resolución ${size.width.toInt()}x${size.height.toInt()}',
          (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  crossAxisCount: size.width > 900 ? 4 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: size.width > 900 ? 1.7 : 1.9,
                  children: const [
                    StatCard(
                      title: 'Pacientes Registrados',
                      value: '1,420',
                      subtitle: 'Fichas clínicas activas',
                      icon: Icons.people_outline,
                    ),
                    StatCard(
                      title: 'Ventas de Hoy',
                      value: 'RD\$ 45,850.00',
                      subtitle: '12 transacciones',
                      icon: Icons.point_of_sale_outlined,
                    ),
                    StatCard(
                      title: 'Stock Bajo',
                      value: '4 Productos',
                      subtitle: 'Requiere reposición',
                      icon: Icons.warning_amber_rounded,
                    ),
                    StatCard(
                      title: 'Citas Programadas',
                      value: '8 Consultas',
                      subtitle: 'Agenda del día',
                      icon: Icons.calendar_month_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('PACIENTES REGISTRADOS'), findsOneWidget);
        expect(find.text('RD\$ 45,850.00'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('EmptyState y Contenedores se adaptan en ${size.width.toInt()}x${size.height.toInt()}',
          (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: EmptyState(
                icon: Icons.inbox_outlined,
                title: 'No hay elementos para mostrar',
                message: 'Comience agregando nuevos registros desde el botón superior.',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('No hay elementos para mostrar'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
