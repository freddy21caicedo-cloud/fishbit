import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:fishbit_finance/core/design_system/fade_content.dart';

void main() {
  group('FadeContent (mist effect)', () {
    testWidgets('revela contenido con efecto mist y desmonta ImageFiltered al terminar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadeContent(
              effect: FadeContentEffect.mist,
              duration: Duration(milliseconds: 400),
              child: Text('Slow light over the bay'),
            ),
          ),
        ),
      );

      expect(find.text('Slow light over the bay'), findsOneWidget);

      // Durante la entrada debe existir Opacity/ImageFiltered
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ImageFiltered), findsOneWidget);

      // Al completar la animación, ImageFiltered se desmonta (cero costo GPU)
      await tester.pumpAndSettle();
      expect(find.byType(ImageFiltered), findsNothing);
      expect(find.text('Slow light over the bay'), findsOneWidget);
    });

    testWidgets('FadeContentStagger renderiza todos los hijos en cascada', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadeContentStagger(
              duration: Duration(milliseconds: 250),
              stagger: Duration(milliseconds: 100),
              spacing: 8,
              children: [
                Text('Bloque 1'),
                Text('Bloque 2'),
                Text('Bloque 3'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bloque 1'), findsOneWidget);
      expect(find.text('Bloque 2'), findsOneWidget);
      expect(find.text('Bloque 3'), findsOneWidget);
      expect(find.byType(ImageFiltered), findsNothing);
    });

    testWidgets('respeta MediaQuery disableAnimations', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: FadeContent(
                duration: Duration(milliseconds: 800),
                child: Text('Instantáneo'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Instantáneo'), findsOneWidget);
      expect(find.byType(ImageFiltered), findsNothing);
    });

    testWidgets('buildMistTransitionPage navega suavemente entre rutas GoRouter', (tester) async {
      final router = GoRouter(
        initialLocation: '/a',
        routes: [
          GoRoute(
            path: '/a',
            pageBuilder: (context, state) => buildMistTransitionPage(
              key: state.pageKey,
              child: Scaffold(
                body: TextButton(
                  onPressed: () => context.go('/b'),
                  child: const Text('Ir a B'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/b',
            pageBuilder: (context, state) => buildMistTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Text('Módulo B'),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      expect(find.text('Ir a B'), findsOneWidget);

      await tester.tap(find.text('Ir a B'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Módulo B'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Módulo B'), findsOneWidget);
      expect(find.byType(ImageFiltered), findsNothing);
    });
  });
}
