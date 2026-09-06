// Frontier 2 (queue Choi 5b6e11a): rapikan top bar desktop.
// Kiri hanya Dashboard/Projects/Search; project-context menyediakan
// Backup & Export; kanan memuat save-status + Undo/Redo + Command Palette
// (Search global) + AI; Theme kini milik Settings (bukan top bar);
// duplikasi Support/Donation hilang dari Account menu.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:void_scriptor/app/shell/desktop/void_top_bar.dart';
import 'package:void_scriptor/core/commands/project_mutation_state.dart';

import '../../shared/theme_test_overrides.dart';

void _noop(String _) {}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 1600,
}) async {
  tester.view
    ..physicalSize = Size(width, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: themeTestOverrides(),
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('left cluster hanya Dashboard, Projects, Search', (tester) async {
    final selected = <String>[];
    await _pump(
      tester,
      SizedBox(width: 1600, child: VoidTopBar(onMenuSelected: selected.add)),
    );

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Characters'), findsNothing);
    expect(find.text('World'), findsNothing);
    // Backup & Export pindah ke konteks project; bukan lagi destinasi top bar.
    expect(find.text('Backup & Export'), findsNothing);

    await tester.tap(find.text('Dashboard'));
    await tester.tap(find.text('Projects'));
    await tester.tap(find.text('Search'));
    expect(selected, ['dashboard', 'novels', 'search']);
  });

  testWidgets('project context menyediakan Backup & Export saat sesi aktif', (
    tester,
  ) async {
    final selected = <String>[];
    await _pump(
      tester,
      SizedBox(
        width: 1600,
        child: VoidTopBar(
          onMenuSelected: selected.add,
          projectContext: const ProjectContextSummary(
            projectId: 'p1',
            projectName: 'Saga Uji',
          ),
        ),
      ),
    );

    expect(find.text('Saga Uji'), findsOneWidget);
    await tester.tap(find.text('Saga Uji'));
    await tester.pumpAndSettle();
    expect(find.text('Backup & Export'), findsOneWidget);
    await tester.tap(find.text('Backup & Export'));
    await tester.pumpAndSettle();
    expect(selected, ['backup-export']);
  });

  testWidgets('project context tidak tampil tanpa sesi', (tester) async {
    await _pump(
      tester,
      const SizedBox(width: 1600, child: VoidTopBar(onMenuSelected: _noop)),
    );
    expect(find.byTooltip('Project context'), findsNothing);
  });

  testWidgets('save status mengikuti state mutasi', (tester) async {
    await _pump(
      tester,
      const SizedBox(
        width: 1600,
        child: VoidTopBar(
          onMenuSelected: _noop,
          saveState: ProjectMutationState(
            currentSequence: 1,
            savedSequence: 1,
          ),
        ),
      ),
    );
    expect(find.text('Tersimpan'), findsOneWidget);

    await _pump(
      tester,
      const SizedBox(
        width: 1600,
        child: VoidTopBar(
          onMenuSelected: _noop,
          saveState: ProjectMutationState(
            currentSequence: 2,
            savedSequence: 1,
          ),
        ),
      ),
    );
    expect(find.text('Belum tersimpan'), findsOneWidget);
  });

  testWidgets('command palette Search global tersedia di kanan', (
    tester,
  ) async {
    var opened = 0;
    await _pump(
      tester,
      SizedBox(
        width: 1600,
        child: VoidTopBar(onMenuSelected: _noop, onOpenSearch: () => opened++),
      ),
    );
    await tester.tap(find.byTooltip('Search across the project'));
    expect(opened, 1);
  });

  testWidgets('Theme popup tidak lagi berada di top bar', (tester) async {
    await _pump(
      tester,
      const SizedBox(width: 1600, child: VoidTopBar(onMenuSelected: _noop)),
    );
    expect(find.byTooltip('Theme'), findsNothing);
  });

  testWidgets('Account menu tidak lagi memuat duplikasi Support', (
    tester,
  ) async {
    await _pump(
      tester,
      const SizedBox(width: 1600, child: VoidTopBar(onMenuSelected: _noop)),
    );
    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Support Void Scriptor'), findsNothing);
    expect(find.text('Account & Cloud'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('undo/redo toolbar tetap mengikuti command state', (
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

  testWidgets('lebar sempit menumpuk sisa cluster tanpa overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      const SizedBox(width: 900, child: VoidTopBar(onMenuSelected: _noop)),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
  });

  testWidgets('AI Studio menu tetap mengekspos image & video generator', (
    tester,
  ) async {
    final selected = <String>[];
    await _pump(
      tester,
      SizedBox(width: 1600, child: VoidTopBar(onMenuSelected: selected.add)),
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
