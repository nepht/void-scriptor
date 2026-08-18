import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/platform/presentation/update_screen.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

  testWidgets('menampilkan update UI', (tester) async {
    await tester.pumpWidget(wrap(const UpdateScreen()));
    expect(find.textContaining('available'), findsOneWidget);
    expect(find.text('Download'), findsWidgets);
    expect(find.text('Later'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const UpdateScreen()));
    expect(tester.takeException(), isNull);
  });
}
