import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinema/presentation/performance_preview_screen.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

  testWidgets('menampilkan opsi toggle performa', (tester) async {
    await tester.pumpWidget(wrap(const PerformancePreviewScreen()));
    expect(find.text('High Quality Hair'), findsOneWidget);
    expect(find.text('Heavy VFX'), findsOneWidget);
    expect(find.text('Ray Tracing'), findsOneWidget);
    expect(find.text('High Resolution Shadows'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const PerformancePreviewScreen()));
    expect(tester.takeException(), isNull);
  });
}
