// WCAG 2.2 — 2.4.3 Focus Order contract for AutomationCenterScreen.
//
// Probe evidence (test/features/workflow/presentation/_probe_focus_test.dart,
// viewport 1536x1024, dpr 1.0, DIHAPUS setelah hasil dibaca):
//   SWITCH_COUNT=3, semua `Switch.onChanged == NULL` (display-only, alpha scope)
//   LISTTILE_COUNT=3, semua `ListTile.onTap == NULL`
//   Tab traversal -> hanya FocusScope root (0 affordance); rect berulang
//     (0,0,1536x1024) pada Tab kedua.
//   RULE r-1 (0,52,1536x72) < r-2 (0,124,1536x72) < r-3 (0,196,1536x72)
//   METRICS (0,280,1536x90)
//
// Catatan kontrak: AutomationCenterScreen adalah permukaan alpha-scope yang
// mengontrol aturan automation secara display-only. Setiap affordance yang
// tampak interaktif (`Switch` per baris, `ListTile` baris) sengaja deferred
// (`onChanged: null` / `onTap: null`). Kontrak ini mengunci keadaan itu supaya
// saat kontrol benar-benar diaktifkan, traversal keyboard wajib didefinisikan
// ulang di sini — bukan diam-diam berubah.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/automation/automation_rule.dart';
import 'package:void_scriptor/automation/workflow_trigger.dart';
import 'package:void_scriptor/features/workflow/presentation/automation_center_screen.dart';

const double _viewportWidth = 1536;
const double _viewportHeight = 1024;

AutomationRule _rule(
  String id,
  WorkflowTriggerType type, {
  bool enabled = true,
}) => AutomationRule(
  ruleId: id,
  trigger: WorkflowTrigger(
    triggerId: 't-$id',
    type: type,
    configuration: const {},
    createdAt: DateTime.utc(2026, 8, 25),
    updatedAt: DateTime.utc(2026, 8, 25),
  ),
  conditions: const [],
  workflowId: 'wf-$id',
  enabled: enabled,
);

Widget _screen({required List<AutomationRule> rules}) => MaterialApp(
  home: Scaffold(
    body: AutomationCenterScreen(
      rules: rules,
      metricsSnapshot: const {
        'run_count': 4,
        'success_rate': 0.75,
        'failure_rate': 0.25,
      },
    ),
  ),
);

List<AutomationRule> _sampleRules() => [
  _rule('r-1', WorkflowTriggerType.manual),
  _rule('r-2', WorkflowTriggerType.jobEvent, enabled: false),
  _rule('r-3', WorkflowTriggerType.schedule),
];

/// Tekan Tab berulang; catat hanya stop yang BUKAN focus scope (affordance
/// nyata), berhenti saat rect affordance berulang.
Future<List<Rect>> _affordanceStops(WidgetTester tester) async {
  final stops = <Rect>[];
  final seen = <String>{};
  for (var i = 0; i < 12; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final node = FocusManager.instance.primaryFocus;
    final ctx = node?.context;
    if (ctx == null) break;
    if (ctx.widget is FocusScope) continue; // scope root bukan affordance
    final object = ctx.findRenderObject();
    if (object is! RenderBox || !object.hasSize || !object.attached) break;
    final rect = object.localToGlobal(Offset.zero) & object.size;
    final key = '${rect.left}|${rect.top}|${rect.width}|${rect.height}';
    if (!seen.add(key)) break;
    stops.add(rect);
  }
  return stops;
}

void _useDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(_viewportWidth, _viewportHeight);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('AutomationCenterScreen — kontrak focus order 2.4.3', () {
    testWidgets(
      '1. traversal keyboard tidak menjangkau affordance (kontrol deferred)',
      (tester) async {
        _useDesktopViewport(tester);
        await tester.pumpWidget(_screen(rules: _sampleRules()));
        await tester.pumpAndSettle();

        final stops = await _affordanceStops(tester);

        expect(
          stops,
          isEmpty,
          reason:
              'Semua kontrol masih deferred; tidak boleh ada affordance '
              'keyboard sampai Switch/ListTile diaktifkan.',
        );

        // Bukti bahwa 0 stop itu BY DESIGN, bukan focus node yang hilang.
        final switches = find.byType(Switch).evaluate().toList();
        expect(switches, hasLength(3));
        for (final e in switches) {
          expect(
            (e.widget as Switch).onChanged,
            isNull,
            reason: 'Switch baris aturan harus display-only (deferred).',
          );
        }
        final tiles = find.byType(ListTile).evaluate().toList();
        expect(tiles, hasLength(3));
        for (final e in tiles) {
          expect(
            (e.widget as ListTile).onTap,
            isNull,
            reason: 'Baris aturan belum punya aksi tap (deferred).',
          );
        }

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '2. urutan baca baris aturan atas-ke-bawah di atas panel metrik',
      (tester) async {
        _useDesktopViewport(tester);
        await tester.pumpWidget(_screen(rules: _sampleRules()));
        await tester.pumpAndSettle();

        Rect rectOf(Key key) => tester.getRect(find.byKey(key));
        final r1 = rectOf(const Key('rule-r-1'));
        final r2 = rectOf(const Key('rule-r-2'));
        final r3 = rectOf(const Key('rule-r-3'));
        final metrics = rectOf(const Key('metrics-panel'));

        // Semua area non-zero dan berada di dalam viewport.
        for (final entry in {
          'rule-r-1': r1,
          'rule-r-2': r2,
          'rule-r-3': r3,
          'metrics-panel': metrics,
        }.entries) {
          expect(entry.value.width, greaterThan(0), reason: entry.key);
          expect(entry.value.height, greaterThan(0), reason: entry.key);
          expect(entry.value.left, greaterThanOrEqualTo(0), reason: entry.key);
          expect(entry.value.top, greaterThanOrEqualTo(0), reason: entry.key);
          expect(
            entry.value.right,
            lessThanOrEqualTo(_viewportWidth),
            reason: entry.key,
          );
          expect(
            entry.value.bottom,
            lessThanOrEqualTo(_viewportHeight),
            reason: entry.key,
          );
        }

        // Urutan baca atas-ke-bawah: r-1 -> r-2 -> r-3 -> panel metrik.
        expect(
          r1.top,
          lessThan(r2.top),
          reason: 'Baris r-1 dibaca sebelum r-2.',
        );
        expect(
          r2.top,
          lessThan(r3.top),
          reason: 'Baris r-2 dibaca sebelum r-3.',
        );
        expect(
          r3.top,
          lessThan(metrics.top),
          reason: 'Panel metrik berada di bawah daftar aturan.',
        );

        // Ketiga baris rata kolom (kiri & lebar identik) — satu kolom daftar.
        expect(r2.left, r1.left);
        expect(r3.left, r1.left);
        expect(r2.width, r1.width);
        expect(r3.width, r1.width);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('3. daftar aturan kosong: chrome tetap render, tetap 0 stop', (
      tester,
    ) async {
      _useDesktopViewport(tester);
      await tester.pumpWidget(_screen(rules: const []));
      await tester.pumpAndSettle();

      expect(find.text('Automation Center'), findsOneWidget);
      expect(find.text('No automation rules yet.'), findsOneWidget);
      expect(find.byKey(const Key('metrics-panel')), findsOneWidget);
      expect(find.byType(Switch), findsNothing);

      final stops = await _affordanceStops(tester);
      expect(stops, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}
