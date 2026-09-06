import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/multiverse/presentation/merge_preview_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan merge preview', (tester) async {
    await tester.pumpWidget(wrap(const MergePreviewScreen()));
    expect(find.text('Merge Preview'), findsOneWidget);
    expect(find.text('Confirm Merge'), findsOneWidget);
  });

  testWidgets('confirm merge notifies the parent', (tester) async {
    var confirmed = false;
    await tester.pumpWidget(
      wrap(MergePreviewScreen(onConfirmMerge: () => confirmed = true)),
    );

    await tester.tap(find.text('Confirm Merge'));

    expect(confirmed, isTrue);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const MergePreviewScreen()));
    expect(tester.takeException(), isNull);
  });
}
