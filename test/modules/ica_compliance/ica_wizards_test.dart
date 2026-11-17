import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/modules/ica_compliance/presentation/screens/ica_certification_screen.dart';
import 'package:fishbit_finance/modules/ica_compliance/presentation/screens/ica_biosecurity_wizards.dart';

void main() {
  testWidgets('IcaCertificationScreen renders adaptive grid and opens F-01 Wizard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: IcaCertificationScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify main screen elements
    expect(find.text('Certificación y Normativa ICA'), findsOneWidget);
    expect(find.text('F-01'), findsWidgets);

    // Tap on Nuevo Registro for F-01 to open Wizard
    final nuevoRegistroBtns = find.text('Nuevo Registro');
    expect(nuevoRegistroBtns, findsWidgets);

    await tester.tap(nuevoRegistroBtns.first);
    await tester.pumpAndSettle();

    // Verify presence of the Wizard screen
    expect(find.byType(IngresoPersonalWizardScreen), findsOneWidget);
    expect(find.text('Control de Ingreso (F-01)'), findsOneWidget);
    expect(find.text('PASO 1 DE 3: IDENTIFICACIÓN Y CARGO'), findsOneWidget);
  });
}
