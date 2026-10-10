import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/shell/desktop/void_desktop_shell.dart';
import 'package:void_scriptor/app/shell/desktop/void_top_bar.dart';

import '../../shared/theme_test_overrides.dart';

/// 115.37/115.38 — Choi, 2026-09-27: top bar 39px lalu 32px, status bar dihapus.
///
/// Dua kontrak ini mengunci keputusan shell:
/// - tinggi top bar persis 39px (bukan 52px lama), dan isinya (project
///   context 34px) masih muat tanpa overflow;
/// - desktop shell tidak lagi merender status bar di bawah konten.
void _noop(String _) {}

void main() {
  // 115.38: 39px -> 32px.
  const shellTopBarHeight = 32.0;

  testWidgets('top bar 32px dan tidak meluap pada viewport sempit', (
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

    final bar = tester.getRect(find.byType(VoidTopBar));
    expect(
      bar.height,
      closeTo(shellTopBarHeight, 0.01),
      reason: '115.38: top bar 32px',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop shell tidak lagi merender status bar', (tester) async {
    tester.view
      ..physicalSize = const Size(1600, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: themeTestOverrides(),
        child: const MaterialApp(home: VoidDesktopShell()),
      ),
    );
    await tester.pump();

    // 115.37: status bar dihapus. Label lamanya tidak boleh muncul lagi,
    // dan konten harus mengisi tinggi yang tersisa.
    expect(find.text('Local'), findsNothing);
    expect(find.text('Undo'), findsNothing);
    expect(find.text('Dirty'), findsNothing);
    expect(find.textContaining('Void Scriptor Studio 0.1 Alpha'), findsNothing);
  });
}
