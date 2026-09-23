import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/ponds_batches/presentation/widgets/pond_bento_card.dart';

void main() {
  final now = DateTime.now();

  final testPond = Pond(
    id: 'pond-test-1',
    empresaId: 'emp-1',
    unidadAcuicolaId: 'u-1',
    nombre: 'Estanque San José 1',
    sigla: 'SJ-01',
    capacidadM3: 600,
    biomasaKg: 2800,
    costoAcumuladoBiologico: 12000000,
    estado: PondStatus.active,
    creadoEn: now,
  );

  final testBatch1 = FishBatch(
    id: 'batch-test-1',
    empresaId: 'emp-1',
    unidadAcuicolaId: 'u-1',
    estanqueId: 'pond-test-1',
    codigoLote: 'LOT-TILAPIA-01',
    especie: 'Tilapia Roja',
    rolPolicultivo: 'principal',
    cantidadInicialPeces: 6000,
    cantidadActualPeces: 5800,
    pesoInicialGramos: 10,
    pesoActualGramos: 480,
    biomasaInicialKg: 60,
    biomasaActualKg: 2784,
    costoInicialAlevinos: 1800000,
    costoAcumuladoInsumos: 8200000,
    costoAcumuladoFijo: 1200000,
    estado: BatchStatus.active,
    fechaSiembra: now.subtract(const Duration(days: 85)),
    creadoEn: now,
  );

  final testBatch2 = FishBatch(
    id: 'batch-test-2',
    empresaId: 'emp-1',
    unidadAcuicolaId: 'u-1',
    estanqueId: 'pond-test-1',
    codigoLote: 'LOT-CACHAMA-01',
    especie: 'Cachama Negra',
    rolPolicultivo: 'secundaria',
    cantidadInicialPeces: 1500,
    cantidadActualPeces: 1450,
    pesoInicialGramos: 15,
    pesoActualGramos: 550,
    biomasaInicialKg: 22.5,
    biomasaActualKg: 797.5,
    costoInicialAlevinos: 450000,
    costoAcumuladoInsumos: 2100000,
    costoAcumuladoFijo: 300000,
    estado: BatchStatus.active,
    fechaSiembra: now.subtract(const Duration(days: 85)),
    creadoEn: now,
  );

  group('PondBentoCard - UX-01 & WCAG 2.5.5 Field Ergonomics Tests', () {
    testWidgets('1. Primary Action Button renders with compact ergonomics (40dp)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PondBentoCard(
                  pond: testPond,
                  batch: testBatch1,
                  batches: [testBatch1],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final primaryBtnFinder = find.text('REGISTRAR ACCIÓN DE CAMPO');
      expect(primaryBtnFinder, findsOneWidget);

      final elevatedBtnFinder = find.ancestor(of: primaryBtnFinder, matching: find.byType(ElevatedButton));
      expect(elevatedBtnFinder, findsOneWidget);

      final primaryBtnSize = tester.getSize(elevatedBtnFinder);
      expect(primaryBtnSize.height, equals(40.0),
          reason: 'Primary field button is specified to be compact (40dp height)');
    });

    testWidgets('2. Tapping primary button opens Operational Bottom Sheet with all 5 routines >= 56dp', (tester) async {
      bool feedCalled = false;
      bool waterCalled = false;
      bool sampleCalled = false;
      bool mortalityCalled = false;
      bool transferCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PondBentoCard(
                  pond: testPond,
                  batch: testBatch1,
                  batches: [testBatch1],
                  onFeedPressed: () => feedCalled = true,
                  onWaterQualityPressed: () => waterCalled = true,
                  onSamplePressed: () => sampleCalled = true,
                  onMortalityPressed: () => mortalityCalled = true,
                  onTransferPressed: () => transferCalled = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.text('REGISTRAR ACCIÓN DE CAMPO'));
      await tester.pumpAndSettle();

      // Verify bottom sheet title and pond indicator
      expect(find.text('ACCIONES DE CAMPO'), findsOneWidget);
      expect(find.text(testPond.sigla), findsWidgets);

      // Verify close button size >= 48x48 dp
      final closeBtnFinder = find.widgetWithIcon(IconButton, Icons.close_rounded);
      expect(closeBtnFinder, findsOneWidget);
      final closeBtnSize = tester.getSize(closeBtnFinder);
      expect(closeBtnSize.width, greaterThanOrEqualTo(48.0));
      expect(closeBtnSize.height, greaterThanOrEqualTo(48.0));

      // Verify all 5 field routines exist and have minHeight >= 56dp
      final routines = [
        'Registrar Alimentación',
        'Calidad de Agua (O₂, pH, Temp)',
        'Muestreo y Biometría',
        'Registrar Bajas / Mortalidad',
        'Traslado o Cosecha',
      ];

      for (final routineTitle in routines) {
        final routineFinder = find.text(routineTitle);
        expect(routineFinder, findsOneWidget);

        final inkWellFinder = find.ancestor(of: routineFinder, matching: find.byType(InkWell)).first;
        final size = tester.getSize(inkWellFinder);
        expect(size.height, greaterThanOrEqualTo(56.0),
            reason: '$routineTitle must be >= 56dp for wet field operation');
      }

      // Tap Calidad de Agua and verify callback is invoked
      await tester.tap(find.text('Calidad de Agua (O₂, pH, Temp)'));
      await tester.pumpAndSettle();
      expect(waterCalled, isTrue);

      // Re-open and test Alimentación
      await tester.tap(find.text('REGISTRAR ACCIÓN DE CAMPO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar Alimentación'));
      await tester.pumpAndSettle();
      expect(feedCalled, isTrue);

      // Re-open and test Muestreo y Biometría
      await tester.tap(find.text('REGISTRAR ACCIÓN DE CAMPO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Muestreo y Biometría'));
      await tester.pumpAndSettle();
      expect(sampleCalled, isTrue);

      // Re-open and test Mortalidad
      await tester.tap(find.text('REGISTRAR ACCIÓN DE CAMPO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar Bajas / Mortalidad'));
      await tester.pumpAndSettle();
      expect(mortalityCalled, isTrue);

      // Re-open and test Traslado
      await tester.tap(find.text('REGISTRAR ACCIÓN DE CAMPO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Traslado o Cosecha'));
      await tester.pumpAndSettle();
      expect(transferCalled, isTrue);
    });

    testWidgets('3. Front card has single top-right flip button meeting WCAG 2.5.5 >= 48x48dp and no redundant bottom flip banner', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PondBentoCard(
                  pond: testPond,
                  batch: testBatch1,
                  batches: [testBatch1],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Front flip button (top right)
      final flipIconFinder = find.byIcon(Icons.flip_camera_android_rounded).first;
      final flipTouchParent = find.ancestor(of: flipIconFinder, matching: find.byType(SizedBox)).first;
      final flipTouchSize = tester.getSize(flipTouchParent);
      expect(flipTouchSize.width, greaterThanOrEqualTo(48.0));
      expect(flipTouchSize.height, greaterThanOrEqualTo(48.0));

      // Front redundant flip banner is removed
      final bannerFinder = find.text('Radiografía y Costos (Flip)');
      expect(bannerFinder, findsNothing);
    });

    testWidgets('4. Back card face has single top VOLVER button and no redundant bottom return button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PondBentoCard(
                  pond: testPond,
                  batch: testBatch1,
                  batches: [testBatch1, testBatch2],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 3D Flip trigger (top-right icon) to show back face
      await tester.tap(find.byIcon(Icons.flip_camera_android_rounded).first);
      await tester.pumpAndSettle();

      // 1. Header VOLVER button
      final volverFinder = find.text('VOLVER');
      expect(volverFinder, findsOneWidget);
      final volverParent = find.ancestor(of: volverFinder, matching: find.byType(SizedBox)).first;
      final volverSize = tester.getSize(volverParent);
      expect(volverSize.height, greaterThanOrEqualTo(48.0));

      // 2. Species selector chips
      final species1Chip = find.text('🐟 Tilapia Roja');
      expect(species1Chip, findsOneWidget);
      final species1Size = tester.getSize(find.ancestor(of: species1Chip, matching: find.byType(InkWell)).first);
      expect(species1Size.height, greaterThanOrEqualTo(48.0));

      // 3. Consolidated chip
      final consolidatedChip = find.text('📊 Consolidado');
      expect(consolidatedChip, findsOneWidget);
      final consolidatedSize = tester.getSize(find.ancestor(of: consolidatedChip, matching: find.byType(InkWell)).first);
      expect(consolidatedSize.height, greaterThanOrEqualTo(48.0));

      // 4. Redundant bottom return button is removed
      final returnBottomFinder = find.text('↩️ Volver a Vista de Estanque');
      expect(returnBottomFinder, findsNothing);
    });
  });
}
