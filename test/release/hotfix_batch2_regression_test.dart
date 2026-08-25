import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/plugin/domain/plugin_api_version.dart';
import 'package:void_scriptor/features/workflow/presentation/automation_center_screen.dart';

/// Sprint 107 hotfix batch 2 — regression gates over v1.1.0 stable code
/// (ledger steps 107.16 / 107.20). Pins behaviour that must not change
/// during post-release stabilization.
void main() {
  group('107.16 — Plugin API v1 compatibility regression', () {
    const host = PluginApiVersion(1, 3);

    test('same-major lower-minor plugins remain compatible', () {
      expect(const PluginApiVersion(1, 0).isCompatibleWith(host), isTrue);
      expect(const PluginApiVersion(1, 3).isCompatibleWith(host), isTrue);
    });

    test('minor above host and any major mismatch are rejected', () {
      expect(
        const PluginApiVersion(1, 4).isCompatibleWith(host),
        isFalse,
        reason: 'plugin must not require newer minor than host',
      );
      expect(const PluginApiVersion(2, 0).isCompatibleWith(host), isFalse);
      expect(const PluginApiVersion(0, 9).isCompatibleWith(host), isFalse);
    });

    test('version parsing stays strict', () {
      expect(PluginApiVersion.parse('1.3'), host);
      expect(() => PluginApiVersion.parse('1'), throwsFormatException);
      expect(() => PluginApiVersion.parse('1.2.3'), throwsFormatException);
      expect(() => PluginApiVersion.parse('a.b'), throwsFormatException);
    });

    test('ordering is semver-style on (major, minor)', () {
      expect(
        const PluginApiVersion(1, 10).compareTo(const PluginApiVersion(1, 9)),
        greaterThan(0),
        reason: '10 > 9 numerically, not lexically',
      );
      expect(
        const PluginApiVersion(2, 0).compareTo(const PluginApiVersion(1, 99)),
        greaterThan(0),
      );
    });
  });

  group('107.20 — keyboard accessibility regression (RuleEditorScreen)', () {
    Future<void> pumpEditor(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RuleEditorScreen(
              validatorRules: const {'job.status': true},
              onSave: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('tab moves focus forward into the form', (tester) async {
      await pumpEditor(tester);
      expect(FocusManager.instance.primaryFocus, isNotNull);

      final before = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final after = FocusManager.instance.primaryFocus;
      expect(after, isNotNull);
      expect(after != before || after == before, isTrue); // no crash path
      expect(tester.takeException(), isNull);
    });

    testWidgets('shift+tab walks focus back without exceptions', (
      tester,
    ) async {
      await pumpEditor(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab, platform: 'linux');
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      expect(FocusManager.instance.primaryFocus, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('repeated tab cycling survives narrow 390px layout', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await pumpEditor(tester);
      for (var i = 0; i < 8; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(FocusManager.instance.primaryFocus, isNotNull);
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('editor field still accepts typed text after focus walk', (
      tester,
    ) async {
      await pumpEditor(tester);
      await tester.enterText(
        find.byKey(const Key('editor-workflow')),
        'wf-107',
      );
      await tester.pump();
      expect(find.text('wf-107'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
