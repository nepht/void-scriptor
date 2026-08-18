import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinema/presentation/branch_preview_screen.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

  testWidgets('menampilkan branch preview', (tester) async {
    await tester.pumpWidget(wrap(const BranchPreviewScreen()));
    expect(find.text('Choice A'), findsOneWidget);
    expect(find.text('Choice B'), findsOneWidget);
    expect(find.text('Timeline Impact'), findsWidgets);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const BranchPreviewScreen()));
    expect(tester.takeException(), isNull);
  });
}
