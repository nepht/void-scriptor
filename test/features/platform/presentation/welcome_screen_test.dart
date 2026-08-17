import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/platform/presentation/welcome_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan welcome experience', (tester) async {
    await tester.pumpWidget(wrap(const WelcomeScreen()));
    expect(find.text('Welcome to Void Scriptor'), findsOneWidget);
    expect(find.text('Create Project'), findsOneWidget);
    expect(find.text('Open Project'), findsOneWidget);
    expect(find.text('Explore Demo'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const WelcomeScreen()));
    expect(tester.takeException(), isNull);
  });
}
