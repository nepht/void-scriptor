import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/presentation/portfolio_builder_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan 5 tahap flow portfolio', (tester) async {
    await tester.pumpWidget(wrap(const PortfolioBuilderScreen()));
    expect(find.text('Project'), findsOneWidget);
    expect(find.text('Select Work'), findsOneWidget);
    expect(find.text('Portfolio Entry'), findsOneWidget);
    expect(find.text('Customize'), findsOneWidget);
    expect(find.text('Publish'), findsOneWidget);
  });

  testWidgets('tahap punya ikon', (tester) async {
    await tester.pumpWidget(wrap(const PortfolioBuilderScreen()));
    expect(find.byType(Icon), findsWidgets);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const PortfolioBuilderScreen()));
    expect(tester.takeException(), isNull);
  });
}
