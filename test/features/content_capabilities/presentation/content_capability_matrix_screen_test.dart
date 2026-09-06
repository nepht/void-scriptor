import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/design_system/theme/void_theme.dart';
import 'package:void_scriptor/features/content_capabilities/presentation/content_capability_matrix_screen.dart';

void main() {
  Widget wrap() => MaterialApp(
    theme: VoidTheme.light,
    darkTheme: VoidTheme.dark,
    home: const ContentCapabilityMatrixScreen(),
  );

  testWidgets('renders a product-integration matrix instead of fake metrics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap());

    expect(find.text('Content Capability Matrix'), findsOneWidget);
    expect(
      find.textContaining('Status menilai integrasi produk'),
      findsOneWidget,
    );
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Partial'), findsWidgets);
    expect(find.text('Novel & Scene'), findsOneWidget);
    await tester.tap(find.text('Novel & Scene'));
    await tester.pumpAndSettle();
    expect(find.text('Langkah berikutnya'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search and maturity filters change the visible modules', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap());
    await tester.enterText(
      find.byKey(const ValueKey('content-capability-search')),
      'Dialogue',
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('content-module-dialogue')),
        matching: find.text('Dialogue'),
      ),
      findsOneWidget,
    );
    expect(find.text('Novel & Scene'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('content-capability-search')),
      '',
    );
    await tester.tap(find.byKey(const ValueKey('maturity-domainOnly')));
    await tester.pump();

    expect(find.text('Domain Only'), findsWidgets);
    expect(find.text('Novel & Scene'), findsNothing);
  });

  testWidgets('reflows without overflow on a narrow mobile viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap());
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
