import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinema/presentation/cinematic_continuity_checker_screen.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

  testWidgets('menampilkan item continuity', (tester) async {
    await tester.pumpWidget(wrap(const CinematicContinuityCheckerScreen()));
    expect(find.text('Wardrobe'), findsOneWidget);
    expect(find.text('Hair'), findsOneWidget);
    expect(find.text('Weather'), findsOneWidget);
    expect(find.text('Character Position'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const CinematicContinuityCheckerScreen()));
    expect(tester.takeException(), isNull);
  });
}
