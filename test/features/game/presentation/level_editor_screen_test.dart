import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/game/presentation/level_editor_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan level editor 3 panel', (tester) async {
    await tester.pumpWidget(wrap(const LevelEditorScreen()));
    expect(find.text('Level Editor'), findsOneWidget);
    expect(find.text('Assets'), findsOneWidget);
    expect(find.text('Inspector'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('play action notifies the parent', (tester) async {
    var played = false;
    await tester.pumpWidget(
      wrap(LevelEditorScreen(onPlay: () => played = true)),
    );
    await tester.tap(find.text('Play'));
    expect(played, isTrue);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const LevelEditorScreen()));
    expect(tester.takeException(), isNull);
  });
}
