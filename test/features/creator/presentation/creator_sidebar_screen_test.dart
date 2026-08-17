import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/presentation/creator_sidebar_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan item sidebar creator', (tester) async {
    await tester.pumpWidget(wrap(const CreatorSidebarScreen()));
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('AI Studio'), findsOneWidget);
    expect(find.text('Assets'), findsOneWidget);
    expect(find.text('Portfolio'), findsOneWidget);
  });

  testWidgets('menampilkan branding', (tester) async {
    await tester.pumpWidget(wrap(const CreatorSidebarScreen()));
    expect(find.text('VOID SCRIPTOR'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const CreatorSidebarScreen()));
    expect(tester.takeException(), isNull);
  });
}
