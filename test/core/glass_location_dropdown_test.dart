import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/core/design_system/widgets/glass_location_dropdown.dart';
import 'package:fishbit_finance/core/design_system/app_colors.dart';

void main() {
  testWidgets('GlassLocationDropdown renders correctly and selects an item', (tester) async {
    String selected = 'Colombia';
    final items = ['Colombia', 'Perú', 'Ecuador'];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Center(
                child: GlassLocationDropdown(
                  label: 'PAÍS',
                  value: selected,
                  items: items,
                  icon: Icons.public_rounded,
                  accentColor: AppColors.cyanWater,
                  onChanged: (val) {
                    setState(() => selected = val);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial value and label are shown
    expect(find.text('PAÍS'), findsOneWidget);
    expect(find.text('Colombia'), findsOneWidget);
    expect(find.byIcon(Icons.public_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down_rounded), findsOneWidget);

    // Tap to open the buttonlist dropdown
    await tester.tap(find.byType(GlassLocationDropdown));
    await tester.pumpAndSettle();

    // Verify items are displayed in the dropdown menu
    expect(find.text('Perú'), findsOneWidget);
    expect(find.text('Ecuador'), findsOneWidget);

    // Tap 'Perú'
    await tester.tap(find.text('Perú').last);
    await tester.pumpAndSettle();

    // Value should now be Perú
    expect(selected, 'Perú');
  });

  testWidgets('GlassLocationDropdown falls back gracefully when value is not in items', (tester) async {
    final items = ['Neiva', 'Pitalito', 'Garzón'];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassLocationDropdown(
            label: 'CIUDAD',
            value: 'CiudadInexistente',
            items: items,
            icon: Icons.location_city_rounded,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Should display first available item instead of crashing
    expect(find.text('Neiva'), findsOneWidget);
  });
}
