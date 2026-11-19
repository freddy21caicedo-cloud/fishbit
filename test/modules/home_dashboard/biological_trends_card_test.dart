import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/core/design_system/glass_select_field.dart';
import 'package:fishbit_finance/modules/home_dashboard/presentation/screens/home_dashboard_screen.dart';
import 'package:fishbit_finance/modules/home_dashboard/presentation/widgets/biological_trends_card.dart';
import 'package:fishbit_finance/modules/home_dashboard/presentation/widgets/pond_feed_ticker_board.dart';

void main() {
  testWidgets(
      'HomeDashboardScreen renders zootecnic KPIs, PondFeedTickerBoard and redesigned BiologicalTrendsCard',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeDashboardScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    // Verify zootecnic hero KPI and PondFeedTickerBoard
    expect(find.text('BIOMASA VIVA TOTAL EN AGUA'), findsOneWidget);
    expect(find.byType(PondFeedTickerBoard), findsOneWidget);
    expect(find.text('PIZARRA DE CONSUMO DIARIO POR ESTANQUE'), findsOneWidget);

    // Verify presence of the redesigned BiologicalTrendsCard
    expect(find.byType(BiologicalTrendsCard), findsOneWidget);
    expect(find.text('ANALÍTICA BIOLÓGICA Y TENDENCIAS'), findsOneWidget);
    expect(find.text('Ver bitácora →'), findsOneWidget);

    // Verify both GlassSelectField selectors (Estanque + Analítica)
    expect(find.text('ESTANQUE DE CONSULTA'), findsOneWidget);
    expect(find.text('ANALÍTICA'), findsOneWidget);
    expect(find.byType(GlassSelectField<String>), findsOneWidget);
    expect(find.byType(GlassSelectField<BiologicalCurveType>), findsOneWidget);

    // Initial metric is Oxígeno (O₂)
    expect(find.text('Oxígeno (O₂)'), findsWidgets);
    expect(find.text('Mín: 4.0 mg/L'), findsOneWidget);

    // Open Analítica selector popover and select Temp & pH (°C)
    final analyticsField = find.byType(GlassSelectField<BiologicalCurveType>);
    await tester.ensureVisible(analyticsField);
    await tester.tap(find.descendant(
      of: analyticsField,
      matching: find.byIcon(Icons.keyboard_arrow_down_rounded),
    ));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Temp & pH (°C)').last);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Rango: 26° - 30°C'), findsOneWidget);
    expect(find.text('Sin registros de temperatura y pH'), findsOneWidget);

    // Open Analítica selector popover and select Tóxicos (NH₃/NO₂)
    await tester.tap(find.descendant(
      of: analyticsField,
      matching: find.byIcon(Icons.keyboard_arrow_down_rounded),
    ));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Tóxicos (NH₃/NO₂)').last);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Máx: 0.50 ppm'), findsOneWidget);
    expect(find.text('Sin registros de tóxicos (NH₃/NO₂)'), findsOneWidget);

    // Open Estanque selector popover and verify "Todos los Estanques" option
    final pondField = find.byType(GlassSelectField<String>);
    await tester.tap(find.descendant(
      of: pondField,
      matching: find.byIcon(Icons.keyboard_arrow_down_rounded),
    ));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('Todos los Estanques'), findsWidgets);
  });
}
