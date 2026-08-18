import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/platform/presentation/keyboard_navigation_screen.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

  testWidgets('menampilkan keyboard shortcuts', (tester) async {
    await tester.pumpWidget(wrap(const KeyboardNavigationScreen()));
    expect(find.text('Tab'), findsOneWidget);
    expect(find.text('Enter'), findsOneWidget);
    expect(find.text('Escape'), findsOneWidget);
    expect(find.text('Arrow Keys'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const KeyboardNavigationScreen()));
    expect(tester.takeException(), isNull);
  });
}
