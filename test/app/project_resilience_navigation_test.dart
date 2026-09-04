import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/shell/desktop/void_top_bar.dart';

import '../shared/theme_test_overrides.dart';

void main() {
  testWidgets('top bar exposes Backup & Export as a Core destination', (
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
          home: Scaffold(body: VoidTopBar(onMenuSelected: selected.add)),
        ),
      ),
    );
    // At 1280 width the visible row holds Dashboard, Novels, Search, and
    // Backup & Export; Settings folds into the overflow menu.
    expect(find.text('Backup & Export'), findsOneWidget);
    await tester.tap(find.text('Backup & Export'));
    expect(selected, ['backup-export']);

    await tester.tap(find.byTooltip('More navigation'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(selected, ['backup-export', 'settings']);
  });
}
