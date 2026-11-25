import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/pond.dart';
import 'package:fishbit_finance/modules/ponds_batches/domain/models/fish_batch.dart';
import 'package:fishbit_finance/modules/water_quality/domain/models/water_parameter.dart';
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
    especie: 'Cachama Blanca',
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

  group('PondBentoCard - Clean Bento UI & WCAG 2.5.5 Tests', () {
    testWidgets('1. Front card omits Registrar acción de campo button and emojis', (tester) async {
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

      expect(find.text('REGISTRAR ACCIÓN DE CAMPO'), findsNothing);
      expect(find.textContaining('🟢'), findsNothing);
      expect(find.textContaining('🟡'), findsNothing);
      expect(find.textContaining('🔴'), findsNothing);
      expect(find.textContaining('⚪'), findsNothing);
    });

    testWidgets('2. Front card has single top-right flip button meeting WCAG 2.5.5 >= 48x48dp', (tester) async {
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

      final flipIconFinder = find.byIcon(Icons.flip_camera_android_rounded).first;
      final flipTouchParent = find.ancestor(of: flipIconFinder, matching: find.byType(SizedBox)).first;
      final flipTouchSize = tester.getSize(flipTouchParent);
      expect(flipTouchSize.width, greaterThanOrEqualTo(48.0));
      expect(flipTouchSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('3. Back card face has clean headers without emojis and omits Ficha estructural y aireación', (tester) async {
      final pondWithDims = testPond.copyWith(
        largoM: 30.0,
        anchoM: 20.0,
        profundidadM: 1.0,
        tipoEstructura: 'Geomembrana Circular',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PondBentoCard(
                  pond: pondWithDims,
                  batch: testBatch1,
                  batches: [testBatch1, testBatch2],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Flip card to reverse face
      await tester.tap(find.byIcon(Icons.flip_camera_android_rounded).first);
      await tester.pumpAndSettle();

      // Header VOLVER button >= 48dp
      final volverFinder = find.text('VOLVER');
      expect(volverFinder, findsOneWidget);
      final volverParent = find.ancestor(of: volverFinder, matching: find.byType(SizedBox)).first;
      expect(tester.getSize(volverParent).height, greaterThanOrEqualTo(48.0));

      // Species selector chips without emojis (>= 48dp)
      final species1Chip = find.text('Tilapia Roja');
      expect(species1Chip, findsOneWidget);
      expect(tester.getSize(find.ancestor(of: species1Chip, matching: find.byType(InkWell)).first).height, greaterThanOrEqualTo(48.0));

      final consolidatedChip = find.text('Consolidado');
      expect(consolidatedChip, findsOneWidget);
      expect(tester.getSize(find.ancestor(of: consolidatedChip, matching: find.byType(InkWell)).first).height, greaterThanOrEqualTo(48.0));

      // Single-batch headers without emojis
      expect(find.text('DESGLOSE BIOLÓGICO'), findsOneWidget);
      expect(find.text('RADIOGRAFÍA FINANCIERA Y COSTOS'), findsOneWidget);

      // No structural card and no emojis
      expect(find.textContaining('FICHA ESTRUCTURAL'), findsNothing);
      expect(find.textContaining('🏗️'), findsNothing);
      expect(find.textContaining('🔬'), findsNothing);
      expect(find.textContaining('💰'), findsNothing);
      expect(find.textContaining('🐟'), findsNothing);
      expect(find.textContaining('📊'), findsNothing);

      // Switch to consolidated polyculture view and verify clean headers
      await tester.tap(consolidatedChip);
      await tester.pumpAndSettle();

      expect(find.text('DISTRIBUCIÓN DE BIOMASA POR ESPECIE'), findsOneWidget);
      expect(find.text('INVERSIÓN TOTAL DEL POLICULTIVO'), findsOneWidget);
      expect(find.textContaining('FICHA ESTRUCTURAL'), findsNothing);
      expect(find.textContaining('📊'), findsNothing);
      expect(find.textContaining('💰'), findsNothing);
    });

    testWidgets('4. Front card renders Water Quality mini-strip with live O2, Temp, and pH', (tester) async {
      final testParam = WaterParameter(
        id: 'wq-1',
        empresaId: 'emp-1',
        unidadAcuicolaId: 'u-1',
        estanqueId: 'pond-test-1',
        fecha: now,
        oxigenoMgL: 5.8,
        temperaturaC: 28.5,
        ph: 7.4,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PondBentoCard(
                  pond: testPond,
                  batch: testBatch1,
                  batches: [testBatch1],
                  latestWaterParameter: testParam,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('O₂: 5.8 mg/L'), findsOneWidget);
      expect(find.textContaining('T: 28.5°C'), findsOneWidget);
      expect(find.textContaining('pH: 7.4'), findsOneWidget);
    });

    testWidgets('5. Reverse face does not overflow inside constrained grid cell (340x390)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 340,
                  height: 390,
                  child: PondBentoCard(
                    pond: testPond,
                    batch: testBatch1,
                    batches: [testBatch1, testBatch2],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.flip_camera_android_rounded).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final consolidatedFinder = find.text('Consolidado');
      await tester.ensureVisible(consolidatedFinder);
      await tester.pumpAndSettle();
      await tester.tap(consolidatedFinder);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('6. Target harvest weight reflects custom targetWeightsBySpecies on front and back faces', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PondBentoCard(
                  pond: testPond,
                  batch: testBatch1,
                  batches: [testBatch1],
                  targetWeightsBySpecies: const {
                    'Tilapia Roja': 800.0,
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('800g cosecha'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.flip_camera_android_rounded).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('800g meta'), findsOneWidget);
    });
  });
}
