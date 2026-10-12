// WCAG 2.4.3 (Focus Order) contract for `RecentProjects`
// (lib/features/dashboard/presentation/widgets/recent_projects.dart).
//
// This surface is production-wired from the Dashboard (dashboard_screen.dart)
// and is keyboard-traversed by real users. It had a behaviour test
// (recent_projects_test.dart) but NO test ever pressed LogicalKeyboardKey.tab,
// so its focus order was never pinned. This contract locks the Tab ring:
//   View all (top-right) -> Continue writing (most-recent card) ->
//   other recent project rows (top to bottom).
// Evidence-first: the ring below is the ground truth measured by a throwaway
// probe on Flutter 3.47.x / viewport 1536x1024 / dpr 1.0 (phase 112).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/dashboard/presentation/widgets/recent_projects.dart';
import 'package:void_scriptor/features/projects/domain/project_model.dart';
import 'package:void_scriptor/features/projects/presentation/project_controller.dart';

const Size _viewport = Size(1536, 1024);

class _ProjectsFixture extends ProjectController {
  _ProjectsFixture(this.items);
  final List<ProjectModel> items;
  @override
  Future<List<ProjectModel>> build() async => items;
}

ProjectModel _project(String id, int day) => ProjectModel(
  id: id,
  name: id,
  description: 'A story in progress',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  lastOpenedAt: DateTime(2026, 9, day),
  localPath: '',
  version: '0.1.0',
);

/// Three projects: `Alpha` is the most recently opened (rendered in the
/// "Pick up where you left off" card), `Bravo`/`Charlie` are the remaining
/// rows in the "Other recent projects" list.
Widget _wrap() => ProviderScope(
  overrides: [
    projectControllerProvider.overrideWith(
      () => _ProjectsFixture([
        _project('Alpha', 7),
        _project('Bravo', 5),
        _project('Charlie', 3),
      ]),
    ),
  ],
  child: const MaterialApp(
    home: Scaffold(
      body: Align(alignment: Alignment.topLeft, child: RecentProjects()),
    ),
  ),
);

class _Stop {
  const _Stop(this.label, this.rect);
  final String label;
  final Rect rect;
}

/// First non-Icon `Text` label inside [el], falling back to a Tooltip message,
/// then the widget runtime type. Mirrors the label rule used by the probe.
String _firstLabel(Element el) {
  final texts = <String>[];
  String? tooltip;
  void visit(Element e) {
    final w = e.widget;
    if (w is Text && w.data != null) texts.add(w.data!);
    if (w is Tooltip && w.message != null) tooltip ??= w.message!;
    e.visitChildren(visit);
  }

  el.visitChildren(visit);
  if (texts.isNotEmpty) return texts.first;
  if (tooltip != null) return 'tooltip:$tooltip';
  return 'widget:${el.widget.runtimeType}';
}

Rect _focusRect() {
  final f = FocusManager.instance.primaryFocus;
  final ro = f?.context?.findRenderObject();
  if (ro is RenderBox) return ro.localToGlobal(Offset.zero) & ro.size;
  return Rect.zero;
}

/// Walks the forward Tab ring until a rect repeats; returns the stops.
Future<List<_Stop>> _forwardRing(
  WidgetTester tester, {
  int maxSteps = 12,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  final stops = <_Stop>[];
  final seen = <String>{};
  for (var i = 0; i < maxSteps; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final f = FocusManager.instance.primaryFocus;
    if (f == null || f.context == null) break;
    final ro = f.context!.findRenderObject();
    if (ro is! RenderBox) break;
    final rect = ro.localToGlobal(Offset.zero) & ro.size;
    final key = '${rect.left},${rect.top},${rect.width},${rect.height}';
    if (seen.contains(key)) break;
    seen.add(key);
    stops.add(_Stop(_firstLabel(f.context! as Element), rect));
  }
  return stops;
}

/// Sends Shift+Tab (there is no `shift` flag on `sendKeyEvent`).
Future<void> _shiftTab(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
}

void main() {
  testWidgets('1. Tab ring is 4 stops in top-to-bottom reading order', (
    tester,
  ) async {
    tester.view.physicalSize = _viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    final stops = await _forwardRing(tester);
    expect(stops.map((s) => s.label).toList(), <String>[
      'View all',
      'Continue writing',
      'Bravo',
      'Charlie',
    ]);
  });

  testWidgets('2. stops progress strictly top-to-bottom', (tester) async {
    tester.view.physicalSize = _viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    final stops = await _forwardRing(tester);
    expect(stops.length, 4);
    for (var i = 1; i < stops.length; i++) {
      expect(
        stops[i].rect.top,
        greaterThan(stops[i - 1].rect.top),
        reason: 'stop ${stops[i].label} must sit below ${stops[i - 1].label}',
      );
    }
  });

  testWidgets('3. every stop has a non-zero rect inside the viewport', (
    tester,
  ) async {
    tester.view.physicalSize = _viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    final stops = await _forwardRing(tester);
    expect(stops, isNotEmpty);
    for (final s in stops) {
      expect(s.rect.width, greaterThan(0), reason: '${s.label} width');
      expect(s.rect.height, greaterThan(0), reason: '${s.label} height');
      expect(s.rect.left, greaterThanOrEqualTo(0), reason: '${s.label} left');
      expect(s.rect.top, greaterThanOrEqualTo(0), reason: '${s.label} top');
      expect(
        s.rect.right,
        lessThanOrEqualTo(_viewport.width + 1),
        reason: '${s.label} right',
      );
      expect(
        s.rect.bottom,
        lessThanOrEqualTo(_viewport.height + 1),
        reason: '${s.label} bottom',
      );
    }
  });

  testWidgets('4. Tab after the last stop returns to the first', (
    tester,
  ) async {
    tester.view.physicalSize = _viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    final stops = await _forwardRing(tester);
    expect(stops.length, 4);
    // The ring is closed: the Tab that terminated _forwardRing (the 5th) had
    // already wrapped back onto the first stop, so primary focus now sits on
    // the first stop again. This is the "wraps to first" contract.
    expect(_focusRect(), stops.first.rect);
  });

  testWidgets('5. Shift+Tab traverses the same ring backwards', (tester) async {
    tester.view.physicalSize = _viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    final forward = await _forwardRing(tester);
    expect(forward.length, 4);
    final ringRects = forward.map((s) => s.rect).toList();

    final backward = <Rect>[];
    for (var i = 0; i < forward.length; i++) {
      await _shiftTab(tester);
      await tester.pump();
      backward.add(_focusRect());
    }
    // Every backward rect must be a member of the forward ring.
    for (final r in backward) {
      expect(
        ringRects.any((m) => m == r),
        isTrue,
        reason: 'backward rect $r must be a member of the forward ring',
      );
    }
    // Backward order is the reverse of the forward order.
    expect(backward, ringRects.reversed.toList());
  });

  testWidgets('6. 10x Tab never loses focus and throws no exception', (
    tester,
  ) async {
    tester.view.physicalSize = _viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.context,
        isNotNull,
        reason: 'focus lost at step ${i + 1}',
      );
    }
    expect(tester.takeException(), isNull);
  });
}
