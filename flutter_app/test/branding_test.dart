import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:only_eyes_360/widgets/brand_logo.dart';

void main() {
  testWidgets('El logotipo oficial conserva su proporción en una superficie neutra', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BrandLogo(width: 200, height: 110)),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.contain);
    expect(image.semanticLabel, contains('Óptica ONLY EYES'));
  });
}
