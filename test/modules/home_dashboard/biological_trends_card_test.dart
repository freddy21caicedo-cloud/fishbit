import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fishbit_finance/modules/home_dashboard/presentation/screens/home_dashboard_screen.dart';
import 'package:fishbit_finance/modules/home_dashboard/presentation/widgets/biological_trends_card.dart';
import 'package:fishbit_finance/modules/home_dashboard/presentation/widgets/pond_feed_ticker_board.dart';

void main() {
  testWidgets('HomeDashboardScreen renders zootecnic KPIs, PondFeedTickerBoard and BiologicalTrendsCard', (WidgetTester tester) async {
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

    await tester.pumpAndSettle();

    // Verify zootecnic hero KPI and PondFeedTickerBoard
    expect(find.text('BIOMASA VIVA TOTAL EN AGUA'), findsOneWidget);
    expect(find.byType(PondFeedTickerBoard), findsOneWidget);
    expect(find.text('PIZARRA DE CONSUMO DIARIO POR ESTANQUE'), findsOneWidget);

    // Verify presence of the BiologicalTrendsCard
    expect(find.byType(BiologicalTrendsCard), findsOneWidget);
    expect(find.text('ANALÍTICA BIOLÓGICA Y TENDENCIAS'), findsOneWidget);

    // Verify presence of the 6 curve chips
    expect(find.text('Oxígeno (O₂)'), findsOneWidget);
    expect(find.text('Temp & pH (°C)'), findsOneWidget);
    expect(find.text('Tóxicos (NH₃/NO₂)'), findsOneWidget);
    expect(find.text('Crecimiento (g)'), findsOneWidget);
    expect(find.text('Conversión (FCR)'), findsOneWidget);
    expect(find.text('Supervivencia (%)'), findsOneWidget);

    // Tap on Temp & pH chip
    await tester.tap(find.text('Temp & pH (°C)'));
    await tester.pumpAndSettle();
    expect(find.text('Rango: 26° - 30°C'), findsOneWidget);
    expect(find.text('Sin registros de temperatura y pH'), findsOneWidget);

    // Tap on Tóxicos chip
    await tester.tap(find.text('Tóxicos (NH₃/NO₂)'));
    await tester.pumpAndSettle();
    expect(find.text('Máx: 0.50 ppm'), findsOneWidget);
    expect(find.text('Sin registros de tóxicos (NH₃/NO₂)'), findsOneWidget);

    // Tap on the pond selector button ("Todos")
    final pondBtn = find.text('Todos');
    expect(pondBtn, findsOneWidget);
    await tester.tap(pondBtn);
    await tester.pumpAndSettle();

    // Verify that the floating Glass dialog is shown with search and "Todos los Estanques"
    expect(find.text('Filtrar por Estanque'), findsOneWidget);
    expect(find.text('Todos los Estanques (Promedio Granja)'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // If an individual pond card is found, tap it and verify no TypeError occurs
    final estanqueText = find.textContaining('Estanque');
    if (estanqueText.evaluate().length > 1) {
      await tester.tap(estanqueText.at(1));
      await tester.pumpAndSettle();
      expect(find.text('Filtrar por Estanque'), findsNothing);
    }
  });
}
