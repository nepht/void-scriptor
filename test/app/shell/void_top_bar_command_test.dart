import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/shell/desktop/void_top_bar.dart';

void main() {
  testWidgets('undo and redo toolbar buttons follow command state', (
    tester,
  ) async {
    var undoCount = 0;
    var redoCount = 0;

    Future<void> pump({required bool canUndo, required bool canRedo}) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1400,
              child: VoidTopBar(
                onMenuSelected: (_) {},
                canUndo: canUndo,
                canRedo: canRedo,
                onUndo: () => undoCount++,
                onRedo: () => redoCount++,
              ),
            ),
          ),
        ),
      );
    }

    await pump(canUndo: false, canRedo: false);
    IconButton buttonFor(IconData icon) => tester.widget<IconButton>(
      find.ancestor(of: find.byIcon(icon), matching: find.byType(IconButton)),
    );
    expect(buttonFor(Icons.undo_rounded).onPressed, isNull);
    expect(buttonFor(Icons.redo_rounded).onPressed, isNull);

    await pump(canUndo: true, canRedo: true);
    await tester.tap(find.byIcon(Icons.undo_rounded));
    await tester.tap(find.byIcon(Icons.redo_rounded));
    expect(undoCount, 1);
    expect(redoCount, 1);
  });
}
