import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/shell/desktop/void_top_bar.dart';

import '../shared/theme_test_overrides.dart';

void main() {
  testWidgets('top bar exposes Backup & Export via project context', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1280, 720)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final selected = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: themeTestOverrides(),
        child: MaterialApp(
          home: Scaffold(
            body: VoidTopBar(
              onMenuSelected: selected.add,
              // Frontier 2: Backup & Export pindah dari row navigasi global ke
              // menu project-context. Intent test tetap: top bar harus
              // mengekspos Backup & Export, kini dalam konteks project.
              projectContext: const ProjectContextSummary(
                projectId: 'p1',
                projectName: 'Saga Uji',
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Backup & Export'), findsNothing);
    await tester.tap(find.text('Saga Uji'));
    await tester.pumpAndSettle();
    expect(find.text('Backup & Export'), findsOneWidget);
    await tester.tap(find.text('Backup & Export'));
    await tester.pumpAndSettle();
    expect(selected, ['backup-export']);

    // Settings tetap terjangkau dari top bar lewat Account menu.
    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(selected, ['backup-export', 'settings']);
  });
}
