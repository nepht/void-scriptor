import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:void_scriptor/app/shell/desktop/void_top_bar.dart';

import '../../shared/theme_test_overrides.dart';

void _noop(String _) {}

void main() {
  testWidgets('limited width moves secondary Core destinations into More', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1600, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: themeTestOverrides(),
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              child: VoidTopBar(onMenuSelected: _noop),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    // Frontier 2: baris Core tinggal 3 destinasi, jadi lebar 1280 sudah
    // memuat semuanya dan tidak ada yang perlu masuk More navigation.
    expect(find.byTooltip('More navigation'), findsNothing);
    expect(find.text('Characters'), findsNothing);
    expect(find.text('World'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      ProviderScope(
        overrides: themeTestOverrides(),
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1600,
              child: VoidTopBar(onMenuSelected: _noop),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Backup & Export'), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('undo and redo toolbar buttons follow command state', (
    tester,
  ) async {
    var undoCount = 0;
    var redoCount = 0;

    Future<void> pump({required bool canUndo, required bool canRedo}) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: themeTestOverrides(),
          child: MaterialApp(
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
        ),
      );
    }

    await pump(canUndo: false, canRedo: false);
    IconButton buttonFor(IconData icon) => tester.widget<IconButton>(
      find.ancestor(of: find.byIcon(icon), matching: find.byType(IconButton)),
    );
    expect(buttonFor(LucideIcons.undo2).onPressed, isNull);
    expect(buttonFor(LucideIcons.redo2).onPressed, isNull);

    await pump(canUndo: true, canRedo: true);
    await tester.tap(find.byIcon(LucideIcons.undo2));
    await tester.tap(find.byIcon(LucideIcons.redo2));
    expect(undoCount, 1);
    expect(redoCount, 1);
  });

  testWidgets('AI Studio top bar menu exposes image and video generators', (
    tester,
  ) async {
    final selected = <String>[];
    tester.view
      ..physicalSize = const Size(1600, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: themeTestOverrides(),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1600,
              child: VoidTopBar(onMenuSelected: selected.add),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('AI Studio'));
    await tester.pumpAndSettle();
    expect(find.text('Image Generator'), findsOneWidget);
    expect(find.text('Video Generator'), findsOneWidget);

    await tester.tap(find.text('Video Generator'));
    await tester.pumpAndSettle();
    expect(selected, ['ai-video-generator']);
  });
}
