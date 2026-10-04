import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/jobs/background_job.dart';
import 'package:void_scriptor/core/jobs/background_job_controller.dart';
import 'package:void_scriptor/core/jobs/background_job_queue.dart';
import 'package:void_scriptor/core/jobs/task_center_screen.dart';

/// WCAG 2.2 A / SC 2.4.3 (Focus Order) contract for [TaskCenterScreen].
///
/// Measured probe baseline (viewport 1536x1024, dpr 1.0, Tab pressed until a
/// focus rect repeats):
/// * route pushed + 2 queued jobs -> 3 stops:
///   `Back@8,8 40x40` -> `Cancel task@1448,124 40x40` ->
///   `Cancel task@1448,204 40x40` -> repeat `Back`.
/// * route pushed + 1 queued job -> 2 stops (`Back`, `Cancel task`).
/// * no parent route (screen is home) + 2 queued jobs -> 2 stops
///   (`Cancel task`, `Cancel task`) - the Back affordance comes from the
///   pushed route, not from the screen itself.
/// * route pushed + 0 jobs -> 1 stop (`Back`): the empty-state Text
///   ("No background tasks") is not focusable.
const Size _viewport = Size(1536, 1024);

class _Stop {
  const _Stop(this.label, this.rect);

  final String label;
  final Rect rect;
}

Future<List<_Stop>> _collectStops(
  WidgetTester tester, {
  required bool pushRoute,
  required int jobCount,
}) async {
  tester.view.physicalSize = _viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final queue = BackgroundJobQueue();
  final controller = BackgroundJobController(queue);
  addTearDown(controller.dispose);
  for (var i = 0; i < jobCount; i++) {
    controller.enqueue(
      _FocusJobTask(id: 'focus-job-$i', label: 'Task number $i'),
    );
  }

  final screen = TaskCenterScreen(controller: controller);
  if (pushRoute) {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => screen)),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
  } else {
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();
  }

  final stops = <_Stop>[];
  final seen = <String>[];
  for (var i = 0; i < 25; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final node = tester.binding.focusManager.primaryFocus;
    final renderObject = node?.context?.findRenderObject();
    Rect? rect;
    if (renderObject is RenderBox &&
        renderObject.attached &&
        renderObject.hasSize) {
      rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    }
    if (rect == null) continue;
    final stop = _Stop(_labelFor(tester, node), rect);
    final key = '${stop.label}@${stop.rect}';
    if (seen.contains(key)) break;
    seen.add(key);
    stops.add(stop);
  }
  return stops;
}

List<String> _labelsOf(List<_Stop> stops) =>
    stops.map((stop) => stop.label).toList();

void _expectRectsInViewport(List<_Stop> stops) {
  for (final stop in stops) {
    expect(stop.rect.width, greaterThan(0), reason: stop.label);
    expect(stop.rect.height, greaterThan(0), reason: stop.label);
    expect(stop.rect.width, lessThanOrEqualTo(_viewport.width));
    expect(stop.rect.height, lessThanOrEqualTo(_viewport.height));
    expect(stop.rect.left, greaterThanOrEqualTo(0), reason: stop.label);
    expect(stop.rect.top, greaterThanOrEqualTo(0), reason: stop.label);
    expect(stop.rect.right, lessThanOrEqualTo(_viewport.width));
    expect(stop.rect.bottom, lessThanOrEqualTo(_viewport.height));
  }
}

void main() {
  testWidgets(
    'route with two queued jobs: 3 stops Back -> Cancel task -> Cancel task',
    (tester) async {
      final stops = await _collectStops(tester, pushRoute: true, jobCount: 2);

      expect(_labelsOf(stops), <String>['Back', 'Cancel task', 'Cancel task']);
      _expectRectsInViewport(stops);

      // Back is the top-left route affordance.
      expect(stops[0].rect.left, lessThanOrEqualTo(16));
      expect(stops[0].rect.top, lessThanOrEqualTo(16));

      // Cancel affordances sit on the right half of the screen, and Back
      // sits to their left.
      expect(stops[1].rect.left, greaterThan(_viewport.width / 2));
      expect(stops[2].rect.left, greaterThan(_viewport.width / 2));
      expect(stops[0].rect.left, lessThan(stops[1].rect.left));

      // Top-to-bottom order: each stop is lower than the previous one.
      expect(stops[1].rect.top, greaterThan(stops[0].rect.top));
      expect(stops[2].rect.top, greaterThan(stops[1].rect.top));

      // The two job rows are distinct focus targets at the same x origin.
      expect(stops[1].rect.left, stops[2].rect.left);
      expect(stops[1].rect.size, stops[2].rect.size);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('route with one queued job: 2 stops Back -> Cancel task', (
    tester,
  ) async {
    final stops = await _collectStops(tester, pushRoute: true, jobCount: 1);

    expect(_labelsOf(stops), <String>['Back', 'Cancel task']);
    _expectRectsInViewport(stops);
    expect(stops[0].rect.left, lessThanOrEqualTo(16));
    expect(stops[1].rect.left, greaterThan(_viewport.width / 2));
    expect(stops[1].rect.top, greaterThan(stops[0].rect.top));

    expect(tester.takeException(), isNull);
  });

  testWidgets('screen without a parent route: 2 stops, both Cancel task', (
    tester,
  ) async {
    final stops = await _collectStops(tester, pushRoute: false, jobCount: 2);

    expect(_labelsOf(stops), <String>['Cancel task', 'Cancel task']);
    _expectRectsInViewport(stops);
    expect(stops[0].rect.left, greaterThan(_viewport.width / 2));
    expect(stops[1].rect.top, greaterThan(stops[0].rect.top));
    expect(_labelsOf(stops), isNot(contains('Back')));

    expect(tester.takeException(), isNull);
  });

  testWidgets('empty state adds no tab stop: 1 stop Back only', (tester) async {
    final stops = await _collectStops(tester, pushRoute: true, jobCount: 0);

    expect(_labelsOf(stops), <String>['Back']);
    _expectRectsInViewport(stops);
    expect(find.text('No background tasks'), findsOneWidget);
    expect(find.byTooltip('Cancel task'), findsNothing);

    expect(tester.takeException(), isNull);
  });
}

bool _isDescendantOf(Element element, Element root) {
  if (element == root) return true;
  var found = false;
  element.visitAncestorElements((ancestor) {
    if (ancestor == root) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

/// Resolves the accessible label of the currently focused element: the
/// focused element itself or its nearest ancestor that carries a label
/// (IconButton.tooltip, Tooltip.message, Text). Falls back to the first
/// non-empty [Text] in the focused subtree, then to a generic marker.
String _labelFor(WidgetTester tester, FocusNode? node) {
  final context = node?.context;
  if (context == null) return '<no-focus>';
  final root = context as Element;

  Element? cursor = root;
  var sawIconish = false;
  while (cursor != null) {
    final widget = cursor.widget;
    if (widget is IconButton) {
      sawIconish = true;
      final tip = widget.tooltip;
      if (tip != null && tip.isNotEmpty) return tip;
    }
    if (widget is Tooltip && (widget.message ?? '').isNotEmpty) {
      return widget.message!;
    }
    if (widget is Text && (widget.data ?? '').isNotEmpty) return widget.data!;
    if (widget is Icon) sawIconish = true;
    Element? ancestor;
    cursor.visitAncestorElements((next) {
      ancestor = next;
      return false;
    });
    cursor = ancestor;
  }

  Text? firstText;
  for (final element in tester.allElements) {
    if (!_isDescendantOf(element, root)) continue;
    final widget = element.widget;
    if (widget is Text && (widget.data ?? '').isNotEmpty) {
      firstText = widget;
      break;
    }
    if (widget is IconButton) sawIconish = true;
  }
  if (firstText != null) return firstText.data!;
  if (sawIconish) return '<icon-button>';
  return '<no-text>';
}

class _FocusJobTask implements BackgroundTask {
  _FocusJobTask({required this.id, required this.label});

  @override
  final String id;
  final String label;

  @override
  BackgroundJob get job => BackgroundJob(
    id: id,
    projectId: 'focus-project',
    type: BackgroundJobType.thumbnail,
    label: label,
    status: BackgroundJobStatus.queued,
    priority: BackgroundJobPriority.normal,
    createdAt: DateTime(2026),
  );

  @override
  BackgroundJobType get type => job.type;

  @override
  String? get taskKey => 'focus-order:$id';

  @override
  Set<JobResource> get resources => const {JobResource.cpu};

  @override
  Future<void> execute(JobContext context) async {}

  @override
  Future<void> cancel() async {}
}
