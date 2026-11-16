import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:only_eyes_360/screens/shell/adaptive_navigation_shell.dart';
import 'package:only_eyes_360/state/app_state.dart';

void main() {
  testWidgets('navegación móvil muestra sólo consulta, ventas y citas',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveNavigationShell(
          appState: AppState(),
          child: const SizedBox.expand(),
        ),
      ),
    );

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Ventas'), findsOneWidget);
    expect(find.text('Citas'), findsOneWidget);
    expect(find.text('Pacientes'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
